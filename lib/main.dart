import 'package:flutter/material.dart';
import 'package:dharana_app/app/app.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru');
  runApp(const DharanaApp());
}
