import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';

// ... imports ...



import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../services/food_search_service.dart';
import '../../services/food_log_service.dart';
import '../../services/user_service.dart';
import '../../models/food_log_model.dart';
import '../logging/food_detail_sheet.dart';

class FoodSearchScreen extends ConsumerStatefulWidget {
  const FoodSearchScreen({super.key});

  @override
  ConsumerState<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends ConsumerState<FoodSearchScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  final _foodSearchService = FoodSearchService();
  
  List<Product> _searchResults = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search food...',
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.search, color: AppTheme.primary),
              onPressed: () => _search(_searchController.text),
            ),
          ),
          style: const TextStyle(color: Colors.white),
          onSubmitted: _search,
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(text: 'Search'),
            Tab(text: 'History'),
            Tab(text: 'Favorites'),
            Tab(text: 'Common'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanBarcode,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSearchResults(),
          _buildHistoryList(),
          _buildFavoritesList(),
          _buildCommonList(),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    }
    if (_searchResults.isEmpty) {
      return const Center(child: Text('No results found', style: TextStyle(color: AppTheme.textSecondary)));
    }
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final product = _searchResults[index];
        return _buildProductTile(product);
      },
    );
  }

  Widget _buildHistoryList() {
    return FutureBuilder<List<String>>(
      future: _foodSearchService.getHistory(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No search history', style: TextStyle(color: AppTheme.textSecondary)));
        }
        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final term = snapshot.data![index];
            return ListTile(
              leading: const Icon(Icons.history, color: AppTheme.textSecondary),
              title: Text(term, style: const TextStyle(color: Colors.white)),
              onTap: () {
                _searchController.text = term;
                _search(term);
                _tabController.animateTo(0);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFavoritesList() {
    return FutureBuilder<List<Product>>(
      future: _foodSearchService.getFavorites(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No favorites yet', style: TextStyle(color: AppTheme.textSecondary)));
        }
        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            return _buildProductTile(snapshot.data![index]);
          },
        );
      },
    );
  }

  Widget _buildCommonList() {
    final commonFoods = [
      'Apple', 'Banana', 'Chicken Breast', 'Rice (White)', 'Egg', 'Oatmeal', 'Milk', 'Almonds', 'Salmon', 'Broccoli'
    ];

    return ListView.builder(
      itemCount: commonFoods.length,
      itemBuilder: (context, index) {
        final foodName = commonFoods[index];
        return ListTile(
          leading: const Icon(Icons.local_dining, color: AppTheme.textSecondary),
          title: Text(foodName, style: const TextStyle(color: Colors.white)),
          trailing: const Icon(Icons.search, color: AppTheme.primary),
          onTap: () {
            _searchController.text = foodName;
            _search(foodName);
            _tabController.animateTo(0);
          },
        );
      },
    );
  }

  Widget _buildProductTile(Product product) {
    return FutureBuilder<bool>(
      future: _foodSearchService.isFavorite(product),
      builder: (context, snapshot) {
        final isFav = snapshot.data ?? false;
        return ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.surfaceHighlight,
              borderRadius: BorderRadius.circular(8),
              image: product.imageFrontUrl != null
                  ? DecorationImage(
                      image: NetworkImage(product.imageFrontUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: product.imageFrontUrl == null
                ? const Icon(Icons.restaurant, color: AppTheme.textSecondary)
                : null,
          ),
          title: Text(product.productName ?? 'Unknown', style: const TextStyle(color: Colors.white)),
          subtitle: Text('${product.brands ?? ''} - ${product.quantity ?? ''}', style: const TextStyle(color: AppTheme.textSecondary)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(isFav ? Icons.star : Icons.star_border, color: isFav ? Colors.amber : AppTheme.textSecondary),
                onPressed: () async {
                  await _foodSearchService.toggleFavorite(product);
                  setState(() {}); // Refresh UI
                },
              ),
              const Icon(Icons.add_circle_outline, color: AppTheme.primary),
            ],
          ),
          onTap: () => _showFoodDetail(product),
        );
      },
    );
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Add to history
    await _foodSearchService.addToHistory(query);

    try {
      final results = await _foodSearchService.searchProducts(query);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Search failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _scanBarcode() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Barcode scanning is only available on mobile devices.')),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );

    if (result is String) {
      _fetchProductByBarcode(result);
    }
  }

  Future<void> _fetchProductByBarcode(String barcode) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final product = await _foodSearchService.getProductByBarcode(barcode);
      if (product != null) {
        _showFoodDetail(product);
      } else {
        setState(() => _error = 'Product not found');
      }
    } catch (e) {
      setState(() => _error = 'Scan failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showFoodDetail(Product product) {
    final nutriments = product.nutriments;
    final calories = nutriments?.getValue(Nutrient.energyKCal, PerSize.oneHundredGrams) ?? 0;
    final protein = nutriments?.getValue(Nutrient.proteins, PerSize.oneHundredGrams) ?? 0;
    final carbs = nutriments?.getValue(Nutrient.carbohydrates, PerSize.oneHundredGrams) ?? 0;
    final fat = nutriments?.getValue(Nutrient.fat, PerSize.oneHundredGrams) ?? 0;
    final name = product.productName ?? 'Unknown Food';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: FoodDetailSheet(
          name: name,
          calories: calories,
          protein: protein,
          carbs: carbs,
          fat: fat,
          onAdd: (factor, timestamp) => _addFoodLog(name, calories, protein, carbs, fat, factor, timestamp),
        ),
      ),
    );
  }

  Future<void> _addFoodLog(String name, double cals, double prot, double carbs, double fat, double factor, DateTime timestamp) async {
    final user = ref.read(userServiceProvider);
    if (user == null) return;

    final log = FoodLog(
      id: const Uuid().v4(),
      userId: user.id,
      name: name,
      calories: cals * factor,
      protein: prot * factor,
      carbs: carbs * factor,
      fat: fat * factor,
      timestamp: timestamp,
      isAiGenerated: false,
    );
    ref.read(foodLogServiceProvider.notifier).addLog(log);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added $name to log')),
      );
    }
  }
}

class BarcodeScannerScreen extends StatelessWidget {
  const BarcodeScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Barcode')),
      body: const Center(
        child: Text('Barcode scanning not supported on Windows', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
