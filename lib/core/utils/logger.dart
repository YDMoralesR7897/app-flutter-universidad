import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart' as pkg;

/// Logger del proyecto. En release se silencia para evitar fugas de datos
/// sensibles (tokens, PII) al log del sistema.
final appLogger = pkg.Logger(
  level: kReleaseMode ? pkg.Level.off : pkg.Level.debug,
  printer: pkg.PrettyPrinter(methodCount: 0, colors: true, printEmojis: false),
);
