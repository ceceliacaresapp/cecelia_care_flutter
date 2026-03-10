import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'services/drug_interaction_service.dart';
import 'services/rxnav_service.dart';

// Create a global instance of the service locator.
final locator = GetIt.instance;

/// Registers dependencies for the application.
///
/// This function should be called once, typically in `main.dart`
/// before the application starts, to set up the services
/// that the app will use.
void setupLocator() {
  // Registering dependencies as "lazy singletons".
  // This means they are only created the first time they are requested,
  // and then the same instance is returned for all subsequent requests.

  // 1. Register the HTTP client dependency.
  // Both services need an http.Client, so we register it here once.
  locator.registerLazySingleton(() => http.Client());

  // 2. Register the RxNavService.
  // The locator will automatically find the registered http.Client
  // and pass it to the RxNavService constructor.
  locator.registerLazySingleton(
    () => RxNavService(client: locator<http.Client>()),
  );

  // 3. Register the DrugInteractionService.
  // This service also gets the same http.Client instance.
  locator.registerLazySingleton(
    () => DrugInteractionService(client: locator<http.Client>()),
  );
}