import 'dart:convert';
import 'package:flutter/material.dart';
import '../../data/models/realm/faceimage_realm_model.dart';
import '../../data/models/user.dart';
import '../../data/services/userImage_service.dart';

class PatientListItem extends StatefulWidget {
  final User patient;
  final TabController tabController;
  final Function(User) onPatientSelected;

  const PatientListItem({
    Key? key,
    required this.patient,
    required this.tabController,
    required this.onPatientSelected,
  }) : super(key: key);

  @override
  State<PatientListItem> createState() => _PatientListItemState();
}

class _PatientListItemState extends State<PatientListItem> {
  final ImageServices _imageServices = ImageServices();
  ImageRealm? userImage;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _initializeServicesAndLoadProfilepatient();
  }

  Future<void> _initializeServicesAndLoadProfilepatient() async {
    try {
      await _imageServices.initialize();
      await _loadImage();
    } catch (e) {
      print("Initialization error: $e");
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    }
  }

  Future<void> _loadImage() async {
    try {
      // First try to get from local Realm
      ImageRealm? image = _imageServices.getUserImage(widget.patient.id ?? '');

      // If not found locally, try MongoDB backup
      if (image == null) {
        image = await _imageServices.getUserImageWithMongoBackup(widget.patient.id ?? '');
      }

      if (mounted) {
        setState(() {
          userImage = image;
          _loading = false;
        });
      }
    } catch (e) {
      print("Error loading image: $e");
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    }
  }

  String _getInitials() {
    if (widget.patient.name?.isNotEmpty == true) {
      final nameParts = widget.patient.name!.trim().split(' ');
      if (nameParts.length > 1) {
        return '${nameParts.first[0]}${nameParts.last[0]}'.toUpperCase();
      }
      return widget.patient.name![0].toUpperCase();
    }
    return 'P';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          widget.onPatientSelected(widget.patient);
          widget.tabController.animateTo(1);
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              _buildPatientAvatar(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.patient.name ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF0A2463),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildPatientInfo('Aadhaar', widget.patient.aadhaarNumber),
                    const SizedBox(height: 2),
                    _buildPatientInfo('Phone', widget.patient.phoneNumber),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.blueAccent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientInfo(String label, String? value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value ?? 'Not available',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPatientAvatar() {
    return GestureDetector(
      onTap: () {
        if (userImage != null) {
          _showFullImageDialog();
        }
      },
      child: Hero(
        tag: 'patient_image_${widget.patient.id}',
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.blue.shade200,
              width: 2,
            ),
          ),
          child: CircleAvatar(
            backgroundColor: Colors.blue.shade500,
            radius: 28,
            backgroundImage: userImage != null
                ? MemoryImage(base64Decode(userImage!.base64Image))
                : null,
            child: _loading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : userImage == null
                ? Text(
              _getInitials(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            )
                : null,
          ),
        ),
      ),
    );
  }

  void _showFullImageDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Hero(
                tag: 'patient_image_${widget.patient.id}',
                child: Image.memory(
                  base64Decode(userImage!.base64Image),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                widget.patient.name ?? 'Unknown',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}