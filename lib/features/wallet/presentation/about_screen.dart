import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

const _kPrimary = Color(0xFF1B5E97);
const _kPrimaryContainer = Color(0xFFD4E4F7);
const _kSecondary = Color(0xFF2E7D5E);
const _kSecondaryContainer = Color(0xFFB7EDD8);
const _kError = Color(0xFFBA1A1A);
const _kErrorContainer = Color(0xFFFFDAD6);
const _kWarning = Color(0xFF7B5800);
const _kWarningContainer = Color(0xFFFFF3CD);
const _kSurface = Color(0xFFF6F9FC);
const _kOnSurface = Color(0xFF1A2533);
const _kOnSurfaceVariant = Color(0xFF4A5E72);
const _kOutline = Color(0xFFB0C4D8);

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kSurface,
      appBar: AppBar(
        backgroundColor: _kSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const BackButton(color: _kOnSurface),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Acil Bilgiler',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _kOnSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Çevrimdışı erişilebilir · Son güncelleme: bugün',
                      style: TextStyle(fontSize: 13, color: _kOnSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _kErrorContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _kError.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _kError.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.emergency_rounded, color: _kError, size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Acil Hat: 112',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _kError)),
                          SizedBox(height: 2),
                          Text('AFAD: 122  ·  Kızılay: 168',
                              style: TextStyle(fontSize: 13, color: _kError)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: _kError.withOpacity(0.6)),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                child: Text(
                  'Yakınımdaki Noktalar',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: _kOnSurfaceVariant, letterSpacing: 0.5),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.05,
                ),
                delegate: SliverChildListDelegate([
                  _InfoCard(
                    icon: Icons.atm_rounded,
                    label: 'En Yakın ATM',
                    sublabel: 'Haritada Gör',
                    color: _kPrimary,
                    containerColor: _kPrimaryContainer,
                    onTap: () => _openMap(context, 'atm'),
                  ),
                  _InfoCard(
                    icon: Icons.people_alt_rounded,
                    label: 'Toplanma Alanları',
                    sublabel: 'Haritada Gör',
                    color: _kSecondary,
                    containerColor: _kSecondaryContainer,
                    onTap: () => _openMap(context, 'afet toplanma alanı'),
                  ),
                  _InfoCard(
                    icon: Icons.local_hospital_rounded,
                    label: 'Hastaneler',
                    sublabel: 'Haritada Gör',
                    color: const Color(0xFFB71C1C),
                    containerColor: const Color(0xFFFFEBEE),
                    onTap: () => _openMap(context, 'hastane'),
                  ),
                  _InfoCard(
                    icon: Icons.storefront_rounded,
                    label: 'Yardım Merkezleri',
                    sublabel: 'Haritada Gör',
                    color: _kWarning,
                    containerColor: _kWarningContainer,
                    onTap: () => _openMap(context, 'yardım merkezi'),
                  ),
                  _InfoCard(
                    icon: Icons.local_gas_station_rounded,
                    label: 'Yakıt İstasyonları',
                    sublabel: 'Haritada Gör',
                    color: const Color(0xFF1B5E20),
                    containerColor: const Color(0xFFE8F5E9),
                    onTap: () => _openMap(context, 'yakıt istasyonu'),
                  ),
                  _InfoCard(
                    icon: Icons.water_drop_rounded,
                    label: 'Su Dağıtım',
                    sublabel: 'Haritada Gör',
                    color: const Color(0xFF0277BD),
                    containerColor: const Color(0xFFE1F5FE),
                    onTap: () => _openMap(context, 'su dağıtım'),
                  ),
                ]),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 10),
                child: Text('Uygulama',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: _kOnSurfaceVariant, letterSpacing: 0.5)),
              ),
            ),

            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _kOutline.withOpacity(0.4), width: 0.8),
                ),
                child: Column(
                  children: [
                    _AppInfoTile(icon: Icons.nfc_rounded, label: 'NFC Transferi',
                        value: 'Aktif', valueColor: _kSecondary),
                    Divider(height: 1, color: _kOutline.withOpacity(0.3)),
                    _AppInfoTile(icon: Icons.security_rounded, label: 'Şifreleme',
                        value: 'Ed25519', valueColor: _kPrimary),
                    Divider(height: 1, color: _kOutline.withOpacity(0.3)),
                    _AppInfoTile(icon: Icons.wifi_off_rounded, label: 'Çevrimdışı Mod',
                        value: 'Destekleniyor', valueColor: _kSecondary),
                    Divider(height: 1, color: _kOutline.withOpacity(0.3)),
                    _AppInfoTile(icon: Icons.info_outline_rounded, label: 'Versiyon',
                        value: 'v1.0.0', valueColor: _kOnSurfaceVariant),
                  ],
                ),
              ),
            ),

            // ── EN ALTTA: Hakkında bölümü ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 10),
                child: Text(' ',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: _kOnSurfaceVariant, letterSpacing: 0.5)),
              ),
            ),

            const SliverToBoxAdapter(child: _AboutSection()),
          ],
        ),
      ),
    );
  }

  Future<void> _openMap(BuildContext context, String query) async {
    try {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konum bulunuyor, harita açılacak...'), duration: Duration(seconds: 2)),
      );

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konum servisleri kapalı, lütfen açın.')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Konum izni reddedildi.')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konum izni kalıcı olarak reddedildi, ayarlardan açınız.')),
        );
        return;
      }

      // Konum bilgisini alalım, bu işlem Google Maps vs gibi uygulamalara kullanıcının
      // mevcut konumundan arama yapmasını kolaylaştırır.
      await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);

      final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Harita uygulaması açılamadı.')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bir hata oluştu. Harita açılamadı.')),
      );
    }
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final Color containerColor;
  final VoidCallback onTap;

  const _InfoCard({required this.icon, required this.label, required this.sublabel,
    required this.color, required this.containerColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
          boxShadow: [BoxShadow(color: color.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: containerColor, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14, color: _kOnSurface)),
                const SizedBox(height: 3),
                Text(sublabel, style: TextStyle(
                    fontSize: 11, color: color, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AppInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  const _AppInfoTile({required this.icon, required this.label,
    required this.value, required this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _kOnSurfaceVariant),
          const SizedBox(width: 14),
          Expanded(child: Text(label,
              style: const TextStyle(fontSize: 14, color: _kOnSurface))),
          Text(value, style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: valueColor)),
        ],
      ),
    );
  }
}
class _TipItem extends StatelessWidget {
  final String text;
  const _TipItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: _kPrimary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: _kOnSurface,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
      child: Column(
        children: [
          const Icon(Icons.info_outline_rounded, size: 52, color: _kOnSurfaceVariant),
          const SizedBox(height: 16),
          const Text('AfetPay',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                  color: _kOnSurface, letterSpacing: -0.5)),
          const SizedBox(height: 12),
          const Text(
              'AfetPay, Fırat Üniversitesi bünyesinde geliştirilen, '
                  'doğal afet ve olağanüstü hal senaryolarına yönelik '
                  'bir mobil ödeme çözümüdür. İnternet altyapısının '
                  'işlevsiz kaldığı koşullarda NFC teknolojisi aracılığıyla '
                  'cihazlar arasında uçtan uca şifreli, güvenli ve anlık '
                  'para transferi imkânı sunmaktadır.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: _kOnSurfaceVariant, height: 1.6),
          ),
          const SizedBox(height: 20),
          const Text('© 2025 Tüm hakları saklıdır.',
              style: TextStyle(fontSize: 12, color: _kOnSurfaceVariant)),
          const SizedBox(height: 4),
          const Text('Versiyon: 1.0.0',
              style: TextStyle(fontSize: 12, color: _kOnSurfaceVariant)),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kPrimaryContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kPrimary.withOpacity(0.2), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded,
                        color: _kPrimary, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Öneriler',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _TipItem(text: 'Uygulamayı afet öncesinde kurun ve cüzdanınızı önceden oluşturun.'),
                _TipItem(text: 'NFC özelliğinin telefonunuzda açık olduğundan emin olun.'), _TipItem(text: 'İşlem geçmişinizi düzenli olarak kontrol edin.'),
                _TipItem(text: 'Cihazınızın şarjını afet durumlarında mümkün olduğunca yüksek tutun.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}