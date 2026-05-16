import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedGender;
  final List<String> _genderOptions = ['Male', 'Female', 'Other', 'Prefer not to say'];

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _birthDateController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF8B0000),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _birthDateController.text =
            '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Future<void> submitRegister() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      await FirebaseAuth.instance.currentUser
          ?.updateDisplayName(_fullNameController.text.trim());

      _formKey.currentState!.reset();
      _fullNameController.clear();
      _emailController.clear();
      _addressController.clear();
      _contactController.clear();
      _birthDateController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      setState(() => _selectedGender = null);

      if (!mounted) return;
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException code: ${e.code}');
      String message;

      switch (e.code) {
        case 'weak-password':
          message = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          message = 'This email is already in use.';
          break;
        case 'invalid-email':
          message = 'The email address is invalid.';
          break;
        default:
          message = 'Registration failed. Please try again.';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Top red section with logo
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6B0020), Color(0xFF1a0010)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  // Logo — fully visible, no transparency
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/velour_grand.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  _buildCircle(top: 40, right: 20, size: 100, opacity: 0.25),
                  _buildCircle(top: 120, right: 80, size: 60, opacity: 0.15),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                          const Text(
                            'Create Your',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Account',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom white section with logo watermark — fully visible
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                Container(color: Colors.white),
                // Logo watermark on white — no transparency
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/velour_grand.png',
                    fit: BoxFit.contain,
                  ),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormField(
                          label: 'Full Name',
                          hint: 'Juan Dela Cruz',
                          controller: _fullNameController,
                          prefixIcon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Full name is required';
                            if (value.trim().length < 2) return 'Name must be at least 2 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          label: 'Email Address',
                          hint: 'example@email.com',
                          controller: _emailController,
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Email address is required';
                            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                            if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email address';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          label: 'Address',
                          hint: '123 Main St, City, Province',
                          controller: _addressController,
                          prefixIcon: Icons.home_outlined,
                          maxLines: 2,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Address is required';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          label: 'Contact Number',
                          hint: '09XXXXXXXXX',
                          controller: _contactController,
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Contact number is required';
                            if (value.length < 10 || value.length > 11) return 'Enter a valid contact number (10–11 digits)';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          label: 'Birth Date',
                          hint: 'MM/DD/YYYY',
                          controller: _birthDateController,
                          prefixIcon: Icons.cake_outlined,
                          readOnly: true,
                          onTap: _selectBirthDate,
                          suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFF8B0000), size: 20),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Birth date is required';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Gender',
                                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 13)),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<String>(
                              value: _selectedGender,
                              hint: const Text('Select gender', style: TextStyle(color: Colors.grey, fontSize: 13)),
                              icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF8B0000)),
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.wc_outlined, color: Color(0xFF8B0000), size: 20),
                                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF8B0000))),
                                errorBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.red)),
                                focusedErrorBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.red)),
                              ),
                              items: _genderOptions
                                  .map((gender) => DropdownMenuItem(value: gender, child: Text(gender, style: const TextStyle(fontSize: 14))))
                                  .toList(),
                              onChanged: (value) => setState(() => _selectedGender = value),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Please select your gender';
                                return null;
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          label: 'Password',
                          hint: '••••••••••',
                          controller: _passwordController,
                          prefixIcon: Icons.lock_outline,
                          obscure: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 20),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Password is required';
                            if (value.length < 6) return 'Password must be at least 6 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          label: 'Re-enter Password',
                          hint: '••••••••••',
                          controller: _confirmPasswordController,
                          prefixIcon: Icons.lock_outline,
                          obscure: _obscureConfirmPassword,
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 20),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Please confirm your password';
                            if (value != _passwordController.text) return 'Passwords do not match';
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: submitRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B0000),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            child: const Text('SIGN UP',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Already have an account? ', style: TextStyle(color: Colors.grey)),
                              GestureDetector(
                                onTap: () => Navigator.pushReplacement(
                                    context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                                child: const Text('Sign in',
                                    style: TextStyle(color: Color(0xFF8B0000), fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData prefixIcon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 13)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          readOnly: readOnly,
          onTap: onTap,
          maxLines: obscure ? 1 : maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            prefixIcon: Icon(prefixIcon, color: const Color(0xFF8B0000), size: 20),
            suffixIcon: suffixIcon,
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF8B0000))),
            errorBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.red)),
            focusedErrorBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.red)),
          ),
        ),
      ],
    );
  }

  Widget _buildCircle({
    double? top, double? bottom, double? left, double? right,
    required double size, required double opacity,
  }) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red.withOpacity(opacity),
        ),
      ),
    );
  }
}