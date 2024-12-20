import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hediaty_final/Models/Events.dart';
import 'package:hediaty_final/Models/Users.dart';
import 'package:hediaty_final/views/GiftListPage.dart';
import 'package:hediaty_final/views/eventformpage.dart';

class EventListPage extends StatefulWidget {
  final int friendid; // Friend's ID (can be the same as userid for "my events")
  final int userid; // Logged-in user's ID

  const EventListPage({
    required this.friendid,
    required this.userid,
  });

  @override
  State<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  List<event> eventList = [];
  String _sortField = 'name';
  bool _ascending = true;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    try {
      if (widget.userid == widget.friendid) {
        await _fetchEventsFromLocal();
      } else {
        await _fetchFriendEventsFromFirestore();
      }
      _sortEvents();
    } catch (e) {
      print("Error fetching events: $e");
    }
  }

  Future<void> _fetchEventsFromLocal() async {
    try {
      event ev = event("", "", "", "", widget.userid);

      List<event> localEvents = await ev.getevents();

      user? loggedUser = await user("", "", "", "", "", 0).getUserByid(widget.userid);
      if (loggedUser == null) return;

      String phoneNumber = loggedUser.phonenumber;
      final firestore = FirebaseFirestore.instance;

      DocumentSnapshot<Map<String, dynamic>> snapshot =
      await firestore.collection('eventsbyuser').doc(phoneNumber).get();

      if (snapshot.exists) {
        List<dynamic> remoteEvents = snapshot.data()?['events'] ?? [];

        for (var remoteEvent in remoteEvents) {
          bool exists = localEvents.any((localEvent) =>
          localEvent.name == remoteEvent['name'] &&
              localEvent.date == remoteEvent['date'] &&
              localEvent.location == remoteEvent['location']);

          if (!exists) {
            event ev = event('', '', '', '', 0);
            await ev.insertevent(remoteEvent['name'], remoteEvent['date'], remoteEvent['location'], remoteEvent['description'], widget.userid);
          }
        }
      }

      List<event> updatedLocalEvents = await ev.getevents();
      setState(() {
        eventList = updatedLocalEvents.where((e) => e.user_id == widget.userid).toList();
      });
    } catch (e) {
      print("Error fetching events from local or Firestore: $e");
    }
  }

  Future<void> _fetchFriendEventsFromFirestore() async {
    try {
      user? friend = await user("", "", "", "", "", 0).getUserByid(widget.friendid);
      if (friend == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: Friend not found.")),
        );
        return;
      }

      String phoneNumber = friend.phonenumber;
      final firestore = FirebaseFirestore.instance;
      DocumentSnapshot<Map<String, dynamic>> snapshot =
      await firestore.collection('eventsbyuser').doc(phoneNumber).get();

      if (snapshot.exists) {
        List<dynamic> eventsData = snapshot.data()?['events'] ?? [];
        setState(() {
          eventList = eventsData.map((e) {
            return event(
              e['name'] ?? "",
              e['date'] ?? "",
              e['location'] ?? "",
              e['description'] ?? "",
              widget.friendid,
            );
          }).toList();
        });
      } else {
        setState(() {
          eventList = [];
        });
      }
    } catch (e) {
      print("Error fetching friend's events: $e");
    }
  }

  void _sortEvents() {
    setState(() {
      eventList.sort((a, b) {
        var aValue = _getSortValue(a);
        var bValue = _getSortValue(b);
        return _ascending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
      });
    });
  }

  dynamic _getSortValue(event ev) {
    switch (_sortField) {
      case 'category':
        return ev.description;
      case 'date':
        return ev.date;
      default:
        return ev.name;
    }
  }

  void _deleteEvent(int eventId) async {
    try {
      event ev = event("", "", "", "", widget.userid);
      await ev.database.deletedata("DELETE FROM 'Events' WHERE id = $eventId");
      _fetchEvents();
    } catch (e) {
      print("Error deleting event: $e");
    }
  }

  Future<void> _syncEventsToFirestore() async {
    try {
      user? loggedUser = await user("", "", "", "", "", 0).getUserByid(widget.userid);
      if (loggedUser == null) return;

      String phoneNumber = loggedUser.phonenumber;
      List<Map<String, dynamic>> eventsData = eventList.map((ev) {
        return {
          'name': ev.name,
          'description': ev.description,
          'date': ev.date,
          'location': ev.location,
        };
      }).toList();

      final firestore = FirebaseFirestore.instance;
      await firestore.collection('eventsbyuser').doc(phoneNumber).set({
        'events': eventsData,
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Events synced successfully!")),
      );
    } catch (e) {
      print("Error syncing events: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMyEvents = widget.userid == widget.friendid;

    return Scaffold(
      appBar: AppBar(
        title: Text(isMyEvents ? 'My Events' : 'Friend\'s Events'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _sortField = value;
                _ascending = !_ascending;
                _sortEvents();
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'name', child: Text('Sort by Name')),
              PopupMenuItem(value: 'category', child: Text('Sort by Category')),
              PopupMenuItem(value: 'date', child: Text('Sort by Date')),
            ],
          ),
          if (isMyEvents)
            IconButton(
              icon: Icon(Icons.sync),
              onPressed: _syncEventsToFirestore,
              tooltip: "Sync Events",
            ),
        ],
      ),
      body: SlideInUp(
        child: eventList.isEmpty
            ? Center(
          child: Text("No events found.",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        )
            : Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView.builder(
            itemCount: eventList.length,
            itemBuilder: (context, index) {
              final ev = eventList[index];
              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 16),
                  title: Text(
                    ev.name,
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Date: ${ev.date}\nLocation: ${ev.location}',
                    style: TextStyle(height: 1.5),
                  ),
                  onTap: () {
                    if (isMyEvents) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GiftListPage(
                            eventID: ev.id,
                            userid: widget.userid,
                            ownerId: widget.friendid,
                            eventName: ev.name,
                          ),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GiftListPage(
                            eventID: null,
                            eventName: ev.name,
                            userid: widget.userid,
                            ownerId: widget.friendid,
                          ),
                        ),
                      );
                    }
                  },
                  trailing: isMyEvents
                      ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EventFormPage(
                                ev: ev, userId: widget.userid),
                          ),
                        ).then((value) => _fetchEvents()),
                      ),
                      IconButton(
                        icon:
                        Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteEvent(ev.id),
                      ),
                    ],
                  )
                      : null,
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: isMyEvents
          ? FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventFormPage(userId: widget.userid),
          ),
        ).then((value) => _fetchEvents()),
        child: Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
      )
          : null,
    );
  }
}
