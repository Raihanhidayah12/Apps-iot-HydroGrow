// lib/utils/helpers.dart
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class Helpers {
  /// Format waktu WIB (UTC+7)
  static String formatWIB(DateTime dateTime) {
    final wib = dateTime.toUtc().add(const Duration(hours: 7));
    return DateFormat('HH:mm:ss').format(wib);
  }

  /// Format tanggal dan waktu lengkap untuk log
  static String formatFullDateTime(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return "Unknown Time";

    try {
      final date = DateTime.parse(timestamp);
      return DateFormat('dd MMM yyyy, HH:mm:ss').format(date.toUtc().add(const Duration(hours: 7)));
    } catch (e) {
      return timestamp; // fallback jika format salah
    }
  }

  /// Cek apakah waktu ESP32 error (1970 atau 0000)
  static bool isNtpError(String timeStr) {
    if (timeStr.isEmpty) return true;
    return timeStr.contains("1970") || 
           timeStr.contains("1969") || 
           timeStr.contains("0000");
  }

  /// Menampilkan SnackBar dengan style konsisten
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Format durasi pompa menjadi teks yang rapi
  static String formatPumpDuration(int minutes) {
    if (minutes == 0) return "Pompa Mati";
    return "$minutes Menit";
  }

  /// Mendapatkan warna status berdasarkan nilai sensor
  static Color getSensorStatusColor(double value, {double critical = 20}) {
    if (value < critical) return Colors.red;
    if (value < 40) return Colors.orange;
    return Colors.green;
  }

  /// Membersihkan dan memformat data sensor dari Firebase (fallback)
  static Map<String, dynamic> cleanSensorData(Map<dynamic, dynamic> raw) {
    return {
      'moisture': (raw['moisture'] ?? 0).toDouble(),
      'light': (raw['light'] ?? 0).toDouble(),
      'water': (raw['water'] ?? raw['water_level'] ?? 0).toDouble(),
      'battery': (raw['battery'] ?? 0).toDouble(),
      'time': raw['time']?.toString() ?? 'Unknown',
    };
  }

  /// Generate nama file export (contoh: HydroGrow_Log_2026-04-20.csv)
  static String generateExportFileName(String format) {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    return "HydroGrow_Log_$dateStr.$format";
  }

  /// Menampilkan dialog konfirmasi sederhana
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Ya"),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
