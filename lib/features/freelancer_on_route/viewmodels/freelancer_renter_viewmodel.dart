import 'package:flutter/material.dart';

class FreelancerRenterViewModel extends ChangeNotifier {
  String statusRenter = 'renter App';
  String statusFreelancer = 'freelancer App';
  var time = 0;
  var Speed = 0.0;
  // ignore: always_declare_return_types
  updateStatusRenter(String value) {
    statusRenter = value;
    notifyListeners();
  }

  updateStatusFreelancer(String value) {
    statusFreelancer = value;
    notifyListeners();
  }

  updateTimeDistance(int value) {
    time = value;
    notifyListeners();
  }

  updateSpeed(double value) {
    Speed = value;
    notifyListeners();
  }
}
