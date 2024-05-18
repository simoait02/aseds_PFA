import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Profile(false),
    );
  }
}

class Profile extends StatefulWidget {
  final bool darkMode;
  const Profile(this.darkMode, {super.key});

  @override
  ProfileState createState() => ProfileState();
}

class ProfileState extends State<Profile> {
  final DatabaseReference db = FirebaseDatabase.instance.ref("users");
  final DatabaseReference dbp = FirebaseDatabase.instance.ref("Postes");
  final user = FirebaseAuth.instance.currentUser;
  DataSnapshot? snapshot;
  bool isComplete = false;
  final ScrollController _scrollController = ScrollController();
  bool _loading = false;
  DataSnapshot? _lastFetchedItem;
  List<DataSnapshot> _items = [];

  @override
  void initState() {
    super.initState();
    fetchData();
    _scrollController.addListener(_scrollListener);
  }

  Future<void> fetchData() async {
    try {
      final event = await db.child(user!.uid).once();
      setState(() {
        snapshot = event.snapshot;
        isComplete = true;
      });
      _loadMoreItems();
    } catch (e) {
      // Handle error
      setState(() {
        isComplete = false;
      });
    }
  }

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

    Query query = dbp.orderByKey().limitToFirst(10);
    if (_lastFetchedItem != null) {
      query = query.startAfter(_lastFetchedItem!.key);
    }

    DataSnapshot snapshot = await query.get();
    List<DataSnapshot> fetchedItems = snapshot.children.toList();

    setState(() {
      _items.addAll(fetchedItems);
      if (fetchedItems.isNotEmpty) {
        _lastFetchedItem = fetchedItems.last;
      }
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.darkMode ? const Color(0xFF212121) : const Color(0xFFFAFAFA),
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: widget.darkMode ? const Color(0xFF303030) : const Color(0xFFE0E0E0),
        title: Container(
          margin: const EdgeInsets.only(left: 30),
          child: ListTile(
            leading: Icon(
              Icons.settings,
              color: widget.darkMode ? Colors.white : Colors.black,
            ),
            title: Text(
              "Profile",
              style: TextStyle(
                fontFamily: "Aldrich",
                fontSize: 25,
                color: widget.darkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 40, right: 20),
                      child: Text(
                        isComplete ? snapshot?.child("displayName").value.toString() ?? "username" : "username",
                        style: TextStyle(
                          fontSize: 20,
                          fontFamily: "OpenSans",
                          color: widget.darkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    Container(
                      alignment: Alignment.center,
                      margin: const EdgeInsets.only(top: 40, right: 20),
                      child: isComplete
                          ? CircleAvatar(
                        backgroundImage: snapshot?.child("photoUrl").value != null
                            ? NetworkImage(snapshot!.child("photoUrl").value.toString())
                            : const AssetImage("assets/profile.png") as ImageProvider<Object>,
                        radius: 40,
                      )
                          : const CircleAvatar(
                        backgroundImage: AssetImage("assets/g0R5.gif"),
                        radius: 40,
                      ),
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: widget.darkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                if (index == _items.length) {
                  return _loading ? const Center(child: CircularProgressIndicator()) : Container();
                }
                DataSnapshot item = _items[index];
                String photoUrl = item.child("photoUrl").value.toString();
                String profilePic = item.child("profilePic").value.toString();
                String ownerName = item.child("displayName").value.toString();
                final screenWidth = MediaQuery.of(context).size.width;
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(left: 20),
                            child: CircleAvatar(
                              backgroundImage: isComplete ? NetworkImage(profilePic) : const AssetImage("assets/profile.png") as ImageProvider<Object>,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 0, left: 10, right: 10),
                            child: Text(
                              ownerName,
                              style: TextStyle(
                                color: widget.darkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 10, top: 5, bottom: 5, right: 10),
                        child: Text(
                          item.child("description").value.toString(),
                          style: TextStyle(
                            fontSize: 18,
                            color: widget.darkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 20),
                        width: screenWidth,
                        color: Colors.amber,
                        child: Image.network(photoUrl, fit: BoxFit.cover),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Row(
                            children: [
                              Container(
                                height: 60,
                                width: 60,
                                child: Icon(
                                  Icons.favorite_border,
                                  size: 32,
                                  color: widget.darkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              Text(
                                "Like",
                                style: TextStyle(
                                  color: widget.darkMode ? Colors.white : Colors.black,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                height: 60,
                                width: 60,
                                child: Icon(
                                  Icons.mode_comment_outlined,
                                  size: 32,
                                  color: widget.darkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              Text(
                                "Comment",
                                style: TextStyle(
                                  color: widget.darkMode ? Colors.white : Colors.black,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                height: 60,
                                width: 60,
                                child: Icon(
                                  Icons.share_outlined,
                                  size: 35,
                                  color: widget.darkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              Text(
                                "Share",
                                style: TextStyle(
                                  color: widget.darkMode ? Colors.white : Colors.black,
                                  fontSize: 20,
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(right: 15),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
              childCount: _items.length + (_loading ? 1 : 0),
            ),
          ),
        ],
      ),
    );
  }
}
