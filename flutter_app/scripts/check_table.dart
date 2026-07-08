import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  await Supabase.initialize(
      url: 'https://mskizgdxpcuuqzjlblou.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1za2l6Z2R4cGN1dXF6amxibG91Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA5MDk0NzgsImV4cCI6MjA5NjQ4NTQ3OH0.gwAKQFhfeLMLUh4I1L4UUORv8hVQ1HzNvLTGQvs4ib4');

  final client = Supabase.instance.client;
  
  try {
    final response = await client.from('trackman_tasks').select().limit(1);
    if (response.isNotEmpty) {
      print("COLUMNS: ${response.first.keys.toList()}");
    } else {
      print("TABLE EMPTY, NO COLUMNS RETURNED");
    }
  } catch (e) {
    print("TABLE ERROR: $e");
  }
}
