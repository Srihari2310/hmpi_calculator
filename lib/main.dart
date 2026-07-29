import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  try {
    await FirebaseAuth.instance.signInAnonymously();
  } catch (e) {
    debugPrint('Auth failed: $e');
  }
  runApp(const HmpiApp());
}

class HmpiApp extends StatelessWidget {
  const HmpiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoIndex Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            return const IndicesDashboardPage();
          }
          return const AuthPage();
        },
      ),
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUp) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');
      setState(() {
        _errorMessage = e.message ?? 'Error (${e.code})';
      });
    } catch (e) {
      debugPrint('Auth Error: $e');
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo.shade400, Colors.indigo.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.withValues(alpha: 0.25),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.eco,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _isSignUp ? 'Create Account' : 'Welcome to EcoIndex',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isSignUp
                    ? 'Register to start analyzing indices'
                    : 'Log in to access your environmental indices',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 36),
              Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 4,
                shadowColor: Colors.black.withValues(alpha: 0.05),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _isLoading ? null : _submit,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.indigo,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _isSignUp ? 'Sign Up' : 'Log In',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isSignUp ? 'Already have an account? ' : 'New to EcoIndex? ',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isSignUp = !_isSignUp;
                        _errorMessage = null;
                      });
                    },
                    child: Text(
                      _isSignUp ? 'Log In' : 'Sign Up',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class IndexOption {
  final String code;
  final String name;
  final String description;
  final IconData icon;
  final List<Color> gradientColors;
  final bool isActive;
  final String statusText;

  const IndexOption({
    required this.code,
    required this.name,
    required this.description,
    required this.icon,
    required this.gradientColors,
    required this.isActive,
    required this.statusText,
  });
}

final indexOptions = [
  IndexOption(
    code: 'HMPI',
    name: 'Heavy Metal Pollution Index',
    description: 'Assess contamination levels in water sources.',
    icon: Icons.science,
    gradientColors: [Colors.orange.shade400, Colors.red.shade500],
    isActive: true,
    statusText: 'Active',
  ),
  IndexOption(
    code: 'HEI',
    name: 'Heavy Metal Evaluation Index',
    description: 'Evaluate overall quality of water regarding heavy metals.',
    icon: Icons.analytics_outlined,
    gradientColors: [Colors.blue.shade400, Colors.indigo.shade600],
    isActive: false,
    statusText: 'Coming Soon',
  ),
  IndexOption(
    code: 'MI',
    name: 'Metal Index',
    description: 'Sum of ratios of measured metals to permissible levels.',
    icon: Icons.percent_outlined,
    gradientColors: [Colors.teal.shade400, Colors.green.shade600],
    isActive: false,
    statusText: 'Coming Soon',
  ),
  IndexOption(
    code: 'Cd',
    name: 'Contamination Degree',
    description: 'Sum of contamination factors for individual metals.',
    icon: Icons.bar_chart_outlined,
    gradientColors: [Colors.purple.shade400, Colors.pink.shade600],
    isActive: false,
    statusText: 'Coming Soon',
  ),
];

class IndicesDashboardPage extends StatelessWidget {
  const IndicesDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.email?.split('@').first ?? 'Analyst';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome Back,',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.notifications_outlined, color: Colors.indigo),
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.logout_outlined, color: Colors.redAccent),
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Previous Reports Button
              InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const PreviousReportsPage()));
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.indigo.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.history, color: Colors.indigo, size: 28),
                          SizedBox(width: 16),
                          Text(
                            'Previous Reports',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                          ),
                        ],
                      ),
                      Icon(Icons.arrow_forward_ios, color: Colors.indigo, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Section Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Available Indices',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Grid of leaf cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = (constraints.maxWidth - 16) / 2;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: indexOptions.map((option) {
                      return SizedBox(
                        width: cardWidth,
                        height: 220,
                        child: IndexCard(
                          option: option,
                          onTap: () {
                            if (option.isActive && option.code == 'HMPI') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HmpiHomePage(),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class IndexCard extends StatelessWidget {
  final IndexOption option;
  final VoidCallback onTap;

  const IndexCard({
    super.key,
    required this.option,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.only(
      topLeft: Radius.circular(32),
      bottomRight: Radius.circular(32),
      topRight: Radius.circular(8),
      bottomLeft: Radius.circular(8),
    );

    return Opacity(
      opacity: option.isActive ? 1.0 : 0.8,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: option.gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: option.gradientColors.first.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: option.isActive ? onTap : null,
            borderRadius: borderRadius,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          option.icon,
                          color: option.gradientColors.first,
                          size: 20,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          option.statusText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    option.code,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 10,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: option.isActive ? 0.35 : 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        option.isActive ? Icons.arrow_forward : Icons.lock,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
    if (value == null || value.trim().isEmpty) return null;
    final parsed = double.tryParse(value.trim());
    if (parsed == null) return 'Enter a valid number';
    if (parsed < 0) return 'Must be >= 0';
    return null;
  }

  Future<void> _calculate() async {
    if (!_formKey.currentState!.validate()) return;

    double weightSum = 0;
    double weightedQualitySum = 0;

    for (var index = 0; index < metalStandards.length; index++) {
      final standard = metalStandards[index];
      final text = _controllers[index].text.trim();
      final measured = text.isEmpty ? 0.0 : double.parse(text);
      final wi = 1 / standard.si;
      final qi = standard.si == standard.ii
          ? (measured / standard.si) * 100
          : ((measured - standard.ii) / (standard.si - standard.ii)).abs() * 100;
      weightSum += wi;
      weightedQualitySum += wi * qi;
    }

    final hpi = weightSum == 0 ? 0.0 : weightedQualitySum / weightSum;
    final classification = hpi < 15
        ? 'Low pollution'
        : hpi <= 30
            ? 'Medium pollution'
            : 'High pollution';

    setState(() {
      _hpiResult = hpi;
      _classification = classification;
    });

    try {
      await FirebaseFirestore.instance.collection('hmpi_calculations').add({
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'hpi': hpi,
        'classification': classification,
        'concentrationsMgL': {
          for (var index = 0; index < metalStandards.length; index++)
            metalStandards[index].symbol: _controllers[index].text.trim().isEmpty
                ? 0.0
                : double.parse(_controllers[index].text.trim()),
        },
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Result calculated, but could not be saved: ${error.message ?? error.code}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HMPI Calculator'),
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
                  backgroundColor: Colors.indigo,
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
        prefixIcon: Padding(
          padding: const EdgeInsets.all(8.0),
          child: _elementBadge(label),
        ),
        suffixText: 'mg/L',
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _elementBadge(String label) {
    final match = RegExp(r"\((.*?)\)").firstMatch(label);
    final symbol = match != null ? match.group(1)! : label;
    final color = _elementColor(symbol);
    return CircleAvatar(
      radius: 14,
      backgroundColor: color,
      child: Text(
        symbol,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
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

class PreviousReportsPage extends StatelessWidget {
  const PreviousReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Previous Reports'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('hmpi_calculations')
              .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Error loading reports'));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.indigo.withValues(alpha: 0.1)),
                ),
                child: const Center(
                  child: Text(
                    'No previous reports found.\nTest an index to see it here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.docs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final hpi = data['hpi'] as double? ?? 0.0;
                final classification = data['classification'] as String? ?? 'Unknown';
                final timestamp = data['createdAt'] as Timestamp?;
                final date = timestamp != null
                    ? '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}'
                    : 'Unknown date';

                final color = classification.contains('Low')
                    ? Colors.green
                    : classification.contains('Medium')
                        ? Colors.orange
                        : Colors.red;

                return InkWell(
                  onTap: () => _showReportDetails(context, data, date, hpi, classification, color),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.science, color: color),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'HMPI Report',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                date,
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              hpi.toStringAsFixed(2),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: color,
                              ),
                            ),
                            Text(
                              classification,
                              style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showReportDetails(BuildContext context, Map<String, dynamic> data, String date, double hpi, String classification, Color color) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final concentrations = data['concentrationsMgL'] as Map<String, dynamic>? ?? {};
        
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Report Details',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text('HMPI Score: ${hpi.toStringAsFixed(2)}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
                    const SizedBox(height: 4),
                    Text(classification, style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Text('Tested on: $date', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Concentrations (mg/L)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: concentrations.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text('${entry.value}', style: const TextStyle(fontFamily: 'monospace')),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
