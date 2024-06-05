import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'myScreen.dart';
import 'main.dart';

void main()=>runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home:Register()
));
class Register extends StatefulWidget{
  const Register({super.key});

  @override
  _RegisterState createState()=> _RegisterState();
  }

class _RegisterState extends State<Register>{
  final DatabaseReference _db = FirebaseDatabase.instance.ref("users");
  final TextEditingController _email = TextEditingController();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _Copassword = TextEditingController();
  bool _statePassword = true;
  bool _stateCoPassword=true;
  var _validatePassword;
  var _validateEmail;
  var _validateUserName;
  var _pass;
  var _copass;
  bool passValid=true;
  bool emailValid=true;
  bool usernameValid=true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage("assets/background.png"),fit: BoxFit.cover)
        ),
        height: MediaQuery.of(context).size.height,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Image.asset("assets/logo.png"),
              Container(
                padding: const EdgeInsets.fromLTRB(16,0,16,0),
                child: const Text(
                  "Create \n   account :)",
                  style: TextStyle(
                    fontFamily: "Aldrich",
                    fontSize: 28,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              Container(
                  padding: const EdgeInsets.all(4),
                  child: TextField(
                    controller: _email,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.email_rounded),
                      labelText: "email",
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () {
                          _email.clear();
                        },
                        icon: const Icon(Icons.clear),
                      ),
                      errorText: _validateEmail,
                    ),
                  )
              ),
              Container(
                  padding: const EdgeInsets.all(4),
                  child: TextField(
                    controller: _username,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person),
                      labelText: "user name",
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () {
                          _username.clear();
                        },
                        icon: const Icon(Icons.clear),
                      ),
                      errorText: _validateUserName,
                    ),
                  )
              ),
              Container(
                  padding: const EdgeInsets.all(4),
                  child: TextField(
                    controller: _password,
                    obscureText: _statePassword,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.password),
                      labelText: "password",
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _statePassword = !_statePassword;
                          });
                        },
                        icon: Icon(
                          _statePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                      errorText: _pass
                    ),
                  )
              ),
              Container(
                  padding: const EdgeInsets.all(4),
                  child: TextField(
                    controller: _Copassword,
                    obscureText: _stateCoPassword,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.password),
                      labelText: "Confirm password",
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _stateCoPassword = !_stateCoPassword;
                          });
                        },
                        icon: Icon(
                          _stateCoPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                      errorText: _Copassword.text.isEmpty? _copass:_validatePassword,
                    ),
                  )
              ),
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.fromLTRB(0,15,0,0),
                child:OutlinedButton(
                    style:ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFEEC86),
                      minimumSize: const Size(253, 54),
                      shape:const StadiumBorder(),
                      side: const BorderSide(width: 2,color: Colors.black),
                    ),
                    onPressed: () {
                      setState(() {
                        if(_password.text==_Copassword.text){
                          _validatePassword=null;
                          passValid=true;
                        }
                        if (_password.text!=_Copassword.text){
                          _validatePassword="fill not match password";
                          passValid=false;
                        }if (_Copassword.text.isEmpty){
                          _copass="case must be filled";
                        }
                        if (_Copassword.text.isNotEmpty){
                          _copass=null;
                        }
                        if (_email.text.length<=4 ){
                          _validateEmail="enter a valid email";
                          emailValid=false;
                        }if(_email.text.length>4 ){
                          _validateEmail=null;
                          emailValid=true;
                        }
                        if(_username.text.length<=4){
                          _validateUserName="enter a valid username";
                          usernameValid=false;
                        }if(_username.text.length>4 ){
                          _validateUserName=null;
                          usernameValid=true;
                        }if(_password.text.isEmpty){
                          _pass="password isn't empty";
                        }
                        if(_password.text.isNotEmpty){
                          _pass=null;
                        }if (emailValid==true && passValid==true && usernameValid==true){
                          FirebaseAuth.instance.createUserWithEmailAndPassword(email: _email.text, password: _password.text).then((value) {
                            var user = FirebaseAuth.instance.currentUser;
                            if (user!=null){
                              user.updateDisplayName(_username.text).then((_) async {
                                await _db.child(user.uid).set({
                                  "displayName":_username.text,
                                  "email":user.email,
                                  "photoUrl":user.photoURL
                                });
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (context) => Application()),
                                      (route) => false,
                                );
                              }).catchError((error) {
                                Fluttertoast.showToast(
                                  msg: "faild to add username",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.BOTTOM,
                                  backgroundColor: Colors.red,
                                  textColor: Colors.white,);
                              });
                            }
                          }).onError((error, stackTrace) {
                            if (error is FirebaseAuthException) {
                              String errorCode = (error).code;
                              Fluttertoast.showToast(
                                msg: errorCode,
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM,
                                backgroundColor: Colors.red,
                                textColor: Colors.white,);
                            }
                          });
                        }
                      });
                    },
                    child: const Text(
                      "Sign up",style: TextStyle(
                        color:Colors.black,
                        fontSize: 20
                    ),)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                      padding: const EdgeInsets.fromLTRB(0,15,0,0),
                      child: const Text(
                          "Already have an account! "
                      )
                  ),
                  Container(
                      padding: const EdgeInsets.fromLTRB(0,15,0,0),
                      child: GestureDetector(
                        onTap:(){
                          Navigator.push(context, MaterialPageRoute(builder: (context)=>Login()));},
                        child: const Text(
                          "connect now!",
                          style: TextStyle(
                              color:Color(0xFF75399F)
                          ),
                        ),
                      )
                  ),
                ],
              ),
            ],
          ),
        ),
      )
    );
  }
}