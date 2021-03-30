import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import "classes.dart";

class UsageNotifier with ChangeNotifier {
  Future<Map<String, ProcStats>> _stats;
  Future<List<Use>> uses;
  Future<Database> _db;

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
