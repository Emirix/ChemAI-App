/// Yaygın kimyasal ürünler ve CAS numaraları
class ChemicalSuggestion {
  final String name;
  final String casNumber;
  final String? formula;

  const ChemicalSuggestion({
    required this.name,
    required this.casNumber,
    this.formula,
  });

  String get displayText => formula != null ? '$name ($formula)' : name;
}

/// Autocomplete için kimyasal öneriler listesi
/// Autocomplete için kimyasal öneriler listesi - ARTIK SUPABASE'DEN ÇEKİLİYOR
// const List<ChemicalSuggestion> chemicalSuggestions = [];
