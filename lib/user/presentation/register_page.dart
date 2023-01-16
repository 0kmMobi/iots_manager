
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:email_validator/email_validator.dart';
import 'package:iots_manager/user/bloc/user_bloc.dart';
import 'package:iots_manager/user/presentation/log_in_page.dart';
import 'package:iots_manager/user/presentation/email_verification_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
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
        title: const Text("Register new user"),
      ),
      body: BlocConsumer<UserBloc, UserState>(
        listener: (context, state) {
          if (state is MainPageViewState) {
            // Navigating to the dashboard screen if the user is authenticated
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const EmailVerificationPage()));
          }
          else if(state is EmailVerificationState) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const EmailVerificationPage()));
          }
          if (state is AuthErrorState) {
            // Displaying the error message if the user is not authenticated
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error)));
          }
        },
        builder: (context, state) {
          if (state is AuthProcessedState) {
            // Displaying the loading indicator while the user is registering up
            return const Center(child: CircularProgressIndicator());
          }
          if (state is UnAuthenticatedState) {
            // Displaying the Register form if the user is not authenticated
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: SingleChildScrollView(
                  reverse: true,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Register form",
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 18,),
                      Center(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  hintText: "Email",
                                  border: OutlineInputBorder(),
                                ),
                                autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                                validator: (value) {
                                  return value != null &&
                                      !EmailValidator.validate(value)
                                      ? 'Enter a valid email'
                                      : null;
                                },
                              ),
                              const SizedBox(height: 10,),
                              TextFormField(
                                controller: _passwordController,
                                decoration: const InputDecoration(
                                  hintText: "Password",
                                  border: OutlineInputBorder(),
                                ),
                                autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                                validator: (value) {
                                  return value != null && value.length < 6
                                      ? "Enter min. 6 characters"
                                      : null;
                                },
                              ),
                              const SizedBox(height: 12,),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.7,
                                child: ElevatedButton(
                                  onPressed: () {
                                    _createAccountWithEmailAndPassword(context);
                                  },
                                  child: const Text('Register Now'),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      const Text("Already have an account?"),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const LogInPage()),
                          );
                        },
                        child: const Text("LogIn"),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return Container();
        },
      ),
    );
  }

  void _createAccountWithEmailAndPassword(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      BlocProvider.of<UserBloc>(context).add(
        RegisterEvent( _emailController.text, _passwordController.text, ),
      );
    }
  }
}
