import 'package:flutter/material.dart';

var colorScheme = ColorScheme(
    primary: Color(0xff251145),
    primaryVariant: Color(0xff160033),
    onPrimary: Color(0xffffffff),
    secondary: Color(0xff4B4453),
    secondaryVariant: Color(0xff26222a),
    onSecondary: Color(0xffb0a8b9),
    background: Colors.white,
    onBackground: Color(0xff251145),
    brightness: Brightness.light,
    error: Colors.red,
    onError: Colors.white,
    surface: Color(0xff4B4453),
    onSurface: Color(0xffB0A8B9));

var globalTheme = ThemeData(
    primaryColor: Color(0xff251145),
    accentColor: Color(0xff4B4453),
    colorScheme: colorScheme,
    textTheme: TextTheme(
        caption: TextStyle(color: colorScheme.onPrimary),
        headline2: TextStyle(color: colorScheme.primary),
        bodyText1: TextStyle(color: colorScheme.onPrimary),
        bodyText2: TextStyle(color: colorScheme.onSecondary),
        headline4: TextStyle(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
        headline5: TextStyle(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.normal,
            fontSize: 16)));
