import 'package:flutter/material.dart';
import 'package:timetracker/home.dart';

var defaultAppBar = AppBar(
  title: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text("Timetracker"),
      CurrentApp()
    ],
  ),
);