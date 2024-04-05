import 'package:InternHeroes/features/user_auth/presentation/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/addpost.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/knowledgeresourcepage.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/userlistpage.dart';
import 'package:InternHeroes/features/user_auth/presentation/widgets/bottom_navbar.dart';
import 'event_list.dart'; // Import the event_list.dart file

void main() {
  runApp(Calendar());
}

class Calendar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Calendar',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.yellow,
          backgroundColor: Colors.white,
        ).copyWith(
          primary: Colors.yellow[800],
        ),
        useMaterial3: true,
      ),
      home: CalendarPage(title: 'Calendar'),
    );
  }
}

class CalendarPage extends StatefulWidget {
  final String title;

  CalendarPage({required this.title});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class Event {
  final String id;
  final String eventName;
  final String eventDescription;
  final DateTime eventDateTime;
  final String createdBy;
  final bool isPublic;

  Event(this.id, this.eventName, this.eventDescription, this.eventDateTime, this.createdBy, this.isPublic);

  @override
  String toString() {
    return eventName;
  }
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _selectedDay;
  late Map<DateTime, List<Event>> _events;
  late TextEditingController _eventController;
  late ValueNotifier<List<Event>> _selectedEvents;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _events = {};
    _eventController = TextEditingController();
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay));
    _loadEvents(); // Load events on init
  }

  @override
  void dispose() {
    _eventController.dispose();
    _selectedEvents.dispose();
    super.dispose();
  }

  // Load events from Firestore
  void _loadEvents() {
    FirebaseFirestore.instance.collection('events').snapshots().listen((QuerySnapshot eventsSnapshot) {
      eventsSnapshot.docChanges.forEach((change) {
        if (change.type == DocumentChangeType.added) {
          // New event added
          Map<String, dynamic> eventData = change.doc.data() as Map<String, dynamic>;
          DateTime eventDateTime = (eventData['eventDateTime'] as Timestamp).toDate();
          Event event = Event(
            change.doc.id,
            eventData['eventName'],
            eventData['eventDescription'],
            eventDateTime,
            eventData['createdBy'],
            eventData['isPublic'],
          );

          if (event.isPublic) {
            _addLocalEvent(event);
          }
        }
        // Handle other change types (removed, modified) if needed
      });
    }, onError: (error) {
      print('Error listening to events: $error');
    });
  }

  List<Event> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }

  void _addLocalEvent(Event event) {
    try {
      DateTime key = DateTime(event.eventDateTime.year, event.eventDateTime.month, event.eventDateTime.day);
      if (_events.containsKey(key)) {
        _events[key]!.add(event);
      } else {
        _events[key] = [event];
      }
      _selectedEvents.value = _getEventsForDay(_selectedDay); // Update selected events
    } catch (e) {
      print('Error adding local event: $e');
    }
  }

  void _addEventToFirestore(Event event) {
    try {
      FirebaseFirestore.instance.collection('events').add({
        'eventName': event.eventName,
        'eventDescription': event.eventDescription,
        'eventDateTime': event.eventDateTime,
        'createdBy': event.createdBy,
        'isPublic': event.isPublic, // Set visibility flag
      });
    } catch (e) {
      print('Error adding event to Firestore: $e');
    }
  }

  void _addEvent() async {
    String eventName = '';
    String eventDescription = '';
    TimeOfDay selectedTime = TimeOfDay.now();

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (pickedTime != null) {
      selectedTime = pickedTime;
    }

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDay = pickedDate;
        _selectedEvents.value = _getEventsForDay(_selectedDay);
      });
    }

    if (pickedDate != null && pickedTime != null) {
      showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              bool isPublic = true; // Default visibility is public

              return AlertDialog(
                scrollable: true,
                title: const Text("Add Event"),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      onChanged: (value) {
                        eventName = value;
                      },
                      decoration: InputDecoration(
                        labelText: 'Event Name',
                      ),
                    ),
                    TextField(
                      onChanged: (value) {
                        eventDescription = value;
                      },
                      decoration: InputDecoration(
                        labelText: 'Event Description',
                      ),
                    ),
                    Row(
                      children: [
                        Radio(
                          value: true,
                          groupValue: isPublic,
                          onChanged: (value) {
                            setState(() {
                              isPublic = value as bool;
                            });
                          },
                        ),
                        Text('Public'),
                        Radio(
                          value: false,
                          groupValue: isPublic,
                          onChanged: (value) {
                            setState(() {
                              isPublic = value as bool;
                            });
                          },
                        ),
                        Text('Private'),
                      ],
                    ),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        DateTime eventDateTime = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );

                        String userId = FirebaseAuth.instance.currentUser!.uid;
                        Event newEvent = Event('', eventName, eventDescription, eventDateTime, userId, isPublic);
                        _addLocalEvent(newEvent);
                        _addEventToFirestore(newEvent);
                      });
                      Navigator.of(context).pop();
                    },
                    child: const Text("Submit"),
                  ),
                ],
              );
            },
          );
        },
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEvent,
        child: const Icon(Icons.add),
        backgroundColor: Colors.yellow[800]!,
      ),
      body: Column(
        children: [
          Text(
            "Selected Day " + _selectedDay.toString().split(" ")[0],
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.all(10),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(color: Colors.grey),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      TableCalendar(
                        rowHeight: 50,
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        availableGestures: AvailableGestures.all,
                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        focusedDay: DateTime.now(),
                        firstDay: DateTime.now().subtract(const Duration(days: 365)),
                        lastDay: DateTime.now().add(const Duration(days: 365)),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _selectedEvents.value = _getEventsForDay(_selectedDay);
                          });
                        },
                        eventLoader: _getEventsForDay,
                        calendarStyle: CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ValueListenableBuilder<List<Event>>(
                          valueListenable: _selectedEvents,
                          builder: (context, value, _) {
                            return ListView.builder(
                              itemCount: value.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    border: Border.all(),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      value[index].eventName,
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Date: ${value[index].eventDateTime.toString().split(" ")[0]}",
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text("Time: ${value[index].eventDateTime.toString().split(" ")[1].substring(0, 5)}"),
                                        Text("Description: ${value[index].eventDescription}"),
                                        FutureBuilder<DocumentSnapshot>(
                                          future: FirebaseFirestore.instance.collection('users').doc(value[index].createdBy).get(),
                                          builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                                            if (snapshot.hasError) {
                                              return Text("Error: ${snapshot.error}");
                                            }

                                            if (snapshot.connectionState == ConnectionState.done) {
                                              Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;
                                              return Text("Posted By: ${data['username']}");
                                            }

                                            return Text("Loading...");
                                          },
                                        ),
                                      ],
                                    ),
                                trailing: Container(
                                decoration: BoxDecoration(
                                color: Colors.yellow[800]!, // Change color of the container
                                borderRadius: BorderRadius.circular(50), // Adjust border radius if needed
                                ),
                                child: IconButton(
                                icon: Icon(Icons.edit),
                                color: Colors.white, // Change color of the icon
                                onPressed: () {
                                // Implement edit functionality
                                },
                                ),
                                ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => EventList()), // Navigate to the EventList page
                          );
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(Colors.yellow[800]!), // Change background color
                        ),
                        child: Text(
                          'See all events',
                          style: TextStyle(color: Colors.white),
                        ),
                  ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 3,
        onItemTapped: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => KnowledgeResource()),
              );
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => UserListPage()),
              );
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AddPostPage()),
              );
              break;
            case 3:
            // Stay on the current page (Calendar)
              break;
            case 4:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen(uid: FirebaseAuth.instance.currentUser!.uid)),
              );
              break;
          }
        },
      ),
    );
  }
}
