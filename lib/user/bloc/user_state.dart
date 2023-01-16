// ignore_for_file: camel_case_types

part of 'user_bloc.dart';

abstract class UserState extends Equatable {
  @override
  List<Object?> get props => [];
}

/// When the new registering or the exist user logging is processed.
class AuthProcessedState extends UserState { }

/// When the new user created or logged but email is not verified.
class EmailVerificationState extends UserState { }

/// When the user is fully authenticated it go to the MainPage or after back from AddNewIoTPage to MainPage.
class MainPageViewState extends UserState {
  late final List<IoTInfo>? listIoTs;

  MainPageViewState(List<IoTInfo>? listIoTs_) {
    listIoTs = listIoTs_ != null ? <IoTInfo>[...listIoTs_] : null;
  }

  @override
  List<Object?> get props => [listIoTs];
}


/// Go to the Login page after logOut, etc.
class UnAuthenticatedState extends UserState { }

/// When any error occurs during auth processing then the state is changed to AuthError.
class AuthErrorState extends UserState {
  final String error;

  AuthErrorState(this.error);
  @override
  List<Object?> get props => [error];
}

/// When the user tap on '+' button then it goes to the MainPage
class NewIoT_InitPage_State extends UserState {}

/// While wait for the correct Id of the IoT-device will be entered or the QR-code scanned.
class NewIoT_WaitId_State extends UserState {}

/// When there is the correct Id of IoT-device to try to registering it.
class NewIoT_TryToAdd_State extends UserState {
  final String newIoTId;

  NewIoT_TryToAdd_State(this.newIoTId);

  @override
  List<Object?> get props => [newIoTId];
}

/// When the new IoT-device Id was not added to the user's devices list since have some error
///   or this device has already been added in the list before.
class NewIoT_IdNotAdded_State extends UserState {
  final bool hasError;
  final String msg;

  NewIoT_IdNotAdded_State({required this.hasError, required this.msg});
  @override
  List<Object?> get props => [hasError, msg];
}

/// When the new IoT-device Id was successfully added in the user's devices list
class NewIoT_IdSuccessfulAdded_State extends UserState {
  final String msg;

  NewIoT_IdSuccessfulAdded_State(this.msg);
  @override
  List<Object?> get props => [msg];
}
