
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../data/datasources/role.service.dart';
import '../../data/datasources/screen.service.dart';
import '../../data/models/permission.dart';
import '../../data/models/role.dart';
import '../../data/models/screen.dart';

class RolesScreen extends StatefulWidget {
  const RolesScreen({Key? key}) : super(key: key);

  @override
  State<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends State<RolesScreen> {
  List<Role> roles = [];
  List<Screen> availableScreens = [];
  bool isLoading = true;
  String? error;
  final RoleService roleService = RoleService();
  final ScreenService screenService = ScreenService();

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // Load both roles and screens in parallel
      final Future<List<Role>> rolesFuture = roleService.getAllRoles();
      final Future<List<Screen>> screensFuture = screenService.getAllScreens();

      final results = await Future.wait([rolesFuture, screensFuture]);

      setState(() {
        roles = results[0] as List<Role>;
        availableScreens = results[1] as List<Screen>;
        isLoading = false;
      });

      print("Loaded ${roles.length} roles and ${availableScreens.length} screens");
      if (roles.isNotEmpty) {
        print("First role has ${roles[0].permissions.length} permissions");
        for (var perm in roles[0].permissions) {
          print("Permission: ${perm.screen} -> C:${perm.create}, R:${perm.read}, U:${perm.update}, D:${perm.delete}");
        }
      }
    } catch (e) {
      print("Error in loadInitialData: $e");
      setState(() {
        error = e.toString();
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> loadRoles() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final fetchedRoles = await roleService.getAllRoles();

      setState(() {
        roles = fetchedRoles;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading roles: $e')),
        );
      }
    }
  }

  Future<void> _showEditPermissionsDialog(Role role) async {
    print("Role permissions count: ${role.permissions.length}");
    for (var perm in role.permissions) {
      print("Permission: screen=${perm.screen}, create=${perm.create}, read=${perm.read}");
    }

    print("Available screens count: ${availableScreens.length}");
    for (var screen in availableScreens) {
      print("Screen: id=${screen.id}, name=${screen.name}");
    }
    List<Permission> editedPermissions = role.permissions.map((p) {
      return Permission(
        screen: p.screen,
        create: p.create,
        read: p.read,
        update: p.update,
        delete: p.delete,
      );
    }).toList();

    print("Initial Role Permissions for ${role.name}:");
    for (var perm in editedPermissions) {
      print("${perm.screen} -> C: ${perm.create}, R: ${perm.read}, U: ${perm.update}, D: ${perm.delete}");
    }

    Set<String> currentScreenNames = editedPermissions.map((p) => p.screen).toSet();

    print("Available Screens: $availableScreens");

    // Add missing screens with default permissions
    for (var screen in availableScreens) {
      if (!currentScreenNames.contains(screen.name)) {
        editedPermissions.add(Permission(
          screen: screen.name,
          create: false,
          read: false,
          update: false,
          delete: false,
        ));
      }
    }

    print("Final Permissions List Before Dialog Opens:");
    for (var perm in editedPermissions) {
      print("${perm.screen} -> C: ${perm.create}, R: ${perm.read}, U: ${perm.update}, D: ${perm.delete}");
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Edit ${role.name} Permissions'),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 10,
                        dataRowHeight: 50,
                        columns: const [
                          DataColumn(label: Text('Screen', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('CREATE', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('READ', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('UPDATE', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('DELETE', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: editedPermissions.map((permission) {
                          final screen = availableScreens.firstWhere(
                                (s) => s.id == permission.screen,
                            orElse: () => Screen(id: permission.screen, name: permission.screen, description: ''),
                          );

                          return DataRow(
                            cells: [
                              DataCell(Text(screen.name, style: const TextStyle(fontSize: 12))),
                              DataCell(
                                Checkbox(
                                  value: permission.create,
                                  activeColor: Colors.black,
                                  onChanged: (value) {
                                    setState(() {
                                      permission.create = value ?? false;
                                    });
                                    print("Updated ${permission.screen} -> C: ${permission.create}");
                                  },
                                ),
                              ),
                              DataCell(
                                Checkbox(
                                  value: permission.read,
                                  activeColor: Colors.black,
                                  onChanged: (value) {
                                    setState(() {
                                      permission.read = value ?? false;
                                    });
                                    print("Updated ${permission.screen} -> R: ${permission.read}");
                                  },
                                ),
                              ),
                              DataCell(
                                Checkbox(
                                  value: permission.update,
                                  activeColor: Colors.black,
                                  onChanged: (value) {
                                    setState(() {
                                      permission.update = value ?? false;
                                    });
                                    print("Updated ${permission.screen} -> U: ${permission.update}");
                                  },
                                ),
                              ),
                              DataCell(
                                Checkbox(
                                  value: permission.delete,
                                  activeColor: Colors.black,
                                  onChanged: (value) {
                                    setState(() {
                                      permission.delete = value ?? false;
                                    });
                                    print("Updated ${permission.screen} -> D: ${permission.delete}");
                                  },
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.grey,
              ),
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.black,
              ),
              child: const Text('Save'),
              onPressed: () async {
                print("Saving Updated Permissions:");
                for (var perm in editedPermissions) {
                  print("${perm.screen} -> C: ${perm.create}, R: ${perm.read}, U: ${perm.update}, D: ${perm.delete}");
                }

                try {
                  await roleService.updateRolePermissions(
                    role.id!,
                    editedPermissions,
                  );
                  Navigator.pop(context);
                  loadInitialData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Permissions updated successfully')),
                    );
                  }
                } catch (e) {
                  print('Error updating permissions: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating permissions: $e')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Role Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: () => _showAddRoleDialog(),
          ),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $error'),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              onPressed: loadRoles,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: roles.length,
        itemBuilder: (context, index) {
          final role = roles[index];
          return Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 4,
              horizontal: 8,
            ),
            child: Slidable(
              key: ValueKey(role.id),
              endActionPane: ActionPane(
                motion: const ScrollMotion(),
                extentRatio: 0.15,
                children: [
                  SlidableAction(
                    onPressed: (_) => _showEditPermissionsDialog(role),
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    icon: Icons.edit,
                    label: 'Edit',
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(16),
                      right: Radius.circular(0),
                    ),
                  ),
                ],
              ),
              startActionPane: ActionPane(
                motion: const ScrollMotion(),
                extentRatio: 0.15,
                children: [
                  SlidableAction(
                    onPressed: (_) => _confirmDeactivateRole(role),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    icon: Icons.delete,
                    label: 'Delete',
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(0),
                      right: Radius.circular(16),
                    ),
                  ),
                ],
              ),
              child: Card(
                elevation: 2,
                color: Colors.white,
                child: ExpansionTile(
                  title: Text(
                    role.name,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    role.description ?? '',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  children: [
                    _buildPermissionsTable(role.permissions),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRoleDialog(),
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }


  Widget _buildPermissionsTable(List<Permission> permissions) {
    // First, sort permissions by screen name for better readability
    final sortedPermissions = List<Permission>.from(permissions)
      ..sort((a, b) => a.screen.compareTo(b.screen));

   Map<String, String> screenIdToName = {};
    for (var screen in availableScreens) {
      screenIdToName[screen.id] = screen.name;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(
            label: Text(
              'Screen',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Create',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Read',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Update',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
        rows: sortedPermissions.map((permission) {
          String screenName =  screenIdToName[permission.screen] ?? permission.screen;
          return DataRow(cells: [
            DataCell(Text(screenName)),
            DataCell(Icon(
              permission.create ? Icons.check : Icons.close,
              color: permission.create ? Colors.black : Colors.red,
            )),
            DataCell(Icon(
              permission.read ? Icons.check : Icons.close,
              color: permission.read ? Colors.black : Colors.red,
            )),
            DataCell(Icon(
              permission.update ? Icons.check : Icons.close,
              color: permission.update ? Colors.black : Colors.red,
            )),
            DataCell(Icon(
              permission.delete ? Icons.check : Icons.close,
              color: permission.delete ? Colors.black : Colors.red,
            )),
          ]);
        }).toList(),
      ),
    );
  }


  Future<void> _showAddRoleDialog() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    Map<String, Permission> permissions = {};

    // Initialize permissions for each available screen
    for (Screen screen in availableScreens) {
      permissions[screen.name] = Permission(
        screen: screen.name,
        create: false,
        read: false,
        update: false,
        delete: false,
      );
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Add New Role',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Container(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Role Name',
                      labelStyle: TextStyle(color: Colors.black),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      labelStyle: TextStyle(color: Colors.black),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Permissions',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DataTable(
                    columnSpacing: 20,
                    headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Screen',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(label: Text('CREATE')),
                      DataColumn(label: Text('READ')),
                      DataColumn(label: Text('UPDATE')),
                      DataColumn(label: Text('DELETE')),
                    ],
                    rows: availableScreens.map((screen) {
                      return DataRow(
                        cells: [
                          DataCell(Text(screen.name)),
                          DataCell(
                            Checkbox(
                              value: permissions[screen.name]!.create,
                              activeColor: Colors.black,
                              onChanged: (value) {
                                setState(() {
                                  permissions[screen.name]!.create = value ?? false;
                                });
                              },
                            ),
                          ),
                          DataCell(
                            Checkbox(
                              value: permissions[screen.name]!.read,
                              activeColor: Colors.black,
                              onChanged: (value) {
                                setState(() {
                                  permissions[screen.name]!.read = value ?? false;
                                });
                              },
                            ),
                          ),
                          DataCell(
                            Checkbox(
                              value: permissions[screen.name]!.update,
                              activeColor: Colors.black,
                              onChanged: (value) {
                                setState(() {
                                  permissions[screen.name]!.update = value ?? false;
                                });
                              },
                            ),
                          ),
                          DataCell(
                            Checkbox(
                              value: permissions[screen.name]!.delete,
                              activeColor: Colors.black,
                              onChanged: (value) {
                                setState(() {
                                  permissions[screen.name]!.delete = value ?? false;
                                });
                              },
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              child: const Text('Create'),
              onPressed: () async {
                try {
                  final permissionsList = permissions.values
                      .where((permission) => permission.hasAnyPermission())
                      .toList();

                  final newRole = Role(
                    name: nameController.text,
                    description: descController.text,
                    permissions: permissionsList,
                  );

                  await roleService.createRole(newRole);
                  Navigator.pop(context);
                  loadInitialData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Role created successfully'),
                        backgroundColor: Colors.black,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error creating role: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }




  Future<void> _confirmDeactivateRole(Role role) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deactivation'),
        content: Text('Are you sure you want to deactivate ${role.name}?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text('Deactivate'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await roleService.deactivateRole(role.id!);
        loadRoles();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Role deactivated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deactivating role: $e')),
          );
        }
      }
    }
  }
}