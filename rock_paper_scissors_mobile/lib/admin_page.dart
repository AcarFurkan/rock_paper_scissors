import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rock_paper_scissors_mobile/appointment_page.dart';
import 'package:rock_paper_scissors_mobile/login_page.dart';
import 'package:rock_paper_scissors_mobile/user.dart';
import 'package:rock_paper_scissors_mobile/user_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  late final ValueNotifier<List<Event>?> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode
      .toggledOff; // Can be toggled on/off by longpressing a date
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();

    _selectedDay = _focusedDay;
    // _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    _selectedEvents = ValueNotifier(null);

    fetchFromCollection(_focusedDay);
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  List<Event> _getEventsForDay(DateTime day) {
    // Implementation example
    return kEvents[day] ?? [];
  }

  List<Event> _getEventsForDayCalendar(DateTime day) {
    // Implementation example
    kEvents[day]?.where((e) => !e.isBooked);
    return kEvents[day]?.where((e) => e.isBooked).toList() ?? [];
  }

  List<Event> _getEventsForRange(DateTime start, DateTime end) {
    // Implementation example
    final days = daysInRange(start, end);

    return [
      for (final d in days) ..._getEventsForDay(d),
    ];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _rangeStart = null; // Important to clean those
        _rangeEnd = null;
        _rangeSelectionMode = RangeSelectionMode.toggledOff;
      });

      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _selectedDay = null;
      _focusedDay = focusedDay;
      _rangeStart = start;
      _rangeEnd = end;
      _rangeSelectionMode = RangeSelectionMode.toggledOn;
    });

    // `start` or `end` could be null
    if (start != null && end != null) {
      _selectedEvents.value = _getEventsForRange(start, end);
    } else if (start != null) {
      _selectedEvents.value = _getEventsForDay(start);
    } else if (end != null) {
      _selectedEvents.value = _getEventsForDay(end);
    }
  }

  int _compareEventTimes(String timeA, String timeB) {
    // Example time format: '9:00', '10:00', ..., '17:00'
    int hourA = int.parse(timeA.split(':')[0]);
    int hourB = int.parse(timeB.split(':')[0]);

    return hourA - hourB; // Sort by hour ascending
  }

  bool loading = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Admin Paneli'),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextButton(
                  onPressed: () async {
                    await UserPreferences.removeUser();
                    Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute<void>(
                            builder: (BuildContext context) => const LoginPage()),
                        (Route<dynamic> route) => false);
                  },
                  child: Text('Cikis Yap')),
            )
          ],
        ),
        body: Column(
          children: [
            TableCalendar<Event>(
              firstDay: kFirstDay,
              lastDay: kLastDay,
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              rangeStartDay: _rangeStart,
              rangeEndDay: _rangeEnd,
              calendarFormat: _calendarFormat,
              rangeSelectionMode: _rangeSelectionMode,
              eventLoader: _getEventsForDayCalendar,
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarStyle: const CalendarStyle(
                // Use `CalendarStyle` to customize the UI
                outsideDaysVisible: false,
              ),
              onDaySelected: _onDaySelected,
              onRangeSelected: _onRangeSelected,
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                }
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
            ),
            const SizedBox(height: 8.0),
            Expanded(
              child: ValueListenableBuilder<List<Event>?>(
                valueListenable: _selectedEvents,
                builder: (context, value, _) {
                  if (value == null || loading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  value.sort((a, b) => _compareEventTimes(a.title, b.title));

                  return ListView.builder(
                    itemCount: value.length,
                    itemBuilder: (context, index) {
                      final currentEvent = value[index];
                      final user = currentEvent.user;
                      final isBooked = currentEvent.isBooked;

                      // Define decoration and onTap behavior based on booking status
                      BoxDecoration decoration = BoxDecoration(
                        border: Border.all(),
                        borderRadius: BorderRadius.circular(12.0),
                      );

                      TextStyle textStyle = TextStyle(
                          color: isBooked ? Colors.white : Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold);

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 4.0,
                        ),
                        decoration: decoration.copyWith(
                          color: isBooked
                              ? Colors.grey.shade400
                              : null, // Example: Grey out booked items
                        ),
                        child: ExpansionTile(
                          title: Text(
                            '${currentEvent.title} ${currentEvent.isBooked ? ' Rezervasyon var' : ''}',
                            style: textStyle,
                          ),
                          enabled: (currentEvent.isBooked && user != null),
                          children: user != null
                              ? [
                                  ListTile(
                                    title: Text('Isim: ${user.name}'),
                                  ),
                                  ListTile(
                                    title: Text('Telefon: ${user.phone}'),
                                  ),
                                  ListTile(
                                    title: Text('Sehir: ${user.city}'),
                                  ),
                                  ListTile(
                                    title: Text('Ilce: ${user.district}'),
                                  ),
                                ]
                              : [],
                        ),
                        // child: ListTile(
                        //   onTap: () {
                        //     ExpansionTile(
                        //       title: Text(
                        //         '${currentEvent.title} ${currentEvent.isBooked ? ' Rezervasyon var' : ''}',
                        //         style: textStyle,
                        //       ),
                        //     );
                        //     if (!isBooked) {
                        //       //showAppointmentPopup(currentEvent.title);
                        //       //print(_focusedDay);
                        //       print('${currentEvent}');
                        //     } else {
                        //       ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                        //           SnackBar(
                        //               content: Text('Bu slot rezerve edildi')));
                        //     }
                        //   },
                        //   title: Text(
                        //     '${currentEvent.title}',
                        //     style: textStyle,
                        //   ),
                        // ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ));
  }

  Future<void> fetchFromCollection(DateTime focusedDay) async {
    CollectionReference appointments =
        FirebaseFirestore.instance.collection('appointments');

    try {
      QuerySnapshot querySnapshot = await appointments.get();
      List<QueryDocumentSnapshot> docs = querySnapshot.docs;

      Map<DateTime, List<Event>> events = {};

      for (var doc in docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Parse data and update events
        data.forEach((key, value) {
          DateTime date = DateTime.parse(key);
          List<Event> eventsList = (value as Map<String, dynamic>)
              .entries
              .map((e) => Event(e.key, e.value['isBooked'] ?? false,
                  user: (e.value['isBooked'] ?? false) == true
                      ? User(
                          phone: e.value['phone'] ?? '',
                          name: e.value['name'] ?? '',
                          city: e.value['city'] ?? '',
                          district: e.value['district'] ?? '')
                      : null))
              .toList();
          events[date] = eventsList;
        });
      }

      // Update kEvents with the fetched events
      setState(() {
        kEvents.clear();
        kEvents.addAll(events);
      });
      _selectedEvents.value = _getEventsForDay(focusedDay);
      //setState(() {});
    } catch (e) {
      print("Failed to fetch appointments: $e");
    }
  }
}
