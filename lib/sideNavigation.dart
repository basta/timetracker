import 'package:flutter/material.dart';
import 'package:timetracker/settings.dart';

class SideNavigation extends StatefulWidget {
  @override
  _SideNavigationState createState() => _SideNavigationState();
}

class _SideNavigationState extends State<SideNavigation> {
  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.secondary,
      child: Column(
        children: [
          SideNavigationButton(
            icon: Icons.home,
            onPressed: () {},
          ),
          SideNavigationButton(
            icon: Icons.bar_chart,
            onPressed: () {},
          ),
          SideNavigationButton(
            icon: Icons.settings,
            onPressed: () {
              print("Opening settings");
              Navigator.push(context, PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) {
                  return SettingsPage();
                },
              ));
            },
          )
        ],
      ),
    );
  }
}

class SideNavigationButton extends StatefulWidget {
  IconData icon;
  void Function() onPressed;

  @override
  _SideNavigationButtonState createState() => _SideNavigationButtonState();

  SideNavigationButton({this.icon, this.onPressed});
}

class _SideNavigationButtonState extends State<SideNavigationButton> {
  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    return Container(
        decoration: BoxDecoration(
            border: Border(
              top: BorderSide(width: 2, color: colorScheme.onPrimary),
            ),
            color: colorScheme.primary),
        child: IconButton(
            color: colorScheme.onPrimary,
            icon: Icon(this.widget.icon),
            onPressed: this.widget.onPressed));
  }
}
