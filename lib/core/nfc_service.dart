import 'dart:convert';
import 'dart:typed_data';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:afetpay/core/crypto_service.dart';

/// NDEF tabanlı NFC para transferi için encode/decode yardımcısı.
///
/// Payload formatı (URI scheme) — imzalı:
///   afetpay://transfer?amount=150.00&txId=UUID&from=AY•4821&note=Market
///             &sig=BASE64_SIGNATURE&pk=BASE64_PUBLIC_KEY
///
/// İmzalanan veri: "$txId|$amount|$fromWalletId"
/// Bu üç alanın birleşimi imzalanır; alıcı aynı veriyi yeniden
/// oluşturarak Ed25519 doğrulaması yapar.
class NfcService {
  NfcService._();

  static const _scheme = 'afetpay://transfer';

  /// Gönderici NDEF mesajı oluşturur (imzalı).
  static Future<NdefMessage> buildTransferMessage({
    required double amount,
    required String txId,
    required String fromWalletId,
    String note = '',
  }) async {
    // İmzalanacak kanonik veri — sıra değişmemeli
    final signingData = _buildSigningData(
      txId: txId,
      amount: amount,
      fromWalletId: fromWalletId,
    );

    final signature = await CryptoService.instance.sign(signingData);
    final publicKey = await CryptoService.instance.getPublicKeyBase64();

    final uri = Uri.parse(_scheme).replace(queryParameters: {
      'amount': amount.toStringAsFixed(2),
      'txId': txId,
      'from': fromWalletId,
      'note': note,
      'sig': signature,
      'pk': publicKey,
    });

    final payload = _encodeTextRecord(uri.toString());
    return NdefMessage([
      NdefRecord(
        typeNameFormat: NdefTypeNameFormat.nfcWellknown,
        type: Uint8List.fromList([0x54]), // 'T' — Text record
        identifier: Uint8List(0),
        payload: payload,
      )
    ]);
  }

  /// NFC Tag'den okunan NDEF mesajını parse eder.
  ///
  /// Döner:
  ///   - [NfcParseResult.valid]   → imza geçerli, params dolu
  ///   - [NfcParseResult.invalidSignature] → mesaj okundu ama imza bozuk
  ///   - [NfcParseResult.notAfetPay]       → AfetPay mesajı değil
  static Future<NfcParseResult> parseAndVerifyTransferMessage(
      NdefMessage message) async {
    for (final record in message.records) {
      try {
        final text = _decodeTextRecord(record.payload);
        if (text == null || !text.startsWith(_scheme)) continue;

        final uri = Uri.parse(text);
        final params = uri.queryParameters;

        // Zorunlu alanlar
        if (!params.containsKey('amount') ||
            !params.containsKey('txId') ||
            !params.containsKey('from') ||
            !params.containsKey('sig') ||
            !params.containsKey('pk')) {
          return NfcParseResult.notAfetPay();
        }

        // İmza doğrulama
        final signingData = _buildSigningData(
          txId: params['txId']!,
          amount: double.tryParse(params['amount']!) ?? 0.0,
          fromWalletId: params['from']!,
        );

        final isValid = await CryptoService.instance.verify(
          data: signingData,
          signatureB64: params['sig']!,
          publicKeyB64: params['pk']!,
        );

        if (!isValid) return NfcParseResult.invalidSignature();

        return NfcParseResult.valid(Map<String, String>.from(params));
      } catch (_) {
        continue;
      }
    }
    return NfcParseResult.notAfetPay();
  }

  /// İmzalanacak kanonik veri stringini oluşturur.
  /// Sıra ve format her iki tarafta aynı olmalıdır.
  static String _buildSigningData({
    required String txId,
    required double amount,
    required String fromWalletId,
  }) =>
      '$txId|${amount.toStringAsFixed(2)}|$fromWalletId';

  /// NFC Text Record (type=T) payload encode.
  /// Format: [status byte][lang bytes][text bytes]
  static Uint8List _encodeTextRecord(String text) {
    const lang = 'en';
    final langBytes = utf8.encode(lang);
    final textBytes = utf8.encode(text);
    final statusByte = langBytes.length & 0x3F;
    return Uint8List.fromList([statusByte, ...langBytes, ...textBytes]);
  }

  /// NFC Text Record payload decode.
  static String? _decodeTextRecord(Uint8List payload) {
    if (payload.isEmpty) return null;
    try {
      final langLen = payload[0] & 0x3F;
      return utf8.decode(payload.sublist(1 + langLen));
    } catch (_) {
      return null;
    }
  }
}

/// NFC mesajı parse sonucu.
class NfcParseResult {
  final NfcParseStatus status;
  final Map<String, String>? params;

  NfcParseResult._({required this.status, this.params});

  factory NfcParseResult.valid(Map<String, String> params) =>
      NfcParseResult._(status: NfcParseStatus.valid, params: params);

  factory NfcParseResult.invalidSignature() =>
      NfcParseResult._(status: NfcParseStatus.invalidSignature);

  factory NfcParseResult.notAfetPay() =>
      NfcParseResult._(status: NfcParseStatus.notAfetPay);

  bool get isValid => status == NfcParseStatus.valid;
}

enum NfcParseStatus { valid, invalidSignature, notAfetPay }