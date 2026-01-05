import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../models/user_model.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCurrency = 'ARS';
  UserModel? _recipient;
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _searchUser() async {
    if (_searchController.text.isEmpty) return;

    setState(() {
      _isSearching = true;
      _recipient = null;
    });

    final walletProvider = context.read<WalletProvider>();
    final user = await walletProvider.findUser(_searchController.text.trim());

    setState(() {
      _isSearching = false;
      _recipient = user;
    });

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario no encontrado')),
      );
    }
  }

  Future<void> _handleTransfer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_recipient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Busca un destinatario primero')),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final walletProvider = context.read<WalletProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar transferencia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Destinatario: ${_recipient!.fullName ?? _recipient!.email}'),
            Text('Monto: $_selectedCurrency ${_amountController.text}'),
            if (_descriptionController.text.isNotEmpty)
              Text('Descripcion: ${_descriptionController.text}'),
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

    final success = await walletProvider.transfer(
      fromUserId: authProvider.user!.id,
      toIdentifier: _recipient!.cvu ?? _recipient!.email,
      amount: double.parse(_amountController.text),
      currency: _selectedCurrency,
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transferencia exitosa'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/home');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(walletProvider.error ?? 'Error en la transferencia'),
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
        title: const Text('Transferir'),
      ),
      body: Consumer<WalletProvider>(
        builder: (context, wallet, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Buscar destinatario
                  Text(
                    'Buscar destinatario',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            labelText: 'CVU o Email',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _isSearching ? null : _searchUser,
                        child: _isSearching
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Buscar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Destinatario encontrado
                  if (_recipient != null)
                    Card(
                      color: Colors.green[50],
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        title: Text(_recipient!.fullName ?? 'Sin nombre'),
                        subtitle: Text(_recipient!.email),
                        trailing: const Icon(Icons.check_circle, color: Colors.green),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Moneda
                  Text(
                    'Moneda',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'ARS', label: Text('Pesos')),
                      ButtonSegment(value: 'USD', label: Text('Dolares')),
                    ],
                    selected: {_selectedCurrency},
                    onSelectionChanged: (value) {
                      setState(() {
                        _selectedCurrency = value.first;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Disponible: ${_selectedCurrency == 'ARS' ? NumberFormat.currency(locale: 'es_AR', symbol: '\$').format(wallet.arsWallet?.balance ?? 0) : NumberFormat.currency(locale: 'en_US', symbol: 'US\$').format(wallet.usdWallet?.balance ?? 0)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Monto
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Monto',
                      prefixIcon: const Icon(Icons.attach_money),
                      prefixText: _selectedCurrency == 'ARS' ? '\$ ' : 'US\$ ',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa un monto';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'Monto invalido';
                      }
                      final available = _selectedCurrency == 'ARS'
                          ? wallet.arsWallet?.balance ?? 0
                          : wallet.usdWallet?.balance ?? 0;
                      if (amount > available) {
                        return 'Saldo insuficiente';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Descripcion
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripcion (opcional)',
                      prefixIcon: Icon(Icons.description),
                      border: OutlineInputBorder(),
                    ),
                    maxLength: 100,
                  ),
                  const SizedBox(height: 24),

                  // Boton transferir
                  FilledButton.icon(
                    onPressed: wallet.isLoading ? null : _handleTransfer,
                    icon: wallet.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send),
                    label: const Text('Transferir'),
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
