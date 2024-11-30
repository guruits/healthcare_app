import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;

class Medicine {
  String id;
  String name;
  String genericName;
  String manufacturer;
  String category;

  // Stock and Pricing Details
  double mrpRate;
  double buyRate;
  double sellRate;
  int currentStock;
  int minStockLevel;
  String batchNumber;
  DateTime expiryDate;

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
    this.minStockLevel = 10,
    required this.batchNumber,
    required this.expiryDate,
  });

  // Check if medicine is low in stock
  bool get isLowStock => currentStock <= minStockLevel;

  // Check if medicine is expired
  bool get isExpired => DateTime.now().isAfter(expiryDate);
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

class PharmacyController {
  // Medicine Inventory
  List<Medicine> medicines = [
    Medicine(
      id: 'MET001',
      name: 'Metformin',
      genericName: 'Metformin Hydrochloride',
      manufacturer: 'Cipla',
      category: 'Diabetes',
      mrpRate: 50.0,
      buyRate: 40.0,
      sellRate: 55.0,
      currentStock: 100,
      minStockLevel: 20,
      batchNumber: 'B2024001',
      expiryDate: DateTime(2025, 12, 31),
    ),
    Medicine(
      id: 'INS001',
      name: 'Insulin Novolog',
      genericName: 'Insulin Aspart',
      manufacturer: 'Novo Nordisk',
      category: 'Diabetes',
      mrpRate: 300.0,
      buyRate: 250.0,
      sellRate: 320.0,
      currentStock: 50,
      minStockLevel: 10,
      batchNumber: 'B2024002',
      expiryDate: DateTime(2025, 6, 30),
    ),
    // Add more medicines as needed
  ];

  // Current Transaction Variables
  Medicine? selectedMedicine;
  int quantity = 1;
  List<BillingItem> billingList = [];
  double cashReceived = 0.0;

  // Method to get available medicines
  List<Medicine> getAvailableMedicines() {
    return medicines.where((med) =>
    med.currentStock > 0 &&
        !med.isExpired
    ).toList();
  }

  // Method to update medicine stock
  void updateMedicineStock(String medicineId, int quantityToReduce) {
    final medicine = medicines.firstWhere((med) => med.id == medicineId);
    medicine.currentStock -= quantityToReduce;
  }

  // Method to calculate total bill amount
  double calculateTotalBillAmount() {
    return billingList.fold(0.0, (total, item) => total + item.totalPrice);
  }

  // Add medicine to billing list
  void addToBillingList() {
    if (selectedMedicine != null && quantity > 0) {
      // Check if enough stock is available
      if (selectedMedicine!.currentStock >= quantity) {
        final totalPrice = selectedMedicine!.sellRate * quantity;

        billingList.add(BillingItem(
          medicine: selectedMedicine!,
          quantity: quantity,
          totalPrice: totalPrice,
        ));

        // Reduce stock
        updateMedicineStock(selectedMedicine!.id, quantity);

        // Reset selection
        selectedMedicine = null;
        quantity = 1;
      } else {
        // Handle insufficient stock scenario
        throw Exception('Insufficient stock for selected medicine');
      }
    }
  }

  // Generate PDF Bill
  Future<void> generatePdf() async {
    final pdf = pw.Document();
    double totalAmount = calculateTotalBillAmount();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Medical Pharmacy Bill',
                  style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold
                  )
              ),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>['Medicine', 'Qty', 'Rate', 'Total'],
                  ...billingList.map((item) => [
                    item.medicine.name,
                    item.quantity.toString(),
                    '₹${item.medicine.sellRate.toStringAsFixed(2)}',
                    '₹${item.totalPrice.toStringAsFixed(2)}'
                  ]),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text('Subtotal: ₹${totalAmount.toStringAsFixed(2)}',
                  style: pw.TextStyle(fontSize: 18)
              ),
              pw.Text('GST (18%): ₹${(totalAmount * 0.18).toStringAsFixed(2)}',
                  style: pw.TextStyle(fontSize: 18)
              ),
              pw.Text('Total Amount: ₹${(totalAmount * 1.18).toStringAsFixed(2)}',
                  style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold
                  )
              ),
              pw.SizedBox(height: 20),
              pw.Text('Cash Received: ₹${cashReceived.toStringAsFixed(2)}',
                  style: pw.TextStyle(fontSize: 18)
              ),
              pw.Text('Change: ₹${(cashReceived - (totalAmount * 1.18)).toStringAsFixed(2)}',
                  style: pw.TextStyle(fontSize: 18)
              ),
            ],
          );
        },
      ),
    );

    // Preview the PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  // Method to add new medicine to inventory
  void addNewMedicine(Medicine medicine) {
    medicines.add(medicine);
  }

  // Method to get low stock medicines
  List<Medicine> getLowStockMedicines() {
    return medicines.where((med) => med.isLowStock).toList();
  }

  // Method to get expired medicines
  List<Medicine> getExpiredMedicines() {
    return medicines.where((med) => med.isExpired).toList();
  }


  // Print bill
  void printBill() {
    generatePdf();
  }
}