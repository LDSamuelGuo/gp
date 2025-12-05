
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HealthRecordsScreen extends StatefulWidget {
  @override
  _HealthRecordsScreenState createState() => _HealthRecordsScreenState();
}

class _HealthRecordsScreenState extends State<HealthRecordsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<dynamic> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);

    final result = await _firebaseService.getHealthRecords();

    if (result['success']) {
      setState(() {
        _records = result['data'];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${result['error']}')),
        );
      }
    }
  }

  Future<void> _createRecord() async {
    // Show dialog to create record
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedType = 'general';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('New Health Record'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: 'Title'),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: InputDecoration(labelText: 'Type'),
                  items: [
                    DropdownMenuItem(value: 'general', child: Text('General')),
                    DropdownMenuItem(value: 'consultation', child: Text('Consultation')),
                    DropdownMenuItem(value: 'test', child: Text('Test')),
                    DropdownMenuItem(value: 'prescription', child: Text('Prescription')),
                    DropdownMenuItem(value: 'therapy', child: Text('Therapy')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedType = value ?? 'general';
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Title is required')),
                  );
                  return;
                }

                final createResult = await _firebaseService.createHealthRecord(
                  patientId: _firebaseService.currentUserId!,
                  title: titleController.text,
                  description: descController.text,
                  type: selectedType,
                  tags: [selectedType],
                );
                Navigator.pop(context, createResult['success']);
              },
              child: Text('Create'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      _loadRecords(); // Reload records
    }
  }

  Future<void> _deleteRecord(String recordId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Record'),
        content: Text('Are you sure you want to delete this record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await _firebaseService.deleteHealthRecord(recordId);
      if (result['success']) {
        _loadRecords();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Record deleted')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${result['error']}')),
          );
        }
      }
    }
  }

  String _getTypeIcon(String? type) {
    switch (type) {
      case 'consultation':
        return '🩺';
      case 'test':
        return '🔬';
      case 'prescription':
        return '💊';
      case 'therapy':
        return '🏥';
      default:
        return '📄';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Health Records'),
        backgroundColor: Color(0xFF1877F2),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _createRecord,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadRecords,
        child: _records.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.folder_open, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No health records yet',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _createRecord,
                icon: Icon(Icons.add),
                label: Text('Add First Record'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1877F2),
                ),
              ),
            ],
          ),
        )
            : ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: _records.length,
          itemBuilder: (context, index) {
            final record = _records[index];
            final type = record['type'] as String?;
            return Card(
              margin: EdgeInsets.only(bottom: 12),
              elevation: 2,
              child: ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Color(0xFF1877F2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      _getTypeIcon(type),
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                title: Text(
                  record['title'] ?? 'Untitled',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    Text(record['description'] ?? ''),
                    SizedBox(height: 4),
                    if (type != null)
                      Chip(
                        label: Text(
                          type.toUpperCase(),
                          style: TextStyle(fontSize: 10),
                        ),
                        backgroundColor: Color(0xFF1877F2).withOpacity(0.1),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteRecord(record['id']),
                ),
                isThreeLine: true,
              ),
            );
          },
        ),
      ),
    );
  }
}
