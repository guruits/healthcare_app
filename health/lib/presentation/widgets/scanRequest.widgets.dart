import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../data/datasources/doctorconsultation_services.dart';
import '../controller/consultation.controller.dart';
import '../screens/consultaionpageAdmin.dart';

class BuildScanRequestsCard extends StatefulWidget {
  const BuildScanRequestsCard({super.key});

  @override
  State<BuildScanRequestsCard> createState() => _BuildScanRequestsCardState();
}

class _BuildScanRequestsCardState extends State<BuildScanRequestsCard> {
  DoctorconsultationServices _doctorconsultationServices = DoctorconsultationServices();
  final ConsultationController _controller = ConsultationController();

  List<ScanRequest> _scanRequests = [];
  List<ScanType> _scanTypes = [];


  bool _isLoading = false;
  bool _hasUnsavedChanges = false;

  Future<void> _fetchScanRequests() async {
    try {
      final requests = await _doctorconsultationServices.getPatientScanRequests(_controller.patientId);
      setState(() {
        _scanRequests = requests;
      });
      print('Loaded ${_scanRequests.length} scan requests');
    } catch (e) {
      print('Error fetching scan requests: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load scan requests. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  Future<void> _fetchDialogData(StateSetter setState, Function(List<ReferringTeam>, List<ScanType>) onComplete) async {


    try {
      // Fetch both data sets in parallel
      final futureTeams = _doctorconsultationServices.fetchReferringTeams();
      final futureScanTypes = _doctorconsultationServices.fetchScanTypes();

      // Wait for both to complete
      final results = await Future.wait([futureTeams, futureScanTypes]);

      // Update state when data is available
      setState(() {
        onComplete(results[0] as List<ReferringTeam>, results[1] as List<ScanType>);
      });
    } catch (e) {
      print('Error fetching scan data: $e');
      setState(() {
        // Provide empty lists on error
        onComplete([], []);
      });

      // You might want to show an error message
    }
  }

  void _requestScan() {
    showDialog(
      context: context,
      builder: (context) => buildScanRequestDialog(),
    );
  }

  void _editScanRequest(ScanRequest request) {
    showDialog(
      context: context,
      builder: (context) => _buildEditScanRequestDialog(request),
    );
  }

  @override
  Widget build(BuildContext context) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with animation
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.document_scanner, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Medical Test',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_scanRequests.length} Total',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh, color: Colors.black),
                    onPressed: _fetchScanRequests,
                  ),
                ],
              ),
              const Divider(height: 24, thickness: 1),

              // Empty state with better styling
              if (_scanRequests.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  width: double.infinity,
                  child: Column(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Medical requests created',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create a new Medical request to get started',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              else
              // Enhanced list with better styling
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _scanRequests.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final request = _scanRequests[index];

                    // Get scan type name using the helper method
                    final scanTypeName = _getScanTypeName(request.testType);

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    scanTypeName, // Use the scan type name instead of raw ID
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(request.status),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _getStatusColor(request.status).withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    request.status,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Enhanced metadata display
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.group, size: 16, color: Colors.blueGrey),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Name: ${request.testName}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        request.urgency == 'High' ? Icons.priority_high : Icons.low_priority,
                                        size: 16,
                                        color: request.urgency == 'High' ? Colors.red : Colors.green,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Urgency: ${request.urgency}',
                                        style: TextStyle(
                                          color: request.urgency == 'High' ? Colors.red : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 16, color: Colors.blueGrey),
                                      const SizedBox(width: 8),
                                      Text('Submitted: ${request.dateRequested}'),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            if (request.instructions.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.amber.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Instructions:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      request.instructions,
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Improved action buttons
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.receipt_long, size: 16),
                                  label: const Text('View'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.blue,
                                    side: const BorderSide(color: Colors.blue),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  onPressed: () {
                                    // Show request form details
                                  },
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('Edit'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.orange,
                                    side: const BorderSide(color: Colors.orange),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  onPressed: () {
                                    _editScanRequest(request);
                                  },
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.cancel, size: 16),
                                  label: const Text('Cancel'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  onPressed: () {
                                    _showCancelConfirmDialog(request);
                                  },
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.print, size: 16),
                                  label: const Text('Print'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  onPressed: () {
                                    // Print request
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              // Enhanced call-to-action button
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Request New Diagnostic Request'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 2,
                  ),
                  onPressed: _requestScan,
                ),
              ),
            ],
          ),
        ),
      );
    }

  Widget buildScanRequestDialog() {
    // Controllers
    final TextEditingController instructionsController = TextEditingController();
    final TextEditingController scanTypeController = TextEditingController();

    // State variables
    String? selectedScanType;
    String selectedUrgency = 'Normal';
    bool isLoading = true;
    List<ScanType> scanTypes = [];

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        // Fetch data when the dialog opens
        if (isLoading) {
          _fetchDialogData(setState, (fetchedTeams, fetchedScanTypes) {

            scanTypes = fetchedScanTypes;
            isLoading = false;
          });
        }

        // Get screen size for responsiveness
        final screenSize = MediaQuery.of(context).size;
        final isSmallScreen = screenSize.width < 600;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          elevation: 4,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 16 : 80,
            vertical: isSmallScreen ? 24 : 80,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 650,
              maxHeight: isSmallScreen ? screenSize.height * 0.9 : screenSize.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Professional header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A365D), // Navy blue professional color
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12.0),
                      topRight: Radius.circular(12.0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.document_scanner,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'New Diagnostic Request',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Patient referral form',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable content for responsiveness
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Form instruction text
                        const Padding(
                          padding: EdgeInsets.only(bottom: 20),
                          child: Text(
                            'Please complete all required fields (*) to submit your request.',
                            style: TextStyle(
                              color: Color(0xFF64748B), // Slate grey
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),

                        // Responsive form layout
                        LayoutBuilder(
                          builder: (context, constraints) {
                            // Calculate if we can use two-column layout
                            final useDoubleColumn = constraints.maxWidth > 500;

                            return useDoubleColumn
                                ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left column
                                Expanded(
                                  child: _buildLeftFormColumn(
                                    scanTypeController: scanTypeController,
                                    scanTypes: scanTypes,
                                    onScanTypeChanged: (value) {
                                      setState(() {
                                        selectedScanType = value;
                                      });
                                    },
                                    selectedScanType: selectedScanType,
                                    isLoading: isLoading,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Right column
                                Expanded(
                                  child: _buildRightFormColumn(
                                    selectedUrgency: selectedUrgency,
                                    onUrgencyChanged: (value) {
                                      setState(() {
                                        selectedUrgency = value ?? 'Normal';
                                      });
                                    },
                                    instructionsController: instructionsController,
                                  ),
                                ),
                              ],
                            )
                                : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLeftFormColumn(
                                  scanTypeController: scanTypeController,
                                  scanTypes: scanTypes,
                                  onScanTypeChanged: (value) {
                                    setState(() {
                                      selectedScanType = value;
                                    });
                                  },
                                  selectedScanType: selectedScanType,
                                  isLoading: isLoading,
                                ),
                                const SizedBox(height: 16),
                                _buildRightFormColumn(
                                  selectedUrgency: selectedUrgency,
                                  onUrgencyChanged: (value) {
                                    setState(() {
                                      selectedUrgency = value ?? 'Normal';
                                    });
                                  },
                                  instructionsController: instructionsController,
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Divider before action buttons
                const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

                // Action buttons with professional styling
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF64748B)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: isLoading ? null : () async {
                          // Validate required fields
                          if (selectedScanType == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please complete all required fields'),
                                backgroundColor: Color(0xFFDC2626),
                              ),
                            );
                            return;
                          }

                          // Find scan type name from ID
                          final scanTypeName = scanTypes
                              .firstWhere((type) => type.id == selectedScanType,
                              orElse: () => ScanType(id: '', name: 'Unknown'))
                              .name;

                          // Find team name from ID

                          // Set loading state
                          setState(() {
                            isLoading = true;
                          });

                          // Format current date
                          final dateRequested = DateFormat('yyyy-MM-dd').format(DateTime.now());

                          // Create request payload
                          final requestPayload = {
                            'patientId': _controller.patientId,
                            "testType": scanTypeName,
                            'scanTypeId': selectedScanType,
                            'urgency': selectedUrgency,
                            'instructions': instructionsController.text,
                            'dateRequested': dateRequested,
                          };

                          // Submit request to API
                          try {
                            final success = await _doctorconsultationServices.createScanRequest(requestPayload);

                            setState(() {
                              isLoading = false;
                            });

                            if (success) {
                              final newRequest = ScanRequest(
                                id: 'SRQ-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                                testType: scanTypeName,
                                testName: "",
                                urgency: selectedUrgency,
                                status: selectedUrgency == 'Urgent' ? 'Urgent' : 'Pending',
                                dateRequested: dateRequested,
                                instructions: instructionsController.text,
                              );
                              await _fetchScanRequests();
                              setState(() {
                                _hasUnsavedChanges = true;
                              });

                              _showProfessionalNotification(
                                context,
                                'Test and Scan request submitted successfully to $scanTypeName',
                                NotificationType.success,
                              );

                              Navigator.of(context).pop();
                            } else {
                              _showProfessionalNotification(
                                context,
                                'Failed to submit scan request. Please try again.',
                                NotificationType.error,
                              );
                            }
                          } catch (e) {
                            setState(() {
                              isLoading = false;
                            });

                            // Check if it's a backend error with response body
                            String errorMessage = 'An unexpected error occurred.';
                            if (e is http.Response) {
                              try {
                                final errorBody = jsonDecode(e.body);
                                errorMessage = errorBody['message'] ?? errorMessage;
                              } catch (_) {
                                errorMessage = e.body.toString();
                              }
                            } else if (e is Exception) {
                              errorMessage = e.toString();
                            }

                            _showProfessionalNotification(
                              context,
                              'Failed to submit scan request: $errorMessage',
                              NotificationType.error,
                            );
                          }

                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A365D),
                          foregroundColor: Colors.white,
                          elevation: 1,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.check_circle_outline, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Submit Request',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
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

  void _showProfessionalNotification(
      BuildContext context,
      String message,
      NotificationType type, {
        Function()? onAction,
        String actionLabel = 'VIEW',
      }) {
    Color backgroundColor;
    IconData iconData;
    switch (type) {
      case NotificationType.success:
        backgroundColor = const Color(0xFF047857);
        iconData = Icons.check_circle_outline;
        break;
      case NotificationType.error:
        backgroundColor = const Color(0xFFDC2626);
        iconData = Icons.error_outline;
        break;
      case NotificationType.info:
        backgroundColor = const Color(0xFF1E40AF);
        iconData = Icons.info_outline;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(iconData, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        action: onAction != null
            ? SnackBarAction(
          label: actionLabel,
          textColor: Colors.white,
          onPressed: onAction,
        )
            : null,
      ),
    );
  }

  Widget _buildRightFormColumn({
    required String selectedUrgency,
    required Function(String?) onUrgencyChanged,
    required TextEditingController instructionsController,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Urgency Selector
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFormLabel('Urgency', isRequired: true),
            const SizedBox(height: 6),
            _buildUrgencySelector(
              selectedUrgency: selectedUrgency,
              onChanged: onUrgencyChanged,
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Special Instructions
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFormLabel('Special Instructions', isRequired: false),
            const SizedBox(height: 6),
            TextFormField(
              controller: instructionsController,
              maxLines: 3,
              decoration: _buildInputDecoration(
                hintText: 'Any special instructions or additional information...',
                icon: Icons.note_alt_outlined,
                isRequired: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLeftFormColumn({
    required TextEditingController scanTypeController,
    required List<ScanType> scanTypes,
    required Function(String?) onScanTypeChanged,
    required String? selectedScanType,
    required bool isLoading,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Referring Team Dropdown

        const SizedBox(height: 20),
        // Scan Type Dropdown
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFormLabel('Diagnostic Request Types', isRequired: true),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: selectedScanType,
              decoration: _buildInputDecoration(
                hintText: 'Select Diagnostic type...',
                icon: Icons.medical_services_outlined,
                isRequired: true,
              ),
              isExpanded: true,
              items: isLoading
                  ? [] // Empty list while loading
                  : scanTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type.id,
                  child: Text(type.name),
                );
              }).toList(),
              onChanged: isLoading ? null : onScanTypeChanged,
            ),
          ],
        ),
      ],
    );
  }

  void _showCancelConfirmDialog(ScanRequest request) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.amber[700]),
              const SizedBox(width: 10),
              const Text('Cancel Request', style: TextStyle(fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to cancel this ${_getScanTypeName(request.testName)} request?',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Request ID: ${request.id}',
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text('Status: ${request.status}',
                        style: TextStyle(color: _getStatusColor(request.status))),
                    Text('Date Requested: ${request.dateRequested}'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'This action cannot be undone.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.red,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('No, Keep Request'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.cancel, size: 16),
              label: const Text('Yes, Cancel Request'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                _cancelScanRequest(request);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildFormLabel(String text, {required bool isRequired}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF334155),
          ),
        ),
        if (isRequired)
          const Text(
            ' *',
            style: TextStyle(
              color: Color(0xFFDC2626),
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  Widget _buildEditScanRequestDialog(ScanRequest existingRequest) {
    // Controllers pre-filled with existing data
    final TextEditingController instructionsController = TextEditingController(text: existingRequest.instructions);
    final TextEditingController scanTypeController = TextEditingController();

    // State variables initialized with existing values
    String? selectedScanType = _getScanTypeId(existingRequest.testType); // Need to convert name to ID
    String selectedUrgency = existingRequest.urgency;
    bool isLoading = true;
    List<ScanType> scanTypes = [];

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        // Fetch data when the dialog opens
        if (isLoading) {
          _fetchDialogData(setState, (fetchedTeams, fetchedScanTypes) {
            scanTypes = fetchedScanTypes;
            isLoading = false;
          });
        }

        // Get screen size for responsiveness
        final screenSize = MediaQuery.of(context).size;
        final isSmallScreen = screenSize.width < 600;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          elevation: 4,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 16 : 80,
            vertical: isSmallScreen ? 24 : 80,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 650,
              maxHeight: isSmallScreen ? screenSize.height * 0.9 : screenSize.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Professional header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A365D), // Navy blue professional color
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12.0),
                      topRight: Radius.circular(12.0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.edit_document,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Edit Diagnostic Request',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ID: ${existingRequest.id}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable content for responsiveness
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Form instruction text
                        const Padding(
                          padding: EdgeInsets.only(bottom: 20),
                          child: Text(
                            'Update the request details below.',
                            style: TextStyle(
                              color: Color(0xFF64748B), // Slate grey
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),

                        // Responsive form layout
                        LayoutBuilder(
                          builder: (context, constraints) {
                            // Calculate if we can use two-column layout
                            final useDoubleColumn = constraints.maxWidth > 500;

                            return useDoubleColumn
                                ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left column
                                Expanded(
                                  child: _buildLeftFormColumn(
                                    scanTypeController: scanTypeController,
                                    scanTypes: scanTypes,
                                    onScanTypeChanged: (value) {
                                      setState(() {
                                        selectedScanType = value;
                                      });
                                    },
                                    selectedScanType: selectedScanType,
                                    isLoading: isLoading,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Right column
                                Expanded(
                                  child: _buildRightFormColumn(
                                    selectedUrgency: selectedUrgency,
                                    onUrgencyChanged: (value) {
                                      setState(() {
                                        selectedUrgency = value ?? 'Normal';
                                      });
                                    },
                                    instructionsController: instructionsController,
                                  ),
                                ),
                              ],
                            )
                                : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLeftFormColumn(
                                  scanTypeController: scanTypeController,
                                  scanTypes: scanTypes,
                                  onScanTypeChanged: (value) {
                                    setState(() {
                                      selectedScanType = value;
                                    });
                                  },
                                  selectedScanType: selectedScanType,
                                  isLoading: isLoading,
                                ),
                                const SizedBox(height: 16),
                                _buildRightFormColumn(
                                  selectedUrgency: selectedUrgency,
                                  onUrgencyChanged: (value) {
                                    setState(() {
                                      selectedUrgency = value ?? 'Normal';
                                    });
                                  },
                                  instructionsController: instructionsController,
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Divider before action buttons
                const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

                // Action buttons with professional styling
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF64748B)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: isLoading ? null : () async {
                          // Validate required fields
                          if (selectedScanType == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please complete all required fields'),
                                backgroundColor: Color(0xFFDC2626),
                              ),
                            );
                            return;
                          }

                          // Find scan type name from ID
                          final scanTypeName = scanTypes
                              .firstWhere((type) => type.id == selectedScanType,
                              orElse: () => ScanType(id: '', name: 'Unknown'))
                              .name;

                          // Set loading state
                          setState(() {
                            isLoading = true;
                          });

                          // Create request payload
                          final requestPayload = {
                            'id': existingRequest.id,
                            'patientId': _controller.patientId,
                            "scanType": scanTypeName,
                            'scanTypeId': selectedScanType,
                            'urgency': selectedUrgency,
                            'instructions': instructionsController.text,
                            'dateRequested': existingRequest.dateRequested, // Preserve original date
                          };

                          // Submit update to API
                          final success = await _doctorconsultationServices.updateScanRequest(requestPayload);

                          // Reset loading state
                          setState(() {
                            isLoading = false;
                          });

                          if (success) {
                            // Update local representation for UI
                            final updatedRequest = ScanRequest(
                              id: existingRequest.id,
                              testType: scanTypeName,
                              testName: existingRequest.testName,
                              urgency: selectedUrgency,
                              status: existingRequest.status, // Keep existing status
                              dateRequested: existingRequest.dateRequested,
                              instructions: instructionsController.text,
                            );
                            // Refresh scan requests
                            await _fetchScanRequests();

                            // Mark changes as saved
                            setState(() {
                              _hasUnsavedChanges = true;
                            });

                            // Update in local list
                            setState(() {
                              final index = _scanRequests.indexWhere((req) => req.id == existingRequest.id);
                              if (index >= 0) {
                                _scanRequests[index] = updatedRequest;
                              }
                            });

                            // Show success notification
                            _showProfessionalNotification(
                              context,
                              'Test and scan request updated successfully',
                              NotificationType.success,
                            );

                            Navigator.of(context).pop();
                          } else {
                            // Show error notification
                            _showProfessionalNotification(
                              context,
                              'Failed to update scan request. Please try again.',
                              NotificationType.error,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A365D),
                          foregroundColor: Colors.white,
                          elevation: 1,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.save, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildUrgencySelector({
    required String selectedUrgency,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFCBD5E1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Normal option
          _buildUrgencyOption(
            label: 'Normal',
            description: 'Standard processing time (24-48 hours)',
            color: Colors.green,
            isSelected: selectedUrgency == 'Normal',
            onTap: () => onChanged('Normal'),
          ),
          // Priority option
          _buildUrgencyOption(
            label: 'Priority',
            description: 'Expedited processing (8-12 hours)',
            color: Colors.orange,
            isSelected: selectedUrgency == 'Priority',
            onTap: () => onChanged('Priority'),
            showDivider: true,
          ),
          // Urgent option
          _buildUrgencyOption(
            label: 'Urgent',
            description: 'Emergency processing (ASAP)',
            color: Colors.red,
            isSelected: selectedUrgency == 'Urgent',
            onTap: () => onChanged('Urgent'),
            showDivider: true,
          ),
        ],
      ),
    );
  }

  Future<void> _cancelScanRequest(ScanRequest request) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final success = await _doctorconsultationServices.cancelScanRequest(request.id);

      setState(() {
        _isLoading = false;
      });

      if (success) {
        // Update the local list by removing the cancelled request or changing its status
        setState(() {
          // Option 1: Remove from list
          _scanRequests.removeWhere((item) => item.id == request.id);

          // Option 2: Or update status instead of removing
          // final index = _scanRequests.indexWhere((item) => item.id == request.id);
          // if (index >= 0) {
          //   _scanRequests[index] = _scanRequests[index].copyWith(status: 'Cancelled');
          // }
        });

        _showProfessionalNotification(
          context,
          'Request cancelled successfully',
          NotificationType.success,
        );
      } else {
        _showProfessionalNotification(
          context,
          'Failed to cancel request. Please try again.',
          NotificationType.error,
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showProfessionalNotification(
        context,
        'Error: $e',
        NotificationType.error,
      );
    }
  }

  Widget _buildUrgencyOption({
    required String label,
    required String description,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
    bool showDivider = false,
  }) {
    return Column(
      children: [
        if (showDivider) const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? color : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? color : const Color(0xFFCBD5E1),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? color : const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData icon,
    required bool isRequired,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
      prefixIconConstraints: const BoxConstraints(minWidth: 42),
      suffix: isRequired
          ? const Text(
        '*',
        style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold),
      )
          : null,
      isDense: true,
    );
  }

  String? _getScanTypeId(String scanTypeName) {
    // Find the scan type ID that matches the given name
    for (final scanType in _scanTypes) {
      if (scanType.name == scanTypeName) {
        return scanType.id;
      }
    }
    return null; // Return null if not found
  }
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Requested':
        return const Color(0xFFD97706); // Professional amber
      case 'Scheduled':
        return const Color(0xFF2563EB); // Professional blue
      case 'Completed':
        return const Color(0xFF059669); // Professional green
      case 'Urgent':
        return const Color(0xFFDC2626); // Professional red
      default:
        return const Color(0xFF64748B); // Professional slate
    }
  }

  String _getScanTypeName(String scanTypeId) {
    // Try to find the scan type in the available scan types list
    try {
      // If scanTypeId is already a name (not an ID), return it as is
      if (!scanTypeId.contains('-') && !RegExp(r'^\d+$').hasMatch(scanTypeId)) {
        return scanTypeId;
      }

      // Otherwise, try to find the scan type by ID
      final scanType = _scanTypes.firstWhere(
            (type) => type.id == scanTypeId,
        orElse: () => ScanType(id: scanTypeId, name: 'Unknown Test'),
      );

      return scanType.name;
    } catch (e) {
      // Fallback to the original value if something goes wrong
      return scanTypeId;
    }
  }
  }




class ScanRequest {
  final String id;
  final String testType;
  final String testName;
  final String urgency;
  final String status;
  final String dateRequested;
  final String instructions;

  ScanRequest({
    required this.id,
    required this.testType,
    required this.testName,
    required this.urgency,
    required this.status,
    required this.dateRequested,
    this.instructions = '',
  });
  factory ScanRequest.fromJson(Map<String, dynamic> json) {
    return ScanRequest(
      id: json['_id'] ?? json['id'] ?? '',
      testType: json['scanType'] ?? '',
      testName: json['scanName'] ?? 'unknown',
      urgency: json['urgency'] ?? 'Normal',
      status: json['status'] ?? 'Pending',
      dateRequested: json['dateRequested'] ?? '',
      instructions: json['instructions'] ?? '',
    );
  }
}
enum NotificationType { success, error, info }
