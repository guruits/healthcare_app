import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../data/datasources/Userdetailsservice.dart';
import '../widgets/reusable_button.widget.dart';

class ProfileUserDetailsScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> basicUserData;

  const ProfileUserDetailsScreen({
    Key? key,
    required this.userId,
    required this.basicUserData,
  }) : super(key: key);

  @override
  State<ProfileUserDetailsScreen> createState() => _ProfileUserDetailsScreenState();
}

class _ProfileUserDetailsScreenState extends State<ProfileUserDetailsScreen> {
  final UserDetailsService _userDetailsService = UserDetailsService();
  bool _isLoading = true;
  Map<String, dynamic> _userData = {};
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchUserMedicalData();
  }

  Future<void> _fetchUserMedicalData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _userDetailsService.getMedicalData(widget.userId);

      if (response['status'] == 'success' && response['data'] != null) {
        // Combine the medical data with the basic user data
        final medicalData = response['data'];

        // Create a combined user data map
        Map<String, dynamic> combinedData = {
          'name': widget.basicUserData['name'] ?? medicalData['patientId']['name'] ?? 'Not available',
          'phone': widget.basicUserData['phoneNumber'] ?? medicalData['patientId']['phone_number'] ?? 'Not available',
          'aadharnumber': widget.basicUserData['aadhaarNumber'] ?? medicalData['patientId']['aadhaarNumber'] ?? 'Not available',
          'address': widget.basicUserData['address'] ?? 'Not available',
          'dateofbirth': widget.basicUserData['dob'] != null
              ? DateFormat('dd MMM yyyy').format(widget.basicUserData['dob'])
              : 'Not available',
          // Add all medical data fields
          'hasDiabetes': medicalData['hasDiabetes'] ?? false,
          'diabetesType': medicalData['diabetesType'] ?? 'Not specified',
          'diagnosisDate': medicalData['diagnosisDate'] ?? 'Not specified',
          'takingMedication': medicalData['takingMedication'] ?? false,
          'medications': medicalData['medications'] ?? 'None',
          'healthConditions': medicalData['healthConditions'] ?? [],
          'familyHistory': medicalData['familyHistory'] ?? false,
          'familyRelation': medicalData['familyRelation'] ?? 'None',
          'symptoms': medicalData['symptoms'] ?? [],
          'activityLevel': medicalData['activityLevel'] ?? 'Not specified',
          'dietType': medicalData['dietType'] ?? 'Not specified',
          'isSmoker': medicalData['isSmoker'] ?? false,
          'consumesAlcohol': medicalData['consumesAlcohol'] ?? false,
          'sleepHours': medicalData['sleepHours'] ?? 'Not specified',
          'checksBloodSugar': medicalData['checksBloodSugar'] ?? false,
          'monitoringFrequency': medicalData['monitoringFrequency'] ?? 'Not specified',
          'ownsGlucometer': medicalData['ownsGlucometer'] ?? false,
          'fastingBloodSugar': medicalData['fastingBloodSugar'] ?? 'Not specified',
          'postMealBloodSugar': medicalData['postMealBloodSugar'] ?? 'Not specified',
          'emergencyContactName': medicalData['emergencyContactName'] ?? '',
          'emergencyContactRelation': medicalData['emergencyContactRelation'] ?? '',
          'emergencyContactPhone': medicalData['emergencyContactPhone'] ?? '',
          // Calculate age if DOB is available
          'age': _calculateAge(widget.basicUserData['dob']),
          'gender': 'Not specified', // Add default or fetch from somewhere else if available
        };

        setState(() {
          _userData = combinedData;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to fetch user data';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error in _fetchUserMedicalData: $e');
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  String _calculateAge(DateTime? dob) {
    if (dob == null) return 'Not available';

    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age.toString();
  }

  void _navigateToEditProfile() {
    // Navigate to edit profile screen with the user data
    Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen(userData: _userData, userId: widget.userId)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'User Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? Center(
        child: LoadingAnimationWidget.discreteCircle(
          color: Colors.pink,
          secondRingColor: Colors.teal,
          thirdRingColor: Colors.orange,
          size: 60,
        ),
      )
          : _errorMessage.isNotEmpty
          ? _buildErrorView()
          : _buildUserDetailsView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchUserMedicalData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserDetailsView() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildUserDetailsWidget(),
            const SizedBox(height: 20),
            ReusableButton(
              label: "Edit Details",
              icon: Icons.edit,
              onPressed: _navigateToEditProfile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserDetailsWidget() {
    return UserDetailsWidget(
      userData: _userData,
      onEdit: _navigateToEditProfile,
      primaryColor: Theme.of(context).primaryColor,
    );
  }
}

class UserDetailsWidget extends StatelessWidget {
  final Map<String, dynamic> userData;
  final Function() onEdit;
  final bool showEditButton;
  final Color primaryColor;
  final Color secondaryColor;
  final Color textColor;

  const UserDetailsWidget({
    Key? key,
    required this.userData,
    required this.onEdit,
    this.showEditButton = false,
    this.primaryColor = const Color(0xFF6A5ACD), // Slate blue
    this.secondaryColor = const Color(0xFF9370DB), // Medium purple
    this.textColor = const Color(0xFF333366), // Dark blue
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 20),
          _buildPersonalDetails(),
          const SizedBox(height: 24),
          _buildMedicalHistory(),
          const SizedBox(height: 24),
          _buildLifestyleInformation(),
          const SizedBox(height: 24),
          _buildEmergencyContact(),
          if (showEditButton) ...[
            const SizedBox(height: 20),
            _buildEditButton(),
          ],
        ],
      ),
    );
  }

  bool _hasEmergencyContact() {
    return userData['emergencyContactName'] != null &&
        userData['emergencyContactName'].toString().isNotEmpty;
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name and basic info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userData['name'] ?? 'Name not available',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              SizedBox(height: 4),
              _buildInfoChip(
                icon: Icons.phone,
                text: userData['phone'] ?? 'Phone not available',
              ),
              SizedBox(height: 4),
              _buildInfoChip(
                icon: Icons.cake,
                text: '${userData['age'] ?? 'Age not available'} years (${userData['dateofbirth'] ?? 'DOB not available'})',
              ),
              SizedBox(height: 4),
              _buildInfoChip(
                icon: Icons.people,
                text: userData['gender'] ?? 'Gender not specified',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: primaryColor),
        SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.8)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Personal Details', Icons.person_outline),
        SizedBox(height: 12),
        _buildDetailItem('Aadhaar Number', userData['aadharnumber'] ?? 'Not provided', Icons.credit_card),
        _buildDetailItem('Address', userData['address'] ?? 'Not provided', Icons.home),
      ],
    );
  }

  Widget _buildMedicalHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Medical History', Icons.medical_services),
        SizedBox(height: 12),
        _buildDetailItem(
          'Diabetes Status',
          userData['hasDiabetes'] == true ? 'Has Diabetes' : 'No Diabetes',
          Icons.monitor_heart,
        ),
        if (userData['hasDiabetes'] == true) ...[
          _buildDetailItem('Diabetes Type', userData['diabetesType'] ?? 'Not specified', Icons.category),
          _buildDetailItem('Diagnosis Date', userData['diagnosisDate'] ?? 'Not specified', Icons.calendar_today),
        ],
        _buildDetailItem(
          'Medications',
          userData['takingMedication'] == true
              ? userData['medications'] ?? 'Not specified'
              : 'Not taking medications',
          Icons.medication,
        ),
        _buildDetailItem(
          'Other Health Conditions',
          _formatListItems(userData['healthConditions']),
          Icons.health_and_safety,
        ),
        _buildDetailItem(
          'Family History of Diabetes',
          userData['familyHistory'] == true
              ? 'Yes (${userData['familyRelation'] ?? 'Not specified'})'
              : 'No family history',
          Icons.family_restroom,
        ),
        _buildDetailItem(
          'Symptoms',
          _formatListItems(userData['symptoms']),
          Icons.warning_amber,
        ),
      ],
    );
  }

  Widget _buildLifestyleInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Lifestyle Information', Icons.self_improvement),
        SizedBox(height: 12),
        _buildDetailItem('Activity Level', userData['activityLevel'] ?? 'Not specified', Icons.directions_run),
        _buildDetailItem('Diet Type', userData['dietType'] ?? 'Not specified', Icons.restaurant_menu),
        _buildDetailItem(
          'Smoking Status',
          userData['isSmoker'] == true ? 'Smoker' : 'Non-smoker',
          Icons.smoking_rooms,
        ),
        _buildDetailItem(
          'Alcohol Consumption',
          userData['consumesAlcohol'] == true ? 'Yes' : 'No',
          Icons.local_bar,
        ),
        _buildDetailItem('Sleep Hours', '${userData['sleepHours'] ?? 'Not specified'} hours', Icons.nights_stay),
        _buildDetailItem(
          'Blood Sugar Monitoring',
          userData['checksBloodSugar'] == true
              ? 'Yes (${userData['monitoringFrequency'] ?? 'Frequency not specified'})'
              : 'No regular monitoring',
          Icons.monitor_heart,
        ),
        _buildDetailItem(
          'Has Glucometer',
          userData['ownsGlucometer'] == true ? 'Yes' : 'No',
          Icons.devices,
        ),
        _buildDetailItem(
          'Recent Blood Sugar Readings',
          'Fasting: ${userData['fastingBloodSugar'] ?? 'N/A'} mg/dL, Post-meal: ${userData['postMealBloodSugar'] ?? 'N/A'} mg/dL',
          Icons.bloodtype,
        ),
      ],
    );
  }

  Widget _buildEmergencyContact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Emergency Contact', Icons.emergency),
        SizedBox(height: 12),
        _buildDetailItem('Name', userData['emergencyContactName'] ?? 'Not provided', Icons.person),
        _buildDetailItem('Relationship', userData['emergencyContactRelation'] ?? 'Not provided', Icons.people),
        _buildDetailItem('Phone', userData['emergencyContactPhone'] ?? 'Not provided', Icons.phone),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: primaryColor),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor.withOpacity(0.6),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditButton() {
    return Center(
      child: ReusableButton(
        label: "Edit Profile",
        icon: Icons.edit,
        onPressed: onEdit,
      ),
    );
  }

  String _formatListItems(dynamic list) {
    if (list == null) return 'None';

    if (list is List) {
      if (list.isEmpty) return 'None';
      return list.join(', ');
    }

    return list.toString();
  }
}

class EditProfileScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const EditProfileScreen({
    Key? key,
    required this.userId,
    required this.userData,
  }) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserDetailsService _userDetailsService = UserDetailsService();
  bool _isLoading = false;
  String _errorMessage = '';
  String _successMessage = '';
  late Map<String, dynamic> _editableData;

  // Controllers for form fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _aadharController = TextEditingController();
  final TextEditingController _medicationsController = TextEditingController();
  final TextEditingController _emergencyNameController = TextEditingController();
  final TextEditingController _emergencyRelationController = TextEditingController();
  final TextEditingController _emergencyPhoneController = TextEditingController();
  final TextEditingController _fastingBloodSugarController = TextEditingController();
  final TextEditingController _postMealBloodSugarController = TextEditingController();
  final TextEditingController _sleepHoursController = TextEditingController();

  // Dropdowns and toggles
  String? _selectedDiabetesType;
  String? _selectedActivityLevel;
  String? _selectedDietType;
  String? _selectedMonitoringFrequency;
  String? _selectedGender;
  bool _hasDiabetes = false;
  bool _takingMedication = false;
  bool _hasFamilyHistory = false;
  bool _isSmoker = false;
  bool _consumesAlcohol = false;
  bool _checksBloodSugar = false;
  bool _ownsGlucometer = false;

  // Multi-select options
  List<String> _selectedHealthConditions = [];
  List<String> _selectedSymptoms = [];

  // Options for dropdowns
  final List<String> _diabetesTypes = ['Type 1', 'Type 2', 'Gestational', 'Pre-diabetic', 'Other'];
  final List<String> _activityLevels = ['Sedentary', 'Light', 'Moderate', 'Active', 'Very Active'];
  final List<String> _dietTypes = ['Vegetarian', 'Vegan', 'Non-vegetarian', 'Pescatarian', 'Keto', 'Low-carb', 'Other'];
  final List<String> _monitoringFrequencies = ['Daily', 'Weekly', 'Monthly', 'Occasionally', 'Never'];
  final List<String> _genderOptions = ['Male', 'Female', 'Other', 'Prefer not to say'];

  // Health conditions and symptoms lists
  final List<String> _healthConditionOptions = [
    'High Blood Pressure', 'Heart Disease', 'Kidney Disease', 'Thyroid Disorder',
    'Obesity', 'Depression/Anxiety', 'Asthma', 'Cancer', 'Stroke', 'Other'
  ];

  final List<String> _symptomOptions = [
    'Frequent Urination', 'Excessive Thirst', 'Unexplained Weight Loss', 'Extreme Hunger',
    'Blurred Vision', 'Fatigue', 'Slow-healing Sores', 'Frequent Infections', 'Numbness/Tingling in Hands/Feet', 'None'
  ];

  @override
  void initState() {
    super.initState();
    _initializeFormData();
  }

  void _initializeFormData() {
    // Create a copy of the userData to edit
    _editableData = Map<String, dynamic>.from(widget.userData);

    // Initialize text controllers
    _nameController.text = _editableData['name'] ?? '';
    _phoneController.text = _editableData['phone'] ?? '';
    _addressController.text = _editableData['address'] ?? '';
    _aadharController.text = _editableData['aadharnumber'] ?? '';
    _medicationsController.text = _editableData['medications'] ?? '';
    _emergencyNameController.text = _editableData['emergencyContactName'] ?? '';
    _emergencyRelationController.text = _editableData['emergencyContactRelation'] ?? '';
    _emergencyPhoneController.text = _editableData['emergencyContactPhone'] ?? '';
    _fastingBloodSugarController.text = _editableData['fastingBloodSugar']?.toString() ?? '';
    _postMealBloodSugarController.text = _editableData['postMealBloodSugar']?.toString() ?? '';
    _sleepHoursController.text = _editableData['sleepHours']?.toString() ?? '';

    // Initialize dropdowns with validation to ensure values exist in the option lists
    _selectedDiabetesType = _validateDropdownValue(_editableData['diabetesType'], _diabetesTypes);
    _selectedActivityLevel = _validateDropdownValue(_editableData['activityLevel'], _activityLevels);
    _selectedDietType = _validateDropdownValue(_editableData['dietType'], _dietTypes);
    _selectedMonitoringFrequency = _validateDropdownValue(_editableData['monitoringFrequency'], _monitoringFrequencies);
    _selectedGender = _editableData['gender'] == 'Not specified' ? null : _validateDropdownValue(_editableData['gender'], _genderOptions);

    // Initialize booleans
    _hasDiabetes = _editableData['hasDiabetes'] ?? false;
    _takingMedication = _editableData['takingMedication'] ?? false;
    _hasFamilyHistory = _editableData['familyHistory'] ?? false;
    _isSmoker = _editableData['isSmoker'] ?? false;
    _consumesAlcohol = _editableData['consumesAlcohol'] ?? false;
    _checksBloodSugar = _editableData['checksBloodSugar'] ?? false;
    _ownsGlucometer = _editableData['ownsGlucometer'] ?? false;

    // Initialize multi-select options
    _selectedHealthConditions = _convertToStringList(_editableData['healthConditions']);
    _selectedSymptoms = _convertToStringList(_editableData['symptoms']);
  }

  // Validate dropdown values to ensure they exist in the options list
  String? _validateDropdownValue(String? value, List<String> options) {
    if (value == null) return null;
    return options.contains(value) ? value : null;
  }

  List<String> _convertToStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return [];
  }

  @override
  void dispose() {
    // Dispose all controllers
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _aadharController.dispose();
    _medicationsController.dispose();
    _emergencyNameController.dispose();
    _emergencyRelationController.dispose();
    _emergencyPhoneController.dispose();
    _fastingBloodSugarController.dispose();
    _postMealBloodSugarController.dispose();
    _sleepHoursController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
        _successMessage = '';
      });

      // Update the editable data from form values
      Map<String, dynamic> updatedData = {
        'name': _nameController.text,
        'phone_number': _phoneController.text,
        'address': _addressController.text,
        'aadhaarNumber': _aadharController.text,
        'gender': _selectedGender ?? 'Not specified',

        // Medical data
        'hasDiabetes': _hasDiabetes,
        'diabetesType': _selectedDiabetesType,
        'takingMedication': _takingMedication,
        'medications': _takingMedication ? _medicationsController.text : '',
        'healthConditions': _selectedHealthConditions,
        'familyHistory': _hasFamilyHistory,
        'symptoms': _selectedSymptoms,
        'activityLevel': _selectedActivityLevel,
        'dietType': _selectedDietType,
        'isSmoker': _isSmoker,
        'consumesAlcohol': _consumesAlcohol,
        'sleepHours': _sleepHoursController.text,
        'checksBloodSugar': _checksBloodSugar,
        'monitoringFrequency': _checksBloodSugar ? _selectedMonitoringFrequency : '',
        'ownsGlucometer': _ownsGlucometer,
        'fastingBloodSugar': _fastingBloodSugarController.text,
        'postMealBloodSugar': _postMealBloodSugarController.text,
        'emergencyContactName': _emergencyNameController.text,
        'emergencyContactRelation': _emergencyRelationController.text,
        'emergencyContactPhone': _emergencyPhoneController.text,
      };

      try {
        final response = await _userDetailsService.updateMedicalData(widget.userId, updatedData);

        setState(() {
          _isLoading = false;
        });

        if (response['status'] == 'success') {
          setState(() {
            _successMessage = 'Profile updated successfully!';
          });
          // Wait a moment and then navigate back
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.pop(context, true);
          });
        } else {
          setState(() {
            _errorMessage = response['message'] ?? 'Failed to update profile';
          });
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An error occurred: $e';
        });
      }
    }
  }

  Widget _buildMultiSelectChips(
      List<String> options,
      List<String> selectedValues,
      Function(List<String>) onChanged,
      String title
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedValues.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                List<String> newSelection = List.from(selectedValues);
                if (selected) {
                  newSelection.add(option);
                } else {
                  newSelection.remove(option);
                }
                onChanged(newSelection);
              },
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.3),
              checkmarkColor: Theme.of(context).primaryColor,
              backgroundColor: Colors.grey.withOpacity(0.1),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? Center(
        child: LoadingAnimationWidget.discreteCircle(
          color: Colors.pink,
          secondRingColor: Colors.teal,
          thirdRingColor: Colors.orange,
          size: 60,
        ),
      )
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            if (_successMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.green),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _successMessage,
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),

            _buildSectionTitle('Personal Information', Icons.person),
            const SizedBox(height: 16),

            // Personal Information Fields
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person, color: Theme.of(context).primaryColor),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone, color: Theme.of(context).primaryColor),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: InputDecoration(
                labelText: 'Gender',
                prefixIcon: Icon(Icons.people, color: Theme.of(context).primaryColor),
                border: OutlineInputBorder(),
              ),
              items: _genderOptions.map((gender) {
                return DropdownMenuItem(
                  value: gender,
                  child: Text(gender),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGender = value;
                });
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Address',
                prefixIcon: Icon(Icons.home, color: Theme.of(context).primaryColor),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _aadharController,
              decoration: InputDecoration(
                labelText: 'Aadhaar Number',
                prefixIcon: Icon(Icons.credit_card, color: Theme.of(context).primaryColor),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),

            // Medical History Section
            _buildSectionTitle('Medical History', Icons.medical_services),
            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text('Has Diabetes'),
              value: _hasDiabetes,
              onChanged: (value) {
                setState(() {
                  _hasDiabetes = value;
                });
              },
              activeColor: Theme.of(context).primaryColor,
            ),

            if (_hasDiabetes)
              DropdownButtonFormField<String>(
                value: _selectedDiabetesType,
                decoration: InputDecoration(
                  labelText: 'Diabetes Type',
                  border: OutlineInputBorder(),
                ),
                items: _diabetesTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDiabetesType = value;
                  });
                },
              ),
            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text('Taking Medication'),
              value: _takingMedication,
              onChanged: (value) {
                setState(() {
                  _takingMedication = value;
                });
              },
              activeColor: Theme.of(context).primaryColor,
            ),

            if (_takingMedication)
              TextFormField(
                controller: _medicationsController,
                decoration: InputDecoration(
                  labelText: 'Medications',
                  hintText: 'List your current medications',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            const SizedBox(height: 16),

            _buildMultiSelectChips(
                _healthConditionOptions,
                _selectedHealthConditions,
                    (newValues) {
                  setState(() {
                    _selectedHealthConditions = newValues;
                  });
                },
                'Health Conditions'
            ),
            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text('Family History of Diabetes'),
              value: _hasFamilyHistory,
              onChanged: (value) {
                setState(() {
                  _hasFamilyHistory = value;
                });
              },
              activeColor: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 16),

            _buildMultiSelectChips(
                _symptomOptions,
                _selectedSymptoms,
                    (newValues) {
                  setState(() {
                    _selectedSymptoms = newValues;
                  });
                },
                'Symptoms'
            ),
            const SizedBox(height: 24),

            // Lifestyle Section
            _buildSectionTitle('Lifestyle Information', Icons.self_improvement),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedActivityLevel,
              decoration: InputDecoration(
                labelText: 'Activity Level',
                border: OutlineInputBorder(),
              ),
              items: _activityLevels.map((level) {
                return DropdownMenuItem(
                  value: level,
                  child: Text(level),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedActivityLevel = value;
                });
              },
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedDietType,
              decoration: InputDecoration(
                labelText: 'Diet Type',
                border: OutlineInputBorder(),
              ),
              items: _dietTypes.map((diet) {
                return DropdownMenuItem(
                  value: diet,
                  child: Text(diet),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDietType = value;
                });
              },
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: SwitchListTile(
                    title: const Text('Smoker'),
                    value: _isSmoker,
                    onChanged: (value) {
                      setState(() {
                        _isSmoker = value;
                      });
                    },
                    activeColor: Theme.of(context).primaryColor,
                  ),
                ),
                Expanded(
                  child: SwitchListTile(
                    title: const Text('Alcohol'),
                    value: _consumesAlcohol,
                    onChanged: (value) {
                      setState(() {
                        _consumesAlcohol = value;
                      });
                    },
                    activeColor: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _sleepHoursController,
              decoration: InputDecoration(
                labelText: 'Sleep Hours (per day)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text('Checks Blood Sugar Regularly'),
              value: _checksBloodSugar,
              onChanged: (value) {
                setState(() {
                  _checksBloodSugar = value;
                });
              },
              activeColor: Theme.of(context).primaryColor,
            ),

            if (_checksBloodSugar)
              DropdownButtonFormField<String>(
                value: _selectedMonitoringFrequency,
                decoration: InputDecoration(
                  labelText: 'Monitoring Frequency',
                  border: OutlineInputBorder(),
                ),
                items: _monitoringFrequencies.map((frequency) {
                  return DropdownMenuItem(
                    value: frequency,
                    child: Text(frequency),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMonitoringFrequency = value;
                  });
                },
              ),
            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text('Owns Glucometer'),
              value: _ownsGlucometer,
              onChanged: (value) {
                setState(() {
                  _ownsGlucometer = value;
                });
              },
              activeColor: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _fastingBloodSugarController,
                    decoration: InputDecoration(
                      labelText: 'Fasting Blood Sugar (mg/dL)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _postMealBloodSugarController,
                    decoration: InputDecoration(
                      labelText: 'Post-meal Blood Sugar (mg/dL)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Emergency Contact Section
            _buildSectionTitle('Emergency Contact', Icons.emergency),
            const SizedBox(height: 16),

            TextFormField(
              controller: _emergencyNameController,
              decoration: InputDecoration(
                labelText: 'Contact Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _emergencyRelationController,
              decoration: InputDecoration(
                labelText: 'Relationship',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _emergencyPhoneController,
              decoration: InputDecoration(
                labelText: 'Contact Phone Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 32),

            // Save Button
            Center(
              child: ElevatedButton.icon(
                onPressed: _saveChanges,
                icon: const Icon(Icons.save),
                label: const Text('Save Changes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
     );
  }
}