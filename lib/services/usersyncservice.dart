import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hediaty_final/Models/Users.dart';
import 'package:hediaty_final/Models/Users.dart';

class UserSyncService {
  Future<void> syncAllUsersToFirestore() async {
    try {
      // Step 1: Retrieve all users from SQLite
      user userModel = user("", "", "", "", "", 0); // Create a dummy instance to access methods
      List<user> usersList = await userModel.getusers();

      // Step 2: Iterate through users and push them to Firestore
      for (var user in usersList) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.phonenumber) // Use phone number as the document ID
            .set({
          'name': user.name,
          'email': user.email,
          'preferences': user.preference,
          'phonenumber': user.phonenumber,
          'password': user.password,
          'logged': user.logged,
          // Initialize token field as empty
        }, SetOptions(merge: true)); // Merge to avoid overwriting existing data
        print("User ${user.name} synced to Firestore with empty token.");
      }
      print("All users have been successfully synced to Firestore.");
    } catch (e) {
      print("Error syncing users to Firestore: $e");
    }
  }

  Future<void> syncUsersWithFriendsToFirestore() async {
    try {
      // Step 1: Retrieve all users from SQLite
      user userModel = user("", "", "", "", "", 0); // Create a dummy instance to access methods
      List<user> usersList = await userModel.getusers();

      // Step 2: Iterate through users and sync their data and friends to Firestore
      for (var currentUser in usersList) {
        // Fetch friends of the user from SQLite
        List<user> friendsList = await userModel.getfriendswithuserid(currentUser.id);

        // Extract phone numbers of friends
        List<String> friendsPhoneNumbers = friendsList
            .map((friend) => (friend as user).phonenumber) // Ensure correct typing
            .toList();

        // Sync user data to Firestore along with their friends
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.phonenumber) // Use phone number as the document ID
            .set({
          'name': currentUser.name,
          'email': currentUser.email,
          'preferences': currentUser.preference,
          'phonenumber': currentUser.phonenumber,
          'password': currentUser.password,
          'logged': currentUser.logged,
          'friends': friendsPhoneNumbers, // Store friends' phone numbers
        }, SetOptions(merge: true)); // Merge to avoid overwriting existing data

        print("User ${currentUser.name} and their friends synced to Firestore.");
      }

      print("All users and their friends have been successfully synced to Firestore.");
    } catch (e) {
      print("Error syncing users and their friends to Firestore: $e");
    }
  }




  Future<void> deleteAllUsersFromFirestore() async {
  try {
  // Step 1: Retrieve all users from Firestore
  QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      .collection('users')
      .get();

  // Step 2: Iterate through all users and delete them
  for (var doc in querySnapshot.docs) {
  await doc.reference.delete();
  print("Deleted user with phone number: ${doc['phonenumber']}");
  }

  print("All users have been successfully deleted from Firestore.");
  } catch (e) {
  print("Error deleting users from Firestore: $e");
  }
  }
  }


