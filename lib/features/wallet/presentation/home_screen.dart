import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:afetpay/features/auth/presentation/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:afetpay/features/wallet/presentation/about_screen.dart';

const _kPrimary = Color(0xFF64819A);
const _kOnPrimary = Color(0xFFFFFFFF);
const _kPrimaryContainer = Color(0xFFD4E4F7);
const _kSecondary = Color(0xFF2E7D5E);
const _kSecondaryContainer = Color(0xFFB7EDD8);
const _kError = Color(0xFFBA1A1A);
const _kSurface = Color(0xFFF6F9FC);
const _kSurfaceVariant = Color(0xFFE8EFF6);
const _kOutline = Color(0xFFB0C4D8);
const _kOnSurface = Color(0xFF1A2533);
const _kOnSurfaceVariant = Color(0xFF4A5E72);

class TransactionItem {
  final String id;
  final String name;
  final double amount;
  final bool isSent;
  final DateTime time;
  final String note;

  const TransactionItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.isSent,
    required this.time,
    required this.note,
  });
}

/// Transfer yöntemi seçim modalı — NFC veya QR
class _TransferMethodSheet extends StatelessWidget {
  final bool isSend;

  const _TransferMethodSheet({required this.isSend});

  @override
  Widget build(BuildContext context) {
    final actionLabel = isSend ? 'Gönder' : 'Al';
    final actionColor = isSend ? _kPrimary : _kSecondary;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '$actionLabel Yöntemi Seçin',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _kOnSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Karşı tarafla nasıl transfer yapmak istersiniz?',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _kOnSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              // NFC seçeneği
              Expanded(
                child: _MethodCard(
                  icon: Icons.nfc_rounded,
                  title: 'NFC',
                  subtitle: 'Telefonları\nyaklaştırın',
                  color: _kPrimary,
                  badge: 'Hızlı',
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (_) => _TransferSheet(
                        isSend: isSend,
                        method: TransferMethod.nfc,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 14),
              // QR seçeneği
              Expanded(
                child: _MethodCard(
                  icon: Icons.qr_code_2_rounded,
                  title: 'QR Kod',
                  subtitle: 'Kodu tara\nveya göster',
                  color: actionColor == _kPrimary ? const Color(0xFF5C6BC0) : _kSecondary,
                  badge: 'Kolay',
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (_) => _TransferSheet(
                        isSend: isSend,
                        method: TransferMethod.qr,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('İptal'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String badge;
  final VoidCallback onTap;

  const _MethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.25), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: _kOnSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum TransferMethod { nfc, qr }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _balanceVisible = true;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  int _selectedIndex = 0;
  final double _balance = 1250.75;
  final String _userName = 'Mete Gedik';
  final String _walletId = 'AY•4821';
  bool _isOffline = false;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  final List<TransactionItem> _transactions = [
    TransactionItem(
      id: 'tx001',
      name: 'Fatma K.',
      amount: 150.0,
      isSent: false,
      time: DateTime.now().subtract(const Duration(minutes: 12)),
      note: 'NFC ile alındı',
    ),
    TransactionItem(
      id: 'tx002',
      name: 'Mehmet A.',
      amount: 75.50,
      isSent: true,
      time: DateTime.now().subtract(const Duration(hours: 1)),
      note: 'Market alışverişi',
    ),
    TransactionItem(
      id: 'tx003',
      name: 'Zeynep D.',
      amount: 300.0,
      isSent: false,
      time: DateTime.now().subtract(const Duration(hours: 3)),
      note: 'NFC ile alındı',
    ),
    TransactionItem(
      id: 'tx004',
      name: 'Hasan B.',
      amount: 50.0,
      isSent: true,
      time: DateTime.now().subtract(const Duration(hours: 5)),
      note: 'İlaç',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _initConnectivity() async {
    late List<ConnectivityResult> result;
    try {
      result = await Connectivity().checkConnectivity();
    } on PlatformException catch (_) {
      return;
    }
    if (!mounted) {
      return;
    }
    return _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    setState(() {
      _isOffline = result.contains(ConnectivityResult.none) || result.isEmpty;
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} sa önce';
    return '${diff.inDays} gün önce';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kSurface,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildAppBar()),
                if (_isOffline)
                  SliverToBoxAdapter(child: _buildOfflineBanner()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _buildBalanceCard(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: _buildActionButtons(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 28, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Son İşlemler',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: _kOnSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Tümü',
                              style: TextStyle(color: _kPrimary)),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final tx = _transactions[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: _buildTransactionTile(tx),
                      );
                    },
                    childCount: _transactions.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
          ),
          const AboutScreen(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _showProfileSheet(context),
            icon: const Icon(Icons.account_circle_outlined),
            color: _kOnSurfaceVariant,
          ),
          const Expanded(
            child: Center(
              child: Text(
                'AfetPay',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _kPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
            },
            icon: const Icon(Icons.info_outline_rounded),
            color: _kOnSurfaceVariant,
          ),
        ],
      ),
    );
  }

  void _showProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: _kPrimary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, size: 40, color: _kPrimary),
            ),
            const SizedBox(height: 16),
            const Text(
              'Mete Gedik',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _kOnSurface,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Cüzdan No: AY•4821',
              style: TextStyle(color: _kOnSurfaceVariant, fontSize: 14),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('is_logged_in');
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout_rounded, color: _kError),
                label: const Text(
                  'Çıkış Yap',
                  style: TextStyle(color: _kError, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: _kError),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3CD),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFFFB300).withOpacity(_pulseAnimation.value),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 18, color: Color(0xFF7B5800)),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Çevrimdışı görünüyorsunuz — NFC transferi aktif',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF7B5800),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF55728A), Color(0xFFAFC1D5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet_rounded,
                      color: Colors.white60, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Cüzdan $_walletId',
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _balanceVisible = !_balanceVisible);
                },
                child: Icon(
                  _balanceVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.white60,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _balanceVisible
                ? Row(
              key: const ValueKey('visible'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text('₺',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 22,
                          fontWeight: FontWeight.w500)),
                ),
                const SizedBox(width: 4),
                Text(
                  '1.250,75',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                    letterSpacing: -1,
                  ),
                ),
              ],
            )
                : const Text(
              key: ValueKey('hidden'),
              '••••••',
              style: TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text('Kullanılabilir Bakiye',
              style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 20),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user_rounded,
                    color: Color(0xFF69F0AE), size: 14),
                SizedBox(width: 6),
                Text(
                  'Ed25519 ile imzalandı · Güvenli',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.arrow_upward,
            label: 'Gönder',
            color: _kPrimary,
            onTap: () => _showMethodSelectionSheet(context, isSend: true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.arrow_downward,
            label: 'Al',
            color: _kPrimary,
            onTap: () => _showMethodSelectionSheet(context, isSend: false),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.history,
            label: 'Geçmiş',
            color: _kOnSurfaceVariant,
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionTile(TransactionItem tx) {
    final color = tx.isSent ? _kError : _kSecondary;
    final sign = tx.isSent ? '-' : '+';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kOutline.withOpacity(0.4), width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              tx.isSent ? Icons.arrow_upward : Icons.arrow_downward,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: _kOnSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.nfc_rounded,
                        size: 12, color: _kOnSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(tx.note,
                        style: const TextStyle(
                            fontSize: 12, color: _kOnSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sign₺${tx.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: color,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _formatTime(tx.time),
                style: const TextStyle(
                    fontSize: 11, color: _kOnSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Yöntem seçim modal'ını göster
  void _showMethodSelectionSheet(BuildContext context, {required bool isSend}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _TransferMethodSheet(isSend: isSend),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NfcSheet extends StatefulWidget {
  const _NfcSheet();

  @override
  State<_NfcSheet> createState() => _NfcSheetState();
}

class _NfcSheetState extends State<_NfcSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _ripple;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _ripple = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'NFC Transferi',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _kOnSurface),
          ),
          const SizedBox(height: 6),
          const Text('Telefonları yaklaştırın',
              style: TextStyle(color: _kOnSurfaceVariant, fontSize: 14)),
          const SizedBox(height: 36),
          SizedBox(
            width: 160,
            height: 160,
            child: AnimatedBuilder(
              animation: _ripple,
              builder: (_, __) => Stack(
                alignment: Alignment.center,
                children: [
                  for (final factor in [0.4, 0.65, 0.9])
                    Opacity(
                      opacity:
                      (1.0 - ((_ripple.value - factor).abs() % 1.0))
                          .clamp(0.0, 0.5),
                      child: Container(
                        width: 160 * factor,
                        height: 160 * factor,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _kPrimary, width: 2),
                        ),
                      ),
                    ),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: _kPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.nfc_rounded,
                        color: Colors.white, size: 36),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Cihazlar birbirine değdiğinde\ntransfer otomatik başlar',
            textAlign: TextAlign.center,
            style: TextStyle(color: _kOnSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('İptal'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransferSheet extends StatefulWidget {
  final bool isSend;
  final TransferMethod method;

  const _TransferSheet({required this.isSend, required this.method});

  @override
  State<_TransferSheet> createState() => _TransferSheetState();
}

class _TransferSheetState extends State<_TransferSheet>
    with SingleTickerProviderStateMixin {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  // NFC ripple animation
  late AnimationController _nfcCtrl;
  late Animation<double> _nfcRipple;

  @override
  void initState() {
    super.initState();
    _nfcCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _nfcRipple = CurvedAnimation(parent: _nfcCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _nfcCtrl.dispose();
    super.dispose();
  }

  bool get _isNfc => widget.method == TransferMethod.nfc;
  bool get _isQr => widget.method == TransferMethod.qr;

  Future<void> _handleNfcTransfer() async {
    final amountText = _amountCtrl.text.replaceAll(',', '.');
    final amount = double.tryParse(amountText) ?? 0.0;
    
    if (amount <= 0 && widget.isSend) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen geçerli bir tutar girin')),
      );
      return;
    }

    try {
      bool isAvailable = await NfcManager.instance.isAvailable();
      if (!isAvailable) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('NFC bu cihazda desteklenmiyor veya kapalı.')),
        );
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cihazınızı diğer cihaza yaklaştırın...')),
      );

      NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          NfcManager.instance.stopSession();
          _showSuccessDialog(amount);
        },
      );
    } catch (e) {
      NfcManager.instance.stopSession();
    }
  }

  void _showSuccessDialog(double amount) {
    if (!mounted) return;
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Colors.green),
            ),
            const SizedBox(width: 12),
            const Text('Başarılı'),
          ],
        ),
        content: Text(
          widget.isSend 
              ? '₺${amount.toStringAsFixed(2)} tutarındaki transferiniz başarıyla karşı cihaza aktarıldı.'
              : 'Karşı cihazdan ₺${amount.toStringAsFixed(2)} başarıyla alındı.',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isSend ? _kPrimary : _kSecondary;
    final qrColor = widget.isSend ? const Color(0xFF5C6BC0) : _kSecondary;
    final activeColor = _isNfc ? color : qrColor;
    final label = widget.isSend ? 'Gönder' : 'Al';

    return Padding(
      padding:
      EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Başlık + method badge
            Row(
              children: [
                Text(
                  '$label İşlemi',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _kOnSurface),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: activeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: activeColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isNfc ? Icons.nfc_rounded : Icons.qr_code_2_rounded,
                        size: 13,
                        color: activeColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isNfc ? 'NFC' : 'QR Kod',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: activeColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Tutar alanı
            TextField(
              controller: _amountCtrl,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _kOnSurface),
              decoration: InputDecoration(
                prefixText: '₺ ',
                prefixStyle: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: activeColor),
                hintText: '0,00',
                hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 28,
                    fontWeight: FontWeight.bold),
                filled: true,
                fillColor: activeColor.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                  BorderSide(color: activeColor.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                  BorderSide(color: activeColor.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: activeColor, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Not alanı
            TextField(
              controller: _noteCtrl,
              decoration: InputDecoration(
                hintText: 'Not ekle (isteğe bağlı)',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: _kSurfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- NFC bölümü ---
            if (_isNfc) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kPrimaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 16, color: _kPrimary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Transfer NFC ile gerçekleşir, internet gerekmez',
                        style: TextStyle(fontSize: 12, color: _kPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // NFC ripple animasyonu (küçük versiyon)
              Center(
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: AnimatedBuilder(
                    animation: _nfcRipple,
                    builder: (_, __) => Stack(
                      alignment: Alignment.center,
                      children: [
                        for (final factor in [0.4, 0.65, 0.9])
                          Opacity(
                            opacity: (1.0 -
                                ((_nfcRipple.value - factor).abs() % 1.0))
                                .clamp(0.0, 0.4),
                            child: Container(
                              width: 100 * factor,
                              height: 100 * factor,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: _kPrimary, width: 1.5),
                              ),
                            ),
                          ),
                        Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            color: _kPrimary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.nfc_rounded,
                              color: Colors.white, size: 24),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Cihazları yaklaştırmaya hazır',
                  style: TextStyle(
                    fontSize: 12,
                    color: _kOnSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // --- QR bölümü ---
            if (_isQr) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: qrColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: qrColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 16, color: qrColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.isSend
                            ? 'Karşı tarafın QR kodunu okutun'
                            : 'QR kodunuzu karşı tarafa gösterin',
                        style: TextStyle(fontSize: 12, color: qrColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // QR kod placeholder
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: _kSurfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: qrColor.withOpacity(0.3), width: 1.5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_2_rounded,
                          size: 64, color: qrColor.withOpacity(0.7)),
                      const SizedBox(height: 4),
                      Text(
                        widget.isSend ? 'Tarayıcı Açılıyor...' : 'QR Hazır',
                        style: TextStyle(
                          fontSize: 10,
                          color: qrColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Buton
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  if (_isNfc) {
                    await _handleNfcTransfer();
                  } else {
                    Navigator.pop(context);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: activeColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isNfc ? Icons.nfc_rounded : Icons.qr_code_scanner_rounded,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isNfc ? 'NFC ile $label' : 'QR ile $label',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}