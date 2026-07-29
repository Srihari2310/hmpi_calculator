import 'package:flutter/material.dart';
import '../main.dart'; // To access MetalStandard

class MetalInputField extends StatelessWidget {
  final TextEditingController controller;
  final MetalStandard standard;
  final String? Function(String?)? validator;

  const MetalInputField({
    super.key,
    required this.controller,
    required this.standard,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final color = _elementColor(standard.symbol);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align to top for error text space
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8, left: 8, right: 12),
            child: _elementBadge(standard, color),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: TextFormField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: validator,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: standard.name,
                  labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  suffixText: 'mg/L',
                  suffixStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.bold),
                  border: InputBorder.none,
                  errorStyle: const TextStyle(height: 0.8),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _elementBadge(MetalStandard standard, Color color) {
    return Container(
      width: 48,
      height: 52,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 3,
            left: 5,
            child: Text(
              standard.atomicNumber.toString(),
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                Text(
                  standard.symbol,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color, height: 1.0),
                ),
                const SizedBox(height: 1),
                Text(
                  standard.atomicMass.toStringAsFixed(2),
                  style: TextStyle(fontSize: 7, color: color, fontWeight: FontWeight.w600, height: 1.0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _elementColor(String symbol) {
    final s = symbol.toLowerCase();
    const nobleGases = ['he', 'ne', 'ar', 'kr', 'xe', 'rn'];
    const metalloids = ['as', 'sb', 'te', 'b', 'si', 'ge'];
    if (nobleGases.contains(s)) return Colors.deepPurple;
    if (metalloids.contains(s)) return Colors.green.shade700;
    return Colors.indigo.shade400;
  }
}
