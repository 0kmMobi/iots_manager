// ignore_for_file: camel_case_types

part of 'user_bloc.dart';

abstract class UserEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class StartEvent extends UserEvent {}

// When the user logging in with email and password this event is called and the [AuthRepository] is called to log in the user
class LogInEvent extends UserEvent {
  final String email;
  final String password;

  LogInEvent(this.email, this.password);
  @override
  List<Object> get props => [email, password];
}

// When the new user registering with email and password this event is called and the [AuthRepository] is called to register the user
class RegisterEvent extends UserEvent {
  final String email;
  final String password;

  RegisterEvent(this.email, this.password);
  @override
  List<Object> get props => [email, password];
}

class EmailVerifyEvent extends UserEvent {}

// When the user logging out this event is called and the [AuthRepository] is called to log out the user
class LogOutEvent extends UserEvent {}

class DeleteIoTDeviceEvent extends UserEvent {
  final String sIoTId;

  DeleteIoTDeviceEvent(this.sIoTId);
  @override
  List<Object> get props => [sIoTId];
}

class NewIoT_InitPage_Event extends UserEvent {}


/// Waiting for specific Id during user enter or recognize QR-code
/// This happens when user click on the '+' button (to add the new IoT-device) in the MainPage or right here when it fails when trying to add a new device
class NewIoT_WaitingId_Event extends UserEvent {}

class NewIoT_Id_Entered_Event extends UserEvent {
  final String newIoTId;

  NewIoT_Id_Entered_Event(this.newIoTId);
  @override
  List<Object> get props => [newIoTId];
}

/// When tap to the Back-button on the 'Adding new IoT-device' page
/// or when adding a new IoT was successful completed
class NewIoT_BackHomeEvent extends UserEvent {
  final bool newIoTAdded;

  NewIoT_BackHomeEvent(this.newIoTAdded);
  @override
  List<Object> get props => [newIoTAdded];
}
