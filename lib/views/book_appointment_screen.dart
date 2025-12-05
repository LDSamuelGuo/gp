

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/api_service.dart';

class BookAppointmentScreen extends StatefulWidget {
  final String? preSelectedDoctorId;

  const BookAppointmentScreen({Key? key, this.preSelectedDoctorId})
      : super(key: key);

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  DateTime? _selectedDate;
  String? _selectedTime;
  String? _selectedDoctorId;
  Map<String, dynamic>? _selectedDoctor;

  List<dynamic> _doctors = [];
  List<String> _availableSlots = [];
  bool _isLoadingDoctors = true;
  bool _isLoadingSlots = false;

  final TextEditingController _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDoctorId = widget.preSelectedDoctorId;
    _loadDoctors();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    setState(() => _isLoadingDoctors = true);

    final result = await _firebaseService.getAllDoctors();
    if (!mounted) return;

    if (result['success'] == true) {
      final list = (result['data'] as List).cast<Map<String, dynamic>>();
      setState(() {
        _doctors = list;
        _isLoadingDoctors = false;

        if (_selectedDoctorId != null) {
          _selectedDoctor = list.firstWhere(
                (d) => d['id'] == _selectedDoctorId,
            orElse: () => {},
          );
          if (_selectedDoctor!.isEmpty) _selectedDoctor = null;
        }
      });
    } else {
      setState(() => _isLoadingDoctors = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading doctors: ${result['error']}')),
      );
    }
  }

  Future<void> _loadAvailableSlots() async {
    if (_selectedDate == null || _selectedDoctorId == null) return;

    setState(() {
      _isLoadingSlots = true;
      _availableSlots = [];
      _selectedTime = null;
    });

    // Load the doc’s per-date availability map
    final doctorRes = await _firebaseService.getUserData(_selectedDoctorId!);
    if (!mounted) return;

    if (doctorRes['success'] != true) {
      setState(() => _isLoadingSlots = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading doctor availability')),
      );
      return;
    }

    final data = (doctorRes['data'] as Map<String, dynamic>);
    final availability = data['availability'] as Map<String, dynamic>?;

    if (availability == null || availability.isEmpty) {
      setState(() => _isLoadingSlots = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('This doctor has not set availability yet'),
          backgroundColor: Colors.orange.shade700,
        ),
      );
      return;
    }

    final dateStr =
        '${_selectedDate!.year.toString().padLeft(4, '0')}-'
        '${_selectedDate!.month.toString().padLeft(2, '0')}-'
        '${_selectedDate!.day.toString().padLeft(2, '0')}';

    final slotsForDate = (availability[dateStr] as List?)?.cast<String>() ?? [];

    // Collect booked slots for the same day
    final apptRes =
    await _firebaseService.getAppointments(doctorId: _selectedDoctorId);
    if (!mounted) return;

    final booked = <String>[];
    if (apptRes['success'] == true) {
      final appts = (apptRes['data'] as List).cast<Map<String, dynamic>>();
      for (final apt in appts) {
        final ts = apt['startsAt'];
        if (ts is Timestamp) {
          final dt = ts.toDate();
          if (dt.year == _selectedDate!.year &&
              dt.month == _selectedDate!.month &&
              dt.day == _selectedDate!.day) {
            final hh = dt.hour.toString().padLeft(2, '0');
            final mm = dt.minute.toString().padLeft(2, '0');
            booked.add('$hh:$mm');
          }
        }
      }
    }

    final available = slotsForDate.where((s) => !booked.contains(s)).toList();

    setState(() {
      _availableSlots = available;
      _isLoadingSlots = false;
    });

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('All slots are booked for this date'),
          backgroundColor: Colors.orange.shade700,
        ),
      );
    }
  }

  Future<void> _bookAppointment() async {
    if (_selectedDoctorId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select a doctor')));
      return;
    }
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select a date')));
      return;
    }
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select a time')));
      return;
    }

    final parts = _selectedTime!.split(':');
    final startsAt = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
    final endsAt = startsAt.add(const Duration(minutes: 30));

    // Loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final res = await _firebaseService.createAppointment(
      doctorId: _selectedDoctorId!,
      startsAt: startsAt,
      endsAt: endsAt,
      reason: _reasonController.text.isEmpty
          ? 'General Consultation'
          : _reasonController.text,
      type: 'consultation',
    );

    if (!mounted) return;
    Navigator.pop(context); // close loader

    if (res['success'] == true) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Success!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your appointment has been booked.'),
              const SizedBox(height: 12),
              Text(
                  'Date: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
              Text('Time: $_selectedTime'),
              Text('Doctor: ${_selectedDoctor?['fullName'] ?? 'Doctor'}'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style:
              ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
          Text('Error booking appointment: ${res['error'] ?? 'unknown'}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _doctorCards() {
    if (_doctors.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('No doctors available'),
      );
    }

    return Column(
      children: _doctors.map<Widget>((doctor) {
        final isSelected = _selectedDoctorId == doctor['id'];
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDoctorId = doctor['id'] as String?;
              _selectedDoctor = doctor;
              _availableSlots = [];
              _selectedTime = null;
            });
            if (_selectedDate != null) _loadAvailableSlots();
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              color: isSelected ? Colors.blue.shade50 : Colors.white,
            ),
            child: Row(
              children: [
                const CircleAvatar(radius: 24, child: Icon(Icons.person)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor['fullName'] ?? 'Doctor',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        doctor['specialty'] ?? 'General Practice',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: Colors.blue),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoadingDoctors
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Doctor selection (cards)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Doctor',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _doctorCards(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Calendar
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Date',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TableCalendar(
                      firstDay: DateTime.now(),
                      lastDay: DateTime.now().add(const Duration(days: 90)),
                      focusedDay: _selectedDate ?? DateTime.now(),
                      selectedDayPredicate: (d) =>
                          isSameDay(_selectedDate, d),
                      onDaySelected: (selected, focused) {
                        setState(() => _selectedDate = selected);
                        _loadAvailableSlots();
                      },
                      calendarFormat: CalendarFormat.month,
                      calendarStyle: CalendarStyle(
                        selectedDecoration: BoxDecoration(
                          color: Colors.blue.shade700,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: Colors.blue.shade300,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Slots
            if (_isLoadingSlots)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_availableSlots.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.access_time, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Available Times',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableSlots.map((time) {
                          final selected = _selectedTime == time;
                          return ChoiceChip(
                            label: Text(time),
                            selected: selected,
                            selectedColor: Colors.blue.shade700,
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : Colors.black87,
                              fontWeight:
                              selected ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (_) {
                              setState(() => _selectedTime = time);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              )
            else if (_selectedDate != null && _selectedDoctorId != null)
                Card(
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No available slots for this date. Please select another date.',
                            style: TextStyle(color: Colors.orange.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

            const SizedBox(height: 16),

            // Reason
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reason for Visit (Optional)',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _reasonController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'e.g., Annual checkup, Follow-up...',
                        contentPadding: EdgeInsets.all(12),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Book
            ElevatedButton(
              onPressed: _selectedTime != null ? _bookAppointment : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: const Text(
                'Book Appointment',
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
