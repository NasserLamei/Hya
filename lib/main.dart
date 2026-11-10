import 'package:flutter/widgets.dart';

import 'app.dart';
import 'core/remote.dart';
import 'core/store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = AppStore();
  runApp(StoreScope(store: store, child: const HyaApp()));
  await RemoteSync.init();
  await store.load();
}
