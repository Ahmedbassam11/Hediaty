
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hediaty_final/Models/Users.dart';

class MyPledgedGiftsPage extends StatefulWidget {
  final int userid; // Phone number of the logged-in user

  const MyPledgedGiftsPage({required this.userid});

  @override
  _MyPledgedGiftsPageState createState() => _MyPledgedGiftsPageState();
}

class _MyPledgedGiftsPageState extends State<MyPledgedGiftsPage> {
  late Future<List<Map<String, dynamic>>> _pledgedGifts;

  @override
  void initState() {
    super.initState();
    _pledgedGifts = _fetchPledgedGifts();
  }

  Future<List<Map<String, dynamic>>> _fetchPledgedGifts() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final currentUser = await user("", "", "", "", "", 0).getUserByid(widget.userid);
      final userPhoneNumber = currentUser!.phonenumber;
      // Fetch all documents in the giftsbyuser collection
      final querySnapshot = await firestore.collection('giftsbyuser').get();

      List<Map<String, dynamic>> pledgedGifts = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final gifts = data['gifts'] as List<dynamic>?;
        final ownerPhoneNumber = doc.id; // Document ID as the owner's phone number
        user? owner= await user('', '', '', '', '', 0).getUserByPhoneNumber(ownerPhoneNumber);
        final ownername = owner!.name;
        if (gifts != null) {
          for (var giftData in gifts) {
            if (giftData['pledgedBy'] == userPhoneNumber) {
              pledgedGifts.add({
                'name': giftData['name'],
                'category': giftData['category'],
                'price': giftData['price'],
                'ownername': ownername,
              });
            }
          }
        }
      }

      return pledgedGifts;
    } catch (e) {
      print("Error fetching pledged gifts: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Pledged Gifts"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: FadeIn(
        duration: const Duration(seconds: 1),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _pledgedGifts,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return FadeInUp(
                child: const Center(
                  child: Text(
                    "You have not pledged any gifts.",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ),
              );
            } else {
              List<Map<String, dynamic>> gifts = snapshot.data!;
              return ListView.builder(
                itemCount: gifts.length,
                itemBuilder: (context, index) {
                  final gift = gifts[index];
                  return SlideInUp(
                    duration: const Duration(milliseconds: 500),
                    child: Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 5,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16.0),
                        leading: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.blueAccent.withOpacity(0.2),
                          child: const Icon(
                            Icons.card_giftcard,
                            size: 30,
                            color: Colors.blueAccent,
                          ),
                        ),
                        title: Text(
                          gift['name'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              Text(
                                "Category: ${gift['category']}",
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                "Price: \$${gift['price'].toStringAsFixed(2)}",
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.green),
                              ),
                              Text(
                                "Owner: ${gift['ownername']}",
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          size: 28,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}
