/*
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:intl/intl.dart';
import 'package:health/presentation/controller/pharmacy.controller.dart';
import '../controller/language.controller.dart';
import '../widgets/language.widgets.dart';

// Define a comprehensive color scheme
class PharmacyTheme {
  // Primary colors
  static const Color primaryColor = Color(0xFF1E88E5); // Professional blue
  static const Color primaryDarkColor = Color(0xFF1565C0);
  static const Color primaryLightColor = Color(0xFF64B5F6);

  // Accent colors
  static const Color accentColor = Color(0xFF26A69A); // Teal accent

  // Background colors
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color cardColor = Colors.white;

  // Text colors
  static const Color primaryTextColor = Color(0xFF2C3E50);
  static const Color secondaryTextColor = Color(0xFF7F8C8D);

  // Alert colors
  static const Color errorColor = Color(0xFFE53935);
  static const Color warningColor = Color(0xFFFFA726);
  static const Color successColor = Color(0xFF2E7D32);

  // Status colors
  static const Color lowStockColor = Color(0xFFEF5350);
  static const Color expiredColor = Color(0xFFF44336);
  static const Color goodStockColor = Color(0xFF4CAF50);
}

class Medicine {
  final String id;
  final String name;
  final String genericName;
  final String manufacturer;
  final String category;
  final double mrpRate;
  final double buyRate;
  final double sellRate;
  final int currentStock;
  final String batchNumber;
  final DateTime expiryDate;

  Medicine({
    required this.id,
    required this.name,
    required this.genericName,
    required this.manufacturer,
    required this.category,
    required this.mrpRate,
    required this.buyRate,
    required this.sellRate,
    required this.currentStock,
    required this.batchNumber,
    required this.expiryDate,
  });

  bool get isLowStock => currentStock < 10;
  bool get isExpired => expiryDate.isBefore(DateTime.now());
  bool get isNearExpiry {
    final difference = expiryDate.difference(DateTime.now()).inDays;
    return difference <= 90 && difference > 0;
  }

  double get profit => sellRate - buyRate;
  double get profitMargin => profit / buyRate * 100;
}

class PharmacyController {
  List<Medicine> medicines = [];

  Future<void> fetchAllMedicines() async {
    // Simulated data for demo purposes
    await Future.delayed(const Duration(seconds: 1));
    medicines = [
      Medicine(
        id: '1',
        name: 'Paracetamol',
        genericName: 'Acetaminophen',
        manufacturer: 'ABC Pharma',
        category: 'Pain Relief',
        mrpRate: 5.0,
        buyRate: 3.0,
        sellRate: 4.5,
        currentStock: 100,
        batchNumber: 'BATCH001',
        expiryDate: DateTime(2026, 5, 15),
      ),
      Medicine(
        id: '2',
        name: 'Amoxicillin',
        genericName: 'Amoxicillin',
        manufacturer: 'XYZ Pharmaceuticals',
        category: 'Antibiotics',
        mrpRate: 12.0,
        buyRate: 8.0,
        sellRate: 11.0,
        currentStock: 50,
        batchNumber: 'BATCH002',
        expiryDate: DateTime(2025, 12, 31),
      ),
      Medicine(
        id: '3',
        name: 'Ibuprofen',
        genericName: 'Ibuprofen',
        manufacturer: 'Health Pharma',
        category: 'Anti-inflammatory',
        mrpRate: 7.0,
        buyRate: 4.5,
        sellRate: 6.5,
        currentStock: 5,
        batchNumber: 'BATCH003',
        expiryDate: DateTime(2025, 8, 15),
      ),
      Medicine(
        id: '4',
        name: 'Aspirin',
        genericName: 'Acetylsalicylic Acid',
        manufacturer: 'MedCare',
        category: 'Pain Relief',
        mrpRate: 6.0,
        buyRate: 3.5,
        sellRate: 5.5,
        currentStock: 200,
        batchNumber: 'BATCH004',
        expiryDate: DateTime(2025, 7, 10),
      ),
      Medicine(
        id: '5',
        name: 'Cetirizine',
        genericName: 'Cetirizine HCl',
        manufacturer: 'AllCure',
        category: 'Antihistamine',
        mrpRate: 8.0,
        buyRate: 5.0,
        sellRate: 7.5,
        currentStock: 30,
        batchNumber: 'BATCH005',
        expiryDate: DateTime(2025, 6, 1),
      ),
    ];
  }

  Future<void> addNewMedicine(Medicine medicine) async {
    await Future.delayed(const Duration(milliseconds: 500));
    medicines.add(medicine);
  }

  Future<void> updateMedicine(Medicine updatedMedicine) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = medicines.indexWhere((med) => med.id == updatedMedicine.id);
    if (index != -1) {
      medicines[index] = updatedMedicine;
    }
  }

  Future<void> deleteMedicine(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    medicines.removeWhere((med) => med.id == id);
  }

  Future<void> updateMedicineStock(String id, int stockChange) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = medicines.indexWhere((med) => med.id == id);
    if (index != -1) {
      final medicine = medicines[index];
      final newStock = medicine.currentStock + stockChange;

      medicines[index] = Medicine(
        id: medicine.id,
        name: medicine.name,
        genericName: medicine.genericName,
        manufacturer: medicine.manufacturer,
        category: medicine.category,
        mrpRate: medicine.mrpRate,
        buyRate: medicine.buyRate,
        sellRate: medicine.sellRate,
        currentStock: newStock,
        batchNumber: medicine.batchNumber,
        expiryDate: medicine.expiryDate,
      );
    }
  }
}

class Pharmacy extends StatefulWidget {
  const Pharmacy({Key? key}) : super(key: key);

  @override
  _PharmacyManagementPageState createState() => _PharmacyManagementPageState();
}

class _PharmacyManagementPageState extends State<Pharmacy> {
  final PharmacyController _pharmacyController = PharmacyController();
  final TextEditingController _searchController = TextEditingController();
  final LanguageController _languageController = LanguageController();

  // Tab controller for different sections
  int _currentTabIndex = 0;

  // Form controllers for adding new medicine
  final _nameController = TextEditingController();
  final _genericNameController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _mrpRateController = TextEditingController();
  final _buyRateController = TextEditingController();
  final _sellRateController = TextEditingController();
  final _currentStockController = TextEditingController();
  final _batchNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();

  // Filtering and searching
  List<Medicine> _filteredMedicines = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMedicines();

    // Set system UI overlay style for a more professional look
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: PharmacyTheme.primaryDarkColor,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  // Load medicines with loading state
  Future<void> _loadMedicines() async {
    setState(() {
      _isLoading = true;
    });

    await _pharmacyController.fetchAllMedicines();

    setState(() {
      _filteredMedicines = _pharmacyController.medicines;
      _isLoading = false;
    });
  }

  // Search functionality
  void _filterMedicines(String query) {
    setState(() {
      _filteredMedicines = _pharmacyController.medicines
          .where((medicine) =>
      medicine.name.toLowerCase().contains(query.toLowerCase()) ||
          medicine.genericName.toLowerCase().contains(query.toLowerCase()) ||
          medicine.manufacturer.toLowerCase().contains(query.toLowerCase())
      )
          .toList();
    });
  }

  // Add New Medicine Dialog
  void _showAddMedicineDialog() {
    // Clear controllers before showing dialog
    _nameController.clear();
    _genericNameController.clear();
    _manufacturerController.clear();
    _mrpRateController.clear();
    _buyRateController.clear();
    _sellRateController.clear();
    _currentStockController.clear();
    _batchNumberController.clear();
    _expiryDateController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Add Medicine',
            style: const TextStyle(
              color: PharmacyTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: PharmacyTheme.cardColor,
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(
                  controller: _nameController,
                  labelText: 'Medicine Name',
                  prefixIcon: Icons.medication,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _genericNameController,
                  labelText: 'Generic Name',
                  prefixIcon: Icons.biotech,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _manufacturerController,
                  labelText: 'Manufacturer',
                  prefixIcon: Icons.factory,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _mrpRateController,
                  labelText: 'MRP Rate',
                  prefixIcon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _buyRateController,
                  labelText: 'Buy Rate',
                  prefixIcon: Icons.download,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _sellRateController,
                  labelText: 'Sell Rate',
                  prefixIcon: Icons.upload,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _currentStockController,
                  labelText: 'Current Stock',
                  prefixIcon: Icons.inventory,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _batchNumberController,
                  labelText: 'Batch Number',
                  prefixIcon: Icons.format_list_numbered,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _expiryDateController,
                  labelText: 'Expiry Date',
                  prefixIcon: Icons.calendar_today,
                  readOnly: true,
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: PharmacyTheme.primaryColor,
                              onPrimary: Colors.white,
                              surface: PharmacyTheme.cardColor,
                              onSurface: PharmacyTheme.primaryTextColor,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );

                    if (pickedDate != null) {
                      _expiryDateController.text =
                          DateFormat('yyyy-MM-dd').format(pickedDate);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                'Cancel',
                style: const TextStyle(color: PharmacyTheme.secondaryTextColor),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: PharmacyTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Add'),
              onPressed: () async {
                // Validate form
                if (_nameController.text.isEmpty ||
                    _mrpRateController.text.isEmpty ||
                    _sellRateController.text.isEmpty ||
                    _currentStockController.text.isEmpty ||
                    _expiryDateController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please fill all required fields'),
                      backgroundColor: PharmacyTheme.errorColor,
                    ),
                  );
                  return;
                }

                // Create new medicine
                final newMedicine = Medicine(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: _nameController.text,
                  genericName: _genericNameController.text,
                  manufacturer: _manufacturerController.text,
                  category: 'General',
                  mrpRate: double.parse(_mrpRateController.text),
                  buyRate: double.parse(_buyRateController.text),
                  sellRate: double.parse(_sellRateController.text),
                  currentStock: int.parse(_currentStockController.text),
                  batchNumber: _batchNumberController.text,
                  expiryDate: DateFormat('yyyy-MM-dd').parse(
                      _expiryDateController.text),
                );

                // Show loading indicator
                setState(() {
                  _isLoading = true;
                });

                // Add medicine and update UI
                await _pharmacyController.addNewMedicine(newMedicine);

                setState(() {
                  _filteredMedicines = _pharmacyController.medicines;
                  _isLoading = false;
                });

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Medicine Added: ${newMedicine.name}'),
                    backgroundColor: PharmacyTheme.successColor,
                  ),
                );

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Reusable text field widget
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    IconData? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    Function()? onTap,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: PharmacyTheme.secondaryTextColor),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: PharmacyTheme.primaryColor)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: PharmacyTheme.primaryLightColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: PharmacyTheme.primaryColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: PharmacyTheme.primaryLightColor),
        ),
        filled: true,
        fillColor: PharmacyTheme.cardColor,
      ),
      style: const TextStyle(color: PharmacyTheme.primaryTextColor),
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
    );
  }

  // Build a medicine card for display
  Widget _buildMedicineCard(Medicine medicine) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: medicine.isExpired
                ? PharmacyTheme.expiredColor.withOpacity(0.3)
                : medicine.isLowStock
                ? PharmacyTheme.lowStockColor.withOpacity(0.3)
                : PharmacyTheme.primaryLightColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: medicine.isExpired
                ? PharmacyTheme.expiredColor
                : medicine.isLowStock
                ? PharmacyTheme.lowStockColor
                : PharmacyTheme.primaryColor,
            child: Icon(
              medicine.isExpired
                  ? Icons.error_outline
                  : medicine.isLowStock
                  ? Icons.warning_amber_outlined
                  : Icons.medication_outlined,
              color: Colors.white,
            ),
          ),
          title: Text(
            medicine.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: PharmacyTheme.primaryTextColor,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                medicine.genericName,
                style: const TextStyle(
                  color: PharmacyTheme.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.inventory,
                    size: 16,
                    color: medicine.isLowStock
                        ? PharmacyTheme.lowStockColor
                        : PharmacyTheme.goodStockColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Stock: ${medicine.currentStock}',
                    style: TextStyle(
                      color: medicine.isLowStock
                          ? PharmacyTheme.lowStockColor
                          : PharmacyTheme.goodStockColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: medicine.isExpired || medicine.isNearExpiry
              ? Tooltip(
            message: medicine.isExpired
                ? 'Expired'
                : 'Expires in ${medicine.expiryDate.difference(DateTime.now()).inDays} days',
            child: Icon(
              Icons.watch_later_outlined,
              color: medicine.isExpired
                  ? PharmacyTheme.expiredColor
                  : PharmacyTheme.warningColor,
            ),
          )
              : const Icon(Icons.keyboard_arrow_down),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Details Section
                  const Text(
                    'Details',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: PharmacyTheme.primaryTextColor,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.factory_outlined,
                          title: 'Manufacturer',
                          value: medicine.manufacturer,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.category_outlined,
                          title: 'Category',
                          value: medicine.category,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.format_list_numbered,
                          title: 'Batch',
                          value: medicine.batchNumber,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.event_outlined,
                          title: 'Expiry',
                          value: DateFormat('MMM dd, yyyy').format(medicine.expiryDate),
                          valueColor: medicine.isExpired
                              ? PharmacyTheme.expiredColor
                              : medicine.isNearExpiry
                              ? PharmacyTheme.warningColor
                              : null,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Pricing Section
                  const Text(
                    'Pricing',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: PharmacyTheme.primaryTextColor,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.shopping_basket_outlined,
                          title: 'Buy Rate',
                          value: '\$${medicine.buyRate.toStringAsFixed(2)}',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.sell_outlined,
                          title: 'Sell Rate',
                          value: '\$${medicine.sellRate.toStringAsFixed(2)}',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.attach_money,
                          title: 'MRP',
                          value: '\$${medicine.mrpRate.toStringAsFixed(2)}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildInfoCard(
                    icon: Icons.trending_up,
                    title: 'Profit Margin',
                    value: '${medicine.profitMargin.toStringAsFixed(2)}%',
                    valueColor: PharmacyTheme.accentColor,
                  ),

                  const SizedBox(height: 16),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: Icons.edit,
                        label: 'Edit',
                        color: PharmacyTheme.primaryColor,
                        onPressed: () => _showEditMedicineDialog(medicine),
                      ),
                      _buildActionButton(
                        icon: Icons.inventory_2_outlined,
                        label: 'Stock',
                        color: PharmacyTheme.accentColor,
                        onPressed: () => _showUpdateStockDialog(medicine),
                      ),
                      _buildActionButton(
                        icon: Icons.delete_outline,
                        label: 'Delete',
                        color: PharmacyTheme.errorColor,
                        onPressed: () => _showDeleteConfirmationDialog(medicine),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Info card for medicine details
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PharmacyTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: PharmacyTheme.secondaryTextColor,
              ),
              const SizedBox(width: 4),
              Text(
                title,
                style: const TextStyle(
                  color: PharmacyTheme.secondaryTextColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? PharmacyTheme.primaryTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Action button for medicine card
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showEditMedicineDialog(Medicine medicine) {
    // Implementation would go here
    // This is a placeholder to handle the function reference
  }

  void _showDeleteConfirmationDialog(Medicine medicine) {
    // Implementation would go here
    // This is a placeholder to handle the function reference
  }

  void _showUpdateStockDialog(Medicine medicine) {
    // Implementation would go here
    // This is a placeholder to handle the function reference
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PharmacyTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: PharmacyTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        title: const Text(
          'Pharmacy Management',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) =>  Start()),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => LanguageToggle(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: PharmacyTheme.cardColor,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: _filterMedicines,
                  decoration: InputDecoration(
                    hintText: 'Search medicines...',
                    prefixIcon: const Icon(Icons.search, color: PharmacyTheme.primaryColor),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear, color: PharmacyTheme.secondaryTextColor),
                      onPressed: () {
                        _searchController.clear();
                        _filterMedicines('');
                      },
                    )
                        : null,
                    filled: true,
                    fillColor: PharmacyTheme.backgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                ),
                const SizedBox(height: 16),

                // Tab buttons
                Row(
                  children: [
                    _buildTabButton(0, 'All', Icons.category),
                    _buildTabButton(1, 'Low Stock', Icons.warning_amber),
                    _buildTabButton(2, 'Expiring', Icons.watch_later),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(PharmacyTheme.primaryColor),
              ),
            )
                : _filteredMedicines.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.medication_outlined,
                    size: 64,
                    color: PharmacyTheme.secondaryTextColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchController.text.isEmpty
                        ? 'No medicines available'
                        : 'No medicines match your search',
                    style: const TextStyle(
                      color: PharmacyTheme.secondaryTextColor,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showAddMedicineDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Medicine'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PharmacyTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredMedicines.length,
              itemBuilder: (context, index) {
                final medicine = _filteredMedicines[index];
                return _buildMedicineCard(medicine);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _filteredMedicines.isNotEmpty
          ? FloatingActionButton(
        onPressed: _showAddMedicineDialog,
        backgroundColor: PharmacyTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      )
          : null,
    );
  }

  // Tab button for filtering
  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = _currentTabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentTabIndex = index;

            // Filter medicines based on selected tab
            switch (index) {
              case 0: // All
                _filteredMedicines = _pharmacyController.medicines;
                break;
              case 1: // Low Stock
                _filteredMedicines = _pharmacyController.medicines
                    .where((medicine) => medicine.isLowStock)
                    .toList();
                break;
              case 2: // Expiring
                _filteredMedicines = _pharmacyController.medicines
                    .where((medicine) => medicine.isNearExpiry || medicine.isExpired)
                    .toList();
                break;
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? PharmacyTheme.primaryColor : PharmacyTheme.backgroundColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: PharmacyTheme.primaryColor.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : PharmacyTheme.secondaryTextColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : PharmacyTheme.secondaryTextColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Implementation of previously declared dialog methods


  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _genericNameController.dispose();
    _manufacturerController.dispose();
    _mrpRateController.dispose();
    _buyRateController.dispose();
    _sellRateController.dispose();
    _currentStockController.dispose();
    _batchNumberController.dispose();
    _expiryDateController.dispose();
    super.dispose();
  }
}*/
