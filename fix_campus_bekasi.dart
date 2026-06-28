import 'dart:convert';
import 'dart:io';

void main() async {
  final file = File('.env');
  final lines = await file.readAsLines();
  String url = '';
  String key = '';
  for(var line in lines) {
    if(line.startsWith('SUPABASE_URL=')) url = line.split('=')[1];
    if(line.startsWith('SUPABASE_ANON_KEY=')) key = line.split('=')[1];
  }
  
  final client = HttpClient();
  
  // Update vendors campus_id to Kampus Bekasi
  var req = await client.patchUrl(Uri.parse('$url/rest/v1/vendors?id=not.is.null'));
  req.headers.add('apikey', key);
  req.headers.add('Authorization', 'Bearer $key');
  req.headers.add('Content-Type', 'application/json');
  req.headers.add('Prefer', 'return=minimal');
  
  final bodyData = jsonEncode({'campus_id': 'bc3287ef-8742-4863-b3b3-993155e13ecc'});
  req.write(bodyData);
  
  var res = await req.close();
  print('Update vendors status: ${res.statusCode}');
  
  // Update users campus_id to Kampus Bekasi
  var req2 = await client.patchUrl(Uri.parse('$url/rest/v1/users?id=not.is.null'));
  req2.headers.add('apikey', key);
  req2.headers.add('Authorization', 'Bearer $key');
  req2.headers.add('Content-Type', 'application/json');
  req2.headers.add('Prefer', 'return=minimal');
  
  req2.write(bodyData);
  var res2 = await req2.close();
  print('Update users status: ${res2.statusCode}');
}
