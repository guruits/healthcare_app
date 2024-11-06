import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;

class PharmacyController{
  // List of products suitable for diabetic patients
  final List<String> products = [
    'Metformin',
    'Insulin (Novolog)',
    'Insulin (Lantus)',
    'Glucometer',
    'Test Strips',
    'Syringes',
    'Glucose Tablets',
    'Aspirin' // Optional: include general medications
  ];

  // Prices for diabetic-related products
  final Map<String, double> productPrices = {
    'Metformin': 50.0,
    'Insulin (Novolog)': 300.0,
    'Insulin (Lantus)': 500.0,
    'Glucometer': 1500.0,
    'Test Strips': 25.0,
    'Syringes': 5.0,
    'Glucose Tablets': 10.0,
    'Aspirin': 10.0, // Optional: include general medications
  };

  // Availability of diabetic-related products
  final Map<String, int> productAvailability = {
    'Metformin': 100,
    'Insulin (Novolog)': 50,
    'Insulin (Lantus)': 30,
    'Glucometer': 20,
    'Test Strips': 200,
    'Syringes': 150,
    'Glucose Tablets': 100,
    'Aspirin': 50, // Optional: include general medications
  };

  String selectedProduct = '';
  int quantity = 1;
  double totalPrice = 0.0;
  double _gstRate = 0.18; // 18% GST rate
  List<Map<String, dynamic>> billingList = [];
  double cashReceived = 0.0; // Cash received

  void updateTotalPrice() {
    {
      totalPrice = (productPrices[selectedProduct] ?? 0.0) * quantity;
    };
  }

  void addToBillingList() {
    if (selectedProduct.isNotEmpty) {
      {
        billingList.add({
          'product': selectedProduct,
          'quantity': quantity,
          'price': totalPrice,
        });
        selectedProduct = '';
        quantity = 1;
        totalPrice = 0.0;
      };
    }
  }

  // PDF generation function
  Future<void> generatePdf() async {
    final pdf = pw.Document();
    double totalAmount = 0.0;

    // Add bill details
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Pharmacy Bill', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>['Product', 'Quantity', 'Price (₹)'],
                  ...billingList.map((item) {
                    totalAmount += item['price'];
                    return [item['product'], item['quantity'].toString(), '₹${item['price'].toStringAsFixed(2)}'];
                  }),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text('Subtotal: ₹${totalAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 18)),
              pw.Text('CGST (9%): ₹${(totalAmount * 0.09).toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 18)),
              pw.Text('SGST (9%): ₹${(totalAmount * 0.09).toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 18)),
              pw.Text('Total Amount: ₹${(totalAmount + (totalAmount * 0.18)).toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text('Cash Received: ₹${cashReceived.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 18)),
              pw.Text('Change: ₹${(cashReceived - (totalAmount + (totalAmount * 0.18))).toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 18)),
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

  void printBill() {
    generatePdf();
  }
}