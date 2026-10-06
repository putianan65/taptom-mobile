import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'app/locator.dart';
import 'core/config/env.dart';
import 'core/effects/shader_backdrop.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Env.init();
  await initializeDateFormatting('th');
  setupLocator();

  // Compile the backdrop shaders while the native splash is still visible so
  // the first animated frame does not stutter.
  await ShaderBackdrop.precache(const [
    FieldBackdrop.asset,
    ContourBackdrop.asset,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Session restore happens on the splash screen, in parallel with its
  // animation, instead of blocking the first frame on a network call.
  runApp(const TaptomApp());
}
