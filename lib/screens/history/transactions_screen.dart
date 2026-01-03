import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../models/transaction_model.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _arsFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$');
  final _usdFormat = NumberFormat.currency(locale: 'en_US', symbol: 'US\$');
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  String _filterType = 'all';
  String _filterCurrency = 'all';

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final authProvider = context.read<AuthProvider>();
    final walletProvider = context.read<WalletProvider>();

    if (authProvider.user != null) {
      await walletProvider.loadTransactions(authProvider.user!.id);
    }
  }

  List<TransactionModel> _getFilteredTransactions(List<TransactionModel> transactions) {
    return transactions.where((tx) {
      if (_filterType != 'all' && tx.typeString != _filterType) {
        return false;
      }
      if (_filterCurrency != 'all' && tx.currency != _filterCurrency) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Historial'),
      ),
      body: Column(
        children: [
          // Filtros
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _filterType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Todos')),
                      DropdownMenuItem(value: 'transfer', child: Text('Transferencias')),
                      DropdownMenuItem(value: 'convert', child: Text('Conversiones')),
                      DropdownMenuItem(value: 'deposit', child: Text('Depositos')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filterType = value ?? 'all';
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _filterCurrency,
                    decoration: const InputDecoration(
                      labelText: 'Moneda',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Todas')),
                      DropdownMenuItem(value: 'ARS', child: Text('Pesos')),
                      DropdownMenuItem(value: 'USD', child: Text('Dolares')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filterCurrency = value ?? 'all';
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // Lista de transacciones
          Expanded(
            child: Consumer<WalletProvider>(
              builder: (context, wallet, child) {
                if (wallet.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final transactions = _getFilteredTransactions(wallet.transactions);

                if (transactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay transacciones',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadTransactions,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: transactions.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      return _buildTransactionCard(tx);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(TransactionModel tx) {
    IconData icon;
    Color color;

    switch (tx.type) {
      case TransactionType.deposit:
        icon = Icons.arrow_downward;
        color = Colors.green;
      case TransactionType.withdraw:
        icon = Icons.arrow_upward;
        color = Colors.red;
      case TransactionType.convert:
        icon = Icons.swap_horiz;
        color = Colors.orange;
      case TransactionType.transfer:
        icon = Icons.send;
        color = Colors.blue;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withAlpha(25),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.typeLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _dateFormat.format(tx.createdAt),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  if (tx.description != null && tx.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      tx.description!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  tx.currency == 'ARS'
                      ? _arsFormat.format(tx.amount)
                      : _usdFormat.format(tx.amount),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: tx.type == TransactionType.deposit ? Colors.green : null,
                  ),
                ),
                Text(
                  tx.currency,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
