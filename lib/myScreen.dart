import 'dart:io';

import 'package:aseds/Profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';

import 'Settings.dart';
import 'main.dart';

void main() => runApp(MaterialApp(
  debugShowCheckedModeBanner: false,
  home: Application(),
));

class Application extends StatefulWidget {
  @override
  _ApplicationState createState() => _ApplicationState();
}

class _ApplicationState extends State<Application> {
  late DataSnapshot snapshot;
  bool _isComplete = false;
  late String? url;
  var user = FirebaseAuth.instance.currentUser;
  DatabaseReference db = FirebaseDatabase.instance.ref("users");
  final TextEditingController _desc = TextEditingController();
  static bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    fetchData().then((_) {
      setState(() {
        _isComplete = true;
      });
    });
  }

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

  Widget _buildIcon() {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.reference().child('users').child(user!.uid).child('photoUrl').onValue,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Icon(
            Icons.error_outline,
            size: 30,
            color: _darkMode ? Colors.white : Colors.black,
          );
        } else if (snapshot.data.snapshot.value != null) {
          return CircleAvatar(
            backgroundImage: Image.network(
              snapshot.data.snapshot.value.toString(),
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ).image,
          );
        } else {
          return Icon(
            Icons.account_circle_outlined,
            size: 30,
            color: _darkMode ? Colors.white : Colors.black,
          );
        }
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkMode ? const Color(0xFF212121) : const Color(0xFFFAFAFA),
      resizeToAvoidBottomInset: true,
      endDrawer: Drawer(
        backgroundColor: _darkMode ? const Color(0xFF303030) : const Color(0xFFE0E0E0),
        child: ListView(
          children: [
            Container(
              alignment: Alignment.center,
              margin: const EdgeInsets.all(30),
              child: _isComplete
                  ? CircleAvatar(
                backgroundImage: snapshot.child("photoUrl").value !=
                    null
                    ? NetworkImage(
                    snapshot.child("photoUrl").value.toString())
                    : const AssetImage("assets/profile.png") as ImageProvider<Object>,
                radius: 50,
              )
                  : CircleAvatar(
                backgroundImage: Image.asset("assets/g0R5.gif").image,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: _darkMode ? Colors.white : Colors.black,
                  ),
                  bottom: BorderSide(
                    color: _darkMode ? Colors.white : Colors.black,
                  ),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                _isComplete
                    ? snapshot.child("displayName").value.toString()
                    : "username",
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: "opensans",
                  color: _darkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 30),
              child: ListTile(
                leading: Icon(!_darkMode ? Icons.dark_mode : Icons.light_mode,
                    color: _darkMode ? Colors.white : Colors.black),
                title: Text(
                  !_darkMode ? "Dark mode" : "Light mode",
                  style: TextStyle(
                    fontSize: 20,
                    color: _darkMode ? Colors.white : Colors.black,
                  ),
                ),
                onTap: () {
                  setState(() {
                    _darkMode = !_darkMode;
                  });
                },
              ),
            ),
            ListTile(
              leading: Icon(Icons.person,
                  color: _darkMode ? Colors.white : Colors.black),
              title: Text(
                "Profile",
                style: TextStyle(
                  fontSize: 20,
                  color: _darkMode ? Colors.white : Colors.black,
                ),
              ),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Profile(_darkMode)));
              },
            ),
            ListTile(
              leading: Icon(Icons.settings,
                  color: _darkMode ? Colors.white : Colors.black),
              title: Text(
                "Settings",
                style: TextStyle(
                  fontSize: 20,
                  color: _darkMode ? Colors.white : Colors.black,
                ),
              ),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => settings(_darkMode)));
              },
            ),
            ListTile(
              leading: Icon(Icons.logout,
                  color: _darkMode ? Colors.white : Colors.black),
              title: Text(
                "Log Out",
                style: TextStyle(
                  fontSize: 20,
                  color: _darkMode ? Colors.white : Colors.black,
                ),
              ),
              onTap: () {
                FirebaseAuth.instance.signOut().then((value) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const Login()),
                        (route) => false,
                  );
                });
              },
            )
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: _darkMode ? const Color(0xFF303030) : const Color(0xFFE0E0E0),
        automaticallyImplyLeading: false,
        toolbarHeight: 120, // Set this height
        actions: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(left:0),
                padding: EdgeInsets.only(left:0),
                child: Text(
                  "Bons Plans",
                  style: TextStyle(
                      fontFamily: "aldrich",
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                      color: _darkMode ? Colors.white : Colors.black),
                ),
              ),
              Container(
                margin:  const EdgeInsets.only(right: 3,left:30),
                child:Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.search_rounded,
                          size: 40, color: _darkMode ? Colors.white : Colors.black),
                    ),
                    IconButton(
                      onPressed: () {
                        showModalBottomSheet(
                          backgroundColor: _darkMode ? const Color(0xFF212121) : const Color(0xFFFAFAFA),
                          context: context,
                          builder: (BuildContext context) {
                            return ImageSelector(darkMode: _darkMode);
                          },
                        ).then((_) {
                          _desc.clear();
                        });
                      },
                      icon: Icon(Icons.add, size: 40, color: _darkMode ? Colors.white : Colors.black),
                    ),
                    Builder(
                      builder: (BuildContext context) {
                        return SizedBox(
                          height: 60,
                          width: 60,
                          child:IconButton(
                            onPressed: () {
                              Scaffold.of(context).openEndDrawer();
                            },
                            icon: _buildIcon(),
                        ),
                        );

                      },
                    ),
                  ],
                )
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        children: [
          Row(
            children: [
              Container(
                margin:EdgeInsets.only(top:20,left: 20),
                child: const CircleAvatar(
                  backgroundImage: AssetImage("assets/profile.png") as ImageProvider<Object>,
                ),

              ),
              Container(
                margin: EdgeInsets.only(top: 20,left: 10),
                child:Text( "hello world",
                  style:TextStyle(
                    color: _darkMode? Colors.white : Colors.black
                  ),),
              ),
            ],
          ),
          //a remplacer par fitched data (Column description+image)
          Container(
            margin: EdgeInsets.only(top:20),
            height: 200,
            color: Colors.limeAccent,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Row(
                children: [
                  Container(
                    height: 60,
                    width: 60,
                    child: Icon(Icons.favorite_border,size:35,color: _darkMode? Colors.white:Colors.black,),
                  ),
                  Text(
                      "Like",
                    style: TextStyle(
                      color:_darkMode? Colors.white:Colors.black,
                      fontSize: 20,
                    ),
                  )
                ],
              ),
              Row(
                children: [
                  Container(
                    height: 60,
                    width: 60,
                    child: Icon(Icons.mode_comment_outlined,size:32,color: _darkMode? Colors.white:Colors.black,),
                  ),
                  Text(
                    "Comment",
                    style: TextStyle(
                      color:_darkMode? Colors.white:Colors.black,
                      fontSize: 20,
                    ),
                  )
                ],
              ),
              Row(
                children: [
                  Container(
                    height: 60,
                    width: 60,
                    child: Icon(Icons.share_outlined,size:35,color: _darkMode? Colors.white:Colors.black,),
                  ),
                  Text(
                    "Share",
                    style: TextStyle(
                      color:_darkMode? Colors.white:Colors.black,
                      fontSize: 20,
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(right: 15),
                  )
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}

class ImageSelector extends StatefulWidget {
  final bool darkMode;

  const ImageSelector({Key? key, required this.darkMode}) : super(key: key);

  @override
  _ImageSelectorState createState() => _ImageSelectorState();
}

class _ImageSelectorState extends State<ImageSelector> {
  late XFile? imageGallery;
  late var imageName;
  final TextEditingController _desc = TextEditingController();
  late String? url;
  var user = FirebaseAuth.instance.currentUser;
  bool _isloaded = false;
  Future<void> uploadImage() async {
    try {
      var file = File(imageGallery!.path);

      imageName = basename(imageGallery!.path);
      var storageReference = FirebaseStorage.instance.ref().child(imageName);

      await storageReference.putFile(file);
      String imageUrl = await storageReference.getDownloadURL();
      setState(() {
        url = imageUrl;
      });
      DatabaseReference ref = FirebaseDatabase.instance.ref("Postes");
      await ref.push().set({
        "ownerId": user!.uid,
        "description": _desc.text,
        "photoUrl": url
      });
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  Future<void> getImage() async {
    final ImagePicker picker = ImagePicker();
    XFile? pickedImage = await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage == null) return;
    setState(() {
      _isloaded = true;
      imageGallery = pickedImage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      children: [
        Container(
          margin: const EdgeInsets.only(right: 2, left: 90),
          padding: const EdgeInsets.only(left: 200),
          child: IconButton(
            onPressed: () {
              uploadImage();
              Fluttertoast.showToast(
                msg: "post uploaded successfully",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                backgroundColor: Colors.red,
                textColor: Colors.white,);
            },
            icon: Icon(
              Icons.send,
              color: widget.darkMode ? Colors.white : Colors.black,
              size: 30,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 5, right: 10, left: 20),
          child: Text(
            "Add Post's Description:",
            style: TextStyle(
              color: widget.darkMode ? Colors.white : Colors.black,
              fontFamily: "OpenSans",
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 15, right: 10, left: 10),
          child: TextField(
            style: TextStyle(
              color: widget.darkMode ? Colors.white : Colors.black,
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
          margin: const EdgeInsets.only(top: 15, right: 10, left: 20),
          child: Text( _isloaded? "image to post":
            "Add Post's Poster:",
            style: TextStyle(
              color: widget.darkMode ? Colors.white : Colors.black,
              fontFamily: "OpenSans",
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 15),
          child: _isloaded
              ? Image.file(
            File(imageGallery!.path),
            width: 300,
            height: 300,
            fit: BoxFit.cover,
          )
              : IconButton(
                  onPressed: () {
                    getImage();
            },
                icon: Icon(
                  Icons.add_photo_alternate_rounded,
                  color: widget.darkMode ? Colors.white : Colors.black,
                  size: 70,
                ),
          ),
        ),
      ],
    );
  }
}
