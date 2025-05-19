import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:intl/intl.dart';
import 'package:health/presentation/controller/pharmacy.controller.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../controller/language.controller.dart';
import '../widgets/language.widgets.dart';

// Define a comprehensive color scheme
class PharmacyTheme {
  // Primary colors
  static const Color primaryColor = Colors.deepPurpleAccent; // Professional blue
  static const Color primaryDarkColor = Colors.purple;
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

class Pharmacy extends StatefulWidget {
  const Pharmacy({Key? key}) : super(key: key);

  @override
  _PharmacyManagementPageState createState() => _PharmacyManagementPageState();
}

class _PharmacyManagementPageState extends State<Pharmacy> {
  final PharmacyController _pharmacyController = PharmacyController();
  final TextEditingController _searchController = TextEditingController();
  final LanguageController _languageController = LanguageController();
  bool _isLoading = false;
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

  @override
  @override
  void initState() {
    super.initState();

    _isLoading = true;
    _pharmacyController.fetchAllMedicines().then((_) {
      setState(() {
        _filteredMedicines = _pharmacyController.medicines;
        _isLoading = false;
      });
    });

    // Set system UI overlay style for a more professional look
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: PharmacyTheme.primaryDarkColor,
      statusBarIconBrightness: Brightness.light,
    ));
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
  void _showAddMedicineDialog({Medicine? medicineToEdit}) {
    // Clear controllers or populate with existing data
    _nameController.text = medicineToEdit?.name ?? '';
    _genericNameController.text = medicineToEdit?.genericName ?? '';
    _manufacturerController.text = medicineToEdit?.manufacturer ?? '';
    _mrpRateController.text = medicineToEdit?.mrpRate.toString() ?? '';
    _buyRateController.text = medicineToEdit?.buyRate.toString() ?? '';
    _sellRateController.text = medicineToEdit?.sellRate.toString() ?? '';
    _currentStockController.text = medicineToEdit?.currentStock.toString() ?? '';
    _batchNumberController.text = medicineToEdit?.batchNumber ?? '';
    _expiryDateController.text = medicineToEdit != null
        ? DateFormat('yyyy-MM-dd').format(medicineToEdit.expiryDate)
        : '';

    final isEditing = medicineToEdit != null;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            constraints: BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              color: PharmacyTheme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: PharmacyTheme.primaryColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isEditing ? Icons.edit_note : Icons.add_box_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        SizedBox(width: 12),
                        Text(
                          isEditing ? 'Edit Medicine' : 'Add New Medicine',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Form content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Basic Info Section
                        _buildSectionHeader('Basic Information', Icons.info_outline),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _nameController,
                          labelText: 'Medicine Name *',
                          prefixIcon: Icons.medication_rounded,
                          isRequired: true,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _genericNameController,
                          labelText: 'Generic Name',
                          prefixIcon: Icons.biotech_rounded,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _manufacturerController,
                          labelText: 'Manufacturer',
                          prefixIcon: Icons.factory_rounded,
                        ),

                        const SizedBox(height: 24),
                        // Pricing Section
                        _buildSectionHeader('Pricing Details', Icons.currency_rupee),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _mrpRateController,
                                labelText: 'MRP Rate *',
                                prefixIcon: Icons.currency_rupee,
                                keyboardType: TextInputType.number,
                                isRequired: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                controller: _buyRateController,
                                labelText: 'Buy Rate',
                                prefixIcon: Icons.shopping_basket_outlined,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _sellRateController,
                          labelText: 'Sell Rate *',
                          prefixIcon: Icons.point_of_sale_rounded,
                          keyboardType: TextInputType.number,
                          isRequired: true,
                        ),

                        const SizedBox(height: 24),
                        // Inventory Section
                        _buildSectionHeader('Inventory Details', Icons.inventory_2_rounded),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _currentStockController,
                          labelText: 'Current Stock *',
                          prefixIcon: Icons.inventory_rounded,
                          keyboardType: TextInputType.number,
                          isRequired: true,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _batchNumberController,
                          labelText: 'Batch Number',
                          prefixIcon: Icons.qr_code_rounded,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _expiryDateController,
                          labelText: 'Expiry Date *',
                          prefixIcon: Icons.event_rounded,
                          readOnly: true,
                          isRequired: true,
                          onTap: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: medicineToEdit?.expiryDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2030),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: PharmacyTheme.primaryColor,
                                      onPrimary: Colors.white,
                                      surface: PharmacyTheme.cardColor,
                                      onSurface: PharmacyTheme.primaryTextColor,
                                    ),
                                    dialogBackgroundColor: PharmacyTheme.cardColor,
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
                        const SizedBox(height: 8),
                        Text(
                          '* Required fields',
                          style: TextStyle(
                            fontSize: 12,
                            color: PharmacyTheme.secondaryTextColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Actions footer
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  decoration: BoxDecoration(
                    color: PharmacyTheme.backgroundColor,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        icon: Icon(Icons.cancel_outlined, size: 20),
                        label: Text('Cancel'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: PharmacyTheme.secondaryTextColor,
                          side: BorderSide(color: PharmacyTheme.secondaryTextColor),
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      ElevatedButton.icon(
                        icon: Icon(
                          isEditing ? Icons.save_rounded : Icons.add_circle_outline_rounded,
                          size: 20,
                        ),
                        label: Text(isEditing ? 'Update' : 'Add'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isEditing
                              ? PharmacyTheme.accentColor
                              : PharmacyTheme.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () async {
                          // Validate form
                          if (_nameController.text.isEmpty ||
                              _mrpRateController.text.isEmpty ||
                              _sellRateController.text.isEmpty ||
                              _currentStockController.text.isEmpty ||
                              _expiryDateController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.error_outline, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text('Please fill all required fields'),
                                  ],
                                ),
                                backgroundColor: PharmacyTheme.errorColor,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                            return;
                          }

                          // Calculate profit margin
                          double buyRate = double.tryParse(_buyRateController.text) ?? 0;
                          double sellRate = double.tryParse(_sellRateController.text) ?? 0;
                          double profitMargin = buyRate > 0
                              ? ((sellRate - buyRate) / buyRate) * 100
                              : 0;

                          setState(() {
                            _isLoading = true;
                          });

                          try {
                            if (isEditing) {
                              // Update existing medicine
                              final updatedMedicine = Medicine(
                                id: medicineToEdit!.id,
                                name: _nameController.text,
                                genericName: _genericNameController.text,
                                manufacturer: _manufacturerController.text,
                                category: medicineToEdit.category,
                                profitMargin: profitMargin,
                                mrpRate: double.parse(_mrpRateController.text),
                                buyRate: buyRate,
                                sellRate: sellRate,
                                currentStock: int.parse(_currentStockController.text),
                                batchNumber: _batchNumberController.text,
                                expiryDate: DateFormat('yyyy-MM-dd').parse(
                                    _expiryDateController.text),
                              );

                              await _pharmacyController.updateMedicine(updatedMedicine);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text('Medicine Updated: ${updatedMedicine.name}'),
                                    ],
                                  ),
                                  backgroundColor: PharmacyTheme.successColor,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              );
                            } else {
                              // Create new medicine
                              final newMedicine = Medicine(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                name: _nameController.text,
                                genericName: _genericNameController.text,
                                manufacturer: _manufacturerController.text,
                                category: 'General',
                                profitMargin: profitMargin,
                                mrpRate: double.parse(_mrpRateController.text),
                                buyRate: buyRate,
                                sellRate: sellRate,
                                currentStock: int.parse(_currentStockController.text),
                                batchNumber: _batchNumberController.text,
                                expiryDate: DateFormat('yyyy-MM-dd').parse(
                                    _expiryDateController.text),
                              );

                              await _pharmacyController.addNewMedicine(newMedicine);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text('Medicine Added: ${newMedicine.name}'),
                                    ],
                                  ),
                                  backgroundColor: PharmacyTheme.successColor,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              );
                            }

                            // Refresh the medicine list
                            await _pharmacyController.fetchAllMedicines();
                            setState(() {
                              _filteredMedicines = _pharmacyController.medicines;
                              _isLoading = false;
                            });

                            Navigator.of(context).pop();
                          } catch (e) {
                            setState(() {
                              _isLoading = false;
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.error_outline, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text('Error: ${e.toString()}'),
                                  ],
                                ),
                                backgroundColor: PharmacyTheme.errorColor,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

// Helper method to build section headers
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: PharmacyTheme.primaryColor,
          size: 20,
        ),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: PharmacyTheme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Divider(
            color: PharmacyTheme.primaryLightColor.withOpacity(0.5),
            thickness: 1,
          ),
        ),
      ],
    );
  }

// Enhance the text field builder with required field indicator
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    IconData? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    bool isRequired = false,
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
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: isRequired
            ? Icon(Icons.star, size: 10, color: PharmacyTheme.warningColor)
            : null,
      ),
      style: const TextStyle(color: PharmacyTheme.primaryTextColor),
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
    );
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
                        onPressed: () => _showAddMedicineDialog(medicineToEdit: medicine),
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
                        onPressed: () {
                          // Show confirmation dialog before deleting
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Delete ${medicine.name}?'),
                              content: Text('This action cannot be undone.'),
                              actions: [
                                TextButton(
                                  child: Text('Cancel'),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: PharmacyTheme.errorColor,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text('Delete'),
                                  onPressed: () async {
                                    setState(() {
                                      _isLoading = true;
                                    });

                                    Navigator.of(context).pop(); // Close dialog

                                    await _pharmacyController.deleteMedicine(medicine.id);

                                    setState(() {
                                      _filteredMedicines = _pharmacyController.medicines;
                                      _isLoading = false;
                                    });

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Medicine deleted: ${medicine.name}'),
                                        backgroundColor: PharmacyTheme.successColor,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
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

  // Build Tab Button
  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = _currentTabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () async {
          setState(() {
            _currentTabIndex = index;
            _isLoading = true; // Show loading state
          });

          // Filter medicines based on selected tab
          switch (index) {
            case 0: // All
            // Fetch all medicines from API
              await _pharmacyController.fetchAllMedicines();
              setState(() {
                _filteredMedicines = _pharmacyController.medicines;
              });
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

          setState(() {
            _isLoading = false; // Hide loading after filtering
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
// Update Stock Dialog
  void _showUpdateStockDialog(Medicine medicine) {
    final localizations = AppLocalizations.of(context)!;
    final TextEditingController stockController = TextEditingController();
    bool isAddingStock = true; // Default to adding stock
    int currentStockValue = medicine.currentStock;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder( // Using StatefulBuilder to update dialog state
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text('Manage Stock: ${medicine.name}'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Current stock display
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: PharmacyTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Current Stock:',
                            style: TextStyle(
                              color: PharmacyTheme.secondaryTextColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            medicine.currentStock.toString(),
                            style: TextStyle(
                              color: medicine.isLowStock
                                  ? PharmacyTheme.lowStockColor
                                  : PharmacyTheme.goodStockColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Add or Remove toggle
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                isAddingStock = true;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isAddingStock
                                    ? PharmacyTheme.primaryColor
                                    : PharmacyTheme.backgroundColor,
                                borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(8),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Add Stock',
                                style: TextStyle(
                                  color: isAddingStock
                                      ? Colors.white
                                      : PharmacyTheme.secondaryTextColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                isAddingStock = false;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: !isAddingStock
                                    ? PharmacyTheme.errorColor
                                    : PharmacyTheme.backgroundColor,
                                borderRadius: const BorderRadius.horizontal(
                                  right: Radius.circular(8),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Remove Stock',
                                style: TextStyle(
                                  color: !isAddingStock
                                      ? Colors.white
                                      : PharmacyTheme.secondaryTextColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Stock quantity input
                    TextField(
                      controller: stockController,
                      decoration: InputDecoration(
                        labelText: isAddingStock ? 'Quantity to Add' : 'Quantity to Remove',
                        prefixIcon: Icon(
                          isAddingStock ? Icons.add : Icons.remove,
                          color: isAddingStock
                              ? PharmacyTheme.primaryColor
                              : PharmacyTheme.errorColor,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        int changeValue = int.tryParse(value) ?? 0;
                        setDialogState(() {
                          if (isAddingStock) {
                            currentStockValue = medicine.currentStock + changeValue;
                          } else {
                            currentStockValue = medicine.currentStock - changeValue;
                            if (currentStockValue < 0) currentStockValue = 0;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Preview new stock value
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: PharmacyTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: currentStockValue <= medicine.minStockLevel
                              ? PharmacyTheme.lowStockColor
                              : PharmacyTheme.goodStockColor,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'New Stock Value:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            currentStockValue.toString(),
                            style: TextStyle(
                              color: currentStockValue <= medicine.minStockLevel
                                  ? PharmacyTheme.lowStockColor
                                  : PharmacyTheme.goodStockColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    child: Text('Cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAddingStock
                          ? PharmacyTheme.primaryColor
                          : PharmacyTheme.errorColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(isAddingStock ? 'Add Stock' : 'Remove Stock'),
                    onPressed: () async {
                      int stockChange = int.tryParse(stockController.text) ?? 0;
                      if (stockChange <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid quantity'),
                            backgroundColor: PharmacyTheme.errorColor,
                          ),
                        );
                        return;
                      }

                      setState(() {
                        _isLoading = true;
                      });

                      try {
                        if (isAddingStock) {
                          await _pharmacyController.updateMedicineStock(
                              medicine.id, stockChange);
                        } else {
                          // Ensure we don't go below zero
                          int finalStock = medicine.currentStock - stockChange;
                          if (finalStock < 0) finalStock = 0;
                          int actualChange = medicine.currentStock - finalStock;

                          await _pharmacyController.updateMedicineStock(
                              medicine.id, -actualChange);
                        }

                        // Refresh the list
                        await _pharmacyController.fetchAllMedicines();
                        setState(() {
                          _filteredMedicines = _pharmacyController.medicines;
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                isAddingStock
                                    ? 'Added $stockChange items to stock'
                                    : 'Removed $stockChange items from stock'
                            ),
                            backgroundColor: PharmacyTheme.successColor,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error updating stock: $e'),
                            backgroundColor: PharmacyTheme.errorColor,
                          ),
                        );
                      } finally {
                        setState(() {
                          _isLoading = false;
                        });
                      }

                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            }
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, [Color? valueColor]) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: PharmacyTheme.primaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
