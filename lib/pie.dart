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
  List<PieChartModel> data = [
    PieChartModel(
        name: "Data 1",
        time: 20,
        color: new charts.Color(r: 50, g: 50, b: 255)),
    PieChartModel(
        name: "Data 2", time: 10, color: new charts.Color(r: 255, g: 50, b: 50))
  ];

  void loadDataFromStats(Map<String, ProcStats> stats) {
    this.data = [];
    stats.forEach((key, stat) {
      data.add(new PieChartModel(
          name: stat.processName,
          time: stat.totalTime.inSeconds,
          color: PieChartModel.colorFromString(stat.processName)));
    });
  }

  List<charts.Series<PieChartModel, String>> get series {
    var ret = [
      new charts.Series(
        id: "Time",
        data: data,
        domainFn: (PieChartModel model, _) => model.name, // name
        measureFn: (PieChartModel model, _) => model.time, // value
        colorFn: (PieChartModel model, _) => model.color, // color
        labelAccessorFn: (PieChartModel model, _) => model.name
      ),
    ];
    return ret;
  }

  charts.PieChart get chart {
    return new charts.PieChart(
      series,
      animate: false,
      defaultRenderer: charts.ArcRendererConfig(arcRendererDecorators: [
        new charts.ArcLabelDecorator(
          labelPosition: charts.ArcLabelPosition.inside
        )
      ]),
    );
  }

  Widget get chartWidget {
    return SizedBox(
      height: 400,
      width: 400,
      child: chart,
    );
  }
}

class PieChartWidget extends StatefulWidget {
  @override
  _PieChartWidgetState createState() => _PieChartWidgetState();
}

class _PieChartWidgetState extends State<PieChartWidget> {
  @override
  Widget build(BuildContext context) {
    final notifier = Provider.of<UsageNotifier>(context);
    final stats = notifier.stats;
    var _pieChart = PieChart();

    return FutureBuilder<Map<String, ProcStats>>(
        future: stats,
        builder: (context, snapshot) {
      // * load stats into chart data
      if (snapshot.hasData) {
        _pieChart.loadDataFromStats(snapshot.data);
        return _pieChart.chartWidget;
      } else {
        return Text("Chart loading");
      }

    });

  }
}
