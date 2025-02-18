import 'package:flutter/material.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:intl/intl.dart';
import '../controller/appointments.controller.dart';

class ManageAppointments extends StatefulWidget {
  const ManageAppointments({Key? key}) : super(key: key);

  @override
  _ManageAppointmentsState createState() => _ManageAppointmentsState();
}

class _ManageAppointmentsState extends State<ManageAppointments> {
  final AppointmentsController controller = AppointmentsController();
  bool isLoading = false;
  String? selectedStatus;
  DateTime? selectedDate;
  List<Map<String, dynamic>> appointments = [];

  @override
  void initState() {
    super.initState();
    controller.addListener(_controllerListener);
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
        isLoading = controller.isLoading;
      });
    }
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

  Future<void> _updateStatus(String appointmentId, String currentStatus) async {
    final statuses = ['scheduled', 'confirmed', 'completed', 'cancelled', 'no-show'];
    final String? newStatus = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Update Status'),
        children: statuses
            .where((status) => status != currentStatus)
            .map((status) => SimpleDialogOption(
          onPressed: () => Navigator.pop(context, status),
          child: Text(status.toUpperCase()),
        ))
            .toList(),
      ),
    );

    if (newStatus != null) {
      setState(() => isLoading = true);
      try {
        await controller.updateAppointmentStatus(
          appointmentId: appointmentId,
          status: newStatus,
        );
        await _loadAppointments();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Status updated to ${newStatus.toUpperCase()}')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _deleteAppointment(String appointmentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => isLoading = true);
      try {
        await controller.deleteAppointment(appointmentId);
        await _loadAppointments();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Appointment deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      } finally {
        setState(() => isLoading = false);
      }
    }
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

  Widget _buildStatusFilterDropdown() {
    final statuses = ['scheduled', 'confirmed', 'completed', 'cancelled'];
    return DropdownButton<String>(
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
  void navigateToScreen(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            navigateToScreen(Start());
          },
        ),
        title: const Text('Manage Appointments'),
        actions: [
          _buildStatusFilterDropdown(),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAppointments,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
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
      ),
    );
  }
}

class AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final Function(String, String) onStatusUpdate;
  final Function(String) onDelete;

  const AppointmentCard({
    Key? key,
    required this.appointment,
    required this.onStatusUpdate,
    required this.onDelete,
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
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => onStatusUpdate(
                        appointment['id'],
                        appointment['status'],
                      ),
                      tooltip: 'Update Status',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => onDelete(appointment['id']),
                      tooltip: 'Delete Appointment',
                      color: Colors.red,
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
/*
Widget _buildAdminControls() {
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
}*/
