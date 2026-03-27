import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TransactionRecord {
  final String id;
  final String name;
  final double amount;
  final bool isSent;
  final DateTime time;
  final String note;

  const TransactionRecord({
    required this.id,
    required this.name,
    required this.amount,
    required this.isSent,
    required this.time,
    required this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'isSent': isSent,
        'time': time.toIso8601String(),
        'note': note,
      };

  factory TransactionRecord.fromJson(Map<String, dynamic> json) =>
      TransactionRecord(
        id: json['id'] as String,
        name: json['name'] as String,
        amount: (json['amount'] as num).toDouble(),
        isSent: json['isSent'] as bool,
        time: DateTime.parse(json['time'] as String),
        note: json['note'] as String,
      );
}

class WalletService {
  WalletService._();
  static final WalletService instance = WalletService._();

  static const _balanceKey = 'wallet_balance';
  static const _txKey = 'wallet_transactions';
  static const _processedTxKey = 'processed_tx_ids';

  Future<double> loadBalance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_balanceKey) ?? 1250.75;
  }

  Future<void> saveBalance(double balance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_balanceKey, balance);
  }

  Future<List<TransactionRecord>> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_txKey);
    if (raw == null) return _defaultTransactions();
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => TransactionRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveTransactions(List<TransactionRecord> txs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _txKey, jsonEncode(txs.map((e) => e.toJson()).toList()));
  }

  Future<void> addTransaction(TransactionRecord tx) async {
    final txs = await loadTransactions();
    txs.insert(0, tx);
    await saveTransactions(txs);
  }

  Future<bool> isAlreadyProcessed(String txId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_processedTxKey) ?? [];
    return ids.contains(txId);
  }

  Future<void> markProcessed(String txId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_processedTxKey) ?? [];
    ids.add(txId);
    // Sadece son 200 tx ID'yi tut (taşma önlemi)
    if (ids.length > 200) ids.removeAt(0);
    await prefs.setStringList(_processedTxKey, ids);
  }

  List<TransactionRecord> _defaultTransactions() => [
        TransactionRecord(
          id: 'tx001',
          name: 'Fatma K.',
          amount: 150.0,
          isSent: false,
          time: DateTime.now().subtract(const Duration(minutes: 12)),
          note: 'NFC ile alındı',
        ),
        TransactionRecord(
          id: 'tx002',
          name: 'Mehmet A.',
          amount: 75.50,
          isSent: true,
          time: DateTime.now().subtract(const Duration(hours: 1)),
          note: 'Market alışverişi',
        ),
        TransactionRecord(
          id: 'tx003',
          name: 'Zeynep D.',
          amount: 300.0,
          isSent: false,
          time: DateTime.now().subtract(const Duration(hours: 3)),
          note: 'NFC ile alındı',
        ),
        TransactionRecord(
          id: 'tx004',
          name: 'Hasan B.',
          amount: 50.0,
          isSent: true,
          time: DateTime.now().subtract(const Duration(hours: 5)),
          note: 'İlaç',
        ),
      ];
}
