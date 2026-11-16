import network
import time
import math
import json
import urequests


BACKEND_URL = (
    "http://host.wokwi.internal:5000"
    "/api/ble/detection"
)

DEVICE_ID = "user_001"


# =====================================================
# BEACON POSITIONS
# These match the normalized coordinates used by Flutter
# =====================================================

beacons = {
    "BEACON_OUTSIDE": (0.15, 0.82),
    "BEACON_LAB": (0.27, 0.20),
    "BEACON_STAIRS": (0.73, 0.20),
    "BEACON_WASHROOM": (0.73, 0.79),
    "BEACON_CENTER_LEFT": (0.38, 0.50),
    "BEACON_CENTER_RIGHT": (0.62, 0.50)
}


# =====================================================
# SIMULATED USER PATH
# This represents the person walking around the floor
# =====================================================

walk_path = [

    # Start outside
    (0.15, 0.82),

    # Move toward center
    (0.20, 0.75),
    (0.25, 0.68),
    (0.32, 0.60),
    (0.38, 0.50),

    # Move across open area
    (0.48, 0.50),
    (0.62, 0.50),

    # Move toward stairs
    (0.68, 0.42),
    (0.73, 0.32),
    (0.73, 0.20),

    # Move toward washroom
    (0.73, 0.30),
    (0.73, 0.42),
    (0.73, 0.55),
    (0.73, 0.68),
    (0.73, 0.79),

    # Move back toward center
    (0.65, 0.70),
    (0.55, 0.60),
    (0.45, 0.50),

    # Move toward computer lab
    (0.38, 0.42),
    (0.32, 0.32),
    (0.27, 0.20),

    # Return outside
    (0.25, 0.30),
    (0.22, 0.45),
    (0.18, 0.60),
    (0.15, 0.82)
]


# =====================================================
# WIFI
# =====================================================

def connect_wifi():

    print("Connecting to Wokwi WiFi", end="")

    wifi = network.WLAN(network.STA_IF)

    wifi.active(True)

    wifi.connect(
        "Wokwi-GUEST",
        ""
    )

    while not wifi.isconnected():

        print(".", end="")

        time.sleep(0.2)

    print()

    print("WiFi connected")

    print(
        "ESP32 IP:",
        wifi.ifconfig()[0]
    )


# =====================================================
# RSSI SIMULATION
# =====================================================

def calculate_rssi(
    user_x,
    user_y,
    beacon_x,
    beacon_y
):

    distance = math.sqrt(
        (user_x - beacon_x) ** 2 +
        (user_y - beacon_y) ** 2
    )

    # Avoid division/log problems
    distance = max(
        distance,
        0.03
    )

    # Simple indoor signal model
    rssi = (
        -40
        - 25 * math.log10(
            distance / 0.03
        )
    )

    # Limit signal range
    rssi = max(
        -95,
        min(-35, rssi)
    )

    return int(rssi)


# =====================================================
# CREATE BLE SCAN DATA
# =====================================================

def scan_beacons(
    user_x,
    user_y
):

    detected = []

    for beacon_id, position in beacons.items():

        rssi = calculate_rssi(
            user_x,
            user_y,
            position[0],
            position[1]
        )

        detected.append({
            "id": beacon_id,
            "rssi": rssi
        })

    return detected


# =====================================================
# SEND BLE DATA TO BACKEND
# =====================================================

def send_detection(
    user_x,
    user_y
):

    detected = scan_beacons(
        user_x,
        user_y
    )

    payload = {
        "device_id": DEVICE_ID,
        "beacons": detected
    }

    print()
    print("===================================")
    print("SIMULATED BLE SCAN")
    print(
        "User:",
        round(user_x, 3),
        round(user_y, 3)
    )
    print("===================================")

    for beacon in detected:

        print(
            beacon["id"],
            "RSSI:",
            beacon["rssi"]
        )

    try:

        response = urequests.post(
            BACKEND_URL,
            headers={
                "Content-Type":
                    "application/json"
            },
            data=json.dumps(payload)
        )

        print()
        print(
            "Backend response:"
        )

        print(
            response.text
        )

        response.close()

    except Exception as error:

        print()
        print(
            "HTTP ERROR:",
            error
        )


# =====================================================
# START
# =====================================================

print(
    "==================================="
)

print(
    "INDOOR NAVIGATION BLE SIMULATOR"
)

print(
    "==================================="
)

connect_wifi()


# =====================================================
# SIMULATE USER WALKING
# =====================================================

while True:

    for i in range(
        len(walk_path) - 1
    ):

        start = walk_path[i]

        end = walk_path[i + 1]

        # Interpolate between two points
        # instead of jumping instantly

        steps = 8

        for step in range(
            steps + 1
        ):

            t = step / steps

            user_x = (
                start[0]
                +
                (end[0] - start[0])
                * t
            )

            user_y = (
                start[1]
                +
                (end[1] - start[1])
                * t
            )

            send_detection(
                user_x,
                user_y
            )

            time.sleep(1)