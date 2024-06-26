import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:openstreetmap/homepage.dart';
import 'package:openstreetmap/locationservices.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OpenStreetMap',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.green),
        useMaterial3: true,
      ),
      home: const LocationPermissionHandler(),
    );
  }
}

class LocationPermissionHandler extends StatelessWidget {
  const LocationPermissionHandler({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Position?>(
      future: LocationService().getCurrentLocation(),
      builder: (context, AsyncSnapshot<Position?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else {
          if (snapshot.hasData && snapshot.data != null) {
            // Convert Position to LatLng
            LatLng currentPosition = LatLng(
              snapshot.data!.latitude,
              snapshot.data!.longitude,
            );

            // Navigate to home page with the obtained location
            return HomePage(currentPosition: currentPosition);
          } else {
            // Handle case where location couldn't be retrieved
            return const Scaffold(
              body: Center(
                child: Text('Unable to fetch current location'),
              ),
            );
          }
        }
      },
    );
  }
}
