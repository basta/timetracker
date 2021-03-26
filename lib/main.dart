// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ! Better comments definitions
// * used for sectioning the code

// * dart internals
import 'dart:async';
import 'dart:developer';
import 'dart:io';
import "package:provider/provider.dart";

// * styling packages
import 'package:flutter/material.dart';

// * imported packages
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:timetracker/usageNotifier.dart';
import 'package:charts_common/common.dart' as common;
import 'package:timetracker/home.dart';

// * own packages
import "classes.dart";
import 'pie.dart';

// * config constants
void main() async {
  initHome();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Timetracker',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Timetracker'),
        ),
        body: Home(),
      ),
    );
  }
}