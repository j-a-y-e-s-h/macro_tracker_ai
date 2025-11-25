import 'dart:convert';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    final configuration = ProductSearchQueryConfiguration(
      parametersList: [
        SearchTerms(terms: [query]),
      ],
      language: OpenFoodFactsLanguage.ENGLISH,
      // languages: [OpenFoodFactsLanguage.ENGLISH], // Removed to avoid conflict
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
        const User(userId: '', password: ''),
        configuration,
      );

      return result.products ?? [];
    } catch (e) {
      print('Error searching products: $e');
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
      print('Error fetching product by barcode: $e');
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
