import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hediaty_final/views/%20Event_List_Page.dart';
import 'package:hediaty_final/views/Addfriend.dart';
import 'package:hediaty_final/Models/Friends.dart';
import 'package:hediaty_final/Models/Users.dart';
import 'package:hediaty_final/views/MyProfilePage.dart';
import 'package:hediaty_final/views/eventformpage.dart';
import 'package:hediaty_final/services/push_notification_service.dart';
import 'package:hediaty_final/services/usersyncservice.dart';
import 'package:hediaty_final/services/sql_db.dart';
import 'package:animate_do/animate_do.dart';
import 'package:hediaty_final/views/login.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  pushnotificationService.init();
  runApp(HedieatyApp());
}

class HedieatyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hedieaty',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.black87),
          bodyMedium: TextStyle(color: Colors.black54),
        ),
      ),
      navigatorKey: navigatorKey,
      home: StartupPage(),

    );
  }
}


class StartupPage extends StatefulWidget {
  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late sqflite_database _sqlDb;

  @override
  void initState() {
    super.initState();
    _sqlDb = sqflite_database();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    User? firebaseUser = _auth.currentUser;
    List<Map> localUser = await _sqlDb.readdata("SELECT id FROM Users WHERE logged = 1 LIMIT 1");

    if (firebaseUser != null && localUser.isNotEmpty) {
      int userId = localUser[0]['id'];
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Homepage(userid: userId)),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => login()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('StartupPageScaffold'),
      body: Center(
        child: ZoomIn(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
          ),
        ),
      ),
    );
  }
}

class Homepage extends StatefulWidget {
  final int userid;

  const Homepage({required this.userid});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  FirebaseAuth instance = FirebaseAuth.instance;
  List<user> friendslist = [];
  user loggedUser = user('', '', '', '', '', 0);

  Future<void> getLoggedUser() async {
    try {
      user us = user('', '', '', '', '', 0);
      user? fetchedUser = await us.getUserByid(widget.userid);
      if (fetchedUser != null) {
        setState(() {
          loggedUser = fetchedUser;
        });
      }
    } catch (e) {
      print("Error fetching logged user: $e");
    }
  }

  Future<void> getFriends() async {
    try {
      user us = user("", "", "", "", "", 0);
      List<user> fetchedFriends = await us.getfriendswithuserid(widget.userid);
      setState(() {
        friendslist = fetchedFriends;
      });
    } catch (e) {
      print("Error fetching friends: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    instance.authStateChanges().listen((User? user) {
      if (user == null) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => login()));
      } else {
        getFriends();
        getLoggedUser();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Text("Hedieaty"),
          SizedBox(width: 10,),
          Icon(Icons.wallet_giftcard_outlined)
        ],),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              user us = user('', '', '', '', '', 0);
              await us.setLogged(widget.userid, 0);
              instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => login()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildFriendsList()),
          _buildCreateEventButton(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Addfriend(userid: widget.userid)),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueAccent, Colors.lightBlueAccent],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        children: [
          GestureDetector(
            key: Key('myProfileButton'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MyProfilePage(userId: widget.userid)),
              );
            },
            child: CircleAvatar(
              radius: 40,
              backgroundImage: AssetImage('lib/assets/images/myuser.png'),
              backgroundColor: Colors.white,
            ),
          ),
          SizedBox(width: 16),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MyProfilePage(userId: widget.userid)),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Bounce(
                  infinite: true,
                  duration: Duration(seconds:2),
                  child: Text(
                    loggedUser.name.isNotEmpty ? loggedUser.name : "Loading...",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  loggedUser.email,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsList() {
    if (friendslist.isEmpty) {
      return Center(
        child: Text(
          "No friends found.",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    } else {
      return ListView.builder(
        itemCount: friendslist.length,
        itemBuilder: (context, index) {
          return FadeInUp(
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: AssetImage('lib/assets/images/user.png'),
                  backgroundColor: Colors.white70,
                ),
                title: Text('${friendslist[index].name}'),
                subtitle: Text('Phone: ${friendslist[index].phonenumber}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventListPage(
                          friendid: friendslist[index].id, userid: widget.userid),
                    ),
                  );
                },
              ),
            ),
          );
        },
      );
    }
  }

  Widget _buildCreateEventButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
      child: ElevatedButton.icon(
        key: Key('eventButton'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),


        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventFormPage(
                ev: null,
                userId: widget.userid,
              ),
            ),
          );
        },
        icon: Icon(Icons.add),
        label: Text("Create Your Own Event/List"),
      ),
    );
  }
}
