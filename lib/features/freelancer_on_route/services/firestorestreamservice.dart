import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelancer_tracking/features/freelancer_on_route/model/freelancer_route.dart';

import '../../../config/firebase_paths.dart';

abstract class FireStreamService {
  Stream<FreelancerOnRoute> freelancerOnRouteStream();
}

class FireStoreStreamService extends FireStreamService {
  @override
  Stream<FreelancerOnRoute> freelancerOnRouteStream() {
    return FirebasePaths.freelancerOnRouteD
        .snapshots()
        .map((snapshot) => FreelancerOnRoute.fromSnapshot(snapshot));
  }
}
