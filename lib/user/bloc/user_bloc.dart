import 'package:either_dart/either.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iots_manager/user/data/model/iot_info.dart';
import 'package:iots_manager/user/data/repositories/user_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'user_event.dart';
part 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRepository userRepository;

  UserBloc({required this.userRepository}) : super(UnAuthenticatedState()) {

    /// When the app starts, it checks the user's authorization status and selects the next state.
    on<StartEvent>((event, emit) async {
      emit(AuthProcessedState());
      User? user = await userRepository.authStateFirstChange();
      if(user == null) {
        emit(UnAuthenticatedState());
      } else {
        emit( await _getMainPageOrEmailVerifyState(user.emailVerified) );
      }
    });

    /// When User Presses the LogIn Button, we will send the LogInEvent Event to the UserBloc to handle it and emit the Authenticated State if the user is authenticated
    on<LogInEvent>((event, emit) async {
      emit(AuthProcessedState());

      await userRepository.userLogIn(email: event.email, password: event.password).fold(
        (failure) {
            emit(AuthErrorState(failure.msg));
            emit(UnAuthenticatedState());
        },
        (success) async {
          emit( await _getMainPageOrEmailVerifyState(success.success) );
        }
      );
    });

    /// When User Presses the Register Button, we will send the RegisterRequest Event to the UserBloc to handle it and emit the Authenticated State if the user is authenticated
    on<RegisterEvent>((event, emit) async {
      emit(AuthProcessedState());

      await userRepository.newUserRegister(email: event.email, password: event.password).fold(
        (failure) {
          emit(AuthErrorState(failure.msg));
          emit(UnAuthenticatedState());
        },
        (success) async {
          emit( await _getMainPageOrEmailVerifyState(success.success) );
        });
    });

    /// While the application is on the EmailVerificationPage, it periodically checks the user's email verification status and then selects the next state of the app.
    on<EmailVerifyEvent>((event, emit) async {
      emit(AuthProcessedState());

      await userRepository.checkEmailVerified().fold(
        (failure) {
          emit( EmailVerificationState() );
        },
        (success) async {
          emit( await _getMainPageOrEmailVerifyState(success.success) );
        });
    });


    /// When User Presses the LogOut Button, we will send the LogOutRequested Event to the UserBloc to handle it and emit the UnAuthenticated State
    on<LogOutEvent>((event, emit) async {
      emit(AuthProcessedState());
      await userRepository.userLogOut().fold(
        (error)  => emit(UnAuthenticatedState()),
        (result) => emit(UnAuthenticatedState()));
    });

    on<DeleteIoTDeviceEvent>((event, emit) async {
      await userRepository.deleteIoTDeviceById(event.sIoTId).fold(
        (left) {
          emit(MainPageViewState(null));
        },
        (right) {
          emit(MainPageViewState(userRepository.listIoTs));
        });
    });

    /// ///////////////////////////////
    on<NewIoT_InitPage_Event>((event, emit) => emit(NewIoT_InitPage_State()) );

    /// ///////////////////////////////
    on<NewIoT_WaitingId_Event>((event, emit) => emit(NewIoT_WaitId_State()) );

    /// ///////////////////////////////
    on<NewIoT_Id_Entered_Event>((event, emit) async {
      final String sIoTId = event.newIoTId;
      emit(NewIoT_TryToAdd_State(sIoTId));

      await userRepository.addNewIoT(sIoTId).fold(
        (failure) => emit(NewIoT_IdNotAdded_State(hasError: true, msg: failure.msg)),
        (success) {
          if(success.success) {
            emit(NewIoT_IdSuccessfulAdded_State(success.msg));
          } else {
            emit(NewIoT_IdNotAdded_State(hasError: false, msg: success.msg));
          }
        }
      );
    });

    /// When the new IoT-device was successfully added or user pressed Back-key in the AnnNewIoT_Page
    on<NewIoT_BackHomeEvent>((event, emit) {
      emit(MainPageViewState( event.newIoTAdded? userRepository.listIoTs: null));
    });
  }

  Future<UserState> _getMainPageOrEmailVerifyState(bool isVerified) async {
    if(isVerified) {
      await userRepository.queryUserDevicesList().fold(
              (failure) => debugPrint("Query user's devices list failed: ${failure.msg}"),
              (success) => debugPrint("User's devices list successfully completed"));
      return MainPageViewState(userRepository.listIoTs);
    } else {
      return EmailVerificationState();
    }
  }

  @override
  void onTransition(Transition<UserEvent, UserState> transition) {
    super.onTransition(transition);
    //debugPrint("--- Bloc.onTransition: $transition");
  }
}