import 'package:flutter/material.dart';
import 'package:timetracker/sideNavigation.dart';
import 'package:timetracker/usageNotifier.dart';
import "package:provider/provider.dart";
import 'package:sqflite/sqflite.dart';

import 'classes.dart';
import 'package:timetracker/pie.dart';

import 'dart:async';
import 'dart:developer';
import 'dart:io';

// * constants definitions
const DELAY = 1;

class Home extends StatelessWidget {
  const Home({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        children: [
          SideNavigation(),
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [Column(
                    children: [
                      PieChartWidget(),
                      BreakButton()
                    ],
                  ), AppUsage()],
                )
              ],
            ),
          ),
        ],
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
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      var notifier = Provider.of<UsageNotifier>(context, listen: false);
      Future<Database> database = notifier.db;
      Future<List<Use>> uses = notifier.uses;

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

          _currentProcess = Process.runSync(
              "ps", ["-p", processPid.toString(), "-o", "comm="]).stdout;
          
          // * clean newlines from end
          _currentApp = _currentApp.replaceAll("\n", "");
          _currentProcess = _currentProcess.replaceAll("\n", "");
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
        uses.then((value) => value.add(use));

        // * add new use to stats
        notifier.updateStats(use);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    notifier = Provider.of<UsageNotifier>(context);

    if (_currentApp.isEmpty) {
      _currentApp = "No Application";
    }

    return Container(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(child: Text.rich(TextSpan(text : "Application: $_currentApp"), textAlign: TextAlign.center)),
          SizedBox(width: 50,),
          Center(child: Text.rich(TextSpan(text: "Process: $_currentProcess"), textAlign: TextAlign.center))
        ],
      ),
    );
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

    return FutureBuilder<Map<String, ProcStats>>(
        future: stats,
        builder: (context, snapshot) {
          _gridItems = [];
          //Sorted keys from stats
          if (snapshot.hasData) {
            var statsValue = snapshot.data.values.toList();

            //b, a -> descending
            //a, b -> ascending
            statsValue.sort((b, a) => a.totalTime.compareTo(b.totalTime));
            statsValue.forEach((value) {
              _gridItems.add(AppUsageSingle(stat: value));
            });
          } else {
            return Text("Loading data");
          }

          return SizedBox(
            height: MediaQuery.of(context).size.height - 56,
            width: MediaQuery.of(context).size.width/2,
            child: GridView.count(
              crossAxisCount: (MediaQuery.of(context).size.width/250).toInt(), // 2 * 100
              children: _gridItems,
              shrinkWrap: true,
            ),
          );
        });
  }
}

class AppUsageSingle extends StatefulWidget {
  final ProcStats stat;

  AppUsageSingle({this.stat});

  @override
  _AppUsageSingleState createState() => _AppUsageSingleState();
}

class _AppUsageSingleState extends State<AppUsageSingle> {
  @override
  Widget build(BuildContext context) {
    int minutes = widget.stat.totalTime.inMinutes % 60;
    int seconds = widget.stat.totalTime.inSeconds % 60;
    return Padding(
      padding: EdgeInsets.all(10),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return this.widget.stat.appStatsPage();
          }));
        },
        child: Container(
            child: Center(
                child: Column(children: [
          Text("Process: ${widget.stat.processName}"),
          Text(
              "Total time: ${widget.stat.totalTime.inHours}h ${minutes}m ${seconds}s")
        ]))),
      ),
    );
  }
}
