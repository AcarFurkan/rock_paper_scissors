import 'dart:collection';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rock_paper_scissors_mobile/user.dart';
import 'package:rock_paper_scissors_mobile/user_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

class AppointmentPage extends StatefulWidget {
  AppointmentPage({super.key});

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
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
    return kEvents[day]?.where((e) => !e.isBooked).toList() ?? [];
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
  showAppointmentPopup(String time) {
    DateTime selectedDay = _selectedDay ?? _focusedDay;
    String dateFormat = DateFormat('dd/MM/yyyy').format(selectedDay);

    // String currentDate =
    //     '${selectedDay.day.toString().padLeft(2, '0')}/${selectedDay.month.toString().padLeft(2, '0')}/${selectedDay.year}';
    DateFormat.EEEE().format(selectedDay);

    AwesomeDialog(
      context: context,
      dialogType: DialogType.info,
      animType: AnimType.rightSlide,
      title: 'Randevuyu Oluştur',
      desc:
          ' ${dateFormat} ${DateFormat.EEEE().format(selectedDay)} $time bu tarihte randevuyu almayi onayliyor musunuz?',
      btnCancelOnPress: () {},
      btnOkOnPress: () {
        makeAppointment(time);
      },
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    int currentYear = DateTime.now().year;
    int currentMonth = DateTime.now().month + 3;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Randevu Sistemi'),
      ),
      // floatingActionButton: Column(
      //   mainAxisAlignment: MainAxisAlignment.end,
      //   children: [
      //     FloatingActionButton(
      //       heroTag: 'aboo',
      //       onPressed: () => setToCollection(currentYear, currentMonth),
      //       child: const Icon(Icons.add),
      //     ),
      //   ],
      // ),
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
                      child: ListTile(
                        onTap: () {
                          if (!isBooked) {
                            showAppointmentPopup(currentEvent.title);
                            print(_focusedDay);
                            print('${currentEvent}');
                          } else {
                            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                                SnackBar(
                                    content: Text('Bu slot rezerve edildi')));
                          }
                        },
                        title: Text(
                          '${currentEvent.title}',
                          style: textStyle,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> initializeMonthSchedule(int year, int month) {
    Map<String, dynamic> monthSchedule = {};
    int daysInMonth = DateTime(year, month + 1, 0).day;

    for (int day = 1; day <= daysInMonth; day++) {
      String dateKey = DateTime(year, month, day)
          .toString()
          .split(' ')[0]; // yyyy-MM-dd formatında tarih
      monthSchedule[dateKey] = generateDaySchedule();
    }

    return monthSchedule;
  }

  setToCollection(int year, int month) {
    CollectionReference appointments =
        FirebaseFirestore.instance.collection('appointments');
    String monthKey =
        "${year}-${month.toString().padLeft(2, '0')}"; // yyyy-MM formatında

    appointments
        .doc(monthKey)
        .set(initializeMonthSchedule(year, month))
        .then((value) => print("$monthKey appointment list Added"))
        .catchError((error) =>
            print("Failed to add $monthKey appointment list: $error"));
  }

  Map<String, Map<String, dynamic>> generateDaySchedule() {
    List<int> hours = List.generate(9, (index) => index + 9); // 9 AM to 5 PM
    Map<String, Map<String, dynamic>> dailySchedule = {};

    for (int hour in hours) {
      dailySchedule['$hour:00'] = {'isBooked': false, 'phone': null};
    }

    return dailySchedule;
  }

  // fetchFromCollection() async {
  //   CollectionReference appointments =
  //       FirebaseFirestore.instance.collection('appointments');

  //   try {
  //     QuerySnapshot querySnapshot = await appointments.get();
  //     List<QueryDocumentSnapshot> docs = querySnapshot.docs;

  //     for (var doc in docs) {
  //       print(doc.id); // Doküman ID'si
  //       print(doc.data()); // Doküman verileri
  //     }
  //   } catch (e) {
  //     print("Failed to fetch appointments: $e");
  //   }
  // }

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
              .map((e) => Event(e.key, e.value['isBooked'] ?? false))
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

  Future<void> makeAppointment(String timeSlot) async {
    try {
      setState(() {
        loading = true;
      });
      DateTime selectedDay = _selectedDay ?? _focusedDay;
      CollectionReference appointments =
          FirebaseFirestore.instance.collection('appointments');
      // Construct the document ID for the selected day (yyyy-MM-dd format)
      String docId =
          '${_focusedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}';
      print(docId);
      print(timeSlot.padLeft(2, '0'));
      // if (timeSlot.length == 4) {
      //   timeSlot = '0$timeSlot'; // Add leading zero if hour is single digit
      // }
      print(timeSlot);
      // Get the document reference
      DocumentReference docRef = appointments.doc(docId);

      // Update the document
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(docRef);
        if (snapshot.exists) {
          // Update the document data here as needed
          // For example, mark a specific time slot as booked
          // Assume you have a method to determine which time slot to book, like `bookTimeSlot`
          //String timeSlot = '9:00'; // Example time slot
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          String dayRef =
              '${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.day.toString().padLeft(2, '0')}';

          print(data);
          print(data.keys.first.runtimeType);

          print('------');
          print(data[dayRef].containsKey(timeSlot));
          print(data[dayRef].containsKey(timeSlot));
          if (data[dayRef].containsKey(timeSlot)) {
            data[dayRef][timeSlot]['isBooked'] = true;
            data[dayRef][timeSlot]['phone'] =
                '+1234567890'; // Example phone number
          }
          final user = await getLocalUser();
          if (data[dayRef][timeSlot] is Map && user != null) {
            (data[dayRef][timeSlot] as Map).addAll(user.toMap());
          }
          // Update the document
          transaction.update(docRef, data);
        }
      });

      // After updating, fetch all appointments again
      await fetchFromCollection(selectedDay);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text('Randevunuz Olusturulmustur ')));
      setState(() {
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
      print("Failed to make appointment: $e");
    }
  }

  Future<User?> getLocalUser() async {
    try {
      return await UserPreferences.getUser();
    } catch (e) {
      return null;
    }
  }
}

class DaySchedule {
  bool isBooked;
  String? phone;
  DaySchedule(this.isBooked, {this.phone});

  Map<String, dynamic> toMap() {
    return {'isBooked': isBooked, 'phone': phone};
  }

  factory DaySchedule.fromMap(Map<String, dynamic> map) {
    return DaySchedule(map['isBooked'] ?? false, phone: map['phone']);
  }

  @override
  String toString() {
    return 'DaySchedule{isBooked=$isBooked, phone=$phone}';
  }
}
// Copyright 2019 Aleksander Woźniak
// SPDX-License-Identifier: Apache-2.0

/// Example event class.
class Event {
  final String title;
  final bool isBooked;
  final User? user;

  const Event(this.title, this.isBooked, {this.user});

  @override
  String toString() {
    return 'Event{title=$title, isBooked=$isBooked}';
  }
}

/// Example events.
///
/// Using a [LinkedHashMap] is highly recommended if you decide to use a map.
final kEvents = LinkedHashMap<DateTime, List<Event>>(
  equals: isSameDay,
  hashCode: getHashCode,
);

int getHashCode(DateTime key) {
  return key.day * 1000000 + key.month * 10000 + key.year;
}

/// Returns a list of [DateTime] objects from [first] to [last], inclusive.
List<DateTime> daysInRange(DateTime first, DateTime last) {
  final dayCount = last.difference(first).inDays + 1;
  return List.generate(
    dayCount,
    (index) => DateTime.utc(first.year, first.month, first.day + index),
  );
}

final kToday = DateTime.now();
final kFirstDay = DateTime(kToday.year, kToday.month, kToday.day);
final kLastDay = DateTime(kToday.year, kToday.month + 4, kToday.day);
