import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// Centralized helper that syncs the Supabase profile row
/// into SharedPreferences so every screen can read the data
/// offline and instantly — even after a fresh login.
class ProfileSyncService {
  ProfileSyncService._();

  /// Call this after every successful login / app restart.
  /// It reads user-metadata + the profiles table and writes
  /// every field into SharedPreferences.
  static Future<void> syncProfileToLocal(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final meta = user.userMetadata;

      // 1. Grab name + dept from user-metadata (set at registration)
      String name = prefs.getString('user_name') ?? '';
      String dept = prefs.getString('user_dept') ?? '';

      if (name.isEmpty && meta != null && meta['full_name'] != null) {
        name = meta['full_name'].toString();
      }
      if (dept.isEmpty && meta != null && meta['department'] != null) {
        dept = meta['department'].toString();
      }

      // 2. Fetch the full profile row from Supabase
      try {
        final data = await SupabaseService.client
            .from('profiles')
            .select(
                'full_name, department, semester, current_cgpa, last_sem_cgpa, '
                'total_credits, completed_credits, target_cgpa, '
                'strong_basics, weak_basics')
            .eq('id', user.id)
            .maybeSingle();

        if (data != null) {
          // Name
          if (data['full_name'] != null &&
              data['full_name'].toString().isNotEmpty) {
            name = data['full_name'].toString();
          }
          // Department
          if (data['department'] != null &&
              data['department'].toString().isNotEmpty) {
            dept = data['department'].toString();
          }
          // Semester
          if (data['semester'] != null &&
              data['semester'].toString().isNotEmpty) {
            await prefs.setString('user_semester', data['semester'].toString());
          }

          // Numeric fields — helper
          Future<void> setNum(String key, String? simKey, dynamic val) async {
            if (val != null) {
              final s = val.toString();
              if (s.isNotEmpty && s != '0.0' && s != '0') {
                await prefs.setString(key, s);
                if (simKey != null) await prefs.setString(simKey, s);
              }
            }
          }

          await setNum('user_current_cgpa', 'sim_prev_cgpa', data['current_cgpa']);
          await setNum('user_last_sem_cgpa', null, data['last_sem_cgpa']);
          await setNum('user_target_cgpa', 'sim_target_cgpa', data['target_cgpa']);
          await setNum('user_total_credit', 'sim_total_credit', data['total_credits']);
          await setNum('user_completed_credit', 'sim_completed_credit', data['completed_credits']);

          // Lists
          if (data['strong_basics'] != null) {
            await prefs.setString(
                'user_strong_basics', jsonEncode(data['strong_basics']));
          }
          if (data['weak_basics'] != null) {
            await prefs.setString(
                'user_weak_basics', jsonEncode(data['weak_basics']));
          }
        }
      } catch (_) {
        // Supabase fetch failed — fine, local data stays intact
      }

      // 3. Always persist name & dept (may come from metadata only)
      if (name.isNotEmpty) await prefs.setString('user_name', name);
      if (dept.isNotEmpty) await prefs.setString('user_dept', dept);
    } catch (_) {}
  }
}
