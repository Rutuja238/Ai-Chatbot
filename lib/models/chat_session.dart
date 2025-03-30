import 'package:hive/hive.dart';

part 'chat_session.g.dart';

@HiveType(typeId: 0)
class ChatSession extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  List<Map<String, String>> messages;

  ChatSession({required this.id, required this.title, required this.messages});
}
