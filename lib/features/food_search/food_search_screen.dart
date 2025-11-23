import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:uuid/uuid.dart';
import '../../services/food_search_service.dart';
import '../../services/food_log_service.dart';
import '../../services/user_service.dart';
import '../../models/food_log_model.dart';

class FoodSearchScreen extends ConsumerStatefulWidget {
  const FoodSearchScreen({super.key});

  @override
  ConsumerState<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends ConsumerState<FoodSearchScreen> {
  final _searchController = TextEditingController();
  final _foodSearchService = FoodSearchService();
  
  List<Product> _searchResults = [];
  bool _isLoading = false;
  String? _error;

  Future<void> _search(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

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
    // Check platform support for scanning
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
        _addFoodLog(product);
      } else {
        setState(() => _error = 'Product not found');
      }
    } catch (e) {
      setState(() => _error = 'Scan failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addFoodLog(Product product) {
    final user = ref.read(userServiceProvider);
    if (user == null) return;

    // Extract macros (default to 0 if missing)
    final nutriments = product.nutriments;
    final calories = nutriments?.getValue(Nutrient.energyKCal, PerSize.oneHundredGrams) ?? 0;
    final protein = nutriments?.getValue(Nutrient.proteins, PerSize.oneHundredGrams) ?? 0;
    final carbs = nutriments?.getValue(Nutrient.carbohydrates, PerSize.oneHundredGrams) ?? 0;
    final fat = nutriments?.getValue(Nutrient.fat, PerSize.oneHundredGrams) ?? 0;
    final name = product.productName ?? 'Unknown Food';

    // Show dialog to confirm portion
    showDialog(
      context: context,
      builder: (context) => _AddFoodDialog(
        name: name,
        caloriesPer100g: calories,
        proteinPer100g: protein,
        carbsPer100g: carbs,
        fatPer100g: fat,
        onAdd: (factor) async {
           final log = FoodLog(
            id: const Uuid().v4(),
            userId: user.id,
            name: name,
            calories: calories * factor,
            protein: protein * factor,
            carbs: carbs * factor,
            fat: fat * factor,
            timestamp: DateTime.now(),
            isAiGenerated: false,
          );

          await ref.read(foodLogServiceProvider.notifier).addLog(log);
          if (mounted) {
            Navigator.pop(context); // Close dialog
            Navigator.pop(context); // Close search screen
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Food'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanBarcode,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search for food',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _search(_searchController.text),
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: _search,
            ),
          ),
          if (_isLoading)
            const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: _searchResults.isEmpty && !_isLoading && _searchController.text.isNotEmpty
                ? const Center(child: Text('No products found. Try a different term.'))
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final product = _searchResults[index];
                      return ListTile(
                        leading: product.imageFrontSmallUrl != null
                            ? Image.network(product.imageFrontSmallUrl!, width: 50, height: 50, errorBuilder: (c,e,s) => const Icon(Icons.fastfood))
                            : const Icon(Icons.fastfood),
                        title: Text(product.productName ?? 'Unknown', style: const TextStyle(color: Colors.white)),
                        subtitle: Text(product.brands ?? '', style: const TextStyle(color: Colors.grey)),
                        onTap: () => _addFoodLog(product),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class BarcodeScannerScreen extends StatelessWidget {
  const BarcodeScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Barcode')),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              Navigator.pop(context, barcode.rawValue);
              break; // Return first code found
            }
          }
        },
      ),
    );
  }
}

class _AddFoodDialog extends StatefulWidget {
  final String name;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final Function(double) onAdd;

  const _AddFoodDialog({
    required this.name,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    required this.onAdd,
  });

  @override
  State<_AddFoodDialog> createState() => _AddFoodDialogState();
}

class _AddFoodDialogState extends State<_AddFoodDialog> {
  double _grams = 100;

  @override
  Widget build(BuildContext context) {
    final factor = _grams / 100;
    return AlertDialog(
      title: Text(widget.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Calories: ${(widget.caloriesPer100g * factor).toInt()}'),
          Text('P: ${(widget.proteinPer100g * factor).toInt()}g  C: ${(widget.carbsPer100g * factor).toInt()}g  F: ${(widget.fatPer100g * factor).toInt()}g'),
          const SizedBox(height: 16),
          TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount (g)',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _grams = double.tryParse(value) ?? 100;
              });
            },
            controller: TextEditingController(text: '100'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => widget.onAdd(factor),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
