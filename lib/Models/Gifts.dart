import 'package:hediaty_final/services/sql_db.dart';

class Gift {
  late int id;
  late String name;
  late String description;
  late String category;
  late double price;
  late String status; // "available" or "pledged"
  late int eventID;
  late int? userId; // New attribute to associate a gift with a user

  sqflite_database database = sqflite_database();

  Gift(this.name, this.description, this.category, this.price, this.status, this.eventID, {this.userId});
  Gift.withId(this.id, this.name, this.description, this.category, this.price, this.status, this.eventID, {this.userId});

  // Factory constructor to map database response to the Gift object.
  factory Gift.fromMap(Map<String, dynamic> map) {
    return Gift.withId(
      map['id'],
      map['name'] ?? '',
      map['description'] ?? '',
      map['category'] ?? '',
      map['price'] ?? 0.0,
      map['status'] ?? 'available',
      map['event_ID'],
      userId: map['user_id'], // Load user ID
    );
  }

  // Convert the Gift object into a map for database operations.
  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{};
    if (id != null) map['id'] = id;
    map['name'] = name;
    map['description'] = description;
    map['category'] = category;
    map['price'] = price;
    map['status'] = status;
    map['event_ID'] = eventID;
    map['user_id'] = userId; // Add user ID to the map
    return map;
  }

  // Insert a new gift into the database.
  Future<int> insertGift() async {
    try {
      int result = await database.insertdata(
        "INSERT INTO 'Gifts' ('name', 'description', 'category', 'price', 'status', 'event_ID', 'user_id') "
            "VALUES ('$name', '$description', '$category', $price, '$status', $eventID, ${userId ?? 'NULL'})",
      );
      print("Gift inserted successfully with ID: $result");
      return result;
    } catch (e) {
      print("Error inserting gift: $e");
      return -1;
    }
  }

  // Update an existing gift in the database.
  Future<int> updateGift() async {
    try {
      int result = await database.updatedata(
        "UPDATE 'Gifts' SET name = '$name', description = '$description', category = '$category', price = $price, "
            "status = '$status', user_id = ${userId ?? 'NULL'} WHERE id = $id",
      );
      print("Gift updated successfully. Rows affected: $result");
      return result;
    } catch (e) {
      print("Error updating gift: $e");
      return -1;
    }
  }

  // Delete a gift from the database.
  Future<int> deleteGift(int id) async {
    try {
      int result = await database.deletedata("DELETE FROM 'Gifts' WHERE id = $id");
      print("Gift deleted successfully. Rows affected: $result");
      return result;
    } catch (e) {
      print("Error deleting gift: $e");
      return -1;
    }
  }

  // Retrieve gifts by event ID.
  Future<List<Gift>> getGiftsByEventID(int eventID) async {
    try {
      List<Map<String, dynamic>> response =
      await database.readdata("SELECT * FROM 'Gifts' WHERE event_ID = $eventID");
      return response.map((giftMap) => Gift.fromMap(giftMap)).toList();
    } catch (e) {
      print("Error retrieving gifts by event ID: $e");
      return [];
    }
  }

  // Pledge or unpledge a gift.
  Future<int> pledgeGift(int giftId, int? userId) async {
    try {
      String status = userId == null ? 'available' : 'pledged';
      int result = await database.updatedata(
        "UPDATE 'Gifts' SET status = '$status', user_id = ${userId ?? 'NULL'} WHERE id = $giftId",
      );
      print("Gift pledge status updated. Rows affected: $result");
      return result;
    } catch (e) {
      print("Error updating pledge status: $e");
      return -1;
    }
  }

  // Get all gifts pledged by a specific user.
  Future<List<Gift>> getPledgedGifts(int userId) async {
    try {
      List<Map<String, dynamic>> response = await database.readdata(
        "SELECT * FROM 'Gifts' WHERE user_id = $userId AND status = 'pledged'",
      );
      return response.map((giftMap) => Gift.fromMap(giftMap)).toList();
    } catch (e) {
      print("Error retrieving pledged gifts: $e");
      return [];
    }
  }

  // Get detailed information about pledged gifts.
  Future<List<Map<String, dynamic>>> getPledgedGiftsWithDetails(int userId) async {
    try {
      String query = '''
      SELECT 
        g.id AS gift_id, g.name AS gift_name, g.description, g.category, g.price, g.status,
        e.id AS event_id, e.name AS event_name, e.date AS event_date, e.location AS event_location,
        u.id AS friend_id, u.name AS friend_name
      FROM Gifts g
      JOIN Events e ON g.event_ID = e.id
      JOIN Users u ON e.user_ID = u.id
      WHERE g.user_id = $userId AND g.status = 'pledged'
      ''';
      List<Map<String, dynamic>> response = await database.readdata(query);
      print("Pledged gifts with details retrieved successfully. Count: ${response.length}");
      return response;
    } catch (e) {
      print("Error retrieving pledged gifts with details: $e");
      return [];
    }
  }
}
