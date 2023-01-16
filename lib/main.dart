import 'package:iots_manager/user/data/repositories/notifications_manager.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iots_manager/user/data/repositories/user_repository.dart';
import 'package:iots_manager/user/bloc/user_bloc.dart';
import 'package:iots_manager/user/presentation/log_in_page.dart';
import 'package:iots_manager/locator_service.dart';

void main() async {
  // debugPrintGestureArenaDiagnostics = true;
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initFirebaseCloudMessaging();
  initServiceLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {

  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => sl<UserRepository>(),
      child: BlocProvider(
        create: (context) => UserBloc( userRepository: RepositoryProvider.of<UserRepository>(context),)..add(StartEvent()),
        child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(primarySwatch: Colors.blueGrey,),
            home: const LogInPage()
        ),
      ),
    );
  }
}





