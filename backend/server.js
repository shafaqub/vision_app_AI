import express from "express";
import cors from "cors";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const app = express();
const PORT = 5000;

app.use(cors());
app.use(express.json());

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const beaconsPath = path.join(
  __dirname,
  "data",
  "beacons.json"
);

let beacons = {};

try {
  const fileData = fs.readFileSync(
    beaconsPath,
    "utf8"
  );

  beacons = JSON.parse(fileData);

  console.log(
    `Loaded ${Object.keys(beacons).length} beacons.`
  );
} catch (error) {
  console.error(
    "Could not load beacons.json:",
    error.message
  );
}

const userPositions = new Map();

/*
  EXACT same normalized boundaries
  used by the Flutter floor map.

  x = left -> right
  y = top -> bottom
*/
const ROOM_ZONES = {
  computer_lab_01: {
    name: "Computer Lab 01",
    type: "room",
    left: 0.08,
    top: 0.06,
    right: 0.46,
    bottom: 0.34,
  },

  stairs: {
    name: "Stairs",
    type: "stairs",
    left: 0.54,
    top: 0.06,
    right: 0.92,
    bottom: 0.34,
  },

  washroom: {
    name: "Washroom",
    type: "room",
    left: 0.54,
    top: 0.65,
    right: 0.92,
    bottom: 0.93,
  },
};

const BEACON_ZONE = {
  BEACON_LAB: "computer_lab_01",
  BEACON_STAIRS: "stairs",
  BEACON_WASHROOM: "washroom",

  BEACON_CENTER_LEFT: "open_floor",
  BEACON_CENTER_RIGHT: "open_floor",

  BEACON_OUTSIDE: "outside",
};

app.get("/", (req, res) => {
  res.json({
    message: "Indoor Navigation Backend is running",
  });
});

app.post("/api/ble/detection", (req, res) => {
  const {
    device_id,
    beacons: detectedBeacons,
  } = req.body;

  if (
    !device_id ||
    !Array.isArray(detectedBeacons)
  ) {
    return res.status(400).json({
      error:
        "device_id and beacons array are required",
    });
  }

  if (detectedBeacons.length === 0) {
    return res.status(400).json({
      error: "No beacons detected",
    });
  }

  const validBeacons =
    detectedBeacons.filter((beacon) => {
      return (
        beacon.id &&
        typeof beacon.rssi === "number" &&
        beacons[beacon.id]
      );
    });

  if (validBeacons.length === 0) {
    return res.status(400).json({
      error: "No known beacons detected",
    });
  }

  /*
    Find strongest beacon.
  */
  let strongestBeacon = validBeacons[0];

  for (const beacon of validBeacons) {
    if (
      beacon.rssi >
      strongestBeacon.rssi
    ) {
      strongestBeacon = beacon;
    }
  }

  /*
    -----------------------------------------
    STEP 1
    RSSI weighted position
    -----------------------------------------
  */

  let totalWeight = 0;
  let weightedX = 0;
  let weightedY = 0;

  for (const beacon of validBeacons) {
    const info = beacons[beacon.id];

    const weight =
      calculateWeight(
        beacon.rssi
      );

    totalWeight += weight;

    weightedX +=
      info.x * weight;

    weightedY +=
      info.y * weight;
  }

  let x =
    weightedX /
    totalWeight;

  let y =
    weightedY /
    totalWeight;

  x = clamp(x, 0.02, 0.98);
  y = clamp(y, 0.02, 0.98);

  const rawX = x;
  const rawY = y;

  /*
    -----------------------------------------
    STEP 2
    Smooth the RSSI estimate
    -----------------------------------------
  */

  const previousPosition =
    userPositions.get(device_id);

  if (previousPosition) {
    const smoothing = 1;

    x =
      previousPosition.x *
        (1 - smoothing) +
      x * smoothing;

    y =
      previousPosition.y *
        (1 - smoothing) +
      y * smoothing;
  }

  x = clamp(x, 0.02, 0.98);
  y = clamp(y, 0.02, 0.98);

  /*
    -----------------------------------------
    STEP 3
    Work out BLE zone evidence
    AFTER smoothing
    -----------------------------------------
  */

  const zoneScores =
    calculateZoneScores(
      validBeacons
    );

  const strongestZone =
    BEACON_ZONE[
      strongestBeacon.id
    ];

  const bestZone =
    getBestRoomZone(
      zoneScores
    );

  const bestZoneScore =
    bestZone == null
      ? 0
      : zoneScores[bestZone] /
        totalWeight;

  /*
    -----------------------------------------
    STEP 4
    Check exact map zone
    -----------------------------------------
  */

  let zone =
    getZoneFromPoint(
      x,
      y
    );

  let mapMatched = false;

  /*
    CASE 1:
    Point is already inside a room.
  */

  if (
    zone !== "open_floor" &&
    zone !== "outside"
  ) {
    /*
      If BLE strongly agrees with another
      room, correct to that room.
    */

    if (
      bestZone &&
      bestZone !== zone &&
      strongestZone === bestZone &&
      bestZoneScore >= 0.60 &&
      strongestBeacon.rssi >= -65
    ) {
      const corrected =
        clampPointToZone(
          x,
          y,
          ROOM_ZONES[bestZone],
          0.01
        );

      x = corrected.x;
      y = corrected.y;

      zone = bestZone;
      mapMatched = true;
    }
  }

  /*
    CASE 2:
    Point is on open floor but strong BLE
    evidence says the user is near a room.
  */

  if (
    zone === "open_floor" &&
    bestZone &&
    strongestZone === bestZone &&
    bestZoneScore >= 0.45 &&
    strongestBeacon.rssi >= -72
  ) {
    const distance =
      distanceToRect(
        x,
        y,
        ROOM_ZONES[bestZone]
      );

    /*
      Only snap when reasonably close
      to the room boundary.
    */

    if (distance <= 0.16) {
      const corrected =
        clampPointToZone(
          x,
          y,
          ROOM_ZONES[bestZone],
          0.01
        );

      x = corrected.x;
      y = corrected.y;

      zone = bestZone;
      mapMatched = true;
    }
  }

  /*
    CASE 3:
    Very strong room beacon.

    This is useful when a user is clearly
    inside the room and the RSSI estimate
    is slightly outside the wall.
  */

  if (
    bestZone &&
    strongestZone === bestZone &&
    strongestBeacon.rssi >= -60
  ) {
    const distance =
      distanceToRect(
        x,
        y,
        ROOM_ZONES[bestZone]
      );

    if (distance <= 0.10) {
      const corrected =
        clampPointToZone(
          x,
          y,
          ROOM_ZONES[bestZone],
          0.01
        );

      x = corrected.x;
      y = corrected.y;

      zone = bestZone;
      mapMatched = true;
    }
  }

  /*
    -----------------------------------------
    STEP 5
    Outside handling
    -----------------------------------------
  */

  if (
    strongestZone === "outside" &&
    strongestBeacon.rssi >= -58
  ) {
    const outsideBeacon =
      beacons["BEACON_OUTSIDE"];

    const outsideDistance =
      Math.sqrt(
        Math.pow(
          x - outsideBeacon.x,
          2
        ) +
        Math.pow(
          y - outsideBeacon.y,
          2
        )
      );

    if (
      outsideDistance <= 0.12
    ) {
      zone = "outside";
    }
  }

  /*
    -----------------------------------------
    STEP 6
    FINAL SAFETY CHECK
    -----------------------------------------

    Very important:
    If the zone says "Stairs",
    the final coordinates MUST be
    inside the exact Stairs rectangle.

    Same for Lab and Washroom.
  */

  if (
    zone !== "open_floor" &&
    zone !== "outside" &&
    ROOM_ZONES[zone]
  ) {
    const finalZone =
      ROOM_ZONES[zone];

    if (
      !isPointInsideZone(
        x,
        y,
        finalZone
      )
    ) {
      const corrected =
        clampPointToZone(
          x,
          y,
          finalZone,
          0.01
        );

      x = corrected.x;
      y = corrected.y;

      mapMatched = true;
    }
  }

  /*
    -----------------------------------------
    STEP 7
    Final location name
    -----------------------------------------
  */

  let location = "Open Floor";
  let zoneType = "open_floor";

  if (zone === "outside") {
    location = "Outside";
    zoneType = "outside";
  } else if (
    ROOM_ZONES[zone]
  ) {
    location =
      ROOM_ZONES[zone].name;

    zoneType =
      ROOM_ZONES[zone].type;
  } else {
    location =
      beacons[
        strongestBeacon.id
      ].location;
  }

  /*
    -----------------------------------------
    STEP 8
    Confidence
    -----------------------------------------
  */

  const confidence =
    calculateConfidence(
      strongestBeacon.rssi,
      validBeacons.length,
      bestZoneScore
    );

  const currentPosition = {
    location,
    zone: zoneType,

    x: Number(
      x.toFixed(4)
    ),

    y: Number(
      y.toFixed(4)
    ),

    beaconId:
      strongestBeacon.id,

    rssi:
      strongestBeacon.rssi,

    confidence,

    mapMatched,

    rawPosition: {
      x: Number(
        rawX.toFixed(4)
      ),

      y: Number(
        rawY.toFixed(4)
      ),
    },
  };

  userPositions.set(
    device_id,
    currentPosition
  );

  console.log(
    `\nPosition for ${device_id}:`
  );

  console.log(
    "Detected beacons:"
  );

  for (
    const beacon of validBeacons
  ) {
    console.log(
      `  ${beacon.id} -> ${beacon.rssi} dBm`
    );
  }

  console.log(
    "Strongest beacon:",
    strongestBeacon.id
  );

  console.log(
    "Raw position:",
    {
      x: rawX,
      y: rawY,
    }
  );

  console.log(
    "Final map position:",
    currentPosition
  );

  res.json({
    success: true,
    device_id,
    position: currentPosition,
  });
});

app.get(
  "/api/position/:deviceId",
  (req, res) => {
    const deviceId =
      req.params.deviceId;

    const position =
      userPositions.get(
        deviceId
      );

    if (!position) {
      return res.json({
        success: true,
        device_id: deviceId,
        position: {
          location: "Outside",
          zone: "outside",
          x: 0.15,
          y: 0.82,
          beaconId: null,
          rssi: null,
          confidence: 0,
          mapMatched: false,

          rawPosition: {
            x: 0.15,
            y: 0.82,
          },
        },
      });
    }

    res.json({
      success: true,
      device_id: deviceId,
      position,
    });
  }
);

function calculateWeight(rssi) {
  const minimumRssi = -95;

  const adjustedRssi =
    Math.max(
      rssi,
      minimumRssi
    );

  return Math.pow(
    10,
    (adjustedRssi + 95) /
      20
  );
}

function calculateZoneScores(
  detectedBeacons
) {
  const scores = {};

  for (
    const beacon of detectedBeacons
  ) {
    const zone =
      BEACON_ZONE[
        beacon.id
      ];

    if (
      !zone ||
      zone === "open_floor" ||
      zone === "outside"
    ) {
      continue;
    }

    const weight =
      calculateWeight(
        beacon.rssi
      );

    if (!scores[zone]) {
      scores[zone] = 0;
    }

    scores[zone] += weight;
  }

  return scores;
}

function getBestRoomZone(
  zoneScores
) {
  let bestZone = null;
  let bestScore = 0;

  for (
    const zone in zoneScores
  ) {
    if (
      zoneScores[zone] >
      bestScore
    ) {
      bestScore =
        zoneScores[zone];

      bestZone = zone;
    }
  }

  return bestZone;
}

function getZoneFromPoint(
  x,
  y
) {
  for (
    const zoneName in ROOM_ZONES
  ) {
    const zone =
      ROOM_ZONES[zoneName];

    if (
      x >= zone.left &&
      x <= zone.right &&
      y >= zone.top &&
      y <= zone.bottom
    ) {
      return zoneName;
    }
  }

  return "open_floor";
}

function isPointInsideZone(
  x,
  y,
  zone
) {
  return (
    x >= zone.left &&
    x <= zone.right &&
    y >= zone.top &&
    y <= zone.bottom
  );
}

function clampPointToZone(
  x,
  y,
  zone,
  padding
) {
  const left =
    zone.left + padding;

  const right =
    zone.right - padding;

  const top =
    zone.top + padding;

  const bottom =
    zone.bottom - padding;

  return {
    x: clamp(
      x,
      left,
      right
    ),

    y: clamp(
      y,
      top,
      bottom
    ),
  };
}

function distanceToRect(
  x,
  y,
  rect
) {
  const dx =
    Math.max(
      rect.left - x,
      0,
      x - rect.right
    );

  const dy =
    Math.max(
      rect.top - y,
      0,
      y - rect.bottom
    );

  return Math.sqrt(
    dx * dx +
    dy * dy
  );
}

function calculateConfidence(
  strongestRssi,
  beaconCount,
  zoneScore
) {
  let signalConfidence = 0.4;

  if (
    strongestRssi >= -45
  ) {
    signalConfidence = 1.0;
  } else if (
    strongestRssi >= -55
  ) {
    signalConfidence = 0.9;
  } else if (
    strongestRssi >= -65
  ) {
    signalConfidence = 0.75;
  } else if (
    strongestRssi >= -75
  ) {
    signalConfidence = 0.6;
  }

  const beaconConfidence =
    Math.min(
      beaconCount / 4,
      1
    );

  const zoneConfidence =
    Math.min(
      zoneScore,
      1
    );

  const finalConfidence =
    signalConfidence * 0.5 +
    beaconConfidence * 0.3 +
    zoneConfidence * 0.2;

  return Number(
    finalConfidence.toFixed(2)
  );
}

function clamp(
  value,
  min,
  max
) {
  return Math.min(
    Math.max(
      value,
      min
    ),
    max
  );
}

app.listen(
  PORT,
  "0.0.0.0",
  () => {
    console.log(
      `Backend running on http://localhost:${PORT}`
    );
  }
);