import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skripsi2/auth_bloc.dart';
import 'package:skripsi2/home.dart';
import 'package:skripsi2/login.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(),
          ),
        ],
        child: AppNavigator(),
      ),
    );
  }
}

class AppNavigator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AuthBloc authBloc = BlocProvider.of<AuthBloc>(context);
    return BlocBuilder<AuthBloc, bool>(
      builder: (context, isLoggedIn) {
        return Navigator(
          pages: [
            if (isLoggedIn)
              MaterialPage(
                child: homeScreen(id: authBloc.idAnggota.toString()),
              )
            else
              const MaterialPage(
                child: login(),
              ),
          ],
          onPopPage: (route, result) {
            authBloc.add(AuthEvent.logout);
            return route.didPop(result);
          },
        );
      },
    );
  }
}
