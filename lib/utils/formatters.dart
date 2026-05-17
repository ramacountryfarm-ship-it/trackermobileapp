import 'package:intl/intl.dart';

class Fmt {
  static final _inr = NumberFormat.currency(locale: 'en_IN', symbol: '\u20B9', decimalDigits: 0);
  static final _inrDecimal = NumberFormat.currency(locale: 'en_IN', symbol: '\u20B9', decimalDigits: 2);
  static final _dateFull = DateFormat('dd MMM yyyy');
  static final _dateShort = DateFormat('dd/MM/yyyy');
  static final _dateApi = DateFormat('yyyy-MM-dd');
  static final _num = NumberFormat('#,##,###', 'en_IN');
  static final _decimal = NumberFormat('#,##,###.##', 'en_IN');

  static String currency(num? v) => v == null ? '\u20B90' : _inr.format(v);
  static String currencyDecimal(num? v) => v == null ? '\u20B90.00' : _inrDecimal.format(v);
  static String date(DateTime? d) => d == null ? '-' : _dateFull.format(d);
  static String dateShort(DateTime? d) => d == null ? '-' : _dateShort.format(d);
  static String dateApi(DateTime d) => _dateApi.format(d);
  static String number(num? v) => v == null ? '0' : _num.format(v);
  static String decimal(num? v) => v == null ? '0' : _decimal.format(v);
  static String kg(num? v) => v == null ? '0 kg' : '${_decimal.format(v)} kg';
  static String money(num? v) => v == null ? '0' : _num.format(v);
  static String compact(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
  static String dateDisplay(String? s) {
    if (s == null || s.isEmpty) return '-';
    try {
      final d = DateTime.parse(s);
      return DateFormat('dd MMM').format(d);
    } catch (_) { return s; }
  }
}
