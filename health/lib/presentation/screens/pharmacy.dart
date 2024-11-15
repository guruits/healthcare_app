import 'package:flutter/material.dart';
import 'package:health/presentation/controller/language.controller.dart';
import 'package:health/presentation/controller/pharmacy.controller.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../widgets/language.widgets.dart';

class Pharmacy extends StatefulWidget {
  const Pharmacy({super.key});

  @override
  State<Pharmacy> createState() => _PharmacyState();
}

class _PharmacyState extends State<Pharmacy> {
  final PharmacyController _controller = PharmacyController();
  final LanguageController _languageController = LanguageController();
  final ScrollController _horizontalScrollController = ScrollController();

  static  double defaultSpacing = 20.0;
  static  double elementSpacing = 16.0;
  static  double contentPadding = 24.0;

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => Start()));
          },
        ),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            localizations.pharmacy,
            style: TextStyle(fontSize: screenWidth * 0.05),
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: elementSpacing),
            child: LanguageToggle(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(contentPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top section with horizontal scroll
              Container(
                margin: EdgeInsets.only(bottom: defaultSpacing),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  controller: _horizontalScrollController,
                  child: IntrinsicHeight(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: screenWidth * 0.4,
                          child: _buildProductSelection(textScaleFactor),
                        ),
                        SizedBox(width: elementSpacing),
                        SizedBox(
                          width: screenWidth * 0.3,
                          child: _buildQuantityInput(textScaleFactor),
                        ),
                        SizedBox(width: elementSpacing),
                        _buildAddToBillButton(textScaleFactor),
                      ],
                    ),
                  ),
                ),
              ),

              // Billing list section
              Container(
                margin: EdgeInsets.symmetric(vertical: defaultSpacing),
                child: SizedBox(
                  height: screenWidth * 0.5,
                  child: _buildBillingList(textScaleFactor),
                ),
              ),

              // Cash received section
              Container(
                margin: EdgeInsets.symmetric(vertical: defaultSpacing),
                child: _buildCashReceivedInput(textScaleFactor),
              ),

              // Generate bill button
              Container(
                margin: EdgeInsets.only(top: defaultSpacing),
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: elementSpacing,
                      horizontal: elementSpacing,
                    ),
                  ),
                  onPressed: () {
                    _languageController.speakText(localizations.generate_bill);
                    _controller.printBill();
                  },
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      localizations.generate_bill,
                      style: TextStyle(fontSize: screenWidth * 0.04),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


    Widget _buildProductSelection(double textScaleFactor) {
      final localizations = AppLocalizations.of(context)!;
      final screenWidth = MediaQuery.of(context).size.width;

      return Container(
        padding: EdgeInsets.symmetric(vertical: elementSpacing / 2),
        child: DropdownButtonFormField<String>(
          value: _controller.selectedProduct.isEmpty ? null : _controller.selectedProduct,
          hint: Text(
            localizations.select_product,
            style: TextStyle(fontSize: screenWidth * 0.03),
          ),
          onChanged: (String? newValue) {
            setState(() {
              _controller.selectedProduct = newValue ?? '';
              _controller.updateTotalPrice();
            });
          },
          items: _controller.products.map<DropdownMenuItem<String>>((String product) {
            return DropdownMenuItem<String>(
              value: product,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: screenWidth * 0.35),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product,
                      style: TextStyle(fontSize: screenWidth * 0.03),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${localizations.available}: ${_controller.productAvailability[product]}',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: screenWidth * 0.025,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: elementSpacing,
              vertical: elementSpacing / 2,
            ),
          ),
          isExpanded: true, // Add this to prevent overflow
        ),
      );
    }

  Widget _buildQuantityInput(double textScaleFactor) {
    final localizations = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.symmetric(vertical: elementSpacing / 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            localizations.quantity,
            style: TextStyle(fontSize: screenWidth * 0.03),
          ),
          SizedBox(width: elementSpacing),
          Flexible(
            fit: FlexFit.loose,
            child: TextField(
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _controller.quantity = int.tryParse(value) ?? 1;
                  _controller.updateTotalPrice();
                });
              },
              style: TextStyle(fontSize: screenWidth * 0.03),
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: localizations.enter_quantity,
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: elementSpacing,
                  vertical: elementSpacing / 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddToBillButton(double textScaleFactor) {
    final localizations = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.symmetric(vertical: elementSpacing / 2),
      constraints: BoxConstraints(maxWidth: screenWidth * 0.3),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: EdgeInsets.symmetric(
            vertical: elementSpacing,
            horizontal: elementSpacing,
          ),
        ),
        onPressed: () {
          _languageController.speakText(localizations.add_to_bill);
          _controller.addToBillingList();
        },
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '${localizations.add_to_bill}: ₹${_controller.totalPrice.toStringAsFixed(2)}',
            style: TextStyle(fontSize: screenWidth * 0.03),
          ),
        ),
      ),
    );
  }

  Widget _buildBillingList(double textScaleFactor) {
    final screenWidth = MediaQuery.of(context).size.width;

    return ListView.builder(
      itemCount: _controller.billingList.length,
      itemBuilder: (context, index) {
        final item = _controller.billingList[index];
        return Card(
          margin: EdgeInsets.symmetric(vertical: elementSpacing / 2),
          child: Padding(
            padding: EdgeInsets.all(elementSpacing / 2),
            child: ListTile(
              title: Text(
                '${item['quantity']} x ${item['product']}',
                style: TextStyle(fontSize: screenWidth * 0.035),
              ),
              trailing: Text(
                '₹${item['price'].toStringAsFixed(2)}',
                style: TextStyle(fontSize: screenWidth * 0.035),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCashReceivedInput(double textScaleFactor) {
    final localizations = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.symmetric(vertical: elementSpacing / 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            localizations.cash_received,
            style: TextStyle(fontSize: screenWidth * 0.035),
          ),
          SizedBox(width: elementSpacing),
          Flexible(
            fit: FlexFit.loose,
            child: TextField(
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _controller.cashReceived = double.tryParse(value) ?? 0.0;
                });
              },
              style: TextStyle(fontSize: screenWidth * 0.035),
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: localizations.enter_cash_received,
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: elementSpacing,
                  vertical: elementSpacing / 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}