
import 'package:hediaty_final/services/sql_db.dart';

class friend {
  late int _id;
  late int _user_id;
  late int _friend_id;

  sqflite_database database = sqflite_database();

  friend(this._user_id,this._friend_id);
  friend.withid(this._id, this._user_id,this._friend_id);

  int get id => _id;
  int get user_id => _user_id;
  int get friend_id => _friend_id;



  factory friend.objectfrommap(Map<String, dynamic> map) {
    return friend.withid(
      map['id'] ,
      map['User_ID'] ?? 0,
      map['Friend_ID'] ?? 0,
    );
  }

  Map<String, dynamic> tomap() {
    var map = Map<String, dynamic>();

    if (id != null) {
      map['id'] = _id;
    }
    map['User_ID']= _user_id ;
    map['Friend_ID']= _friend_id ;

    return map;
  }

  Future<List<friend>> getfriends() async {
    List<friend> friendslist = [];
    List<Map<String, dynamic>> response = await database.readdata("SELECT * FROM 'Friends'");

    for (var row in response) {
      try {
        // Convert each row to a user object and add it to the list
        friendslist.add(friend.objectfrommap(row));
      } catch (e) {
        print("Error parsing friend: $e"); // Log parsing errors for debugging
      }
    }
    return friendslist; // Return the list of user objects
  }

  deleteAllfriends() async {

    int response = await database.deletedata('DELETE FROM Friends');
    if(response !=0){
      print("All Friends deleted successfully.");
    }
    else{
      print("error ======= in deleting");
    }

  }

  Future<int> insertfriend(int user_id, int friend_id) async {
    // Check if the relationship already exists
    List<Map<String, dynamic>> response = await database.readdata(
        "SELECT * FROM 'Friends' WHERE User_ID = $user_id AND Friend_ID = $friend_id"
    );

    if (response.isEmpty) {
      // Insert if not exists
      int result = await database.insertdata(
          "INSERT INTO 'Friends' ('User_ID','Friend_ID') VALUES ('$user_id', '$friend_id')"
      );
      if (result != 0) {
        print("Friend relationship added successfully with row = $result");
        return result;
      } else {
        print("Error in adding friend relationship");
        return 0;
      }
    } else {
      print("Friend relationship already exists in the database.");
      return 0;
    }
  }

//
  // // Function to get a user by phone number
  // Future<user?> getUserByPhoneNumber(String phoneNumber) async {
  //   List<Map<String, dynamic>> response = await database.readdata(
  //       "SELECT * FROM 'Users' WHERE phonenumber = '$phoneNumber'"
  //   );
  //
  //   if (response.isNotEmpty) {
  //     return user.objectfrommap(response[0]);
  //   } else {
  //     print("No user found with the phone number $phoneNumber");
  //     return null;
  //   }
  // }
}
