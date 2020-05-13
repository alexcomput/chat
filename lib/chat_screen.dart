import 'dart:io';

import 'package:chat/chat_message.dart';
import 'package:chat/text_composer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class ChatScrean extends StatefulWidget {
  @override
  _ChatScreanState createState() => _ChatScreanState();
}

class _ChatScreanState extends State<ChatScrean> {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final GlobalKey<ScaffoldState> _scaffoldkey = GlobalKey<ScaffoldState>();

  FirebaseUser _currentUser;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.onAuthStateChanged.listen((user) {
      _currentUser = user;
    });
  }

  Future<FirebaseUser> _getUser() async {
    if (_currentUser != null) return _currentUser;

    try {
      //Pega a Conta da pesssoas
      final GoogleSignInAccount googleSignInAccount =
          await googleSignIn.signIn();

      // Autenticação no firebase  Pego os dados de autentica e coloco para acessar firebase
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;

      //Para colocar FAcebook instagram entre outros só alterar o Provider
      final AuthCredential credential = GoogleAuthProvider.getCredential(
          idToken: googleSignInAuthentication.idToken,
          accessToken: googleSignInAuthentication.accessToken);

      //Agora conseguimos fazer autenticação no Firebase
      final AuthResult authResult =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final FirebaseUser user = authResult.user;

      return user;
    } catch (error) {
      print(error);
      return null;
    }
  }

  void _sendMenssage({String text, File imageFile}) async {
    final FirebaseUser user = await _getUser();

    if (user == null) {
      _scaffoldkey.currentState.showSnackBar(SnackBar(
        content: Text("Não foi possível fazer o login. Tente novamente "),
        backgroundColor: Colors.red,
      ));
    }

    Map<String, dynamic> data = {
      'uid': user.uid,
      'senderName': user.displayName,
      'senderPhotoUrl': user.photoUrl
    };

    if (imageFile != null) {
      StorageUploadTask task = FirebaseStorage.instance
          .ref()
          .child("imagens")
          .child(DateTime.now().millisecondsSinceEpoch.toString())
          .putFile(imageFile);

      StorageTaskSnapshot taskSnapshot = await task.onComplete;
      data['imgUrl'] = await taskSnapshot.ref.getDownloadURL();
    }

    if (text != null) data['text'] = text;

    Firestore.instance.collection('messages').add(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldkey,
      appBar: AppBar(
        title: Text("Olá"),
        elevation: 0,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: Firestore.instance.collection("messages").snapshots(),
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.none:
                  case ConnectionState.waiting:
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  default:
                    List<DocumentSnapshot> documents =
                        snapshot.data.documents.reversed.toList();

                    return ListView.builder(
                        itemCount: documents.length,
                        reverse: true,
                        itemBuilder: (context, index) {
                          return ChatMessage(documents[index].data, true);
                        });
                }
              },
            ),
          ),
          TextComposer(_sendMenssage),
        ],
      ),
    );
  }
}
