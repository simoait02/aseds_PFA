import 'package:firebase_database/firebase_database.dart';

class PostMonitorService {
  final DatabaseReference _postRef = FirebaseDatabase.instance.ref().child('Postes');

  PostMonitorService() {
    _postRef.onChildChanged.listen(_onPostChanged);
  }

  void _onPostChanged(DatabaseEvent event) {
    final data = event.snapshot.value as Map<dynamic, dynamic>;
    final nbReports = data["nbReports"] as int;

    if (nbReports >= 5) {
      final postId = event.snapshot.key;
      _deletePost(postId);
    }
  }

  Future<void> _deletePost(String? postId) async {
    if (postId != null) {
      await _postRef.child(postId).remove().then((_) {
      }).catchError((error) {
        print('******************************** $error');
      });
    }
  }
}


