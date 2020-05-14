import 'package:chat/chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

void main() {
  runApp( MyApp());
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sistema de Chat ',
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
