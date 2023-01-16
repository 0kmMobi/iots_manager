import 'dart:async';
import 'package:iots_manager/user/bloc/user_bloc.dart';
import 'package:iots_manager/user/presentation/log_in_page.dart';
import 'package:iots_manager/locator_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iots_manager/user/presentation/main_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({Key? key}) : super(key: key);

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool canResendEmail = false;
  Timer? timer;
  late User currentUser;

  @override
  void initState() {
    currentUser = sl<FirebaseAuth>().currentUser!;

    super.initState();

    if(!currentUser.emailVerified) {
      sendVerificationEmail();
      timer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => BlocProvider.of<UserBloc>(context).add( EmailVerifyEvent() ) );
    }
  }

  void sendVerificationEmail() async {
    try {
      await currentUser.sendEmailVerification();

      setState(() => canResendEmail = false);
      await Future.delayed(const Duration(seconds: 5));
      // if(mounted) {
      setState(() => canResendEmail = true);
      // }
    } catch(e) {
      debugPrint("Error: ${e.toString()}");
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text(e.toString())) );
        }
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Verify Email')
        ),
        body: BlocListener<UserBloc, UserState>(
          listener: (context, state) {
            if(state is UnAuthenticatedState) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LogInPage()));
            }
            else if(state is MainPageViewState) {
              timer?.cancel();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainPage(listIoTs: state.listIoTs!)));
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Email: ${currentUser.email}", style: const TextStyle(fontSize: 32),),
                const SizedBox(height: 20,),
                ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50)
                    ),
                    icon: const Icon(Icons.email, size: 32),
                    label: Text( canResendEmail?"Resent email":"Hold on...", style: const TextStyle(fontSize: 24),),
                    onPressed: canResendEmail? sendVerificationEmail : null,
                ),
                const SizedBox(height: 20,),
                TextButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50)
                  ),
                  child: const Text("Cancel", style: TextStyle(fontSize: 24)),
                  onPressed: () => BlocProvider.of<UserBloc>(context).add(LogOutEvent(),),
                )
              ],
            ),
          ),
        ),
    );
  }
}
