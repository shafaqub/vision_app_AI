class BeaconLocation {
  final String id;
  final String name;
  final double x;
  final double y;

  const BeaconLocation({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
  });
}

const beaconLocations = [
  BeaconLocation(
    id: 'BEACON_OUTSIDE',
    name: 'OUTSIDE',
    x: 0.15,
    y: 0.82,
  ),
  BeaconLocation(
    id: 'BEACON_LAB',
    name: 'LAB',
    x: 0.27,
    y: 0.20,
  ),
  BeaconLocation(
    id: 'BEACON_STAIRS',
    name: 'STAIRS',
    x: 0.73,
    y: 0.20,
  ),
  BeaconLocation(
    id: 'BEACON_WASHROOM',
    name: 'WASHROOM',
    x: 0.73,
    y: 0.79,
  ),
  BeaconLocation(
    id: 'BEACON_CENTER_LEFT',
    name: 'CENTER L',
    x: 0.38,
    y: 0.50,
  ),
  BeaconLocation(
    id: 'BEACON_CENTER_RIGHT',
    name: 'CENTER R',
    x: 0.62,
    y: 0.50,
  ),
];