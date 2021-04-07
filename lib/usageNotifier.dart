import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import "classes.dart";

class UsageNotifier with ChangeNotifier {
  Future<Map<String, ProcStats>> _stats;
  Future<List<Use>> uses;
  Future<Database> _db;

  Future<Map<String, String>> get settings => loadSettings(db);

  void updateSettings (String key, String value) async {
    var awaited_db = await db;
    awaited_db.update("appSettings", {"value": value}, where: "key = ?", whereArgs: [key]);
  }
  
  String selectedTimerange = "all";
  String selectedTextFilter = "";

  bool isActive = false;
  bool isBreak = false;

  Future<Map<String, ProcStats>> get stats => _stats;

  Future<Database> get db {
    return _db;
  }

  set stats(Future<Map<String, ProcStats>> newStats) {
    _stats = newStats;
    notifyListeners();
  }


  UsageNotifier() {
    this._db = setUpDatabase();
    this.uses = Use.loadFromDatabase(db);
    this.stats = ProcStats.multipleFromUses(uses);
  }

  Future<Map<String, String>> loadSettings(Future<Database> db) async {
    Map<String, String> settings = {};
    var query = await ((await db).query("appSettings"));
    for (var entry in query){
      settings[entry["key"]] = entry["value"];
    }

    return settings;
  }

  static DateTimeRange rangeFromString(String str) {
    switch(str) {
      // * since the start of the day
      case "today": {
        return DateTimeRange(start: DateTime.now().subtract(Duration(hours: DateTime.now().hour)), end: DateTime.now());
      }
      break;

      case "all": {
        return DateTimeRange(start: DateTime.fromMillisecondsSinceEpoch(0), end: DateTime.now());
      }
      break;

      case "month": {
        return DateTimeRange(start: DateTime.now().subtract(Duration(days: 30)), end: DateTime.now());
      }
      break;

      case "week": {
        return DateTimeRange(start: DateTime.now().subtract(Duration(days: 7)), end: DateTime.now());
      }
      break;

      case "day": {
        return DateTimeRange(start: DateTime.now().subtract(Duration(days: 1)), end: DateTime.now());
      }
      break;

      default: {
        return DateTimeRange(start: DateTime.fromMillisecondsSinceEpoch(0), end: DateTime.now());
      }
    }
  }

  void reloadStats({String timerangeFilter, String textFilter}) async {

    // * time-range filter filter by time of uses
    if (timerangeFilter != null) {
      selectedTimerange = timerangeFilter;
    }

    // * text filter by checking if process contains string
    if (textFilter != null) {
      selectedTextFilter = textFilter;
    }
    // * if no text filter, ignore
    if (selectedTextFilter != "") {
      _stats = ProcStats.multipleFromUses(uses, timeRange: rangeFromString(selectedTimerange), textFilter: textFilter);
    } else {
      _stats = ProcStats.multipleFromUses(uses, timeRange: rangeFromString(selectedTimerange));
    }

    notifyListeners();
  }

  void updateStats(Use use) async {
    (await _stats)
        .putIfAbsent(
            use.processName,
            () => ProcStats(
                processName: use.processName,
                totalTime: Duration()))
        .totalTime += Duration(milliseconds: (use.useEnd - use.useStart));
    
    _stats.then((value) => value[use.processName].updateAppStats(use));
    notifyListeners();
  }

}
