import 'package:flutter/material.dart';
import 'package:health/presentation/controller/pharmacy.controller.dart';
import 'package:health/presentation/screens/start.dart';

import '../widgets/language.widgets.dart';

class Pharmacy extends StatefulWidget {
  const Pharmacy({super.key});

  @override
  State<Pharmacy> createState() => _PharmacyState();
}

class _PharmacyState extends State<Pharmacy> {
  final PharmacyController _controller = PharmacyController();


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
        actions: [
          LanguageToggle(),
        ],
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
              onPressed: _controller.printBill,
              child: Text('Generate Bill'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSelection() {
    return DropdownButtonFormField<String>(
      value: _controller.selectedProduct.isEmpty ? null : _controller.selectedProduct,
      hint: Text('Select Product'),
      onChanged: (String? newValue) {
        setState(() {
          _controller.selectedProduct = newValue ?? '';
          _controller.updateTotalPrice(); // Update total price whenever product changes
        });
      },
      items: _controller.products.map<DropdownMenuItem<String>>((String product) {
        return DropdownMenuItem<String>(
          value: product,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(product),
              Text(
                'Available: ${_controller.productAvailability[product]}',
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
                _controller.quantity = int.tryParse(value) ?? 1; // Default to 1 if parsing fails
                _controller.updateTotalPrice(); // Update total price whenever quantity changes
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
      onPressed: _controller.addToBillingList,
      child: Text('Add - Total: ₹${_controller.totalPrice.toStringAsFixed(2)}'),
    );
  }

  Widget _buildBillingList() {
    return Expanded(
      child: ListView.builder(
        itemCount: _controller.billingList.length,
        itemBuilder: (context, index) {
          final item = _controller.billingList[index];
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
                _controller.cashReceived = double.tryParse(value) ?? 0.0; // Default to 0 if parsing fails
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
