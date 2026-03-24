import 'dart:convert';
import 'dart:io';
import 'package:firedart/firedart.dart';

class FileTokenStore extends TokenStore {
  File get _file {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';
    return File('$home/.codepath_auth_token.json');
  }

  @override
  Token? read() {
    if (!_file.existsSync()) return null;
    try {
      final jsonStr = _file.readAsStringSync();
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      return Token.fromMap(map);
    } catch (e) {
      return null;
    }
  }

  @override
  void write(Token? token) {
    if (token == null) {
      delete();
      return;
    }
    try {
      final map = token.toMap();
      _file.writeAsStringSync(json.encode(map));
    } catch (e) {
      // Ignored
    }
  }

  @override
  void delete() {
    if (_file.existsSync()) {
      _file.deleteSync();
    }
  }
}
