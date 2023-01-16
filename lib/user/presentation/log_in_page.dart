
import 'package:email_validator/email_validator.dart';
import 'package:iots_manager/user/bloc/user_bloc.dart';
import 'package:iots_manager/user/presentation/email_verification_page.dart';
import 'package:iots_manager/user/presentation/main_page.dart';
import 'package:iots_manager/user/presentation/register_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class LogInPage extends StatefulWidget {
  const LogInPage({Key? key}) : super(key: key);

  @override
  State<LogInPage> createState() => _LogInPageState();
}

class _LogInPageState extends State<LogInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

@override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("LogIn"),
      ),
      body: BlocListener<UserBloc, UserState>(
        listener: (context, state) {
          if (state is MainPageViewState) {
            // Navigating to the HomePage if the user is authenticated
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainPage(listIoTs: state.listIoTs!)));
          }
          else if(state is EmailVerificationState) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const EmailVerificationPage()));
          }
          else if (state is AuthErrorState) {
            // Showing the error message if the user has entered invalid credentials
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error)));
          }
        },
        child: BlocBuilder<UserBloc, UserState>(
          builder: (context, state) {
            if (state is AuthProcessedState) {
              // Showing the loading indicator while the user is login in
              return const Center( child: CircularProgressIndicator(),);
            }
            if (state is UnAuthenticatedState) {
              // Showing the log in form if the user is not authenticated
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: SingleChildScrollView(
                    reverse: true,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Log In",
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox( height: 18, ),
                        Center(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  keyboardType: TextInputType.emailAddress,
                                  controller: _emailController,
                                  decoration: const InputDecoration(
                                    hintText: "Email",
                                    border: OutlineInputBorder(),
                                  ),
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  validator: (value) {
                                    return value != null && !EmailValidator.validate(value) ? 'Enter a valid email' : null;
                                  },
                                ),
                                const SizedBox( height: 10, ),
                                TextFormField(
                                  keyboardType: TextInputType.text,
                                  controller: _passwordController,
                                  decoration: const InputDecoration(
                                    hintText: "Password",
                                    border: OutlineInputBorder(),
                                  ),
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  validator: (value) {
                                    return value != null && value.length < 6 ? "Enter min. 6 characters" : null;
                                  },
                                ),
                                const SizedBox( height: 12, ),
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.7,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      _authenticateWithEmailAndPassword(context);
                                    },
                                    child: const Text('Log In'),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        const Text("Don't have an account?"),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (routeContext) => const RegisterPage()),);
                          },
                          child: const Text("Register"),
                        )
                      ],
                    ),
                  ),
                ),
              );
            }
            return Container();
          },
        ),
      ),
    );
  }


  void _authenticateWithEmailAndPassword(context) {
    if (_formKey.currentState!.validate()) {
      debugPrint("LogInPage: authentication event");
      // If email is valid adding new Event [LogInEvent].
      BlocProvider.of<UserBloc>(context).add(
        LogInEvent(_emailController.text, _passwordController.text),
      );
    }
  }

}


