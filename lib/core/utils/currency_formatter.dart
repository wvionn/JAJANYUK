import 'package:intl/intl.dart';

extension RupiahFormatter on num {
  String toRupiah() {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(this);
  }
}
