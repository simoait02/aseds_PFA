import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';

void main() => runApp(const MaterialApp(
    debugShowCheckedModeBanner: true,
    home:settings(false)
));

class settings extends StatefulWidget{
  final bool _darkMode;
  const settings(this._darkMode, {super.key});
  @override
  _settingsState createState()=>_settingsState();
}
class _settingsState extends State<settings>{
  DatabaseReference db = FirebaseDatabase.instance.ref("users");
  var user = FirebaseAuth.instance.currentUser;
  File? file;
  String? url;
  final TextEditingController _email = TextEditingController();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _Copassword = TextEditingController();

  Future<void> changePasswordWithVerification(String currentPassword, String newPassword) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      AuthCredential credential = EmailAuthProvider.credential(email: user!.email.toString(), password: currentPassword);

      await user.reauthenticateWithCredential(credential);

      await user.updatePassword(newPassword);

      print('***********************************Password updated successfully.');
    } catch (error) {
      print(error);
    }
  }
  Future<void> getImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? imageGallery = await picker.pickImage(source: ImageSource.gallery);
    if (imageGallery == null) return;

    var file = File(imageGallery.path);
    var imageName = basename(imageGallery.path);
    var storageReference = FirebaseStorage.instance.ref().child(user!.uid.toString()).child(imageName);

    await storageReference.putFile(file);
    String imageUrl = await storageReference.getDownloadURL();
    setState(() {
      url = imageUrl;
    });
    db.child(user!.uid).update({"photoUrl": url}).then((_) {
      fetchData();
    });
  }
  late DataSnapshot snapshot;
  bool _isComplete=false;
  Future<void> fetchData() async {
    db.child(user!.uid).onValue.listen((DatabaseEvent event) {
      setState(() {
        snapshot = event.snapshot;
        _isComplete = true;
      });
    });
    snapshot = (await db.child(user!.uid).once()) as DataSnapshot;
    setState(() {});
  }
  @override
  void initState() {
    super.initState();
    fetchData().then((_){
      setState(() {
        _isComplete=true;
      });
    });
  }
  Future<void> changeEmail(String newEmail) async {
    try {
      await user!.updateEmail(newEmail);
      print('*************************************************Email updated successfully.');
    } catch (error) {
      print('Error updating email: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget._darkMode? const Color(0xFF212121):const Color(0xFFFAFAFA),
        resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: widget._darkMode? const Color(0xFF303030):const Color(0xFFE0E0E0),
        title: Container(
          margin: const EdgeInsets.only(left:30),
          child: ListTile(
              leading: Icon(Icons.settings,color: widget._darkMode? Colors.white:Colors.black,),
            title:Text("Settings",
            style: TextStyle(
              fontFamily: "aldrich",
              fontSize: 25,
              color: widget._darkMode? Colors.white:Colors.black,
            ),)
        ),
      ),),
      body:Column(
        children: [
          Container(
            alignment: Alignment.center,
            margin: const EdgeInsets.only(top:40),
            child:_isComplete?CircleAvatar(
              backgroundImage: snapshot.child("photoUrl").value != null
                  ? NetworkImage(snapshot.child("photoUrl").value.toString())
                  : const AssetImage("assets/profile.png") as ImageProvider<Object>,
              radius: 80,
            ):CircleAvatar(backgroundImage: Image.asset("assets/g0R5.gif").image),
          ),
          Container(
            margin: const EdgeInsets.only(top:20),
            child: GestureDetector(
              onTap: () {
                getImage();
              },
              child: const Text(
                "change profile picture",
                style: TextStyle(color: Color(0xFF75399F)),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top:20),
            decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: widget._darkMode? Colors.white:Colors.black,
                  ),
                )
            ),
          ),
          Container(
            margin:const EdgeInsets.only(top:80,right:10,left:10),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(top:10,right:10,left:40,bottom: 10),
            decoration: BoxDecoration(
              border: Border.all(
            color: widget._darkMode ? Colors.white : Colors.black,
              width: 2,
            ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      "Change Email",
                      style: TextStyle(
                        color: widget._darkMode ? Colors.purpleAccent : Colors.purple,
                        fontSize: 20,
                        fontFamily: "aldrich",
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      backgroundColor: widget._darkMode ? const Color(0xFF212121):const Color(0xFFFAFAFA),
                      context: context,
                      builder: (BuildContext context) {
                        return ListView(
                          padding: EdgeInsets.only(top:20,left:20,right:20,
                              bottom: MediaQuery.of(context).viewInsets.bottom),
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                    alignment: Alignment.centerLeft,
                                  child:Text("Current Email:",
                                  style:TextStyle(
                                    color:widget._darkMode ? Colors.white : Colors.black,
                                  ))),
                                Container(
                                  padding: const EdgeInsets.only(top:15,right:10,left:10,bottom: 15),
                                  alignment: Alignment.centerLeft,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: widget._darkMode ? Colors.white : Colors.black,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child:Text(
                                    snapshot.child("email").value.toString(),
                                  style:TextStyle(
                                    fontFamily:"opensans",
                                    fontSize: 15,
                                    color: widget._darkMode ? Colors.purpleAccent : Colors.purple,
                                  )),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(top:5),
                                    alignment: Alignment.centerLeft,
                                    child:Text("New Email:",
                                        style:TextStyle(
                                          color:widget._darkMode ? Colors.white : Colors.black,
                                        ))),
                                TextField(
                                  autofocus: true,
                                  controller: _email,
                                  decoration: InputDecoration(
                                    labelText: "new email",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        _email.clear();
                                      },
                                      icon: const Icon(Icons.clear),
                                    ),
                                  ),
                                  style: TextStyle(color: widget._darkMode ? Colors.white : Colors.black,),
                                ),
                                const SizedBox(height: 20.0),
                                OutlinedButton(
                                  onPressed: () {
                                    changeEmail(_email.text);
                                    db.child(user!.uid).update({"email": _email.text}).then((_) {
                                      fetchData();
                                    });
                                    Navigator.pop(context);
                                    _email.clear();
                                  },
                                  child: const Text("Submit"),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Icon(Icons.navigate_next_outlined,color: widget._darkMode?Colors.white : Colors.black,),
                ),
              ],
            ),
          ),
          Container(
            margin:const EdgeInsets.only(top:40,right:10,left:10),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(top:10,right:10,left:40,bottom: 10),
            decoration: BoxDecoration(
              border: Border.all(
                color: widget._darkMode ? Colors.white : Colors.black,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      "Change User Name",
                      style: TextStyle(
                        color: widget._darkMode ? Colors.purpleAccent : Colors.purple,
                        fontSize: 20,
                        fontFamily: "aldrich",
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      backgroundColor: widget._darkMode ? const Color(0xFF212121):const Color(0xFFFAFAFA),
                      context: context,
                      builder: (BuildContext context) {
                        return ListView(
                          padding: EdgeInsets.only(top:20,left:20,right:20,
                              bottom: MediaQuery.of(context).viewInsets.bottom),
                          children: [Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                  alignment: Alignment.centerLeft,
                                  child:Text("Current Username:",
                                      style:TextStyle(
                                        color:widget._darkMode ? Colors.white : Colors.black,
                                      ))),
                              Container(
                                padding: const EdgeInsets.only(top:15,right:10,left:10,bottom: 15),
                                alignment: Alignment.centerLeft,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: widget._darkMode ? Colors.white : Colors.black,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child:Text(
                                    snapshot.child("displayName").value.toString(),
                                    style:TextStyle(
                                      fontFamily:"opensans",
                                      fontSize: 15,
                                      color: widget._darkMode ? Colors.purpleAccent : Colors.purple,
                                    )),
                              ),
                              Container(
                                  margin: const EdgeInsets.only(top:5),
                                  alignment: Alignment.centerLeft,
                                  child:Text("New Username:",
                                      style:TextStyle(
                                        color:widget._darkMode ? Colors.white : Colors.black,
                                      ))),
                              TextField(
                                autofocus: true,
                                style: TextStyle(color: widget._darkMode ? Colors.white : Colors.black,),
                                controller: _username,
                                decoration: InputDecoration(
                                  labelText: "new username",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      _username.clear();
                                    },
                                    icon: const Icon(Icons.clear),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20.0),
                              OutlinedButton(
                                onPressed: () {
                                  db.child(user!.uid).update({"displayName": _username.text}).then((_) {
                                    fetchData();
                                  });
                                  Navigator.pop(context);
                                  _username.clear();
                                },
                                child: const Text("Submit"),
                              ),
                            ],
                          ),]
                        );
                      },
                    );
                  },
                  child: Icon(Icons.navigate_next_outlined,color: widget._darkMode?Colors.white : Colors.black,),
                ),
              ],
            ),
          ),
          Container(
            margin:const EdgeInsets.only(top:40,right:10,left:10),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(top:10,right:10,left:40,bottom: 10),
            decoration: BoxDecoration(
              border: Border.all(
                color: widget._darkMode ? Colors.white : Colors.black,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      "Change Password",
                      style: TextStyle(
                        color: widget._darkMode ? Colors.purpleAccent : Colors.purple,
                        fontSize: 20,
                        fontFamily: "aldrich",
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      backgroundColor: widget._darkMode ? const Color(0xFF212121):const Color(0xFFFAFAFA),
                      context: context,
                      builder: (BuildContext context) {
                        return ListView(
                          padding: EdgeInsets.only(top:20,left:20,right:20,
                              bottom: MediaQuery.of(context).viewInsets.bottom),
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                    alignment: Alignment.centerLeft,
                                    child:Text("Actual Password:",
                                        style:TextStyle(
                                          color:widget._darkMode ? Colors.white : Colors.black,
                                        ))),
                                TextField(
                                  autofocus: true,
                                  style: TextStyle(color: widget._darkMode ? Colors.white : Colors.black,),
                                  controller: _password,
                                  decoration: InputDecoration(
                                    labelText: "Actual Password",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        _password.clear();
                                      },
                                      icon: const Icon(Icons.clear),
                                    ),
                                  ),
                                ),
                                Container(
                                    margin: const EdgeInsets.only(top:5),
                                    alignment: Alignment.centerLeft,
                                    child:Text("New password:",
                                        style:TextStyle(
                                          color:widget._darkMode ? Colors.white : Colors.black,
                                        ))),
                                TextField(
                                  style: TextStyle(color: widget._darkMode ? Colors.white : Colors.black,),
                                  controller: _Copassword,
                                  decoration: InputDecoration(
                                    labelText: "New Password",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        _Copassword.clear();
                                      },
                                      icon: const Icon(Icons.clear),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20.0),
                                OutlinedButton(
                                  onPressed: () {
                                    changePasswordWithVerification(_password.text, _Copassword.text);
                                    Navigator.pop(context);
                                    _Copassword.clear();
                                    _password.clear();
                                  },
                                  child: const Text("Submit"),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Icon(Icons.navigate_next_outlined,color: widget._darkMode?Colors.white : Colors.black,),
                ),
              ],
            ),
          ),
        ],
      )
    );
  }
}