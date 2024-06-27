// import 'dart:developer';

// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:geocoding/geocoding.dart';
// import 'dart:math' as math;

// class BusRoutesScreen extends StatefulWidget {
//   final LatLng startPoint;
//   final LatLng endPoint;
//   final List<LatLng> routePoints;
//   final List<Map<String, dynamic>> routes;

//   const BusRoutesScreen({
//     super.key,
//     required this.startPoint,
//     required this.endPoint,
//     required this.routePoints,
//     required this.routes,
//   });

//   @override
//   State<BusRoutesScreen> createState() => _BusRoutesScreenState();
// }

// class _BusRoutesScreenState extends State<BusRoutesScreen> {
//   final MapController _mapController = MapController();
//   List<Marker> markers = [];

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _fitMapToRoute();
//       _fetchStopLocations();
//     });
//   }

//   void _fitMapToRoute() {
//     if (widget.routePoints.isEmpty) return;

//     List<LatLng> allPoints = [
//       ...widget.routePoints,
//       widget.startPoint,
//       widget.endPoint,
//     ];

//     LatLngBounds bounds = LatLngBounds.fromPoints(allPoints);
//     LatLng center = bounds.center;
//     double zoom = _calculateZoom(bounds);

//     _mapController.move(center, zoom);
//   }

//   double _calculateZoom(LatLngBounds bounds) {
//     const double maxZoom = 18.0;
//     const double minZoom = 2.0;
//     const double paddingFactor = 1.2;

//     double mapWidth = MediaQuery.of(context).size.width;
//     double mapHeight = MediaQuery.of(context).size.height;

//     double west = bounds.west;
//     double east = bounds.east;
//     double north = bounds.north;
//     double south = bounds.south;

//     double deltaX = (east - west).abs();
//     double deltaY = (north - south).abs();

//     double zoomX = (mapWidth / deltaX) / paddingFactor;
//     double zoomY = (mapHeight / deltaY) / paddingFactor;

//     double zoom = math.log(math.min(zoomX, zoomY)) / math.log(2);

//     return math.min(math.max(zoom, minZoom), maxZoom);
//   }

//   Future<void> _fetchStopLocations() async {
//     List<Marker> markers = [];

//     for (var route in widget.routes) {
//       List<String> routeStops = List<String>.from(route["stops"]);

//       for (var stop in routeStops) {
//         try {
//           List<Location> locations =
//               await locationFromAddress('$stop, Pokhara, Nepal');
//           if (locations.isNotEmpty) {
//             LatLng position =
//                 LatLng(locations.first.latitude, locations.first.longitude);
//             markers.add(
//               Marker(
//                 point: position,
//                 width: 60,
//                 height: 60,
//                 child: const Icon(
//                   Icons.circle,
//                   color: Colors.deepPurple,
//                   size: 60,
//                 ),
//               ),
//             );
//           }
//         } catch (e) {
//           log('Error fetching location for $stop: $e');
//         }
//       }
//     }

//     setState(() {
//       this.markers = markers;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         titleSpacing: 0,
//         title: const Text(
//           'Available Bus Routes',
//           style: TextStyle(fontSize: 22, color: Colors.green),
//         ),
//         iconTheme: const IconThemeData(color: Colors.green),
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Column(
//               children: [
//                 Text(
//                   'Route from ${widget.startPoint} to ${widget.endPoint}',
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.green,
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 if (widget.routes.isNotEmpty)
//                   ...widget.routes.map((route) => Text(
//                         'Bus Route: ${route["route_name"]}',
//                         style: const TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.blue,
//                         ),
//                       )),
//                 const SizedBox(height: 10),
//               ],
//             ),
//           ),
//           Expanded(
//             child: FlutterMap(
//               mapController: _mapController,
//               options: MapOptions(
//                 initialCenter: widget.startPoint,
//                 initialZoom: 18,
//               ),
//               children: [
//                 TileLayer(
//                   urlTemplate:
//                       'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
//                   userAgentPackageName: 'dev.fleaflet.flutter_map.example',
//                 ),
//                 PolylineLayer(
//                   polylines: [
//                     Polyline(
//                       points: widget.routePoints,
//                       strokeWidth: 4.0,
//                       color: Colors.blue,
//                     ),
//                   ],
//                 ),
//                 MarkerLayer(
//                   markers: [
//                     Marker(
//                       point: widget.startPoint,
//                       width: 60,
//                       height: 60,
//                       alignment: Alignment.center,
//                       child: const Icon(
//                         Icons.location_pin,
//                         color: Colors.green,
//                         size: 60,
//                       ),
//                     ),
//                     Marker(
//                       point: widget.endPoint,
//                       width: 60,
//                       height: 60,
//                       alignment: Alignment.center,
//                       child: const Icon(
//                         Icons.location_pin,
//                         color: Colors.red,
//                         size: 60,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:math' as math;

class BusRoutesScreen extends StatefulWidget {
  final LatLng startPoint;
  final LatLng endPoint;
  final List<LatLng> routePoints;
  final List<Map<String, dynamic>> routes;

  const BusRoutesScreen({
    super.key,
    required this.startPoint,
    required this.endPoint,
    required this.routePoints,
    required this.routes,
  });

  @override
  State<BusRoutesScreen> createState() => _BusRoutesScreenState();
}

class _BusRoutesScreenState extends State<BusRoutesScreen> {
  final MapController _mapController = MapController();
  List<Marker> markers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitMapToRoute();
      _fetchStopLocations();
    });
  }

  void _fitMapToRoute() {
    if (widget.routePoints.isEmpty) return;

    List<LatLng> allPoints = [
      ...widget.routePoints,
      widget.startPoint,
      widget.endPoint,
    ];

    LatLngBounds bounds = LatLngBounds.fromPoints(allPoints);
    LatLng center = bounds.center;
    double zoom = _calculateZoom(bounds);

    _mapController.move(center, zoom);
  }

  double _calculateZoom(LatLngBounds bounds) {
    const double maxZoom = 18.0;
    const double minZoom = 2.0;
    const double paddingFactor = 1.2;

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

  Future<void> _fetchStopLocations() async {
    List<Marker> markers = [];

    for (var route in widget.routes) {
      List<String> routeStops = List<String>.from(route["stops"]);

      for (var stop in routeStops) {
        try {
          List<Location> locations =
              await locationFromAddress('$stop, Pokhara, Nepal');
          if (locations.isNotEmpty) {
            LatLng position =
                LatLng(locations.first.latitude, locations.first.longitude);
            markers.add(
              Marker(
                point: position,
                width: 60,
                height: 60,
                child: const Icon(
                  Icons.circle,
                  color: Colors.deepPurple,
                  size: 60,
                ),
              ),
            );
          }
        } catch (e) {
          log('Error fetching location for $stop: $e');
        }
      }
    }

    setState(() {
      this.markers = markers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        titleSpacing: 0,
        title: const Text(
          'Available Bus Routes',
          style: TextStyle(fontSize: 22, color: Colors.green),
        ),
        iconTheme: const IconThemeData(color: Colors.green),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  'Route from ${widget.startPoint} to ${widget.endPoint}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 10),
                if (widget.routes.isNotEmpty)
                  ...widget.routes.map((route) => Text(
                        'Bus Route: ${route["route_name"]}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      )),
                const SizedBox(height: 10),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: widget.startPoint,
                initialZoom: 18,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'dev.fleaflet.flutter_map.example',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: widget.routePoints,
                      strokeWidth: 4.0,
                      color: Colors.blue,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: widget.startPoint,
                      width: 60,
                      height: 60,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.green,
                        size: 60,
                      ),
                    ),
                    Marker(
                      point: widget.endPoint,
                      width: 60,
                      height: 60,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 60,
                      ),
                    ),
                    ...markers,
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
