import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
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
      title: "Chat on ${DateTime.now().toLocal()}",
      messages: [],
    );
    chatBox.put(chatId, newChat);
    setState(() {
      currentChat = newChat;
    });
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
    if (currentChat == null) return; // Prevent crashes if no chat exists

    setState(() {
      currentChat!.messages.add({"sender": "user", "text": message});
    });

    chatBox.put(currentChat!.id, currentChat!); // Ensure Hive saves message

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
      String reply = data["candidates"][0]["content"]["parts"][0]["text"];

      setState(() {
        currentChat!.messages.add({"sender": "bot", "text": reply});
      });

      chatBox.put(currentChat!.id, currentChat!); // Save response in Hive
    }
  }

  Drawer buildChatHistoryDrawer() {
    return Drawer(
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
                      currentChat!.messages[index]["text"]!,
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
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(),
                    ),
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
// import 'dart:convert';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:hive/hive.dart';
// import 'package:http/http.dart' as http;
// import 'models/chat_session.dart';

// class ChatScreen extends StatefulWidget {
//   @override
//   _ChatScreenState createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final Box<ChatSession> chatBox = Hive.box<ChatSession>('chat_sessions');
//   ChatSession? currentChat;
//   final TextEditingController _controller = TextEditingController();
//   final String apiKey = dotenv.env['OPENAI_API_KEY'] ?? "";
//   User? user = FirebaseAuth.instance.currentUser; // Get logged-in user info

//   @override
//   void initState() {
//     super.initState();
//     if (chatBox.isNotEmpty) {
//       currentChat = chatBox.values.last;
//     } else {
//       createNewChat();
//     }
//   }

//   void createNewChat() {
//     String chatId = DateTime.now().millisecondsSinceEpoch.toString();
//     ChatSession newChat = ChatSession(
//       id: chatId,
//       title: "Chat on ${DateTime.now().toLocal()}",
//       messages: [],
//     );
//     chatBox.put(chatId, newChat);
//     setState(() {
//       currentChat = newChat;
//     });
//   }

//   void renameChat(String newTitle) {
//     if (currentChat != null) {
//       setState(() {
//         currentChat!.title = newTitle;
//       });
//       chatBox.put(currentChat!.id, currentChat!);
//     }
//   }

//   void deleteChat(String chatId) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text("Delete Chat"),
//         content: Text("Are you sure you want to delete this chat?"),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text("Cancel"),
//           ),
//           TextButton(
//             onPressed: () {
//               chatBox.delete(chatId);
//               setState(() {
//                 if (chatBox.isNotEmpty) {
//                   currentChat = chatBox.values.last;
//                 } else {
//                   createNewChat();
//                 }
//               });
//               Navigator.pop(context);
//             },
//             child: Text("Delete", style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> sendMessage(String message) async {
//     if (currentChat == null) return;

//     setState(() {
//       currentChat!.messages.add({"sender": "user", "text": message});
//     });

//     chatBox.put(currentChat!.id, currentChat!);

//     final response = await http.post(
//       Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey"),
//       headers: {"Content-Type": "application/json"},
//       body: jsonEncode({
//         "contents": [
//           {
//             "parts": [
//               {"text": message}
//             ]
//           }
//         ]
//       }),
//     );

//     if (response.statusCode == 200) {
//       var data = jsonDecode(response.body);
//       String reply = data["candidates"][0]["content"]["parts"][0]["text"];

//       setState(() {
//         currentChat!.messages.add({"sender": "bot", "text": reply});
//       });

//       chatBox.put(currentChat!.id, currentChat!);
//     }
//   }

//   Drawer buildChatHistoryDrawer() {
//     return Drawer(
//       child: Column(
//         children: [
//           UserAccountsDrawerHeader(
//             accountName: Text(user?.displayName ?? "Guest"),
//             accountEmail: Text(user?.email ?? "No email"),
//             currentAccountPicture: CircleAvatar(
//               backgroundColor: Colors.white,
//               child: Icon(Icons.person, size: 40, color: Colors.blue),
//             ),
//           ),
//           ListTile(
//             title: Text("New Chat", style: TextStyle(fontWeight: FontWeight.bold)),
//             leading: Icon(Icons.add),
//             onTap: () {
//               createNewChat();
//               Navigator.pop(context);
//             },
//           ),
//           Divider(),
//           Expanded(
//             child: ListView.builder(
//               padding: EdgeInsets.all(10),
//               itemCount: chatBox.values.length,
//               itemBuilder: (context, index) {
//                 ChatSession chat = chatBox.getAt(index)!;
//                 return ListTile(
//                   title: Text(chat.title),
//                   trailing: IconButton(
//                     icon: Icon(Icons.delete, color: Colors.red),
//                     onPressed: () => deleteChat(chat.id),
//                   ),
//                   onTap: () {
//                     setState(() {
//                       currentChat = chat;
//                     });
//                     Navigator.pop(context);
//                   },
//                   onLongPress: () {
//                     TextEditingController renameController = TextEditingController(text: chat.title);
//                     showDialog(
//                       context: context,
//                       builder: (context) => AlertDialog(
//                         title: Text("Rename Chat"),
//                         content: TextField(controller: renameController),
//                         actions: [
//                           TextButton(
//                             onPressed: () {
//                               renameChat(renameController.text);
//                               Navigator.pop(context);
//                             },
//                             child: Text("Save"),
//                           )
//                         ],
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: Text(currentChat?.title ?? "Gemini Chatbot"),
//         backgroundColor: Colors.white,
//       ),
//       drawer: buildChatHistoryDrawer(),
//       body: Column(
//         children: [
//           Expanded(
//             child: ListView.builder(
//               padding: EdgeInsets.all(10),
//               itemCount: currentChat?.messages.length ?? 0,
//               itemBuilder: (context, index) {
//                 bool isUser = currentChat!.messages[index]["sender"] == "user";
//                 return Align(
//                   alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
//                   child: Container(
//                     margin: EdgeInsets.symmetric(vertical: 5),
//                     padding: EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: isUser ? Colors.blueAccent : Colors.grey[800],
//                       borderRadius: BorderRadius.only(
//                         topLeft: Radius.circular(12),
//                         topRight: Radius.circular(12),
//                         bottomLeft: isUser ? Radius.circular(12) : Radius.zero,
//                         bottomRight: isUser ? Radius.zero : Radius.circular(12),
//                       ),
//                     ),
//                     child: Text(
//                       currentChat!.messages[index]["text"]!,
//                       style: TextStyle(color: Colors.white),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//           Container(
//             padding: EdgeInsets.all(10),
//             decoration: BoxDecoration(color: Colors.white, boxShadow: [
//               BoxShadow(color: Colors.white10, blurRadius: 5),
//             ]),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _controller,
//                     style: TextStyle(color: Colors.white),
//                     decoration: InputDecoration(
//                       hintText: "Type a message...",
//                       hintStyle: TextStyle(color: Colors.grey),
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                 ),
//                 IconButton(
//                   icon: Icon(Icons.send, color: Colors.blue),
//                   onPressed: () {
//                     if (_controller.text.isNotEmpty) {
//                       sendMessage(_controller.text);
//                       _controller.clear();
//                     }
//                   },
//                 )
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
