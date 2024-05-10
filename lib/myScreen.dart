import 'dart:io';

import 'package:aseds/Settings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'main.dart';
void main() => runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home:application()
));
class application extends StatefulWidget{
  @override
  _applicationState createState()=>_applicationState();
}
class _applicationState extends State<application>{
  late DataSnapshot snapshot;
  bool _isloaded=false;
  bool _isComplete=false;
  late String? url;
  DatabaseReference db = FirebaseDatabase.instance.ref("users");
  final TextEditingController _desc = TextEditingController();
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
  var user = FirebaseAuth.instance.currentUser;
  static bool _darkMode=false;
  @override
  void initState() {
    super.initState();
    fetchData().then((_){
      setState(() {
        _isComplete=true;
      });
    });
  }
  late var imageName;
  Future<void> getImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? imageGallery = await picker.pickImage(source: ImageSource.gallery);
    if (imageGallery == null) return;

    try {
      var file = File(imageGallery.path);

      imageName = basename(imageGallery.path);
      var storageReference = FirebaseStorage.instance.ref().child(imageName);

      await storageReference.putFile(file);
      String imageUrl = await storageReference.getDownloadURL();
      setState(() {
        url = imageUrl;
      });
    } catch (e) {
      // Handle the exception here, you can print it for debugging purposes
      print('*************************************Error uploading image: $e');
    }
  }
  Widget _buildIcon() {
    if (snapshot.child("photoUrl").value != null) {
      return CircleAvatar(
        backgroundImage: NetworkImage(snapshot.child("photoUrl").value.toString()),
        radius: 20,
      );
    } else {
      return Icon(
        Icons.account_circle_outlined,
        size: 30,
        color: _darkMode ? Colors.white : Colors.black,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: _darkMode? Color(0xFF212121):Color(0xFFFAFAFA),
        resizeToAvoidBottomInset: true,
        endDrawer: Drawer(
            backgroundColor: _darkMode? Color(0xFF303030):Color(0xFFE0E0E0),
            child: ListView(
              children: [
                Container(
                  alignment: Alignment.center,
                  margin: EdgeInsets.all(30),
                  child:_isComplete?CircleAvatar(
                    backgroundImage: snapshot.child("photoUrl").value != null
                        ? NetworkImage(snapshot.child("photoUrl").value.toString())
                        : AssetImage("assets/profile.png") as ImageProvider<Object>,
                    radius: 50,
                  ):CircleAvatar(
                    backgroundImage: Image.asset("assets/g0R5.gif").image,
                  ),
                ),
                Container(
                    decoration: BoxDecoration(
                        border: Border(
                          top:BorderSide(
                            color: _darkMode? Colors.white:Colors.black,
                          ),
                          bottom: BorderSide(
                            color: _darkMode? Colors.white:Colors.black,
                          ),
                        )
                    ),
                    alignment: Alignment.center,
                    child:Text(
                        _isComplete? snapshot.child("displayName").value.toString():"username",
                        style:TextStyle(
                          fontSize: 20,
                          fontFamily:"opensans",
                          color: _darkMode? Colors.white:Colors.black,
                        )
                    )
                ),
                Container(
                    margin: EdgeInsets.only(top:30),
                    child:ListTile(
                      leading: Icon(!_darkMode?Icons.dark_mode:Icons.light_mode,color: _darkMode? Colors.white:Colors.black,),
                      title: Text(
                          !_darkMode? "Dark mode":"Light mode",
                          style:TextStyle(
                            fontSize: 20,
                            color: _darkMode? Colors.white:Colors.black,
                          )
                      ),
                      onTap: (){
                        setState(() {
                          _darkMode=!_darkMode;
                        });
                      },
                    )
                ),
                ListTile(
                  leading: Icon(Icons.person,color:_darkMode? Colors.white:Colors.black),
                  title: Text(
                      "Profile",
                      style:TextStyle(
                        fontSize: 20,
                        color: _darkMode? Colors.white:Colors.black,
                      )
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.settings,color:_darkMode? Colors.white:Colors.black),
                  title: Text(
                      "Settings",
                      style:TextStyle(
                        fontSize: 20,
                        color: _darkMode? Colors.white:Colors.black,
                      )
                  ),
                  onTap: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>settings(_darkMode)));
                  },
                ),
                ListTile(
                  leading: Icon(Icons.logout,color:_darkMode? Colors.white:Colors.black),
                  title: Text(
                      "Log Out",
                      style:TextStyle(
                        fontSize: 20,
                        color: _darkMode? Colors.white:Colors.black,
                      )
                  ),
                  onTap: (){
                    FirebaseAuth.instance.signOut().then((value) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => Login()),
                            (route) => false,
                      );
                    });
                  },
                )
              ],
            )
        ),
        appBar: AppBar(
            backgroundColor: _darkMode? Color(0xFF303030):Color(0xFFE0E0E0),
            automaticallyImplyLeading: false,
            toolbarHeight: 120, // Set this height
            actions: <Widget>[Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Container(
                      padding: const EdgeInsets.only(top:10,right:35,bottom:10),
                      child:Text(
                        "Bons Plans",
                        style: TextStyle(
                            fontFamily: "aldrich",
                            fontWeight: FontWeight.bold,
                            fontSize: 30,
                            color: _darkMode? Colors.white:Colors.black
                        ),
                      )
                  ),
                  IconButton(
                    onPressed: () {  },
                    icon:Icon(Icons.search_rounded,size:40,color: _darkMode? Colors.white:Colors.black),
                  ),
                  IconButton(
                    onPressed: () {
                      showModalBottomSheet(
                        backgroundColor: _darkMode ? const Color(0xFF212121):const Color(0xFFFAFAFA),
                        context: context,
                        builder: (BuildContext context) {
                          return ListView(
                            padding: EdgeInsets.only(top:20,left:20,right:20,
                                bottom: MediaQuery.of(context).viewInsets.bottom),
                            children: [
                              Container(
                                  margin:const EdgeInsets.only(right:2,left:90),
                                  padding:const EdgeInsets.only(left:200),
                                  child:IconButton(
                                      onPressed: () async {
                                        DatabaseReference ref = FirebaseDatabase.instance.ref("Postes");
                                        await ref.push().set({
                                          "ownerId": user!.uid,
                                          "description": _desc.text,
                                          "photoUrl": url
                                        });
                                      },

                                      icon:Icon(Icons.send,color:_darkMode? Colors.white:Colors.black,size: 30,)
                                  )
                              ),
                              Container(
                                  margin:const EdgeInsets.only(top:5,right:10,left:20),
                                child:Text(
                                  "Add Post's Description:",
                                  style:TextStyle(
                                    color:_darkMode? Colors.white:Colors.black,
                                    fontFamily: "OpenSans",
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold
                                  )
                                )
                              ),
                              Container(
                                margin:const EdgeInsets.only(top:15,right:10,left:10),
                                child: TextField(
                                  style:TextStyle(
                                    color:_darkMode ? Colors.white : Colors.black,
                                  ),
                                  controller: _desc,
                                  maxLines: null,
                                  keyboardType: TextInputType.multiline,
                                  decoration: InputDecoration(
                                    hintText: "Description",
                                    border: const OutlineInputBorder(),
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        _desc.clear();
                                      },
                                      icon: const Icon(Icons.clear),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                margin:const EdgeInsets.only(top:15,right:10,left:20),
                                  child:Text(
                                      "Add Post's Poster:",
                                      style:TextStyle(
                                          color:_darkMode? Colors.white:Colors.black,
                                          fontFamily: "OpenSans",
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold
                                      )
                                  )
                              ),
                              Container(
                                margin:const EdgeInsets.only(top:15,right:10,left:10),
                                child:IconButton(
                                  onPressed: (){getImage();},
                                  icon:Icon(Icons.add_photo_alternate_rounded,color:_darkMode? Colors.white:Colors.black,size: 70,)
                                )
                              ),
                            ],
                          );
                        },
                      );
                    },
                    icon:Icon( Icons.add,size:40,color: _darkMode? Colors.white:Colors.black),
                  ),
                  Builder(builder: (BuildContext context) {
                    return IconButton(
                      onPressed: () {
                        Scaffold.of(context).openEndDrawer();
                      },
                      icon:_buildIcon(),
                    );
                  },
                  )
                ],
              ),
            ),
            ]
        ),
        body: const Column(
          children: [
          ],
        )
    );
  }
}