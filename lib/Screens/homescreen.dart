import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:openstreetmap/Screens/busroutescreen.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class HomeScreen extends StatefulWidget {
  final LatLng currentPosition;
  const HomeScreen({super.key, required this.currentPosition});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  final MapController _mapController = MapController();
  List<Map<String, dynamic>> busRoutes = [];
  Map<String, LatLng> uniquePlaces = {};

  @override
  void initState() {
    super.initState();
    _loadBusRoutes();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setInitialLocation();
    });
  }

  void _setInitialLocation() {
    _mapController.move(widget.currentPosition, 18.0);
  }

  Future<void> _loadBusRoutes() async {
    final data = await rootBundle.loadString('assets/bus_routes.csv');
    List<List<dynamic>> csvTable = const CsvToListConverter().convert(data);

    for (var i = 1; i < csvTable.length; i++) {
      List<dynamic> row = csvTable[i];
      String routeId = row[0].toString();
      String routeName = row[1];
      List<String> stops =
          (row[2] as String).split(',').map((e) => e.trim()).toList();
      List<LatLng> coordinates = (row[3] as String).split(';').map((e) {
        List<String> latlng = e.split(',');
        return LatLng(double.parse(latlng[0]), double.parse(latlng[1]));
      }).toList();

      busRoutes.add({
        'routeId': routeId,
        'routeName': routeName,
        'stops': stops,
        'coordinates': coordinates,
      });

      for (int j = 0; j < stops.length; j++) {
        uniquePlaces[stops[j]] = coordinates[j];
      }
    }
  }

  void _searchRoutes() {
    String start = _startController.text.trim();
    String end = _endController.text.trim();
    for (var route in busRoutes) {
      List<String> stops = List<String>.from(route['stops']);
      if (stops.contains(start) && stops.contains(end)) {
        int startIndex = stops.indexOf(start);
        int endIndex = stops.indexOf(end);
        List<LatLng> routePoints = [];
        for (int i = startIndex; i <= endIndex; i++) {
          routePoints.add(route['coordinates'][i]);
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BusRouteScreen(routePoints: routePoints),
          ),
        );
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Find Pokhara Bus Routes',
          style: TextStyle(fontSize: 22, color: Colors.green),
        ),
        actions: [
          ElevatedButton(
            onPressed: _searchRoutes,
            child: const Text('Find Routes'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TypeAheadFormField(
                  textFieldConfiguration: TextFieldConfiguration(
                    controller: _startController,
                    cursorColor: Colors.green,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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
                  ),
                  suggestionsCallback: (pattern) {
                    return _getUniquePlaceSuggestions(pattern);
                  },
                  itemBuilder: (context, suggestion) {
                    return ListTile(
                      title: Text(suggestion),
                    );
                  },
                  onSuggestionSelected: (suggestion) {
                    _startController.text = suggestion;
                  },
                ),
                const SizedBox(height: 8),
                TypeAheadFormField(
                  textFieldConfiguration: TextFieldConfiguration(
                    controller: _endController,
                    cursorColor: Colors.green,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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
                  ),
                  suggestionsCallback: (pattern) {
                    return _getUniquePlaceSuggestions(pattern);
                  },
                  itemBuilder: (context, suggestion) {
                    return ListTile(
                      title: Text(suggestion),
                    );
                  },
                  onSuggestionSelected: (suggestion) {
                    _endController.text = suggestion;
                  },
                ),
              ],
            ),
          ),
          Expanded(child: content()),
        ],
      ),
    );
  }

  List<String> _getUniquePlaceSuggestions(String pattern) {
    return uniquePlaces.keys
        .where((place) => place.toLowerCase().contains(pattern.toLowerCase()))
        .toList();
  }

  Widget content() {
    List<Marker> markers = [
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
    ];
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
      ],
    );
  }

  TileLayer get openStreetMapTileLayer => TileLayer(
        urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'dev.fleaflet.flutter_map.example',
      );
}
