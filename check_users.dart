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
  
  // Get users
  var req = await client.getUrl(Uri.parse('$url/rest/v1/users?select=*'));
  req.headers.add('apikey', key);
  req.headers.add('Authorization', 'Bearer $key');
  var res = await req.close();
  var body = await res.transform(utf8.decoder).join();
  print('Users: $body');
}
