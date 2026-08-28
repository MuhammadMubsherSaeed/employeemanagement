import 'dart:convert';
import 'package:asn1lib/asn1lib.dart';
import 'package:crypto/crypto.dart' as Crypto;
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pointycastle/export.dart';
import 'constants.dart';

class RSAUtil {
  Future<String> getEncryptedHashKeyInHexFormat() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      List<int> packageNameBytes = utf8.encode(packageInfo.packageName);

      Crypto.Digest sha1Digest =
          Crypto.sha1.convert(Uint8List.fromList(packageNameBytes));

      String base64Signature = base64.encode(sha1Digest.bytes);

      String hashKey = encrypt(
        base64Signature.trim().replaceAll("\n", ""),
        await decodePublicKey(Constants.PUBLIC_KEY),
      ).toString();

      return hashKey;
    } on PlatformException catch (e) {
      // Handle platform-specific exceptions
      print("Error: ${e.message}");
    } catch (e) {
      // Handle other exceptions
      print("Error: $e");
    }

    return "";
  }

  Future<RSAPublicKey> decodePublicKey(String publicKey) async {
    bool isSimplePublic = true;

    if (publicKey.contains("-----BEGIN RSA PUBLIC KEY-----")) {
      isSimplePublic = false;
    }

    // Remove the extra string from the public key
    String publicKeyString = getDecodedKey(publicKey);
    print("@public string $publicKeyString");

    if (isSimplePublic) {
      List<int> publicBytes = base64.decode(publicKeyString);
      ASN1Sequence seq =
          ASN1Sequence.fromBytes(Uint8List.fromList(publicBytes));
      ASN1Integer modulus = seq.elements[0] as ASN1Integer;
      ASN1Integer publicExponent = seq.elements[1] as ASN1Integer;

      RSAPublicKey key = RSAPublicKey(
        modulus.valueAsBigInteger,
        publicExponent.valueAsBigInteger,
      );

      return key;
    } else {
      List<int> keyBytes = base64.decode(publicKeyString);
      ASN1Sequence seq = ASN1Sequence.fromBytes(Uint8List.fromList(keyBytes));

      ASN1Integer modulus = seq.elements[0] as ASN1Integer;
      ASN1Integer publicExponent = seq.elements[1] as ASN1Integer;

      RSAPublicKey key = RSAPublicKey(
        modulus.valueAsBigInteger,
        publicExponent.valueAsBigInteger,
      );

      return key;
    }
  }

  String getDecodedKey(String publicKey) {
    List<int> decodedBytes = base64.decode(publicKey);

    // Convert the decoded bytes to a string
    String decodedString = utf8.decode(decodedBytes);

    return decodedString
        .replaceAll("-----BEGIN PUBLIC KEY-----", "")
        .replaceAll("-----END PUBLIC KEY-----", "")
        .replaceAll("-----BEGIN RSA PUBLIC KEY-----", "")
        .replaceAll("-----END RSA PUBLIC KEY-----", "")
        .replaceAll("\n", "");
  }

  String encrypt(String plaintext, RSAPublicKey publicKey) {
    try {
      final encryptor = OAEPEncoding(RSAEngine())
        ..init(
          true,
          PublicKeyParameter<RSAPublicKey>(publicKey),
        );

      Uint8List plaintextBytes = Uint8List.fromList(utf8.encode(plaintext));
      Uint8List encryptedBytes = encryptor.process(plaintextBytes);

      return bytesToHex(encryptedBytes);
    } catch (e) {
      print("Encryption error: $e");
      return "";
    }
  }

  String bytesToHex(Uint8List bytes) {
    StringBuffer hexStringBuilder = StringBuffer();
    for (int i = 0; i < bytes.length; i++) {
      // Convert each byte to its hexadecimal representation
      hexStringBuilder
          .write(bytes[i].toRadixString(16).padLeft(2, '0').toUpperCase());
    }
    return hexStringBuilder.toString();
  }
}
