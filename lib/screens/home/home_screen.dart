import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../models/transaction_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$');
  final _usdFormat = NumberFormat.currency(locale: 'en_US', symbol: 'US\$');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final walletProvider = context.read<WalletProvider>();

    if (authProvider.user != null) {
      await Future.wait([
        walletProvider.loadWallets(authProvider.user!.id),
        walletProvider.loadExchangeRate(),
        walletProvider.loadTransactions(authProvider.user!.id),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billetera Virtual'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.go('/history'),
            tooltip: 'Historial',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
            tooltip: 'Cerrar sesion',
          ),
        ],
      ),
      body: Consumer2<AuthProvider, WalletProvider>(
        builder: (context, auth, wallet, child) {
          if (auth.user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Saludo
                  Text(
                    'Hola, ${auth.user!.fullName ?? "Usuario"}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'CVU: ${auth.user!.cvu ?? "No disponible"}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 24),

                  // Tarjetas de saldo
                  _buildBalanceCard(
                    context,
                    title: 'Pesos Argentinos',
                    balance: wallet.arsWallet?.balance ?? 0,
                    currency: 'ARS',
                    color: Colors.blue,
                    icon: Icons.attach_money,
                  ),
                  const SizedBox(height: 16),
                  _buildBalanceCard(
                    context,
                    title: 'Dolares',
                    balance: wallet.usdWallet?.balance ?? 0,
                    currency: 'USD',
                    color: Colors.green,
                    icon: Icons.currency_exchange,
                  ),
                  const SizedBox(height: 24),

                  // Cotizacion
                  if (wallet.exchangeRate != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Text('Compra'),
                                Text(
                                  _currencyFormat.format(wallet.exchangeRate!.buyRate),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(Icons.currency_exchange, size: 32),
                            Column(
                              children: [
                                const Text('Venta'),
                                Text(
                                  _currencyFormat.format(wallet.exchangeRate!.sellRate),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Acciones rapidas
                  Text(
                    'Acciones',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          context,
                          icon: Icons.send,
                          label: 'Transferir',
                          color: Colors.blue,
                          onTap: () => context.go('/transfer'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          context,
                          icon: Icons.currency_exchange,
                          label: 'Convertir',
                          color: Colors.orange,
                          onTap: () => context.go('/convert'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          context,
                          icon: Icons.qr_code,
                          label: 'QR',
                          color: Colors.purple,
                          onTap: () => context.go('/qr'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Ultimas transacciones
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ultimas transacciones',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      TextButton(
                        onPressed: () => context.go('/history'),
                        child: const Text('Ver todas'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (wallet.transactions.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text('No hay transacciones'),
                        ),
                      ),
                    )
                  else
                    ...wallet.transactions.take(5).map((tx) => Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: tx.type == TransactionType.deposit
                                  ? Colors.green[100]
                                  : Colors.blue[100],
                              child: Icon(
                                tx.type == TransactionType.deposit
                                    ? Icons.arrow_downward
                                    : tx.type == TransactionType.convert
                                        ? Icons.swap_horiz
                                        : Icons.arrow_upward,
                                color: tx.type == TransactionType.deposit
                                    ? Colors.green
                                    : Colors.blue,
                              ),
                            ),
                            title: Text(tx.typeLabel),
                            subtitle: Text(
                              DateFormat('dd/MM/yyyy HH:mm').format(tx.createdAt),
                            ),
                            trailing: Text(
                              tx.currency == 'ARS'
                                  ? _currencyFormat.format(tx.amount)
                                  : _usdFormat.format(tx.amount),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: tx.type == TransactionType.deposit
                                    ? Colors.green
                                    : null,
                              ),
                            ),
                          ),
                        )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(
    BuildContext context, {
    required String title,
    required double balance,
    required String currency,
    required Color color,
    required IconData icon,
  }) {
    final format = currency == 'ARS' ? _currencyFormat : _usdFormat;

    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, size: 48, color: Colors.white),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    format.format(balance),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
