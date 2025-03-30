import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'models/chat_session.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final Box<ChatSession> chatBox = Hive.box<ChatSession>('chat_sessions');
  ChatSession? currentChat;
  final TextEditingController _controller = TextEditingController();
  final String apiKey = dotenv.env['OPENAI_API_KEY'] ?? "";
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Auth instance

  @override
  void initState() {
    super.initState();
    if (chatBox.isNotEmpty) {
      currentChat = chatBox.values.last; // Load last session
    } else {
      createNewChat(); // Auto-create a new chat if none exist
    }
  }

  void createNewChat() {
    String chatId = DateTime.now().millisecondsSinceEpoch.toString();
    ChatSession newChat = ChatSession(
      id: chatId,
      title: "New Chat", // Default title until user sends a message
      messages: [],
    );
    chatBox.put(chatId, newChat);
    setState(() {
      currentChat = newChat;
    });
  }

  void updateChatTitle() {
    if (currentChat == null || currentChat!.messages.isEmpty) return;
    String firstMessage = currentChat!.messages.first["text"]!;
    String shortTitle =
        firstMessage.length > 30 ? firstMessage.substring(0, 30) + "..." : firstMessage;

    setState(() {
      currentChat!.title = shortTitle;
    });

    chatBox.put(currentChat!.id, currentChat!);
  }

  void renameChat(String newTitle) {
    if (currentChat != null) {
      setState(() {
        currentChat!.title = newTitle;
      });
      chatBox.put(currentChat!.id, currentChat!);
    }
  }

  void deleteChat(String chatId) {
    chatBox.delete(chatId);
    setState(() {
      if (chatBox.isNotEmpty) {
        currentChat = chatBox.values.last;
      } else {
        createNewChat();
      }
    });
  }

  Future<void> sendMessage(String message) async {
    if (currentChat == null) return;

    setState(() {
      currentChat!.messages.add({"sender": "user", "text": message});
    });

    if (currentChat!.messages.length == 1) {
      updateChatTitle(); // Set title after first message
    }

    chatBox.put(currentChat!.id, currentChat!);

    final response = await http.post(
      Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": message}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      String reply = "I'm not sure how to respond."; // Default response

      if (data.containsKey("candidates") &&
          data["candidates"].isNotEmpty &&
          data["candidates"][0].containsKey("content") &&
          data["candidates"][0]["content"].containsKey("parts") &&
          data["candidates"][0]["content"]["parts"].isNotEmpty &&
          data["candidates"][0]["content"]["parts"][0].containsKey("text")) {
        reply = data["candidates"][0]["content"]["parts"][0]["text"];
      }

      setState(() {
        currentChat!.messages.add({"sender": "bot", "text": reply});
      });

      chatBox.put(currentChat!.id, currentChat!);
    } else {
      print("Error fetching response: ${response.body}");
    }
  }

  void logout() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, "/login"); // Navigate to login screen
  }

  Drawer buildChatHistoryDrawer() {
    final user = _auth.currentUser; // Get logged-in user

    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(10),
              children: [
                ListTile(
                  title: Text("New Chat", style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    createNewChat();
                    Navigator.pop(context);
                  },
                ),
                Divider(),
                ...chatBox.values.map((chat) => ListTile(
                      title: Text(chat.title),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => deleteChat(chat.id),
                      ),
                      onTap: () {
                        setState(() {
                          currentChat = chat;
                        });
                        Navigator.pop(context);
                      },
                      onLongPress: () {
                        TextEditingController renameController = TextEditingController(text: chat.title);
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text("Rename Chat"),
                            content: TextField(controller: renameController),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  renameChat(renameController.text);
                                  Navigator.pop(context);
                                },
                                child: Text("Save"),
                              )
                            ],
                          ),
                        );
                      },
                    )),
              ],
            ),
          ),
          if (user != null)
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.photoURL != null
                      ? NetworkImage(user.photoURL!)
                      : AssetImage('assets/default_avatar.png') as ImageProvider,
                ),
                title: Text(user.displayName ?? "User"),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'logout') logout();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: Colors.red),
                          SizedBox(width: 10),
                          Text("Logout"),
                        ],
                      ),
                    ),
                  ],
                  child: Icon(Icons.arrow_drop_down),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(currentChat?.title ?? "Gemini Chatbot")),
      drawer: buildChatHistoryDrawer(),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(10),
              itemCount: currentChat?.messages.length ?? 0,
              itemBuilder: (context, index) {
                if (currentChat == null || currentChat!.messages.isEmpty) return SizedBox();

                bool isUser = currentChat!.messages[index]["sender"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 5),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blueAccent : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      currentChat!.messages[index]["text"] ?? "Error: No Message",
                      style: TextStyle(color: isUser ? Colors.white : Colors.black),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(hintText: "Type a message..."),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blue),
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      sendMessage(_controller.text);
                      _controller.clear();
                    }
                  },
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
