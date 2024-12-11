import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PhoneInputWidget extends StatefulWidget {
  final Function(bool isValid, String phoneNumber) onPhoneValidated;

  const PhoneInputWidget({
    Key? key,
    required this.onPhoneValidated,
  }) : super(key: key);

  @override
  _PhoneInputWidgetState createState() => _PhoneInputWidgetState();
}

class _PhoneInputWidgetState extends State<PhoneInputWidget> {
  final Map<String, String> countryPrefixes = {
    "India": "+91",
    "USA": "+1 ",
    "UK": "+44 ",
    "Australia": "+61 ",
  };

  String selectedCountry = "India";
  String phoneNumberPrefix = "+91";
  int maxLength = 10;
  late RegExp phoneRegex;
  bool isPhoneValid = true;

  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _updateValidationLogic();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _updateValidationLogic() {
    switch (selectedCountry) {
      case "India":
        maxLength = 10;
        phoneRegex = RegExp(r'[6-9]\d{9}$');
        break;
      case "USA":
        maxLength = 10;
        phoneRegex = RegExp(r'[2-9][0-9]{2}[2-9][0-9]{2}[0-9]{4}$');
        break;
      case "UK":
        maxLength = 11;
        phoneRegex = RegExp(r'^[07]\d{9}$');
        break;
      case "Australia":
        maxLength = 9;
        phoneRegex = RegExp(r'^[4]\d{8}$');
        break;
      default:
        maxLength = 10;
        phoneRegex = RegExp(r'^\+(\d{1,3})[-\s]?(\(?\d{3}\)?[-\s]?\d{3}[-\s]?\d{4})$');
        break;
    }
    phoneNumberPrefix = countryPrefixes[selectedCountry] ?? "+";
  }

  void _validatePhone(String value) {
    final fullPhoneNumber = "$phoneNumberPrefix$value";
    setState(() {
      isPhoneValid = phoneRegex.hasMatch(fullPhoneNumber);
    });
    widget.onPhoneValidated(isPhoneValid, fullPhoneNumber);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Column(
      children: [
        Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonHideUnderline(
                child: DropdownButtonFormField<String>(
                  value: selectedCountry,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.select_country,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  isExpanded: true,
                  onChanged: (String? newCountry) {
                    setState(() {
                      selectedCountry = newCountry!;
                      _updateValidationLogic();
                      _validatePhone(_phoneController.text);
                    });
                  },
                  items: countryPrefixes.keys
                      .map<DropdownMenuItem<String>>((String country) {
                    return DropdownMenuItem<String>(
                      value: country,
                      child: Text(country),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),



        SizedBox(height: 20),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(maxLength),
          ],
          decoration: InputDecoration(
            labelText: localizations.phone_number,
            prefixText: "$phoneNumberPrefix ",
            border: OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: isPhoneValid ? Colors.grey : Colors.red,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: isPhoneValid ? Colors.blue : Colors.red,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red),
            ),
            helperText: isPhoneValid ? null : 'Invalid phone number format',
            helperStyle: TextStyle(color: Colors.red),
          ),
          onChanged: _validatePhone,
        ),
      ],
    );
  }
}