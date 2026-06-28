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
  
  // Update users campus_id where it's not null (or where id is not null)
  var req = await client.patchUrl(Uri.parse('$url/rest/v1/users?id=not.is.null'));
  req.headers.add('apikey', key);
  req.headers.add('Authorization', 'Bearer $key');
  req.headers.add('Content-Type', 'application/json');
  req.headers.add('Prefer', 'return=minimal');
  
  final bodyData = jsonEncode({'campus_id': '37b8e9ce-034f-4531-b93e-182743e98fa5'});
  req.write(bodyData);
  
  var res = await req.close();
  print('Update status: ${res.statusCode}');
  var body = await res.transform(utf8.decoder).join();
  print('Response: $body');
}
