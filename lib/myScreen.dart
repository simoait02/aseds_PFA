import 'dart:io';
import 'package:aseds/Profile.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
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

  late String? url;
  var user = FirebaseAuth.instance.currentUser;
  late DataSnapshot snapshot;
  late DataSnapshot item;
  DatabaseReference db = FirebaseDatabase.instance.ref("users");
  DatabaseReference dbp = FirebaseDatabase.instance.ref("Postes");
  final TextEditingController _desc = TextEditingController();
  static bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadMoreItems();
    _scrollController.addListener(() {_scrollListener();});
    dbp.onChildRemoved.listen((DatabaseEvent event) {
      final removedKey = event.snapshot.key;
      setState(() {
        _items.removeWhere((item) => item.key == removedKey);
      });
    });
    fetchData().then((_) {
      setState(() {
      });
    });
  }

  Future<void> fetchData() async {
    db.child(user!.uid).onValue.listen((DatabaseEvent event) {
      setState(() {
        snapshot = event.snapshot;
      });
    });
    snapshot = (await db.once()).snapshot as DataSnapshot;
    setState(() {
    });
  }

  final ScrollController _scrollController = ScrollController();
  bool _loading = false;
  DataSnapshot? _lastFetchedItem;
  final List<dynamic> _items = [];

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreItems();
    }
  }

  Future<void> _loadMoreItems() async {
    if (_loading) return;
    setState(() {
      _loading = true;
    });

    Query query = dbp.orderByKey();
    if (_lastFetchedItem != null) {
      query = query.startAfter(_lastFetchedItem!.key);
    }

    DataSnapshot snapshot = await query.get();
    List<DataSnapshot> fetchedItems = snapshot.children.toList();

    if (fetchedItems.isNotEmpty) {
      setState(() {
        _lastFetchedItem = fetchedItems.last;
        for (int i = 0; i < fetchedItems.length; i++) {
          if (!_items.contains(fetchedItems[i])) {
            _items.insert(0,fetchedItems[i]);
          }
        }
      });
    }

    setState(() {
      _loading = false;
    });
  }
  Widget _buildDisplayName(String id, double size, bool darkMode) {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref().child("users").child(id).child('displayName').onValue,
      builder: (BuildContext context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (snapshot.hasError) {
          return const Text("error");
        } else if (snapshot.hasData && snapshot.data?.snapshot.value != null) {
          return Text(
            snapshot.data!.snapshot.value.toString(),
            style: TextStyle(
              fontSize: size,
              color: darkMode ? Colors.white : Colors.black,
            ),
          );
        } else {
          return const Text("username");
        }
      },
    );
  }
  Widget _buildIcon(String id) {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref().child("users").child(id).child('photoUrl').onValue,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
         if (snapshot.hasError) {
          return Icon(
            Icons.error_outline,
            size: 30,
            color: _darkMode ? Colors.white : Colors.black,
          );
        } else if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          return ClipOval(
            child: CachedNetworkImage(
              placeholder: (context, url) => const CupertinoActivityIndicator(),
              imageUrl: snapshot.data!.snapshot.value.toString(),
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 20),
            ),
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
  Widget _buildProfile() {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref().child('users').child(user!.uid).child('photoUrl').onValue,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Icon(
            Icons.error_outline,
            size: 150,
            color: _darkMode ? Colors.white : Colors.black,
          );
        } else if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          return CircleAvatar(
            radius: 150,
            backgroundImage: NetworkImage(
              snapshot.data!.snapshot.value.toString(),
            ),
          );
        } else {
          return Icon(
            Icons.account_circle_outlined,
            size: 150,
            color: _darkMode ? Colors.white : Colors.black,
          );
        }
      },
    );
  }
  final TextEditingController _comment = TextEditingController();
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
              child: Builder(
                builder: (BuildContext context) {
                  return SizedBox(
                    height: 150,
                    width: 150,
                    child:IconButton(
                      onPressed: () {
                        Scaffold.of(context).openEndDrawer();
                      },
                      icon: _buildProfile(),
                    ),
                  );
                },
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
              child: Builder(
                builder: (BuildContext context) {
                  return _buildDisplayName(user!.uid,20,_darkMode);
                },
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
        toolbarHeight: 120,
        actions: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(right:50),
                padding: EdgeInsets.only(left:5),
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
                              icon: _buildIcon(user!.uid),
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
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _items.length + 1,
              itemBuilder: (context, index) {
                if (index == _items.length) {
                  return _loading ? Center(child: CircularProgressIndicator()) : Container();
                }
                item = _items[index];
                String photoUrl = item.child("photoUrl").value.toString();
                String ownerId = item.child("ownerId").value.toString();
                final screenWidth = MediaQuery.of(context).size.width;
                String postId = item.key!;
                return Card(
                  elevation: 10,
                  key: ValueKey(item.key),
                  color: _darkMode ? const Color(0x004c2d37) : const Color(0xFFE0E1E0),
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ListTile(
                          leading: Container(
                            margin: const EdgeInsets.only(top:5) ,
                            child:Builder(
                              builder: (BuildContext context) {
                                return SizedBox(
                                  height: 60,
                                  width: 50,
                                  child:Builder(
                                    builder: (BuildContext context) {
                                      return _buildIcon(ownerId);
                                    },
                                  ),
                                );
                              },
                            ),),
                          title: Builder(
                            builder: (BuildContext context) {
                              return _buildDisplayName(ownerId, 15, _darkMode);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                    Container(
                        margin: const EdgeInsets.only(left: 10,right: 10),
                        child: Text(
                          item.child("description").value.toString(),
                          style: TextStyle(
                            fontSize: 18,
                            color: _darkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      Container(
                        width: screenWidth,
                        height: 450,
                        color: Colors.black,
                        child: CachedNetworkImage(
                          placeholder: (context, url) => const CupertinoActivityIndicator(),
                          width: screenWidth,
                          height: 450,
                          fit: BoxFit.contain,
                          imageUrl: photoUrl,
                        ),
                      ),
                       Row(
                         mainAxisAlignment: MainAxisAlignment.spaceAround,
                         children: [
                           StreamBuilder(
                             stream: FirebaseDatabase.instance.ref().child("users").child(user!.uid).child('liked').onValue,
                             builder: (BuildContext context, AsyncSnapshot<DatabaseEvent> userSnapshot) {
                              if (userSnapshot.hasError) {
                                return const Text("Error");
                              }
                              List<dynamic> likes = [];
                              if (userSnapshot.hasData && userSnapshot.data?.snapshot.value != null) {
                                likes = List<dynamic>.from(userSnapshot.data!.snapshot.value as Iterable);
                              }

                              return StreamBuilder(
                                stream: FirebaseDatabase.instance.ref().child("Postes").child(postId).child('nbLike').onValue,
                                builder: (BuildContext context, AsyncSnapshot<DatabaseEvent> postSnapshot) {
                                  if (postSnapshot.hasError) {
                                    return const Text("Error");
                                  }
                                  int nbLike = 0;
                                  if (postSnapshot.hasData && postSnapshot.data?.snapshot.value != null) {
                                    nbLike = int.tryParse(postSnapshot.data!.snapshot.value.toString()) ?? 0;
                                  }
                                  return Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () async {
                                          setState(() {
                                            if (likes.contains(postId)) {
                                              likes.remove(postId);
                                              if (nbLike > 0) {
                                                nbLike--;
                                              }
                                            } else {
                                              likes.add(postId);
                                              nbLike++;
                                            }
                                          });
                                          await FirebaseDatabase.instance.ref().child("users").child(user!.uid).child('liked').set(likes);
                                          await FirebaseDatabase.instance.ref().child("Postes").child(postId).child("nbLike").set(nbLike);
                                        },
                                        child: SizedBox(
                                          height: 60,
                                          width: 60,
                                          child: Icon(
                                            likes.contains(postId) ? Icons.favorite : Icons.favorite_border,
                                            size: 32,
                                            color: likes.contains(postId) ? Colors.red : (_darkMode ? Colors.white : Colors.black),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        nbLike.toString(),
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: _darkMode ? Colors.white : Colors.black,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                           Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  showModalBottomSheet(
                                    backgroundColor: _darkMode ? const Color(0xFF212121) : const Color(0xFFFAFAFA),
                                    context: context,
                                    builder: (BuildContext context) {
                                      return StatefulBuilder(
                                        builder: (BuildContext context, StateSetter setModalState) {
                                          return Padding(
                                            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                                            child: Container(
                                              padding: const EdgeInsets.all(16.0),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: <Widget>[
                                                  Text(
                                                    'Comments',
                                                    style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold,color: !_darkMode ? const Color(0xFF212121) : const Color(0xFFFAFAFA),),
                                                  ),
                                                  Expanded(
                                                    child: FutureBuilder<DataSnapshot>(
                                                      future: dbp.child(postId).child('comments').once().then((event) => event.snapshot),
                                                      builder: (context, snapshot) {
                                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                                          return const Center(child: CircularProgressIndicator());
                                                        } else if (snapshot.hasError) {
                                                          return const Center(child: Text('Error loading comments'));
                                                        } else if (!snapshot.hasData || snapshot.data!.children.isEmpty) {
                                                          return Center(
                                                            child: Text(
                                                              'No comments yet',
                                                              style: TextStyle(
                                                                color: !_darkMode ? const Color(0xFF212121) : const Color(0xFFFAFAFA),
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          List<DataSnapshot> commentSnapshots = snapshot.data!.children.toList();
                                                          return ListView.builder(
                                                            shrinkWrap: true,
                                                            itemCount: commentSnapshots.length,
                                                            itemBuilder: (context, index) {
                                                              var commentData = commentSnapshots[index].value as Map<dynamic, dynamic>;
                                                              return Card(
                                                                color: _darkMode ? const Color(0x004c2d37) : const Color(0xFFE0E1E0),
                                                                child: ListTile(
                                                                  leading: Container(
                                                                    height: 60,
                                                                    width: 60,
                                                                    decoration: const BoxDecoration(
                                                                      shape: BoxShape.circle,
                                                                    ),
                                                                    child: Center(
                                                                      child: IconButton(
                                                                        onPressed: () {},
                                                                        icon: _buildIcon(commentData['ownerId']),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                    title: Builder(
                                                                    builder: (BuildContext context) {
                                                                      return _buildDisplayName(commentData['ownerId'],10, _darkMode);
                                                                    },
                                                                  ),
                                                                  subtitle: Text(
                                                                    commentData['comment'] ?? '',
                                                                    style: TextStyle(
                                                                      color: _darkMode ? Colors.white : Colors.black,
                                                                      fontSize: 16,
                                                                    ),
                                                                  ),
                                                                ),
                                                              );

                                                            },
                                                          );
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                  TextField(
                                                    controller: _comment,
                                                    style: TextStyle(
                                                        color: _darkMode ? Colors.white : Colors.black),
                                                    decoration: InputDecoration(
                                                      hintText: 'Add a comment',
                                                      hintStyle: TextStyle(
                                                          color: _darkMode ? Colors.white : Colors.black),
                                                      suffixIcon: IconButton(
                                                        icon: Icon(Icons.send,
                                                            color: _darkMode ? Colors.white : Colors.black),
                                                        onPressed: () async {
                                                          if (_comment.text.isNotEmpty) {
                                                            await dbp.child(postId).child('comments').push().set({
                                                              'comment': _comment.text,
                                                              'ownerId':user!.uid,
                                                            });
                                                            setModalState(() {
                                                              _comment.clear();
                                                            });
                                                          }
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                                child: SizedBox(
                                  height: 60,
                                  width: 60,
                                  child: Icon(
                                    Icons.mode_comment_outlined,
                                    size: 32,
                                    color: _darkMode ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                              Text(
                                "Comment",
                                style: TextStyle(
                                  color: _darkMode ? Colors.white : Colors.black,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                           StreamBuilder(
                             stream: FirebaseDatabase.instance.ref().child("users").child(user!.uid).child('reports').onValue,
                             builder: (BuildContext context, AsyncSnapshot<DatabaseEvent> userSnapshot) {
                               if (userSnapshot.hasError) {
                                 return const Text("Error");
                               }
                               List<dynamic> reports = [];
                               if (userSnapshot.hasData && userSnapshot.data?.snapshot.value != null) {
                                 reports = List<dynamic>.from(userSnapshot.data!.snapshot.value as Iterable);
                               }

                               return StreamBuilder(
                                 stream: FirebaseDatabase.instance.ref().child("Postes").child(postId).child('nbReports').onValue,
                                 builder: (BuildContext context, AsyncSnapshot<DatabaseEvent> postSnapshot) {
                                   if (postSnapshot.hasError) {
                                     return const Text("Error");
                                   }
                                   int nbReports = 0;
                                   if (postSnapshot.hasData && postSnapshot.data?.snapshot.value != null) {
                                     nbReports = int.tryParse(postSnapshot.data!.snapshot.value.toString()) ?? 0;
                                   }
                                   return Row(
                                     children: [
                                       GestureDetector(
                                         onTap: () async {
                                           setState(() {
                                             if (reports.contains(postId)) {
                                               reports.remove(postId);
                                               if (nbReports > 0) {
                                                 nbReports--;
                                               }
                                             } else {
                                               reports.add(postId);
                                               nbReports++;
                                             }
                                           });
                                           await FirebaseDatabase.instance.ref().child("users").child(user!.uid).child('reports').set(reports);
                                           await FirebaseDatabase.instance.ref().child("Postes").child(postId).child("nbReports").set(nbReports);
                                         },
                                         child: SizedBox(
                                           height: 60,
                                           width: 60,
                                           child: Icon(
                                             reports.contains(postId) ? Icons.flag : Icons.flag_outlined,
                                             size: 32,
                                             color: reports.contains(postId) ? Colors.red : (_darkMode ? Colors.white : Colors.black),
                                           ),
                                         ),
                                       ),
                                       Text(
                                         "Report",
                                         style: TextStyle(
                                           fontSize: 20,
                                           color: _darkMode ? Colors.white : Colors.black,
                                         ),
                                       ),
                                     ],
                                   );
                                 },
                               );
                             },
                           ),
                           Container(margin: const EdgeInsets.only(right: 15),)
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
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
  @override
  void initState() {
    super.initState();
    fetchData().then((_) {
      setState(() {});
    });
  }

  late DataSnapshot snapshot;
  DatabaseReference db = FirebaseDatabase.instance.ref("users");

  Future<void> fetchData() async {
    db.child(user!.uid).onValue.listen((DatabaseEvent event) {
      setState(() {
        snapshot = event.snapshot;
      });
    });
    snapshot = (await db.child(user!.uid).once()) as DataSnapshot;
    setState(() {});
  }

  Future<void> uploadImage() async {
    try {
      var file = File(imageGallery!.path);
      var result = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        quality: 50,
      );

      if (result == null) {
        print('Error compressing image');
        return;
      }

      var compressedFile = File(imageGallery!.path)..writeAsBytesSync(result);

      imageName = basename(compressedFile.path);
      var storageReference = FirebaseStorage.instance.ref().child(imageName);

      await storageReference.putFile(compressedFile);
      String imageUrl = await storageReference.getDownloadURL();
      setState(() {
        url = imageUrl;
      });

      DatabaseReference ref = FirebaseDatabase.instance.ref("Postes");
      var newPostRef = ref.push();
      await newPostRef.set({
        "ownerId": user!.uid,
        "description": _desc.text,
        "photoUrl": url,
      });

      Fluttertoast.showToast(
        msg: "post uploaded successfully",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      setState(() {});
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
          child: Text(
            _isloaded ? "image to post" : "Add Post's Poster:",
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
