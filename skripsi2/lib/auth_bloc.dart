import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthEvent { login, logout, checkLogin }

class AuthBloc extends Bloc<AuthEvent, bool> {
  late String idAnggota;

  AuthBloc() : super(false) {
    on<AuthEvent>((event, emit) async {
      if (event == AuthEvent.checkLogin) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final bool isLoggedIn = prefs.getBool('isLoggedIn')?? false;
        idAnggota = prefs.getString('idAnggota')?? '';
        emit(isLoggedIn);
      }
      else if (event == AuthEvent.login) {
        emit(true);
      }
      else if (event == AuthEvent.logout) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', false);
        await prefs.remove('idAnggota');
        await prefs.remove('email');
        emit(false);
      }
    });

    add(AuthEvent.checkLogin);
  }
}