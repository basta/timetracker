import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:timetracker/sideNavigation.dart';
import 'package:timetracker/theme.dart';
import 'package:timetracker/usageNotifier.dart';
import "package:provider/provider.dart";
import 'package:sqflite/sqflite.dart';
import "package:collection/collection.dart";
import 'package:timetracker/usageNotifier.dart';

import 'classes.dart';
import 'package:timetracker/pie.dart';

import 'dart:async';
import 'dart:developer';
import 'dart:io';

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
                                    decoration: BoxDecoration(
                                        border: Border(
                                            right: BorderSide(color: Theme.of(context).colorScheme.primary, width: 5))),
                                    width: constraints.maxWidth / 2,
                                    child: PieChartWidget()),
                              ),
                            ],
                          ),
                          SizedBox(
                              height: constraints.maxHeight,
                              width: constraints.maxWidth / 2,
                              child: AppUsageContainer())
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
  List<int> _lastMousePos = [0, 0];
  DateTime _lastMouseMovement;
  bool _isActive = true;

  UsageNotifier notifier;

  // * Reads and saves current app every 10 seconds
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      var notifier = Provider.of<UsageNotifier>(context, listen: false);
      var settings = await notifier.settings;
      var activityDelay = int.parse(settings["detectionInterval"]);
      var mouseDelay = int.parse(settings["mouseDelay"]);

      Future<Database> database = notifier.db;
      Future<List<Use>> uses = notifier.uses;

      Timer.periodic(Duration(seconds: activityDelay), (timer) {
        if (!this.mounted) {
          return;
        }

        // * Check for activity
        print(Process.runSync("xdotool", ["getmouselocation"]).stderr);
        String mouseLocationString = Process.runSync("xdotool", ["getmouselocation"]).stdout;
        // Parse mouse location string
        var mouseLocationList = mouseLocationString.split(" ");
        var x = mouseLocationList[0];
        var y = mouseLocationList[1];
        List<int> mousePos = [int.parse(x.split(":")[1]), int.parse(y.split(":")[1])];

        // * Update mouse info and if inactivity too long, stop tracking
        if (!ListEquality().equals(mousePos, _lastMousePos)) {
          _lastMousePos = mousePos;
          _lastMouseMovement = DateTime.now();
        } else if (_lastMouseMovement.difference(DateTime.now()).inSeconds < -mouseDelay) {
          setState(() {
            _isActive = false;
          });
          notifier.isActive = false;
          return;
        }

        // * Setting the state of the app
        setState(() {
          _isActive = true;
          notifier.isActive = true;

          _currentApp = Process.runSync("xdotool", ["getwindowfocus", "getwindowname"]).stdout;

          // * Get process PID
          int processPid = int.parse(Process.runSync(
            "xdotool",
            ["getwindowfocus", "getwindowpid"],
          ).stdout);

          _currentProcess = Process.runSync("ps", ["-p", processPid.toString(), "-o", "comm="]).stdout;

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
              useStart: DateTime.now().millisecondsSinceEpoch - activityDelay * 1000,
              useEnd: DateTime.now().millisecondsSinceEpoch);

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

    // Widget for showing if app detects presence of a user
    Widget activityWidget;
    if (_isActive) {
      activityWidget =
          Text.rich(TextSpan(text: "ACTIVE"), style: TextStyle(color: Colors.green), textAlign: TextAlign.center);
    } else {
      activityWidget =
          Text.rich(TextSpan(text: "AWAY"), style: TextStyle(color: Colors.red), textAlign: TextAlign.center);
    }

    return Container(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: activityWidget,
          ),
          SizedBox(
            width: 50,
          ),
          Center(child: Text.rich(TextSpan(text: "Application: $_currentApp"), textAlign: TextAlign.center)),
          SizedBox(
            width: 50,
          ),
          Center(child: Text.rich(TextSpan(text: "Process: $_currentProcess"), textAlign: TextAlign.center))
        ],
      ),
    );
  }
}

class AppUsageContainer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppUsageHeader(),
        Expanded(child: AppUsage()),
        //AppUsageFooter()
      ],
    );
  }
}

class AppUsageFooter extends StatelessWidget {
  const AppUsageFooter({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primaryVariant,
      height: 50,
      child: Row(
        children: [],
      ),
    );
  }
}

class AppUsageHeader extends StatelessWidget {
  const AppUsageHeader({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primaryVariant,
      height: 50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Text(
              "Most used processes",
              style: Theme.of(context).textTheme.headline5,
            ),
            Expanded(child: TimeRangePicker()),
            Expanded(
                child: Container(
              height: 25,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        Provider.of<UsageNotifier>(context, listen: false).reloadStats(textFilter: value);
                      },
                      decoration: InputDecoration(border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                    ),
                  ),
                  Icon(
                    Icons.search,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ],
              ),
            ))
          ],
        ),
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
          Widget content;
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
            content = Center(child: Text("Loading data"));
          }

          return GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width ~/ 300, // 2 * 100
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

    TextTheme textTheme = Theme.of(context).textTheme;
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: EdgeInsets.all(10),
      child: Container(
          color: Theme.of(context).colorScheme.primary,
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
                      child: Text("$hours", style: textTheme.bodyText2.copyWith(fontSize: 19)),
                    ),
                    Text(
                      ":",
                      style: textTheme.bodyText2,
                    ),
                    Container(
                      padding: EdgeInsets.all(2),
                      color: colorScheme.secondary,
                      margin: EdgeInsets.symmetric(horizontal: 2),
                      child: Text("$minutes", style: textTheme.bodyText2.copyWith(fontSize: 19)),
                    ),
                    Text(":", style: textTheme.bodyText2),
                    Container(
                      padding: EdgeInsets.all(2),
                      color: colorScheme.secondary,
                      margin: EdgeInsets.symmetric(horizontal: 2),
                      child: Text("$seconds", style: textTheme.bodyText2.copyWith(fontSize: 19)),
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
                            Navigator.push(
                                context,
                                PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) =>
                                        this.widget.stat.appStatsPage(),
                                    transitionDuration: Duration(seconds: 0)));
                          }),
                      IconButton(color: colorScheme.onPrimary, icon: Icon(Icons.show_chart), onPressed: () {}),
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

class TimeRangePicker extends StatefulWidget {
  @override
  _TimeRangePickerState createState() => _TimeRangePickerState();
}

class _TimeRangePickerState extends State<TimeRangePicker> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10),
      height: 20,
      decoration: BoxDecoration(
          border: Border(
        top: BorderSide(width: 2, color: Theme.of(context).colorScheme.onSecondary),
        bottom: BorderSide(width: 2, color: Theme.of(context).colorScheme.onSecondary),
        left: BorderSide(width: 2, color: Theme.of(context).colorScheme.onSecondary),
      )),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          TimeRangePickerButton(label: "today"),
          TimeRangePickerButton(
            label: "week",
          ),
          TimeRangePickerButton(
            label: "month",
          ),
          TimeRangePickerButton(
            label: "all",
          ),
          // TODO: implement custom time range picker
          // TimeRangePickerButton(
          //   label: "custom",
          // ),
        ],
      ),
    );
  }
}

// ignore: must_be_immutable
class TimeRangePickerButton extends StatefulWidget {
  final String label;
  final Function() onPressedExtension;

  TimeRangePickerButton({this.label, this.onPressedExtension});

  @override
  _TimeRangePickerButtonState createState() => _TimeRangePickerButtonState();
}

class _TimeRangePickerButtonState extends State<TimeRangePickerButton> {
  @override
  Widget build(BuildContext context) {
    // * get decorations based on being selected
    BoxDecoration defaultDecorations =
        BoxDecoration(border: Border(right: BorderSide(width: 2, color: Theme.of(context).colorScheme.onSecondary)));
    BoxDecoration decoration;
    if (this.widget.label == Provider.of<UsageNotifier>(context).selectedTimerange) {
      decoration = defaultDecorations.copyWith(color: Theme.of(context).colorScheme.primary);
    } else {
      decoration = defaultDecorations.copyWith(color: Theme.of(context).colorScheme.secondary);
    }
    return Expanded(
      flex: 1,
      child: TextButton(
          onPressed: () {
            Provider.of<UsageNotifier>(context, listen: false).reloadStats(timerangeFilter: this.widget.label);
            //this.widget.onPressedExtension();
          },
          child: Container(
            width: double.infinity,
            height: double.infinity,
            child: Center(
                child: Text(
              this.widget.label,
              style: Theme.of(context).textTheme.bodyText1,
            )),
            decoration: decoration,
          )),
    );
  }
}
