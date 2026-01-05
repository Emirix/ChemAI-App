import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chem_ai/data/chemical_suggestions.dart';

class ChemicalService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<ChemicalSuggestion>> searchChemicals(String query) async {
    if (query.isEmpty) return [];

    try {
      final response = await _client
          .from('raw_materials')
          .select()
          .or(
            'name.ilike.%$query%,cas_number.ilike.%$query%,formula.ilike.%$query%',
          )
          .limit(10);

      final List<dynamic> data = response as List<dynamic>;

      return data
          .map(
            (json) => ChemicalSuggestion(
              name: json['name'] as String,
              casNumber: json['cas_number'] as String? ?? '',
              formula: json['formula'] as String?,
            ),
          )
          .toList();
    } catch (e) {
      // Fail silently or log error
      return [];
    }
  }
}
