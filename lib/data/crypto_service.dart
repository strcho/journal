import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CryptoService {
  CryptoService(this._secretKey, this._algorithm);

  static const _storage = FlutterSecureStorage();
  static const _keyName = 'journal_encryption_key';
  static const _nonceLength = 12;
  static const _macLength = 16;

  final SecretKey _secretKey;
  final Cipher _algorithm;

  static Future<CryptoService> create() async {
    final keyBytes = await _getOrCreateKeyBytes();
    return CryptoService(SecretKey(keyBytes), AesGcm.with256bits());
  }

  static Future<Uint8List> _getOrCreateKeyBytes() async {
    final existing = await _storage.read(key: _keyName);
    if (existing != null && existing.isNotEmpty) {
      return base64Decode(existing);
    }

    final random = Random.secure();
    final key = Uint8List.fromList(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
    await _storage.write(key: _keyName, value: base64Encode(key));
    return key;
  }

  Future<String> encryptString(String plaintext) async {
    if (plaintext.isEmpty) {
      return '';
    }
    final secretBox = await _algorithm.encrypt(
      utf8.encode(plaintext),
      secretKey: _secretKey,
    );
    return base64Encode(_combineSecretBox(secretBox));
  }

  Future<String> decryptString(String encrypted) async {
    if (encrypted.isEmpty) {
      return '';
    }
    final secretBox = _splitSecretBox(base64Decode(encrypted));
    final clearBytes = await _algorithm.decrypt(
      secretBox,
      secretKey: _secretKey,
    );
    return utf8.decode(clearBytes);
  }

  Future<Uint8List> encryptBytes(Uint8List bytes) async {
    if (bytes.isEmpty) {
      return Uint8List(0);
    }
    final secretBox = await _algorithm.encrypt(bytes, secretKey: _secretKey);
    return _combineSecretBox(secretBox);
  }

  Future<Uint8List> decryptBytes(Uint8List encrypted) async {
    if (encrypted.isEmpty) {
      return Uint8List(0);
    }
    final secretBox = _splitSecretBox(encrypted);
    final clearBytes = await _algorithm.decrypt(
      secretBox,
      secretKey: _secretKey,
    );
    return Uint8List.fromList(clearBytes);
  }

  Future<String> sha256Hex(Uint8List bytes) async {
    if (bytes.isEmpty) {
      return '';
    }
    final hash = await Sha256().hash(bytes);
    return _bytesToHex(hash.bytes);
  }

  String _bytesToHex(List<int> bytes) {
    final buffer = StringBuffer();
    for (final byte in bytes) {
      buffer.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  Uint8List _combineSecretBox(SecretBox secretBox) {
    final bytes = Uint8List(
      _nonceLength + _macLength + secretBox.cipherText.length,
    );
    bytes.setRange(0, _nonceLength, secretBox.nonce);
    bytes.setRange(
      _nonceLength,
      _nonceLength + _macLength,
      secretBox.mac.bytes,
    );
    bytes.setRange(
      _nonceLength + _macLength,
      bytes.length,
      secretBox.cipherText,
    );
    return bytes;
  }

  SecretBox _splitSecretBox(Uint8List bytes) {
    final nonce = bytes.sublist(0, _nonceLength);
    final mac = Mac(bytes.sublist(_nonceLength, _nonceLength + _macLength));
    final cipherText = bytes.sublist(_nonceLength + _macLength);
    return SecretBox(cipherText, nonce: nonce, mac: mac);
  }
}
