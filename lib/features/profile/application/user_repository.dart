import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orya/features/profile/domain/user.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<UserModel> userStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.error('User not logged in');
    }
    return _firestore.collection('users').doc(user.uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return UserModel.fromFirestore(snapshot, null);
      } else {
        return UserModel(uid: user.uid, email: user.email ?? '', displayName: user.displayName ?? 'No Name');
      }
    });
  }

  Future<void> updateUser(UserModel user) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not logged in');
    }
    await _firestore.collection('users').doc(currentUser.uid).set(user.toFirestore());
  }
}

final userRepoProvider = Provider((ref) => UserRepository());

final userProvider = StreamProvider<UserModel>((ref) {
  return ref.watch(userRepoProvider).userStream();
});
