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
        title: const Text('Billetera JJ'),
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
      floatingActionButton: _buildAdminFab(context),
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
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131A22),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E2A36),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF47E6B1)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hola, ${auth.user!.fullName ?? "Usuario"}',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'CVU: ${auth.user!.cvu ?? "No disponible"}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.white60,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tarjetas de saldo
                  _buildBalanceCard(
                    context,
                    title: 'Pesos Argentinos',
                    balance: wallet.arsWallet?.balance ?? 0,
                    currency: 'ARS',
                    color: const Color(0xFF1F8A70),
                    accent: const Color(0xFF47E6B1),
                    icon: Icons.payments_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildBalanceCard(
                    context,
                    title: 'Dolares',
                    balance: wallet.usdWallet?.balance ?? 0,
                    currency: 'USD',
                    color: const Color(0xFF1F2A36),
                    accent: const Color(0xFF4AC1FF),
                    icon: Icons.attach_money,
                  ),
                  const SizedBox(height: 24),

                  // Cotizacion
                  if (wallet.exchangeRate != null) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF131A22),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _rateTile('Compra', _currencyFormat.format(wallet.exchangeRate!.buyRate), Colors.greenAccent),
                            const Icon(Icons.currency_exchange, size: 28, color: Colors.white70),
                            _rateTile('Venta', _currencyFormat.format(wallet.exchangeRate!.sellRate), Colors.redAccent),
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
                          icon: Icons.send_rounded,
                          label: 'Transferir',
                          color: const Color(0xFF47E6B1),
                          onTap: () => context.go('/transfer'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          context,
                          icon: Icons.currency_exchange_rounded,
                          label: 'Convertir',
                          color: const Color(0xFF4AC1FF),
                          onTap: () => context.go('/convert'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          context,
                          icon: Icons.qr_code_rounded,
                          label: 'QR',
                          color: const Color(0xFFB388FF),
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
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131A22),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Center(
                        child: Text('No hay transacciones'),
                      ),
                    )
                  else
                    ...wallet.transactions.take(5).map((tx) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF131A22),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: (tx.type == TransactionType.deposit
                                      ? Colors.greenAccent
                                      : Colors.blueAccent)
                                  .withOpacity(0.12),
                              child: Icon(
                                tx.type == TransactionType.deposit
                                    ? Icons.arrow_downward
                                    : tx.type == TransactionType.convert
                                        ? Icons.swap_horiz
                                        : Icons.arrow_upward,
                                color: tx.type == TransactionType.deposit
                                    ? Colors.greenAccent
                                    : Colors.blueAccent,
                              ),
                            ),
                            title: Text(tx.typeLabel),
                            subtitle: Text(
                              DateFormat('dd/MM/yyyy HH:mm').format(tx.createdAt),
                              style: const TextStyle(color: Colors.white60),
                            ),
                            trailing: Text(
                              tx.currency == 'ARS'
                                  ? _currencyFormat.format(tx.amount)
                                  : _usdFormat.format(tx.amount),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: tx.type == TransactionType.deposit
                                    ? Colors.greenAccent
                                    : Colors.white,
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
    required Color accent,
    required IconData icon,
  }) {
    final format = currency == 'ARS' ? _currencyFormat : _usdFormat;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.85),
            const Color(0xFF0F1720),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 36, color: accent),
          ),
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
                const SizedBox(height: 6),
                Text(
                  format.format(balance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF131A22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.14),
              radius: 24,
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rateTile(String title, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildAdminFab(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => context.go('/admin'),
      backgroundColor: const Color(0xFF47E6B1),
      child: const Icon(Icons.attach_money_rounded, color: Colors.black),
    );
  }
}
