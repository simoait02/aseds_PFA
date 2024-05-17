import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(
    debugShowCheckedModeBanner: true,
    home:Profile(false)
));
class Profile extends StatefulWidget {
  final bool _darkMode;
  const Profile(this._darkMode, {super.key});

  @override
  ProfileState createState() => ProfileState();
}

class ProfileState extends State<Profile> {
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
              title:Text("Profile",
                style: TextStyle(
                  fontFamily: "aldrich",
                  fontSize: 25,
                  color: widget._darkMode? Colors.white:Colors.black,
                ),)
          ),
        ),
      ),
    );
  }
}
