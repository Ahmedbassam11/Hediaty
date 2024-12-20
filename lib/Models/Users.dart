
import 'package:hediaty_final/services/sql_db.dart';
class user {
  late int _id;
  late String _name;
  late String _email;
  late String _preference;
  late String _phonenumber;
  late String _password;
  late int _logged;
  sqflite_database database = sqflite_database();

  user(this._name, this._email, this._preference, this._phonenumber,this._password,this._logged);
  user.withid(this._id, this._name, this._email, this._preference, this._phonenumber,this._password,this._logged);

  int get id => _id;
  String get name => _name;
  String get email => _email;
  String get preference => _preference;
  String get phonenumber => _phonenumber;
  String get password => _password;
  int get logged => _logged;

  set name(String newname) {
    this._name = newname;
  }
  set email(String newemail) {
    this._email = newemail;
  }
  set preference(String newpreference) {
    this._preference = newpreference;
  }
  set phonenumber(String newphonenumber) {
    this._phonenumber = newphonenumber;
  }
set logged(int newlogged){
    this._logged=newlogged;
}
  factory user.objectfrommap(Map<String, dynamic> map) {
    return user.withid(
      map['id'] ,
      map['name'] ?? '',
      map['email'] ?? '',
      map['preferences'] ?? '',
      map['phonenumber'] ?? '',
      map['password'] ?? '',
      map['logged'],
    );
  }

  Map<String, dynamic> tomap() {
    var map = Map<String, dynamic>();

    if (id != null) {
      map['id'] = _id;
    }
    map['name'] = _name;
    map['email'] = _email;
    map['preferences'] = _preference;
    map['phonenumber'] = _phonenumber;
    map['password']= _password;
    map['logged']= _logged;

    return map;
  }

  Future<void> setLogged(int userId, int loggedValue) async {
    try {
      // Update the logged field in the database for the given userId
      int response = await database.updatedata(
          "UPDATE 'Users' SET logged = $loggedValue WHERE id = $userId");
      if (response != 0) {
        print("User's logged status updated successfully.");
      } else {
        print("Error: No user found with the id: $userId.");
      }
    } catch (e) {
      print("Error updating logged status: $e");
    }
  }


  Future<List<user>> getusers() async {
    List<user> userslist = [];
    List<Map<String, dynamic>> response = await database.readdata("SELECT * FROM 'Users'");

    for (var row in response) {
      try {
        // Convert each row to a user object and add it to the list
        userslist.add(user.objectfrommap(row));
      } catch (e) {
        print("Error parsing user: $e"); // Log parsing errors for debugging
      }
    }
    return userslist; // Return the list of user objects
  }


  deleteAllUsers() async {

    int response = await database.deletedata('DELETE FROM Users');
    if(response !=0){
      print("All users deleted successfully.");
    }
    else{
      print("error ======= in deleting");
    }

  }

  Future<int> updateUser() async {
    try {
      // SQL to update user data
      String query = '''
      UPDATE 'Users'
      SET 
        name = '$_name', 
        email = '$_email', 
        preferences = '$_preference', 
        phonenumber = '$_phonenumber'
      WHERE id = $_id
      ''';

      int response = await database.updatedata(query);
      if (response != 0) {
        print("User updated successfully.");
      } else {
        print("Error: No user found with id $_id.");
      }
      return response;
    } catch (e) {
      print("Error updating user: $e");
      return 0;
    }
  }
  Future<List<user>> getfriendswithuserid(int userid) async {
    List<user> friendsList = [];

    // SQL query to get friends of the given userid
    String query = '''
    SELECT u.id, u.name, u.email, u.preferences, u.phonenumber, u.password, u.logged 
    FROM Users u
    JOIN Friends f ON u.id = f.Friend_ID
    WHERE f.User_ID = $userid
  ''';

    // Execute the query
    List<Map<String, dynamic>> response = await database.readdata(query);

    // Parse the response to create a list of user objects
    for (var row in response) {
      try {
        friendsList.add(user.objectfrommap(row));
      } catch (e) {
        print("Error parsing friend data: $e");
      }
    }

    return friendsList;
  }



  insertuser(String name, String email, String preferences, String phonenumber, String password, int logged) async {
    int response = await database.insertdata("INSERT INTO 'Users' ('name','email','preferences','phonenumber','password','logged') VALUES ('$name', '$email', '$preferences', '$phonenumber', '$password','$logged')");
    if (response != 0) {
      print("========added successfully=========");
      return response;
    } else {
      print("========error in adding=========");
    }
  }

  // Function to get a user by phone number
  Future<user?> getUserByPhoneNumber(String phoneNumber) async {
    List<Map<String, dynamic>> response = await database.readdata(
        "SELECT * FROM 'Users' WHERE phonenumber = '$phoneNumber'"
    );

    if (response.isNotEmpty) {
      return user.objectfrommap(response[0]);
    } else {
      print("No user found with the phone number $phoneNumber");
      return null;
    }
  }
  Future<user?> getUserByid(int id) async {
    List<Map<String, dynamic>> response = await database.readdata(
        "SELECT * FROM 'Users' WHERE id = '$id'"
    );

    if (response.isNotEmpty) {
      return user.objectfrommap(response[0]);
    } else {
      print("No user found with the id : $id");
      return null;
    }
  }
}
