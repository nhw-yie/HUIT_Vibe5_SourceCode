import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:status_air/features/map/presentation/widgets/address_search_field.dart';

class PollutionMapPage extends StatefulWidget {
  const PollutionMapPage({super.key});

  @override
  State<PollutionMapPage> createState() => _PollutionMapPageState();
}

class _PollutionMapPageState extends State<PollutionMapPage> {
  final MapController _mapController = MapController();
  LatLng _currentCenter = const LatLng(10.7725, 106.7000);
  double _currentZoom = 14.0;

  bool _showRouteForm = false;
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();

  LatLng? _startLatLng;
  LatLng? _endLatLng;
  List<LatLng> _routePoints = [];

  List<Polygon> _gridPolygons = [];
  final String _mapboxToken = "API_TOKEN"; // 🔑 thay bằng token

  @override
  void initState() {
    super.initState();
    _goToCurrentLocation();
  }

  Future<void> _goToCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition();
    _currentCenter = LatLng(position.latitude, position.longitude);

    setState(() {
      _gridPolygons = _buildGridPolygons(_currentCenter, _currentZoom);
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      _mapController.move(_currentCenter, _currentZoom);
    });
  }

  void _zoom(double delta) {
    _currentZoom = (_currentZoom + delta).clamp(5.0, 18.0);
    _mapController.move(_currentCenter, _currentZoom);
    setState(() {
      _gridPolygons = _buildGridPolygons(_currentCenter, _currentZoom);
    });
  }

  void _toggleRouteForm() {
    setState(() {
      _showRouteForm = !_showRouteForm;
    });
  }

  /// 🔥 Sinh heatmap grid quanh vị trí hiện tại (1km²/ô)
  List<Polygon> _buildGridPolygons(LatLng center, double zoom) {
    double step = 0.009; // ~1km theo lat/lng (HCM)
    double radius = 0.03; // ~3km quanh user
    List<Polygon> polygons = [];

    for (
      double lat = center.latitude - radius;
      lat < center.latitude + radius;
      lat += step
    ) {
      for (
        double lng = center.longitude - radius;
        lng < center.longitude + radius;
        lng += step
      ) {
        // Fake AQI (demo)
        int aqi = 30 + (lat * lng * 1000).toInt().abs() % 200;

        Color color =
            aqi <= 50
                ? Colors.green
                : aqi <= 100
                ? Colors.yellow
                : aqi <= 150
                ? Colors.orange
                : Colors.red;

        polygons.add(
          Polygon(
            points: [
              LatLng(lat, lng),
              LatLng(lat + step, lng),
              LatLng(lat + step, lng + step),
              LatLng(lat, lng + step),
            ],
            color: color.withOpacity(0.45),
            borderColor: Colors.transparent,
          ),
        );
      }
    }
    return polygons;
  }

  Future<void> _fetchRoute() async {
    if (_startLatLng == null || _endLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng chọn cả điểm xuất phát và điểm đến"),
        ),
      );
      return;
    }

    final url =
        'https://api.mapbox.com/directions/v5/mapbox/driving/'
        '${_startLatLng!.longitude},${_startLatLng!.latitude};'
        '${_endLatLng!.longitude},${_endLatLng!.latitude}'
        '?alternatives=true&geometries=geojson&overview=full'
        '&access_token=$_mapboxToken';

    try {
      final res = await http.get(Uri.parse(url));
      final data = json.decode(res.body);

      if (data['routes'] != null && data['routes'].isNotEmpty) {
        List<dynamic> routes = data['routes'];
        List<Map<String, dynamic>> routeOptions = [];

        for (var route in routes) {
          final coords = route['geometry']['coordinates'] as List;
          List<LatLng> latlngRoute =
              coords
                  .map((e) => LatLng(e[1] as double, e[0] as double))
                  .toList();

          // Fake AQI trung bình
          double avgAQI = 50 + (latlngRoute.length % 150).toDouble();

          routeOptions.add({
            'route': latlngRoute,
            'avgAQI': avgAQI,
            'duration': (route['duration'] / 60).toStringAsFixed(1),
            'distance': (route['distance'] / 1000).toStringAsFixed(1),
          });
        }

        // ✅ BottomSheet chọn tuyến
        final selected = await showModalBottomSheet<int>(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Chọn tuyến đường",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: routeOptions.length,
                      itemBuilder: (context, index) {
                        double avgAQI = routeOptions[index]['avgAQI'];
                        String label =
                            avgAQI <= 100
                                ? "Tốt"
                                : avgAQI <= 150
                                ? "Trung bình"
                                : "Ô nhiễm";
                        Color color =
                            avgAQI <= 100
                                ? Colors.green
                                : avgAQI <= 150
                                ? Colors.orange
                                : Colors.red;
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: color,
                              child: Text(
                                avgAQI.toStringAsFixed(0),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              "Tuyến ${index + 1} - ${routeOptions[index]['distance']} km",
                            ),
                            subtitle: Text(
                              "${routeOptions[index]['duration']} phút • AQI: $label",
                            ),
                            onTap: () => Navigator.pop(context, index),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );

        if (selected != null) {
          setState(() {
            _routePoints = routeOptions[selected]['route'];
            _showRouteForm = false;
            _mapController.move(_startLatLng!, _currentZoom);
          });
        }
      }
    } catch (e) {
      print("Lỗi khi lấy đường: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản đồ ô nhiễm'),
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: _currentZoom,
              onPositionChanged: (pos, _) {
                if (pos.center != null) {
                  _currentCenter = pos.center!;
                  _currentZoom = pos.zoom;
                  setState(() {
                    _gridPolygons = _buildGridPolygons(
                      _currentCenter,
                      _currentZoom,
                    );
                  });
                }
              },
              onMapReady: () {
                _mapController.move(_currentCenter, _currentZoom);
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}",
                additionalOptions: {
                  "accessToken": _mapboxToken,
                  "id": "mapbox/streets-v11",
                },
                userAgentPackageName: 'com.example.status_air',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentCenter,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.blue,
                      size: 40,
                    ),
                  ),
                ],
              ),
              PolygonLayer(polygons: _gridPolygons),
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
          ),

          // ---------- Form tìm đường ----------
          if (_showRouteForm)
            Positioned(
              top: 20,
              left: 15,
              right: 15,
              child: Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 12,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Tìm đường đi",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed:
                                () => setState(() {
                                  _showRouteForm = false;
                                }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      AddressSearchField(
                        controller: _startController,
                        labelText: "Điểm xuất phát",
                        prefixIcon: const Icon(
                          Icons.location_on,
                          color: Colors.blue,
                        ),
                        onSelected: (lat, lng) {
                          _startLatLng = LatLng(lat, lng);
                        },
                      ),
                      const SizedBox(height: 12),
                      AddressSearchField(
                        controller: _endController,
                        labelText: "Điểm đến",
                        prefixIcon: const Icon(Icons.flag, color: Colors.green),
                        onSelected: (lat, lng) {
                          _endLatLng = LatLng(lat, lng);
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _fetchRoute,
                        icon: const Icon(Icons.directions),
                        label: const Text("Tìm đường"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          minimumSize: const Size.fromHeight(45),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ---------- Nút tìm đường ----------
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton.extended(
              onPressed: _toggleRouteForm,
              backgroundColor: Colors.orange,
              icon: const Icon(Icons.directions),
              label: const Text("Tìm đường"),
            ),
          ),
        ],
      ),
    );
  }
}
