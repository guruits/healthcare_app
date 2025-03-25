import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:intl/intl.dart';
import '../../data/datasources/user.service.dart';
import '../controller/appointments.controller.dart';
import '../widgets/language.widgets.dart';

class Appointments extends StatefulWidget {
  const Appointments({Key? key}) : super(key: key);

  @override
  State<Appointments> createState() => _AppointmentsState();
}

class _AppointmentsState extends State<Appointments> {
  final AppointmentsController controller = AppointmentsController();
  final UserImageService _imageService = UserImageService();
  bool isLoading = false;
  bool isDoctorSelected = false;
  String? selectedStatus;
  DateTime? selectedDate;
  List<Map<String, dynamic>> appointments = [];
  bool showAppointments = false;



  @override
  void initState() {
    super.initState();
    controller.addListener(_controllerListener);
    // Initialize data
    _initializeData();
    _loadAppointments();
  }

  @override
  void dispose() {
    controller.removeListener(_controllerListener);
    super.dispose();
  }
  void _controllerListener() {
    if (mounted) {
      setState(() {
        // Ensure UI updates when controller notifies
        isLoading = controller.isLoading;
      });
    }
  }
  Future<void> _initializeData() async {
    setState(() => isLoading = true);
    await controller.fetchDoctors();
    setState(() => isLoading = false);
  }
  void _debugPrintTimeSlots() {
    print("Current timeSlots in UI: ${controller.timeSlots}");
    print("Selected doctor: ${controller.selectedDoctorId}");
    print("Selected date: ${controller.selectedDate}");
    print("Is on leave: ${controller.isOnLeave}");
  }
  Future<void> _loadAppointments() async {
    setState(() => isLoading = true);
    try {
      final List<Appointment> result = await controller.getAppointments(
        status: selectedStatus,
        date: selectedDate,
      );

      setState(() => appointments = result.map((appointment) => {
        'id': appointment.id,
        'patientName': appointment.patientName,
        'doctorName': appointment.doctorName,
        'date': appointment.date.toIso8601String(),
        'timeSlot': appointment.timeSlot,
        'status': appointment.status,
        'patientContact': appointment.patientContact,
        'createdAt': appointment.createdAt.toIso8601String(),
      }).toList());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading appointments: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }


  Widget _buildStatusFilterDropdown() {
    final statuses = ['scheduled', 'confirmed', 'completed', 'cancelled'];
    return DropdownButton<String>(
      dropdownColor: Colors.white,
      value: selectedStatus,
      hint: Text('Filter Status'),
      items: [
        DropdownMenuItem(value: null, child: Text('All Statuses')),

        ...statuses.map((status) =>
            DropdownMenuItem(value: status, child: Text(status.toUpperCase()))
        ).toList(),
      ],
      onChanged: (status) {
        setState(() {
          selectedStatus = status;
          _loadAppointments();
        });
      },
    );
  }


  Future<void> _updateStatus(String appointmentId, String currentStatus) async {
    try {
      final statuses = ['scheduled', 'confirmed', 'completed', 'cancelled', 'no-show'];
      final String? newStatus = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Update Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: statuses
                .where((status) => status != currentStatus)
                .map((status) => ListTile(
              title: Text(status.toUpperCase()),
              onTap: () => Navigator.pop(context, status),
            ))
                .toList(),
          ),
        ),
      );

      if (newStatus != null && mounted) {
        setState(() => isLoading = true);

        await controller.updateAppointmentStatus(
          appointmentId: appointmentId,
          status: newStatus,
        );

        // Refresh appointments list after status update
        await _loadAppointments();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Status updated to ${newStatus.toUpperCase()}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }
  Future<void> _deleteAppointment(String appointmentId) async {
    try {
      // First check if user has permission to delete
     /* if (controller.userRole != 'Admin' && controller.userRole != 'Doctor') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Only administrators and doctors can delete appointments'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }*/

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this appointment? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('DELETE', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        setState(() => isLoading = true);

        final success = await controller.deleteAppointment(appointmentId);

        if (success && mounted) {
          await _loadAppointments();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appointment deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  /*Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final bool isAdminOrDoctor = controller.userRole == 'Admin' || controller.userRole == 'Doctor';
    final bool isCompleted = appointment['status'].toString().toUpperCase() == 'COMPLETED';
    final bool canBook = _canBookAppointment(appointment);

    return AppointmentCard(
      appointment: appointment,
      onStatusUpdate: isAdminOrDoctor ? _updateStatus : null,
      onDelete: isAdminOrDoctor ? _deleteAppointment : null,
      showControls: isAdminOrDoctor && !isCompleted,
      canBook: canBook,
    );
  }*/

  bool _canBookAppointment(Map<String, dynamic> appointment) {
    if (appointment['status'] == 'completed') {
      return false;
    }
    return true;
  }



  Future<void> _showFilterDialog() async {
  final DateTime? date = await showDatePicker(
      context: context,
       initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
       lastDate: DateTime(2025),
     );

     if (date != null) {
       setState(() {
        selectedDate = date;
       });
       await _loadAppointments();
     }
  }

  Widget _buildDoctorList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.doctors.isEmpty) {
      return const Center(child: Text('No doctors available'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.doctors.length,
      itemBuilder: (context, index) {
        final doctor = controller.doctors[index];
        final doctorId = doctor['_id'] ?? doctor['id'];
        final isSelected = doctorId != null && controller.selectedDoctorId == doctorId;

        if (doctorId == null) {
          return const SizedBox.shrink();
        }

        return FutureBuilder<bool>(
          future: UserImageService().checkImageExists(doctorId),
          builder: (context, snapshot) {
            final hasImage = snapshot.data ?? false;
            final imageUrl = UserImageService().getUserImageUrl(doctorId);

            return Card(
              elevation:  4,
              color: isSelected ? Colors.blue[50] : Colors.white,
              margin: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: hasImage ? NetworkImage(imageUrl) : null,
                  child: hasImage ? null : Icon(Icons.person, color: Colors.grey[400]),
                ),
                title: Text(doctor['name'] ?? 'Unknown Doctor'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doctor['title'] ?? ''),
                    Text(doctor['department'] ?? ''),
                  ],
                ),
                selected: isSelected,
                onTap: () async {
                  setState(() {
                    isLoading = true;
                    // Clear previously selected doctor if a new one is selected
                    if (controller.selectedDoctorId != doctorId) {
                      controller.selectedDoctorId = doctorId;
                    } else {
                      controller.selectedDoctorId = null; // Deselect the doctor if the same doctor is tapped
                    }
                    isDoctorSelected = controller.selectedDoctorId != null;
                  });

                  if (controller.selectedDoctorId != null) {
                    if (controller.selectedDate != null) {
                      await controller.fetchDoctorTimeSlots(doctorId);
                    } else {
                      controller.setSelectedDate(DateTime.now());
                    }
                  }

                  setState(() => isLoading = false);
                },
              ),
            );
          },
        );
      },
    );
  }



  Widget _buildDateScroller() {
    if (controller.selectedDoctorId == null) return const SizedBox.shrink();

    final dates = List.generate(
      30,
          (index) => DateTime.now().add(Duration(days: index)),
    );

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = controller.selectedDate?.day == date.day &&
              controller.selectedDate?.month == date.month;

          return GestureDetector(
            onTap: () {
              controller.setSelectedDate(date);
            },
            onDoubleTap: () => _showEditSlotsDialog(),
            child: Container(
              width: 80,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black38 : Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(date),
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                    ),
                  ),
                  Text(
                    DateFormat('MMM d').format(date),
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeSlots() {
    //_debugPrintTimeSlots(); // Add this debug print

    if (controller.selectedDoctorId == null) {
      return const Center(
        child: Text('Please select the doctor'),
      );
    }

    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.timeSlots.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No time slots available for this date',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }


    if (controller.timeSlots.isEmpty) {
      return const Center(
        child: Text('No time slots available for this date'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Available Slots Title
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Text(
            'Available Time Slots',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Time Slots Grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: controller.timeSlots.length,
            itemBuilder: (context, index) {
              final slot = controller.timeSlots[index];
              final isSelected = controller.selectedTimeSlot == slot;
              final isAvailable = slot['isAvailable'] == true && slot['availableSlots'] > 0;

              return InkWell(
                onTap: isAvailable ? () {
                  controller.setSelectedTimeSlot(slot);
                } : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : (isAvailable ? Colors.black : Colors.grey[300]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${slot['startTime']} ',
                        style: TextStyle(
                          color: isAvailable ? Colors.white : Colors.black54,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${slot['availableSlots']}/${slot['maxPatients']}',
                        style: TextStyle(
                          color: isAvailable ? Colors.white70 : Colors.black45,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Confirm Button
        if (controller.selectedTimeSlot != null && !controller.isOnLeave)
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: ElevatedButton(
                onPressed: _confirmAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)?.confirm_appointment ?? 'Confirm Appointment',
                ),
              ),
            ),
          ),
      ],
    );
  }
  Widget _buildAdminControls() {
    if (!controller.canModifySlots()) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.event_busy),
            label: const Text('Mark Leave'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _showLeaveDialog(),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.edit_calendar),
            label: const Text('Edit Slots'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _showEditSlotsDialog(),
          ),
        ],
      ),
    );
  }


  Color _getSlotColor(bool isSelected, bool isAvailable) {
    if (isSelected) return Colors.blue.shade100;
    if (!isAvailable) return Colors.grey.shade200;
    return Colors.white;
  }

  Future<void> _showLeaveDialog() async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (selectedDate != null && mounted) {
      // Check current leave status for the selected date
      final isCurrentlyOnLeave = await controller.checkDoctorLeaveStatus(
        doctorId: controller.selectedDoctorId!,
        date: selectedDate,
      );

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(isCurrentlyOnLeave ? 'Remove Leave' : 'Mark Leave'),
          content: Text(
              isCurrentlyOnLeave
                  ? 'Remove leave for ${DateFormat('MMM dd, yyyy').format(selectedDate)}?'
                  : 'Mark leave for ${DateFormat('MMM dd, yyyy').format(selectedDate)}?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(isCurrentlyOnLeave ? 'Remove' : 'Confirm'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final success = await controller.leaveDoctor(
          isOnLeave: !isCurrentlyOnLeave,
          leaveDate: selectedDate,
          doctorId: controller.selectedDoctorId!,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  isCurrentlyOnLeave
                      ? 'Leave removed successfully'
                      : 'Leave marked successfully'
              ),
            ),
          );
          // Refresh the time slots
          await controller.fetchDoctorTimeSlots(controller.selectedDoctorId!);
        }
      }
    }
  }
  Future<void> _showEditSlotsDialog() async {
    if (!controller.canModifySlots()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unauthorized to modify slots')),
      );
      return;
    }

    List<Map<String, dynamic>> castTimeSlots = controller.timeSlots.map((dynamic item) {
      return Map<String, dynamic>.from(item);
    }).toList();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Time Slots'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: castTimeSlots.map((slot) {
                return ListTile(
                  title: Text('${slot['startTime']}'),
                  subtitle: Text('Max Patients: ${slot['maxPatients']}'),
                  trailing: Switch(
                    value: slot['isAvailable'] ?? true,
                    onChanged: (bool value) async {
                      Navigator.pop(context);
                      await _toggleSlotAvailability(slot, value);
                      if (controller.selectedDoctorId != null) {
                        await controller.fetchDoctorTimeSlots(controller.selectedDoctorId!);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }


  Future<void> _toggleSlotAvailability(Map<String, dynamic> slot, bool isAvailable) async {
    try {
      if (controller.selectedDoctorId == null || controller.selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a doctor and date')),
        );
        return;
      }

      // Create a new list of slots with the updated availability
      List<Map<String, dynamic>> updatedSlots = controller.timeSlots.map((dynamic s) {
        final Map<String, dynamic> slotMap = Map<String, dynamic>.from(s);
        if (slotMap['startTime'] == slot['startTime']) {
          slotMap['isAvailable'] = isAvailable; // Use the passed isAvailable parameter
        }
        return slotMap;
      }).toList();

      final success = await controller.updateTimeSlots(
          updatedSlots,
          doctorId: controller.selectedDoctorId!,
          date: controller.selectedDate!,
          slots: updatedSlots
      );

      if (success) {
        await controller.fetchDoctorTimeSlots(controller.selectedDoctorId!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isAvailable ? 'Slot enabled successfully' : 'Slot disabled successfully'),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(controller.error ?? 'Failed to update slot')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _confirmAppointment() async {
    if (!controller.canBookAppointment()) return;

    setState(() => isLoading = true);
    final appointmentResponse = await controller.bookAppointment();
    setState(() => isLoading = false);

    if (appointmentResponse != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)?.appointment_confirmed ?? 'Appointment Confirmed'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Appointment ID: ${appointmentResponse['_id']}'),
                Text('Doctor: ${controller.getSelectedDoctorName()}'),
                Text('Date: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(appointmentResponse['date']))}'),
                Text('Time: ${appointmentResponse['timeSlot']}'),
                Text('Status: ${appointmentResponse['status'].toUpperCase()}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Reset and go back to doctor selection
                  setState(() {
                    isDoctorSelected = false;
                    controller.resetSelection();
                  });
                },
                child: Text(AppLocalizations.of(context)?.ok ?? 'OK'),
              ),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.error ?? 'Failed to book appointment'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void navigateToScreen(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),color: Colors.white,
          onPressed: () {
            if (isDoctorSelected) {
              setState(() {
                isDoctorSelected = false;
                controller.selectedDoctorId = null;
                controller.selectedDate = null;
                controller.selectedTimeSlot = null;
              });
            } else {
              navigateToScreen(Start());
            }
          },
        ),
        title: Text(
          isDoctorSelected
              ? controller.getSelectedDoctorName()
              : AppLocalizations.of(context)?.book_appointment ?? 'Book Appointment',
               style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        actions: [
          _buildStatusFilterDropdown(),
          if (controller.canModifySlots())
            const LanguageToggle(),
          IconButton(
            icon: const Icon(Icons.refresh) ,color: Colors.white,
            onPressed: _loadAppointments,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!isDoctorSelected) _buildDoctorList(),
            if (isDoctorSelected) ...[
              _buildAdminControls(),
              const SizedBox(height: 50),
              _buildDateScroller(),
              const SizedBox(height: 50),
              _buildTimeSlots(),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  showAppointments = !showAppointments;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                showAppointments ? 'Hide Appointments' : 'Show Appointments',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            if (showAppointments) ...[
              if (appointments.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final appointment = appointments[index];
                    return AppointmentCard(
                      appointment: {
                        'id': appointment['id'],
                        'patientName': appointment['patientName'],
                        'doctorName': appointment['doctorName'],
                        'date': appointment['date'],
                        'timeSlot': appointment['timeSlot'],
                        'status': appointment['status'],
                        'patientContact': appointment['patientContact'],
                        'createdAt': appointment['createdAt'],
                      },
                      onStatusUpdate: _updateStatus,
                      onDelete: _deleteAppointment,
                    );
                  },
                )
              else
                const Center(child: Text('No appointments found')),
            ],
          ],
        ),
      ),
    );
  }
}
class AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final Function(String, String) onStatusUpdate;
  final Function(String) onDelete;
  final bool showControls;
  final bool canBook;

  const AppointmentCard({
    Key? key,
    required this.appointment,
    required this.onStatusUpdate,
    required this.onDelete,
    this.showControls = true,
    this.canBook = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final status = appointment['status'].toString().toUpperCase();
    final Color statusColor = _getStatusColor(status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment['patientName'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dr. ${appointment['doctorName']}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('MMM dd, yyyy').format(
                            DateTime.parse(appointment['date']),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(appointment['timeSlot']),
                      ],
                    ),
                    if (!canBook)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'This appointment slot is not available',
                          style: TextStyle(
                            color: Colors.red,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
                Row(
                  children: [
                    if (showControls) Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (onStatusUpdate != null)
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => onStatusUpdate!(
                              appointment['id'],
                              appointment['status'],
                            ),
                            tooltip: 'Update Status',
                          ),
                        if (onDelete != null)
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => onDelete!(appointment['id']),
                            tooltip: 'Delete Appointment',
                            color: Colors.red,
                          ),
                      ],
                    ),

                    if (!canBook)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'This appointment slot is not available',
                          style: TextStyle(
                            color: Colors.red,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'SCHEDULED':
        return Colors.blue;
      case 'CONFIRMED':
        return Colors.green;
      case 'COMPLETED':
        return Colors.purple;
      case 'CANCELLED':
        return Colors.red;
      case 'NO-SHOW':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}