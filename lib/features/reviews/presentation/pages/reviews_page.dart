import 'package:flutter/material.dart';
import 'package:tinkiyagro_app/core/session_manager.dart';
import '../../data/review_model.dart';
import '../../../catalog/data/product_model.dart';
import '../../../catalog/data/remote/catalog_service.dart';
import 'write_review_page.dart';

class ResenasPage extends StatefulWidget {
  const ResenasPage({super.key});

  @override
  State<ResenasPage> createState() => _ResenasPageState();
}

class _ResenasPageState extends State<ResenasPage> {
  final _service = CatalogService();
  List<Resena> _resenas = [];
  bool _cargando = true;
  bool _puedeResenar = false;
  Producto? _producto;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_producto == null) {
      _producto = ModalRoute.of(context)?.settings.arguments as Producto?;
      if (_producto != null) _cargarResenas();
    }
  }

  Future<void> _cargarResenas() async {
    if (_producto == null) return;
    setState(() => _cargando = true);
    try {
      final results = await Future.wait([
        _service.listarResenas(_producto!.id),
        _service.verificarCompra(_producto!.id),
      ]);
      if (mounted) {
        final resenas = results[0] as List<Resena>;
        final comproProduto = results[1] as bool;
        final username = SessionManager().username ?? '';
        final yaReseno = resenas.any((r) => r.userName == username);
        setState(() {
          _resenas = resenas;
          _puedeResenar = comproProduto && !yaReseno;
          _cargando = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _resenas = List.from(mockResenas);
          _cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Reseñas',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: _puedeResenar
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF5CA399),
              foregroundColor: Colors.white,
              onPressed: () async {
                final newReview = await Navigator.push<Resena>(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        WriteReviewsPage(productId: _producto?.id ?? ''),
                  ),
                );
                if (newReview != null) {
                  if (!context.mounted) return;
                  setState(() => _resenas.insert(0, newReview));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reseña publicada correctamente.'),
                      backgroundColor: Color(0xFF5CA399),
                    ),
                  );
                }
              },
              child: const Icon(Icons.edit_outlined),
            )
          : null,
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF5CA399)),
            )
          : _resenas.isEmpty
          ? const Center(
              child: Text(
                'Aún no hay reseñas para este producto.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _resenas.length,
              itemBuilder: (context, index) {
                return _buildReviewItem(_resenas[index]);
              },
            ),
    );
  }

  Widget _buildReviewItem(Resena resena) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: resena.avatarUrl.isNotEmpty
                    ? NetworkImage(resena.avatarUrl)
                    : null,
                backgroundColor: Colors.grey.shade200,
                child: resena.avatarUrl.isEmpty
                    ? const Icon(Icons.person, size: 20)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resena.userName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      resena.timeAgo,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFECECEC), height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                resena.rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 6),
              Row(
                children: List.generate(5, (index) {
                  final val = index + 1;
                  final llena = val <= resena.rating.floor();
                  final media = !llena && (resena.rating - index >= 0.5);
                  return Icon(
                    llena
                        ? Icons.star
                        : (media ? Icons.star_half : Icons.star_border),
                    color: const Color(0xFFFFC107),
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            resena.content,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
