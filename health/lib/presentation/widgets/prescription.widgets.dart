import 'package:flutter/material.dart';

import '../../data/datasources/prescription.service.dart';
import '../../data/models/prescription.dart';
import '../controller/pharmacy.controller.dart';

class BuildPrescriptionCard extends StatefulWidget {
  final String patientId;
  final String? doctorId;
  final Prescription? existingPrescription;

  const BuildPrescriptionCard({
    required this.patientId,
    required this.doctorId,
    this.existingPrescription,
  });

  @override
  State<BuildPrescriptionCard> createState() => _BuildPrescriptionCardState();
}

class _BuildPrescriptionCardState extends State<BuildPrescriptionCard> {
  final List<PrescriptionItem> _medications = [];
  final PrescriptionService _prescriptionService = PrescriptionService();
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // If editing an existing prescription, load its data
    if (widget.existingPrescription != null) {
      _loadExistingPrescription();
    }
  }

  void _loadExistingPrescription() {
    final prescription = widget.existingPrescription!;
    setState(() {
      _medications.addAll(prescription.items);
      _notesController.text = prescription.notes ?? '';
    });
  }

  // In _BuildPrescriptionCardState._addMedication method
  void _addMedication() async {
    final result = await showDialog(
      context: context,
      builder: (context) => _buildMedicationDialog(),
    );

    if (result != null && result is List) {
      setState(() {
        for (final medicationData in result) {
          // Improved medicine ID handling
          int medicineId = 0;
          final rawId = medicationData['medicineId'];

          if (rawId != null) {
            if (rawId is int) {
              medicineId = rawId;
            } else if (rawId is String) {
              medicineId = int.tryParse(rawId) ?? 0;
            }
          }

          final item = PrescriptionItem.fromDialogData(medicationData, medicineId);
          _medications.add(item);
        }
      });
    }
  }

  Future<void> _savePrescription() async {
    if (_medications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one medication'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final prescription = Prescription(
        id: widget.existingPrescription?.id,
        patientId: widget.patientId,
        doctorId: widget.doctorId,
        status: widget.existingPrescription?.status ?? 'active',
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        createdAt: widget.existingPrescription?.createdAt ?? DateTime.now(),
        items: _medications,
      );

      if (widget.existingPrescription != null) {
        // Update existing prescription
        await _prescriptionService.updatePrescription(prescription);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prescription updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Create new prescription
        await _prescriptionService.createPrescription(prescription);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prescription saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Clear medications after successful save
        setState(() {
          _medications.clear();
          _notesController.clear();
        });
      }
    } catch (e) {
      print("Failed to save prescription: $e");
      setState(() {
        _errorMessage = 'Failed to save prescription: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _deletePrescription() async {
    if (widget.existingPrescription == null || widget.existingPrescription!.id == null) {
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Prescription'),
        content: const Text('Are you sure you want to delete this prescription? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _prescriptionService.deletePrescription(widget.existingPrescription!.id!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prescription deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back or notify parent
      Navigator.of(context).pop(true); // Return true to indicate deletion
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to delete prescription: $e';
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.medication, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'Prescription',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (widget.existingPrescription != null)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: _isLoading ? null : _deletePrescription,
                    tooltip: 'Delete Prescription',
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Show prescription status if existing
            if (widget.existingPrescription != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(widget.existingPrescription!.status),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  widget.existingPrescription!.status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Error message if any
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ),
                  ],
                ),
              ),

            // Notes field
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Add any special notes about this prescription',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 16),

            // Medications list
            const Text(
              'Medications',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            _medications.isEmpty
                ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No medications prescribed yet',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _medications.length,
              itemBuilder: (context, index) {
                final med = _medications[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: _getPriorityColor(med.priority).withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: _getPriorityColor(med.priority).withOpacity(0.3),
                    ),
                  ),
                  child: ListTile(
                    title: Text(med.medicineName,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dosage: ${med.dosage}'),
                        Text('Frequency: ${med.timesOfDay.join(", ")} - ${med.mealTiming}'),
                        Text('Duration: ${med.duration}'),
                        if (med.instructions != null && med.instructions!.isNotEmpty)
                          Text('Instructions: ${med.instructions}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(med.priority),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            med.priority[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _medications.removeAt(index);
                            });
                          },
                          tooltip: 'Remove medication',
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Medication'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: _isLoading || _isSaving ? null : _addMedication,
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: Icon(_isSaving ? Icons.hourglass_empty : Icons.save),
                  label: Text(_isSaving ? 'Saving...' : 'Save Prescription'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: _isLoading || _isSaving ? null : _savePrescription,
                ),
              ],
            ),

            if (_isLoading)
              Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Colors.indigo;
      case 'high':
        return Colors.blue;
      case 'normal':
      default:
        return Colors.teal;
    }
  }

  Widget _buildMedicationDialog() {
    final nameController = TextEditingController();
    final dosageController = TextEditingController();
    final durationController = TextEditingController();
    final instructionsController = TextEditingController();
    String selectedPriority = 'Normal';
    String selectedMealTiming = 'After Food';

    // State for medicine list
    List<Medicine> availableMedicines = [];
    bool isLoadingMedicines = true;
    String? errorMessage;

    // Medicine search functionality
    final searchController = TextEditingController();
    List<Medicine> filteredMedicines = [];
    Medicine? selectedMedicine;

    // Convert to lists to allow multiple selections
    List<String> selectedTimesOfDay = ['Morning'];

    // List to store added medications
    List<Map<String, dynamic>> addedMedications = [];

    return StatefulBuilder(
      builder: (context, setDialogState) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final screenSize = MediaQuery.of(context).size;
        final isSmallScreen = screenSize.width < 600;

        // Initialize medicine list on first build
        void loadMedicines() async {
          try {
            final prescriptionService = PrescriptionService();
            final medicines = await prescriptionService.fetchMedicines();

            setDialogState(() {
              availableMedicines = medicines;
              filteredMedicines = medicines;
              isLoadingMedicines = false;
              errorMessage = null;
            });
          } catch (e) {
            setDialogState(() {
              isLoadingMedicines = false;
              errorMessage = 'Failed to load medicines: $e';
            });
          }
        }

        // Call loadMedicines only once when the dialog is first shown
        if (isLoadingMedicines && errorMessage == null) {
          loadMedicines();
        }

        // Search functionality
        void filterMedicines(String query) {
          setDialogState(() {
            if (query.isEmpty) {
              filteredMedicines = availableMedicines;
            } else {
              filteredMedicines = availableMedicines
                  .where((medicine) =>
                  medicine.name.toLowerCase().contains(query.toLowerCase()))
                  .toList();
            }
          });
        }

        // Define professional medication priority colors
        final normalColor = Colors.teal;
        final highColor = Colors.blue;
        final urgentColor = Colors.indigo;

        // Get medication priority color
        Color getPriorityColor() {
          switch (selectedPriority) {
            case 'High': return highColor;
            case 'Urgent': return urgentColor;
            default: return normalColor;
          }
        }

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          clipBehavior: Clip.antiAlias,
          child: Container(
            width: isSmallScreen ? screenSize.width * 0.95 : 550,
            constraints: BoxConstraints(
              maxHeight: screenSize.height * 0.85,
              maxWidth: screenSize.width * 0.95,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Enhanced header with gradient background
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 16 : 20,
                      vertical: isSmallScreen ? 12 : 16
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        highColor.shade700,
                        highColor.shade600,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.medication,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Add Medication',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                        isSmallScreen ? 16 : 24,
                        isSmallScreen ? 16 : 20,
                        isSmallScreen ? 16 : 24,
                        isSmallScreen ? 8 : 12
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Subtitle with icon
                        Row(
                          children: [
                            Icon(Icons.person, size: 16, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Enter prescription details for patient',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[700],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Show medicine search box
                        Text('Search Medications', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),

                        // Medicine search input
                        TextFormField(
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: 'Search medicines...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            suffixIcon: searchController.text.isNotEmpty
                                ? IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                searchController.clear();
                                filterMedicines('');
                              },
                            )
                                : null,
                          ),
                          onChanged: filterMedicines,
                        ),

                        const SizedBox(height: 16),

                        // Show medicines list or loading state
                        if (isLoadingMedicines)
                          Center(
                            child: Column(
                              children: [
                                CircularProgressIndicator(color: highColor),
                                const SizedBox(height: 8),
                                Text('Loading medicines...'),
                              ],
                            ),
                          )
                        else if (errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Error',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(errorMessage!),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Try Again'),
                                  onPressed: () {
                                    setDialogState(() {
                                      isLoadingMedicines = true;
                                      errorMessage = null;
                                    });
                                    loadMedicines();
                                  },
                                ),
                              ],
                            ),
                          )
                        else if (filteredMedicines.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  searchController.text.isEmpty
                                      ? 'No medicines available'
                                      : 'No medicines found matching "${searchController.text}"',
                                  style: TextStyle(fontStyle: FontStyle.italic),
                                ),
                              ),
                            )
                          else
                            DropdownButtonFormField<Medicine>(
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Select Medicine',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              value: selectedMedicine,
                              items: filteredMedicines.map((medicine) {
                                return DropdownMenuItem<Medicine>(
                                  value: medicine,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(medicine.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      if (medicine.genericName != null)
                                        Text(
                                          medicine.genericName!,
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      if (medicine.manufacturer != null)
                                        Text(
                                          medicine.manufacturer!,
                                          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (medicine) {
                                if (medicine != null) {
                                  setDialogState(() {
                                    selectedMedicine = medicine;
                                    nameController.text = medicine.name;
                                    if (medicine.category != null) {
                                      dosageController.text = medicine.category!;
                                    }
                                  });
                                }
                              },
                              selectedItemBuilder: (context) {
                                return filteredMedicines.map((medicine) {
                                  return Text(medicine.name); // Only display name when selected
                                }).toList();
                              },
                            ),

                        const SizedBox(height: 24),

                        // Manual entry option
                        Text(
                          selectedMedicine != null
                              ? 'Selected Medicine: ${selectedMedicine!.name}'
                              : 'Manual Entry',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        if (selectedMedicine != null)
                          TextButton.icon(
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Clear Selection'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              alignment: Alignment.centerLeft,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                selectedMedicine = null;
                              });
                            },
                          ),

                        const SizedBox(height: 16),

                        _buildFormField(
                          controller: nameController,
                          label: 'Medication Name*',
                          hint: 'e.g., Metformin, Amoxicillin, Lisinopril',
                          icon: Icons.medical_services,
                          color: highColor,
                        ),
                        const SizedBox(height: 16),

                        // 2. Duration and Dosage fields
                        if (!isSmallScreen)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildFormField(
                                  controller: durationController,
                                  label: 'Duration*',
                                  hint: 'e.g., 30 days, 1 week, As needed',
                                  icon: Icons.calendar_today,
                                  color: highColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildFormField(
                                  controller: dosageController,
                                  label: 'Dosage*',
                                  hint: 'e.g., 500mg, 10mg, 5ml',
                                  icon: Icons.scale,
                                  color: highColor,
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _buildFormField(
                            controller: durationController,
                            label: 'Duration*',
                            hint: 'e.g., 30 days, 1 week, As needed',
                            icon: Icons.calendar_today,
                            color: highColor,
                          ),
                          const SizedBox(height: 16),
                          _buildFormField(
                            controller: dosageController,
                            label: 'Dosage*',
                            hint: 'e.g., 500mg, 10mg, 5ml',
                            icon: Icons.scale,
                            color: highColor,
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Special instructions with more height
                        _buildFormField(
                          controller: instructionsController,
                          label: 'Special Instructions',
                          hint: 'e.g., Take with food, Avoid alcohol, Store in refrigerator',
                          icon: Icons.info_outline,
                          color: highColor,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),

                        // 3. THIRD: Meal timing and Time of Day
                        // Meal timing
                        Text('Meal Timing', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: selectedMealTiming,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.restaurant_menu),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          items: ['Before Food', 'After Food', 'With Food']
                              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                              .toList(),
                          onChanged: (value) => setDialogState(() => selectedMealTiming = value!),
                        ),

                        const SizedBox(height: 16),

                        // Multiple Time of Day selections
                        Text('Time of Day (Select multiple)', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ['Morning', 'Afternoon', 'Evening', 'Night'].map((time) {
                            final isSelected = selectedTimesOfDay.contains(time);
                            return FilterChip(
                              label: Text(time),
                              selected: isSelected,
                              checkmarkColor: Colors.white,
                              selectedColor: highColor,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (selected) {
                                setDialogState(() {
                                  if (selected) {
                                    if (!selectedTimesOfDay.contains(time)) {
                                      selectedTimesOfDay.add(time);
                                    }
                                  } else {
                                    selectedTimesOfDay.remove(time);
                                    // Ensure at least one time is selected
                                    if (selectedTimesOfDay.isEmpty) {
                                      selectedTimesOfDay.add('Morning');
                                    }
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 24),

                        // Enhanced priority selection with better visual feedback
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Priority',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Responsive priority chips layout
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                _buildPriorityChip(
                                  label: 'Normal',
                                  icon: Icons.check_circle_outline,
                                  color: normalColor,
                                  isSelected: selectedPriority == 'Normal',
                                  onSelected: (selected) {
                                    if (selected) {
                                      setDialogState(() {
                                        selectedPriority = 'Normal';
                                      });
                                    }
                                  },
                                ),
                                _buildPriorityChip(
                                  label: 'High',
                                  icon: Icons.priority_high,
                                  color: highColor,
                                  isSelected: selectedPriority == 'High',
                                  onSelected: (selected) {
                                    if (selected) {
                                      setDialogState(() {
                                        selectedPriority = 'High';
                                      });
                                    }
                                  },
                                ),
                                _buildPriorityChip(
                                  label: 'Urgent',
                                  icon: Icons.warning_amber_rounded,
                                  color: urgentColor,
                                  isSelected: selectedPriority == 'Urgent',
                                  onSelected: (selected) {
                                    if (selected) {
                                      setDialogState(() {
                                        selectedPriority = 'Urgent';
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Display added medications
                        if (addedMedications.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Text(
                            'Added Medications',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...addedMedications.map((med) => _buildAddedMedicationCard(
                            med,
                            onRemove: () {
                              setDialogState(() {
                                addedMedications.remove(med);
                              });
                            },
                            theme: theme,
                          )).toList(),
                        ],
                      ],
                    ),
                  ),
                ),

                // Enhanced footer with action buttons
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12 : 16,
                      vertical: isSmallScreen ? 8 : 12
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Action buttons with enhanced styling
                      // Adaptive layout for buttons based on screen size
                      isSmallScreen
                          ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              side: BorderSide(color: Colors.grey[400]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(null),
                            child: Text(
                              'Cancel',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              backgroundColor: getPriorityColor(),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              // Validate form data
                              if (nameController.text.isEmpty ||
                                  dosageController.text.isEmpty ||
                                  durationController.text.isEmpty) {
                                // Show error message for required fields
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Please fill in all required fields'),
                                    backgroundColor: Colors.red[700],
                                  ),
                                );
                                return;
                              }

                              // Create medication object and add to list
                              final medication = {
                                'name': nameController.text,
                                'dosage': dosageController.text,
                                'duration': durationController.text,
                                'instructions': instructionsController.text,
                                'priority': selectedPriority,
                                'mealTiming': selectedMealTiming,
                                'timesOfDay': List<String>.from(selectedTimesOfDay),
                                'medicineId': selectedMedicine?.id,
                              };

                              // Add to medications list
                              setDialogState(() {
                                addedMedications.add(medication);
                              });

                              // Return medication data to caller
                              Navigator.of(context).pop([...addedMedications]);
                            },
                            child: Text('Save Medication${addedMedications.isNotEmpty ? "s" : ""}'),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            icon: Icon(Icons.add_circle_outline),
                            label: Text('Add Another Medicine'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              backgroundColor: Colors.green[600],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              // Validate form data
                              if (nameController.text.isEmpty ||
                                  dosageController.text.isEmpty ||
                                  durationController.text.isEmpty) {
                                // Show error message for required fields
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Please fill in all required fields'),
                                    backgroundColor: Colors.red[700],
                                  ),
                                );
                                return;
                              }

                              // Create medication object and add to list
                              final medication = {
                                'name': nameController.text,
                                'dosage': dosageController.text,
                                'duration': durationController.text,
                                'instructions': instructionsController.text,
                                'priority': selectedPriority,
                                'mealTiming': selectedMealTiming,
                                'timesOfDay': List<String>.from(selectedTimesOfDay),
                                'medicineId': selectedMedicine?.id,
                              };

                              // Add to medications list
                              setDialogState(() {
                                addedMedications.add(medication);
                              });

                              // Clear form fields for next medication
                              nameController.clear();
                              dosageController.clear();
                              durationController.clear();
                              instructionsController.clear();

                              // Reset selections to defaults
                              setDialogState(() {
                                selectedPriority = 'Normal';
                                selectedMealTiming = 'After Food';
                                selectedTimesOfDay = ['Morning'];
                                selectedMedicine = null;
                              });

                              // Show confirmation message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Medication added! Add another one.'),
                                  backgroundColor: Colors.green[700],
                                ),
                              );
                            },
                          ),
                        ],
                      )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              side: BorderSide(color: Colors.grey[400]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(null),
                            child: Text(
                              'Cancel',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              backgroundColor: getPriorityColor(),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              // Validate form data
                              if (nameController.text.isEmpty ||
                                  dosageController.text.isEmpty ||
                                  durationController.text.isEmpty) {
                                // Show error message for required fields
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Please fill in all required fields'),
                                    backgroundColor: Colors.red[700],
                                  ),
                                );
                                return;
                              }

                              // Create medication object and add to list
                              final medication = {
                                'name': nameController.text,
                                'dosage': dosageController.text,
                                'duration': durationController.text,
                                'instructions': instructionsController.text,
                                'priority': selectedPriority,
                                'mealTiming': selectedMealTiming,
                                'timesOfDay': List<String>.from(selectedTimesOfDay),
                                'medicineId': selectedMedicine?.id,
                              };

                              // Add to medications list
                              setDialogState(() {
                                addedMedications.add(medication);
                              });

                              // Return medication data to caller
                              Navigator.of(context).pop([...addedMedications]);
                            },
                            child: Text('Save Medication${addedMedications.isNotEmpty ? "s" : ""}'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: Icon(Icons.add_circle_outline),
                            label: Text('Add Another Medicine'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              backgroundColor: Colors.green[600],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              // Validate form data
                              if (nameController.text.isEmpty ||
                                  dosageController.text.isEmpty ||
                                  durationController.text.isEmpty) {
                                // Show error message for required fields
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Please fill in all required fields'),
                                    backgroundColor: Colors.red[700],
                                  ),
                                );
                                return;
                              }

                              // Create medication object and add to list
                              final medication = {
                                'name': nameController.text,
                                'dosage': dosageController.text,
                                'duration': durationController.text,
                                'instructions': instructionsController.text,
                                'priority': selectedPriority,
                                'mealTiming': selectedMealTiming,
                                'timesOfDay': List<String>.from(selectedTimesOfDay),
                                'medicineId': selectedMedicine?.id,
                              };

                              // Add to medications list
                              setDialogState(() {
                                addedMedications.add(medication);
                              });

                              // Clear form fields for next medication
                              nameController.clear();
                              dosageController.clear();
                              durationController.clear();
                              instructionsController.clear();

                              // Reset selections to defaults
                              setDialogState(() {
                                selectedPriority = 'Normal';
                                selectedMealTiming = 'After Food';
                                selectedTimesOfDay = ['Morning'];
                                selectedMedicine = null;
                              });

                              // Show confirmation message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Medication added! Add another one.'),
                                  backgroundColor: Colors.green[700],
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
      },
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color color,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: color),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityChip({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required Function(bool) onSelected,
  }) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : color,
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      showCheckmark: false,
      selectedColor: color,
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey,
        fontWeight: FontWeight.bold,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? Colors.transparent : color.withOpacity(0.5),
          width: 1,
        ),
      ),
      onSelected: onSelected,
    );
  }

  Widget _buildAddedMedicationCard(Map<String, dynamic> medication, {required Function onRemove, required ThemeData theme}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medication['name'],
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time_filled, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${medication['timesOfDay'].join(', ')} - ${medication['mealTiming']}',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),
                  if (medication['instructions'] != null && medication['instructions'].isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      medication['instructions'],
                      style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => onRemove(),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.red[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
