import 'dart:convert';
import 'dart:typed_data';
import 'package:nfc_manager/nfc_manager.dart';

/// NDEF tabanlı NFC para transferi için encode/decode yardımcısı.
///
/// Payload formatı (URI scheme):
///   afetpay://transfer?amount=150.00&txId=UUID&from=AY•4821&note=Market
class NfcService {
  NfcService._();

  static const _scheme = 'afetpay://transfer';

  /// Gönderici NDEF mesajı oluşturur.
  static NdefMessage buildTransferMessage({
    required double amount,
    required String txId,
    required String fromWalletId,
    String note = '',
  }) {
    final uri = Uri.parse(_scheme).replace(queryParameters: {
      'amount': amount.toStringAsFixed(2),
      'txId': txId,
      'from': fromWalletId,
      'note': note,
    });
    final payload = _encodeTextRecord(uri.toString());
    return NdefMessage([NdefRecord(typeNameFormat: NdefTypeNameFormat.nfcWellknown, type: Uint8List.fromList([0x54]), identifier: Uint8List(0), payload: payload)]);
  }

  /// NFC Tag'den okunan NDEF mesajını parse eder.
  /// Geçerli bir AfetPay transfer mesajı ise map döner, değilse null.
  static Map<String, String>? parseTransferMessage(NdefMessage message) {
    for (final record in message.records) {
      try {
        final text = _decodeTextRecord(record.payload);
        if (text != null && text.startsWith(_scheme)) {
          final uri = Uri.parse(text);
          final params = uri.queryParameters;
          if (params.containsKey('amount') &&
              params.containsKey('txId') &&
              params.containsKey('from')) {
            return Map<String, String>.from(params);
          }
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }

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
      final text = utf8.decode(payload.sublist(1 + langLen));
      return text;
    } catch (_) {
      return null;
    }
  }
}
