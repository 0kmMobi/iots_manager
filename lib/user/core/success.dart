import 'package:equatable/equatable.dart';

abstract class Success extends Equatable {
  final bool success;
  final String msg;

  const Success(this.success, this.msg);

  @override
  List<Object?> get props => [msg];
}

class RepositorySuccess extends Success {
  const RepositorySuccess(super.success, super.msg);
  const RepositorySuccess.ok(msg) : super(true, msg);
  const RepositorySuccess.fail(msg) : super(false, msg);
}

class FirebaseAuthSuccess extends Success {
  const FirebaseAuthSuccess(super.success, super.msg);
  const FirebaseAuthSuccess.ok() : super(true, '');
  const FirebaseAuthSuccess.fail(msg) : super(false, msg);
}

class FirebaseRTDBSuccess extends Success {
  const FirebaseRTDBSuccess(super.success, super.msg);
  const FirebaseRTDBSuccess.ok() : super(true, '');
  const FirebaseRTDBSuccess.fail(msg) : super(false, msg);
}