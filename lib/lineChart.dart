import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:timetracker/classes.dart';

class LineChartData {
  final DateTime date;
  int totalTime = 0;

  LineChartData(this.date, {this.totalTime});
}

class SimpleLineChart extends StatefulWidget {
  List<charts.Series> seriesList;

  SimpleLineChart(this.seriesList);

  @override
  _SimpleLineChartState createState() => _SimpleLineChartState();
}

class _SimpleLineChartState extends State<SimpleLineChart> {
  List<charts.Series> _seriesList;
  List<LineChartData> _chartDataList;

  setSeriesFromUses(List<Use> uses, Duration xStep) {
    var sortedUses = [...uses];
    sortedUses.sort((a, b) => a.useStart.compareTo(b.useStart));

    setState(() {
      DateTime currentStepEnd = DateTime.fromMillisecondsSinceEpoch(sortedUses[0].useEnd).add(xStep);
      LineChartData currentChartData = LineChartData(DateTime.fromMillisecondsSinceEpoch(sortedUses[0].useStart));
      for (var use in sortedUses) {
        // * If useEnd still belongs in this xStep
        if (DateTime.fromMillisecondsSinceEpoch(use.useEnd).isBefore(currentStepEnd)) {
          currentChartData.totalTime += (use.useEnd - use.useStart);
        } else {
          // * this use belongs in the next chartData/xStep
          this._chartDataList.add(currentChartData);
          currentChartData = LineChartData(currentStepEnd, totalTime: use.useEnd - use.useStart);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return charts.LineChart(this.widget.seriesList, animate: false);
  }
}
