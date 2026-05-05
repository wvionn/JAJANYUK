import 'package:intl/intl.dart';

class Formatters {
  static String currency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp. ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  static String date(DateTime date) {
    final formatter = DateFormat('dd MMM yyyy', 'id_ID');
    return formatter.format(date);
  }

  static String dateTime(DateTime dateTime) {
    final formatter = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
    return formatter.format(dateTime);
  }

  static String time(DateTime time) {
    final formatter = DateFormat('HH:mm', 'id_ID');
    return formatter.format(time);
  }

  static String phoneNumber(String phone) {
    if (phone.startsWith('0')) {
      return '+62${phone.substring(1)}';
    }
    return phone;
  }
}
