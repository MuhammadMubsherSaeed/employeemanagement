/// Secure token storage contract for the upcoming auth feature.
/// Existing code still uses SharedPreferences in [Utils].
abstract class TokenStorage {
  Future<void> saveAccessToken(String token);
  Future<String?> readAccessToken();
  Future<void> clear();
}
