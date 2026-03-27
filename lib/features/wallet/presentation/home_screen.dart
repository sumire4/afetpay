import 'dart:async';
import 'dart:typed_data';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:afetpay/features/auth/presentation/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:afetpay/features/wallet/presentation/about_screen.dart';
import 'package:afetpay/core/wallet_service.dart';
import 'package:afetpay/core/nfc_service.dart';
import 'package:uuid/uuid.dart';

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

// TransactionItem — UI display model (wraps TransactionRecord)
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

  factory TransactionItem.fromRecord(TransactionRecord r) => TransactionItem(
        id: r.id,
        name: r.name,
        amount: r.amount,
        isSent: r.isSent,
        time: r.time,
        note: r.note,
      );
}

enum TransferMethod { nfc, qr }

/// Transfer yöntemi seçim modalı
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
          const Text(
            'Karşı tarafla nasıl transfer yapmak istersiniz?',
            textAlign: TextAlign.center,
            style: TextStyle(color: _kOnSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
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
              Expanded(
                child: _MethodCard(
                  icon: Icons.qr_code_2_rounded,
                  title: 'QR Kod',
                  subtitle: 'Kodu tara\nveya göster',
                  color: actionColor == _kPrimary
                      ? const Color(0xFF5C6BC0)
                      : _kSecondary,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

// ─────────────────────────────────────────────
// HomeScreen
// ─────────────────────────────────────────────

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

  // Wallet state — loaded from SharedPreferences
  double _balance = 0;
  String _userName = '';
  String _walletId = '';
  List<TransactionItem> _transactions = [];
  bool _isLoading = true;

  bool _isOffline = false;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

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
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    final prefs = await SharedPreferences.getInstance();
    final balance = await WalletService.instance.loadBalance();
    final records = await WalletService.instance.loadTransactions();
    final userName = prefs.getString('user_name') ?? 'Kullanıcı';
    final walletId = prefs.getString('wallet_id') ?? 'AY•0000';
    if (!mounted) return;
    setState(() {
      _balance = balance;
      _userName = userName;
      _walletId = walletId;
      _transactions =
          records.map((r) => TransactionItem.fromRecord(r)).toList();
      _isLoading = false;
    });
  }

  Future<void> _refreshWalletData() async {
    final balance = await WalletService.instance.loadBalance();
    final records = await WalletService.instance.loadTransactions();
    if (!mounted) return;
    setState(() {
      _balance = balance;
      _transactions =
          records.map((r) => TransactionItem.fromRecord(r)).toList();
    });
  }

  Future<void> _initConnectivity() async {
    late List<ConnectivityResult> result;
    try {
      result = await Connectivity().checkConnectivity();
    } on PlatformException catch (_) {
      return;
    }
    if (!mounted) return;
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    setState(() {
      _isOffline =
          result.contains(ConnectivityResult.none) || result.isEmpty;
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

  String _formatBalance(double v) {
    final parts = v.toStringAsFixed(2).split('.');
    final intPart = parts[0]
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+$)'), (m) => '${m[1]}.');
    return '$intPart,${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _kSurface,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: _kSurface,
      body: SafeArea(
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
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
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
            if (_transactions.isEmpty)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Henüz işlem yok.',
                        style: TextStyle(color: _kOnSurfaceVariant)),
                  ),
                ),
              )
            else
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
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AboutScreen()),
            ),
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
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _kPrimary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, size: 40, color: _kPrimary),
            ),
            const SizedBox(height: 16),
            Text(
              _userName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _kOnSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Cüzdan No: $_walletId',
              style:
                  const TextStyle(color: _kOnSurfaceVariant, fontSize: 14),
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
                  style: TextStyle(
                      color: _kError, fontWeight: FontWeight.bold),
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
              color:
                  const Color(0xFFFFB300).withOpacity(_pulseAnimation.value),
              width: 1.5,
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.wifi_off_rounded,
                  size: 18, color: Color(0xFF7B5800)),
              SizedBox(width: 10),
              Expanded(
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
                    style:
                        const TextStyle(color: Colors.white60, fontSize: 13),
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
                        _formatBalance(_balance),
                        key: ValueKey(_balance),
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
            onTap: () => _openTransferSheet(isSend: true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.arrow_downward,
            label: 'Al',
            color: _kSecondary,
            onTap: () => _openTransferSheet(isSend: false),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.history,
            label: 'Geçmiş',
            color: _kOnSurfaceVariant,
            onTap: _refreshWalletData,
          ),
        ),
      ],
    );
  }

  void _openTransferSheet({required bool isSend}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _TransferMethodSheet(isSend: isSend),
    ).then((_) => _refreshWalletData());
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
                    Expanded(
                      child: Text(tx.note,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: _kOnSurfaceVariant)),
                    ),
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
}

// ─────────────────────────────────────────────
// Action Button
// ─────────────────────────────────────────────

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

// ─────────────────────────────────────────────
// Transfer Sheet (NFC send / receive)
// ─────────────────────────────────────────────

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
  bool _nfcActive = false;

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
    // NFC session kapatılmadan kapanırsa güvenli sonlandır
    NfcManager.instance.stopSession().catchError((_) {});
    super.dispose();
  }

  bool get _isNfc => widget.method == TransferMethod.nfc;
  bool get _isQr => widget.method == TransferMethod.qr;

  // ── GÖNDER ──────────────────────────────────
  Future<void> _handleNfcSend() async {
    final amountText = _amountCtrl.text.replaceAll(',', '.');
    final amount = double.tryParse(amountText) ?? 0.0;

    if (amount <= 0) {
      _showSnack('Lütfen geçerli bir tutar girin');
      return;
    }

    final balance = await WalletService.instance.loadBalance();
    if (amount > balance) {
      _showSnack('Yetersiz bakiye — mevcut: ₺${balance.toStringAsFixed(2)}');
      return;
    }

    final isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      _showSnack('NFC bu cihazda desteklenmiyor veya kapalı');
      return;
    }

    final txId = const Uuid().v4();
    final walletId =
        (await SharedPreferences.getInstance()).getString('wallet_id') ??
            'AY•0000';
    final note =
        _noteCtrl.text.trim().isEmpty ? 'NFC Transferi' : _noteCtrl.text.trim();

    final ndefMsg = NfcService.buildTransferMessage(
      amount: amount,
      txId: txId,
      fromWalletId: walletId,
      note: note,
    );

    setState(() => _nfcActive = true);
    _showSnack('Cihazınızı NFC tag\'e/karta yaklaştırın...');

    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          final ndef = Ndef.from(tag);
          if (ndef == null || !ndef.isWritable) {
            await NfcManager.instance.stopSession(errorMessage: 'Tag yazılabilir değil');
            if (!mounted) return;
            setState(() => _nfcActive = false);
            _showSnack('NFC tag yazılabilir değil, farklı bir tag deneyin');
            return;
          }
          await ndef.write(ndefMsg);
          await NfcManager.instance.stopSession();

          // Bakiyeyi düşür ve işlemi kaydet
          final newBalance = balance - amount;
          await WalletService.instance.saveBalance(newBalance);
          await WalletService.instance.addTransaction(TransactionRecord(
            id: txId,
            name: 'NFC Transferi',
            amount: amount,
            isSent: true,
            time: DateTime.now(),
            note: note,
          ));
          await WalletService.instance.markProcessed(txId);

          if (!mounted) return;
          setState(() => _nfcActive = false);
          _showSuccessDialog(amount);
        } catch (e) {
          await NfcManager.instance.stopSession(errorMessage: 'Yazma hatası');
          if (!mounted) return;
          setState(() => _nfcActive = false);
          _showSnack('NFC yazma hatası: $e');
        }
      },
    );
  }

  // ── AL ──────────────────────────────────────
  Future<void> _handleNfcReceive() async {
    final isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      _showSnack('NFC bu cihazda desteklenmiyor veya kapalı');
      return;
    }

    setState(() => _nfcActive = true);
    _showSnack('Cihazınızı NFC tag\'e/karta yaklaştırın...');

    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          final ndef = Ndef.from(tag);
          if (ndef == null) {
            await NfcManager.instance.stopSession(errorMessage: 'NDEF desteklenmiyor');
            if (!mounted) return;
            setState(() => _nfcActive = false);
            _showSnack('Bu tag AfetPay transferi içermiyor');
            return;
          }

          final message = await ndef.read();
          final params = NfcService.parseTransferMessage(message);

          if (params == null) {
            await NfcManager.instance.stopSession(errorMessage: 'Geçersiz mesaj');
            if (!mounted) return;
            setState(() => _nfcActive = false);
            _showSnack('Bu tag AfetPay transfer verisi içermiyor');
            return;
          }

          final txId = params['txId']!;
          final amount = double.tryParse(params['amount']!) ?? 0.0;
          final fromId = params['from'] ?? 'Bilinmeyen';
          final note = params['note'] ?? 'NFC ile alındı';

          // Çift işlem koruması
          if (await WalletService.instance.isAlreadyProcessed(txId)) {
            await NfcManager.instance.stopSession();
            if (!mounted) return;
            setState(() => _nfcActive = false);
            _showSnack('Bu transfer zaten işlendi');
            return;
          }

          final oldBalance = await WalletService.instance.loadBalance();
          final newBalance = oldBalance + amount;
          await WalletService.instance.saveBalance(newBalance);
          await WalletService.instance.addTransaction(TransactionRecord(
            id: txId,
            name: fromId,
            amount: amount,
            isSent: false,
            time: DateTime.now(),
            note: note,
          ));
          await WalletService.instance.markProcessed(txId);
          await NfcManager.instance.stopSession();

          if (!mounted) return;
          setState(() => _nfcActive = false);
          _showSuccessDialog(amount);
        } catch (e) {
          await NfcManager.instance.stopSession(errorMessage: 'Okuma hatası');
          if (!mounted) return;
          setState(() => _nfcActive = false);
          _showSnack('NFC okuma hatası: $e');
        }
      },
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
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
              child: const Icon(Icons.check_circle_rounded,
                  color: Colors.green),
            ),
            const SizedBox(width: 12),
            const Text('Başarılı'),
          ],
        ),
        content: Text(
          widget.isSend
              ? '₺${amount.toStringAsFixed(2)} başarıyla gönderildi.\nBakiyenizden düşüldü.'
              : '₺${amount.toStringAsFixed(2)} başarıyla alındı.\nBakiyenize eklendi.',
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
    final qrColor =
        widget.isSend ? const Color(0xFF5C6BC0) : _kSecondary;
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: activeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: activeColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isNfc
                            ? Icons.nfc_rounded
                            : Icons.qr_code_2_rounded,
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

            // Tutar
            if (widget.isSend || _isQr) ...[
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
                    borderSide:
                        BorderSide(color: activeColor, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),
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
            ],

            // NFC bölümü
            if (_isNfc) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kPrimaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 16, color: _kPrimary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.isSend
                            ? 'Butona basın → NFC kart/tag\'e yaklaştırın → Tutar karşıya yazılır'
                            : 'Butona basın → NFC kart/tag\'i okutun → Tutar bakiyenize eklenir',
                        style: const TextStyle(
                            fontSize: 12, color: _kPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
                            opacity: _nfcActive
                                ? (1.0 -
                                        ((_nfcRipple.value - factor).abs() %
                                            1.0))
                                    .clamp(0.0, 0.4)
                                : 0.0,
                            child: Container(
                              width: 100 * factor,
                              height: 100 * factor,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: _kPrimary, width: 1.5),
                              ),
                            ),
                          ),
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: _nfcActive
                                ? _kPrimary
                                : _kPrimary.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.nfc_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _nfcActive
                      ? 'NFC bekleniyor...'
                      : 'Hazır — butona basın',
                  style: TextStyle(
                    fontSize: 12,
                    color: _nfcActive ? _kPrimary : _kOnSurfaceVariant,
                    fontWeight: _nfcActive
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // QR bölümü
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
                        widget.isSend
                            ? 'Tarayıcı Açılıyor...'
                            : 'QR Hazır',
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

            // Ana buton
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _nfcActive
                    ? null
                    : () async {
                        HapticFeedback.mediumImpact();
                        if (_isNfc) {
                          if (widget.isSend) {
                            await _handleNfcSend();
                          } else {
                            await _handleNfcReceive();
                          }
                        } else {
                          Navigator.pop(context);
                        }
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: activeColor,
                  disabledBackgroundColor: activeColor.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isNfc
                          ? Icons.nfc_rounded
                          : Icons.qr_code_scanner_rounded,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _nfcActive
                          ? 'Bekleniyor...'
                          : (_isNfc ? 'NFC ile $label' : 'QR ile $label'),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

            if (_nfcActive) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    NfcManager.instance.stopSession();
                    setState(() => _nfcActive = false);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('İptal Et'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}