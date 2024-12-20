import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hediaty_final/Models/Users.dart';
import 'package:hediaty_final/services/push_notification_service.dart';
import 'package:hediaty_final/views/main.dart';


class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  late  String _email,_password,_name,_preference, _phonenumber;

  FirebaseAuth instance = FirebaseAuth.instance;
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        title: Text('Register page'),
      ),
      body: Center(
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(hintText: 'Enter your name'),
              onChanged: (value){
                setState(() {
                  this._name=value;
                });

              },
            ),
            SizedBox(height: 10,),
            TextField(
              decoration: InputDecoration(hintText: 'Enter your email'),
              onChanged: (value){
                setState(() {
                  this._email=value;
                });

              },
            ),
            SizedBox(height: 10,),
            TextField(
              decoration: InputDecoration(hintText: 'Enter your password'),
              onChanged: (value){
                setState(() {
                  this._password=value;
                }
                );


              },
            ),
        SizedBox(height: 10,),
        TextField(
        decoration: InputDecoration(hintText: 'Enter your preference'),
         onChanged: (value){
         setState(() {
         this._preference=value;
          });
         },
         ),
            SizedBox(height: 10,),
            TextField(
              decoration: InputDecoration(hintText: 'Enter your phone number'),
              onChanged: (value){
                setState(() {
                  this._phonenumber=value;
                });
              },
            ),




    ElevatedButton(
      onPressed: () async {
        try {
          // Firebase Auth Registration
          UserCredential credentials = await instance.createUserWithEmailAndPassword(
            email: _email,
            password: _password,
          );

          // SQLite User Insertion
          user us = user(_name, _email, _preference, _phonenumber, _password, 1);
          int response1 = await us.insertuser(_name, _email, _preference, _phonenumber, _password, 1);

          // Save FCM Token
          String? token = await pushnotificationService.gettoken();

          // Save to Firestore
          await FirebaseFirestore.instance.collection('users').doc(_phonenumber).set({
            'name': _name,
            'email': _email,
            'password':_password,
            'preferences': _preference,
            'phonenumber': _phonenumber,
            'logged':1,
            'fcm_token': token ??'',
          });

          print("User saved to Firestore successfully!");

          // Navigate to Homepage
          Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (context) => Homepage(userid: response1),
          ));
        } catch (e) {
          print("Registration Exception: $e");
        }
      },
      child: Text("Register"),
    ),


      ],
        ),
      ),
    );
  }
}
