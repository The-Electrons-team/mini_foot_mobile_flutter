import 'package:firebase_core/firebase_core.dart';

FirebaseOptions? buildWebFirebaseOptions({
  required String? apiKey,
  required String? authDomain,
  required String? projectId,
  required String? storageBucket,
  required String? messagingSenderId,
  required String? appId,
  String? measurementId,
}) {
  final requiredValues = [
    apiKey,
    authDomain,
    projectId,
    storageBucket,
    messagingSenderId,
    appId,
  ];

  final hasMissingRequiredValue = requiredValues.any(
    (value) => value == null || value.trim().isEmpty,
  );

  if (hasMissingRequiredValue) {
    return null;
  }

  return FirebaseOptions(
    apiKey: apiKey!,
    authDomain: authDomain!,
    projectId: projectId!,
    storageBucket: storageBucket!,
    messagingSenderId: messagingSenderId!,
    appId: appId!,
    measurementId: measurementId,
  );
}
