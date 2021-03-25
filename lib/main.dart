// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ! Better comments definitions
// * used for sectioning the code

// * dart internals
import 'dart:async';
import 'dart:developer';
import 'dart:io';
import "package:provider/provider.dart";

// * styling packages
import 'package:flutter/material.dart';

// * imported packages
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:timetracker/usageNotifier.dart';
import 'package:charts_common/common.dart' as common;

// * own packages
import "classes.dart";
import 'pie.dart';

// * config constants
const DELAY = 1;
Database database;
List<Use> uses;
Map<String, ProcStats> stats;

void main() async {
  database = await setUpDatabase();
  uses = await Use.loadFromDatabase(database);
  stats = ProcStats.multipleFromUses(uses);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Timetracker',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Timetracker'),
        ),
        body: Container(
          child: ChangeNotifierProvider(
            create: (context) => UsageNotifier(stats),
            child: Column(
              children: [
                CurrentApp(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PieChartWidget(),
                    AppUsage()
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CurrentApp extends StatefulWidget {
  @override
  _CurrentAppState createState() => _CurrentAppState();
}

class _CurrentAppState extends State<CurrentApp> {
  String _currentApp = "";
  String _currentProcess = "";
  UsageNotifier notifier;

  // * Reads and saves current app every 10 seconds
  @override
  void initState() {
    Timer.periodic(Duration(seconds: DELAY), (timer) {
      if (!this.mounted) {
        return;
      }

      // * Setting the state of the app
      setState(() {
        _currentApp =
            Process.runSync("xdotool", ["getwindowfocus", "getwindowname"])
                .stdout;

        // * Get process PID
        int processPid = int.parse(Process.runSync(
          "xdotool",
          ["getwindowfocus", "getwindowpid"],
        ).stdout);

        _currentProcess =
            Process.runSync("ps", ["-p", processPid.toString(), "-o", "comm="])
                .stdout;
      });

      // * Saving into db
      //Create the object
      Use use = Use(
          appName: _currentApp,
          processName: _currentProcess,
          useStart: DateTime.now().millisecondsSinceEpoch - DELAY * 1000,
          useEnd: DateTime.now().millisecondsSinceEpoch);

      insertUse(use, database);

      // * add new use to uses
      uses.add(use);

      // * add new use to stats
      notifier.updateStats(use);
    });
  }

  @override
  Widget build(BuildContext context) {
    notifier = Provider.of<UsageNotifier>(context);

    if (_currentApp.isEmpty) {
      _currentApp = "No Application";
    }

    return Align(
        alignment: Alignment.topCenter,
        child: Container(
          child: Column(
            children: [
              Column(
                children: [
                  Text("Application: $_currentApp"),
                  Text("Process: $_currentProcess")
                ],
              )
            ],
          ),
          color: Colors.amber,
        ));
  }
}

class AppUsage extends StatefulWidget {
  final state = _AppUsageState();

  @override
  _AppUsageState createState() => state;
}

class _AppUsageState extends State<AppUsage> {
  List<Widget> _gridItems = <Widget>[];

  @override
  Widget build(BuildContext context) {
    final notifier = Provider.of<UsageNotifier>(context);
    final stats = notifier.stats;

    _gridItems = [];
    stats.forEach((key, value) {
      _gridItems.add(AppUsageSingle(stat: value));
    });

    return SizedBox(
      height: 600,
      width: 600,
      child: GridView.count(
        crossAxisCount: 4,
        children: _gridItems,
      ),
    );
  }
}

class AppUsageSingle extends StatefulWidget {
  ProcStats stat;
  AppUsageSingle({this.stat});
  @override
  _AppUsageSingleState createState() => _AppUsageSingleState();
}

class _AppUsageSingleState extends State<AppUsageSingle> {
  @override
  Widget build(BuildContext context) {
    int minutes = widget.stat.totalTime.inMinutes % 60;
    int seconds = widget.stat.totalTime.inSeconds % 60;
    return Container(
        color: Colors.lime,
        margin: EdgeInsets.all(16),
        child: Center(
            child: Column(children: [
          Text("Process: ${widget.stat.processName}"),
          Text("Application: ${widget.stat.appName}"),
          Text(
              "Total time: ${widget.stat.totalTime.inHours}h ${minutes}m ${seconds}s")
        ])));
  }
}
