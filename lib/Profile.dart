import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Profile extends StatefulWidget {
  final bool _darkMode;
  const Profile(this._darkMode, {super.key});
  bool get darkMode => _darkMode;
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String? url;
  var user = FirebaseAuth.instance.currentUser;
  DataSnapshot? snapshot;
  late DataSnapshot item;
  DatabaseReference db = FirebaseDatabase.instance.ref("users");
  DatabaseReference dbp = FirebaseDatabase.instance.ref("Postes");

  final ScrollController _scrollController = ScrollController();
  bool _loading = false;
  DataSnapshot? _lastFetchedItem;
  final List<dynamic> _items = [];
  final TextEditingController _comment = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMoreItems();
    _scrollController.addListener(() {
      _scrollListener();
    });
    dbp.onChildRemoved.listen((DatabaseEvent event) {
      final removedKey = event.snapshot.key;
      setState(() {
        _items.removeWhere((item) => item.key == removedKey);
      });
    });
    fetchData().then((_) {
      setState(() {});
    });
  }

  Future<void> fetchData() async {
    db
        .child(user!.uid)
        .onValue
        .listen((DatabaseEvent event) {
      setState(() {
        snapshot = event.snapshot;
      });
    });
    snapshot = (await db.once()).snapshot;
    setState(() {});
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
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
          item = fetchedItems[i];
          String ownerId = item
              .child("ownerId")
              .value
              .toString();
          print(
              "*************************************************************************${ownerId ==
                  user!.uid}");
          if (ownerId == user!.uid.toString()) {
            if (!_items.contains(fetchedItems[i])) {
              _items.insert(0,fetchedItems[i]);
            }
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
      stream: FirebaseDatabase.instance
          .ref()
          .child("users")
          .child(id)
          .child('displayName')
          .onValue,
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
      stream: FirebaseDatabase.instance
          .ref()
          .child("users")
          .child(id)
          .child('photoUrl')
          .onValue,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasError) {
          return Icon(
            Icons.error_outline,
            size: 30,
            color: widget.darkMode ? Colors.white : Colors.black,
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
            color: widget.darkMode ? Colors.white : Colors.black,
          );
        }
      },
    );
  }

  Widget _buildProfile() {
    return StreamBuilder(
      stream: FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(user!.uid)
          .child('photoUrl')
          .onValue,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Icon(
            Icons.error_outline,
            size: 150,
            color: widget._darkMode ? Colors.white : Colors.black,
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
            color: widget._darkMode ? Colors.white : Colors.black,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.darkMode ? const Color(0xFF212121) : const Color(
          0xFFFAFAFA),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: widget.darkMode
            ? const Color(0xFF303030)
            : const Color(0xFFE0E0E0),
        title: Container(
          margin: const EdgeInsets.only(left: 30),
          child: ListTile(
            leading: Icon(Icons.person,
                color: widget.darkMode ? Colors.white : Colors.black),
            title: Text(
              "Profile",
              style: TextStyle(
                fontFamily: "aldrich",
                fontSize: 25,
                color: widget.darkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: _items.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Card(
              color: widget.darkMode? const Color(0x0029143b):const Color(0x00d9e1ff),
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10, right: 20),
                    child: Builder(
                      builder: (BuildContext context) {
                        return _buildDisplayName(user!.uid, 20, widget.darkMode);
                      },
                    ),
                  ),
                  Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(top: 10, right: 20),
                    child: Builder(
                      builder: (BuildContext context) {
                        return SizedBox(
                          height: 100,
                          width: 100,
                          child: IconButton(
                            onPressed: () {},
                            icon: _buildProfile(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );

          } else if (index == _items.length + 1) {
            return _loading
                ? const Center(child: CircularProgressIndicator())
                : Container();
          } else {
            var item = _items[index - 1];
            String photoUrl = item.child("photoUrl").value.toString();
            String ownerId = item.child("ownerId").value.toString();
            final screenWidth = MediaQuery.of(context).size.width;
            String postId = item.key!;

            return Card(
              elevation: 10,
              key: ValueKey(item.key),
              color: widget.darkMode ? Color(0x4C2D37) : Color(0xFFE0E1E0),
              margin: EdgeInsets.symmetric(vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ListTile(
                          leading:Container(
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
                              return _buildDisplayName(ownerId, 15, widget._darkMode);
                            },
                          ),
                        ),
                      ),
                      if (user!.uid == ownerId)
                        IconButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text("Confirm Deletion"),
                                  content: const Text("Are you sure you want to delete this post?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        FirebaseDatabase.instance.ref().child("Postes").child(postId).remove();

                                        Navigator.of(context).pop();
                                      },
                                      child: const Text("Delete"),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          icon: Icon(
                            Icons.delete_outline,
                            color: widget._darkMode ? Colors.white : Colors.black,
                          ),
                        ),
                    ],
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 10, right: 10),
                    child: Text(
                      item.child("description").value.toString(),
                      style: TextStyle(
                        fontSize: 18,
                        color: widget.darkMode ? Colors.white : Colors.black,
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
                                        color: likes.contains(postId) ? Colors.red : (widget._darkMode ? Colors.white : Colors.black),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    nbLike.toString(),
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: widget._darkMode ? Colors.white : Colors.black,
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
                                backgroundColor: widget._darkMode ? const Color(0xFF212121) : const Color(0xFFFAFAFA),
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
                                                style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold,color: !widget._darkMode ? const Color(0xFF212121) : const Color(0xFFFAFAFA),),
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
                                                            color: !widget._darkMode ? const Color(0xFF212121) : const Color(0xFFFAFAFA),
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
                                                            color: widget._darkMode ? const Color(0x004c2d37) : const Color(0xFFE0E1E0),
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
                                                                  return _buildDisplayName(commentData['ownerId'],10, widget._darkMode);
                                                                },
                                                              ),
                                                              subtitle: Text(
                                                                commentData['comment'] ?? '',
                                                                style: TextStyle(
                                                                  color: widget._darkMode ? Colors.white : Colors.black,
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
                                                    color: widget._darkMode ? Colors.white : Colors.black),
                                                decoration: InputDecoration(
                                                  hintText: 'Add a comment',
                                                  hintStyle: TextStyle(
                                                      color: widget._darkMode ? Colors.white : Colors.black),
                                                  suffixIcon: IconButton(
                                                    icon: Icon(Icons.send,
                                                        color: widget._darkMode ? Colors.white : Colors.black),
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
                                color: widget._darkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          Text(
                            "Comment",
                            style: TextStyle(
                              color: widget._darkMode ? Colors.white : Colors.black,
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
                                        color: reports.contains(postId) ? Colors.red : (widget._darkMode ? Colors.white : Colors.black),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "Report",
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: widget._darkMode ? Colors.white : Colors.black,
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
          }
        },
      ),
    );
  }
}