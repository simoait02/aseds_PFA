import 'package:aseds/main.dart';
import 'package:aseds/myScreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context,snapshot){
          if(snapshot.connectionState== ConnectionState.waiting){
            return const Center(
              child:CircularProgressIndicator(),
            );
          }else if(snapshot.hasError){
            return const Center(
              child: Text("Error")
            );
          }else{
            if (snapshot.data==null){
              return Login();
            }else{
              return Application();
            }
          }
        },
      ),
    );
  }
}
