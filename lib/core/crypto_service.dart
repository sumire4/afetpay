import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ed25519 tabanlı dijital imza servisi.
/// Her cihazda uygulama kurulumunda bir kez anahtar çifti üretilir.
/// Özel anahtar SharedPreferences'ta base64 olarak saklanır.
/// Transfer payload'ları bu anahtarla imzalanır; alıcı cihaz
/// gönderilen public key ile imzayı doğrular.
class CryptoService {
  CryptoService._();
  static final CryptoService instance = CryptoService._();

  static const _privateKeyPref = 'ed25519_private_key';
  static const _publicKeyPref = 'ed25519_public_key';

  final _algorithm = Ed25519();

  SimpleKeyPair? _cachedKeyPair;

  /// Mevcut anahtar çiftini yükler; yoksa yeni üretir ve kaydeder.
  Future<SimpleKeyPair> getOrCreateKeyPair() async {
    if (_cachedKeyPair != null) return _cachedKeyPair!;

    final prefs = await SharedPreferences.getInstance();
    final privateKeyB64 = prefs.getString(_privateKeyPref);
    final publicKeyB64 = prefs.getString(_publicKeyPref);

    if (privateKeyB64 != null && publicKeyB64 != null) {
      // Kayıtlı anahtarları geri yükle
      final privateKeyBytes = base64Decode(privateKeyB64);
      final publicKeyBytes = base64Decode(publicKeyB64);

      _cachedKeyPair = SimpleKeyPairData(
        privateKeyBytes,
        publicKey: SimplePublicKey(publicKeyBytes, type: KeyPairType.ed25519),
        type: KeyPairType.ed25519,
      );
      return _cachedKeyPair!;
    }

    // İlk kez: yeni anahtar çifti üret
    _cachedKeyPair = await _algorithm.newKeyPair();
    await _saveKeyPair(_cachedKeyPair!);
    return _cachedKeyPair!;
  }

  /// Anahtar çiftini SharedPreferences'a kaydeder.
  Future<void> _saveKeyPair(SimpleKeyPair keyPair) async {
    final prefs = await SharedPreferences.getInstance();
    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
    final publicKey = await keyPair.extractPublicKey();

    await prefs.setString(
        _privateKeyPref, base64Encode(privateKeyBytes));
    await prefs.setString(
        _publicKeyPref, base64Encode(publicKey.bytes));
  }

  /// Verilen veriyi (genellikle txId + amount + fromWalletId) imzalar.
  /// Dönen değer base64 kodlu imzadır.
  Future<String> sign(String data) async {
    final keyPair = await getOrCreateKeyPair();
    final bytes = utf8.encode(data);
    final signature = await _algorithm.sign(bytes, keyPair: keyPair);
    return base64Encode(signature.bytes);
  }

  /// Cihazın public key'ini base64 string olarak döner.
  Future<String> getPublicKeyBase64() async {
    final keyPair = await getOrCreateKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    return base64Encode(publicKey.bytes);
  }

  /// İmzayı doğrular.
  ///
  /// [data]        — imzalanan orijinal veri
  /// [signatureB64] — base64 kodlu imza
  /// [publicKeyB64] — göndericinin base64 kodlu public key'i
  ///
  /// Döner: true ise imza geçerli, false ise geçersiz veya değiştirilmiş.
  Future<bool> verify({
    required String data,
    required String signatureB64,
    required String publicKeyB64,
  }) async {
    try {
      final dataBytes = utf8.encode(data);
      final signatureBytes = base64Decode(signatureB64);
      final publicKeyBytes = base64Decode(publicKeyB64);

      final publicKey =
      SimplePublicKey(publicKeyBytes, type: KeyPairType.ed25519);
      final signature = Signature(signatureBytes, publicKey: publicKey);

      return await _algorithm.verify(dataBytes, signature: signature);
    } catch (_) {
      // Hatalı base64, kısa byte dizisi vb. → geçersiz say
      return false;
    }
  }

  /// Anahtar çiftini sıfırlar (çıkış yapıldığında çağrılır).
  Future<void> clearKeys() async {
    _cachedKeyPair = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_privateKeyPref);
    await prefs.remove(_publicKeyPref);
  }
}