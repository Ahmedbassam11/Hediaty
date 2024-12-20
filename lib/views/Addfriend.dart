import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hediaty_final/Models/Friends.dart';
import 'package:hediaty_final/Models/Users.dart';
import 'package:hediaty_final/views/main.dart';

class Addfriend extends StatefulWidget {
  final int userid;

  const Addfriend({required this.userid});

  @override
  State<Addfriend> createState() => _AddfriendState();
}

class _AddfriendState extends State<Addfriend>
    with SingleTickerProviderStateMixin {
  late TextEditingController _NameController;
  late TextEditingController _phoneController;
  final _formKey = GlobalKey<FormState>();

  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _NameController = TextEditingController(text: '');
    _phoneController = TextEditingController(text: '');

    // Initialize animation controller
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 800));
    _fadeInAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _NameController.dispose();
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<int> saveFriend() async {
    if (_formKey.currentState!.validate()) {
      user us = user('', '', '', '', '', 0);
      friend fd = friend(0, 0);

      // Step 1: Check if the friend exists locally by phone number
      user? us1 = await us.getUserByPhoneNumber(_phoneController.text);
      user? us2 = await us.getUserByid(widget.userid);

      if (us1 != null && us2 != null) {
        // Insert the friend relationship into the local database
        await fd.insertfriend(widget.userid, us1.id);

        // Step 2: Sync with Firestore
        try {
          // Current user's document ID is their phone number
          final currentUserDocRef = FirebaseFirestore.instance
              .collection('users')
              .doc(us2.phonenumber); // Phone number of the current user

          // Friend's document ID is their phone number
          final friendDocRef = FirebaseFirestore.instance
              .collection('users')
              .doc(us1.phonenumber);

          // Fetch current user's friends list
          final currentUserSnapshot = await currentUserDocRef.get();
          List<String> currentFriendsList = [];

          if (currentUserSnapshot.exists) {
            currentFriendsList =
            List<String>.from(currentUserSnapshot.data()?['friends'] ?? []);
          }

          // Add friend's phone number to current user's friends list if not already there
          if (!currentFriendsList.contains(us1.phonenumber)) {
            currentFriendsList.add(us1.phonenumber);
            await currentUserDocRef.update({'friends': currentFriendsList});
            print("Friend added to current user's Firestore document.");
          } else {
            print("Friend already exists in current user's friends list.");
          }

          // Step 3: Update the friend's friends list (bidirectional sync)
          final friendSnapshot = await friendDocRef.get();
          List<String> friendFriendsList = [];

          if (friendSnapshot.exists) {
            friendFriendsList =
            List<String>.from(friendSnapshot.data()?['friends'] ?? []);
          }

          if (!friendFriendsList.contains(us2.phonenumber)) {
            friendFriendsList.add(us2.phonenumber);
            await friendDocRef.update({'friends': friendFriendsList});
            print("Current user added to friend's Firestore document.");
          } else {
            print("Current user already exists in friend's friends list.");
          }

          return 1; // Success
        } catch (e) {
          print("Error syncing friends in Firestore: $e");
          return 0; // Firestore sync failed
        }
      } else {
        print("There is no user with this phone number.");
        return 0; // Friend not found locally
      }
    }
    return 0; // Form validation failed
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Friend"),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
      ),
      body: FadeTransition(
        opacity: _fadeInAnimation,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Text(
                            "Add a New Friend",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        _buildTextField(
                          controller: _NameController,
                          label: "Friend Name",
                          hint: "Enter friend's name",
                          icon: Icons.person,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Name cannot be empty";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),
                        _buildTextField(
                          controller: _phoneController,
                          label: "Phone Number",
                          hint: "Enter friend's phone number",
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Phone number cannot be empty";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 30),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                vertical: 15, horizontal: 20),
                            backgroundColor: Colors.blue.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                          ),
                          onPressed: () async {
                            int x = await saveFriend();
                            if (_formKey.currentState!.validate() && x != 0) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      Homepage(userid: widget.userid),
                                ),
                              );
                            }
                          },
                          child: Text(
                            "Add Friend",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blue.shade700),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue.shade700),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        fillColor: Colors.blue.shade50,
        filled: true,
      ),
      validator: validator,
    );
  }
}
