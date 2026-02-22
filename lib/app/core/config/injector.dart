import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:portugal_guide/app/core/auth/auth_token_manager.dart';
import 'package:portugal_guide/app/core/auth/auth_error_handler.dart';
import 'package:portugal_guide/features/auth_credentials/auth_credentials_login_view_model.dart';
import 'package:portugal_guide/features/auth_credentials/auth_credentials_service.dart';
import 'package:portugal_guide/features/auth_google/auth_google_service.dart';
import 'package:portugal_guide/features/auth_google/auth_google_view_model.dart';
import 'package:portugal_guide/features/main_contents/topic/main_content_topic_repository.dart';
import 'package:portugal_guide/features/main_contents/topic/main_content_topic_repository_interface.dart';
import 'package:portugal_guide/features/main_contents/topic/main_content_topic_view_model.dart';
import 'package:portugal_guide/features/user/user_repository.dart';
import 'package:portugal_guide/features/user/user_repository_interface.dart';
import 'package:portugal_guide/features/user/user_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

final injector =
    GetIt
        .instance; //##### dependency_injector ###### get_it dependency add to the pubspekage!!

Future<void> setupDependencies() async {
  // Registrar SharedPreferences (deve ser inicializado de forma assíncrona)
  final sharedPreferences = await SharedPreferences.getInstance();
  injector.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  // Registrar HTTP Client
  injector.registerLazySingleton<http.Client>(() => http.Client());

  //### For Authentication ###
  injector.registerLazySingleton<AuthTokenManager>(
    () => AuthTokenManager(injector<SharedPreferences>()),
  );
  
  // Registrar AuthErrorHandler (depende de AuthTokenManager)
  injector.registerLazySingleton<AuthErrorHandler>(
    () => AuthErrorHandler(injector<AuthTokenManager>()),
  );
  
  injector.registerLazySingleton<AuthCredentialsService>(
    () => AuthCredentialsService(injector<http.Client>()),
  );
  injector.registerFactory<AuthCredentialsLoginViewModel>(
    () => AuthCredentialsLoginViewModel(
      service: injector<AuthCredentialsService>(),
      tokenManager: injector<AuthTokenManager>(),
    ),
  );

  //### For Google OAuth Authentication ###
  injector.registerLazySingleton<AuthGoogleService>(
    () => AuthGoogleService.defaultInstance(),
  );
  injector.registerFactory<AuthGoogleViewModel>(
    () => AuthGoogleViewModel(
      service: injector<AuthGoogleService>(),
      tokenManager: injector<AuthTokenManager>(),
    ),
  );

  //### For User ###
  injector.registerLazySingleton<UserRepositoryInterface>(
    () => UserRepository(),
  );
  injector.registerFactory<UserViewModel>(
    () => UserViewModel(repository: injector<UserRepositoryInterface>()),
  );

  //### For Main Content Topic ###
  injector.registerLazySingleton<MainContentTopicRepositoryInterface>(
    () => MainContentTopicRepository(),
  );
  injector.registerFactory<MainContentTopicViewModel>(
    () => MainContentTopicViewModel(
      repository: injector<MainContentTopicRepositoryInterface>(),
    ),
  );
}

// -----------------------------------------------------------------------------
// ### DOCUMENTATION ###
// -----------------------------------------------------------------------------
//
// ## OVERVIEW
//
// This file serves as the central configuration point for Dependency Injection (DI)
// throughout the application, using the 'get_it' package as a Service Locator.
// The primary goal is to decouple classes from their concrete dependencies,
// promoting a more modular, testable, and maintainable architecture.
//
// ## KEY COMPONENTS
//
// - `injector`: This is a global, singleton instance of `GetIt`. It acts
//   as a registry where we can "register" how to create certain classes and then
//   "request" instances of those classes from anywhere in the app.
//
// - `injectAppGlobalDependenciesForDI()`: This function is the main setup routine. It should be
//   called once at application startup (e.g., in `main.dart`) to register all
//   the necessary dependencies before they are needed.
//
// ## REGISTRATION DETAILS
//
// 1. `registerLazySingleton<UserRepositoryInterface>(() => UserRepository());`
//    - This line registers the repository dependency.
//    - `registerLazySingleton`: It tells the service locator that there should only
//      be ONE instance of the repository throughout the app's lifecycle. It's "lazy"
//      because the `UserRepository` instance is only created the very first time
//      it's requested, not at startup.
//    - `<UserRepositoryInterface>`: We are registering the ABSTRACT INTERFACE as the "key".
//      This is the core of the Dependency Inversion Principle. Other classes will
//      request an `UserRepositoryInterface` without knowing the concrete implementation.
//    - `() => UserRepository()`: This is the factory function that tells the locator
//      HOW to create the object. It provides the CONCRETE CLASS `UserRepository`.
//
// 2. `registerFactory<UserViewModel>(() => UserViewModel(...));`
//    - This line registers the ViewModel dependency.
//    - `registerFactory`: This tells the service locator to create a NEW INSTANCE
//      of `UserViewModel` every single time it is requested. This is ideal for
//      ViewModels that are tied to the lifecycle of a specific screen.
//    - `repository: injector<UserRepositoryInterface>()`: This is where the
//      magic of DI happens. When creating the `UserViewModel`, its `repository`
//      parameter is fulfilled by asking the service locator for an instance of
//      `UserRepositoryInterface`. The locator looks up its registry and provides the
//      singleton instance of `UserRepository` that we registered above.
