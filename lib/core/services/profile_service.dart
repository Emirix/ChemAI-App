import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user ID
  String? get userId => _supabase.auth.currentUser?.id;

  // Get profile data
  Future<Map<String, dynamic>?> getProfile() async {
    try {
      if (userId == null) return null;

      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId!)
          .maybeSingle();

      return data;
    } catch (e) {
      // If table doesn't exist or other error, return null or handle gracefully
      print('Error fetching profile: $e');
      return null;
    }
  }

  // Check if user is Plus member
  Future<bool> checkIsPlus() async {
    try {
      final profile = await getProfile();
      return profile?['is_plus'] ?? false;
    } catch (e) {
      return false;
    }
  }

  // Update profile data
  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? avatarUrl,
    bool? isPlus,
  }) async {
    if (userId == null) return;

    final updates = {
      'id': userId,
      'updated_at': DateTime.now().toIso8601String(),
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (isPlus != null) 'is_plus': isPlus,
    };

    try {
      await _supabase.from('profiles').upsert(updates);
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  // Get all companies for the user
  Future<List<Map<String, dynamic>>> getCompanies() async {
    try {
      if (userId == null) return [];

      // Try to fetch companies linked to this user.
      // Assuming 'companies' table has a 'profile_id' or 'user_id' column.
      // If the schema is strictly 1-to-1 via profiles.company_id, this might need migration.
      // We will try to select based on user_id if column exists, otherwise we fallback to the old method for backward compatibility until schema is updated.

      try {
        final data = await _supabase
            .from('companies')
            .select()
            .eq('user_id', userId!);

        return List<Map<String, dynamic>>.from(data);
      } catch (_) {
        // Fallback: existing structure (1 company linked in profiles)
        final profile = await getProfile();
        final companyId = profile?['company_id'];
        if (companyId != null) {
          final data = await _supabase
              .from('companies')
              .select()
              .eq('id', companyId)
              .maybeSingle();
          if (data != null) return [data];
        }
        return [];
      }
    } catch (e) {
      print('Error fetching companies: $e');
      return [];
    }
  }

  // Create a new company
  Future<void> addCompany({
    required String name,
    required String address,
    String? logoUrl,
  }) async {
    if (userId == null) return;

    try {
      await _supabase.from('companies').insert({
        'profile_id': userId, // New schema assumption
        'name': name,
        'address': address,
        'logo_url': logoUrl,
      });
    } catch (e) {
      print('Error adding company: $e');
      // If column profile_id doesn't exist, this will fail.
      // The user requested "add multiple companies", implying a DB change is acceptable or expected.
      rethrow;
    }
  }

  // Update existing company
  Future<void> updateCompany({
    required String companyId,
    String? name,
    String? address,
    String? logoUrl,
  }) async {
    try {
      final updates = {
        if (name != null) 'name': name,
        if (address != null) 'address': address,
        if (logoUrl != null) 'logo_url': logoUrl,
      };
      await _supabase.from('companies').update(updates).eq('id', companyId);
    } catch (e) {
      print('Error updating company: $e');
      rethrow;
    }
  }

  // Delete company
  Future<void> deleteCompany(String companyId) async {
    try {
      await _supabase.from('companies').delete().eq('id', companyId);
    } catch (e) {
      print('Error deleting company: $e');
      rethrow;
    }
  }

  // Upload Image
  Future<String?> uploadImage(
    File imageFile,
    String bucket,
    String path,
  ) async {
    try {
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${DateTime.now().toIso8601String()}.$fileExt';
      final fullPath = '$path/$fileName';

      await _supabase.storage
          .from(bucket)
          .upload(
            fullPath,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final imageUrl = _supabase.storage.from(bucket).getPublicUrl(fullPath);
      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }
}
