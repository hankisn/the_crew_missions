import 'package:flutter/material.dart';

class TheCrewTheme {
  static Color primary = Colors.blue[800]!;
  static Color cards = Colors.brown[100]!;
  static Color error = Colors.redAccent[700]!;
  static Color icons = Colors.purple[600]!;
  static Color cardOnCards = Colors.blueGrey[200]!;


  static ThemeData get standardTheme {
    return ThemeData(
      primaryColor: primary,
      primaryIconTheme: new IconThemeData(
        color: icons,
      ),
      accentColor: primary,      
      scaffoldBackgroundColor: Colors.grey[900],
      errorColor: error,
      cardColor: cards,
      splashColor: Colors.blue.withAlpha(90),
      

      textTheme: new TextTheme(
        headline1: TextStyle(
          fontFamily: 'Audiowide',
          color: Colors.white,
          fontSize: 20,
        ),
        headline4: TextStyle(
          fontFamily: 'Audiowide',
          color: Colors.black54,
          fontSize: 26,
        ),
        headline5: TextStyle(
          fontFamily: 'Audiowide',
          color: Colors.black54,
          fontSize: 24,
        ),
        headline6: TextStyle(
          fontFamily: 'Audiowide',
          color: Colors.black54,
          fontSize: 18,
        ),
        subtitle1: TextStyle(
          fontFamily: 'Iceland',
          color: Colors.black,
          fontSize: 20,
        ),
        subtitle2: TextStyle(
          fontFamily: 'Iceland',
          color: Colors.black,
          fontSize: 18,
        ),
        button: TextStyle(
          fontFamily: 'Audiowide',
          color: Colors.white,
        ),
        caption: TextStyle(
          fontFamily: 'Iceland',
          fontSize: 14,
        ),
        overline: TextStyle(
          fontFamily: 'Iceland',
          fontSize: 20,
        ),
      ),


      accentIconTheme: new IconThemeData(
        color: Colors.white,
      ),

      iconTheme: new IconThemeData(
        color: icons,
      ),

      floatingActionButtonTheme: new FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      appBarTheme: new AppBarTheme(
        color: primary,
        iconTheme: new IconThemeData(
          color: Colors.white,
        ),
      ),
      bottomNavigationBarTheme: new BottomNavigationBarThemeData(
        backgroundColor: cards,
        selectedItemColor: primary,
        showUnselectedLabels: true,
        showSelectedLabels: true,
        unselectedItemColor: icons,
        selectedLabelStyle: new TextStyle(
          fontFamily: 'Iceland',
          fontSize: 20,
        ),
        unselectedLabelStyle: new TextStyle(
          fontFamily: 'Iceland',
          fontSize: 20,
        ),
      ),
      elevatedButtonTheme: new ElevatedButtonThemeData(
        style: new ButtonStyle(
          shadowColor: MaterialStateProperty.all<Color>(error),
          foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
          backgroundColor: MaterialStateProperty.all<Color>(primary),
          overlayColor: MaterialStateProperty.resolveWith<Color>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.focused) ||
                  states.contains(MaterialState.pressed))
                return Colors.blue;
              return primary; // Defer to the widget's default.
            },
          ),
        ),
      ),
      snackBarTheme: new SnackBarThemeData(
        backgroundColor: Colors.purple[800],
      )
    );
  }
}