import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;

import 'dart:convert';

import '../../data/datasources/pharmacy.service.dart';

class Medicine {
  final String id;
  final String name;
  final String genericName;
  final String manufacturer;
  final String category;
  final double mrpRate;
  final double buyRate;
  final double sellRate;
  final double profitMargin;
  int currentStock;
  final int minStockLevel;
  final String batchNumber;
  final DateTime expiryDate;
  final DateTime? createdAt;
  final String? createdBy;
  final DateTime? updatedAt;
  final String? updatedBy;
  final bool isExpired;
  final bool isLowStock;

  Medicine({
    required this.id,
    required this.name,
    required this.genericName,
    required this.manufacturer,
    this.category = 'General',
    required this.mrpRate,
    required this.buyRate,
    required this.sellRate,
    required this.profitMargin,
    required this.currentStock,
    this.minStockLevel = 10,
    required this.batchNumber,
    required this.expiryDate,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
    bool? isExpired,
    bool? isLowStock,
  })  : isExpired = isExpired ?? DateTime.now().isAfter(expiryDate),
        isLowStock = isLowStock ?? (currentStock <= minStockLevel);

  bool get isNearExpiry {
    final difference = expiryDate.difference(DateTime.now()).inDays;
    return difference <= 90 && difference > 0;
  }
  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      genericName: json['genericName'] ?? '',
      manufacturer: json['manufacturer'] ?? '',
      category: json['category'] ?? 'General',
      mrpRate: (json['mrpRate'] ?? 0).toDouble(),
      buyRate: (json['buyRate'] ?? 0).toDouble(),
      sellRate: (json['sellRate'] ?? 0).toDouble(),
      profitMargin: (json['profitMargin'] ?? 0).toDouble(),
      currentStock: json['currentStock'] ?? 0,
      minStockLevel: json['minStockLevel'] ?? 10,
      batchNumber: json['batchNumber'] ?? '',
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'])
          : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      createdBy: json['createdBy'],
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      updatedBy: json['updatedBy'],
      isExpired: json['isExpired'] ?? false,
      isLowStock: json['isLowStock'] ?? false,
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'genericName': genericName,
      'manufacturer': manufacturer,
      'category': category,
      'mrpRate': mrpRate,
      'buyRate': buyRate,
      'sellRate': sellRate,
      'currentStock': currentStock,
      'minStockLevel': minStockLevel,
      'batchNumber': batchNumber,
      'expiryDate': expiryDate.toIso8601String(),
    };
  }

  Medicine copyWith({
    String? id,
    String? name,
    String? genericName,
    String? manufacturer,
    String? category,
    double? mrpRate,
    double? buyRate,
    double? sellRate,
    int? currentStock,
    int? minStockLevel,
    String? batchNumber,
    DateTime? expiryDate,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      genericName: genericName ?? this.genericName,
      manufacturer: manufacturer ?? this.manufacturer,
      category: category ?? this.category,
      mrpRate: mrpRate ?? this.mrpRate,
      profitMargin: profitMargin ?? this.profitMargin,
      buyRate: buyRate ?? this.buyRate,
      sellRate: sellRate ?? this.sellRate,
      currentStock: currentStock ?? this.currentStock,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      batchNumber: batchNumber ?? this.batchNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      createdAt: this.createdAt,
      createdBy: this.createdBy,
      updatedAt: this.updatedAt,
      updatedBy: this.updatedBy,
    );
  }
}

class BillingItem {
  Medicine medicine;
  int quantity;
  double totalPrice;

  BillingItem({
    required this.medicine,
    required this.quantity,
    required this.totalPrice,
  });
}

class PharmacyController extends ChangeNotifier {
  final MedicineService _medicineService = MedicineService();
  List<Medicine> _medicines = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Medicine> get medicines => _medicines;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Constructor
  PharmacyController() {
    fetchAllMedicines();
  }

  // Fetch all medicines from API
  Future<void> fetchAllMedicines() async {
    _setLoading(true);
    try {
      _medicines = await _medicineService.fetchMedicines();
      _error = null;
    } catch (e) {
      _error = 'Failed to load medicines: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Add new medicine
  Future<void> addNewMedicine(Medicine medicine) async {
    _setLoading(true);
    try {
      final newMedicine = await _medicineService.createMedicine(medicine);
      _medicines.add(newMedicine);
      _error = null;
    } catch (e) {
      _error = 'Failed to add medicine: $e';
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // Update medicine
  Future<void> updateMedicine(Medicine medicine) async {
    _setLoading(true);
    try {
      final updatedMedicine = await _medicineService.updateMedicine(medicine.id, medicine);
      final index = _medicines.indexWhere((m) => m.id == medicine.id);
      if (index != -1) {
        _medicines[index] = updatedMedicine;
      }
      _error = null;
    } catch (e) {
      _error = 'Failed to update medicine: $e';
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // Delete medicine
  Future<void> deleteMedicine( id) async {
    _setLoading(true);
    try {
      await _medicineService.deleteMedicine(id);
      _medicines.removeWhere((m) => m.id == id);
      _error = null;
    } catch (e) {
      _error = 'Failed to delete medicine: $e';
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // Update medicine stock
  Future<void> updateMedicineStock(String id, int additionalStock) async {
    _setLoading(true);
    try {
      final updatedMedicine = await _medicineService.updateMedicineStock(id, additionalStock);
      final index = _medicines.indexWhere((m) => m.id == id);
      if (index != -1) {
        _medicines[index] = updatedMedicine;
      }
      _error = null;
    } catch (e) {
      _error = 'Failed to update medicine stock: $e';
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // Search medicines
  Future<List<Medicine>> searchMedicines(String query) async {
    try {
      if (query.isEmpty) {
        return _medicines;
      }
      return await _medicineService.searchMedicines(query);
    } catch (e) {
      _error = 'Failed to search medicines: $e';
      return [];
    }
  }

  // Get low stock medicines
  List<Medicine> getLowStockMedicines() {
    return _medicines.where((medicine) => medicine.isLowStock).toList();
  }

  // Get expired medicines
  List<Medicine> getExpiredMedicines() {
    return _medicines.where((medicine) => medicine.isExpired).toList();
  }

  // Helper method to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}