import 'package:flutter/material.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class Pharmacy extends StatefulWidget {
  const Pharmacy({super.key});

  @override
  State<Pharmacy> createState() => _PharmacyState();
}

class _PharmacyState extends State<Pharmacy> {
  // List of products suitable for diabetic patients
  final List<String> _products = [
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
  final Map<String, double> _productPrices = {
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
  final Map<String, int> _productAvailability = {
    'Metformin': 100,
    'Insulin (Novolog)': 50,
    'Insulin (Lantus)': 30,
    'Glucometer': 20,
    'Test Strips': 200,
    'Syringes': 150,
    'Glucose Tablets': 100,
    'Aspirin': 50, // Optional: include general medications
  };

  String _selectedProduct = '';
  int _quantity = 1;
  double _totalPrice = 0.0;
  double _gstRate = 0.18; // 18% GST rate
  List<Map<String, dynamic>> _billingList = [];
  double _cashReceived = 0.0; // Cash received

  void _updateTotalPrice() {
    setState(() {
      _totalPrice = (_productPrices[_selectedProduct] ?? 0.0) * _quantity;
    });
  }

  void _addToBillingList() {
    if (_selectedProduct.isNotEmpty) {
      setState(() {
        _billingList.add({
          'product': _selectedProduct,
          'quantity': _quantity,
          'price': _totalPrice,
        });
        _selectedProduct = '';
        _quantity = 1;
        _totalPrice = 0.0;
      });
    }
  }

  // PDF generation function
  Future<void> _generatePdf() async {
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
                  ..._billingList.map((item) {
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
              pw.Text('Cash Received: ₹${_cashReceived.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 18)),
              pw.Text('Change: ₹${(_cashReceived - (totalAmount + (totalAmount * 0.18))).toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 18)),
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

  void _printBill() {
    _generatePdf();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => Start()));
          },
        ),
        title: Text('Pharmacy'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: _buildProductSelection()),
                SizedBox(width: 10), // Space between widgets
                Expanded(child: _buildQuantityInput()),
                SizedBox(width: 10), // Space between widgets
                _buildAddToBillButton(),
              ],
            ),
            SizedBox(height: 20),
            _buildBillingList(),
            SizedBox(height: 20),
            _buildCashReceivedInput(),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _printBill,
              child: Text('Generate Bill'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSelection() {
    return DropdownButtonFormField<String>(
      value: _selectedProduct.isEmpty ? null : _selectedProduct,
      hint: Text('Select Product'),
      onChanged: (String? newValue) {
        setState(() {
          _selectedProduct = newValue ?? '';
          _updateTotalPrice(); // Update total price whenever product changes
        });
      },
      items: _products.map<DropdownMenuItem<String>>((String product) {
        return DropdownMenuItem<String>(
          value: product,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(product),
              Text(
                'Available: ${_productAvailability[product]}',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      }).toList(),
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildQuantityInput() {
    return Row(
      children: [
        Text('Quantity:', style: TextStyle(fontSize: 16)),
        SizedBox(width: 10),
        Expanded(
          child: TextField(
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                _quantity = int.tryParse(value) ?? 1; // Default to 1 if parsing fails
                _updateTotalPrice(); // Update total price whenever quantity changes
              });
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter Quantity',
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddToBillButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        padding: EdgeInsets.symmetric(vertical: 15),
        textStyle: TextStyle(fontSize: 18),
      ),
      onPressed: _addToBillingList,
      child: Text('Add - Total: ₹${_totalPrice.toStringAsFixed(2)}'),
    );
  }

  Widget _buildBillingList() {
    return Expanded(
      child: ListView.builder(
        itemCount: _billingList.length,
        itemBuilder: (context, index) {
          final item = _billingList[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 5),
            child: ListTile(
              title: Text('${item['quantity']} x ${item['product']}'),
              trailing: Text('₹${item['price'].toStringAsFixed(2)}'),
            ),
          );
        },
      ),
    );
  }

  // Cash received input method
  Widget _buildCashReceivedInput() {
    return Row(
      children: [
        Text('Cash Received:', style: TextStyle(fontSize: 16)),
        SizedBox(width: 10),
        Expanded(
          child: TextField(
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                _cashReceived = double.tryParse(value) ?? 0.0; // Default to 0 if parsing fails
              });
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter Cash Received',
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
