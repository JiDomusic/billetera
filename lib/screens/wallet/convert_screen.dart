import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';

class ConvertScreen extends StatefulWidget {
  const ConvertScreen({super.key});

  @override
  State<ConvertScreen> createState() => _ConvertScreenState();
}

class _ConvertScreenState extends State<ConvertScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  String _fromCurrency = 'ARS';
  String _toCurrency = 'USD';

  final _arsFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$');
  final _usdFormat = NumberFormat.currency(locale: 'en_US', symbol: 'US\$');

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _swapCurrencies() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
    });
  }

  double _calculateConversion(WalletProvider wallet) {
    if (_amountController.text.isEmpty) return 0;
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (wallet.exchangeRate == null) return 0;

    if (_fromCurrency == 'ARS' && _toCurrency == 'USD') {
      return amount / wallet.exchangeRate!.sellRate;
    } else {
      return amount * wallet.exchangeRate!.buyRate;
    }
  }

  Future<void> _handleConvert() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final walletProvider = context.read<WalletProvider>();

    final amount = double.parse(_amountController.text);
    final converted = _calculateConversion(walletProvider);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar conversion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Cambias: ${_fromCurrency == 'ARS' ? _arsFormat.format(amount) : _usdFormat.format(amount)}',
            ),
            const Icon(Icons.arrow_downward, size: 32),
            Text(
              'Recibes: ${_toCurrency == 'ARS' ? _arsFormat.format(converted) : _usdFormat.format(converted)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await walletProvider.convert(
      userId: authProvider.user!.id,
      amount: amount,
      fromCurrency: _fromCurrency,
      toCurrency: _toCurrency,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conversion exitosa'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/home');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(walletProvider.error ?? 'Error en la conversion'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Convertir'),
      ),
      body: Consumer<WalletProvider>(
        builder: (context, wallet, child) {
          final converted = _calculateConversion(wallet);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cotizacion actual
                  if (wallet.exchangeRate != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text('Cotizacion actual'),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    const Text('Compra'),
                                    Text(
                                      _arsFormat.format(wallet.exchangeRate!.buyRate),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    const Text('Venta'),
                                    Text(
                                      _arsFormat.format(wallet.exchangeRate!.sellRate),
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
                          ],
                        ),
                      ),
                    )
                  else
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Cotizacion no disponible',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Desde
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Desde: $_fromCurrency',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                'Disponible: ${_fromCurrency == 'ARS' ? _arsFormat.format(wallet.arsWallet?.balance ?? 0) : _usdFormat.format(wallet.usdWallet?.balance ?? 0)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              prefixText: _fromCurrency == 'ARS' ? '\$ ' : 'US\$ ',
                              border: const OutlineInputBorder(),
                              hintText: '0.00',
                            ),
                            onChanged: (value) => setState(() {}),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingresa un monto';
                              }
                              final amount = double.tryParse(value);
                              if (amount == null || amount <= 0) {
                                return 'Monto invalido';
                              }
                              final available = _fromCurrency == 'ARS'
                                  ? wallet.arsWallet?.balance ?? 0
                                  : wallet.usdWallet?.balance ?? 0;
                              if (amount > available) {
                                return 'Saldo insuficiente';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Boton swap
                  Center(
                    child: IconButton.filled(
                      onPressed: _swapCurrencies,
                      icon: const Icon(Icons.swap_vert),
                      iconSize: 32,
                    ),
                  ),

                  // Hacia
                  Card(
                    color: Colors.grey[100],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hacia: $_toCurrency',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _toCurrency == 'ARS'
                                ? _arsFormat.format(converted)
                                : _usdFormat.format(converted),
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Boton convertir
                  FilledButton.icon(
                    onPressed: wallet.isLoading || wallet.exchangeRate == null
                        ? null
                        : _handleConvert,
                    icon: wallet.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.currency_exchange),
                    label: const Text('Convertir'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
