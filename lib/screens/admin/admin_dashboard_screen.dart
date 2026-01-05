import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/admin_service.dart';
import '../../services/exchange_rate_service.dart';
import '../../services/wallet_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _adminService = AdminService();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Admin'),
        backgroundColor: const Color(0xFF00D4AA),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _adminService.signOut();
              if (mounted) {
                context.go('/admin');
              }
            },
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.arrow_downward),
                label: Text('Depositos'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.arrow_upward),
                label: Text('Retiros'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people),
                label: Text('Usuarios'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.currency_exchange),
                label: Text('Cotizacion'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text('Config'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return const _PendingDepositsView();
      case 1:
        return const _PendingWithdrawalsView();
      case 2:
        return const _UsersView();
      case 3:
        return const _ExchangeRateView();
      case 4:
        return const _AppConfigView();
      default:
        return const SizedBox();
    }
  }
}

class _PendingDepositsView extends StatefulWidget {
  const _PendingDepositsView();

  @override
  State<_PendingDepositsView> createState() => _PendingDepositsViewState();
}

class _PendingDepositsViewState extends State<_PendingDepositsView> {
  final _adminService = AdminService();
  List<Map<String, dynamic>> _deposits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeposits();
  }

  Future<void> _loadDeposits() async {
    setState(() => _isLoading = true);
    try {
      final deposits = await _adminService.getPendingDeposits();
      setState(() => _deposits = deposits);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_deposits.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('No hay depositos pendientes'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDeposits,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _deposits.length,
        itemBuilder: (context, index) {
          final deposit = _deposits[index];
          final user = deposit['users'] as Map<String, dynamic>?;
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange,
                child: Text(deposit['currency'] ?? ''),
              ),
              title: Text(user?['full_name'] ?? 'Usuario'),
              subtitle: Text(
                '\$${deposit['amount']} ${deposit['currency']}\n${user?['email'] ?? ''}',
              ),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () async {
                      await _adminService.approveDeposit(
                        deposit['id'],
                        deposit['user_id'],
                        (deposit['amount'] as num).toDouble(),
                        deposit['currency'],
                      );
                      _loadDeposits();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () async {
                      await _adminService.rejectDeposit(deposit['id'], null);
                      _loadDeposits();
                    },
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

class _PendingWithdrawalsView extends StatefulWidget {
  const _PendingWithdrawalsView();

  @override
  State<_PendingWithdrawalsView> createState() => _PendingWithdrawalsViewState();
}

class _PendingWithdrawalsViewState extends State<_PendingWithdrawalsView> {
  final _adminService = AdminService();
  List<Map<String, dynamic>> _withdrawals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWithdrawals();
  }

  Future<void> _loadWithdrawals() async {
    setState(() => _isLoading = true);
    try {
      final withdrawals = await _adminService.getPendingWithdrawals();
      setState(() => _withdrawals = withdrawals);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_withdrawals.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('No hay retiros pendientes'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadWithdrawals,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _withdrawals.length,
        itemBuilder: (context, index) {
          final withdrawal = _withdrawals[index];
          final user = withdrawal['users'] as Map<String, dynamic>?;
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.red,
                child: Text(withdrawal['currency'] ?? ''),
              ),
              title: Text(user?['full_name'] ?? 'Usuario'),
              subtitle: Text(
                '\$${withdrawal['amount']} ${withdrawal['currency']}\n'
                '${user?['email'] ?? ''}\n'
                'CBU: ${withdrawal['destination_cbu'] ?? 'N/A'}',
              ),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () async {
                      try {
                        await _adminService.approveWithdrawal(
                          withdrawal['id'],
                          withdrawal['user_id'],
                          (withdrawal['amount'] as num).toDouble(),
                          withdrawal['currency'],
                        );
                        _loadWithdrawals();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Retiro aprobado')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () async {
                      await _adminService.rejectWithdrawal(withdrawal['id'], null);
                      _loadWithdrawals();
                    },
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

class _UsersView extends StatefulWidget {
  const _UsersView();

  @override
  State<_UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<_UsersView> {
  final _adminService = AdminService();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _adminService.getAllUsers();
      setState(() => _users = users);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddBalanceDialog(Map<String, dynamic> user) {
    final amountController = TextEditingController();
    String currency = 'ARS';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Agregar saldo a ${user['full_name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monto',
                prefixText: '\$ ',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: currency,
              items: const [
                DropdownMenuItem(value: 'ARS', child: Text('ARS')),
                DropdownMenuItem(value: 'USD', child: Text('USD')),
              ],
              onChanged: (value) => currency = value ?? 'ARS',
              decoration: const InputDecoration(labelText: 'Moneda'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                await _adminService.addBalance(user['id'], amount, currency);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Saldo agregado')),
                  );
                }
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Text(
                  (user['full_name'] as String?)?.substring(0, 1).toUpperCase() ?? '?',
                ),
              ),
              title: Text(user['full_name'] ?? 'Sin nombre'),
              subtitle: Text('${user['email']}\nCVU: ${user['cvu'] ?? 'N/A'}'),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.green),
                onPressed: () => _showAddBalanceDialog(user),
                tooltip: 'Agregar saldo',
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ExchangeRateView extends StatefulWidget {
  const _ExchangeRateView();

  @override
  State<_ExchangeRateView> createState() => _ExchangeRateViewState();
}

class _ExchangeRateViewState extends State<_ExchangeRateView> {
  final _adminService = AdminService();
  final _exchangeRateService = ExchangeRateService();
  final _buyController = TextEditingController();
  final _sellController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isFetchingMep = false;
  bool _hasAutoUpdated = false;

  @override
  void initState() {
    super.initState();
    _loadRate();
  }

  @override
  void dispose() {
    _buyController.dispose();
    _sellController.dispose();
    super.dispose();
  }

  Future<void> _loadRate() async {
    setState(() => _isLoading = true);
    try {
      final rate = await _adminService.getExchangeRate();
      if (rate != null) {
        _buyController.text = rate['buy_rate'].toString();
        _sellController.text = rate['sell_rate'].toString();
      }
      // Al abrir, intenta actualizar MEP una vez para mantener fresco el valor diario.
      _autoUpdateMepOnce();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveRate({bool silent = false}) async {
    final buyRate = double.tryParse(_buyController.text);
    final sellRate = double.tryParse(_sellController.text);

    if (buyRate == null || sellRate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valores invalidos')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _adminService.updateExchangeRate(buyRate, sellRate);
      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cotizacion actualizada')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _fetchMep({bool save = false, bool silent = false}) async {
    setState(() => _isFetchingMep = true);
    try {
      final mep = await _exchangeRateService.fetchMepRate();
      _buyController.text = mep['buy']!.toStringAsFixed(2);
      _sellController.text = mep['sell']!.toStringAsFixed(2);
      if (save) {
        await _saveRate(silent: silent);
      }
      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cotizacion MEP actualizada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo obtener MEP: $e')),
        );
      }
    } finally {
      setState(() => _isFetchingMep = false);
    }
  }

  void _autoUpdateMepOnce() {
    if (_hasAutoUpdated) return;
    _hasAutoUpdated = true;
    // Busca MEP y guarda silenciosamente en Supabase para que usuarios vean el valor del día.
    _fetchMep(save: true, silent: true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Cotizacion USD',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _buyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Precio de compra (ARS)',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
                helperText: 'Precio al que compras USD',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _sellController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Precio de venta (ARS)',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
                helperText: 'Precio al que vendes USD',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isFetchingMep ? null : _fetchMep,
              icon: _isFetchingMep
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.currency_exchange),
              label: const Text('Tomar MEP (dolarapi.com)'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _isSaving ? null : _saveRate,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF00D4AA),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Guardar Cotizacion'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppConfigView extends StatefulWidget {
  const _AppConfigView();

  @override
  State<_AppConfigView> createState() => _AppConfigViewState();
}

class _AppConfigViewState extends State<_AppConfigView> {
  final _walletService = WalletService();
  final _aliasController = TextEditingController();
  final _bankController = TextEditingController();
  final _currencyController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _aliasController.dispose();
    _bankController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);
    try {
      final config = await _walletService.getAppConfig();
      _aliasController.text = config['deposit_alias'] ?? '';
      _bankController.text = config['deposit_bank'] ?? '';
      _currencyController.text = config['deposit_currency'] ?? '';
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveConfig() async {
    setState(() => _isSaving = true);
    try {
      await _walletService.updateAppConfig('deposit_alias', _aliasController.text.trim());
      await _walletService.updateAppConfig('deposit_bank', _bankController.text.trim());
      await _walletService.updateAppConfig('deposit_currency', _currencyController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuracion guardada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Datos para depositos',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Los usuarios veran estos datos cuando quieran depositar dinero.',
              style: TextStyle(color: Colors.white60),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _aliasController,
              decoration: const InputDecoration(
                labelText: 'Alias bancario',
                hintText: 'ej: mi.cuenta.banco',
                prefixIcon: Icon(Icons.account_balance),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bankController,
              decoration: const InputDecoration(
                labelText: 'Nombre del banco',
                hintText: 'ej: Banco Galicia',
                prefixIcon: Icon(Icons.business),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _currencyController,
              decoration: const InputDecoration(
                labelText: 'Tipo de cuenta',
                hintText: 'ej: Pesos ARS',
                prefixIcon: Icon(Icons.monetization_on),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _saveConfig,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF00D4AA),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Guardar Configuracion'),
            ),
          ],
        ),
      ),
    );
  }
}
