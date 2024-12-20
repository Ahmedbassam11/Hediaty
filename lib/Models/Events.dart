import 'package:hediaty_final/services/sql_db.dart';

class event {
  late int _id;
  late String _name;
  late String _date;
  late String _location;
  late String _description;
  late int _user_id;
  sqflite_database database = sqflite_database();

  // Constructors
  event(this._name, this._date, this._location, this._description, this._user_id);
  event.withid(this._id, this._name, this._date, this._location, this._description, this._user_id);

  // Getters
  int get id => _id;
  String get name => _name;
  String get date => _date;
  String get location => _location;
  String get description => _description;
  int get user_id => _user_id;

  // Setters
  set name(String newname) => _name = newname;
  set date(String newdate) => _date = newdate;
  set location(String newlocation) => _location = newlocation;
  set description(String newdescription) => _description = newdescription;

  // Convert object to map
  Map<String, dynamic> tomap() {
    var map = Map<String, dynamic>();
    if (id != null) {
      map['id'] = _id;
    }
    map['name'] = _name;
    map['date'] = _date;
    map['location'] = _location;
    map['description'] = _description;
    map['user_ID'] = _user_id;
    return map;
  }

  // Create an object from a map
  factory event.objectfrommap(Map<String, dynamic> map) {
    return event.withid(
      map['id'],
      map['name'] ?? '',
      map['date'] ?? '',
      map['location'] ?? '',
      map['description'] ?? '',
      map['user_ID'],
    );
  }

  // Fetch all events
  Future<List<event>> getevents() async {
    List<event> eventslist = [];
    List<Map<String, dynamic>> response = await database.readdata("SELECT * FROM 'Events'");

    for (var row in response) {
      try {
        eventslist.add(event.objectfrommap(row));
      } catch (e) {
        print("Error parsing event: $e");
      }
    }
    return eventslist;
  }

  // Insert a new event
  Future<void> insertevent(String name, String date, String location, String description, int user_id) async {
    int response = await database.insertdata(
        "INSERT INTO 'Events' ('name','date','location','description','user_ID') VALUES ('$name', '$date', '$location', '$description', '$user_id')");
    if (response != 0) {
      print("======== Event added successfully ========");
    } else {
      print("======== Error in adding event ========");
    }
  }

  // Delete an event by ID
  Future<void> deleteEvent(int eventId) async {
    try {
      int response = await database.deletedata("DELETE FROM 'Events' WHERE id = $eventId");
      if (response != 0) {
        print("======== Event deleted successfully ========");
      } else {
        print("======== Error: No event found with ID: $eventId ========");
      }
    } catch (e) {
      print("Error deleting event: $e");
    }
  }

  // Update an existing event
  Future<int> updateEvent() async {
    try {
      String query = '''
      UPDATE 'Events'
      SET 
        name = '$_name',
        date = '$_date',
        location = '$_location',
        description = '$_description',
        user_ID = $_user_id
      WHERE id = $_id
      ''';

      int response = await database.updatedata(query);
      if (response != 0) {
        print("======== Event updated successfully ========");
      } else {
        print("======== Error: No event found with ID: $_id ========");
      }
      return response;
    } catch (e) {
      print("Error updating event: $e");
      return 0;
    }
  }

  // Fetch a specific event by ID
  Future<event?> getEventById(int id) async {
    try {
      List<Map<String, dynamic>> response = await database.readdata(
          "SELECT * FROM 'Events' WHERE id = '$id'");

      if (response.isNotEmpty) {
        return event.objectfrommap(response[0]);
      } else {
        print("======== No event found with ID: $id ========");
        return null;
      }
    } catch (e) {
      print("Error fetching event: $e");
      return null;
    }
  }
}
