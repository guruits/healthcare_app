import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:intl/intl.dart';
import 'package:health/presentation/controller/pharmacy.controller.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../controller/language.controller.dart';
import '../widgets/language.widgets.dart';

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

  @override
  void initState() {
    super.initState();
    _filteredMedicines = _pharmacyController.medicines;
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final localizations = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(localizations.addMedicine),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                      labelText: localizations.medicineName),
                ),
                TextField(
                  controller: _genericNameController,
                  decoration: InputDecoration(
                      labelText: localizations.genericName),
                ),
                TextField(
                  controller: _manufacturerController,
                  decoration: InputDecoration(
                      labelText: localizations.manufacturer),
                ),
                TextField(
                  controller: _mrpRateController,
                  decoration: InputDecoration(labelText: localizations.mrpRate),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _buyRateController,
                  decoration: InputDecoration(labelText: localizations.buyRate),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _sellRateController,
                  decoration: InputDecoration(
                      labelText: localizations.sellRate),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _currentStockController,
                  decoration: InputDecoration(
                      labelText: localizations.currentStock),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _batchNumberController,
                  decoration: InputDecoration(
                      labelText: localizations.batchNumber),
                ),
                TextField(
                  controller: _expiryDateController,
                  decoration: InputDecoration(
                    labelText: localizations.expiryDate,
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
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
              child: Text(localizations.cancel),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text(localizations.add),
              onPressed: () {
                // Validate and add medicine
                final newMedicine = Medicine(
                  id: DateTime
                      .now()
                      .millisecondsSinceEpoch
                      .toString(),
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

                _pharmacyController.addNewMedicine(newMedicine);

                // Clear controllers
                _nameController.clear();
                _genericNameController.clear();
                _manufacturerController.clear();
                _mrpRateController.clear();
                _buyRateController.clear();
                _sellRateController.clear();
                _currentStockController.clear();
                _batchNumberController.clear();
                _expiryDateController.clear();

                // Refresh list
                setState(() {
                  _filteredMedicines = _pharmacyController.medicines;
                });

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Billing Section
  void _showBillingDialog() {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(localizations.billing),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Medicine Selection Dropdown
                    DropdownButtonFormField<Medicine>(
                      value: _pharmacyController.selectedMedicine,
                      hint: Text(localizations.selectMedicine),
                      items: _pharmacyController.getAvailableMedicines()
                          .map((medicine) =>
                          DropdownMenuItem(
                            value: medicine,
                            child: Text('${medicine.name} (Stock: ${medicine
                                .currentStock})'),
                          ))
                          .toList(),
                      onChanged: (Medicine? selectedMedicine) {
                        setState(() {
                          _pharmacyController.selectedMedicine =
                              selectedMedicine;
                        });
                      },
                    ),
                    // Quantity Input
                    TextField(
                      decoration: InputDecoration(
                          labelText: localizations.quantity),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _pharmacyController.quantity = int.tryParse(value) ?? 1;
                      },
                    ),
                    // Billing List
                    if (_pharmacyController.billingList.isNotEmpty)
                      Column(
                        children: _pharmacyController.billingList.map((item) =>
                            ListTile(
                              title: Text(
                                  '${item.medicine.name} x ${item.quantity}'),
                              trailing: Text(
                                  '₹${item.totalPrice.toStringAsFixed(2)}'),
                            )
                        ).toList(),
                      ),
                    // Total Amount
                    Text(
                      '${localizations.total}: ₹${_pharmacyController
                          .calculateTotalBillAmount().toStringAsFixed(2)}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text(localizations.addToBill),
                  onPressed: () {
                    setState(() {
                      _pharmacyController.addToBillingList();
                    });
                  },
                ),
                ElevatedButton(
                  child: Text(localizations.generateBill),
                  onPressed: () {
                    _pharmacyController.printBill();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.pharmacy),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => Start()),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.point_of_sale),
            onPressed: _showBillingDialog,
          ),
          const LanguageToggle(),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: localizations.searchMedicines,
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: _filterMedicines,
            ),
          ),

          // Tabs for different views
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTabButton(localizations.allMedicines, 0),
                _buildTabButton(localizations.lowStock, 1),
                _buildTabButton(localizations.expired, 2),
              ],
            ),
          ),

          // Medicine List
          Expanded(
            child: ListView.builder(
              itemCount: _getCurrentTabMedicines().length,
              itemBuilder: (context, index) {
                final medicine = _getCurrentTabMedicines()[index];
                return ListTile(
                  title: Text(medicine.name),
                  subtitle: Text(
                      '${medicine.genericName} - ${medicine.manufacturer}'),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Stock: ${medicine.currentStock}',
                        style: TextStyle(
                          color: medicine.isLowStock ? Colors.red : Colors
                              .green,
                        ),
                      ),
                      Text('₹${medicine.sellRate.toStringAsFixed(2)}'),
                    ],
                  ),
                  onTap: () => _showMedicineDetailsDialog(medicine),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: _showAddMedicineDialog,
      ),
    );
  }

  // Build Tab Button
  Widget _buildTabButton(String title, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _currentTabIndex == index
              ? Colors.blue
              : Colors.grey[300],
          foregroundColor: _currentTabIndex == index
              ? Colors.white
              : Colors.black,
        ),
        onPressed: () {
          setState(() {
            _currentTabIndex = index;
          });
        },
        child: Text(title),
      ),
    );
  }

  // Get Medicines based on current tab
  List<Medicine> _getCurrentTabMedicines() {
    switch (_currentTabIndex) {
      case 1:
        return _pharmacyController.getLowStockMedicines();
      case 2:
        return _pharmacyController.getExpiredMedicines();
      default:
        return _filteredMedicines;
    }
  }

  // Show Medicine Details Dialog
  // Show Medicine Details Dialog
  void _showMedicineDetailsDialog(Medicine medicine) {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(medicine.name),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${localizations.genericName}: ${medicine.genericName}'),
              Text('${localizations.manufacturer}: ${medicine.manufacturer}'),
              Text('MRP: ₹${medicine.mrpRate.toStringAsFixed(2)}'),
              Text('${localizations.sellRate}: ₹${medicine.sellRate
                  .toStringAsFixed(2)}'),
              Text('${localizations.currentStock}: ${medicine.currentStock}'),
              Text('${localizations.batchNumber}: ${medicine.batchNumber}'),
              Text('${localizations.expiryDate}: ${DateFormat('yyyy-MM-dd')
                  .format(medicine.expiryDate)}'),
              if (medicine.isLowStock)
                Text(
                  localizations.lowStockAlert,
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold),
                ),
              if (medicine.isExpired)
                Text(
                  localizations.expiredAlert,
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          actions: [
            TextButton(
              child: Text(localizations.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text(localizations.updateStock),
              onPressed: () {
                _showUpdateStockDialog(medicine);
              },
            ),
          ],
        );
      },
    );
  }

// Update Stock Dialog
  void _showUpdateStockDialog(Medicine medicine) {
    final localizations = AppLocalizations.of(context)!;
    final TextEditingController stockController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${localizations.updateStock} ${medicine.name}'),
          content: TextField(
            controller: stockController,
            decoration: InputDecoration(
              labelText: localizations.currentStock,
              hintText: '${localizations.currentStock}: ${medicine
                  .currentStock}',
            ),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              child: Text(localizations.cancel),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text(localizations.updateStock),
              onPressed: () {
                int addedStock = int.tryParse(stockController.text) ?? 0;
                setState(() {
                  medicine.currentStock += addedStock;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}