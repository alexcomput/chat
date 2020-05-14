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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.onAuthStateChanged.listen((user) {
      setState(() {
        _currentUser = user;
      });
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
      'senderPhotoUrl': user.photoUrl,
      'time': Timestamp.now()
    };

    //Enviando a imagem
    if (imageFile != null) {
      StorageUploadTask task = FirebaseStorage.instance
          .ref()
          .child(user.uid)
          .child(user.uid + DateTime.now().millisecondsSinceEpoch.toString())
          .putFile(imageFile);
      // Start send Image
      setState(() {
        _isLoading = true;
      });
      StorageTaskSnapshot taskSnapshot = await task.onComplete;
      data['imgUrl'] = await taskSnapshot.ref.getDownloadURL();
      //End Send Image
      setState(() {
        _isLoading = false;
      });
    }

    if (text != null) data['text'] = text;

    Firestore.instance.collection('messages').add(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldkey,
      appBar: AppBar(
        title: Text(_currentUser != null
            ? "Olá. ${_currentUser.displayName}"
            : " MEU CHAT",),
        centerTitle: true,
        elevation: 0,
        actions: <Widget>[
          _currentUser != null
              ? IconButton(
                  icon: Icon(
                    Icons.exit_to_app,
                  ),
                  onPressed: () {
                    FirebaseAuth.instance.signOut();
                    googleSignIn.signOut();
                    _scaffoldkey.currentState.showSnackBar(SnackBar(
                      content: Text("Você saiu com sucesso! "),
                    ));
                  },
                )
              : Container(),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: Firestore.instance
                  .collection("messages")
                  .orderBy("time")
                  .snapshots(),
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
                          return ChatMessage(
                              documents[index].data,
                              documents[index].data['uid'] ==
                                  _currentUser?.uid);
                        });
                }
              },
            ),
          ),
          _isLoading ? LinearProgressIndicator() : Container(),
          TextComposer(_sendMenssage),
        ],
      ),
    );
  }
}
