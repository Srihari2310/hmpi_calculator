import 'package:flutter/material.dart';

void main() => runApp(const HmpiApp());

class HmpiApp extends StatelessWidget {
  const HmpiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HMPI Calculator',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const HmpiHomePage(),
    );
  }
}

class MetalStandard {
  final String name;
  final String symbol;
  final double si;
  final double ii;

  const MetalStandard(this.name, this.symbol, this.si, this.ii);
}

/// Ordered from most to least commonly found in groundwater.
const metalStandards = <MetalStandard>[
  MetalStandard('Iron', 'Fe', 1.0, 0.3),
  MetalStandard('Manganese', 'Mn', 0.3, 0.0),
  MetalStandard('Arsenic', 'As', 0.01, 0.0),
  MetalStandard('Zinc', 'Zn', 5.0, 5.0),
  MetalStandard('Copper', 'Cu', 2.0, 0.05),
  MetalStandard('Chromium', 'Cr', 0.05, 0.0),
  MetalStandard('Nickel', 'Ni', 0.02, 0.0),
  MetalStandard('Lead', 'Pb', 0.01, 0.0),
  MetalStandard('Uranium', 'U', 0.03, 0.0),
  MetalStandard('Cadmium', 'Cd', 0.003, 0.0),
  MetalStandard('Mercury', 'Hg', 0.001, 0.0),
];

class HmpiHomePage extends StatefulWidget {
  const HmpiHomePage({super.key});

  @override
  State<HmpiHomePage> createState() => _HmpiHomePageState();
}

class _HmpiHomePageState extends State<HmpiHomePage> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = List.generate(
    metalStandards.length,
    (_) => TextEditingController(),
  );

  double? _hpiResult;
  String? _classification;

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _numberValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final parsed = double.tryParse(value.trim());
    if (parsed == null) return 'Enter a valid number';
    if (parsed < 0) return 'Must be >= 0';
    return null;
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    double weightSum = 0;
    double weightedQualitySum = 0;

    for (var index = 0; index < metalStandards.length; index++) {
      final standard = metalStandards[index];
      final measured = double.parse(_controllers[index].text.trim());
      final wi = 1 / standard.si;
      // Zinc has Si == Ii, so use its modified sub-index formula.
      final qi = standard.si == standard.ii
          ? (measured / standard.si) * 100
          : ((measured - standard.ii) / (standard.si - standard.ii)).abs() * 100;
      weightSum += wi;
      weightedQualitySum += wi * qi;
    }

    final hpi = weightedQualitySum / weightSum;
    final classification = hpi < 15
        ? 'Low pollution'
        : hpi <= 30
            ? 'Medium pollution'
            : 'High pollution';

    setState(() {
      _hpiResult = hpi;
      _classification = classification;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HMPI Calculator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Heavy Metal Pollution Index',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Enter all measured concentrations in mg/L',
                style: TextStyle(fontSize: 13, color: Colors.grey),
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
                        child: _buildInputField(
                          controller: _controllers[index],
                          label: '${standard.name} (${standard.symbol})',
                        ),
                      );
                    }),
                  );
                },
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _calculate,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Calculate HPI', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 28),
              if (_hpiResult != null) _buildResultCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: _numberValidator,
      decoration: InputDecoration(
        labelText: label,
        suffixText: 'mg/L',
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildResultCard() {
    final color = switch (_classification) {
      'Low pollution' => Colors.green,
      'Medium pollution' => Colors.orange,
      _ => Colors.red,
    };

    return Card(
      color: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color, width: 1.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('HPI Result', style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 6),
            Text(
              _hpiResult!.toStringAsFixed(2),
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 6),
            Text(
              _classification!,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: color),
            ),
            const SizedBox(height: 10),
            const Text(
              'Classification: <15 Low | 15-30 Medium | >30 High\n'
              '(Prasad & Bose scheme; critical overall limit approximately 100)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
