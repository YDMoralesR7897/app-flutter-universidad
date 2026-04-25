import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di/injection.dart';
import 'core/security/integrity_checker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();

  // Bloqueo temprano si el dispositivo está comprometido (solo release).
  try {
    await IntegrityChecker.instance.assertSafe();
  } catch (_) {
    runApp(const _IntegrityBlockedApp());
    return;
  }

  runApp(const App());
}

class _IntegrityBlockedApp extends StatelessWidget {
  const _IntegrityBlockedApp();
  @override
  Widget build(BuildContext context) => const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Este dispositivo no cumple los requisitos de seguridad '
                'para ejecutar la aplicación.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
}
