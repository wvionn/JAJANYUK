// ignore_for_file: avoid_print
// Skrip utility untuk mengecek skema tabel orders di Supabase. Bukan kode produksi.
import 'dart:convert';
import 'dart:io';

void main() async {
  // ── Baca .env ──────────────────────────────────────────────────────────────
  final envFile = File('.env');
  if (!await envFile.exists()) {
    print('ERROR: File .env tidak ditemukan di direktori saat ini.');
    exit(1);
  }

  final lines = await envFile.readAsLines();
  String url = '';
  String key = '';

  for (final line in lines) {
    // Gunakan indexOf agar value yang mengandung '=' tidak terpotong
    final eqIndex = line.indexOf('=');
    if (eqIndex == -1) continue;
    final k = line.substring(0, eqIndex).trim();
    final v = line.substring(eqIndex + 1).trim();
    if (k == 'SUPABASE_URL') url = v;
    if (k == 'SUPABASE_ANON_KEY') key = v;
  }

  if (url.isEmpty || key.isEmpty) {
    print('ERROR: SUPABASE_URL atau SUPABASE_ANON_KEY tidak ditemukan di .env');
    exit(1);
  }

  print('URL  : $url');
  print('KEY  : ${key.substring(0, 10)}...\n');

  final client = HttpClient();

  try {
    // ── 1. Cek isi tabel orders (max 10 baris) ────────────────────────────
    print('=== EXISTING ORDERS (limit 10) ===');
    final req1 = await client.getUrl(
      Uri.parse('$url/rest/v1/orders?select=id,payment_status,order_status&limit=10'),
    );
    req1.headers
      ..add('apikey', key)
      ..add('Authorization', 'Bearer $key')
      ..add('Accept', 'application/json');
    final res1 = await req1.close();
    final body1 = await res1.transform(utf8.decoder).join();
    _prettyPrint(body1);

    // ── 2. Cek definisi kolom orders via OpenAPI ──────────────────────────
    print('\n=== ORDERS TABLE SCHEMA (via OpenAPI) ===');
    final req2 = await client.getUrl(Uri.parse('$url/rest/v1/'));
    req2.headers
      ..add('apikey', key)
      ..add('Authorization', 'Bearer $key')
      ..add('Accept', 'application/json');
    final res2 = await req2.close();
    final body2 = await res2.transform(utf8.decoder).join();

    try {
      final spec = jsonDecode(body2) as Map<String, dynamic>;
      final defs = spec['definitions'] as Map<String, dynamic>?;

      if (defs == null) {
        print('Tidak ada definitions di OpenAPI spec.');
      } else if (!defs.containsKey('orders')) {
        print('Tabel "orders" tidak ditemukan.\nTabel tersedia: ${defs.keys.toList()}');
      } else {
        final props = (defs['orders']['properties'] as Map<String, dynamic>?) ?? {};
        print('Kolom pada tabel orders:\n');
        for (final entry in props.entries) {
          final info = entry.value as Map<String, dynamic>;
          final type = info['type'] ?? info['format'] ?? '?';
          final desc = info['description'] ?? '';
          final enumVals = info['enum'];
          final enumStr = enumVals != null ? '  [enum: $enumVals]' : '';
          print('  ${entry.key.padRight(20)} type: $type$enumStr  $desc');
        }
      }
    } catch (e) {
      print('Gagal parse OpenAPI spec: $e');
      print('Raw response (200 chars): ${body2.length > 200 ? body2.substring(0, 200) : body2}');
    }
  } finally {
    client.close();
  }
}

void _prettyPrint(String jsonStr) {
  try {
    final obj = jsonDecode(jsonStr);
    print(const JsonEncoder.withIndent('  ').convert(obj));
  } catch (_) {
    print(jsonStr);
  }
}
