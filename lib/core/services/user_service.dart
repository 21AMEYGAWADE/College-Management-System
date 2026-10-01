import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createUserProfile({
    required String uid,
    required String name,
    required String email,
    required String role,
    String? studentId,
    String? employeeId,
  }) async {
    final userData = <String, dynamic>{
      'name': name,
      'email': email,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (studentId != null && studentId.isNotEmpty) {
      userData['studentId'] = studentId;
    }

    if (employeeId != null && employeeId.isNotEmpty) {
      userData['employeeId'] = employeeId;
    }

    await _firestore.collection('users').doc(uid).set(userData);
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final document =
    await _firestore.collection('users').doc(uid).get();

    if (!document.exists) {
      return null;
    }

    return document.data();
  }

  Future<String?> getUserRole(String uid) async {
    final userProfile = await getUserProfile(uid);

    if (userProfile == null) {
      return null;
    }

    return userProfile['role'] as String?;
  }
}