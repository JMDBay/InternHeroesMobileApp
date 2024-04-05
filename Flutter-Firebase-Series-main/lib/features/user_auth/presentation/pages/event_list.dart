import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grouped_list/grouped_list.dart';

class EventList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Events',
          style: TextStyle(fontWeight: FontWeight.bold), // Making the title text bold
        ),
        centerTitle: true, // Centering the title text
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('events').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          // Extract events from snapshot
          final events = snapshot.data!.docs;

          if (events.isEmpty) {
            return Center(
              child: Text('No events available.'),
            );
          }

          // Sort events by date
          events.sort((a, b) {
            final aDate = (a['eventDateTime'] as Timestamp).toDate();
            final bDate = (b['eventDateTime'] as Timestamp).toDate();
            return aDate.compareTo(bDate);
          });

          // Display grouped list of events
          return GroupedListView<dynamic, DateTime>(
            elements: events,
            groupBy: (element) {
              final eventDateTime = (element['eventDateTime'] as Timestamp).toDate();
              // Group events by date
              return DateTime(eventDateTime.year, eventDateTime.month, eventDateTime.day);
            },
            groupSeparatorBuilder: (DateTime date) {
              // Display group separator with date
              return ListTile(
                title: Text(
                  '${_formatDate(date)}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            },
            itemBuilder: (context, dynamic element) {
              final createdBy = element['createdBy'];
              final eventDateTime = (element['eventDateTime'] as Timestamp).toDate();
              final eventDescription = element['eventDescription'];
              final eventName = element['eventName'];

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Event Name: $eventName'),
                      Text('Event Description: $eventDescription'),
                      Text('Event Date & Time: ${eventDateTime.toString()}'),
                      FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        future: FirebaseFirestore.instance.collection('users').doc(createdBy).get(),
                        builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          }

                          if (snapshot.connectionState == ConnectionState.done) {
                            Map<String, dynamic>? userData = snapshot.data?.data();
                            String userName = userData?['name'] ?? 'Unknown';
                            return Text('Created by: $userName');
                          }

                          return Text('Created by: Loading...');
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${_getDayOfWeek(date.weekday)} ${_getMonth(date.month)} ${date.day}, ${date.year}';
  }

  String _getDayOfWeek(int day) {
    switch (day) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }

  String _getMonth(int month) {
    switch (month) {
      case 1:
        return 'January';
      case 2:
        return 'February';
      case 3:
        return 'March';
      case 4:
        return 'April';
      case 5:
        return 'May';
      case 6:
        return 'June';
      case 7:
        return 'July';
      case 8:
        return 'August';
      case 9:
        return 'September';
      case 10:
        return 'October';
      case 11:
        return 'November';
      case 12:
        return 'December';
      default:
        return '';
    }
  }
}
