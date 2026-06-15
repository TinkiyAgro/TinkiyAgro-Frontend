import 'package:flutter/material.dart';

class _TransactionItem {
  final String description;
  final double amount;

  const _TransactionItem(this.description, this.amount);
}

class _Transaction {
  final int orderNumber;
  final double total;
  final List<_TransactionItem> items;
  bool isExpanded;

  _Transaction({
    required this.orderNumber,
    required this.total,
    required this.items,
    this.isExpanded = false,
  });
}

class ConsumerTransactionsPage extends StatefulWidget {
  const ConsumerTransactionsPage({super.key});

  @override
  State<ConsumerTransactionsPage> createState() =>
      _ConsumerTransactionsPageState();
}

class _ConsumerTransactionsPageState extends State<ConsumerTransactionsPage> {
  final List<_Transaction> _transactions = [
    _Transaction(
      orderNumber: 3,
      total: 92.45,
      isExpanded: true,
      items: const [
        _TransactionItem('Naranja para jugo × 5 kg', 19.00),
        _TransactionItem('Papa Blanca Yungay × 5 kg', 17.50),
        _TransactionItem('Palta Hass × 5 kg', 25.95),
        _TransactionItem('Piña Golden × 5 kg', 20.00),
        _TransactionItem('Gastos de envío (Sebastian Paredes)', 5.00),
        _TransactionItem('Gastos de envío (María Ccopa)', 5.00),
      ],
    ),
    _Transaction(
      orderNumber: 2,
      total: 92.45,
      items: const [
        _TransactionItem('Naranja para jugo × 5 kg', 19.00),
        _TransactionItem('Papa Blanca Yungay × 5 kg', 17.50),
        _TransactionItem('Palta Hass × 5 kg', 25.95),
        _TransactionItem('Piña Golden × 5 kg', 20.00),
        _TransactionItem('Gastos de envío (Sebastian Paredes)', 5.00),
        _TransactionItem('Gastos de envío (María Ccopa)', 5.00),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: _buildAppBar(context),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _transactions.length,
        itemBuilder: (context, index) =>
            _buildTransactionCard(_transactions[index]),
      ),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          // Expanded items
          if (tx.isExpanded) ...[
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                children: tx.items
                    .map((item) => _buildItemRow(item))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemRow(_TransactionItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Text(
            '- S/. ${item.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
