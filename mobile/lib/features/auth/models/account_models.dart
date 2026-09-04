class AccountInfo {
  final String username;
  final String email;

  const AccountInfo({
    required this.username,
    required this.email,
  });

  factory AccountInfo.fromJson(Map<String, dynamic> json) => AccountInfo(
        username: json['username'] as String? ?? '',
        email: json['email'] as String? ?? '',
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
