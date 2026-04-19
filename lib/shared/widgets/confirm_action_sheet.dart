import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';

/// Jenis aksi untuk gaya bawaan (ikon, warna, teks default Bahasa Indonesia).
enum ConfirmActionVariant {
  /// Hapus permanen - ikon sampah, aksen merah/oranye.
  delete,

  /// Perbarui data - ikon edit, aksen biru.
  update,

  /// Simpan - ikon simpan, aksen hijau.
  save,

  /// Lanjut bayar / checkout - ikon pembayaran, aksen kuning brand.
  checkout,

  /// Hapus dari keranjang - mirip delete, pesan khusus keranjang.
  removeFromCart,

  /// Cabut akses / izin - ikon person_off, aksen merah.
  revokeAccess,

  /// Kirim pengajuan berisiko (mis. pembatalan) - ikon peringatan, oranye.
  submitRisk,

  /// Konfirmasi umum (netral).
  neutral,

  /// Semua teks dan warna diisi manual lewat parameter [showConfirmActionSheet].
  custom,

  /// Keluar akun - ikon logout, aksen merah.
  logout,

  /// Pembatalan pesanan - ikon close/cancel, aksen merah.
  cancelOrder,

  /// Tambah ke keranjang - ikon shopping_cart, aksen kuning.
  addToCart,
}

class _Preset {
  const _Preset({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.icon,
    required this.iconBackgroundColor,
    required this.iconColor,
    required this.confirmBackgroundColor,
    this.confirmForegroundColor = Colors.white,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final IconData icon;
  final Color iconBackgroundColor;
  final Color iconColor;
  final Color confirmBackgroundColor;
  final Color confirmForegroundColor;
}

_Preset _presetFor(ConfirmActionVariant variant) {
  switch (variant) {
    case ConfirmActionVariant.delete:
      return _Preset(
        title: 'Hapus?',
        message:
            'Apakah Anda yakin ingin menghapus item ini? Aksi ini tidak dapat dibatalkan.',
        confirmLabel: 'Hapus',
        icon: Icons.delete_outline_rounded,
        iconBackgroundColor: const Color(0xFFFFE4E6),
        iconColor: const Color(0xFFDC2626),
        confirmBackgroundColor: const Color(0xFFE85D4C),
      );
    case ConfirmActionVariant.update:
      return _Preset(
        title: 'Perbarui data?',
        message:
            'Apakah Anda yakin ingin memperbarui data ini? Pastikan informasi sudah benar.',
        confirmLabel: 'Perbarui',
        icon: Icons.edit_rounded,
        iconBackgroundColor: const Color(0xFFE0F2FE),
        iconColor: const Color(0xFF0284C7),
        confirmBackgroundColor: const Color(0xFF0284C7),
      );
    case ConfirmActionVariant.save:
      return _Preset(
        title: 'Simpan perubahan?',
        message:
            'Apakah Anda yakin ingin menyimpan? Pastikan data yang dimasukkan sudah benar.',
        confirmLabel: 'Simpan',
        icon: Icons.save_rounded,
        iconBackgroundColor: const Color(0xFFDCFCE7),
        iconColor: const Color(0xFF16A34A),
        confirmBackgroundColor: const Color(0xFF16A34A),
      );
    case ConfirmActionVariant.checkout:
      return _Preset(
        title: 'Bayar sekarang?',
        message:
            'Apakah Anda yakin ingin melanjutkan pemesanan dengan total yang tertera?',
        confirmLabel: 'Lanjutkan',
        icon: Icons.payments_rounded,
        iconBackgroundColor: const Color(0xFFFFF4CC),
        iconColor: const Color(0xFFCA8A04),
        confirmBackgroundColor: AppTheme.primaryColor,
        confirmForegroundColor: AppTheme.textColor,
      );
    case ConfirmActionVariant.removeFromCart:
      return _Preset(
        title: 'Hapus dari keranjang?',
        message:
            'Apakah Anda yakin ingin menghapus produk ini dari keranjang?',
        confirmLabel: 'Hapus',
        icon: Icons.remove_shopping_cart_rounded,
        iconBackgroundColor: const Color(0xFFFFE4E6),
        iconColor: const Color(0xFFDC2626),
        confirmBackgroundColor: const Color(0xFFE85D4C),
      );
    case ConfirmActionVariant.revokeAccess:
      return _Preset(
        title: 'Cabut akses?',
        message:
            'Apakah Anda yakin ingin mencabut hak akses admin untuk pengguna ini?',
        confirmLabel: 'Cabut akses',
        icon: Icons.person_off_rounded,
        iconBackgroundColor: const Color(0xFFFFE4E6),
        iconColor: const Color(0xFFDC2626),
        confirmBackgroundColor: const Color(0xFFDC2626),
      );
    case ConfirmActionVariant.submitRisk:
      return _Preset(
        title: 'Kirim pengajuan?',
        message:
            'Apakah Anda yakin ingin mengirim pengajuan ini? Tindakan ini akan diproses oleh tim.',
        confirmLabel: 'Kirim',
        icon: Icons.warning_amber_rounded,
        iconBackgroundColor: const Color(0xFFFFEDD5),
        iconColor: const Color(0xFFEA580C),
        confirmBackgroundColor: const Color(0xFFEA580C),
      );
    case ConfirmActionVariant.neutral:
      return _Preset(
        title: 'Konfirmasi',
        message: 'Apakah Anda yakin ingin melanjutkan?',
        confirmLabel: 'Ya',
        icon: Icons.help_outline_rounded,
        iconBackgroundColor: const Color(0xFFF1F5F9),
        iconColor: const Color(0xFF64748B),
        confirmBackgroundColor: const Color(0xFF334155),
      );
    case ConfirmActionVariant.logout:
      return _Preset(
        title: 'Keluar Akun?',
        message: 'Apakah Anda yakin ingin keluar dari akun Anda?',
        confirmLabel: 'Keluar',
        icon: Icons.logout_rounded,
        iconBackgroundColor: const Color(0xFFFFE4E6),
        iconColor: const Color(0xFFDC2626),
        confirmBackgroundColor: const Color(0xFFDC2626),
      );
    case ConfirmActionVariant.cancelOrder:
      return _Preset(
        title: 'Batalkan Pesanan?',
        message: 'Apakah Anda yakin ingin membatalkan pesanan ini?',
        confirmLabel: 'Batalkan',
        icon: Icons.close_rounded,
        iconBackgroundColor: const Color(0xFFFFE4E6),
        iconColor: const Color(0xFFDC2626),
        confirmBackgroundColor: const Color(0xFFDC2626),
      );
    case ConfirmActionVariant.addToCart:
      return _Preset(
        title: 'Masukkan Keranjang?',
        message: 'Apakah Anda yakin ingin memasukkan produk ini ke keranjang?',
        confirmLabel: 'Masukkan',
        icon: Icons.shopping_cart_rounded,
        iconBackgroundColor: const Color(0xFFFFF4CC),
        iconColor: const Color(0xFFCA8A04),
        confirmBackgroundColor: const Color(0xFFFFCC00),
        confirmForegroundColor: AppTheme.textColor,
      );
    case ConfirmActionVariant.custom:
      return _Preset(
        title: '',
        message: '',
        confirmLabel: 'OK',
        icon: Icons.check_circle_outline,
        iconBackgroundColor: const Color(0xFFF1F5F9),
        iconColor: const Color(0xFF64748B),
        confirmBackgroundColor: AppTheme.primaryColor,
        confirmForegroundColor: AppTheme.textColor,
      );
  }
}

/// Bottom sheet konfirmasi dengan ikon bulat, teks, dan dua tombol (utama + batal).
/// Mengembalikan `true` jika pengguna mengetuk aksi utama, `false` untuk batal, `null` jika ditutup tanpa pilihan.
Future<bool?> showConfirmActionSheet(
  BuildContext context, {
  required ConfirmActionVariant variant,
  String? title,
  String? message,
  String? confirmLabel,
  String? cancelLabel,
  IconData? icon,
  Color? iconBackgroundColor,
  Color? iconColor,
  Color? confirmBackgroundColor,
  Color? confirmForegroundColor,
}) {
  final base = _presetFor(variant);
  if (variant == ConfirmActionVariant.custom &&
      (title == null ||
          message == null ||
          confirmLabel == null ||
          icon == null ||
          confirmBackgroundColor == null)) {
    throw ArgumentError(
      'Untuk variant custom, wajib menyediakan title, message, confirmLabel, icon, dan confirmBackgroundColor.',
    );
  }

  final resolvedTitle = title ?? base.title;
  final resolvedMessage = message ?? base.message;
  final resolvedConfirm = confirmLabel ?? base.confirmLabel;
  final resolvedCancel = cancelLabel ?? 'Batal';
  final resolvedIcon = icon ?? base.icon;
  final resolvedIconBg = iconBackgroundColor ?? base.iconBackgroundColor;
  final resolvedIconFg = iconColor ?? base.iconColor;
  final resolvedConfirmBg = confirmBackgroundColor ?? base.confirmBackgroundColor;
  final resolvedConfirmFg =
      confirmForegroundColor ?? base.confirmForegroundColor;

  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    isScrollControlled: true,
    useSafeArea: false,
    builder: (ctx) {
      final width = MediaQuery.sizeOf(ctx).width;
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(ctx).bottom,
        ),
        child: SizedBox(
          width: width,
          child: _ConfirmActionSheetBody(
          title: resolvedTitle,
          message: resolvedMessage,
          confirmLabel: resolvedConfirm,
          cancelLabel: resolvedCancel,
          icon: resolvedIcon,
          iconBackgroundColor: resolvedIconBg,
          iconColor: resolvedIconFg,
          confirmBackgroundColor: resolvedConfirmBg,
          confirmForegroundColor: resolvedConfirmFg,
          onCancel: () => Navigator.of(ctx).pop(false),
          onConfirm: () => Navigator.of(ctx).pop(true),
        ),
        ),
      );
    },
  );
}

class _ConfirmActionSheetBody extends StatelessWidget {
  const _ConfirmActionSheetBody({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.icon,
    required this.iconBackgroundColor,
    required this.iconColor,
    required this.confirmBackgroundColor,
    required this.confirmForegroundColor,
    required this.onCancel,
    required this.onConfirm,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final IconData icon;
  final Color iconBackgroundColor;
  final Color iconColor;
  final Color confirmBackgroundColor;
  final Color confirmForegroundColor;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 34),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  height: 1.45,
                  color: AppTheme.subtitleColor,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: confirmBackgroundColor,
                    foregroundColor: confirmForegroundColor,
                    surfaceTintColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: Text(
                    confirmLabel,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: confirmForegroundColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: onCancel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    foregroundColor: const Color(0xFF475569),
                    surfaceTintColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: Text(
                    cancelLabel,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }
}
