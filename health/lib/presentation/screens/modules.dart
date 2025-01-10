import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../data/datasources/modules.service.dart';

class Modules extends StatefulWidget {
  const Modules({super.key});

  @override
  State<Modules> createState() => _ModulesState();
}

class _ModulesState extends State<Modules> {
  final List<Map<String, dynamic>> _modules = [];
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _selectedImage;
  bool _isOn = false;
  bool _isLoading = false;
  String? _editingModuleId;

  @override
  void initState() {
    super.initState();
    _loadModules();
  }

  Future<void> _loadModules() async {
    setState(() => _isLoading = true);
    try {
      final modules = await ModuleService.getModules();
      setState(() {
        _modules.clear();
        _modules.addAll(modules);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading modules: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteModule(String id) async {
    try {
      await ModuleService.deleteModule(id);
      setState(() {
        _modules.removeWhere((module) => module['_id'] == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Module deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting module: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveModule() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an image')),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        // Add the new module
        final newModule = await ModuleService.addModule(
          _nameController.text,
          _descriptionController.text,
          _isOn,
          _selectedImage!,
        );

        // Update the UI
        setState(() {
          _modules.add(newModule);
          _isLoading = false;
        });

        // Close the dialog and show success message
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Module saved successfully')),
        );
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving module: $e')),
        );
      }
    }
  }

  Future<void> _saveOrUpdateModule() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedImage == null && _editingModuleId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an image')),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        if (_editingModuleId != null) {
          // Update existing module
          await ModuleService.updateModule(
            _editingModuleId!,
            _nameController.text,
            _descriptionController.text,
            _isOn,
            _selectedImage,
          );
          setState(() {
            final index = _modules.indexWhere((m) => m['_id'] == _editingModuleId);
            if (index != -1) {
              _modules[index] = {
                '_id': _editingModuleId,
                'name': _nameController.text,
                'description': _descriptionController.text,
                'status': _isOn,
                'module_image_path': _selectedImage?.path ?? _modules[index]['module_image_path'],
              };
            }
          });
        } else {
          // Add a new module
          final newModule = await ModuleService.addModule(
            _nameController.text,
            _descriptionController.text,
            _isOn,
            _selectedImage!,
          );
          setState(() {
            _modules.add(newModule);
          });
        }

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_editingModuleId != null ? 'Module updated successfully' : 'Module added successfully'),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving module: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddOrEditModuleDialog([Map<String, dynamic>? module]) {
    _editingModuleId = module?['_id'];
    _nameController.text = module?['name'] ?? '';
    _descriptionController.text = module?['description'] ?? '';
    _isOn = module?['status'] ?? false;
    _selectedImage = null;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            width: MediaQuery.of(context).size.width * 0.9,
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dialog Title
                      Text(
                        _editingModuleId != null ? 'Edit Module' : 'Add Module',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),

                      // Name Field
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(33.6),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Description Field
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(33.6),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Image Picker Section
                      Center(
                        child: ElevatedButton(
                          onPressed: () async {
                            await _pickImage();
                            setDialogState(() {});
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Pick Image'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_selectedImage != null)
                        Center(
                          child: Image.file(
                            _selectedImage!,
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(height: 20),

                      // Status Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Status'),
                          Switch(
                            value: _isOn,
                            onChanged: (value) {
                              setDialogState(() {
                                _isOn = value;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Dialog Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: _saveOrUpdateModule,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }




  void _showDeleteConfirmation(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Module'),
        content: const Text('Are you sure you want to delete this module?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteModule(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
      itemCount: _modules.length,
      itemBuilder: (context, index) {
        final module = _modules[index];
        return Card(
          color: Colors.white,
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            leading: Builder(
              builder: (context) {
                final imageUrl = ModuleService.getImageUrl(module['module_image_path']);
                print('Image URL for ${module['name']}: $imageUrl');

                return CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  child: imageUrl != null
                      ? ClipOval(
                    child: Image.network(
                      imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        print('Error loading image: $error');
                        return const Icon(Icons.image);
                      },
                    ),
                  )
                      : const Icon(Icons.image),
                );
              },
            ),
            title: Text(module['name']),
            subtitle: Text(module['description']),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.black),
                  onPressed: () => _showAddOrEditModuleDialog(module),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.black),
                  onPressed: () => _showDeleteConfirmation(module['_id']),
                ),
              ],
            ),
          ),
        );
      },
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () => _showAddOrEditModuleDialog(),
      backgroundColor: Colors.black,
      child: const Icon(Icons.add, color: Colors.white),
    ),
  );
}
}