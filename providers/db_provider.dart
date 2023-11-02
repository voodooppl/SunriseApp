// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:path/path.dart';
// import 'package:sqflite/sqflite.dart';
//
// ///Database provider here
// Future<Database> _getDatabase() async {
//   final dbPath = await getDatabasesPath();
//   final db = await openDatabase(
//     join(dbPath, 'theme_data.db'),
//     onCreate: (db, version) {
//       return db.execute(
//           'CREATE TABLE color_scheme (user_email TEXT PRIMARY KEY, r INTEGER, g INTEGER, b INTEGER, opacity REAL)');
//     },
//     version: 1,
//   );
//   return db;
// }
//
// class DBProvider extends StateNotifier<Database> {
//   DBProvider(Database database) : super(database);
// }
