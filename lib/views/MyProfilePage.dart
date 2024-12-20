import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:hediaty_final/Models/Users.dart';
import 'package:hediaty_final/views/ Event_List_Page.dart';
import 'package:hediaty_final/views/MyPledgedGiftsPage.dart';

class MyProfilePage extends StatefulWidget {
  final int userId;

  const MyProfilePage({required this.userId});

  @override
  _MyProfilePageState createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  late user currentUser;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  // Fetch user data from the database
  Future<void> fetchUserData() async {
    user? fetchedUser = await user('', '', '', '', '', 0).getUserByid(widget.userId);
    if (fetchedUser != null) {
      setState(() {
        currentUser = fetchedUser;
        isLoading = false;
      });
    } else {
      print("Error: User not found.");
      setState(() => isLoading = false);
    }
  }

  // Update user data using the new `updateUser` function
  Future<void> updateUserField(String field, String value) async {
    switch (field) {
      case 'name':
        currentUser.name = value;
        break;
      case 'email':
        currentUser.email = value;
        break;
      case 'preference':
        currentUser.preference = value;
        break;
      case 'phonenumber':
        currentUser.phonenumber = value;
        break;
    }

    // Call the updateUser function to save changes to the database
    int result = await currentUser.updateUser();
    if (result != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$field updated successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating $field.')),
      );
    }
  }

  // Display a dialog to edit the selected field
  void editField(String fieldName, String currentValue) {
    TextEditingController controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $fieldName'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: 'New $fieldName'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await updateUserField(fieldName.toLowerCase(), controller.text.trim());
              setState(() {});
              Navigator.of(context).pop();
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('My Profile')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('My Profile')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            FadeIn(
              child: Stack(
                children: [
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blueAccent, Colors.lightBlueAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 50,
                    left: 20,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage('lib/assets/images/myuser.png'),
                    ),
                  ),
                  Positioned(
                    top: 60,
                    left: 130,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUser.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          currentUser.email,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FadeInUp(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Display user fields with edit icons
                    buildProfileField('Name', currentUser.name),
                    buildProfileField('Email', currentUser.email),
                    buildProfileField('Phone Number', currentUser.phonenumber),
                    buildProfileField('Preference', currentUser.preference),
                    const SizedBox(height: 20),

                    // My Events Button
                    ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to EventListPage for this user
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EventListPage(friendid: widget.userId, userid: widget.userId),
                          ),
                        );
                      },
                      icon: Icon(Icons.event),
                      label: Text('My Events'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MyPledgedGiftsPage(userid: widget.userId),
                          ),
                        );
                      },
                      child: Text('View My Pledged Gifts'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Back Button
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('Back'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to display a profile field
  Widget buildProfileField(String fieldName, String fieldValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '$fieldName: $fieldValue',
              style: TextStyle(fontSize: 16),
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit, color: Colors.blue),
            onPressed: () => editField(fieldName.toLowerCase(), fieldValue),
          ),
        ],
      ),
    );
  }
}
