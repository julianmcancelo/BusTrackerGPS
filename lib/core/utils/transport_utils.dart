import 'package:flutter/material.dart';

/// Funciones utilitarias y canónicas para el sistema de transporte de Lanús Digital.
class TransportUtils {
  /// Normaliza una cadena de texto para extraer el número canónico de línea (ej. "Línea 520" -> "520").
  static String normalizeLineNumber(String? input) {
    if (input == null) return '';
    final clean = input.trim();
    if (clean.isEmpty) return '';

    // Intenta capturar un número de 1 a 4 dígitos, posiblemente con sufijo de letra (ej: 520, 520A, 271)
    final match = RegExp(r'(\d{1,4}[A-Za-z]?)').firstMatch(clean);
    if (match != null) {
      return match.group(1)!;
    }

    // Fallback: remover prefijos como "Línea", "Linea", "Line"
    return clean.replaceAll(RegExp(r'^(l[ií]nea|line)\s*', caseSensitive: false), '').trim();
  }

  /// Retorna un color distintivo oficial según el número de línea de Lanús.
  static Color getLineColor(String? lineNumber) {
    final num = normalizeLineNumber(lineNumber);
    switch (num) {
      case '520':
        return const Color(0xFF1D4ED8); // Azul Cobalto
      case '522':
        return const Color(0xFF059669); // Esmeralda Tránsito
      case '524':
        return const Color(0xFFD97706); // Ámbar / Ocre Institucional
      case '526':
        return const Color(0xFF7C3AED); // Púrpura Municipal
      case '527':
        return const Color(0xFFEA580C); // Naranja Tránsito
      default:
        return const Color(0xFF0284C7); // Azul Celeste Tránsito
    }
  }

  /// Retorna el color de fondo suave para chips y badges.
  static Color getLineColorLight(String? lineNumber) {
    return getLineColor(lineNumber).withValues(alpha: 0.12);
  }

  /// Formatea la etiqueta de presentación de una línea.
  static String formatLineBadge(String? lineNumber) {
    final num = normalizeLineNumber(lineNumber);
    return num.isNotEmpty ? num : 'LÍNEA';
  }
}
