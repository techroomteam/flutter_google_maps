import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

void startBackGround(ServiceInstance service,
    {required VoidCallback listenDeviceLocation}) {
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }
  service.on('stopService').listen((event) {
    service.stopSelf();
  });
  // bring to foreground
  Timer.periodic(
    const Duration(seconds: 5),
    (timer) async {
      if (service is AndroidServiceInstance) {
        await service.setForegroundNotificationInfo(
            title: 'CASA', content: 'Running Background Service.');
      }

      listenDeviceLocation();
    },
  );
}
