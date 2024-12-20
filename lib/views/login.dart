import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hediaty_final/Models/Friends.dart';
import 'package:hediaty_final/Models/Users.dart';
import 'package:hediaty_final/views/main.dart';
import 'package:hediaty_final/views/register.dart';
import 'package:hediaty_final/services/push_notification_service.dart';

class login extends StatefulWidget {
  const login({super.key});

  @override
  State<login> createState() => _loginState();
}

class _loginState extends State<login> {
  late String _email, _password, _phonenumber;
  FirebaseAuth instance = FirebaseAuth.instance;
  var loginkey = GlobalKey<ScaffoldState>();

  Future<void> syncFirestoreToLocal() async {
    try {
      final QuerySnapshot firestoreUsers =
      await FirebaseFirestore.instance.collection('users').get();

      for (var doc in firestoreUsers.docs) {
        final userData = doc.data() as Map<String, dynamic>;
        user firestoreUser = user(
          userData['name'] ?? '',
          userData['email'] ?? '',
          userData['preferences'] ?? '',
          userData['phonenumber'] ?? '',
          userData['password'] ?? '',
          0,
        );

        user? existingUser =
        await firestoreUser.getUserByPhoneNumber(firestoreUser.phonenumber);

        if (existingUser == null) {
          await firestoreUser.insertuser(
            firestoreUser.name,
            firestoreUser.email,
            firestoreUser.preference,
            firestoreUser.phonenumber,
            firestoreUser.password,
            0,
          );
        }

        List<String> friendsPhoneNumbers =
        await List<String>.from(userData['friends'] ?? []);

        for (var friendPhone in friendsPhoneNumbers) {
          user? friendUser =
          await firestoreUser.getUserByPhoneNumber(friendPhone);

          if (friendUser != null && existingUser != null) {
            friend localFriend =  friend(existingUser.id, friendUser.id);
            List<friend> existingFriends = await localFriend.getfriends();

            bool friendExists = existingFriends.any((f) =>
            (f.user_id == localFriend.user_id &&
                f.friend_id == localFriend.friend_id));

            if (!friendExists) {
              await localFriend.insertfriend(
                  localFriend.user_id, localFriend.friend_id);
            }
          }
        }
      }
    } catch (e) {
      print("Error syncing Firestore to local database: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Login', style: GoogleFonts.lato(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 20),
              Center(
                child: Text(
                  "Welcome Back!",
                  style: GoogleFonts.lato(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
              SizedBox(height: 10),
              Center(
                child: Text(
                  "Login to continue",
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              SizedBox(height: 40),
              TextField(
                key: Key('emailField'),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.email, color: Colors.blueAccent),
                  hintText: 'Enter your email',
                  hintStyle: GoogleFonts.lato(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) => setState(() => _email = value),
              ),
              SizedBox(height: 20),
              TextField(
                key: Key('passwordField'),
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.lock, color: Colors.blueAccent),
                  hintText: 'Enter your password',
                  hintStyle: GoogleFonts.lato(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) => setState(() => _password = value),
              ),
              SizedBox(height: 20),
              TextField(
                key: Key('phoneField'),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.phone, color: Colors.blueAccent),
                  hintText: 'Enter your phone number',
                  hintStyle: GoogleFonts.lato(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) => setState(() => _phonenumber = value),
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await syncFirestoreToLocal();

                    UserCredential credential =
                    await instance.signInWithEmailAndPassword(
                      email: _email,
                      password: _password,
                    );

                    final QuerySnapshot userSnapshot = await FirebaseFirestore
                        .instance
                        .collection('users')
                        .where('phonenumber', isEqualTo: _phonenumber)
                        .get();

                    if (userSnapshot.docs.isNotEmpty) {
                      final userDoc = userSnapshot.docs.first;
                      final userData = userDoc.data() as Map<String, dynamic>;
                      final phonenumber = userData['phonenumber'];

                      user localUser = user(
                        userData['name'] ?? '',
                        userData['email'] ?? '',
                        userData['preferences'] ?? '',
                        userData['phonenumber'] ?? '',
                        userData['password'] ?? '',
                        0,
                      );

                      user? existingUser =
                      await localUser.getUserByPhoneNumber(_phonenumber);

                      int userId;
                      if (existingUser == null) {
                        int response = await localUser.insertuser(
                          localUser.name,
                          localUser.email,
                          localUser.preference,
                          localUser.phonenumber,
                          localUser.password,
                          1,
                        );
                        userId = response;
                      } else {
                        await existingUser.setLogged(existingUser.id, 1);
                        userId = existingUser.id;
                      }

                      String? token =
                      await pushnotificationService.gettoken();

                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(phonenumber)
                          .update({'token': token});

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => Homepage(userid: userId)),
                      );
                    }
                  } on FirebaseAuthException catch (e) {
                    print("Authentication error: ${e.message}");
                  } catch (e) {
                    print("An error occurred during login: $e");
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15), backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  "Login",
                  style: GoogleFonts.lato(fontSize: 16, color: Colors.white),
                ),
                key: Key('loginButton'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => Register()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15), backgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  "Register",
                  style: GoogleFonts.lato(fontSize: 16, color: Colors.black),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: Text(
                  "Forgot your password?",
                  style: GoogleFonts.lato(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
