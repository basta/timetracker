import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:timetracker/usageNotifier.dart';
import 'classes.dart';

class PieChartModel {
  String name;
  int time;
  charts.Color color;

  static charts.Color colorFromString(String string) {
    int r, g, b;
    r = hash("red" + string);
    g = hash("blue" + string);
    b = hash("green" + string);

    return charts.Color(r: r, g: g, b: b);
  }

  PieChartModel({this.name, this.time, this.color});
}

class PieChart {
  final int minimalSlice;
  
  List<PieChartModel> _data;
  int othersTime = 0;
  
  PieChart({this.minimalSlice});
  
  


  void loadDataFromProcStats(Map<String, ProcStats> stats) {
    this._data = [];
    stats.forEach((key, stat) {
      _data.add(new PieChartModel(
          name: stat.processName,
          time: stat.totalTime.inSeconds,
          color: PieChartModel.colorFromString(stat.processName)));
    });
    this._data.sort((b, a) => a.time.compareTo(b.time));
    joinSmallToOthers();
  }

  void loadDataFromAppStats(Map<String, AppStat> stats) {
    this._data = [];
    stats.forEach((key, stat) {
      _data.add(new PieChartModel(
          name: stat.appName,
          time: stat.totalTime.inSeconds,
          color: PieChartModel.colorFromString(stat.appName)));
    });
    this._data.sort((b, a) => a.time.compareTo(b.time));
    joinSmallToOthers();
  }

  void joinSmallToOthers() {
    var totalTime = this._data.fold(0, (previousValue, element) => previousValue + element.time);
    this._data.removeWhere((element) {
      if ((element.time) < totalTime * minimalSlice / 100) {
        othersTime += element.time;
        return true;
      } else {
        return false;
      }
    });
    this._data.add(new PieChartModel(
      name: "Other",
      time: othersTime,
      color: charts.Color(r: 180, g: 180, b: 180)
    ));
  }

  List<charts.Series<PieChartModel, String>> get series {
    var ret = [
      new charts.Series(
          id: "Time",
          data: _data,
          domainFn: (PieChartModel model, _) => model.name,
          // name
          measureFn: (PieChartModel model, _) => model.time,
          // value
          colorFn: (PieChartModel model, _) => model.color,
          // color
          labelAccessorFn: (PieChartModel model, _) => model.name),
    ];
    return ret;
  }

  charts.PieChart get chart {
    return new charts.PieChart(
      series,
      animate: false,
      defaultRenderer: charts.ArcRendererConfig(arcRendererDecorators: [
        new charts.ArcLabelDecorator(
            labelPosition: charts.ArcLabelPosition.inside)
      ]),
    );
  }

  Widget get chartWidget => chart;
}

class PieChartWidget extends StatefulWidget {
  final Map<String, AppStat> appStats;

  PieChartWidget({this.appStats});

  @override
  _PieChartWidgetState createState() => _PieChartWidgetState();
}

class _PieChartWidgetState extends State<PieChartWidget> {
  @override
  Widget build(BuildContext context) {
    final notifier = Provider.of<UsageNotifier>(context);
    final stats = notifier.stats;
    final settings = notifier.settings;

    return FutureBuilder(
        future: Future.wait([stats, settings]),
        builder: (context, snapshot) {

          // * load stats into chart data
          if (this.widget.appStats != null && snapshot.hasData) {
            var _pieChart = PieChart(minimalSlice: int.parse(snapshot.data[1]["minimalSlice"]));
            _pieChart.loadDataFromAppStats(this.widget.appStats);
            return _pieChart.chartWidget;
          }
          else if (snapshot.hasData) {
            var _pieChart = PieChart(minimalSlice: int.parse(snapshot.data[1]["minimalSlice"]));
            _pieChart.loadDataFromProcStats(snapshot.data[0]);
            return _pieChart.chartWidget;
          } else  {
            return Text("Chart loading");
          }
        });
  }
}

class PieFooter extends StatefulWidget {
  final Widget child;

  PieFooter({this.child});

  @override
  _PieFooterState createState() => _PieFooterState();

}

class _PieFooterState extends State<PieFooter> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primary,
      margin: EdgeInsets.symmetric(horizontal: 70, vertical: 20),
      width: double.infinity,
      height: 53,
      child: this.widget.child,
    );
  }
}
