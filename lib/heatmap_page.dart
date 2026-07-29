import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_heatmap/flutter_map_heatmap.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

class MapDataPoint {
  final double lat;
  final double lng;
  final double hpi;
  final String state;
  final String district;
  final String location;
  final String classification;
  final int year;

  MapDataPoint({
    required this.lat,
    required this.lng,
    required this.hpi,
    required this.state,
    required this.district,
    required this.location,
    required this.classification,
    required this.year,
  });

  factory MapDataPoint.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MapDataPoint(
      lat: (data['latitude'] ?? 0.0).toDouble(),
      lng: (data['longitude'] ?? 0.0).toDouble(),
      hpi: (data['hpi'] ?? 0.0).toDouble(),
      state: data['state']?.toString() ?? '',
      district: data['district']?.toString() ?? '',
      location: data['location']?.toString() ?? '',
      classification: data['classification']?.toString() ?? '',
      year: data['year'] as int? ?? 2023,
    );
  }
}

class HeatmapPage extends StatefulWidget {
  const HeatmapPage({super.key});

  @override
  State<HeatmapPage> createState() => _HeatmapPageState();
}

class _HeatmapPageState extends State<HeatmapPage> {
  List<MapDataPoint> _allData = [];
  List<MapDataPoint> _filteredData = [];
  bool _isLoading = true;
  String _error = '';
  
  double _currentZoom = 5.0;

  // Filters
  String _selectedState = 'ALL';
  List<String> _availableStates = ['ALL'];
  double _minHpi = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('hmpi_calculations')
          .limit(2000)
          .get();

      if (mounted) {
        setState(() {
          _allData = snapshot.docs.map((doc) => MapDataPoint.fromDocument(doc)).toList();
          final states = _allData.map((e) => e.state).where((s) => s.isNotEmpty).toSet().toList();
          states.sort();
          _availableStates = ['ALL', ...states];
          
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredData = _allData.where((item) {
        if (_selectedState != 'ALL' && item.state != _selectedState) return false;
        if (item.hpi < _minHpi) return false;
        if (_searchQuery.isNotEmpty) {
          final locStr = '${item.location} ${item.district} ${item.state}'.toLowerCase();
          if (!locStr.contains(_searchQuery.toLowerCase())) return false;
        }
        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('India Groundwater Heatmap'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.dashboard),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          )
        ],
      ),
      endDrawer: _buildDashboardDrawer(),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blue),
            SizedBox(height: 16),
            Text('Fetching Native Data from Firestore...', style: TextStyle(color: Colors.black54)),
          ],
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error: $_error', style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    // Convert data to native HeatMap format
    final heatPoints = _filteredData.map((d) {
      return WeightedLatLng(
        LatLng(d.lat, d.lng),
        math.min(1.0, d.hpi / 40.0), // intensity mapping
      );
    }).toList();

    // Map to Circle Markers for zooming in
    final markers = _filteredData.map((d) {
      Color color = Colors.orange;
      if (d.hpi < 15) {
        color = Colors.blue;
      } else if (d.hpi <= 30) {
        color = Colors.yellow;
      }

      return CircleMarker(
        point: LatLng(d.lat, d.lng),
        color: color.withValues(alpha: 0.8),
        borderStrokeWidth: 1,
        borderColor: Colors.white,
        radius: 8,
      );
    }).toList();

    return FlutterMap(
      options: MapOptions(
        initialCenter: const LatLng(22.9734, 78.6569),
        initialZoom: 5.0,
        maxZoom: 18.0,
        onPositionChanged: (position, hasGesture) {
          if (position.zoom != _currentZoom) {
            setState(() {
              _currentZoom = position.zoom;
            });
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.hmpi',
        ),
        HeatMapLayer(
          heatMapDataSource: InMemoryHeatMapDataSource(data: heatPoints),
          heatMapOptions: HeatMapOptions(
            // MASSIVE radius to cover the entire country natively
            radius: 120 * math.pow(1.4, math.max(0, _currentZoom - 5)).toDouble(),
            blurFactor: 0.9,
            minOpacity: 0.01, // Near zero so NO area is blank
            gradient: {
              0.01: Colors.blue,
              0.3: Colors.yellow,
              0.8: Colors.orange,
              1.0: Colors.red,
            },
          ),
        ),
        if (_currentZoom >= 9)
          CircleLayer(circles: markers),
      ],
    );
  }

  Widget _buildDashboardDrawer() {
    return Drawer(
      backgroundColor: Colors.grey.shade900,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black,
              width: double.infinity,
              child: const Text(
                'HMPI Dashboard',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStatsSection(),
                  const Divider(color: Colors.grey, height: 32),
                  _buildFiltersSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    final total = _filteredData.length;
    final avgHpi = total == 0 ? 0.0 : _filteredData.map((e) => e.hpi).reduce((a, b) => a + b) / total;
    
    int low = 0, med = 0, high = 0;
    for (var item in _filteredData) {
      if (item.hpi < 15) {
        low++;
      } else if (item.hpi <= 30) {
        med++;
      } else {
        high++;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('📊 Summary Statistics', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _statCard('Total Sites', total.toString()),
            _statCard('Avg HPI', avgHpi.toStringAsFixed(2)),
          ],
        ),
        const SizedBox(height: 16),
        _buildDistBar('Low (<15)', low, total, Colors.blue),
        const SizedBox(height: 8),
        _buildDistBar('Medium (15-30)', med, total, Colors.yellow),
        const SizedBox(height: 8),
        _buildDistBar('High (>30)', high, total, Colors.orange),
      ],
    );
  }

  Widget _statCard(String label, String value) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDistBar(String label, int count, int total, Color color) {
    final pct = total == 0 ? 0.0 : (count / total);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text('$count (${(pct * 100).toStringAsFixed(1)}%)', style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: pct,
          backgroundColor: Colors.grey.shade800,
          color: color,
        ),
      ],
    );
  }

  Widget _buildFiltersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🔍 Interactive Filters', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        
        TextField(
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Search location/district',
            labelStyle: const TextStyle(color: Colors.grey),
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            filled: true,
            fillColor: Colors.black,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
          onChanged: (val) {
            _searchQuery = val;
            _applyFilters();
          },
        ),
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              dropdownColor: Colors.grey.shade900,
              value: _selectedState,
              style: const TextStyle(color: Colors.white),
              items: _availableStates.map((s) => DropdownMenuItem(value: s, child: Text(s == 'ALL' ? 'All States (India)' : s))).toList(),
              onChanged: (val) {
                if (val != null) {
                  _selectedState = val;
                  _applyFilters();
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        Text('Min HPI Threshold: ${_minHpi.toInt()}', style: const TextStyle(color: Colors.white70)),
        Slider(
          value: _minHpi,
          min: 0,
          max: 100,
          divisions: 100,
          activeColor: Colors.teal,
          inactiveColor: Colors.grey.shade800,
          onChanged: (val) {
            setState(() {
              _minHpi = val;
              _applyFilters();
            });
          },
        ),
      ],
    );
  }
}
