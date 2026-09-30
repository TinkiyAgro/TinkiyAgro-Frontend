import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tinkiyagro_app/features/catalog/data/product_model.dart';
import 'package:tinkiyagro_app/features/orders/presentation/pages/consumer_orders_page.dart';
import 'package:tinkiyagro_app/features/organization/data/organization_service.dart';
import 'package:tinkiyagro_app/features/wholesale/data/wholesale_service.dart';

const _brand = Color(0xFF5CA8A0),
    _ink = Color(0xFF132823),
    _bg = Color(0xFFF6F9F8);

class WholesaleProductCard extends StatelessWidget {
  const WholesaleProductCard({
    super.key,
    required this.product,
    this.compact = false,
  });
  final Map<String, dynamic> product;
  final bool compact;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WholesaleQuoteRequestPage(initialProduct: product),
      ),
    ),
    borderRadius: BorderRadius.circular(14),
    child: Container(
      width: compact ? 225 : double.infinity,
      margin: const EdgeInsets.only(right: 12, bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDDE6E3)),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 112,
            width: double.infinity,
            child: _NetworkImage(product['imageUrl']),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product['organizationName'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF65736F)),
                ),
                const SizedBox(height: 8),
                Text(
                  'S/ ${product['referencePrice']} / ${product['unit']}',
                  style: const TextStyle(
                    color: _brand,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${(product['distanceKm'] as num?)?.toStringAsFixed(1) ?? '-'} km · Stock ${product['stock']} ${product['unit']}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF65736F),
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

class WholesaleCatalogPage extends StatefulWidget {
  const WholesaleCatalogPage({super.key});
  @override
  State<WholesaleCatalogPage> createState() => _WholesaleCatalogPageState();
}

class _WholesaleCatalogPageState extends State<WholesaleCatalogPage> {
  late Future<List<Map<String, dynamic>>> _future = WholesaleService()
      .products();
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _bg,
    appBar: AppBar(title: const Text('Al por mayor'), backgroundColor: _bg),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, s) {
        if (s.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator());
        if (s.hasError)
          return _Error(
            message: '${s.error}',
            retry: () =>
                setState(() => _future = WholesaleService().products()),
          );
        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Text(
              'Productos de organizaciones dentro de tu radio',
              style: TextStyle(color: Color(0xFF65736F)),
            ),
            const SizedBox(height: 16),
            ...(s.data ?? []).map((p) => WholesaleProductCard(product: p)),
          ],
        );
      },
    ),
  );
}

class WholesaleQuoteRequestPage extends StatefulWidget {
  const WholesaleQuoteRequestPage({super.key, required this.initialProduct});
  final Map<String, dynamic> initialProduct;
  @override
  State<WholesaleQuoteRequestPage> createState() =>
      _WholesaleQuoteRequestPageState();
}

class _WholesaleQuoteRequestPageState extends State<WholesaleQuoteRequestPage> {
  final _delivery = TextEditingController(),
      _days = TextEditingController(),
      _notes = TextEditingController();
  final List<Map<String, dynamic>> _selected = [];
  final Map<String, TextEditingController> _quantities = {};
  List<Map<String, dynamic>> _available = [];
  bool _saving = false;
  bool _loadingProducts = true;
  @override
  void initState() {
    super.initState();
    _addProduct(widget.initialProduct);
    WholesaleService()
        .products()
        .then((products) {
          if (mounted) {
            setState(() {
              _available = products
                  .where(
                    (product) =>
                        product['organizationId'] ==
                        widget.initialProduct['organizationId'],
                  )
                  .toList();
              _loadingProducts = false;
            });
          }
        })
        .catchError((_) {
          if (mounted) setState(() => _loadingProducts = false);
        });
  }

  void _addProduct(Map<String, dynamic> product) {
    if (_selected.any((item) => item['id'] == product['id'])) return;
    _selected.add(product);
    _quantities[product['id'].toString()] = TextEditingController();
  }

  @override
  void dispose() {
    _delivery.dispose();
    _days.dispose();
    _notes.dispose();
    for (final controller in _quantities.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.initialProduct;
    return _Screen(
      title: 'Solicitar cotización',
      children: [
        Text(
          '${p['organizationName']} · ${p['region']}',
          style: const TextStyle(color: _brand, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),
        _Notice(
          title: 'Compra mayorista',
          text:
              'La organización revisará cantidades, precios y condiciones antes de que decidas aceptar.',
        ),
        const SizedBox(height: 14),
        ..._selected.map(
          (product) => _ProductLine(
            product: product,
            trailing: SizedBox(
              width: 118,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _quantities[product['id'].toString()],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _input('${product['unit']}'),
                    ),
                  ),
                  if (_selected.length > 1)
                    IconButton(
                      tooltip: 'Quitar producto',
                      onPressed: () => setState(() {
                        final removed = _quantities.remove(
                          product['id'].toString(),
                        );
                        removed?.dispose();
                        _selected.removeWhere(
                          (item) => item['id'] == product['id'],
                        );
                      }),
                      icon: const Icon(Icons.close, size: 18),
                    ),
                ],
              ),
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: _loadingProducts ? null : _chooseProduct,
          icon: const Icon(Icons.add),
          label: const Text('Agregar otro producto'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _delivery,
          decoration: _input('Lugar de entrega'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _days,
          keyboardType: TextInputType.number,
          decoration: _input('Plazo deseado en días (opcional)'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notes,
          maxLines: 3,
          decoration: _input('Condiciones u observaciones (opcional)'),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _saving ? null : _send,
          style: _primary,
          child: _saving
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Enviar solicitud'),
        ),
      ],
    );
  }

  Future<void> _send() async {
    final items = <Map<String, dynamic>>[];
    for (final product in _selected) {
      final quantity = double.tryParse(
        (_quantities[product['id'].toString()]?.text ?? '').replaceAll(
          ',',
          '.',
        ),
      );
      if (quantity == null || quantity <= 0) {
        _message('Completa una cantidad válida para ${product['name']}');
        return;
      }
      items.add({'productId': product['id'], 'quantity': quantity});
    }
    if (_delivery.text.trim().isEmpty) {
      _message('Completa el lugar de entrega');
      return;
    }
    setState(() => _saving = true);
    try {
      final quote = await WholesaleService().requestQuote({
        'organizationId': widget.initialProduct['organizationId'],
        'items': items,
        'deliveryLocation': _delivery.text.trim(),
        'requestedDeliveryDays': int.tryParse(_days.text),
        'notes': _notes.text.trim(),
      });
      if (mounted)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ConsumerQuoteDetailPage(quoteId: quote['id']),
          ),
        );
    } catch (e) {
      _message('$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _chooseProduct() async {
    final options = _available
        .where(
          (product) =>
              !_selected.any((selected) => selected['id'] == product['id']),
        )
        .toList();
    if (options.isEmpty) {
      _message(
        'Ya agregaste todos los productos disponibles de esta organización',
      );
      return;
    }
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          children: [
            const Text(
              'Agregar producto',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...options.map(
              (product) => ListTile(
                leading: SizedBox(
                  width: 52,
                  height: 52,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _NetworkImage(product['imageUrl']),
                  ),
                ),
                title: Text(product['name'] ?? ''),
                subtitle: Text('Stock ${product['stock']} ${product['unit']}'),
                onTap: () => Navigator.pop(context, product),
              ),
            ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) setState(() => _addProduct(selected));
  }

  void _message(String text) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(text.replaceFirst('Exception: ', ''))));
}

class ConsumerActivityPage extends StatelessWidget {
  const ConsumerActivityPage({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        title: const Text('Actividad'),
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Pedidos'),
            Tab(text: 'Cotizaciones'),
          ],
        ),
      ),
      body: const TabBarView(
        children: [ConsumerOrdersPage(), ConsumerQuotesPage()],
      ),
    ),
  );
}

class ConsumerQuotesPage extends StatefulWidget {
  const ConsumerQuotesPage({super.key});
  @override
  State<ConsumerQuotesPage> createState() => _ConsumerQuotesPageState();
}

class _ConsumerQuotesPageState extends State<ConsumerQuotesPage> {
  late Future<List<Map<String, dynamic>>> _future = WholesaleService().quotes();
  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, s) {
          if (s.connectionState != ConnectionState.done)
            return const Center(child: CircularProgressIndicator());
          if (s.hasError)
            return _Error(
              message: '${s.error}',
              retry: () =>
                  setState(() => _future = WholesaleService().quotes()),
            );
          final data = s.data ?? [];
          if (data.isEmpty)
            return const Center(child: Text('Aún no tienes cotizaciones'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: data
                .map(
                  (q) => _QuoteTile(
                    q: q,
                    onTap: () =>
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ConsumerQuoteDetailPage(quoteId: q['id']),
                          ),
                        ).then((_) {
                          if (mounted)
                            setState(
                              () => _future = WholesaleService().quotes(),
                            );
                        }),
                  ),
                )
                .toList(),
          );
        },
      );
}

class ConsumerQuoteDetailPage extends StatefulWidget {
  const ConsumerQuoteDetailPage({super.key, required this.quoteId});
  final String quoteId;
  @override
  State<ConsumerQuoteDetailPage> createState() =>
      _ConsumerQuoteDetailPageState();
}

class _ConsumerQuoteDetailPageState extends State<ConsumerQuoteDetailPage> {
  late Future<Map<String, dynamic>> _future = WholesaleService().quote(
    widget.quoteId,
  );
  bool _busy = false;
  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: _future,
    builder: (context, s) {
      if (!s.hasData)
        return Scaffold(
          backgroundColor: _bg,
          body: Center(
            child: s.hasError
                ? Text('${s.error}')
                : const CircularProgressIndicator(),
          ),
        );
      final q = s.data!, quoted = q['status'] == 'COTIZADA';
      return _Screen(
        title: 'Revisar cotización',
        children: [
          _DarkHeader(
            title: 'Solicitud #${q['quoteNumber']}',
            subtitle: _status(q['status']),
          ),
          const SizedBox(height: 14),
          Text(
            q['organizationName'] ?? '',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            '${q['region']} · ${q['zone']}',
            style: const TextStyle(color: Color(0xFF65736F)),
          ),
          const SizedBox(height: 18),
          const Text(
            'Detalle propuesto',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...(q['items'] as List).map(
            (e) => _ProductLine(
              product: (e as Map).cast<String, dynamic>(),
              subtitle: 'Solicitado: ${e['requestedQuantity']} ${e['unit']}',
              trailing: Text(
                e['offeredUnitPrice'] == null
                    ? 'Pendiente'
                    : 'S/ ${e['offeredUnitPrice']}/${e['unit']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          if (quoted) ...[
            const SizedBox(height: 10),
            _Summary(
              rows: {
                'Preparación': '${q['preparationDays'] ?? '-'} días',
                'Entrega': '${q['deliveryDays'] ?? '-'} días',
                'Origen de despacho': q['dispatchOrigin'] ?? '-',
                'Costo de entrega': 'S/ ${q['deliveryCost'] ?? 0}',
                'Total': 'S/ ${q['total'] ?? 0}',
              },
            ),
            if ((q['organizationNotes'] ?? '').toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _Notice(
                  title: 'Condiciones',
                  text: q['organizationNotes'],
                ),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : () => _accept(q),
              style: _primary,
              child: const Text('Aceptar cotización'),
            ),
            TextButton(
              onPressed: _busy ? _noop : _reject,
              child: const Text('Rechazar cotización'),
            ),
          ] else if (q['status'] == 'ACEPTADA') ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                final order = await WholesaleService().orderByQuote(
                  widget.quoteId,
                );
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          WholesaleOrderPage(order: order, quote: q),
                    ),
                  );
                }
              },
              style: _primary,
              child: const Text('Ver orden formal'),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 18),
              child: _Notice(
                title: 'Solicitud enviada',
                text:
                    'La organización está revisando cantidades y condiciones. Aquí verás su propuesta cuando esté lista.',
              ),
            ),
        ],
      );
    },
  );
  void _noop() {}
  Future<void> _reject() async {
    setState(() => _busy = true);
    try {
      await WholesaleService().rejectQuote(widget.quoteId);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _accept(Map<String, dynamic> q) async {
    setState(() => _busy = true);
    try {
      final order = await WholesaleService().acceptQuote(widget.quoteId);
      if (mounted)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => WholesaleOrderPage(order: order, quote: q),
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class WholesaleOrderPage extends StatelessWidget {
  const WholesaleOrderPage({super.key, required this.order, this.quote});
  final Map<String, dynamic> order;
  final Map<String, dynamic>? quote;
  @override
  Widget build(BuildContext context) => _Screen(
    title: 'Orden formal',
    children: [
      _Notice(
        title: 'Orden #${order['orderNumber']}',
        text:
            'Cotización aceptada. El pago y los acuerdos finales se realizan fuera de la aplicación.',
      ),
      const SizedBox(height: 16),
      Text(
        order['organizationName'] ?? '',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 14),
      _Summary(
        rows: {
          'Estado': _status(order['status']),
          'Origen': order['dispatchOrigin'] ?? '-',
          'Lugar de entrega': order['deliveryLocation'] ?? '-',
          'Preparación': '${order['preparationDays'] ?? '-'} días',
          'Entrega': '${order['deliveryDays'] ?? '-'} días',
          'Total referencial': 'S/ ${order['total'] ?? 0}',
        },
      ),
      const SizedBox(height: 14),
      _Notice(
        title: 'Contacta a la organización',
        text: order['organizationPhone'] ?? 'Sin número registrado',
      ),
      OutlinedButton.icon(
        onPressed: () {
          Clipboard.setData(
            ClipboardData(text: order['organizationPhone'] ?? ''),
          );
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Número copiado')));
        },
        icon: const Icon(Icons.copy),
        label: const Text('Copiar número'),
      ),
      const SizedBox(height: 12),
      FilledButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WholesaleTrackingPage(orderId: order['id']),
          ),
        ),
        style: _primary,
        child: const Text('Ver seguimiento'),
      ),
    ],
  );
}

class OrganizationQuotesPage extends StatelessWidget {
  const OrganizationQuotesPage({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Padding(
            padding: EdgeInsets.fromLTRB(20, 22, 20, 10),
            child: Text(
              'Órdenes',
              style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
            ),
          ),
          TabBar(
            tabs: [
              Tab(text: 'Cotizaciones'),
              Tab(text: 'Órdenes formales'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [_OrganizationQuoteList(), _OrganizationOrderList()],
            ),
          ),
        ],
      ),
    ),
  );
}

class _OrganizationQuoteList extends StatefulWidget {
  const _OrganizationQuoteList();
  @override
  State<_OrganizationQuoteList> createState() => _OrganizationQuoteListState();
}

class _OrganizationQuoteListState extends State<_OrganizationQuoteList> {
  late Future<List<Map<String, dynamic>>> _future = OrganizationService()
      .getQuotes();
  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: snapshot.hasError
                  ? Text('${snapshot.error}')
                  : const CircularProgressIndicator(),
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                setState(() => _future = OrganizationService().getQuotes()),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: (snapshot.data ?? [])
                  .map(
                    (quote) => _QuoteTile(
                      q: quote,
                      statusLabel: _organizationQuoteStatus(quote['status']),
                      onTap: () =>
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  OrganizationQuoteProposalPage(quote: quote),
                            ),
                          ).then((_) {
                            if (mounted)
                              setState(
                                () =>
                                    _future = OrganizationService().getQuotes(),
                              );
                          }),
                    ),
                  )
                  .toList(),
            ),
          );
        },
      );
}

class _OrganizationOrderList extends StatefulWidget {
  const _OrganizationOrderList();
  @override
  State<_OrganizationOrderList> createState() => _OrganizationOrderListState();
}

class _OrganizationOrderListState extends State<_OrganizationOrderList> {
  late Future<List<Map<String, dynamic>>> _future = OrganizationService()
      .getOrders();
  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<List<Map<String, dynamic>>>(
    future: _future,
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return Center(
          child: snapshot.hasError
              ? Text('${snapshot.error}')
              : const CircularProgressIndicator(),
        );
      }
      final orders = snapshot.data ?? [];
      if (orders.isEmpty)
        return const Center(child: Text('Aún no hay órdenes formales'));
      return RefreshIndicator(
        onRefresh: () async =>
            setState(() => _future = OrganizationService().getOrders()),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: orders
              .map(
                (order) => Card(
                  elevation: 0,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(14),
                    title: Text(
                      '#${order['orderNumber']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${_status(order['status'])} · ${order['deliveryLocation']}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrganizationOrderTrackingPage(
                              orderId: order['id'],
                            ),
                          ),
                        ).then((_) {
                          if (mounted)
                            setState(
                              () => _future = OrganizationService().getOrders(),
                            );
                        }),
                  ),
                ),
              )
              .toList(),
        ),
      );
    },
  );
}

class OrganizationQuoteProposalPage extends StatefulWidget {
  const OrganizationQuoteProposalPage({super.key, required this.quote});
  final Map<String, dynamic> quote;
  @override
  State<OrganizationQuoteProposalPage> createState() =>
      _OrganizationQuoteProposalPageState();
}

class _OrganizationQuoteProposalPageState
    extends State<OrganizationQuoteProposalPage> {
  final _prep = TextEditingController(),
      _delivery = TextEditingController(),
      _cost = TextEditingController(text: '0'),
      _origin = TextEditingController(),
      _notes = TextEditingController(),
      _valid = TextEditingController(text: '7');
  late final List<TextEditingController> _qty, _prices;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    final lines = widget.quote['items'] as List;
    _qty = lines
        .map(
          (x) => TextEditingController(
            text: (x['offeredQuantity'] ?? x['requestedQuantity']).toString(),
          ),
        )
        .toList();
    _prices = lines
        .map(
          (x) => TextEditingController(
            text: (x['offeredUnitPrice'] ?? x['referenceUnitPrice']).toString(),
          ),
        )
        .toList();
    _prep.text = widget.quote['preparationDays']?.toString() ?? '';
    _delivery.text = widget.quote['deliveryDays']?.toString() ?? '';
    _cost.text = widget.quote['deliveryCost']?.toString() ?? '0';
    _origin.text = widget.quote['dispatchOrigin']?.toString() ?? '';
    _notes.text = widget.quote['organizationNotes']?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.quote['items'] as List;
    final status = widget.quote['status'];
    final editable = status == 'SOLICITADA' || status == 'EN_REVISION';
    return _Screen(
      title: editable ? 'Preparar cotización' : 'Detalle de cotización',
      children: [
        _DarkHeader(
          title: 'Solicitud #${widget.quote['quoteNumber']}',
          subtitle:
              '${widget.quote['consumerUsername']} · ${_organizationQuoteStatus(status)}',
        ),
        if (!editable) ...[
          const SizedBox(height: 12),
          _Notice(
            title: 'Cotización bloqueada',
            text: status == 'COTIZADA'
                ? 'La propuesta ya fue enviada y está esperando la respuesta del consumidor.'
                : 'Esta cotización ya fue cerrada y no puede modificarse.',
          ),
        ],
        const SizedBox(height: 16),
        ...List.generate(
          lines.length,
          (i) => _ProductLine(
            product: (lines[i] as Map).cast<String, dynamic>(),
            subtitle:
                'Solicitado: ${lines[i]['requestedQuantity']} ${lines[i]['unit']}',
            trailing: SizedBox(
              width: 125,
              child: Column(
                children: [
                  TextField(
                    controller: _qty[i],
                    enabled: editable,
                    keyboardType: TextInputType.number,
                    decoration: _input('Cantidad'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _prices[i],
                    enabled: editable,
                    keyboardType: TextInputType.number,
                    decoration: _input('S/ por ${lines[i]['unit']}'),
                  ),
                ],
              ),
            ),
          ),
        ),
        TextField(
          controller: _origin,
          enabled: editable,
          decoration: _input('Origen real del despacho'),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _prep,
                enabled: editable,
                keyboardType: TextInputType.number,
                decoration: _input('Preparación (días)'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _delivery,
                enabled: editable,
                keyboardType: TextInputType.number,
                decoration: _input('Entrega (días)'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _cost,
          enabled: editable,
          keyboardType: TextInputType.number,
          decoration: _input('Costo de entrega'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _valid,
          enabled: editable,
          keyboardType: TextInputType.number,
          decoration: _input('Validez (días)'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _notes,
          enabled: editable,
          maxLines: 3,
          decoration: _input('Condiciones y observaciones'),
        ),
        const SizedBox(height: 16),
        if (editable)
          FilledButton(
            onPressed: _busy ? null : _save,
            style: _primary,
            child: const Text('Enviar cotización al consumidor'),
          ),
      ],
    );
  }

  Future<void> _save() async {
    if (_origin.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indica el origen del despacho')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final now = DateTime.now();
      await OrganizationService().proposeQuote(widget.quote['id'], {
        'items': List.generate(
          _qty.length,
          (i) => {
            'itemId': widget.quote['items'][i]['id'],
            'quantity': double.parse(_qty[i].text.replaceAll(',', '.')),
            'unitPrice': double.parse(_prices[i].text.replaceAll(',', '.')),
          },
        ),
        'preparationDays': int.parse(_prep.text),
        'deliveryDays': int.parse(_delivery.text),
        'estimatedReadyAt': now
            .add(Duration(days: int.parse(_prep.text)))
            .toUtc()
            .toIso8601String(),
        'validUntil': now
            .add(Duration(days: int.tryParse(_valid.text) ?? 7))
            .toUtc()
            .toIso8601String(),
        'deliveryCost': double.tryParse(_cost.text.replaceAll(',', '.')) ?? 0,
        'notes': _notes.text.trim(),
        'dispatchOrigin': _origin.text.trim(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class WholesaleTrackingPage extends StatefulWidget {
  const WholesaleTrackingPage({super.key, required this.orderId});
  final String orderId;
  @override
  State<WholesaleTrackingPage> createState() => _WholesaleTrackingPageState();
}

class _WholesaleTrackingPageState extends State<WholesaleTrackingPage> {
  late Future<Map<String, dynamic>> _future = WholesaleService().order(
    widget.orderId,
  );
  bool _busy = false;
  void _reload() =>
      setState(() => _future = WholesaleService().order(widget.orderId));
  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: _future,
    builder: (context, s) {
      if (!s.hasData)
        return Scaffold(
          backgroundColor: _bg,
          body: Center(
            child: s.hasError
                ? Text('${s.error}')
                : const CircularProgressIndicator(),
          ),
        );
      final order = s.data!;
      return _Screen(
        title: 'Seguimiento de orden',
        children: [
          _DarkHeader(
            title: 'Orden #${order['orderNumber']}',
            subtitle:
                '${order['organizationName']} → ${order['deliveryLocation']}',
          ),
          const SizedBox(height: 16),
          _OrderTimeline(order: order),
          if (order['dispatchLatitude'] != null) ...[
            const SizedBox(height: 12),
            _Notice(
              title: 'Ubicación de despacho registrada',
              text:
                  '${order['dispatchLatitude']}, ${order['dispatchLongitude']} · precisión ${(order['dispatchAccuracyMeters'] as num?)?.toStringAsFixed(0) ?? '-'} m',
            ),
          ],
          if (order['status'] == 'EN_TRANSITO') ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? _noop : _confirmDelivery,
              style: _primary,
              child: const Text('Confirmar entrega'),
            ),
          ],
          if (order['status'] != 'ENTREGADA') ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _busy ? _noop : _reportIncident,
              child: const Text('Reportar incidencia'),
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'El transporte se coordina fuera de TinkiyAgro. La aplicación registra únicamente la ubicación del despacho y de la entrega.',
            style: TextStyle(color: Color(0xFF65736F), fontSize: 12),
          ),
        ],
      );
    },
  );
  void _noop() {}
  Future<void> _confirmDelivery() async {
    final accepted = await _confirmCompleteDelivery(context);
    if (!accepted) return;
    setState(() => _busy = true);
    try {
      final p = await _currentPosition();
      await WholesaleService().deliverOrder(
        widget.orderId,
        p.latitude,
        p.longitude,
        p.accuracy,
      );
      _reload();
    } catch (e) {
      _show('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reportIncident() async {
    final c = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reportar incidencia'),
        content: TextField(
          controller: c,
          maxLines: 4,
          decoration: _input('Describe lo ocurrido'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, c.text.trim()),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    if (text == null || text.isEmpty) return;
    setState(() => _busy = true);
    try {
      await WholesaleService().reportIncident(widget.orderId, text);
      _reload();
    } catch (e) {
      _show('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _show(String text) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(text.replaceFirst('Exception: ', ''))),
      );
  }
}

class OrganizationOrderTrackingPage extends StatefulWidget {
  const OrganizationOrderTrackingPage({super.key, required this.orderId});
  final String orderId;
  @override
  State<OrganizationOrderTrackingPage> createState() =>
      _OrganizationOrderTrackingPageState();
}

class _OrganizationOrderTrackingPageState
    extends State<OrganizationOrderTrackingPage> {
  late Future<Map<String, dynamic>> _future = OrganizationService().getOrder(
    widget.orderId,
  );
  bool _busy = false;
  void _reload() =>
      setState(() => _future = OrganizationService().getOrder(widget.orderId));
  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: _future,
    builder: (context, s) {
      if (!s.hasData)
        return Scaffold(
          backgroundColor: _bg,
          body: Center(
            child: s.hasError
                ? Text('${s.error}')
                : const CircularProgressIndicator(),
          ),
        );
      final o = s.data!;
      return _Screen(
        title: 'Gestionar orden',
        children: [
          _DarkHeader(
            title: 'Orden #${o['orderNumber']}',
            subtitle: 'Destino: ${o['deliveryLocation']}',
          ),
          const SizedBox(height: 16),
          _OrderTimeline(order: o),
          const SizedBox(height: 14),
          _Summary(
            rows: {
              'Origen declarado': o['dispatchOrigin'] ?? '-',
              'Preparación': '${o['preparationDays'] ?? '-'} días',
              'Entrega': '${o['deliveryDays'] ?? '-'} días',
              'Total': 'S/ ${o['total'] ?? 0}',
            },
          ),
          if (o['incidentNotes'] != null) ...[
            const SizedBox(height: 12),
            _Notice(title: 'Incidencia reportada', text: o['incidentNotes']),
          ],
          const SizedBox(height: 16),
          if (o['status'] == 'CONFIRMADA')
            FilledButton(
              onPressed: _busy
                  ? _noop
                  : () => _simpleAction(
                      'Iniciar preparación',
                      'La orden pasará a En preparación.',
                      () => OrganizationService().prepareOrder(widget.orderId),
                    ),
              style: _primary,
              child: const Text('Iniciar preparación'),
            ),
          if (o['status'] == 'EN_PREPARACION')
            FilledButton(
              onPressed: _busy ? _noop : _dispatch,
              style: _primary,
              child: const Text('Registrar despacho y ubicación'),
            ),
          if (o['status'] == 'DESPACHADA')
            FilledButton(
              onPressed: _busy
                  ? _noop
                  : () => _simpleAction(
                      'Marcar en tránsito',
                      'Confirma que la orden ya se encuentra en tránsito.',
                      () => OrganizationService().transitOrder(widget.orderId),
                    ),
              style: _primary,
              child: const Text('Marcar en tránsito'),
            ),
          if (o['status'] == 'EN_TRANSITO')
            const _Notice(
              title: 'Orden en tránsito',
              text: 'El consumidor confirmará la entrega desde su dispositivo.',
            ),
          if (o['status'] == 'ENTREGADA')
            const _Notice(
              title: 'Entrega completada',
              text: 'El seguimiento ha finalizado.',
            ),
        ],
      );
    },
  );
  void _noop() {}
  Future<void> _simpleAction(
    String title,
    String message,
    Future<Map<String, dynamic>> Function() action,
  ) async {
    if (!await _confirm(context, title, message)) return;
    setState(() => _busy = true);
    try {
      await action();
      _reload();
    } catch (e) {
      _show('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _dispatch() async {
    if (!await _confirm(
      context,
      'Confirmar despacho',
      'Se guardará una sola vez la ubicación actual del dispositivo. Esta acción es irreversible.',
    ))
      return;
    setState(() => _busy = true);
    try {
      final p = await _currentPosition();
      await OrganizationService().dispatchOrder(
        widget.orderId,
        p.latitude,
        p.longitude,
        p.accuracy,
      );
      _reload();
    } catch (e) {
      _show('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _show(String text) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(text.replaceFirst('Exception: ', ''))),
      );
  }
}

class _OrderTimeline extends StatelessWidget {
  const _OrderTimeline({required this.order});
  final Map<String, dynamic> order;
  static const _states = [
    'CONFIRMADA',
    'EN_PREPARACION',
    'DESPACHADA',
    'EN_TRANSITO',
    'ENTREGADA',
  ];
  static const _timestamps = [
    'acceptedAt',
    'preparedAt',
    'dispatchedAt',
    'inTransitAt',
    'deliveredAt',
  ];
  @override
  Widget build(BuildContext context) {
    final current = _states.indexOf(order['status']);
    return Column(
      children: List.generate(_states.length, (i) {
        final done = i <= current;
        final active = i == current;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFDFF1EC) : Colors.white,
            border: Border.all(
              color: active ? _brand : const Color(0xFFDDE6E3),
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                done ? Icons.check_circle : Icons.radio_button_unchecked,
                color: done ? _brand : Colors.grey,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _status(_states[i]),
                  style: TextStyle(
                    fontWeight: active ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
              Text(
                _formatDate(order[_timestamps[i]]),
                style: const TextStyle(fontSize: 12, color: Color(0xFF65736F)),
              ),
            ],
          ),
        );
      }),
    );
  }
}

Future<Position> _currentPosition() async {
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied)
    permission = await Geolocator.requestPermission();
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever)
    throw Exception('Se necesita permiso de ubicación');
  final position = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
  if (position.accuracy > 100)
    throw Exception(
      'La precisión actual es ${position.accuracy.toStringAsFixed(0)} m. Acércate a una ventana o activa GPS e inténtalo nuevamente.',
    );
  return position;
}

Future<bool> _confirm(BuildContext context, String title, String text) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(text),
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
    ) ??
    false;

Future<bool> _confirmCompleteDelivery(BuildContext context) async {
  bool complete = false;
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Confirmar entrega'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Se registrará tu ubicación y esta acción no podrá deshacerse.',
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: complete,
                  onChanged: (value) =>
                      setDialogState(() => complete = value ?? false),
                  title: const Text('Recibí la orden completa'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: complete
                    ? () => Navigator.pop(dialogContext, true)
                    : null,
                child: const Text('Confirmar entrega'),
              ),
            ],
          ),
        ),
      ) ??
      false;
}

String _formatDate(dynamic raw) {
  if (raw == null) return 'Pendiente';
  final d = DateTime.tryParse(raw.toString())?.toLocal();
  if (d == null) return '';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)} ${two(d.hour)}:${two(d.minute)}';
}

class _Screen extends StatelessWidget {
  const _Screen({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _bg,
    appBar: AppBar(
      backgroundColor: _bg,
      title: const Text(
        'TINKIYAGRO',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    ),
  );
}

class _NetworkImage extends StatelessWidget {
  const _NetworkImage(this.raw);
  final dynamic raw;
  @override
  Widget build(BuildContext context) {
    final url = resolveMediaUrl(raw);
    return url.isEmpty
        ? Container(
            color: const Color(0xFFE5EFEC),
            child: const Icon(Icons.eco, size: 42, color: _brand),
          )
        : Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFFE5EFEC),
              child: const Icon(Icons.broken_image_outlined),
            ),
          );
  }
}

class _ProductLine extends StatelessWidget {
  const _ProductLine({required this.product, this.trailing, this.subtitle});
  final Map<String, dynamic> product;
  final Widget? trailing;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFDDE6E3)),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 64,
            height: 64,
            child: _NetworkImage(
              product['productImageUrl'] ?? product['imageUrl'],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product['productName'] ?? product['name'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: const TextStyle(color: Color(0xFF65736F)),
                ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.title, required this.text});
  final String title, text;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFDFF1EC),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: _ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(color: Color(0xFF53635F))),
      ],
    ),
  );
}

class _DarkHeader extends StatelessWidget {
  const _DarkHeader({required this.title, required this.subtitle});
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: _ink,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(subtitle, style: const TextStyle(color: Color(0xFFCBE2DA))),
      ],
    ),
  );
}

class _Summary extends StatelessWidget {
  const _Summary({required this.rows});
  final Map<String, dynamic> rows;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFDDE6E3)),
      borderRadius: BorderRadius.circular(14),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) => Column(
        children: rows.entries
            .map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: constraints.maxWidth * 0.46,
                      child: Text(
                        e.key,
                        style: const TextStyle(color: Color(0xFF65736F)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${e.value}',
                        textAlign: TextAlign.left,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    ),
  );
}

class _QuoteTile extends StatelessWidget {
  const _QuoteTile({required this.q, required this.onTap, this.statusLabel});
  final Map<String, dynamic> q;
  final VoidCallback onTap;
  final String? statusLabel;
  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.all(14),
      leading: const CircleAvatar(
        backgroundColor: Color(0xFFDFF1EC),
        child: Icon(Icons.request_quote, color: _brand),
      ),
      title: Text(
        q['organizationName'] ?? q['consumerUsername'] ?? '',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '#${q['quoteNumber']} · ${statusLabel ?? _status(q['status'])}',
      ),
      trailing: const Icon(Icons.chevron_right),
    ),
  );
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.retry});
  final String message;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          TextButton(onPressed: retry, child: const Text('Reintentar')),
        ],
      ),
    ),
  );
}

String _status(dynamic raw) =>
    {
      'SOLICITADA': 'Solicitada',
      'EN_REVISION': 'En revisión',
      'COTIZADA': 'Lista para revisar',
      'ACEPTADA': 'Aceptada',
      'RECHAZADA': 'Rechazada',
      'VENCIDA': 'Vencida',
      'CONFIRMADA': 'Confirmada',
      'EN_PREPARACION': 'En preparación',
      'DESPACHADA': 'Despachada',
      'EN_TRANSITO': 'En tránsito',
      'ENTREGADA': 'Entregada',
    }[raw] ??
    raw?.toString() ??
    '';

String _organizationQuoteStatus(dynamic raw) =>
    {
      'SOLICITADA': 'Pendiente de revisión',
      'EN_REVISION': 'En preparación',
      'COTIZADA': 'Esperando respuesta del consumidor',
      'ACEPTADA': 'Aceptada por el consumidor',
      'RECHAZADA': 'Rechazada por el consumidor',
      'VENCIDA': 'Vencida',
    }[raw] ??
    _status(raw);
InputDecoration _input(String label) => InputDecoration(
  labelText: label,
  filled: true,
  fillColor: Colors.white,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
);
final ButtonStyle _primary = FilledButton.styleFrom(
  backgroundColor: _brand,
  minimumSize: const Size.fromHeight(52),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
);
