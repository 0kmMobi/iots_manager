import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String msg;

  const Failure(this.msg);

  @override
  List<Object?> get props => [msg];
}

class RepositoryFailure extends Failure {
  const RepositoryFailure(super.msg);
}

class FirebaseAuthFailure extends Failure {
  const FirebaseAuthFailure(super.msg);
}

class FirebaseRTDBFailure extends Failure {
  const FirebaseRTDBFailure(super.msg);
}