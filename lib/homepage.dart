import 'dart:developer';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:math' as math;
import 'pokhara_locations.dart';

class HomePage extends StatefulWidget {
  final LatLng currentPosition;
  const HomePage({super.key, required this.currentPosition});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  LatLng? startPoint;
  LatLng? endPoint;
  List<String> _startSuggestions = [];
  List<String> _endSuggestions = [];
  List<LatLng> _routePoints = [];
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    // Delay setting initial location until after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setInitialLocation();
    });
  }

  void _setInitialLocation() {
    _mapController.move(widget.currentPosition, 18.0);
  }

  Future<void> _updatePolyline() async {
    startPoint = await _getLatLngFromAddress(_startController.text);
    endPoint = await _getLatLngFromAddress(_endController.text);

    // Debug prints
    log('Start Point: $startPoint');
    log('End Point: $endPoint');

    if (startPoint != null && endPoint != null) {
      _routePoints = await _fetchRoute(startPoint!, endPoint!);
      _fitMapToRoute();
    } else {
      _routePoints = [];
    }

    setState(() {});
  }

  Future<LatLng?> _getLatLngFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
      }
    } catch (e) {
      log('Error: $e');
    }
    return null;
  }

  Future<List<LatLng>> _fetchRoute(LatLng start, LatLng end) async {
    final url =
        'http://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List coordinates = json['routes'][0]['geometry']['coordinates'];

      return coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();
    }
    return [];
  }

  Future<void> _fetchSuggestions(String query, bool isStart) async {
    if (query.isEmpty) {
      setState(() {
        if (isStart) {
          _startSuggestions = [];
        } else {
          _endSuggestions = [];
        }
      });
      return;
    }
//search the local dataset
    final localSuggestions = pokharaLocations
        .where(
            (location) => location.toLowerCase().contains(query.toLowerCase()))
        .toList();
    // Define the bounding box for Pokhara
    const String pokharaViewbox = '83.9582,28.2846,84.1116,28.2669';

    final url =
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=5&viewbox=$pokharaViewbox&bounded=1';
// If no local suggestions, query Nominatim API
    if (localSuggestions.isEmpty) {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final apiSuggestions = (json as List)
            .map((item) => item['display_name'] as String)
            .toList();

        setState(() {
          if (isStart) {
            _startSuggestions = apiSuggestions;
          } else {
            _endSuggestions = apiSuggestions;
          }
        });
        return;
      }
    }

    // Use local suggestions if available
    setState(() {
      if (isStart) {
        _startSuggestions = localSuggestions;
      } else {
        _endSuggestions = localSuggestions;
      }
    });
  }

  void _fitMapToRoute() {
    if (_routePoints.isEmpty || startPoint == null || endPoint == null) return;

    // Create bounds including start, end points and route points
    List<LatLng> allPoints = [
      ..._routePoints,
      if (startPoint != null) startPoint!,
      if (endPoint != null) endPoint!,
    ];

    LatLngBounds bounds = LatLngBounds.fromPoints(allPoints);

    // Calculate center and zoom level
    LatLng center = bounds.center;
    double zoom = _calculateZoom(bounds);

    // Move map to calculated center and zoom
    _mapController.move(center, zoom);
  }

  double _calculateZoom(LatLngBounds bounds) {
    const double maxZoom = 18.0; // Adjust as needed
    const double minZoom = 2.0; // Adjust as needed
    const double paddingFactor = 1.2; // Adjust padding around bounds

    double mapWidth = MediaQuery.of(context).size.width;
    double mapHeight = MediaQuery.of(context).size.height;

    double west = bounds.west;
    double east = bounds.east;
    double north = bounds.north;
    double south = bounds.south;

    double deltaX = (east - west).abs();
    double deltaY = (north - south).abs();

    double zoomX = (mapWidth / deltaX) / paddingFactor;
    double zoomY = (mapHeight / deltaY) / paddingFactor;

    double zoom = math.log(math.min(zoomX, zoomY)) / math.log(2);

    return math.min(math.max(zoom, minZoom), maxZoom);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Pokhara Bus Routes',
          style: TextStyle(fontSize: 22, color: Colors.green),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _startController,
                  cursorColor: Colors.green,
                  style: const TextStyle(
                      color: Colors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    labelText: 'Start Location',
                    labelStyle: TextStyle(color: Colors.green),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green),
                    ),
                  ),
                  onChanged: (query) => _fetchSuggestions(query, true),
                  onSubmitted: (_) => _updatePolyline(),
                ),
                _startSuggestions.isNotEmpty
                    ? ListView.builder(
                        shrinkWrap: true,
                        itemCount: _startSuggestions.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(_startSuggestions[index]),
                            onTap: () {
                              _startController.text = _startSuggestions[index];
                              _updatePolyline();
                              setState(() {
                                _startSuggestions = [];
                              });
                            },
                          );
                        },
                      )
                    : Container(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _endController,
                  cursorColor: Colors.green,
                  style: const TextStyle(
                      color: Colors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    labelText: 'Destination Location',
                    labelStyle: TextStyle(color: Colors.green),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green),
                    ),
                  ),
                  onChanged: (query) => _fetchSuggestions(query, false),
                  onSubmitted: (_) => _updatePolyline(),
                ),
                _endSuggestions.isNotEmpty
                    ? ListView.builder(
                        shrinkWrap: true,
                        itemCount: _endSuggestions.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(_endSuggestions[index]),
                            onTap: () {
                              _endController.text = _endSuggestions[index];
                              _updatePolyline();
                              setState(() {
                                _endSuggestions = [];
                              });
                            },
                          );
                        },
                      )
                    : Container(),
              ],
            ),
          ),
          Expanded(child: content()),
        ],
      ),
    );
  }

  Widget content() {
    List<Marker> markers = [];
    if (startPoint != null) {
      markers.add(
        Marker(
          point: startPoint!,
          width: 60,
          height: 60,
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () {},
            child: const Icon(
              Icons.location_pin,
              color: Colors.green,
              size: 60,
            ),
          ),
        ),
      );
    }

    if (endPoint != null) {
      markers.add(
        Marker(
          point: endPoint!,
          width: 60,
          height: 60,
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () {},
            child: const Icon(
              Icons.location_pin,
              color: Colors.red,
              size: 60,
            ),
          ),
        ),
      );
    }

    markers.add(
      Marker(
        point: widget.currentPosition,
        width: 60,
        height: 60,
        alignment: Alignment.center,
        child: const Icon(
          Icons.my_location,
          color: Colors.blue,
          size: 30,
        ),
      ),
    );

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: widget.currentPosition,
        initialZoom: 18,
        interactionOptions: const InteractionOptions(
          flags: ~InteractiveFlag.doubleTapZoom,
        ),
      ),
      children: [
        openStreetMapTileLayer,
        MarkerLayer(markers: markers),
        if (_routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _routePoints,
                strokeWidth: 4.0,
                color: Colors.blue,
              ),
            ],
          ),
      ],
    );
  }

  TileLayer get openStreetMapTileLayer => TileLayer(
        urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'dev.fleaflet.flutter_map.example',
      );
}
