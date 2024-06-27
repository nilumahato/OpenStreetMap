// ignore_for_file: use_build_context_synchronously

import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:csv/csv.dart';
import 'package:openstreetmap/views/busroutesscreen.dart';

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
  List<Map<String, dynamic>> busRoutes = [];
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setInitialLocation();
      _loadBusRoutes();
    });
  }

  Future<void> _loadBusRoutes() async {
    final data = await DefaultAssetBundle.of(context)
        .loadString("assets/bus_routes.csv");
    final List<List<dynamic>> csvTable =
        const CsvToListConverter().convert(data);

    List<Map<String, dynamic>> loadedRoutes = [];

    for (int i = 1; i < csvTable.length; i++) {
      final row = csvTable[i];
      loadedRoutes.add({
        "route_id": row[0],
        "route_name": row[1],
        "stops": row[2].split(',').map((e) => e.trim()).toList(),
        "coordinates": row[3]
            .split('),(')
            .map((coord) => coord.replaceAll(RegExp(r'[\(\)]'), '').split(','))
            .map((pair) => LatLng(double.parse(pair[0]), double.parse(pair[1])))
            .toList(),
      });
    }

    setState(() {
      busRoutes = loadedRoutes;
    });
  }

  void _setInitialLocation() {
    _mapController.move(widget.currentPosition, 18.0);
  }

  Future<List<Map<String, dynamic>>> _findMatchingRoutes(
      String start, String end) async {
    List<Map<String, dynamic>> matchingRoutes = [];

    for (var route in busRoutes) {
      List<String> stops = List<String>.from(route["stops"]);
      if (stops.contains(start) && stops.contains(end)) {
        matchingRoutes.add(route);
      }
    }

    return matchingRoutes;
  }

  Future<void> _updatePolyline() async {
    startPoint = await _getLatLngFromAddress(_startController.text);
    endPoint = await _getLatLngFromAddress(_endController.text);

    if (startPoint != null && endPoint != null) {
      List<Map<String, dynamic>> matchingRoutes =
          await _findMatchingRoutes(_startController.text, _endController.text);

      if (matchingRoutes.isNotEmpty) {
        // Convert dynamic list to List<LatLng>
        List<LatLng> routeCoordinates =
            matchingRoutes.first["coordinates"] as List<LatLng>;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BusRoutesScreen(
              startPoint: startPoint!,
              endPoint: endPoint!,
              routePoints: routeCoordinates,
              routes: matchingRoutes,
            ),
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('No Routes Found'),
              content: const Text(
                  'No bus routes found between the selected locations.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Invalid Locations'),
            content: const Text('Please enter valid start and end locations.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  Future<LatLng?> _getLatLngFromAddress(String address) async {
    try {
      List<Location> locations =
          await locationFromAddress('$address, Pokhara, Nepal');
      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
      }
    } catch (e) {
      log('Error fetching location for $address: $e');
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

    Set<String> suggestions = {};

    for (var route in busRoutes) {
      List<String> stops = List<String>.from(route["stops"]);
      for (var stop in stops) {
        if (stop.toLowerCase().contains(query.toLowerCase())) {
          suggestions.add(stop);
          break;
        }
      }
    }

    setState(() {
      if (isStart) {
        _startSuggestions = suggestions.toList();
      } else {
        _endSuggestions = suggestions.toList();
      }
    });
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

// // ignore_for_file: use_build_context_synchronously

// import 'dart:developer';
// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:csv/csv.dart';

// class HomePage extends StatefulWidget {
//   final LatLng currentPosition;
//   const HomePage({Key? key, required this.currentPosition}) : super(key: key);

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   final TextEditingController _startController = TextEditingController();
//   final TextEditingController _endController = TextEditingController();
//   LatLng? startPoint;
//   LatLng? endPoint;
//   List<String> _startSuggestions = [];
//   List<String> _endSuggestions = [];
//   List<LatLng> _routePoints = [];
//   List<Map<String, dynamic>> busRoutes = [];
//   final MapController _mapController = MapController();

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _setInitialLocation();
//       _loadBusRoutes();
//     });
//   }

//   Future<void> _loadBusRoutes() async {
//     final data = await DefaultAssetBundle.of(context)
//         .loadString("assets/bus_routes.csv");
//     final List<List<dynamic>> csvTable =
//         const CsvToListConverter().convert(data);

//     List<Map<String, dynamic>> loadedRoutes = [];

//     for (int i = 1; i < csvTable.length; i++) {
//       final row = csvTable[i];
//       loadedRoutes.add({
//         "route_id": row[0],
//         "route_name": row[1],
//         "stops": (row[2] as String).split(',').map((e) => e.trim()).toList(),
//         "coordinates": (row[3] as String)
//             .split('),(')
//             .map((coord) => coord.replaceAll(RegExp(r'[\(\)]'), '').split(','))
//             .map((pair) => LatLng(double.parse(pair[0]), double.parse(pair[1])))
//             .toList(),
//       });
//     }

//     setState(() {
//       busRoutes = loadedRoutes;
//     });

//     // For debugging purposes, print loaded bus routes
//     for (var route in busRoutes) {
//       log('Route: ${route["route_name"]}, Stops: ${route["stops"]}');
//     }
//   }

//   void _setInitialLocation() {
//     _mapController.move(widget.currentPosition, 18.0);
//   }

//   Future<void> _updatePolyline() async {
//     startPoint = await _getLatLngFromAddress(_startController.text);
//     endPoint = await _getLatLngFromAddress(_endController.text);

//     if (startPoint != null && endPoint != null) {
//       List<Map<String, dynamic>> matchingRoutes =
//           await _findMatchingRoutes(_startController.text, _endController.text);

//       if (matchingRoutes.isNotEmpty) {
//         List<LatLng> routeCoordinates = _getRouteCoordinates(
//           matchingRoutes.first["stops"] as List<String>,
//           matchingRoutes.first["coordinates"] as List<LatLng>,
//           _startController.text,
//           _endController.text,
//         );

//         setState(() {
//           _routePoints = routeCoordinates;
//         });
//       } else {
//         showDialog(
//           context: context,
//           builder: (BuildContext context) {
//             return AlertDialog(
//               title: const Text('No Routes Found'),
//               content: const Text(
//                   'No bus routes found between the selected locations.'),
//               actions: <Widget>[
//                 TextButton(
//                   child: const Text('OK'),
//                   onPressed: () {
//                     Navigator.of(context).pop();
//                   },
//                 ),
//               ],
//             );
//           },
//         );
//       }
//     } else {
//       showDialog(
//         context: context,
//         builder: (BuildContext context) {
//           return AlertDialog(
//             title: const Text('Invalid Locations'),
//             content: const Text('Please enter valid start and end locations.'),
//             actions: <Widget>[
//               TextButton(
//                 child: const Text('OK'),
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                 },
//               ),
//             ],
//           );
//         },
//       );
//     }
//   }

//   Future<LatLng?> _getLatLngFromAddress(String address) async {
//     try {
//       List<Location> locations =
//           await locationFromAddress('$address, Pokhara, Nepal');
//       if (locations.isNotEmpty) {
//         return LatLng(locations.first.latitude, locations.first.longitude);
//       }
//     } catch (e) {
//       log('Error fetching location for $address: $e');
//     }
//     return null;
//   }

//   Future<void> _fetchSuggestions(String query, bool isStart) async {
//     if (query.isEmpty) {
//       setState(() {
//         if (isStart) {
//           _startSuggestions = [];
//         } else {
//           _endSuggestions = [];
//         }
//       });
//       return;
//     }

//     Set<String> suggestions = {};

//     for (var route in busRoutes) {
//       List<String> stops = List<String>.from(route["stops"]);
//       for (var stop in stops) {
//         if (stop.toLowerCase().contains(query.toLowerCase())) {
//           suggestions.add(stop);
//           break;
//         }
//       }
//     }

//     setState(() {
//       if (isStart) {
//         _startSuggestions = suggestions.toList();
//       } else {
//         _endSuggestions = suggestions.toList();
//       }
//     });
//   }

//   Future<List<Map<String, dynamic>>> _findMatchingRoutes(
//       String start, String end) async {
//     List<Map<String, dynamic>> matchingRoutes = [];

//     for (var route in busRoutes) {
//       List<String> stops = List<String>.from(route["stops"]);
//       if (stops.contains(start) && stops.contains(end)) {
//         matchingRoutes.add(route);
//       }
//     }

//     return matchingRoutes;
//   }

//   List<LatLng> _getRouteCoordinates(
//       List<String> stops, List<LatLng> coordinates, String start, String end) {
//     int startIndex = stops.indexOf(start);
//     int endIndex = stops.indexOf(end);
//     if (startIndex < 0 || endIndex < 0 || startIndex >= endIndex) {
//       return [];
//     }
//     return coordinates.sublist(startIndex, endIndex + 1);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: const Text(
//           'Pokhara Bus Routes',
//           style: TextStyle(fontSize: 22, color: Colors.green),
//         ),
//       ),
//       body: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Column(
//               children: [
//                 TextField(
//                   controller: _startController,
//                   cursorColor: Colors.green,
//                   style: const TextStyle(
//                       color: Colors.green,
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold),
//                   decoration: const InputDecoration(
//                     labelText: 'Start Location',
//                     labelStyle: TextStyle(color: Colors.green),
//                     focusedBorder: OutlineInputBorder(
//                       borderSide: BorderSide(color: Colors.green),
//                     ),
//                     enabledBorder: OutlineInputBorder(
//                       borderSide: BorderSide(color: Colors.green),
//                     ),
//                   ),
//                   onChanged: (query) => _fetchSuggestions(query, true),
//                   onSubmitted: (_) => _updatePolyline(),
//                 ),
//                 _startSuggestions.isNotEmpty
//                     ? ListView.builder(
//                         shrinkWrap: true,
//                         itemCount: _startSuggestions.length,
//                         itemBuilder: (context, index) {
//                           return ListTile(
//                             title: Text(_startSuggestions[index]),
//                             onTap: () {
//                               _startController.text = _startSuggestions[index];
//                               _updatePolyline();
//                               setState(() {
//                                 _startSuggestions = [];
//                               });
//                             },
//                           );
//                         },
//                       )
//                     : Container(),
//               ],
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Column(
//               children: [
//                 TextField(
//                   controller: _endController,
//                   cursorColor: Colors.green,
//                   style: const TextStyle(
//                       color: Colors.green,
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold),
//                   decoration: const InputDecoration(
//                     labelText: 'Destination Location',
//                     labelStyle: TextStyle(color: Colors.green),
//                     focusedBorder: OutlineInputBorder(
//                       borderSide: BorderSide(color: Colors.green),
//                     ),
//                     enabledBorder: OutlineInputBorder(
//                       borderSide: BorderSide(color: Colors.green),
//                     ),
//                   ),
//                   onChanged: (query) => _fetchSuggestions(query, false),
//                   onSubmitted: (_) => _updatePolyline(),
//                 ),
//                 _endSuggestions.isNotEmpty
//                     ? ListView.builder(
//                         shrinkWrap: true,
//                         itemCount: _endSuggestions.length,
//                         itemBuilder: (context, index) {
//                           return ListTile(
//                             title: Text(_endSuggestions[index]),
//                             onTap: () {
//                               _endController.text = _endSuggestions[index];
//                               _updatePolyline();
//                               setState(() {
//                                 _endSuggestions = [];
//                               });
//                             },
//                           );
//                         },
//                       )
//                     : Container(),
//               ],
//             ),
//           ),
//           Expanded(
//             child: Stack(
//               children: [
//                 content(),
//                 Positioned.fill(
//                   child: Align(
//                     alignment: Alignment.bottomCenter,
//                     child: _routePoints.isNotEmpty
//                         ? Container(
//                             color: Colors.white.withOpacity(0.8),
//                             padding: const EdgeInsets.all(10),
//                             margin: const EdgeInsets.all(10),
//                             child: Column(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Text(
//                                   'Route from ${_startController.text} to ${_endController.text}',
//                                   style: const TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.bold,
//                                     color: Colors.green,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 10),
//                                 Text(
//                                   'Bus Route: ${busRoutes.isNotEmpty ? busRoutes.first["route_name"] : ""}',
//                                   style: const TextStyle(
//                                     fontSize: 14,
//                                     fontWeight: FontWeight.bold,
//                                     color: Colors.blue,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           )
//                         : Container(),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget content() {
//     List<Marker> markers = [];
//     markers.add(
//       Marker(
//         point: widget.currentPosition,
//         width: 60,
//         height: 60,
//         alignment: Alignment.center,
//         child: const Icon(
//           Icons.my_location,
//           color: Colors.blue,
//           size: 30,
//         ),
//       ),
//     );

//     if (_routePoints.isNotEmpty) {
//       markers.addAll([
//         Marker(
//           point: _routePoints.first,
//           width: 60,
//           height: 60,
//           child: const Icon(
//             Icons.location_on,
//             color: Colors.red,
//             size: 30,
//           ),
//         ),
//         Marker(
//           point: _routePoints.last,
//           width: 60,
//           height: 60,
//           child: const Icon(
//             Icons.location_on,
//             color: Colors.red,
//             size: 30,
//           ),
//         ),
//       ]);
//     }

//     return FlutterMap(
//       mapController: _mapController,
//       options: MapOptions(
//         initialCenter: widget.currentPosition,
//         initialZoom: 18,
//         interactionOptions: const InteractionOptions(
//           flags: ~InteractiveFlag.doubleTapZoom,
//         ),
//       ),
//       children: [
//         openStreetMapTileLayer,
//         MarkerLayer(markers: markers),
//         if (_routePoints.isNotEmpty)
//           PolylineLayer(
//             polylines: [
//               Polyline(
//                 points: _routePoints,
//                 strokeWidth: 4.0,
//                 color: Colors.blue,
//               ),
//             ],
//           ),
//       ],
//     );
//   }

//   TileLayer get openStreetMapTileLayer => TileLayer(
//         urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
//         userAgentPackageName: 'dev.fleaflet.flutter_map.example',
//       );
// }
