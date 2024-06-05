import "package:firebase_auth/firebase_auth.dart";
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'SignUp.dart';
import 'monitoring.dart';
import 'myScreen.dart';
import 'wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  PostMonitorService();
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Wrapper(),
  ));
}

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _statePassword = true;
  final DatabaseReference _db = FirebaseDatabase.instance.ref("users");

  void Registre(BuildContext context){
    Navigator.pushNamed(context, "/SignUp");
  }

  Future<UserCredential> signInWithFacebook() async {
    // Trigger the sign-in flow
    final LoginResult loginResult = await FacebookAuth.instance.login();

    // Create a credential from the access token
    final OAuthCredential facebookAuthCredential = FacebookAuthProvider.credential(loginResult.accessToken!.token);

    // Once signed in, return the UserCredential
    return FirebaseAuth.instance.signInWithCredential(facebookAuthCredential);
  }
  Future<UserCredential> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/background.png"),
            fit: BoxFit.cover,
          ),
        ),
        height: MediaQuery.of(context).size.height,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Image.asset("assets/logo.png"),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: const Text(
                  "Welcome Back !",
                  style: TextStyle(
                    fontFamily: "Aldrich",
                    fontSize: 32,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(40, 0, 0, 20),
                child: const Text(
                  "entrez vos informations",
                  style: TextStyle(
                    fontFamily: "NothingYouCouldDo",
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
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
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                child: TextFormField(
                  obscureText: _statePassword,
                  controller: _password,
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
                  ),
                ),
              ),
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.fromLTRB(0, 40, 0, 0),
                child: OutlinedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFEEC86),
                    minimumSize: const Size(253, 54),
                    shape: const StadiumBorder(),
                    side: const BorderSide(width: 2, color: Colors.black),
                  ),
                  onPressed: () {
                      FirebaseAuth.instance.signInWithEmailAndPassword(email: _email.text, password: _password.text).then((value) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => Application()),
                              (route) => false,
                        );
                      }).onError((error, stackTrace) {
                        String errorMessage="";
                        if (error is FirebaseAuthException) {
                          String errorCode = (error).code;
                          switch (errorCode) {
                            case "invalid-email":
                              errorMessage = "The email address is invalid.";
                              break;
                            case "invalid-credential":
                              errorMessage="incorrect email or password";
                              break;
                            default:
                              errorMessage="please fill the fields correctly";
                              break;
                          }
                        } else {
                          errorMessage = "An unknown error occurred";
                        }
                        Fluttertoast.showToast(
                          msg: errorMessage,
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          backgroundColor: Colors.red,
                          textColor: Colors.white,);
                      });
                  },
                  child: const Text(
                    "Sign in",
                    style: TextStyle(color: Colors.black, fontSize: 20),
                  ),
                ),
              ),
              Container(
                alignment: Alignment.center,
                child: const Text(
                  "--------------- or ---------------",
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 60,
                    width: 60,
                    child: IconButton(
                      onPressed: () async {
                        try {
                          UserCredential userCredential = await signInWithGoogle();
                          DatabaseEvent snapshotEvent = await _db.child(userCredential.user!.uid).once();
                          DataSnapshot snapshot = snapshotEvent.snapshot;

                          if (!snapshot.exists) {
                            await _db.child(userCredential.user!.uid).set({
                              "displayName": userCredential.user!.displayName,
                              "email": userCredential.user!.email,
                              "photoUrl": userCredential.user!.photoURL
                            });
                          }
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => Application()),
                                (route) => false,
                          );
                        } catch (e) {
                          print("*******************************"+e.toString());
                          Fluttertoast.showToast(
                            msg: "Error signing in with Google",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            backgroundColor: Colors.red,
                            textColor: Colors.white,);
                        }
                      },
                      icon: Image.asset("assets/google.png"),
                    ),
                  ),
                  SizedBox(
                    height: 60,
                    width: 60,
                    child: IconButton(
                      onPressed: () async {
                        try {
                          UserCredential userCredential = await signInWithFacebook();
                          DatabaseEvent snapshotEvent = await _db.child(userCredential.user!.uid).once();
                          DataSnapshot snapshot = snapshotEvent.snapshot;

                          if (!snapshot.exists) {
                            await _db.child(userCredential.user!.uid).set({
                              "displayName": userCredential.user!.displayName,
                              "email": userCredential.user!.email,
                              "photoUrl": userCredential.user!.photoURL
                            });
                          }
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) =>Application()),
                                (route) => false,
                          );
                          Navigator.push(context, MaterialPageRoute(builder: (context) => Application()));
                        } catch (e) {
                          print("**********************************$e");
                          if(e.toString()!="Null check operator used on a null value"){
                            Fluttertoast.showToast(
                                msg: "Error signing in with Facebook",
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM,
                                backgroundColor: Colors.red,
                                textColor: Colors.white,);
                          }
                        }
                      },
                      icon: Image.asset("assets/facebook.png"),
                    ),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account! "),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context)=>const Register()));
                    },
                    child: const Text(
                      "register now!",
                      style: TextStyle(color: Color(0xFF75399F)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
