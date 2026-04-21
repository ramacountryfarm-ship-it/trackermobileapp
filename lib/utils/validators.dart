class Validators {
  static String? required(String? v, [String field = 'This field']) {
    if (v == null || v.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? number(String? v, [String field = 'This field']) {
    if (v == null || v.trim().isEmpty) return '$field is required';
    if (double.tryParse(v) == null) return 'Enter a valid number';
    return null;
  }

  static String? positiveNumber(String? v, [String field = 'This field']) {
    if (v == null || v.trim().isEmpty) return '$field is required';
    final n = double.tryParse(v);
    if (n == null) return 'Enter a valid number';
    if (n <= 0) return 'Must be greater than 0';
    return null;
  }

  static String? optionalNumber(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    if (double.tryParse(v) == null) return 'Enter a valid number';
    return null;
  }
}
