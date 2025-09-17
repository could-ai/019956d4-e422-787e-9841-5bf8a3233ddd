import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Position App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Dummy data for positions
  final LatLng _livePosition = const LatLng(59.334591, 18.063240); // Stockholm center
  final List<LatLng> _stationaryPositions = [
    const LatLng(59.3293, 18.0686), // Gamla Stan
    const LatLng(59.3326, 18.0645), // Royal Palace
    const LatLng(59.3498, 18.0685), // Vasastan
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Karta'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: _livePosition,
          initialZoom: 13.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.app',
          ),
          MarkerLayer(
            markers: [
              // Live position marker
              Marker(
                width: 80.0,
                height: 80.0,
                point: _livePosition,
                child: const Column(
                  children: [
                    Icon(Icons.location_on, color: Colors.blue, size: 40.0),
                    Text('Live', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              // Stationary position markers
              ..._stationaryPositions.map((pos) => Marker(
                width: 80.0,
                height: 80.0,
                point: pos,
                child: const Column(
                  children: [
                    Icon(Icons.pin_drop, color: Colors.red, size: 40.0),
                    Text('Ständig', style: TextStyle(color: Colors.red)),
                  ],
                ),
              )),
            ],
          ),
        ],
      ),
    );
  }
}
