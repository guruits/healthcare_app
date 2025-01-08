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
      isPhoneValid = value.length == maxLength && phoneRegex.hasMatch(value);
    });
    widget.onPhoneValidated(isPhoneValid, fullPhoneNumber);
  }


  Future<void> _selectCountry() async {
    final String? selected = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.select_country),
          content: SingleChildScrollView(
            child: ListBody(
              children: countryPrefixes.keys
                  .map(
                    (country) => ListTile(
                  title: Text(country),
                  onTap: () {
                    Navigator.pop(context, country);
                  },
                ),
              )
                  .toList(),
            ),
          ),
        );
      },
    );

    if (selected != null) {
      setState(() {
        selectedCountry = selected;
        _updateValidationLogic();
        _validatePhone(_phoneController.text);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Column(
      children: [
        SizedBox(height: 20),
        Row(
          children: [
            GestureDetector(
              onTap: _selectCountry,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white, // Background color
                  borderRadius: BorderRadius.circular(30.0), // Rounded corners
                  border: Border.all(
                    color: Colors.black, // Border color
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      selectedCountry, // Display the country code as prefix
                      style: TextStyle(fontSize: 18, color: Colors.black), // Text color
                    ),
                    SizedBox(width: 5),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Colors.black, // Drop-down icon color
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(maxLength),
                ],
                decoration: InputDecoration(
                  labelText: localizations.phone_number,
                  prefixText: "$phoneNumberPrefix ",
                  labelStyle: TextStyle(
                    color: isPhoneValid ? Colors.black : Colors.black,
                  ),
                  hintStyle: TextStyle(
                    color: Colors.grey, // Hint text color
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide(
                      color: isPhoneValid ? Colors.black : Colors.red,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide(
                      color: isPhoneValid ? Colors.black : Colors.red,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide(
                      color: isPhoneValid ? Colors.black : Colors.red,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide(color: Colors.red),
                  ),
                  helperText: isPhoneValid ? null : 'Invalid phone number format',
                  helperStyle: TextStyle(color: Colors.red),
                ),
                onChanged: _validatePhone,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
