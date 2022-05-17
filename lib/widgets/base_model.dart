import 'package:flutter/cupertino.dart';

enum ViewState { IDLE, BUSY, CONFIRM }

class BaseModel extends ChangeNotifier {
  ViewState _state = ViewState.IDLE;

  ViewState get state => _state;

  setState(ViewState state) {
    _state = state;
    notifyListeners();
  }
}
