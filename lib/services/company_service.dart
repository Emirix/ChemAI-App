import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/company.dart';
import '../core/constants/api_constants.dart';

class CompanyService {
  static String get baseUrl => ApiConstants.baseUrl;

  /// Get all companies for a user
  Future<List<Company>> getCompanies(String userId) async {
    final url = '$baseUrl/companies';
    debugPrint('CompanyService: Fetching companies for user $userId');

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'userId': userId}),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('CompanyService: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        final List<dynamic> companiesJson = result['companies'] as List;

        return companiesJson
            .map((json) => Company.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        debugPrint('CompanyService: Error response: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('CompanyService: Error fetching companies: $e');
      return [];
    }
  }

  /// Get a single company by ID
  Future<Company?> getCompanyById(String companyId, String userId) async {
    final url = '$baseUrl/companies/get';
    debugPrint('CompanyService: Fetching company $companyId');

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'companyId': companyId, 'userId': userId}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        return Company.fromJson(result['company'] as Map<String, dynamic>);
      } else {
        debugPrint('CompanyService: Company not found');
        return null;
      }
    } catch (e) {
      debugPrint('CompanyService: Error fetching company: $e');
      return null;
    }
  }

  /// Create a new company
  Future<Company?> createCompany(Company company) async {
    final url = '$baseUrl/companies/create';
    debugPrint('CompanyService: Creating company ${company.companyName}');

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(company.toJson()),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('CompanyService: Response status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        debugPrint('CompanyService: Company created successfully');
        return Company.fromJson(result['company'] as Map<String, dynamic>);
      } else {
        debugPrint('CompanyService: Error creating company: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('CompanyService: Error creating company: $e');
      return null;
    }
  }

  /// Update an existing company
  Future<Company?> updateCompany(Company company) async {
    final url = '$baseUrl/companies/update';
    debugPrint('CompanyService: Updating company ${company.id}');

    try {
      final requestBody = company.toJson();
      requestBody['companyId'] = company.id;

      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        debugPrint('CompanyService: Company updated successfully');
        return Company.fromJson(result['company'] as Map<String, dynamic>);
      } else {
        debugPrint('CompanyService: Error updating company: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('CompanyService: Error updating company: $e');
      return null;
    }
  }

  /// Delete a company
  Future<bool> deleteCompany(String companyId, String userId) async {
    final url = '$baseUrl/companies/delete';
    debugPrint('CompanyService: Deleting company $companyId');

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'companyId': companyId, 'userId': userId}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        debugPrint('CompanyService: Company deleted successfully');
        return true;
      } else {
        debugPrint('CompanyService: Error deleting company: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('CompanyService: Error deleting company: $e');
      return false;
    }
  }

  /// Set a company as default
  Future<Company?> setDefaultCompany(String companyId, String userId) async {
    final url = '$baseUrl/companies/set-default';
    debugPrint('CompanyService: Setting default company $companyId');

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'companyId': companyId, 'userId': userId}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        debugPrint('CompanyService: Default company set successfully');
        return Company.fromJson(result['company'] as Map<String, dynamic>);
      } else {
        debugPrint('CompanyService: Error setting default: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('CompanyService: Error setting default company: $e');
      return null;
    }
  }

  /// Get the default company for a user
  Future<Company?> getDefaultCompany(String userId) async {
    final url = '$baseUrl/companies/default';
    debugPrint('CompanyService: Fetching default company for user $userId');

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'userId': userId}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        final companyData = result['company'];

        if (companyData != null) {
          return Company.fromJson(companyData as Map<String, dynamic>);
        }
        return null;
      } else {
        debugPrint(
          'CompanyService: Error getting default company: ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('CompanyService: Error getting default company: $e');
      return null;
    }
  }
}
