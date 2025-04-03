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

   Widget buildChatBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: isUser ? Colors.blueAccent : Colors.grey[300],
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              spreadRadius: 1,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(color: isUser ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  Drawer buildChatHistoryDrawer() {
    final user = _auth.currentUser;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user?.displayName ?? "User"),
            accountEmail: Text(user?.email ?? ""),
            currentAccountPicture: CircleAvatar(
              backgroundImage: user?.photoURL != null
                  ? NetworkImage(user!.photoURL!)
                  : AssetImage('assets/default_avatar.png') as ImageProvider,
            ),
          ),
          ListTile(
            leading: Icon(Icons.add, color: Colors.blue),
            title: Text("New Chat"),
            onTap: () {
              createNewChat();
              Navigator.pop(context);
            },
          ),
          Divider(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(10),
              children: chatBox.values.map((chat) {
                return ListTile(
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
                );
              }).toList(),
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text("Logout"),
            onTap: logout,
          ),
        ],
      ),
    );
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(currentChat?.title ?? "Gemini Chatbot"),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 10),
            child: CircleAvatar(
              backgroundImage: _auth.currentUser?.photoURL != null
                  ? NetworkImage(_auth.currentUser!.photoURL!)
                  : AssetImage('assets/default_avatar.png') as ImageProvider,
            ),
          ),
        ],
      ),
      drawer: buildChatHistoryDrawer(),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: EdgeInsets.all(10),
              itemCount: currentChat?.messages.length ?? 0,
              itemBuilder: (context, index) {
                if (currentChat == null || currentChat!.messages.isEmpty) return SizedBox();
                bool isUser = currentChat!.messages.reversed.toList()[index]["sender"] == "user";
                return buildChatBubble(currentChat!.messages.reversed.toList()[index]["text"] ?? "", isUser);
              },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 3)],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.chat_bubble_outline, color: Colors.grey),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (_controller.text.isNotEmpty) {
                      sendMessage(_controller.text);
                      _controller.clear();
                    }
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
