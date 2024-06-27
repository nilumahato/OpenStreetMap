import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class BusRouteScreen extends StatelessWidget {
  final List<LatLng> routePoints;
  const BusRouteScreen({super.key, required this.routePoints});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Route'),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: routePoints.first,
          initialZoom: 14,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'dev.fleaflet.flutter_map.example',
          ),
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints,
                strokeWidth: 4.0,
                color: Colors.blue,
              ),
            ],
          ),
          MarkerLayer(
            markers: [
              Marker(
                width: 80.0,
                height: 80.0,
                point: routePoints.first,
                child: const Icon(
                  Icons.location_on,
                  size: 50,
                  color: Colors.red,
                ),
              ),
              Marker(
                width: 80.0,
                height: 80.0,
                point: routePoints.last,
                child: const Icon(
                  Icons.location_on,
                  size: 50,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
