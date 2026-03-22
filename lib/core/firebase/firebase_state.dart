bool firebaseAvailable = false;

String? firebaseUnavailableReason;

String get firebaseUnavailableMessage =>
    firebaseUnavailableReason ?? 'Firebase is unavailable.';
