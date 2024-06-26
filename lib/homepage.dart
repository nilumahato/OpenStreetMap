import 'dart:developer';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  final Position position;

  const HomePage({required this.position, super.key});

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

  @override
  void initState() {
    super.initState();
    // Optionally, you could use the initial position here
  }

  Future<void> _updatePolyline() async {
    startPoint = await _getLatLngFromAddress(_startController.text);
    endPoint = await _getLatLngFromAddress(_endController.text);

    // Debug prints
    log('Start Point: $startPoint');
    log('End Point: $endPoint');

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

    // Define the bounding box for Nepal
    const String nepalViewbox = '80.0586,30.4227,88.2015,26.347';

    final url =
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=5&viewbox=$nepalViewbox&bounded=1';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final suggestions =
          (json as List).map((item) => item['display_name'] as String).toList();

      setState(() {
        if (isStart) {
          _startSuggestions = suggestions;
        } else {
          _endSuggestions = suggestions;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Open Street Map in Flutter',
          style: TextStyle(fontSize: 22),
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
                  decoration: const InputDecoration(
                    labelText: 'Start Location (Place Name)',
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
                  decoration: const InputDecoration(
                    labelText: 'End Location (Place Name)',
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

    return FlutterMap(
      options: MapOptions(
        initialCenter:
            LatLng(widget.position.latitude, widget.position.longitude),
        initialZoom: 20,
        interactionOptions: const InteractionOptions(
          flags: ~InteractiveFlag.doubleTapZoom,
        ),
      ),
      children: [
        openStreetMapTileLayer,
        MarkerLayer(markers: markers),
        if (startPoint != null && endPoint != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [startPoint!, endPoint!],
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
