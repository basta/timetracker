import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:timetracker/sideNavigation.dart';
import 'package:timetracker/theme.dart';
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
                Expanded(
                  child: LayoutBuilder(builder: (context, constraints) {
                    return Container(
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Expanded(
                                child: Container(
                                    width: constraints.maxWidth / 2,
                                    child: PieChartWidget()),
                              ),
                              BreakButton()
                            ],
                          ),
                          SizedBox(
                              height: constraints.maxHeight,
                              width: constraints.maxWidth / 2,
                              child: AppUsage())
                        ],
                      ),
                    );
                  }),
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
  final bool isTracking;

  CurrentApp({this.isTracking = false});

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
              Process
                  .runSync("xdotool", ["getwindowfocus", "getwindowname"])
                  .stdout;

          // * Get process PID
          int processPid = int.parse(Process
              .runSync(
            "xdotool",
            ["getwindowfocus", "getwindowpid"],
          )
              .stdout);

          _currentProcess = Process
              .runSync(
              "ps", ["-p", processPid.toString(), "-o", "comm="])
              .stdout;

          // * clean newlines from end
          _currentApp = _currentApp.replaceAll("\n", "");
          _currentProcess = _currentProcess.replaceAll("\n", "");
        });

        // * Saving into db if widget is used for tracking
        //Create the object
        if (this.widget.isTracking) {
          Use use = Use(
              appName: _currentApp,
              processName: _currentProcess,
              useStart: DateTime
                  .now()
                  .millisecondsSinceEpoch - DELAY * 1000,
              useEnd: DateTime
                  .now()
                  .millisecondsSinceEpoch);

          insertUse(use, database);

          // * add new use to uses
          uses.then((value) => value.add(use));

          // * add new use to stats
          notifier.updateStats(use);
        }
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
          Center(
              child: Text.rich(TextSpan(text: "Application: $_currentApp"),
                  textAlign: TextAlign.center)),
          SizedBox(
            width: 50,
          ),
          Center(
              child: Text.rich(TextSpan(text: "Process: $_currentProcess"),
                  textAlign: TextAlign.center))
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

          return GridView.count(
            crossAxisCount: MediaQuery
                .of(context)
                .size
                .width ~/ 300, // 2 * 100
            children: _gridItems,
            shrinkWrap: true,
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
    String hours = (widget.stat.totalTime.inHours % 60).toString();
    if (hours.length < 2) {
      hours = "0" + hours;
    }

    String minutes = (widget.stat.totalTime.inMinutes % 60).toString();
    if (minutes.length < 2) {
      minutes = "0" + minutes;
    }

    String seconds = (widget.stat.totalTime.inSeconds % 60).toString();
    if (seconds.length < 2) {
      seconds = "0" + seconds;
    }

    TextTheme textTheme = Theme
        .of(context)
        .textTheme;
    ColorScheme colorScheme = Theme
        .of(context)
        .colorScheme;
    return Container(
      margin: EdgeInsets.all(10),
      child: Container(
          color: Theme
              .of(context)
              .colorScheme
              .primary,
          child: Center(
              child: Column(children: [
                Text(
                  "Process:",
                  style: textTheme.caption,
                ),
                Container(
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(horizontal: 10),
                    padding: EdgeInsets.symmetric(vertical: 5),
                    color: colorScheme.secondary,
                    child: Center(
                      child: Text(
                        "${widget.stat.processName}",
                        style: textTheme.bodyText2,
                      ),
                    )),
                Container(
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(horizontal: 10),
                    padding: EdgeInsets.symmetric(vertical: 5),
                    child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: EdgeInsets.all(2),
                              color: colorScheme.secondary,
                              margin: EdgeInsets.symmetric(horizontal: 2),
                              child: Text("$hours",
                                  style: textTheme.bodyText2.copyWith(
                                      fontSize: 19)),
                            ),
                            Text(
                              ":",
                              style: textTheme.bodyText2,
                            ),
                            Container(
                              padding: EdgeInsets.all(2),
                              color: colorScheme.secondary,
                              margin: EdgeInsets.symmetric(horizontal: 2),
                              child: Text("$minutes",
                                  style: textTheme.bodyText2.copyWith(
                                      fontSize: 19)),
                            ),
                            Text(":", style: textTheme.bodyText2),
                            Container(
                              padding: EdgeInsets.all(2),
                              color: colorScheme.secondary,
                              margin: EdgeInsets.symmetric(horizontal: 2),
                              child: Text("$seconds",
                                  style: textTheme.bodyText2.copyWith(
                                      fontSize: 19)),
                            )
                          ],
                        ))),
                Expanded(
                  child: FittedBox(
                    child: Container(
                      alignment: Alignment.bottomCenter,
                      margin: EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                              icon: Icon(Icons.read_more),
                              color: colorScheme.onPrimary,
                              onPressed: () {
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) {
                                      return this.widget.stat.appStatsPage();
                                    }));
                              }),
                          IconButton(
                              color: colorScheme.onPrimary,
                              icon: Icon(Icons.show_chart),
                              onPressed: () {}),
                          IconButton(
                              color: colorScheme.onPrimary,
                              icon: Icon(
                                Icons.close,
                              ),
                              onPressed: () {}),
                        ],
                      ),
                    ),
                  ),
                )
              ]))),
    );
  }
}
