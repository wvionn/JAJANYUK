import 'dart:convert';
import 'dart:io';

void main() async {
  final file = File('.env');
  final lines = await file.readAsLines();
  String url = '';
  String key = '';
  for (var line in lines) {
    if (line.startsWith('SUPABASE_URL=')) url = line.split('=')[1].trim();
    if (line.startsWith('SUPABASE_ANON_KEY=')) key = line.split('=')[1].trim();
  }
  
  final client = HttpClient();
  var req = await client.getUrl(Uri.parse(url));
  req.headers.add('apikey', key);
  req.headers.add('Authorization', 'Bearer $key');
  var res = await req.close();
  var body = await res.transform(utf8.decoder).join();
  
  final openapi = jsonDecode(body);
  final definitions = openapi['definitions'];
  final orders = definitions['orders'];
  
  print('--- ORDERS TABLE SCHEMA ---');
  print(JsonEncoder.withIndent('  ').convert(orders));
}
