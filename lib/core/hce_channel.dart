import 'package:flutter/services.dart';

/// Flutter tarafı HCE (Host Card Emulation) Method Channel wrapper.
///
/// Gönderici telefon bu kanal üzerinden native Android HCE servisini
/// başlatır/durdurur. Native servis, alıcı telefonun NFC okumasına
/// sanal bir NDEF Type 4 Tag gibi yanıt verir.
class HceChannel {
  HceChannel._();

  static const _channel = MethodChannel('com.afetpay/hce');

  /// HCE'yi başlatır ve gönderilecek URI payload'unu set eder.
  ///
  /// [ndefUri] — NfcService.buildTransferUri() tarafından üretilen,
  /// Ed25519 imzası içeren tam URI string'i.
  ///
  /// Throws [PlatformException] if native layer fails.
  static Future<void> startHce(String ndefUri) async {
    await _channel.invokeMethod<void>('hce_start', {'uri': ndefUri});
  }

  /// HCE'yi durdurur ve payload'u temizler.
  static Future<void> stopHce() async {
    await _channel.invokeMethod<void>('hce_stop');
  }
}
