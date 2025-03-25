import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../data/datasources/screen.service.dart';
import '../../data/models/screen.dart';

class ScreensScreen extends StatefulWidget {
  const ScreensScreen({super.key});

  @override
  State<ScreensScreen> createState() => _ScreensScreenState();
}

class _ScreensScreenState extends State<ScreensScreen> {
  final List<Screen> _screens = [];
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ScreenService _screenService = ScreenService();
  bool _isLoading = false;
  String? _editingScreenId;

  @override
  void initState() {
    super.initState();
    _loadScreens();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadScreens() async {
    setState(() => _isLoading = true);
    try {
      final screens = await _screenService.getAllScreens();
      setState(() {
        _screens.clear();
        _screens.addAll(screens);
      });
    } catch (e) {
      _showErrorSnackBar('Error loading screens: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade400,
      ),
    );
  }

  Future<void> _deactivateScreen(String id) async {
    try {
      await _screenService.deactivateScreen(id);
      await _loadScreens(); // Reload screens after deactivation
      _showSuccessSnackBar('Screen deactivated successfully');
    } catch (e) {
      _showErrorSnackBar('Error deactivating screen: $e');
    }
  }

  Future<void> _saveOrUpdateScreen() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        // Trim the input values
        String name = _nameController.text.trim();
        String description = _descriptionController.text.trim();

        if (_editingScreenId != null) {
          // Create a Screen object for update
          final screenToUpdate = Screen(
            id: _editingScreenId!,
            name: name,
            description: description,
            isActive: true,
          );

          await _screenService.updateScreen(_editingScreenId!, screenToUpdate);
        } else {
          // Create a new Screen object
          final newScreen = Screen(
            id: '',
            name: name,
            description: description,
            isActive: true,
          );

          await _screenService.createScreen(newScreen);
        }

        await _loadScreens();

        if (mounted) {
          Navigator.pop(context);
          _showSuccessSnackBar(
            _editingScreenId != null
                ? 'Screen updated successfully'
                : 'Screen added successfully',
          );
        }
      } catch (e) {
        print("Error saving screen: $e");
        _showErrorSnackBar('Error saving screen: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddOrEditScreenDialog([Screen? screen]) {
    _editingScreenId = screen?.id;
    _nameController.text = screen?.name ?? '';
    _descriptionController.text = screen?.description ?? '';

    showDialog(
      context: context,
      builder: (context) =>
          Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              width: MediaQuery
                  .of(context)
                  .size
                  .width * 0.9,
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _editingScreenId != null ? 'Edit Screen' : 'Add Screen',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
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
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 24,
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: _saveOrUpdateScreen,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 24,
                              ),
                            ),
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  void _showDeactivateConfirmation(String id) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Deactivate Screen'),
            content: const Text(
                'Are you sure you want to deactivate this screen?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deactivateScreen(id);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Deactivate'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Screen Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _screens.length,
        itemBuilder: (context, index) {
          final screen = _screens[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Slidable(
              key: ValueKey(screen.id),
              // Left slide action (Edit)
              endActionPane: ActionPane(
                motion: const ScrollMotion(),
                extentRatio: 0.15,
                children: [
                  SlidableAction(
                    onPressed: (_) => _showAddOrEditScreenDialog(screen),
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
              // Right slide action (Delete)
              startActionPane: ActionPane(
                motion: const ScrollMotion(),
                extentRatio: 0.15,
                children: [
                  SlidableAction(
                    onPressed: (_) => _showDeactivateConfirmation(screen.id),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.black,
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
                color: Colors.white,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                elevation: 2,
                child: ListTile(
                  title: Text(
                    screen.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    screen.description,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOrEditScreenDialog(),
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}