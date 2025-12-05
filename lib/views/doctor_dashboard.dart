

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/api_service.dart';
import 'doctor_profile.dart';
import 'appointment_detail_screen.dart';

class DoctorDashboard extends StatefulWidget {
  @override
  _DoctorDashboardState createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  final FirebaseService _firebaseService = FirebaseService();

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<String, dynamic>? _doctorData;
  List<dynamic> _allAppointments = [];
  Map<DateTime, List<dynamic>> _appointmentsByDate = {};
  Map<DateTime, List<String>> _availableTimeSlots = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    // Check for upcoming appointments every minute
    Future.delayed(Duration(minutes: 1), _checkUpcomingAppointmentsPeriodically);
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    // Load doctor data
    final doctorResult = await _firebaseService.getUserData(_firebaseService.currentUserId!);
    if (doctorResult['success']) {
      _doctorData = doctorResult['data'];

      // Load availability from Firestore
      if (_doctorData?['availability'] != null) {
        final availability = _doctorData!['availability'] as Map<String, dynamic>;
        _availableTimeSlots.clear();
        availability.forEach((dateStr, slots) {
          try {
            final date = DateTime.parse(dateStr);
            _availableTimeSlots[_normalizeDate(date)] = List<String>.from(slots);
          } catch (e) {
            print('Error parsing availability date: $e');
          }
        });
      }
    }

    // Load appointments
    final appointmentsResult = await _firebaseService.getAppointments(
      doctorId: _firebaseService.currentUserId,
    );

    if (appointmentsResult['success']) {
      _allAppointments = appointmentsResult['data'] as List;

      // Group appointments by date
      _appointmentsByDate.clear();
      for (var apt in _allAppointments) {
        final startsAt = (apt['startsAt'] as Timestamp).toDate();
        final dateKey = _normalizeDate(startsAt);

        if (_appointmentsByDate[dateKey] == null) {
          _appointmentsByDate[dateKey] = [];
        }
        _appointmentsByDate[dateKey]!.add(apt);
      }

      // Sort appointments in each date
      _appointmentsByDate.forEach((date, appointments) {
        appointments.sort((a, b) {
          final aTime = (a['startsAt'] as Timestamp).toDate();
          final bTime = (b['startsAt'] as Timestamp).toDate();
          return aTime.compareTo(bTime);
        });
      });

      // Check for upcoming appointments
      _checkUpcomingAppointments();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  void _checkUpcomingAppointmentsPeriodically() {
    if (mounted) {
      _checkUpcomingAppointments();
      Future.delayed(Duration(minutes: 1), _checkUpcomingAppointmentsPeriodically);
    }
  }

  void _checkUpcomingAppointments() {
    final now = DateTime.now();
    final upcomingThreshold = now.add(Duration(minutes: 15));

    for (var apt in _allAppointments) {
      final startsAt = (apt['startsAt'] as Timestamp).toDate();

      // Check if appointment is within next 15 minutes
      if (startsAt.isAfter(now) && startsAt.isBefore(upcomingThreshold)) {
        _showAppointmentNotification(apt);
      }
    }
  }

  void _showAppointmentNotification(Map<String, dynamic> appointment) {
    final startsAt = (appointment['startsAt'] as Timestamp).toDate();
    final minutesUntil = startsAt.difference(DateTime.now()).inMinutes;

    if (minutesUntil > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.notifications_active, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Appointment starting in $minutesUntil ${minutesUntil == 1 ? "minute" : "minutes"}!',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          duration: Duration(seconds: 10),
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () {
              setState(() {
                _selectedDay = _normalizeDate(startsAt);
              });
            },
          ),
        ),
      );
    }
  }

  List<dynamic> _getAppointmentsForDay(DateTime day) {
    return _appointmentsByDate[_normalizeDate(day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Doctor Dashboard'),
          backgroundColor: Colors.blue.shade700,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final todayAppointments = _getAppointmentsForDay(DateTime.now());
    final selectedDayAppointments = _selectedDay != null
        ? _getAppointmentsForDay(_selectedDay!)
        : [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [

          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DoctorProfile()),
              );
            },
            tooltip: 'Profile',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Doctor Info Header
                Container(
                  padding: EdgeInsets.all(16),
                  color: Colors.blue.shade50,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.blue.shade700,
                        child: Icon(Icons.person, size: 30, color: Colors.white),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _doctorData?['fullName'] ?? 'Doctor',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            Text(
                              _doctorData?['specialty'] ?? 'General Practice',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Today's appointment count
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade700,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${todayAppointments.length} Today',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Calendar Section
                Container(
                  margin: EdgeInsets.all(16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Schedule',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _showAvailabilityDialog(_selectedDay ?? DateTime.now()),
                            icon: Icon(Icons.edit_calendar, size: 18),
                            label: Text('Set Availability'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      TableCalendar(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        calendarFormat: _calendarFormat,
                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        eventLoader: _getAppointmentsForDay,
                        startingDayOfWeek: StartingDayOfWeek.monday,
                        calendarStyle: CalendarStyle(
                          outsideDaysVisible: false,
                          selectedDecoration: BoxDecoration(
                            color: Colors.blue.shade700,
                            shape: BoxShape.circle,
                          ),
                          todayDecoration: BoxDecoration(
                            color: Colors.blue.shade300,
                            shape: BoxShape.circle,
                          ),
                          markerDecoration: BoxDecoration(
                            color: Colors.red.shade400,
                            shape: BoxShape.circle,
                          ),
                        ),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        onFormatChanged: (format) {
                          setState(() {
                            _calendarFormat = format;
                          });
                        },
                        onPageChanged: (focusedDay) {
                          _focusedDay = focusedDay;
                        },
                      ),

                      // Show appointments for selected day
                      if (_selectedDay != null && selectedDayAppointments.isNotEmpty) ...[
                        SizedBox(height: 16),
                        Divider(),
                        SizedBox(height: 8),
                        Text(
                          'Appointments for ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        SizedBox(height: 12),
                        ...selectedDayAppointments.map((apt) => _buildAppointmentCard(apt)).toList(),
                      ] else if (_selectedDay != null) ...[
                        SizedBox(height: 16),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
                              SizedBox(height: 8),
                              Text(
                                'No appointments on this day',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Show available time slots for selected day
                      if (_selectedDay != null && _availableTimeSlots[_normalizeDate(_selectedDay!)] != null) ...[
                        SizedBox(height: 16),
                        Divider(),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Your Available Times',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit, size: 20, color: Colors.green.shade700),
                              onPressed: () => _showAvailabilityDialog(_selectedDay!),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableTimeSlots[_normalizeDate(_selectedDay!)]!.map((time) {
                            return Chip(
                              label: Text(time, style: TextStyle(fontSize: 13)),
                              backgroundColor: Colors.green.shade50,
                              labelStyle: TextStyle(color: Colors.green.shade700),
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            );
                          }).toList(),
                        ),
                      ] else if (_selectedDay != null && _selectedDay!.isAfter(DateTime.now().subtract(Duration(days: 1)))) ...[
                        SizedBox(height: 16),
                        Divider(),
                        SizedBox(height: 8),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.schedule, size: 32, color: Colors.grey.shade400),
                              SizedBox(height: 8),
                              Text(
                                'No availability set for this day',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              TextButton(
                                onPressed: () => _showAvailabilityDialog(_selectedDay!),
                                child: Text('Set Availability'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Today's Appointments Summary
                if (todayAppointments.isNotEmpty) ...[
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.today, color: Colors.blue.shade700),
                            SizedBox(width: 8),
                            Text(
                              'Today\'s Appointments',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        ...todayAppointments.map((apt) => _buildAppointmentCard(apt)).toList(),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                ],

                // Upcoming appointments (next 7 days)
                _buildUpcomingAppointmentsSection(),

                SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final startsAt = (appointment['startsAt'] as Timestamp).toDate();
    final patientId = appointment['patientId'];
    final reason = appointment['reason'] ?? 'Consultation';
    final status = appointment['status'] ?? 'scheduled';
    final now = DateTime.now();
    final isUpcoming = startsAt.difference(now).inMinutes > 0 && startsAt.difference(now).inMinutes <= 15;

    return FutureBuilder<Map<String, dynamic>>(
      future: _firebaseService.getUserData(patientId),
      builder: (context, snapshot) {
        final patientName = snapshot.data?['data']?['fullName'] ?? 'Loading...';

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AppointmentDetailScreen(
                  appointmentId: appointment['id'],
                  appointmentData: appointment,
                ),
              ),
            ).then((_) => _loadDashboardData()); // Refresh after returning
          },
          child: Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUpcoming
                  ? Colors.orange.shade50
                  : (status == 'completed'
                  ? Colors.grey.shade50
                  : Colors.blue.shade50),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isUpcoming
                    ? Colors.orange.shade300
                    : (status == 'completed'
                    ? Colors.grey.shade300
                    : Colors.blue.shade200),
                width: isUpcoming ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isUpcoming ? Icons.notification_important : Icons.access_time,
                  color: isUpcoming ? Colors.orange.shade700 : Colors.blue.shade700,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  _formatTime(startsAt),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: isUpcoming ? Colors.orange.shade900 : Colors.black87,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        reason,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isUpcoming)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'SOON',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  )
                else if (status == 'completed')
                  Chip(
                    label: Text('Done', style: TextStyle(fontSize: 11)),
                    backgroundColor: Colors.green.shade100,
                    padding: EdgeInsets.zero,
                  )
                else
                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUpcomingAppointmentsSection() {
    final now = DateTime.now();
    final nextWeek = now.add(Duration(days: 7));

    final upcomingAppointments = _allAppointments.where((apt) {
      final startsAt = (apt['startsAt'] as Timestamp).toDate();
      return startsAt.isAfter(now) && startsAt.isBefore(nextWeek);
    }).toList();

    upcomingAppointments.sort((a, b) {
      final aTime = (a['startsAt'] as Timestamp).toDate();
      final bTime = (b['startsAt'] as Timestamp).toDate();
      return aTime.compareTo(bTime);
    });

    if (upcomingAppointments.isEmpty) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month, color: Colors.blue.shade700),
              SizedBox(width: 8),
              Text(
                'Upcoming This Week',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...upcomingAppointments.take(5).map((apt) {
            final startsAt = (apt['startsAt'] as Timestamp).toDate();
            return Container(
              margin: EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${startsAt.day}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        Text(
                          _getMonthName(startsAt.month),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildAppointmentCard(apt),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _showAvailabilityDialog(DateTime date) {
    final normalizedDate = _normalizeDate(date);
    final currentSlots = _availableTimeSlots[normalizedDate] ?? [];
    final selectedSlots = Set<String>.from(currentSlots);

    // Generate time slots from 8 AM to 6 PM
    final allSlots = <String>[];
    for (int hour = 8; hour < 18; hour++) {
      allSlots.add('${hour.toString().padLeft(2, '0')}:00');
      allSlots.add('${hour.toString().padLeft(2, '0')}:30');
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Set Availability\n${date.day}/${date.month}/${date.year}'),
          content: Container(
            width: double.maxFinite,
            height: 400,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        setDialogState(() {
                          selectedSlots.addAll(allSlots);
                        });
                      },
                      child: Text('Select All'),
                    ),
                    TextButton(
                      onPressed: () {
                        setDialogState(() {
                          selectedSlots.clear();
                        });
                      },
                      child: Text('Clear All'),
                    ),
                  ],
                ),
                Divider(),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: allSlots.length,
                    itemBuilder: (context, index) {
                      final slot = allSlots[index];
                      final isSelected = selectedSlots.contains(slot);

                      return CheckboxListTile(
                        title: Text(slot),
                        value: isSelected,
                        activeColor: Colors.green,
                        onChanged: (value) {
                          setDialogState(() {
                            if (value == true) {
                              selectedSlots.add(slot);
                            } else {
                              selectedSlots.remove(slot);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _saveAvailability(normalizedDate, selectedSlots.toList());
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: Text('Save Availability'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAvailability(DateTime date, List<String> slots) async {
    // Convert DateTime to string for Firestore
    final dateStr = date.toIso8601String().split('T')[0]; // YYYY-MM-DD format

    // Get current availability
    final currentAvailability = Map<String, dynamic>.from(_doctorData?['availability'] ?? {});

    if (slots.isEmpty) {
      currentAvailability.remove(dateStr);
    } else {
      // Sort slots
      slots.sort();
      currentAvailability[dateStr] = slots;
    }

    // Update in Firestore
    final result = await _firebaseService.updateUserData(
      _firebaseService.currentUserId!,
      {'availability': currentAvailability},
    );

    if (result['success']) {
      setState(() {
        if (slots.isEmpty) {
          _availableTimeSlots.remove(date);
        } else {
          _availableTimeSlots[date] = slots;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Availability saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update availability'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}