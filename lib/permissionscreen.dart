import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:openstreetmap/homepage.dart';
import 'package:openstreetmap/locationservices.dart';

class PermissionScreen extends StatelessWidget {
  const PermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            Position? position = await LocationServices.getCurrentLocation();
            if (position != null) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomePage(position: position)),
              );
            }
          },
          child: const Text('Allow Location Access'),
        ),
      ),
    );
  }
}
