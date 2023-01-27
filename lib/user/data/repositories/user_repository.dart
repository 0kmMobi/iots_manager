// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:iots_manager/user/data/api/user_firebase_api.dart';
import 'package:flutter/material.dart';
import 'package:either_dart/either.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iots_manager/user/core/failure.dart';
import 'package:iots_manager/user/core/success.dart';
import 'package:iots_manager/user/data/model/iot_info.dart';

class UserRepository {


  final FirebaseAuth _firebaseAuth;
  final UserFirebaseApi _dbAPI;
  final List<IoTInfo> listIoTs = <IoTInfo>[];

  UserRepository(this._firebaseAuth, this._dbAPI);

  Future<void> sendEmailVerification() async {
    if(_firebaseAuth.currentUser == null) {
      throw Exception("The user is not logged");
    }
    await _firebaseAuth.currentUser!.sendEmailVerification();
  }

  String get userUId {
    if(_firebaseAuth.currentUser == null) {
      throw Exception("The user is not logged");
    }
    return _firebaseAuth.currentUser!.uid;
  }

  bool hasUserId() {
    return _firebaseAuth.currentUser != null;
  }

  String get userEmail {
    if(_firebaseAuth.currentUser == null) {
      throw Exception("The user is not logged");
    }
    if(_firebaseAuth.currentUser!.email == null) {
      throw Exception("The user hasn't email");
    }
    return _firebaseAuth.currentUser!.email!;
  }

  bool hasUserEmail() {
    if(!hasUserId()) {
      return false;
    }
    return _firebaseAuth.currentUser!.email != null;
  }

  Future<User?> authStateFirstChange() async {
    return await _firebaseAuth.authStateChanges().first;
  }

  Future<Either<Failure, Success>> checkEmailVerified() async {
    try {
      await _firebaseAuth.currentUser?.reload();
    } catch(e) {
      return Left(FirebaseAuthFailure(e.toString()));
    }

    try {
      bool isVerified = _firebaseAuth.currentUser!.emailVerified;
      debugPrint("Repository: Email Verify status = $isVerified");
      if(isVerified) {
        return const Right(FirebaseAuthSuccess.ok());
      }
      return const Right(FirebaseAuthSuccess.fail("User email is not verified yet."));
    } catch(e) {
      return Left(FirebaseAuthFailure(e.toString()));
    }
  }


  Future<Either<Failure, Success>> newUserRegister({required String email, required String password}) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return const Left(FirebaseAuthFailure('The password provided is too weak.'));
      } else if (e.code == 'email-already-in-use') {
        return const Left(FirebaseAuthFailure('The account already exists for that email.'));
      }
      return Left(FirebaseAuthFailure(e.toString()));
    } catch (e) {
      return Left(FirebaseAuthFailure(e.toString()));
    }
    return await checkEmailVerified();
  }

  Future<Either<Failure, Success>> userLogIn({ required String email, required String password, }) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return const Left(FirebaseAuthFailure('No user found for that email.'));
      } else if (e.code == 'wrong-password') {
        return const Left(FirebaseAuthFailure('Wrong password provided for that user.'));
      }
      return Left(FirebaseAuthFailure(e.toString()));
    } catch(e) {
      return Left(FirebaseAuthFailure(e.toString()));
    }
    return await checkEmailVerified();
  }

  Future<Either<Failure, Success>> userLogOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      return Left(FirebaseAuthFailure(e.toString()));
    }
    return const Right(FirebaseAuthSuccess.ok());
  }


  /// Query the DB for a list of user devices list and other info about them.
  /// And if user's info is absent in DB, then create it.
  Future<Either<Failure, Success>> queryUserDevicesList() async {
    if(!hasUserId()) {
      return const Left(FirebaseAuthFailure("The user is not logged"));
    }
    listIoTs.clear();

    final mapDevices = await _dbAPI.queryUserDevicesList(userUId);

    /// If user's storage already exists in DB, then get this data
    if(mapDevices != null) {
      await Future.forEach(mapDevices.entries, (MapEntry entry) async {
        final String sIoTId = entry.key;
        final String sIoTName = entry.value;
        late IoTInfo info;
        await queryIoTType(sIoTId).fold(
                (failure) {
              debugPrint("Error: Unknown device ($sIoTId) type. ${failure.msg}");
              info = IoTInfo(sIoTId, 0, sIoTName);
            },
                (type) {
              info = IoTInfo(sIoTId, type, sIoTName);
            });
        listIoTs.add(info);
        debugPrint(" ===> queryUserDevicesList: listIoTs.add( $info )");
      });
    }
    /// If user's storage not exists in DB, then create empty storage
    else {
      if(!hasUserEmail()) {
        return const Left(FirebaseAuthFailure("The user hasn't email"));
      }

      try {
        await _dbAPI.setEmptyUserSection(userUId, userEmail);
      } catch (e) {
        return Left(FirebaseRTDBFailure(e.toString()));
      }
    }
    return Right(FirebaseRTDBSuccess(true, "Devices list has ${listIoTs.length} elements."));
  }

  /// Query the DB for the type of new IoT-device to check if this device is in the DB
  Future<Either<Failure, int>> queryIoTType(String sIoTId) async {
    try{
      int type = await _dbAPI.queryIoTType(sIoTId);
      debugPrint("queryIoTType: type = $type");
      return Right(type);
    } catch(e) {
      return Left(FirebaseRTDBFailure(e.toString()));
    }
  }

  Future<Either<Failure, Success>> addNewIoT(String sNewIoTId, [String? sNewIoTName_]) async {

    if(listIoTs.contains( IoTInfo.dummy(sNewIoTId) )) {
      return const Right(RepositorySuccess.fail("This IoT Id already contains in user's list"));
    }
    
    int? newIoTType;

    await queryIoTType(sNewIoTId)
      .fold(  (left) => left, 
              (right) => newIoTType = right);

    if(newIoTType == null) {
      return const Left(FirebaseRTDBFailure("There isn't such the IoT Id in the DataBase"));
    }

    debugPrint("addNewIoT: newIoTType = $newIoTType");

    final IoTInfo info = IoTInfo(sNewIoTId, newIoTType!, sNewIoTName_);

    if(!hasUserId()) {
      return const Left(FirebaseAuthFailure("The user is not logged"));
    }

    try{
      listIoTs.add( info );
      debugPrint("addNewIoT: listIoTs = ${listIoTs.toString()}");
      await _dbAPI.addNewIoT(userUId, sNewIoTId, info.name);
    } catch(e) {
      debugPrint("addNewIoT: exception: ${e.toString()}");
      return Left(FirebaseRTDBFailure(e.toString()));
    }
    return Right(RepositorySuccess.ok("The IoT successfully added. Type: ${newIoTType!}; Id: $sNewIoTId; Name: ${info.name}"));
  }

  Future<Either<Failure, Success>> renameIoT(String sIoTId, String sIoTNewName) async {
    int iElem = listIoTs.indexOf( IoTInfo.dummy(sIoTId) );

    if(iElem == -1) {
      return const Right(RepositorySuccess.fail("This IoT Id not contains in user's list"));
    }
    IoTInfo info = listIoTs[iElem];
    String oldName = info.name;

    if(!hasUserId()) {
      return const Left(FirebaseAuthFailure("The user is not logged"));
    }

    try {
      await _dbAPI.renameIoT(userUId, info.iotId, sIoTNewName);
      info.name = sIoTNewName;
    } on Exception catch(e) {
      return Left(FirebaseRTDBFailure(e.toString()));
    }
    return Right(RepositorySuccess.ok("The IoT device was successful renamed.\nOld Name: $oldName\nNew name: $sIoTNewName"));
  }

  Future<Either<Failure, Success>> deleteIoTDeviceById(String sIoTId) async {
    int iElem = listIoTs.indexOf( IoTInfo.dummy(sIoTId) );

    if(iElem == -1) {
      return const Left(RepositoryFailure("This IoT Id not contains in user's list"));
    }
    IoTInfo info = listIoTs[iElem];
    debugPrint("Try to remove IoT-device #${info.iotId} by index $iElem");

    if(!hasUserId()) {
      return const Left(FirebaseAuthFailure("The user is not logged"));
    }

    try {
      await _dbAPI.deleteIoTDeviceById(userUId, info.iotId);
      listIoTs.removeAt(iElem);

    } on Exception catch(e) {
      return Left(FirebaseRTDBFailure(e.toString()));
    }
    return const Right(RepositorySuccess.ok("The IoT-device successfully deleted from the user's list."));
  }
}

