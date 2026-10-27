import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:jigsaw_pro/core/storage/hive_storage.dart';

/// Manages 30-minute reminder timers and notifications when a puzzle is left incomplete.
class ReminderService extends GetxService {
  final HiveStorage _storage;
  Timer? _reminderTimer;

  ReminderService(this._storage);

  /// Called when a player leaves a puzzle halfway
  void schedulePuzzleReminder() {
    _reminderTimer?.cancel();
    // Schedule reminder for 30 minutes
    _reminderTimer = Timer(const Duration(minutes: 30), () {
      _checkAndShowReminder();
    });
  }

  void cancelReminder() {
    _reminderTimer?.cancel();
  }

  /// Checks on app launch or home resume if 30+ minutes have passed since leaving an incomplete puzzle
  void checkPendingReminder(BuildContext context) {
    final activeSession = _storage.getActiveSession();
    if (activeSession == null) return;

    final locked = (activeSession['lockedPieceKeys'] as List?)?.length ?? 0;
    final total = (activeSession['pieceCount'] ?? activeSession['actualPieceCount']) as int? ?? 48;
    if (locked <= 0 || locked >= total) return;

    final lastSaved = activeSession['timestamp'] as int?;
    if (lastSaved != null) {
      final elapsed = DateTime.now().millisecondsSinceEpoch - lastSaved;
      // If 30+ minutes have passed (30 * 60 * 1000 = 1,800,000 ms)
      if (elapsed >= 30 * 60 * 1000) {
        _showReminderNotification(total - locked, activeSession);
      }
    }
  }

  void _checkAndShowReminder() {
    final activeSession = _storage.getActiveSession();
    if (activeSession == null) return;

    final locked = (activeSession['lockedPieceKeys'] as List?)?.length ?? 0;
    final total = (activeSession['pieceCount'] ?? activeSession['actualPieceCount']) as int? ?? 48;
    if (locked <= 0 || locked >= total) return;

    _showReminderNotification(total - locked, activeSession);
  }

  void _showReminderNotification(int remainingPieces, Map<String, dynamic> activeSession) {
    if (Get.isSnackbarOpen) return;

    Get.snackbar(
      '🧩 Complete Your Puzzle!',
      'You have $remainingPieces pieces remaining. Tap to resume playing!',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 8),
      backgroundColor: const Color(0xFA112238),
      colorText: Colors.white,
      icon: const Icon(Icons.extension_rounded, color: Color(0xFFFFB300), size: 28),
      mainButton: TextButton(
        onPressed: () {
          final picId = activeSession['pictureId'] as String?;
          final total = (activeSession['pieceCount'] ?? activeSession['actualPieceCount']) as int? ?? 48;
          final saga = activeSession['sagaLevel'] as int?;
          if (picId != null) {
            Get.context?.push(
              '/puzzle?id=$picId&pieces=$total${saga != null ? "&sagaLevel=$saga" : ""}&resume=true',
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF00E676),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'RESUME',
            style: TextStyle(
              color: Color(0xFF0E2A47),
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: 18,
    );
  }
}
