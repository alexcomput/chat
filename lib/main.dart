import 'package:chat/chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

void main() {

  runApp(MyApp());
  Firestore.instance.collection("mensagens").document("msg").setData(
      {
        "texto": "Alex SAndro",
        "from": "daniel",
        "read": true
      });
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.green,
        iconTheme: IconThemeData(
          color: Colors.green
        )
      ),
      home: ChatScrean(),
    );
  }
}
