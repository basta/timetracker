import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import "classes.dart";

class UsageNotifier with ChangeNotifier {
  Map<String, ProcStats> _stats;
  List<Use> uses;
  Database db;

  Map<String, ProcStats> startStats;

  Map<String, ProcStats> get stats => _stats;

  set stats(Map<String, ProcStats> newStats) {
    _stats = newStats;
    notifyListeners();
  }

  UsageNotifier() {

  }

  void updateStats(Use use) {
    _stats
        .putIfAbsent(
            use.processName,
            () => ProcStats(
                appName: "TODO",
                processName: use.processName,
                totalTime: Duration()))
        .totalTime += Duration(milliseconds: (use.useEnd - use.useStart));

    notifyListeners();
  }

  UsageNotifier(Map<String, ProcStats> startStats) {
    _stats = startStats;
  }
}
