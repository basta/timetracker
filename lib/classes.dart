import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:path/path.dart';
import "package:flutter/widgets.dart";
import 'package:timetracker/appBar.dart';
import 'package:timetracker/pie.dart';
import 'package:timetracker/sideNavigation.dart';

import 'package:timetracker/usageNotifier.dart';
import 'package:timetracker/classes.dart';

// * A single record for db of n seconds of usage
class Use {
  String processName;
  String appName;
  int useStart;
  int useEnd;

  Use({this.processName, this.appName, this.useStart, this.useEnd});

  Map<String, dynamic> toMap() {
    return {"processName": processName, "appName": appName, "startTime": useStart, "endTime": useEnd};
  }

  static Use fromDbRow(Map<String, Object> row) {
    return new Use(
        appName: row["appName"], processName: row["processName"], useStart: row["startTime"], useEnd: row["endTime"]);
  }

  static Future<List<Use>> loadFromDatabase(Future<Database> dbFuture) async {
    var db = await dbFuture;
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
Future<void> insertUse(Use use, Future<Database> database) async {
  database.then((db) => {db.insert("useHistory", use.toMap(), conflictAlgorithm: ConflictAlgorithm.replace)});
}

Future<Database> setUpDatabase() async {
  sqfliteFfiInit();

  var databaseFactory = databaseFactoryFfi;
  final Future<Database> database = databaseFactory.openDatabase("assets/db.sqlite");

  // * create uses database if it doesn't exist
  try {
    await (await database).execute("""
      CREATE TABLE "useHistory" (
      \"startTime\"	NUMERIC NOT NULL,
      \"endTime\"	NUMERIC NOT NULL,
      \"processName\"	TEXT,
      \"appName\"	TEXT,
      \"id\"	INTEGER,
      PRIMARY KEY(\"id\" AUTOINCREMENT))
      """);
    print("Creating database...");
  } catch (e) {
    print("Use table found");
  }

  // * create settings database if it doesn't exist
  try {
    await ((await database).execute("""
      CREATE TABLE "appSettings" (
      "key" TEXT,
      "value" TEXT,
      PRIMARY KEY("key"))
    """));
  } catch (e) {
    print("Settings table found: $e");
  }

  // * fill settings with default values if empty
  if ((await (await database).query("appSettings")).isEmpty) {
    (await database).insert("appSettings", {"key": "detectionInterval", "value": "1"});
    (await database).insert("appSettings", {"key": "mouseDelay", "value": "60"});
    (await database).insert("appSettings", {"key": "minimalSlice", "value": "5"});
  }
  return database;
}

class ProcStats {
  String processName;
  Duration totalTime;

  Map<String, AppStat> appStats = {};

  // TODO: Not yet implemented
  Duration lastDayTime;
  Duration lastWeekTime;

  ProcStats({this.processName, this.totalTime});

  // * Create a map of ProcStats from uses
  static Future<Map<String, ProcStats>> multipleFromUses(Future<List<Use>> uses,
      {DateTimeRange timeRange, String textFilter}) async {
    Map<String, ProcStats> stats = {};

    (await uses).forEach((use) {
      // * remove uses outside of timeRange
      if (timeRange != null) {
        DateTimeRange useDateTime = DateTimeRange(
            start: DateTime.fromMillisecondsSinceEpoch(use.useStart),
            end: DateTime.fromMillisecondsSinceEpoch(use.useEnd));
        if (timeRange.start.isAfter(useDateTime.start) || timeRange.end.isBefore(useDateTime.end)) {
          return;
        }
      }

      String process = use.processName;

      if (textFilter != null) {
        if (!process.toLowerCase().contains(textFilter.toLowerCase())) {
          return;
        }
      }

      // * create ProcStat
      stats.putIfAbsent(process, () => ProcStats(processName: use.processName, totalTime: Duration())).totalTime +=
          Duration(milliseconds: (use.useEnd - use.useStart));

      // * create AppStats for ProcStat
      stats[process].updateAppStats(use);
    });

    return stats;
  }

  // * Takes a use and adds it to the corresponding AppStat
  void updateAppStats(Use use) {
    appStats.putIfAbsent(use.appName, () => AppStat(appName: use.appName, totalTime: Duration(seconds: 0))).totalTime +=
        Duration(milliseconds: use.useEnd - use.useStart);
  }

  Widget appStatsPage() {
    return AppStatWidget(process: processName);
  }
}

//Holds time of uses with same app name
class AppStat {
  Duration totalTime = Duration(seconds: 0);
  String appName;

  AppStat({this.totalTime, this.appName});

  ///Create a list of AppStats from list of uses with the same procName
  static Map<String, AppStat> multipleFromUses(List<Use> uses, {String procName}) {
    Map<String, AppStat> appStats;
    // * create appStats for every use
    uses.forEach((use) {
      // * optional procName check
      if (procName != null && use.processName != procName) {
        return;
      } else {
        appStats
            .putIfAbsent(use.appName, () => AppStat(appName: use.appName, totalTime: Duration(seconds: 0)))
            .totalTime += Duration(milliseconds: use.useEnd - use.useStart);
      }
    });
    return appStats;
  }
}

class AppStatWidget extends StatefulWidget {
  final String process;

  @override
  _AppStatWidgetState createState() => _AppStatWidgetState();

  AppStatWidget({this.process});
}

class _AppStatWidgetState extends State<AppStatWidget> {
  @override
  Widget build(BuildContext context) {
    String chartType = "pie";

    Future<Map<String, ProcStats>> stats = Provider.of<UsageNotifier>(context).stats;
    return Scaffold(
        appBar: defaultAppBar(),
        body: FutureBuilder<Map<String, ProcStats>>(
            future: stats,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: Text("Loading data"));
              } else if (snapshot.hasData) {
                // * load appStats from future
                var appStats = snapshot.data[this.widget.process].appStats;

                // * sort by totalTime
                var appStatsList = appStats.values.toList();
                appStatsList.sort((b, a) => a.totalTime.compareTo(b.totalTime));

                // * load AppStats and put them into widgets
                List<Widget> appStatWidgets = [];

                appStatsList.forEach((value) {
                  appStatWidgets.add(AppStatWidgetSingle(
                    appStat: value,
                  ));
                });

                return LayoutBuilder(builder: (BuildContext context, viewportConstraints) {
                  Widget chart;
                  if (chartType == "pie") {
                    // * PieChart
                    chart = Container(
                        width: viewportConstraints.maxWidth / 2,
                        child: PieChartWidget(
                          appStats: appStats,
                        ));
                  } else if (chartType == "time") {
                    chart = Text("Not yet implemented time chart");
                  } else {
                    chart = Text("Unknown chart type requested");
                  }

                  var boxDecorations = BoxDecoration(

                  );

                  return Center(
                      child: Column(
                    children: [
                      Expanded(
                        child: Row(key: ValueKey("AppListContainer"), children: [
                          SideNavigation(),
                          Expanded(
                            child: Column(
                              children: [
                                Expanded(child: chart),
                                PieFooter(
                                  child: Container(
                                    decoration: BoxDecoration(border: Border.all(
                                      color: Theme.of(context).colorScheme.onSecondary,
                                      width: 4
                                    )),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                            child: Container(
                                                child: IconButton(
                                                    icon: Icon(Icons.pie_chart, color: Colors.white), onPressed: () {}))),
                                        Expanded(
                                            child: Container(
                                                child: IconButton(
                                                    icon: Icon(
                                                      Icons.show_chart,
                                                      color: Colors.white,
                                                    ),
                                                    onPressed: () {})))
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                          // * AppStats list
                          Expanded(
                            flex: 1,
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height - 56,
                              child: ListView(
                                shrinkWrap: true,
                                scrollDirection: Axis.vertical,
                                children: appStatWidgets,
                              ),
                            ),
                          )
                        ]),
                      ),
                    ],
                  ));
                });
              } else {
                return Text("Something went wrong");
              }
            }));
  }
}

class AppStatWidgetSingle extends StatefulWidget {
  AppStat appStat;

  @override
  _AppStatWidgetSingleState createState() => _AppStatWidgetSingleState();

  AppStatWidgetSingle({this.appStat});
}

class _AppStatWidgetSingleState extends State<AppStatWidgetSingle> {
  @override
  Widget build(BuildContext context) {
    var totalTime = this.widget.appStat.totalTime;
    var colorScheme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    return Container(
        color: colorScheme.primary,
        margin: EdgeInsets.all(10),
        padding: EdgeInsets.all(10),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Align(
              alignment: Alignment.center,
              child: Text(
                "Název: ${this.widget.appStat.appName}",
                style: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
              )),
          Align(
              alignment: Alignment.center,
              child: Text(
                "Čas: ${totalTime.inHours}:${totalTime.inMinutes % 60}:${totalTime.inSeconds % 60}",
                style: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
              ))
        ]));
  }
}

class BreakButton extends StatefulWidget {
  @override
  _BreakButtonState createState() => _BreakButtonState();
}

class _BreakButtonState extends State<BreakButton> {
  var _isBreak = false;

  @override
  Widget build(BuildContext context) {
    var usageNotifier = Provider.of<UsageNotifier>(context);
    Widget buttonChild;

    if (_isBreak) {
      buttonChild = Container(
          child: Text(
        "Take a break",
        style: TextStyle(fontSize: 20),
      ));
    } else {
      buttonChild = Container(color: Colors.red, child: Text("Resume work", style: TextStyle(fontSize: 20)));
    }

    return ElevatedButton(
        onPressed: () {
          setState(() {
            _isBreak = !_isBreak;
          });
          usageNotifier.isBreak = _isBreak;
        },
        child: Container(padding: EdgeInsets.all(10), child: buttonChild));
  }
}
