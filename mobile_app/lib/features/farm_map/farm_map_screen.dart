import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

const Color kEmerald = Color(0xFF10B981);

class FarmMapScreen extends StatefulWidget {
  const FarmMapScreen({super.key});

  @override
  State<FarmMapScreen> createState() => _FarmMapScreenState();
}

class _FarmMapScreenState extends State<FarmMapScreen> {
  // Agricultural plot coordinates (Delhi NCR / Ghaziabad farming belt)
  final LatLng _farmCenter = const LatLng(28.6692, 77.4538);
  final List<LatLng> _fieldPolygon = const [
    LatLng(28.6705, 77.4525),
    LatLng(28.6710, 77.4550),
    LatLng(28.6680, 77.4555),
    LatLng(28.6675, 77.4530),
  ];

  String _currentLayer = "satellite"; // "satellite" or "osm"

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Farm Map & Field Boundary", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _currentLayer == "satellite" ? Icons.map : Icons.satellite_alt_rounded,
              color: kEmerald,
            ),
            onPressed: () {
              setState(() {
                _currentLayer = _currentLayer == "satellite" ? "osm" : "satellite";
              });
            },
            tooltip: "Toggle Map Layer",
          ),
        ],
      ),
      body: Stack(
        children: [
          // Flutter Map View
          FlutterMap(
            options: MapOptions(
              initialCenter: _farmCenter,
              initialZoom: 15.5,
            ),
            children: [
              TileLayer(
                urlTemplate: _currentLayer == "satellite"
                    ? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png' // OpenStreetMap Tile URL
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.smartedge.agriguardian',
              ),
              // Farm Field Boundary Overlay
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: _fieldPolygon,
                    color: kEmerald.withValues(alpha: 0.25),
                    borderColor: kEmerald,
                    borderStrokeWidth: 3,
                  ),
                ],
              ),
              // Farm Center Marker
              MarkerLayer(
                markers: [
                  Marker(
                    point: _farmCenter,
                    width: 45,
                    height: 45,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: kEmerald,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black45, blurRadius: 6),
                        ],
                      ),
                      child: const Icon(Icons.eco, color: Colors.white, size: 26),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Standalone Field Info Card (Bottom Overlay)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kEmerald.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: kEmerald, size: 32),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "AgriGuardian Field Plot #1",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Area: 2.4 Acres • Crop: Tomato & Potato",
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: kEmerald.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kEmerald),
                    ),
                    child: const Text("Healthy", style: TextStyle(color: kEmerald, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}