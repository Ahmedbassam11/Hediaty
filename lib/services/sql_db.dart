import 'package:hediaty_final/Models/Users.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';

class sqflite_database {

  static Database? _db=null;

  Future<Database?> get db async {
    if(_db==null){
      _db= await initialdb();
      return _db;
    }
    else{
         return _db;
    }
  }

initialdb() async{
  String db_path = await getDatabasesPath();
  String path = join(db_path,'hediaty.db');
  Database mydb = await openDatabase(path , onCreate: _oncreate,version: 6,onUpgrade: _onupgrade);
  return mydb;
}
_onupgrade(Database db ,int oldversion, int newversion) async{

  print("===============DATABASE UPGRADED TO INCLUDE user_id COLUMN==============");




    print("===============on upgrade==============");
}
_oncreate(Database db ,int version) async{
  await db.execute('''
  CREATE TABLE "Users" (
  "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  "name" TEXT,
  "email" TEXT,
  "preferences" TEXT,
  "phonenumber" TEXT,
  "password" TEXT ,
  "logged"  INTEGER
  )
  ''');

  await db.execute('''
  CREATE TABLE "Events" (
  "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  "name" TEXT,
  "date" TEXT,
  "location" TEXT,
  "description" TEXT,
  "user_ID" INTEGER,
  FOREIGN KEY (user_ID) REFERENCES Users(id)
  )
  ''');

  await db.execute('''
  CREATE TABLE "Gifts" (
  "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  "name" TEXT,
  "description" TEXT,
  "category" TEXT,
  "price"  DOUBLE,
  "status" TEXT,
  "event_ID" INTEGER,
  "user_id"  INTEGER,
  FOREIGN KEY (event_ID) REFERENCES Events(id),
  FOREIGN KEY (user_id) REFERENCES Users(id) ON DELETE SET NULL
  

  )
  ''');

  await db.execute('''
  CREATE TABLE "Friends" (
  "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  "User_ID" INTEGER,
  "Friend_ID" INTEGER,
  FOREIGN KEY (User_ID) REFERENCES Users(id),
  FOREIGN KEY (Friend_ID) REFERENCES Users(id)
  
  )
  ''');
print("===============DATABASE CREATED SUCCESSFULLY====================");
}

readdata(String sql) async{
    Database? mydb = await db;
    List<Map> response= await mydb!.rawQuery(sql);
          return response;
}
  insertdata(String sql) async{
    Database? mydb = await db;
    int response= await mydb!.rawInsert(sql);
    return response;
  }

  updatedata(String sql) async{
    Database? mydb = await db;
    int response= await mydb!.rawUpdate(sql);
    return response;
  }

  deletedata(String sql) async{
    Database? mydb = await db;
    int response= await mydb!.rawDelete(sql);
    return response;
  }


}

