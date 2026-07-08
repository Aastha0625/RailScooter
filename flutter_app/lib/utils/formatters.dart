class Formatters {
  static String getSiUnit(String type) {
    final t = type.toLowerCase();
    if (t.contains('speed')) return 'km/h';
    if (t.contains('battery')) return '%';
    if (t.contains('temperature') || t.contains('temp')) return '°C';
    if (t.contains('distance') || t.contains('range')) return 'km';
    if (t.contains('pressure')) return 'psi';
    if (t.contains('weight') || t.contains('load')) return 'kg';
    if (t.contains('idle')) return 'min';
    if (t.contains('movement')) return 'm';
    if (t.contains('geofence')) return 'm';
    return '';
  }

  static String formatRule(String type, String operator, double value, [String? existingUnit]) {
    final unit = (existingUnit != null && existingUnit.isNotEmpty) 
        ? existingUnit 
        : getSiUnit(type);
    
    String opSymbol = operator;
    if (operator == 'gt') opSymbol = '>';
    if (operator == 'lt') opSymbol = '<';
    if (operator == 'eq') opSymbol = '=';
    if (operator == 'gte') opSymbol = '>=';
    if (operator == 'lte') opSymbol = '<=';

    final capitalizedType = type.isNotEmpty ? '${type[0].toUpperCase()}${type.substring(1)}' : type;
    
    return '$capitalizedType $opSymbol $value $unit'.trim();
  }

  static String formatAlertMessage(String type, String message) {
    final unit = getSiUnit(type);
    if (unit.isEmpty) return message;
    
    // If the message already contains the unit, return as is
    if (message.toLowerCase().contains(unit.toLowerCase())) {
      return message;
    }
    
    // Many alerts are just "Speed exceeded 25". We can append the unit.
    // If it ends with a number, just append. 
    return '$message $unit'.trim();
  }
}
