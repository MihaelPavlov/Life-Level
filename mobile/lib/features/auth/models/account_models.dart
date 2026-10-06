class AccountInfo {
  final String username;
  final String email;
  final bool hasPassword;
  final bool googleConnected;

  const AccountInfo({
    required this.username,
    required this.email,
    required this.hasPassword,
    required this.googleConnected,
  });

  factory AccountInfo.fromJson(Map<String, dynamic> json) => AccountInfo(
        username: json['username'] as String? ?? '',
        email: json['email'] as String? ?? '',
        hasPassword: json['hasPassword'] as bool? ?? true,
        googleConnected: json['googleConnected'] as bool? ?? false,
      );
}

class UpdateEmailResult {
  final String token;
  final String username;
  final String email;

  const UpdateEmailResult({
    required this.token,
    required this.username,
    required this.email,
  });

  factory UpdateEmailResult.fromJson(Map<String, dynamic> json) =>
      UpdateEmailResult(
        token: json['token'] as String,
        username: json['username'] as String? ?? '',
        email: json['email'] as String? ?? '',
      );
}
