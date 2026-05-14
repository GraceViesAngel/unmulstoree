import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/widgets/camera_capture_screen.dart';
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
  bool _loadingLocation = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _repo.getCurrentProfile();
    if (profile != null) {
      final phoneNumber = profile.phoneNumber ?? '';
      final phoneWithoutPrefix = phoneNumber.startsWith('+62') 
          ? phoneNumber.substring(3) 
          : phoneNumber;
      setState(() {
        _profile = profile;
        _nameController.text = profile.fullName ?? '';
        _phoneController.text = phoneWithoutPrefix;
        _addressController.text = profile.street ?? '';
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  String? _validateFields() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return 'Nama lengkap wajib diisi.';
    }
    if (name.length > 100) {
      return 'Nama maksimal 100 karakter.';
    }

    var phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      return 'Nomor HP wajib diisi.';
    }
    if (phone.length < 12) {
      return 'Nomor HP minimal 12 digit.';
    }
    if (phone.length > 12) {
      return 'Nomor HP maksimal 12 digit.';
    }

    final address = _addressController.text.trim();
    if (address.length > 300) {
      return 'Alamat maksimal 300 karakter.';
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
    final phoneNumber = '+62${_phoneController.text.trim()}';
    final updatedProfile = ProfileModel(
      id: profileId,
      fullName: _nameController.text.trim(),
      phoneNumber: phoneNumber,
      street: _addressController.text.trim(),
      avatarUrl: _profile?.avatarUrl,
    );
    await _repo.updateProfile(updatedProfile);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile berhasil diperbarui.')),
      );
      NotificationService.instance.show(
        id: 1,
        title: 'Profil Diperbarui',
        body: 'Data profil Anda berhasil diperbarui.',
      );
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      context.go('/home?t=$timestamp');
    }
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

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Pilih Sumber Foto',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1B1B1B),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF1B1B1B)),
                title: Text(
                  'Kamera',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1B1B1B),
                  ),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF1B1B1B)),
                title: Text(
                  'Galeri',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1B1B1B),
                  ),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Batal',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;

    XFile? x;
    if (source == ImageSource.camera) {
      final useNativeCamera = !kIsWeb && switch (defaultTargetPlatform) {
        TargetPlatform.android || TargetPlatform.iOS => true,
        _ => false,
      };
      if (useNativeCamera) {
        x = await _imagePicker.pickImage(
          source: source,
          maxWidth: 1024,
          imageQuality: 85,
        );
      } else {
        x = await Navigator.push<XFile>(
          context,
          MaterialPageRoute(builder: (_) => const CameraCaptureScreen()),
        );
        if (x == null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kamera tidak tersedia. Beralih ke galeri.')),
          );
          x = await _imagePicker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 1024,
            imageQuality: 85,
          );
        }
      }
    } else {
      x = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 85,
      );
    }
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

  Future<void> _getCurrentLocation() async {
    setState(() => _loadingLocation = true);
    try {
      if (!kIsWeb) {
        final permission = await Geolocator.requestPermission();
        if (!mounted) return;

        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Izin lokasi tidak diberikan.')),
            );
          }
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted) return;

      String address;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = <String>[
            if (p.street != null && p.street!.isNotEmpty) p.street!,
            if (p.subLocality != null &&
                p.subLocality!.isNotEmpty &&
                p.subLocality != p.street)
              p.subLocality!,
            if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
            if (p.administrativeArea != null &&
                p.administrativeArea!.isNotEmpty)
              p.administrativeArea!,
          ];
          address = parts.join(', ');
        } else {
          address = '${position.latitude}, ${position.longitude}';
        }
      } catch (_) {
        try {
          final res = await http.get(
            Uri.parse(
              'https://nominatim.openstreetmap.org/reverse'
              '?lat=${position.latitude}&lon=${position.longitude}'
              '&format=json&addressdetails=1',
            ),
            headers: {
              'User-Agent': 'pab-flutter-app/1.0',
              'Accept-Language': 'id',
            },
          );
          if (res.statusCode == 200) {
            final data = jsonDecode(res.body) as Map<String, dynamic>;
            final displayName = data['display_name'] as String?;
            address = displayName ?? '${position.latitude}, ${position.longitude}';
          } else {
            address = '${position.latitude}, ${position.longitude}';
          }
        } catch (_) {
          address = '${position.latitude}, ${position.longitude}';
        }
      }
      _addressController.text = address;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lokasi berhasil didapatkan.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mendapatkan lokasi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
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
            _buildTextField(
              controller: _nameController,
              maxLength: 100,
            ),
            const SizedBox(height: 24),
            _buildFieldLabel('Nomor HP'),
            _buildTextField(
              controller: _phoneController,
              maxLength: 12,
              keyboardType: TextInputType.phone,
              hintText: '812345678901',
            ),
            const SizedBox(height: 24),
            _buildFieldLabel('Alamat Lengkap'),
            _buildTextField(
              controller: _addressController,
              maxLines: 4,
              maxLength: 300,
              hintText: 'Nama jalan, RT/RW, kode pos, dll',
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _loadingLocation ? null : _getCurrentLocation,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFFCC00)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _loadingLocation
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location, color: Color(0xFF1B1B1B)),
                label: Text(
                  _loadingLocation
                      ? 'Mendapatkan lokasi...'
                      : 'Gunakan lokasi anda sekarang',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF1B1B1B),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
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
    int? maxLength,
    TextInputType? keyboardType,
    String? prefixText,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: const Color(0xFF1B1B1B),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        prefixText: prefixText,
        prefixStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: const Color(0xFF1B1B1B),
          fontWeight: FontWeight.w500,
        ),
        hintStyle: GoogleFonts.poppins(
          color: const Color(0xFF64748B).withValues(alpha: 0.5),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(16),
        counterStyle: GoogleFonts.poppins(
          fontSize: 12,
          color: const Color(0xFF64748B),
        ),
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

}
