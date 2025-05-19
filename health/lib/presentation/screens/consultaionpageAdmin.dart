import 'package:flutter/material.dart';

import '../../data/datasources/doctorconsultation_services.dart';

class ConsultaionAdmin extends StatefulWidget {
  const ConsultaionAdmin({Key? key}) : super(key: key);

  @override
  State<ConsultaionAdmin> createState() => _ConsultaionAdminState();
}

class _ConsultaionAdminState extends State<ConsultaionAdmin> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = false;
  String errorMessage = '';
  DoctorconsultationServices _doctorconsultationServices = DoctorconsultationServices();
  List<ReferringTeam> _referringTeams = [];

  int _scanTypesRefreshCounter = 0;
  int _teamsRefreshCounter = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReferringTeams();
  }

  // Load referring teams for dropdown selection
  Future<void> _loadReferringTeams() async {
    try {
      final teams = await _doctorconsultationServices.fetchReferringTeams();
      setState(() {
        _referringTeams = teams;
      });
    } catch (e) {
      print('Error loading referring teams: $e');
    }
  }

  // Trigger refresh of scan types list
  void _refreshScanTypes() {
    setState(() {
      _scanTypesRefreshCounter++;
    });
  }

  // Trigger refresh of referring teams list
  void _refreshTeams() {
    setState(() {
      _teamsRefreshCounter++;
      _loadReferringTeams(); // Reload teams data for dropdown
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Custom TabBar
        Container(
          color: Theme.of(context).dividerColor,
          child: Theme(
            data: Theme.of(context).copyWith(
              tabBarTheme: TabBarTheme(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
              ),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Test and Scan Types', icon: Icon(Icons.medical_services)),
                Tab(text: 'Referring Teams', icon: Icon(Icons.people)),
              ],
            ),
          ),
        ),

        // Expanded TabBarView to take remaining space
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              buildScanTypesTab(),
              buildReferringTeamsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildAdminForm() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildScanReportsCard(),
            ],
          ),
        ),
      ),
    );
  }

  // Scan Types Tab
  Widget buildScanTypesTab() {
    return buildCrudPanel<ScanType>(
      key: ValueKey('scan_types_$_scanTypesRefreshCounter'), // Add key for refresh
      title: 'Test and Scan Types',
      fetchFunction: _doctorconsultationServices.fetchScanTypes,
      addFunction: showAddScanTypeDialog,
      editFunction: (item) => showEditScanTypeDialog(item),
      deleteFunction: (id) async {
        await _doctorconsultationServices.deleteScanType(id);
        _refreshScanTypes(); // Refresh after delete
      },
      itemBuilder: (item) => buildScanTypeItem(item),
    );
  }

  // Referring Teams Tab
  Widget buildReferringTeamsTab() {
    return buildCrudPanel<ReferringTeam>(
      key: ValueKey('referring_teams_$_teamsRefreshCounter'), // Add key for refresh
      title: 'Referring Teams',
      fetchFunction: _doctorconsultationServices.fetchReferringTeams,
      addFunction: showAddReferringTeamDialog,
      editFunction: (item) => showEditReferringTeamDialog(item),
      deleteFunction: (id) async {
        await _doctorconsultationServices.deleteReferringTeam(id);
        _refreshTeams(); // Refresh after delete
      },
      itemBuilder: (item) => buildReferringTeamItem(item),
    );
  }

  // Generic CRUD Panel
  Widget buildCrudPanel<T>({
    Key? key,
    required String title,
    required Future<List<T>> Function() fetchFunction,
    required Function() addFunction,
    required Function(T) editFunction,
    required Function(String) deleteFunction,
    required Widget Function(T) itemBuilder,
  }) {
    return FutureBuilder<List<T>>(
      key: key, // Use the key to force rebuild
      future: fetchFunction(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          print("Error for flutter:${snapshot.error}");
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('No $title found'),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: addFunction,
                  child: Text('Add New $title'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: addFunction,
                    icon: const Icon(Icons.add),
                    label: const Text('Add New'),
                  ),
                ],
              ),
            ),
            if (errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  if (T == ScanType) {
                    _refreshScanTypes();
                  } else if (T == ReferringTeam) {
                    _refreshTeams();
                  }
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final item = snapshot.data![index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: Column(
                        children: [
                          itemBuilder(item),
                          ButtonBar(
                            alignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => editFunction(item),
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  String id = '';
                                  String name = '';

                                  // Get the id and name based on the type
                                  if (item is ScanType) {
                                    id = item.id;
                                    name = item.name;
                                  } else if (item is ReferringTeam) {
                                    id = item.id;
                                    name = item.name;
                                  }

                                  showDeleteConfirmationDialog(
                                    context: context,
                                    itemName: name,
                                    onDelete: () => deleteFunction(id),
                                  );
                                },
                                tooltip: 'Delete',
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Scan Type Item
  Widget buildScanTypeItem(ScanType scanType) {
    // Find referring team name by ID
    String referringTeamName = 'None';
    if (scanType.referringTeamId != null && scanType.referringTeamId!.isNotEmpty) {
      final team = _referringTeams.firstWhere(
            (team) => team.id == scanType.referringTeamId,
        orElse: () => ReferringTeam(id: '', name: 'Unknown', department: ''),
      );
      referringTeamName = team.name;
    }

    return ListTile(
      title: Text(scanType.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (scanType.description != null && scanType.description!.isNotEmpty)
            Text('Description: ${scanType.description}'),
          if (scanType.averageDuration != null)
            Text('Duration: ${scanType.averageDuration} minutes'),
          Text('Referring Team: $referringTeamName'),
        ],
      ),
      isThreeLine: true,
    );
  }

  // Referring Team Item
  Widget buildReferringTeamItem(ReferringTeam team) {
    return ListTile(
      title: Text(team.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Department: ${team.department}'),
          if (team.contactPerson != null && team.contactPerson!.isNotEmpty)
            Text('Contact: ${team.contactPerson}'),
          if (team.contactEmail != null && team.contactEmail!.isNotEmpty)
            Text('Email: ${team.contactEmail}'),
        ],
      ),
      isThreeLine: true,
    );
  }

  // Dialog functions for Scan Types
  void showAddScanTypeDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController prepInstructionsController = TextEditingController();
    final TextEditingController durationController = TextEditingController();

    // Default to no team selected
    String? selectedReferringTeamId;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Add New Scan Type'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name *',
                          hintText: 'Enter scan type name',
                        ),
                      ),
                      TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Enter description',
                        ),
                      ),
                      TextField(
                        controller: prepInstructionsController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Preparation Instructions',
                          hintText: 'Enter preparation instructions',
                        ),
                      ),
                      TextField(
                        controller: durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Average Duration (minutes)',
                          hintText: 'Enter duration in minutes',
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Referring Team',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedReferringTeamId,
                        hint: const Text('Select a referring team'),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('None'),
                          ),
                          ..._referringTeams.map((team) {
                            return DropdownMenuItem<String>(
                              value: team.id,
                              child: Text('${team.name} (${team.department})'),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedReferringTeamId = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Name is required')),
                        );
                        return;
                      }

                      final data = ScanType(
                        id: '', // This will be assigned by the backend
                        name: nameController.text.trim(),
                        description: descriptionController.text.trim(),
                        prepInstructions: prepInstructionsController.text.trim(),
                        averageDuration: durationController.text.isNotEmpty
                            ? int.tryParse(durationController.text.trim())
                            : null,
                        referringTeamId: selectedReferringTeamId,
                      );

                      Navigator.of(context).pop();
                      await _doctorconsultationServices.createScanType(data);
                      // Refresh the list after creation
                      _refreshScanTypes();
                    },
                    child: const Text('Save'),
                  ),
                ],
              );
            }
        );
      },
    );
  }

  void showEditScanTypeDialog(ScanType scanType) {
    final TextEditingController nameController = TextEditingController(text: scanType.name);
    final TextEditingController descriptionController = TextEditingController(text: scanType.description ?? '');
    final TextEditingController prepInstructionsController = TextEditingController(text: scanType.prepInstructions ?? '');
    final TextEditingController durationController = TextEditingController(
        text: scanType.averageDuration != null ? scanType.averageDuration.toString() : '');

    // Initialize with current referring team
    String? selectedReferringTeamId = scanType.referringTeamId;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Edit Scan Type'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name *',
                          hintText: 'Enter scan type name',
                        ),
                      ),
                      TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Enter description',
                        ),
                      ),
                      TextField(
                        controller: prepInstructionsController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Preparation Instructions',
                          hintText: 'Enter preparation instructions',
                        ),
                      ),
                      TextField(
                        controller: durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Average Duration (minutes)',
                          hintText: 'Enter duration in minutes',
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Referring Team',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedReferringTeamId,
                        hint: const Text('Select a referring team'),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('None'),
                          ),
                          ..._referringTeams.map((team) {
                            return DropdownMenuItem<String>(
                              value: team.id,
                              child: Text('${team.name} (${team.department})'),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedReferringTeamId = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Name is required')),
                        );
                        return;
                      }

                      final data = ScanType(
                        id: scanType.id,
                        name: nameController.text.trim(),
                        description: descriptionController.text.trim(),
                        prepInstructions: prepInstructionsController.text.trim(),
                        averageDuration: durationController.text.isNotEmpty
                            ? int.tryParse(durationController.text.trim())
                            : null,
                        referringTeamId: selectedReferringTeamId,
                      );

                      Navigator.of(context).pop();
                      await _doctorconsultationServices.updateScanType(scanType.id, data);
                      // Refresh the list after update
                      _refreshScanTypes();
                    },
                    child: const Text('Update'),
                  ),
                ],
              );
            }
        );
      },
    );
  }

  // Dialog functions for Referring Teams
  void showAddReferringTeamDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController departmentController = TextEditingController();
    final TextEditingController contactPersonController = TextEditingController();
    final TextEditingController contactEmailController = TextEditingController();
    final TextEditingController contactPhoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Referring Team'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Team Name *',
                    hintText: 'Enter team name',
                  ),
                ),
                TextField(
                  controller: departmentController,
                  decoration: const InputDecoration(
                    labelText: 'Department *',
                    hintText: 'Enter department',
                  ),
                ),
                TextField(
                  controller: contactPersonController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Person',
                    hintText: 'Enter contact person name',
                  ),
                ),
                TextField(
                  controller: contactEmailController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Email',
                    hintText: 'Enter contact email',
                  ),
                ),
                TextField(
                  controller: contactPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Phone',
                    hintText: 'Enter contact phone',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty || departmentController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Team name and department are required')),
                  );
                  return;
                }

                final data = ReferringTeam(
                  id: '', // This will be assigned by the backend
                  name: nameController.text.trim(),
                  department: departmentController.text.trim(),
                  contactPerson: contactPersonController.text.trim(),
                  contactEmail: contactEmailController.text.trim(),
                  contactPhone: contactPhoneController.text.trim(),
                );

                Navigator.of(context).pop();
                await _doctorconsultationServices.createReferringTeam(data);
                // Refresh the teams list after creation
                _refreshTeams();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void showEditReferringTeamDialog(ReferringTeam team) {
    final TextEditingController nameController = TextEditingController(text: team.name);
    final TextEditingController departmentController = TextEditingController(text: team.department);
    final TextEditingController contactPersonController = TextEditingController(text: team.contactPerson ?? '');
    final TextEditingController contactEmailController = TextEditingController(text: team.contactEmail ?? '');
    final TextEditingController contactPhoneController = TextEditingController(text: team.contactPhone ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Referring Team'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Team Name *',
                    hintText: 'Enter team name',
                  ),
                ),
                TextField(
                  controller: departmentController,
                  decoration: const InputDecoration(
                    labelText: 'Department *',
                    hintText: 'Enter department',
                  ),
                ),
                TextField(
                  controller: contactPersonController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Person',
                    hintText: 'Enter contact person name',
                  ),
                ),
                TextField(
                  controller: contactEmailController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Email',
                    hintText: 'Enter contact email',
                  ),
                ),
                TextField(
                  controller: contactPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Phone',
                    hintText: 'Enter contact phone',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty || departmentController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Team name and department are required')),
                  );
                  return;
                }

                final data = ReferringTeam(
                  id: team.id,
                  name: nameController.text.trim(),
                  department: departmentController.text.trim(),
                  contactPerson: contactPersonController.text.trim(),
                  contactEmail: contactEmailController.text.trim(),
                  contactPhone: contactPhoneController.text.trim(),
                );

                Navigator.of(context).pop();
                await _doctorconsultationServices.updateReferringTeam(team.id, data);
                // Refresh the teams list after update
                _refreshTeams();
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  // Common Functions
  void showDeleteConfirmationDialog({
    required BuildContext context,
    required String itemName,
    required Function onDelete,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete "$itemName"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.of(context).pop();
                onDelete();
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // Placeholder for buildScanReportsCard
  Widget buildScanReportsCard() {
    return const Card(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Scan Reports Dashboard (Admin View)'),
      ),
    );
  }
}

// lib/data/models/scan_type.dart
class ScanType {
  final String id;
  final String name;
  final String? description;
  final String? prepInstructions;
  final int? averageDuration;
  final String? referringTeamId;

  ScanType({
    required this.id,
    required this.name,
    this.description,
    this.prepInstructions,
    this.averageDuration,
    this.referringTeamId,
  });

  factory ScanType.fromJson(Map<String, dynamic> json) {
    return ScanType(
      id: json['_id'],
      name: json['name'],
      description: json['description'],
      prepInstructions: json['prepInstructions'],
      averageDuration: json['averageDuration'] is String
          ? int.tryParse(json['averageDuration'])
          : json['averageDuration'],
      referringTeamId: json['referringTeamId'], // Added parsing for referring team ID
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'prepInstructions': prepInstructions,
      'averageDuration': averageDuration,
      'referringTeamId': referringTeamId, // Added referring team ID to JSON
    };
  }
}

// lib/data/models/referring_team.dart
class ReferringTeam {
  final String id;
  final String name;
  final String department;
  final String? contactPerson;
  final String? contactEmail;
  final String? contactPhone;

  ReferringTeam({
    required this.id,
    required this.name,
    required this.department,
    this.contactPerson,
    this.contactEmail,
    this.contactPhone,
  });

  factory ReferringTeam.fromJson(Map<String, dynamic> json) {
    return ReferringTeam(
      id: json['_id'],
      name: json['name'],
      department: json['department'],
      contactPerson: json['contactPerson'],
      contactEmail: json['contactEmail'],
      contactPhone: json['contactPhone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'department': department,
      'contactPerson': contactPerson,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
    };
  }
}