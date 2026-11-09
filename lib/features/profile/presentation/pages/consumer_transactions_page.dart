import 'package:flutter/material.dart';
import 'package:tinkiyagro_app/features/profile/data/remote/profile_service.dart';

class _TransactionItem {
  final String description;
  final double amount;

  const _TransactionItem(this.description, this.amount);
}

class _Transaction {
  final String orderId;
  final int orderNumber;
  final DateTime? createdAt;
  final String status;
  final double total;
  final List<_TransactionItem> items;
  bool isExpanded = false;

  _Transaction({
    required this.orderId,
    required this.orderNumber,
    required this.createdAt,
    required this.status,
    required this.total,
    required this.items,
  });

  factory _Transaction.fromJson(Map<String, dynamic> json) {
    final orderNum = _parseInt(json['orderNumber'] ?? json['id']);
    final total = _parseDouble(
      json['total'] ?? json['totalAmount'] ?? json['amount'],
    );
    final productsTotal = _parseDouble(json['productsTotal']);
    final deliveryTotal = _parseDouble(json['deliveryTotal']);

    final items = <_TransactionItem>[];
    if (productsTotal > 0)
      items.add(_TransactionItem('Subtotal productos', productsTotal));
    if (deliveryTotal > 0)
      items.add(_TransactionItem('Gastos de envío', deliveryTotal));

    return _Transaction(
      orderId: json['orderId']?.toString() ?? json['id']?.toString() ?? '',
      orderNumber: orderNum,
      createdAt: DateTime.tryParse(
        json['createdAt']?.toString() ?? '',
      )?.toLocal(),
      status: _statusLabel(json['status']?.toString() ?? ''),
      total: total,
      items: items,
    );
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static String _statusLabel(String value) {
    return switch (value.toUpperCase()) {
      'DELIVERED' => 'Entregado',
      'CONFIRMED' => 'Confirmado',
      'IN_PROGRESS' => 'En proceso',
      _ => value.isEmpty ? 'Sin estado' : value,
    };
  }
}

class ConsumerTransactionsPage extends StatefulWidget {
  const ConsumerTransactionsPage({super.key});

  @override
  State<ConsumerTransactionsPage> createState() =>
      _ConsumerTransactionsPageState();
}

class _ConsumerTransactionsPageState extends State<ConsumerTransactionsPage> {
  final _service = ProfileService();
  List<_Transaction> _transactions = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final data = await _service.obtenerTransacciones();
      if (mounted) {
        setState(() {
          _transactions = data.map(_Transaction.fromJson).toList();
          if (_transactions.isNotEmpty) _transactions.first.isExpanded = true;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: _buildAppBar(context),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Transacciones',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Colors.grey.shade200),
      ),
    );
  }

  Widget _buildBody() {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF5CA399)),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.grey.shade400, size: 48),
            const SizedBox(height: 12),
            Text(
              'No se pudieron cargar las transacciones',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargar,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5CA399),
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin transacciones aún',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: const Color(0xFF5CA399),
      onRefresh: _cargar,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _transactions.length,
        itemBuilder: (context, index) =>
            _buildTransactionCard(_transactions[index]),
      ),
    );
  }

  Widget _buildTransactionCard(_Transaction tx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Text(
                  'Pedido #${tx.orderNumber}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const Spacer(),
                Text(
                  '- S/. ${tx.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => setState(() => tx.isExpanded = !tx.isExpanded),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF5CA399),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      tx.isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: const Color(0xFF5CA399),
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_formatDate(tx.createdAt)} • ${tx.status}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
                Text(
                  'Ref. ${tx.orderId.isEmpty ? tx.orderNumber : (tx.orderId.length > 8 ? tx.orderId.substring(0, 8) : tx.orderId)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          if (tx.isExpanded && tx.items.isNotEmpty) ...[
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(children: tx.items.map(_buildItemRow).toList()),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'Fecha no disponible';
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year} ${two(value.hour)}:${two(value.minute)}';
  }

  Widget _buildItemRow(_TransactionItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.description,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          Text(
            '- S/. ${item.amount.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}
