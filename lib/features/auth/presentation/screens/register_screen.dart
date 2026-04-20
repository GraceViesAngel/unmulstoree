import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isButtonEnabled = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _validateInput() {
    setState(() {
      _isButtonEnabled =
          _nameController.text.isNotEmpty &&
          _emailController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty;
    });
  }

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateInput);
    _emailController.addListener(_validateInput);
    _passwordController.addListener(_validateInput);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onRegister() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final authRepo = AuthRepository();
    try {
      await authRepo.signUpWithEmail(
        _emailController.text,
        _passwordController.text,
        _nameController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Link verifikasi telah dikirim ke email Anda'),
          ),
        );
        context.push(
          '/verify-pending',
          extra: {'email': _emailController.text, 'name': _nameController.text},
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();

        if (errorMessage.contains('429') ||
            errorMessage.contains('rate limit')) {
          errorMessage =
              'Terlalu banyak permintaan. Silakan tunggu beberapa detik lalu coba lagi, atau coba gunakan email lain.';
        } else if (errorMessage.contains('already registered') ||
            errorMessage.contains('already exists')) {
          errorMessage = 'Email ini sudah terdaftar. Silakan login.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                bottomInset > 0 ? 20 : 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 40,
                ),
                child: IntrinsicHeight(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Spacer(),
                          Text(
                            'Buat Akunmu',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF1B1B1B),
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Mulai jelajahi dan pesan produk Unmul Store secara online.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF4B4B4B),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'Nama',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1B1B1B),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          CustomTextField(
                            controller: _nameController,
                            hintText: 'Masukin nama lengkap',
                            prefixIcon: const Icon(
                              Icons.person,
                              color: Color(0xFFCBD5E1),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Email',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1B1B1B),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          CustomTextField(
                            controller: _emailController,
                            hintText: 'Masukin email',
                            prefixIcon: const Icon(
                              Icons.email,
                              color: Color(0xFFCBD5E1),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Password',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1B1B1B),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          CustomTextField(
                            controller: _passwordController,
                            hintText: 'Masukin password',
                            prefixIcon: const Icon(
                              Icons.lock,
                              color: Color(0xFFCBD5E1),
                            ),
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: const Color(0xFF94A3B8),
                              ),
                              onPressed: () {
                                setState(
                                  () => _obscurePassword = !_obscurePassword,
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 40),
                          PrimaryButton(
                            text: 'Lanjutkan',
                            isDisabled: !_isButtonEnabled,
                            isLoading: _isLoading,
                            onPressed: _onRegister,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Sudah Memiliki Akun? ',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.push('/login'),
                                child: Text(
                                  'Masuk',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFFFCC00),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text.rich(
                            TextSpan(
                              text: 'By entering my email, I accept ',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: const Color(0xFF94A3B8),
                              ),
                              children: [
                                TextSpan(
                                  text: "Unmul Store's terms\n",
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1B1B1B),
                                  ),
                                ),
                                TextSpan(
                                  text: 'and ',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                                TextSpan(
                                  text: 'personal data.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1B1B1B),
                                  ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
