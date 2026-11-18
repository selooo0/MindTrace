import 'package:crime_endless/screens/home.dart';
import 'package:crime_endless/utils/db_helper.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = DBHelper();
  await db.initDB();
  runApp(MaterialApp(home: const Home()));
}
