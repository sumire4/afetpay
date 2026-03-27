# AfetPay

AfetPay, doğal afet ve olağanüstü hal senaryolarında kesintisiz finansal erişim sağlamak amacıyla geliştirilmiş, NFC tabanlı bir mobil ödeme ve cüzdan uygulamasıdır. Fırat Üniversitesi bünyesinde prototiplenen bu çözüm, internet altyapısının işlevsiz kaldığı durumlarda dahi güvenli para transferine olanak tanır.

## Temel Özellikler

*   **Çevrimdışı İşlem Kabiliyeti:** İnternet bağlantısı olmaksızın cihazlar arası veri değişimi.
*   **NFC ile Ödeme:** Temassız teknoloji kullanılarak hızlı ve güvenli P2P (kişiden kişiye) transfer.
*   **Üst Düzey Güvenlik:** Ed25519 dijital imza algoritması ile uçtan uca şifreli işlemler.
*   **Acil Durum Bilgi Sistemi:** Çevrimdışı erişilebilir hastane, toplanma alanı ve yardım noktası rehberi.
*   **Kritik Rehber:** Acil durum numaraları (AFAD, Kızılay, 112) ve hayati öneme sahip afet önerileri.

## Teknolojiler

*   **Framework:** Flutter (Dart)
*   **İletişim:** NFC (Near Field Communication)
*   **Güvenlik:** Ed25519 Şifreleme
*   **Yerel Depolama:** Shared Preferences & Local Persistence

## Kurulum

Projenin yerel ortamda çalıştırılması için aşağıdaki adımları izleyin:

1.  Depoyu klonlayın: `git clone https://github.com/kullaniciadi/afetpay.git`
2.  Proje dizinine gidin: `cd afetpay`
3.  Bağımlılıkları yükleyin: `flutter pub get`
4.  Uygulamayı çalıştırın: `flutter run`

*Not: NFC özelliklerinin tam fonksiyonel test edilebilmesi için fiziksel bir mobil cihaz gereklidir.*

## Lisans

© 2025 AfetPay. Tüm hakları saklıdır. Fırat Üniversitesi bünyesinde geliştirilmiştir.
