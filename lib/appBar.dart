import 'package:flutter/material.dart';
import 'package:timetracker/home.dart';

AppBar defaultAppBar ({isTracking = false}) => AppBar(
    title: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [Text("Timetracker"), CurrentApp(isTracking: isTracking,)],
    ),
  );