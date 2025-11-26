import 'dart:convert';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final foodSearchServiceProvider = Provider<FoodSearchService>((ref) {
  return FoodSearchService();
});

class FoodSearchService {
  FoodSearchService() {
    _initUserAgent();
  }

  void _initUserAgent() {
    OpenFoodAPIConfiguration.userAgent = UserAgent(
      name: 'MacroMate',
      url: 'https://github.com/macromate',
    );
  }

  Future<List<Product>> searchProducts(String query) async {
    _initUserAgent();
    if (query.isEmpty) return [];
    debugPrint('Searching for "$query" with 30s timeout...');

    // 1. Try generic search first (broadest possible)
    final configuration = ProductSearchQueryConfiguration(
      parametersList: [
        SearchTerms(terms: [query]),
      ],
      language: OpenFoodFactsLanguage.ENGLISH,
      fields: [
        ProductField.NAME,
        ProductField.BRANDS,
        ProductField.NUTRIMENTS,
        ProductField.IMAGE_FRONT_URL,
        ProductField.QUANTITY,
        ProductField.SERVING_SIZE,
      ],
      version: ProductQueryVersion.v3,
    );

    try {
      final result = await OpenFoodAPIClient.searchProducts(
        null, // User can be null for anonymous access
        configuration,
      ).timeout(const Duration(seconds: 30));

      if (result.products != null && result.products!.isNotEmpty) {
        return result.products!;
      }
      
      // 2. If empty, try fallback to global explicitly
      return await _searchGlobal(query);
    } catch (e) {
      debugPrint('Error searching products: $e');
      return await _searchGlobal(query);
    }
  }

  Future<List<Product>> _searchGlobal(String query) async {
     final configuration = ProductSearchQueryConfiguration(
      parametersList: [
        SearchTerms(terms: [query]),
      ],
      language: OpenFoodFactsLanguage.ENGLISH,
      fields: [
        ProductField.NAME,
        ProductField.BRANDS,
        ProductField.NUTRIMENTS,
        ProductField.IMAGE_FRONT_URL,
        ProductField.QUANTITY,
      ],
      version: ProductQueryVersion.v3,
    );

    try {
      final result = await OpenFoodAPIClient.searchProducts(
        null,
        configuration,
      ).timeout(const Duration(seconds: 30));
      return result.products ?? [];
    } catch (e) {
      debugPrint('Global search error: $e');
      return [];
    }
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    if (barcode.isEmpty) return null;

    final configuration = ProductQueryConfiguration(
      barcode,
      language: OpenFoodFactsLanguage.ENGLISH,
      fields: [
        ProductField.NAME,
        ProductField.BRANDS,
        ProductField.NUTRIMENTS,
        ProductField.IMAGE_FRONT_URL,
        ProductField.QUANTITY,
      ],
      version: ProductQueryVersion.v3,
    );

    try {
      final result = await OpenFoodAPIClient.getProductV3(configuration);
      return result.product;
    } catch (e) {
      debugPrint('Error fetching product by barcode: $e');
      return null;
    }
  }

  // History & Favorites
  static const String _historyKey = 'search_history';
  static const String _favoritesKey = 'favorites';

  Future<List<String>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_historyKey) ?? [];
  }

  Future<void> addToHistory(String term) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_historyKey) ?? [];
    if (!history.contains(term)) {
      history.insert(0, term);
      if (history.length > 20) history.removeLast(); // Limit to 20 items
      await prefs.setStringList(_historyKey, history);
    }
  }

  Future<List<Product>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getStringList(_favoritesKey) ?? [];
    return favoritesJson.map((e) => Product.fromJson(jsonDecode(e))).toList();
  }

  Future<void> toggleFavorite(Product product) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_favoritesKey) ?? [];
    
    // Check if exists (by barcode or name)
    final index = favorites.indexWhere((e) {
      final p = Product.fromJson(jsonDecode(e));
      return p.barcode == product.barcode && p.productName == product.productName;
    });

    if (index >= 0) {
      favorites.removeAt(index);
    } else {
      favorites.add(jsonEncode(product.toJson()));
    }
    await prefs.setStringList(_favoritesKey, favorites);
  }

  Future<bool> isFavorite(Product product) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_favoritesKey) ?? [];
    return favorites.any((e) {
      final p = Product.fromJson(jsonDecode(e));
      return p.barcode == product.barcode && p.productName == product.productName;
    });
  }
}
