import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:hediaty_final/Models/Gifts.dart';
import 'package:hediaty_final/Models/Events.dart';
import 'package:hediaty_final/Models/Users.dart';
import 'package:hediaty_final/services/push_notification_service.dart';
import 'package:hediaty_final/views/GiftDetailsPage.dart';

class GiftListPage extends StatefulWidget{
  final int? eventID; // Event ID to fetch gifts (for "My Events")
  final int userid; // Logged-in user's ID
  final int ownerId; // Owner of the event (used for permission check)
  final String? eventName; // Optional Event Name (for Friend's Event)

  const GiftListPage({
    this.eventID,
    required this.userid,
    required this.ownerId,
    this.eventName,
  });

  @override
  _GiftListPageState createState() => _GiftListPageState();
}

class _GiftListPageState extends State<GiftListPage>  with SingleTickerProviderStateMixin {
  late Future<List<Gift>> _giftList;
  bool isMyEvent = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _giftList = Future.value([]);
    isMyEvent = widget.userid == widget.ownerId;
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _controller.forward();

    if (isMyEvent) {
      _fetchGiftsByEventID();
    } else {
      if (widget.eventName != null) {
        _fetchFriendGiftsByEventName(widget.eventName!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
              "Error: Event name is required for friend's events.")),
        );
      }
    }
  }

  Future<String?> _getFriendToken(String phoneNumber) async {
    try {
      final firestore = FirebaseFirestore.instance;
      DocumentSnapshot<Map<String, dynamic>> userDoc = await firestore
          .collection('users')
          .doc(phoneNumber)
          .get();

      if (userDoc.exists) {
        return userDoc.data()?['token'] as String?;
      } else {
        print("No device token found for the user: $phoneNumber");
        return null;
      }
    } catch (e) {
      print("Error fetching friend's token: $e");
      return null;
    }
  }

// Function to handle pledging a gift
  // Function to handle pledging a gift
  Future<void> pledgeGift(Gift gift) async {
    if (gift.status == 'pledged') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("This gift has already been pledged.")),
      );
      return;
    }

    final shouldPledge = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Pledge Gift"),
          content: Text(
              "Are you sure you want to pledge this gift? This action cannot be undone."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text("Pledge"),
            ),
          ],
        );
      },
    );

    if (shouldPledge == true) {
      try {
        final firestore = FirebaseFirestore.instance;

        // Retrieve the current user's phone number
        final currentUser = await user("", "", "", "", "", 0).getUserByid(widget.userid);
        final currentUserPhoneNumber = currentUser!.phonenumber;

        final ownerUser = await user("", "", "", "", "", 0).getUserByid(widget.ownerId);

        if (ownerUser != null && ownerUser.phonenumber.isNotEmpty) {
          String phoneNumber = ownerUser.phonenumber;

          // Retrieve gifts for the event
          DocumentSnapshot<Map<String, dynamic>> snapshot = await firestore
              .collection('giftsbyuser')
              .doc(phoneNumber)
              .get();

          if (snapshot.exists) {
            List<dynamic> giftsData = snapshot.data()?['gifts'] ?? [];
            for (var giftData in giftsData) {
              if (giftData['name'] == gift.name &&
                  giftData['eventName'] == widget.eventName) {
                giftData['status'] = 'pledged'; // Update status to pledged
                giftData['pledgedBy'] = currentUserPhoneNumber; // Add pledgedBy attribute
                break;
              }
            }

            // Update Firestore with the modified data
            await firestore
                .collection('giftsbyuser')
                .doc(phoneNumber)
                .set({'gifts': giftsData}, SetOptions(merge: true));

            // Update local UI
            setState(() {
              gift.status = 'pledged';
            });

            await _updateGiftInLocalDatabase(gift);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Gift pledged successfully!")),
            );

            final QuerySnapshot userSnapshot = await FirebaseFirestore.instance
                .collection('users')
                .where('phonenumber', isEqualTo: phoneNumber)
                .get();
            if (userSnapshot.docs.isNotEmpty) {
              final userDoc = userSnapshot.docs.first;
              final userData = userDoc.data() as Map<String, dynamic>;
              final token = userData['token'];
              await pushnotificationService.sendPushNotification(
                  token,
                  "Gift Pledged",
                  "Your gift: ${gift.name} at event: ${widget.eventName} has been pledged.");
            }
          }
        }
      } catch (e) {
        print("Error pledging gift: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to pledge gift.")),
        );
      }
    }
  }


  Future<void> _updateGiftInLocalDatabase(Gift gift) async {
    try {
      // Update the gift's status to 'pledged' in the local SQLite database
      int result = await gift.pledgeGift(gift.id, gift.userId);

      if (result > 0) {
        print("Gift updated successfully in local database.");
      } else {
        print("Failed to update gift in local database.");
      }
    } catch (e) {
      print("Error updating gift in local database: $e");
    }
  }


  // Fetch gifts for "My Events" using eventID
  void _fetchGiftsByEventID() async {
    try {
      // Fetch gifts from Firestore
      final firestore = FirebaseFirestore.instance;
      final ownerUser = await user("", "", "", "", "", 0).getUserByid(
          widget.ownerId);
      String phoneNumber = ownerUser!.phonenumber;
      event ev = event('', '', '', '', 0);
      event? ev1 = await ev.getEventById(widget.eventID!);

      final eventDoc = await firestore.collection('giftsbyuser').doc(
          phoneNumber).get();

      if (eventDoc.exists) {
        List<dynamic> giftsData = eventDoc.data()?['gifts'] ?? [];
        List<Gift> gifts = giftsData
            .where((gift) => gift['eventName'] == ev1!.name)
            .map((gift) {
          return Gift(
            gift['name'],
            '',
            gift['category'] ?? '',
            (gift['price'] as num).toDouble(),
            gift['status'] ?? 'available',
            widget.eventID!,
          );
        }).toList();

        // Check against local database and insert non-duplicate gifts
        for (var gift in gifts) {
          List<Gift> localGifts = await Gift('', '', '', 0.0, '', 0)
              .getGiftsByEventID(widget.eventID!);

          // Check if the gift already exists in the local database
          bool isDuplicate = localGifts.any((localGift) =>
          localGift.name == gift.name);

          if (!isDuplicate) {
            await gift.insertGift();
          }
        }

        // Update local gift list from the local database
        setState(() {
          _giftList =
              Gift('', '', '', 0.0, '', 0).getGiftsByEventID(widget.eventID!);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gifts fetched and updated successfully!")),
        );
      } else {
        setState(() {
          _giftList =
              Gift('', '', '', 0.0, '', 0).getGiftsByEventID(widget.eventID!);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("No gifts found in Firestore for this event.")),
        );
      }
    } catch (e) {
      print("Error fetching gifts by event ID: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to fetch gifts from Firestore.")),
      );
    }
  }


  // Fetch friend's gifts for "Friend's Event" using eventName
  void _fetchFriendGiftsByEventName(String eventName) async {
    try {
      user? ownerUser = await user("", "", "", "", "", 0).getUserByid(
          widget.ownerId);
      if (ownerUser == null || ownerUser.phonenumber.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: Owner's phone number not found.")),
        );
        return;
      }

      String phoneNumber = ownerUser.phonenumber;

      // Retrieve gifts from Firestore for the specific event name
      setState(() {
        _giftList = _getFriendGiftsFromFirestore(phoneNumber, eventName);
      });
    } catch (e) {
      print("Error fetching friend's gifts: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to fetch friend's gifts.")),
      );
    }
  }

  // Helper method to fetch gifts from Firestore
  Future<List<Gift>> _getFriendGiftsFromFirestore(String phoneNumber,
      String eventName) async {
    try {
      final firestore = FirebaseFirestore.instance;
      DocumentSnapshot<Map<String, dynamic>> snapshot =
      await firestore.collection('giftsbyuser').doc(phoneNumber).get();

      if (snapshot.exists) {
        List<dynamic> giftsData = snapshot.data()?['gifts'] ?? [];
        // Filter gifts based on event name
        List<Gift> filteredGifts = giftsData
            .where((gift) => gift['eventName'] == eventName)
            .map((gift) =>
            Gift(
              gift['name'],
              '',
              gift['category'],
              (gift['price'] as num).toDouble(),
              gift['status'],
              0,
            ))
            .toList()
            .cast<Gift>();

        return filteredGifts;
      } else {
        print("No gifts found for the friend with phone: $phoneNumber");
        return [];
      }
    } catch (e) {
      print("Error retrieving friend's gifts: $e");
      return [];
    }
  }

  // Sync all gifts to Firestore
  Future<void> _syncGiftsToFirestore() async {
    try {
      // Fetch the logged-in user's details
      user? loggedUser = await user("", "", "", "", "", 0).getUserByid(
          widget.userid);
      if (loggedUser == null || loggedUser.phonenumber.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: User phone number not found.")),
        );
        return;
      }

      String phoneNumber = loggedUser.phonenumber;
      List<Gift> newGifts = await _giftList;

      final firestore = FirebaseFirestore.instance;

      // Fetch the current list of gifts from Firestore
      DocumentSnapshot<Map<String, dynamic>> snapshot =
      await firestore.collection('giftsbyuser').doc(phoneNumber).get();

      List<dynamic> existingGiftsData = snapshot.data()?['gifts'] ?? [];
      List<Map<String, dynamic>> existingGifts = existingGiftsData.cast<
          Map<String, dynamic>>();

      // Convert existing Firestore gifts to a list of gift names for comparison
      Set<String> existingGiftNames = existingGifts.map((
          g) => g['name'] as String).toSet();

      // Filter out duplicate gifts by name
      List<Map<String, dynamic>> newGiftsData = newGifts
          .where((gift) => !existingGiftNames.contains(gift.name))
          .map((gift) {
        return {
          'name': gift.name,
          'category': gift.category,
          'price': gift.price,
          'status': gift.status,
          'eventName': widget.eventName ?? '',
        };
      })
          .toList();

      // Merge new gifts with existing ones
      List<Map<String, dynamic>> updatedGifts = [
        ...existingGifts,
        ...newGiftsData
      ];

      // Save the merged list back to Firestore
      await firestore.collection('giftsbyuser').doc(phoneNumber).set({
        'gifts': updatedGifts,
      }, SetOptions(merge: true));


      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gifts synced successfully!")),
      );
    } catch (e) {
      print("Error syncing gifts: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to sync gifts.")),
      );
    }
  }


  // Delete gift logic
  void _deleteGift(Gift gift) async {
    int result = await gift.deleteGift(gift.id);
    if (result > 0) {
      print("Gift deleted successfully.");
      if (isMyEvent) {
        _fetchGiftsByEventID();
      } else {
        _fetchFriendGiftsByEventName(widget.eventName!);
      }
    } else {
      print("Failed to delete gift.");
    }
  }

  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isMyEvent ? 'My Gifts' : 'Friend\'s Gifts'),
        actions: [
          if (isMyEvent)
            IconButton(
              icon: Icon(Icons.sync),
              tooltip: "Sync Gifts",
              onPressed: _syncGiftsToFirestore,
            ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return FadeTransition(
            opacity: _controller,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _controller,
                curve: Curves.easeOut,
              )),
              child: FutureBuilder<List<Gift>>(
                future: _giftList,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: Colors.blueAccent,
                        strokeWidth: 3,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading gifts: ${snapshot.error}',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        'No gifts available.',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    );
                  }

                  final gifts = snapshot.data!;
                  return AnimationLimiter(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12.0),
                      itemCount: gifts.length,
                      itemBuilder: (context, index) {
                        final gift = gifts[index];
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 500),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                                elevation: 4.0,
                                margin: const EdgeInsets.symmetric(
                                    vertical: 8.0, horizontal: 8.0),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16.0),
                                  title: Text(
                                    gift.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18.0,
                                      color: gift.status == 'pledged'
                                          ? Colors.green
                                          : Colors.black,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Category: ${gift.category}\nStatus: ${gift
                                        .status}',
                                    style: TextStyle(fontSize: 14.0),
                                  ),
                                  trailing: isMyEvent
                                      ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit,
                                            color: Colors.blue),
                                        onPressed: () async {
                                          final updated =
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  GiftDetailsPage(
                                                      gift: gift,
                                                      user_id:
                                                      widget.userid),
                                            ),
                                          );
                                          if (updated == true)
                                            _fetchGiftsByEventID();
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () =>
                                            _deleteGift(gift),
                                      ),
                                    ],
                                  )
                                      : Icon(
                                    Icons.card_giftcard,
                                    color: Colors.blueAccent,
                                  ),
                                  onTap:
                                  isMyEvent ? null : () => pledgeGift(gift),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: isMyEvent
          ? ScaleTransition(
        scale: CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOutBack,
        ),
        child: FloatingActionButton(
          onPressed: () async {
            final newGift = Gift.withId(
                0, '', '', '', 0.0, 'available', widget.eventID!, userId: widget.userid);
            final added = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    GiftDetailsPage(gift: newGift, user_id: widget.userid),
              ),
            );

            if (added == true)  _fetchGiftsByEventID();
          },
          child: Icon(Icons.add),
          backgroundColor: Colors.blueAccent,
        ),
      ) : null,
    );
  }
}




























