class TokenPair {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final String email;

  const TokenPair({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.email,
  });

  factory TokenPair.fromJson(Map<String, dynamic> json) => TokenPair(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
        userId: json['user_id'] as String,
        email: json['email'] as String,
      );
}
