import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'location_picker_page.dart';
import 'main.dart';
import 'widgets/result_gauge_card.dart';
import 'widgets/metal_input_field.dart';

/// Metal Index (MI) Calculator
/// Formula: MI = Σ (Ci / MAC_i)
/// Same summation as HEI but with different classification thresholds.
///
/// Classification (Tamasi & Cini, 1976):
///   MI < 0.3  → Very Pure
///   0.3 ≤ MI < 1.0 → Pure
///   1.0 ≤ MI < 2.0 → Slightly Affected
///   2.0 ≤ MI < 4.0 → Moderately Affected
///   4.0 ≤ MI < 6.0 → Strongly Affected
///   MI ≥ 6.0 → Seriously Affected

class MiCalculatorPage extends StatefulWidget {
  const MiCalculatorPage({super.key});

  @override
  State<MiCalculatorPage> createState() => _MiCalculatorPageState();
}

class _MiCalculatorPageState extends State<MiCalculatorPage> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = List.generate(
    metalStandards.length,
    (_) => TextEditingController(),
  );

  double? _miResult;
  String? _classification;
  LatLng? _selectedLocation;
  bool _isLocating = false;

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _numberValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = double.tryParse(value.trim());
    if (parsed == null) return 'Enter a valid number';
    if (parsed < 0) return 'Must be >= 0';
    return null;
  }

  Future<String?> _reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'lat': lat.toString(),
        'lon': lng.toString(),
        'format': 'json',
        'addressdetails': '1',
      });
      final response = await http.get(uri, headers: {
        'User-Agent': 'hmpi_app/1.0',
      });
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['display_name'] as String?;
      }
    } catch (_) {}
    return null;
  }

  String _classify(double mi) {
    if (mi < 0.3) return 'Very Pure';
    if (mi < 1.0) return 'Pure';
    if (mi < 2.0) return 'Slightly Affected';
    if (mi < 4.0) return 'Moderately Affected';
    if (mi < 6.0) return 'Strongly Affected';
    return 'Seriously Affected';
  }

  Color _classificationColor(String c) {
    return switch (c) {
      'Very Pure' => Colors.green.shade800,
      'Pure' => Colors.green,
      'Slightly Affected' => Colors.lime.shade700,
      'Moderately Affected' => Colors.orange,
      'Strongly Affected' => Colors.deepOrange,
      _ => Colors.red,
    };
  }

  Future<void> _calculate() async {
    if (!_formKey.currentState!.validate()) return;

    double mi = 0;

    for (var i = 0; i < metalStandards.length; i++) {
      final standard = metalStandards[i];
      final text = _controllers[i].text.trim();
      final ci = text.isEmpty ? 0.0 : double.parse(text);
      final mac = standard.si;
      mi += ci / mac;
    }

    final classification = _classify(mi);

    setState(() {
      _miResult = mi;
      _classification = classification;
    });

    try {
      final docData = <String, dynamic>{
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'hpi': mi,
        'classification': classification,
        'indexType': 'MI',
        'concentrationsMgL': {
          for (var i = 0; i < metalStandards.length; i++)
            metalStandards[i].symbol: _controllers[i].text.trim().isEmpty
                ? 0.0
                : double.parse(_controllers[i].text.trim()),
        },
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (_selectedLocation != null) {
        docData['location'] = GeoPoint(_selectedLocation!.latitude, _selectedLocation!.longitude);
        final address = await _reverseGeocode(_selectedLocation!.latitude, _selectedLocation!.longitude);
        if (address != null) {
          docData['locationName'] = address;
        }
      }

      await FirebaseFirestore.instance.collection('hmpi_calculations').add(docData);
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Result calculated, but could not be saved: ${error.message ?? error.code}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MI Calculator'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Metal Index',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Enter all measured concentrations in mg/L',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Formula', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    SizedBox(height: 4),
                    Text(
                      'MI = Σ (Cᵢ / MAC_ᵢ)\n'
                      'Cᵢ = measured concentration\n'
                      'MAC = maximum allowable concentration (WHO)',
                      style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = (constraints.maxWidth - 16) / 2;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: List.generate(metalStandards.length, (index) {
                      final standard = metalStandards[index];
                      return SizedBox(
                        width: itemWidth,
                        child: MetalInputField(
                          controller: _controllers[index],
                          standard: standard,
                          validator: _numberValidator,
                        ),
                      );
                    }),
                  );
                },
              ),
              const SizedBox(height: 28),
              _buildLocationSelector(),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _calculate,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.teal.shade700,
                ),
                child: const Text('Calculate MI', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 28),
              if (_miResult != null) _buildResultCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Location (Optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (_selectedLocation != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lat: ${_selectedLocation!.latitude.toStringAsFixed(4)}, Lng: ${_selectedLocation!.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                IconButton(icon: const Icon(Icons.clear, color: Colors.red), onPressed: () => setState(() => _selectedLocation = null)),
              ],
            ),
          ),
        if (_selectedLocation == null)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLocating ? null : _getCurrentLocation,
                  icon: _isLocating
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.my_location),
                  label: const Text('Current GPS'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final LatLng? result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LocationPickerPage(initialLocation: _selectedLocation)),
                    );
                    if (result != null) setState(() => _selectedLocation = result);
                  },
                  icon: const Icon(Icons.map),
                  label: const Text('Pick on Map'),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services are disabled.');
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception('Location permissions are denied');
      }
      if (permission == LocationPermission.deniedForever) throw Exception('Location permissions are permanently denied.');
      Position position = await Geolocator.getCurrentPosition();
      setState(() => _selectedLocation = LatLng(position.latitude, position.longitude));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLocating = false);
    }
  }



  Widget _buildResultCard() {
    final color = _classificationColor(_classification!);

    return ResultGaugeCard(
      title: 'Metal Index',
      score: _miResult!,
      classification: _classification!,
      classificationColor: color,
      segments: [
        GaugeSegment(limit: 0.3, label: '0.3', color: Colors.green.shade800),
        const GaugeSegment(limit: 1.0, label: '1', color: Colors.green),
        GaugeSegment(limit: 2.0, label: '2', color: Colors.lime.shade700),
        const GaugeSegment(limit: 4.0, label: '4', color: Colors.orange),
        const GaugeSegment(limit: 6.0, label: '6', color: Colors.deepOrange),
        const GaugeSegment(limit: 10.0, label: '10+', color: Colors.red),
      ],
      reference: 'Tamasi & Cini, 1976',
    );
  }
}
