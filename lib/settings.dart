import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:timetracker/appBar.dart';
import 'package:timetracker/home.dart';
import 'package:timetracker/sideNavigation.dart';
import 'package:timetracker/usageNotifier.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    var textTheme = Theme.of(context).textTheme;
    var colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
        appBar: defaultAppBar(),
        body: Row(
          children: [
            SideNavigation(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Row(
                    children: [
                      Expanded(
                          child: Container(
                        // * Settings cards
                        child: Column(
                          children: [
                            Text("Settings", style: textTheme.headline2),
                            SettingCard(
                              title: "Data collection",
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SettingsTextInput(
                                    label:
                                        "Interval between active app detection (in s): ",
                                  ),
                                  SettingsTextInput(
                                    label:
                                        "Maximum time of mouse inactivity (in s): ",
                                  )
                                ],
                              ),
                            ),
                            SettingCard(
                              title: "Pie chart settings",
                              child: Column(children: [
                                SettingsTextInput(label: "Minimal slice size (in %): ",)
                              ],),
                            )
                          ],
                        ),
                      )),
                      SizedBox(
                          width: constraints.maxWidth / 2,
                          height: constraints.maxHeight,
                          child: AppUsage())
                    ],
                  );
                },
              ),
            ),
          ],
        ));
  }
}

class SettingCard extends StatefulWidget {
  final Widget child;
  final String title;

  SettingCard({this.child, this.title});

  @override
  _SettingCardState createState() => _SettingCardState();
}

class _SettingCardState extends State<SettingCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
        color: Theme.of(context).colorScheme.primary,
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            Container(
                width: double.infinity,
                child: Text(
                  this.widget.title,
                  style: Theme.of(context).textTheme.headline4,
                  textAlign: TextAlign.start,
                )),
            Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(border: Border(top: BorderSide(width: 2, color: Colors.white24))),
                child: this.widget.child)
          ],
        ));
  }
}

class SettingsTextInput extends StatelessWidget {
  final String label;
  final String settingsKey;


  SettingsTextInput({this.label, this.settingsKey});

  @override
  Widget build(BuildContext context) {
    var notifier = Provider.of<UsageNotifier>(context);
    return Container(
      margin: EdgeInsets.symmetric(vertical: 3),
      height: 26,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label, style: Theme.of(context).textTheme.headline5),
          SizedBox(
              width: 100,
              child: TextField(
                onChanged: (value) => notifier.updateSettings(this.settingsKey, value),
                style: Theme.of(context).textTheme.bodyText2.copyWith(
                    color: Theme.of(context).colorScheme.primary, fontSize: 14),
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white),
              )),
        ],
      ),
    );
  }
}
