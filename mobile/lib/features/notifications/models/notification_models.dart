/// Request body for `POST /notifications/register-token`.
class RegisterTokenRequest {
  final String token;
  final String platform;

  const RegisterTokenRequest({
    required this.token,
    required this.platform,
  });

  Map<String, dynamic> toJson() => {
        'token': token,
        'platform': platform,
      };
}

/// Request body for `POST /notifications/unregister-token`.
class UnregisterTokenRequest {
  final String token;

  const UnregisterTokenRequest({required this.token});

  Map<String, dynamic> toJson() => {
        'token': token,
      };
}
