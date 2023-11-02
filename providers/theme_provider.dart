import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sunrise_app/models/user_info_model.dart';

final theThemeProvider = Provider<ThemeData>((ref) {
  final ColorScheme kColorScheme = ref.watch(colorSchemeProvider);
  return ThemeData().copyWith(
    colorScheme: kColorScheme,
    useMaterial3: true,
    appBarTheme: const AppBarTheme().copyWith(
        backgroundColor: kColorScheme.primary,
        foregroundColor: Colors.white,
        centerTitle: true),
    textTheme: const TextTheme().copyWith(
      titleMedium: TextStyle(color: kColorScheme.primary),
      titleLarge: TextStyle(color: kColorScheme.primary),
      titleSmall: TextStyle(color: kColorScheme.primary),

      ///asta este de la listtile - title
      bodyLarge:
          TextStyle(color: kColorScheme.primary, fontWeight: FontWeight.bold),
      bodyMedium: TextStyle(color: kColorScheme.primary),
      bodySmall: TextStyle(color: kColorScheme.primary),
      displayLarge: TextStyle(color: kColorScheme.primary),
      displayMedium: TextStyle(color: kColorScheme.primary),
      displaySmall: TextStyle(color: kColorScheme.primary),
      labelLarge: TextStyle(color: kColorScheme.primary),
      labelMedium: TextStyle(color: kColorScheme.primary),

      ///asta este textul de la listtile - leading
      labelSmall: TextStyle(color: kColorScheme.primary),
      headlineLarge: TextStyle(color: kColorScheme.primary),
      headlineMedium: TextStyle(color: kColorScheme.primary),
      headlineSmall: TextStyle(color: kColorScheme.primary),
    ),
    inputDecorationTheme: const InputDecorationTheme().copyWith(
      labelStyle: TextStyle(color: kColorScheme.primary),
    ),
    iconTheme: const IconThemeData().copyWith(color: Colors.white),
  );
});

///Database provider here
Future<Database> getDatabase() async {
  final dbPath = await getDatabasesPath();
  final db = await openDatabase(
    join(dbPath, 'user_data.db'),
    onCreate: (db, version) {
      return db.execute(
          'CREATE TABLE user_information (user_email TEXT PRIMARY KEY, r INTEGER, g INTEGER, b INTEGER, o REAL, alias TEXT, firms TEXT)');
    },
    version: 1,
  );
  return db;
}

///Color Scheme Provider here
class ColorSchemeProvider extends StateNotifier<ColorScheme> {
  ColorSchemeProvider()
      : super(ColorScheme.fromSeed(
            seedColor: const Color.fromRGBO(138, 52, 134, 255)));

  Database? database;
  // UserInformation? userInformation;
  UserInformation? userInformation;

  // Future<void> deleteDatabase() async {
  //   final dbPath = await getDatabasesPath();
  //   final path = join(dbPath, 'theme_data.db');
  //   // Check if the database file exists before attempting to delete
  //   await deleteDatabase();
  // }

  Future<void> createDB(String userEmail) async {
    database = await getDatabase();
  }

  Future<Color> getColorFromDB(String userEmail) async {
    Color dbColor = state.primary;
    try {
      final data = await database!.query('user_information',
          where: 'user_email = ?', whereArgs: [userEmail]);
      dbColor = Color.fromRGBO(data.first['r'] as int, data.first['g'] as int,
          data.first['b'] as int, data.first['o'] as double);
    } catch (e) {
      await createColor(userEmail, dbColor);
      return dbColor;
    }
    return dbColor;
  }

  Future<void> updateColor(String userEmail, Color? color) async {
    var newColorScheme = ColorScheme.fromSeed(seedColor: color!);
    state = newColorScheme;
    print('color updated');
  }

  Future<void> createColor(String userEmail, Color color) async {
    await database!.insert('user_information', {
      'user_email': userEmail,
      'r': color.red,
      'g': color.green,
      'b': color.blue,
      'o': color.alpha,
      'alias': '',
      'firms': ''
    });
  }

  Future<void> updateDBColor(String userEmail, Color color) async {
    await database!.update('user_information',
        {'r': color.red, 'g': color.green, 'b': color.blue, 'o': color.alpha},
        where: 'user_email = ?', whereArgs: [userEmail]);
  }

  Future<void> updateUserInfoFromDB(
    String userEmail,
    UserInformation userInfo,
  ) async {
    var firms = userInfo.userFirms;
    String firmsString = firms.join(',');
    await database!.update(
        'user_information', {'alias': userInfo.alias, 'firms': firmsString},
        where: 'user_email = ?', whereArgs: [userEmail]);
    userInformation = userInfo;
    print('user info updated');
  }

  Future<void> updateAliasInDB(String userEmail, String alias) async {
    await database!.update(
        'user_information',
        {
          'alias': alias,
        },
        where: 'user_email = ?',
        whereArgs: [userEmail]);
    userInformation!.alias = alias;
  }
}

final colorSchemeProvider =
    StateNotifierProvider<ColorSchemeProvider, ColorScheme>(
  (ref) => ColorSchemeProvider(),
);
