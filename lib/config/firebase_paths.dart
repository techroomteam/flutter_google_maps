import 'package:cloud_firestore/cloud_firestore.dart';

class FirebasePaths {
  static final db = FirebaseFirestore.instance;

  static final freelancerOnRouteD =
      db.collection('FreelancersOnRoute').doc('user1');
}
