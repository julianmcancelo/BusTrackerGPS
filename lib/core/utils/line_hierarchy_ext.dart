import '../../database/database.dart';

extension LineEntryHierarchy on LineEntry {
  String get hierarchy {
    final match = RegExp(r'\d+').firstMatch(number);
    if (match != null) {
      final num = int.tryParse(match.group(0)!);
      if (num != null) {
        if (num < 200) return 'Jurisdicción Nacional';
        if (num < 500) return 'Jurisdicción Provincial';
      }
    }
    return 'Jurisdicción Municipal';
  }
}
