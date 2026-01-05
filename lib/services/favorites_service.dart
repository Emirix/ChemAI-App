import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:chem_ai/core/constants/app_colors.dart';

class FavoritesService extends ChangeNotifier {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;

  FavoritesService._internal();

  final List<Map<String, dynamic>> _favorites = [
    {
      'name': 'Ethanol',
      'cas': '64-17-5',
      'icon': Symbols.water_drop,
      'color': Colors.blue,
    },
    {
      'name': 'HCL',
      'cas': '7647-01-0',
      'icon': Symbols.science,
      'color': Colors.purple,
    },
    {
      'name': 'NaOH',
      'cas': '1310-73-2',
      'icon': Symbols.soap,
      'color': Colors.green,
    },
  ];

  List<Map<String, dynamic>> get favorites => _favorites;

  bool isFavorite(String name) {
    return _favorites.any((item) => item['name'] == name);
  }

  void toggleFavorite(String name, String cas, {IconData? icon, Color? color}) {
    if (isFavorite(name)) {
      _favorites.removeWhere((item) => item['name'] == name);
    } else {
      _favorites.add({
        'name': name,
        'cas': cas,
        'icon': icon ?? Symbols.science,
        'color': color ?? AppColors.primary,
      });
    }
    notifyListeners();
  }
}
