
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:iots_manager/user/data/api/user_firebase_api.dart';
import 'package:iots_manager/user/data/repositories/notifications_manager.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:iots_manager/user/data/repositories/user_repository.dart';
import 'package:iots_manager/IOTs/temperature_sensors/data/api/temp_sens_firebase_api.dart';
import 'package:iots_manager/IOTs/door_alert/data/api/door_alert_firebase_api.dart';

final sl = GetIt.instance;

void initServiceLocator() {
  sl.registerSingleton<FirebaseAuth>(FirebaseAuth.instance);

  sl.registerSingleton<FirebaseDatabase>(FirebaseDatabase.instance);
  sl.registerSingleton<UserFirebaseApi>(UserFirebaseApi());

  sl.registerSingleton<FirebaseMessaging>(FirebaseMessaging.instance);
  
  sl.registerLazySingleton<UserRepository>(() => UserRepository( sl(), sl() ));

  sl.registerLazySingleton<TempSensFirebaseAPI>(() => TempSensFirebaseAPI() );
  sl.registerLazySingleton<DoorAlertFirebaseAPI>(() => DoorAlertFirebaseAPI() );

  sl.registerLazySingletonAsync<NotificationsManager>(() async => NotificationsManager.create(sl(), sl(), sl()) );
}