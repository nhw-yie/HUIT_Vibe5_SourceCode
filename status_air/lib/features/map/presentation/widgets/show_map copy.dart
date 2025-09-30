import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:status_air/features/map/presentation/widgets/address_search_field.dart';
import 'package:status_air/features/map/presentation/widgets/aqi_gird_cell.dart';
import 'package:status_air/features/map/presentation/widgets/data_index_aqi.dart';

// ---------------- PollutionMapPage ----------------
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
    setState(() {});

    Future.delayed(const Duration(milliseconds: 100), () {
      _mapController.move(_currentCenter, _currentZoom);
    });
  }

  void _zoom(double delta) {
    _currentZoom = (_currentZoom + delta).clamp(5.0, 18.0);
    _mapController.move(_currentCenter, _currentZoom);
    setState(() {});
  }

  void _toggleRouteForm() {
    setState(() {
      _showRouteForm = !_showRouteForm;
    });
  }

  List<Polygon> _buildGridPolygons() {
    return manualAQIData.map((cell) {
      return Polygon(
        points: [
          LatLng(cell.latTop, cell.lngLeft),
          LatLng(cell.latTop, cell.lngRight),
          LatLng(cell.latBottom, cell.lngRight),
          LatLng(cell.latBottom, cell.lngLeft),
        ],
        color: cell.color.withOpacity(0.6),
        borderColor: Colors.transparent,
        borderStrokeWidth: 0,
      );
    }).toList();
  }

  Future<void> _fetchRoute() async {
  if (_startLatLng == null || _endLatLng == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Vui lòng chọn cả điểm xuất phát và điểm đến")),
    );
    return;
  }

  final url =
      'https://api.mapbox.com/directions/v5/mapbox/driving/'
      '${_startLatLng!.longitude},${_startLatLng!.latitude};'
      '${_endLatLng!.longitude},${_endLatLng!.latitude}'
      '?alternatives=true&geometries=geojson&overview=full'
      '&access_token=pk.API_TOKEN';

  try {
    final res = await http.get(Uri.parse(url));
    final data = json.decode(res.body);

    if (data['routes'] != null && data['routes'].isNotEmpty) {
      List<dynamic> routes = data['routes'];

      List<Map<String, dynamic>> routeOptions = [];

      for (var route in routes) {
        final coords = route['geometry']['coordinates'] as List;
        List<LatLng> latlngRoute =
            coords.map((e) => LatLng(e[1] as double, e[0] as double)).toList();

        // Tính AQI trung bình
        double totalAQI = 0;
        int count = 0;
        for (var point in latlngRoute) {
          AQIGridCell? cell;
          for (var c in manualAQIData) {
            if (point.latitude <= c.latTop &&
                point.latitude >= c.latBottom &&
                point.longitude >= c.lngLeft &&
                point.longitude <= c.lngRight) {
              cell = c;
              break;
            }
          }
          if (cell != null) {
            totalAQI += cell.aqi;
            count++;
          }
        }
        double avgAQI = count > 0 ? totalAQI / count : 0;

        routeOptions.add({
          'route': latlngRoute,
          'avgAQI': avgAQI,
          'duration': (route['duration'] / 60).toStringAsFixed(1), // phút
          'distance': (route['distance'] / 1000).toStringAsFixed(1), // km
        });
      }

      // ✅ Hiển thị bottom sheet đẹp hơn
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
                Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
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
                      String label = avgAQI <= 100
                          ? "Tốt"
                          : avgAQI <= 150
                              ? "Trung bình"
                              : "Ô nhiễm";

                      Color color = avgAQI <= 100
                          ? Colors.green
                          : avgAQI <= 150
                              ? Colors.orange
                              : Colors.red;

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
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
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                              "${routeOptions[index]['duration']} phút • AQI: $label"),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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

      // Vẽ tuyến người dùng chọn
      if (selected != null) {
        setState(() {
          _routePoints = routeOptions[selected]['route'];
          _showRouteForm = false;
          _mapController.move(_startLatLng!, _currentZoom);
        });
      }
    }
  } catch (e) {
    print("Lỗi khi lấy đường từ Mapbox: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Lấy đường đi thất bại")),
    );
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
                }
              },
              onMapReady: () {
                _mapController.move(_currentCenter, _currentZoom);
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c'],
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
              PolygonLayer(polygons: _buildGridPolygons()),
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
                            'Tìm đường đi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _showRouteForm = false;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Điểm xuất phát
                      AddressSearchField(
                        controller: _startController,
                        labelText: 'Điểm xuất phát',
                        prefixIcon: const Icon(
                          Icons.location_on,
                          color: Colors.blue,
                        ),
                        onSelected: (lat, lng) {
                          setState(() {
                            _startLatLng = LatLng(lat, lng);
                          });
                        },
                      ),

                      const SizedBox(height: 12),

                      // Điểm đến
                      AddressSearchField(
                        controller: _endController,
                        labelText: 'Điểm đến',
                        prefixIcon: const Icon(Icons.flag, color: Colors.green),
                        onSelected: (lat, lng) {
                          setState(() {
                            _endLatLng = LatLng(lat, lng);
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _fetchRoute,
                              icon: const Icon(Icons.directions),
                              label: const Text('Tìm đường'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _showRouteForm = false;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: const Text('Thoát'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ---------- Nút chức năng ----------
          Positioned(
            right: 10,
            bottom: 50,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: "zoom_in",
                  onPressed: () => _zoom(1),
                  mini: true,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: "zoom_out",
                  onPressed: () => _zoom(-1),
                  mini: true,
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: "current_location",
                  onPressed: _goToCurrentLocation,
                  mini: true,
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: "route_form",
                  onPressed: _toggleRouteForm,
                  mini: true,
                  child: const Icon(Icons.directions),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
