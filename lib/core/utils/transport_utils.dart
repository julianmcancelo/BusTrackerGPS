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

  /// Extrae el valor entero del número de línea para ordenamiento numérico.
  static int parseLineNumberInt(String? input) {
    if (input == null) return 99999;
    final match = RegExp(r'\d+').firstMatch(input);
    if (match != null) {
      return int.tryParse(match.group(0)!) ?? 99999;
    }
    return 99999;
  }

  /// Compara dos líneas por valor numérico real (ej: 9 antes que 10, y 10 antes que 100).
  static int compareLineNumbers(String a, String b) {
    final numA = parseLineNumberInt(a);
    final numB = parseLineNumberInt(b);
    if (numA != numB) return numA.compareTo(numB);
    return a.compareTo(b);
  }

  /// Lista oficial de las líneas comunales municipales de Lanús
  static const Set<String> municipalLineNumbers = {
    '520',
    '521',
    '522',
    '523',
    '524',
    '526',
    '527',
  };

  /// Determina si una línea es de jurisdicción municipal comunal de Lanús (serie 500)
  static bool isMunicipalLine(String? lineNumber) {
    final num = normalizeLineNumber(lineNumber);
    if (municipalLineNumbers.contains(num)) return true;
    final val = int.tryParse(num) ?? 0;
    return val >= 500 && val <= 599;
  }

  /// Determina si una línea es de jurisdicción nacional (1 a 199 en el AMBA)
  static bool isNationalLine(String? lineNumber) {
    final num = normalizeLineNumber(lineNumber);
    final val = int.tryParse(num) ?? 0;
    return val >= 1 && val < 200;
  }

  /// Determina si una línea es de jurisdicción provincial (200 a 499 en el conurbano bonaerense)
  static bool isProvincialLine(String? lineNumber) {
    final num = normalizeLineNumber(lineNumber);
    final val = int.tryParse(num) ?? 0;
    return val >= 200 && val < 500;
  }

  /// Retorna la etiqueta formal de jurisdicción para la línea
  static String getJurisdictionLabel(String? lineNumber) {
    if (isMunicipalLine(lineNumber)) return 'Municipal';
    if (isNationalLine(lineNumber)) return 'Nacional';
    if (isProvincialLine(lineNumber)) return 'Provincial';
    return 'Línea';
  }

  /// Retorna un color distintivo oficial según el número de línea de Lanús.
  static Color getLineColor(String? lineNumber) {
    final num = normalizeLineNumber(lineNumber);
    switch (num) {
      case '9':
        return const Color(0xFF2563EB); // Azul Eléctrico
      case '10':
        return const Color(0xFFDC2626); // Rojo
      case '15':
        return const Color(0xFF059669); // Esmeralda
      case '20':
        return const Color(0xFFD97706); // Ámbar
      case '28':
        return const Color(0xFF7C3AED); // Violeta
      case '31':
        return const Color(0xFF0284C7); // Celeste
      case '32':
        return const Color(0xFFEA580C); // Naranja
      case '33':
        return const Color(0xFF0891B2); // Cian
      case '37':
        return const Color(0xFF4F46E5); // Índigo
      case '45':
        return const Color(0xFF16A34A); // Verde
      case '51':
        return const Color(0xFF0D9488); // Teal
      case '54':
        return const Color(0xFFD97706); // Ámbar
      case '70':
        return const Color(0xFF9333EA); // Púrpura
      case '74':
        return const Color(0xFFE11D48); // Rosa Oscuro
      case '75':
        return const Color(0xFF0D9488); // Teal
      case '79':
        return const Color(0xFF2563EB); // Azul
      case '85':
        return const Color(0xFFCA8A04); // Dorado
      case '100':
        return const Color(0xFFE11D48); // Carmesí
      case '119':
        return const Color(0xFF0284C7); // Celeste
      case '128':
        return const Color(0xFF4338CA); // Índigo
      case '154':
        return const Color(0xFFB45309); // Ámbar Profundo
      case '158':
        return const Color(0xFF059669); // Esmeralda
      case '160':
        return const Color(0xFFDC2626); // Rojo
      case '164':
        return const Color(0xFF7C3AED); // Violeta
      case '177':
        return const Color(0xFF0891B2); // Cian
      case '178':
        return const Color(0xFF16A34A); // Verde
      case '179':
        return const Color(0xFFEA580C); // Naranja
      case '188':
        return const Color(0xFF2563EB); // Azul
      case '239':
        return const Color(0xFFD97706); // Ámbar
      case '247':
        return const Color(0xFFE11D48); // Rosa
      case '263':
        return const Color(0xFF4F46E5); // Índigo
      case '266':
        return const Color(0xFF059669); // Esmeralda
      case '271':
        return const Color(0xFF0284C7); // Celeste
      case '277':
        return const Color(0xFF7C3AED); // Púrpura
      case '283':
        return const Color(0xFFCA8A04); // Dorado
      case '293':
        return const Color(0xFFDC2626); // Rojo
      case '295':
        return const Color(0xFF0891B2); // Cian
      case '299':
        return const Color(0xFFEA580C); // Naranja
      case '318':
        return const Color(0xFF16A34A); // Verde
      case '323':
        return const Color(0xFF2563EB); // Azul
      case '338':
        return const Color(0xFF7C3AED); // Violeta
      case '373':
        return const Color(0xFFE11D48); // Rosa
      case '405':
        return const Color(0xFF0D9488); // Teal
      case '406':
        return const Color(0xFF059669); // Esmeralda
      case '436':
        return const Color(0xFFD97706); // Ámbar
      case '520':
        return const Color(0xFF1D4ED8); // Azul Cobalto
      case '521':
        return const Color(0xFF0D9488); // Teal Municipal
      case '522':
        return const Color(0xFF059669); // Esmeralda Tránsito
      case '523':
        return const Color(0xFF4F46E5); // Índigo Municipal
      case '524':
        return const Color(0xFFD97706); // Ámbar Institucional
      case '526':
        return const Color(0xFF7C3AED); // Púrpura Municipal
      case '527':
        return const Color(0xFFEA580C); // Naranja Tránsito
      default:
        // Hash cromático determinista y balanceado para cualquier otra línea
        final hash = num.hashCode.abs();
        final hues = [
          const Color(0xFF1D4ED8),
          const Color(0xFF059669),
          const Color(0xFFD97706),
          const Color(0xFF7C3AED),
          const Color(0xFFEA580C),
          const Color(0xFFDC2626),
          const Color(0xFF0891B2),
          const Color(0xFFE11D48),
        ];
        return hues[hash % hues.length];
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
