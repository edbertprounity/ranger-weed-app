import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

Future<void> initDatabaseFactory() async {
  final base = Uri.base;
  databaseFactory = createDatabaseFactoryFfiWeb(
    options: SqfliteFfiWebOptions(
      sqlite3WasmUri: base.resolve('sqlite3.wasm'),
      sharedWorkerUri: base.resolve('sqflite_sw.js'),
    ),
  );
}
