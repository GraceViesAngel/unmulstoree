import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/cities.dart';
import '../../../../shared/widgets/confirm_action_sheet.dart';
import '../../data/models/profile_model.dart';
import '../../domain/repositories/profile_repository.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final ProfileRepository _repo = ProfileRepository();
  ProfileModel? _profile;
  bool _isLoading = true;
  bool _uploadingAvatar = false;
  String? _selectedCity;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _repo.getCurrentProfile();
    if (profile != null) {
      setState(() {
        _profile = profile;
        _nameController.text = profile.fullName ?? '';
        _phoneController.text = profile.phoneNumber ?? '';
        _selectedCity = profile.city;
        _addressController.text = profile.street ?? '';
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  String? _validateFields() {
    if (_nameController.text.trim().isEmpty) {
      return 'Nama lengkap wajib diisi.';
    }
    if (_phoneController.text.trim().isEmpty) {
      return 'Nomor telepon wajib diisi.';
    }
    if (_selectedCity == null || _selectedCity!.isEmpty) {
      return 'Kota/kabupaten wajib dipilih.';
    }
    return null;
  }

  Future<void> _onSavePressed() async {
    if (_profile == null) return;
    final err = _validateFields();
    if (err != null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(err)));
      }
      return;
    }
    final confirm = await showConfirmActionSheet(
      context,
      variant: ConfirmActionVariant.save,
    );
    if (confirm != true || !mounted) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session tidak valid. Silakan login ulang.'),
          ),
        );
      }
      return;
    }

    final profileId = _profile?.id ?? userId;
    final updatedProfile = ProfileModel(
      id: profileId,
      fullName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      city: _selectedCity,
      street: _addressController.text.trim(),
      avatarUrl: _profile?.avatarUrl,
    );
    await _repo.updateProfile(updatedProfile);
    if (mounted) context.pop();
  }

  Future<void> _changeProfilePhoto() async {
    if (_profile == null) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Silakan login ulang.')));
      }
      return;
    }

    final x = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (x == null || !mounted) return;

    setState(() => _uploadingAvatar = true);
    try {
      final bytes = await x.readAsBytes();
      final name = x.name.toLowerCase();
      final isPng = name.endsWith('.png');
      final url = await _repo.uploadUserAvatar(
        userId: userId,
        bytes: Uint8List.fromList(bytes),
        isPng: isPng,
      );
      final merged = ProfileModel(
        id: _profile!.id,
        fullName: _profile!.fullName,
        phoneNumber: _profile!.phoneNumber,
        city: _profile!.city,
        street: _profile!.street,
        avatarUrl: url,
      );
      await _repo.updateProfile(merged);
      if (mounted) {
        setState(() {
          _profile = merged;
          _uploadingAvatar = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil berhasil diperbarui.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingAvatar = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal unggah foto: $e')));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B1B1B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1B1B1B),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: _uploadingAvatar ? null : _changeProfilePhoto,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[200],
                        border: Border.all(
                          color: const Color(0xFFFFCC00),
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child:
                            _profile?.avatarUrl != null &&
                                _profile!.avatarUrl!.isNotEmpty
                            ? Image.network(
                                _profile!.avatarUrl!,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.grey,
                                    ),
                              )
                            : const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey,
                              ),
                      ),
                    ),
                    if (_uploadingAvatar)
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.45),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    else
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFCC00),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: Color(0xFF1B1B1B),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Ketuk foto untuk mengganti',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildFieldLabel('Nama Lengkap'),
            _buildTextField(controller: _nameController),
            const SizedBox(height: 24),
            _buildFieldLabel('Nomor HP'),
            _buildTextField(controller: _phoneController),
            const SizedBox(height: 24),
            _buildFieldLabel('Kota / Kabupaten'),
            _buildCityDropdown(),
            const SizedBox(height: 24),
            _buildFieldLabel('Alamat Lengkap'),
            _buildTextField(
              controller: _addressController,
              maxLines: 4,
              hintText: 'Nama jalan, RT/RW, kode pos, dll',
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        child: ElevatedButton(
          onPressed: _onSavePressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFCC00),
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Simpan Perubahan',
            style: GoogleFonts.poppins(
              color: const Color(0xFF1B1B1B),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1B1B1B),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    int maxLines = 1,
    String? hintText,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: const Color(0xFF1B1B1B),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.poppins(
          color: const Color(0xFF64748B).withValues(alpha: 0.5),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFCC00), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildCityDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButton<String>(
        value: _selectedCity,
        isExpanded: true,
        hint: Text(
          'Pilih kota/kabupaten',
          style: GoogleFonts.poppins(
            color: const Color(0xFF64748B).withValues(alpha: 0.5),
          ),
        ),
        underline: const SizedBox(),
        items: Cities.names.map((city) {
          final cityData = Cities.getByName(city);
          return DropdownMenuItem(
            value: city,
            child: Text(
              city,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF1B1B1B),
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() => _selectedCity = value);
        },
      ),
    );
  }
}
