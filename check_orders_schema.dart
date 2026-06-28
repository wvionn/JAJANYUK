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

  // Check existing orders to see what payment_status values exist
  var req2 = await client.getUrl(Uri.parse('$url/rest/v1/orders?select=id,payment_status,order_status&limit=10'));
  req2.headers.add('apikey', key);
  req2.headers.add('Authorization', 'Bearer $key');
  var res2 = await req2.close();
  var body2 = await res2.transform(utf8.decoder).join();
  print('Existing orders: $body2');
  
  // Check the OpenAPI definition for orders
  var req3 = await client.getUrl(Uri.parse('$url/rest/v1/'));
  req3.headers.add('apikey', key);
  req3.headers.add('Authorization', 'Bearer $key');
  var res3 = await req3.close();
  var body3 = await res3.transform(utf8.decoder).join();
  
  try {
    final spec = jsonDecode(body3) as Map<String, dynamic>;
    final defs = spec['definitions'] as Map<String, dynamic>?;
    if (defs != null && defs.containsKey('orders')) {
      final orderDef = defs['orders'];
      final props = orderDef['properties'] as Map<String, dynamic>?;
      if (props != null) {
        print('\n--- ORDERS COLUMN DEFINITIONS ---');
        for (var entry in props.entries) {
          print('  ${entry.key}: ${jsonEncode(entry.value)}');
        }
      }
    } else {
      // Print all available definitions
      print('\nAvailable table definitions: ${defs?.keys.toList()}');
    }
  } catch (e) {
    print('Error parsing spec: $e');
  }

  client.close();
}
