import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:path/path.dart';
import "package:flutter/widgets.dart";

// * A single record for db of n seconds of usage
class Use {
  String processName;
  String appName;
  int useStart;
  int useEnd;

  Use({this.processName, this.appName, this.useStart, this.useEnd});

  Map<String, dynamic> toMap() {
    return {
      "processName": processName,
      "appName": appName,
      "startTime": useStart,
      "endTime": useEnd
    };
  }

  static Use fromDbRow(Map<String, Object> row) {
    return new Use(
        appName: row["appName"],
        processName: row["processName"],
        useStart: row["startTime"],
        useEnd: row["endTime"]);
  }

  static Future<List<Use>> loadFromDatabase(Database db) async {
    var iterator = (await db.query("useHistory")).iterator;
    List<Use> uses = [];

    while (iterator.moveNext()) {
      var row = iterator.current;
      uses.add(Use.fromDbRow(row));
    }

    return uses;
  }
}

// * Used for inserting a Use to db
Future<void> insertUse(Use use, Database database) async {
  final Database db = await database;

  await db.insert("useHistory", use.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace);
}

Future<Database> setUpDatabase() async {
  WidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  var databaseFactory = databaseFactoryFfi;
  final Future<Database> database =
      databaseFactory.openDatabase("assets/db.sqlite");

  // * create database if it doesn't exist
  (await database).execute("""
      CREATE TABLE "useHistory" (
      \"startTime\"	NUMERIC NOT NULL,
      \"endTime\"	NUMERIC NOT NULL,
      \"processName\"	TEXT,
      \"appName\"	TEXT,
      \"id\"	INTEGER,
      PRIMARY KEY(\"id\" AUTOINCREMENT))
      """);
  print("Creating database...");

  return database;
}
// return db.execute("""
//       CREATE TABLE "useHistory" (
//       \"startTime\"	NUMERIC NOT NULL,
//       \"endTime\"	NUMERIC NOT NULL,
//       \"processName\"	TEXT,
//       \"appName\"	TEXT,
//       \"id\"	INTEGER,
//       PRIMARY KEY(\"id\" AUTOINCREMENT))
//       """);

class ProcStats {
  String appName;
  String processName;
  Duration totalTime;

  // TODO: Not yet implemented
  Duration lastDayTime;
  Duration lastWeekTime;

  ProcStats({this.appName, this.processName, this.totalTime});

  static Map<String, ProcStats> multipleFromUses(List<Use> uses) {
    Map<String, ProcStats> stats = {};

    uses.forEach((use) {
      String process = use.processName;
      stats
          .putIfAbsent(
              process,
              () => ProcStats(
                  appName: "TODO",
                  processName: use.processName,
                  totalTime: Duration()))
          .totalTime += Duration(milliseconds: (use.useEnd - use.useStart));
    });

    return stats;
  }
}