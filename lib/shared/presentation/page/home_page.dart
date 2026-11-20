import 'dart:async';
import 'package:flutter/material.dart';
import '../../../features/catalog/data/product_model.dart';
import '../../../features/catalog/data/remote/catalog_service.dart';
import '../../../features/catalog/data/catalog_repository.dart';
import '../../../features/favorites/presentation/pages/favorites_page.dart';
import '../../../features/favorites/data/favorites_cache.dart';
import '../../../features/cart/presentation/pages/cart_page.dart';
import '../../../features/farmer/presentation/pages/farmer_orders_page.dart';
import '../../../features/farmer/presentation/pages/farmer_deliveries_page.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tinkiyagro_app/core/session_manager.dart';
import 'package:tinkiyagro_app/features/farmer/presentation/pages/farmer_products_page.dart';
import 'package:tinkiyagro_app/features/profile/presentation/pages/consumer_profile_page.dart';
import 'package:tinkiyagro_app/features/profile/presentation/pages/farmer_profile_page.dart';
import 'package:tinkiyagro_app/features/profile/presentation/pages/notifications_page.dart';
import 'package:tinkiyagro_app/features/organization/data/organization_service.dart';
import 'package:tinkiyagro_app/features/wholesale/data/wholesale_service.dart';
import 'package:tinkiyagro_app/features/wholesale/presentation/wholesale_pages.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:tinkiyagro_app/core/evaluation/evaluation_analytics_service.dart';
import 'package:tinkiyagro_app/core/evaluation/pilot_feed.dart';
import '../widgets/pilot_feed_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _indicePestana = 0;
  final _catalogService = CatalogService();

  // Estado de búsqueda y filtro (consumer home)
  String _terminoBusqueda = '';
  String? _categoriaSeleccionada;
  final _searchCtrl = TextEditingController();
  Timer? _debounceTimer;

  // Productos del home cargados desde API
  List<Producto> _recomendados = [];
  List<Producto> _tendencias = [];
  List<Producto> _resultadosBusqueda = [];
  List<Map<String, dynamic>> _wholesaleProducts = [];
  bool _cargandoHome = true;
  bool _buscando = false;
  List<PilotFeedList> _pilotLists = [];
  PilotSeasonContext? _pilotSeason;
  bool _feedFailed = false;

  // True si hay cualquier filtro/búsqueda/categoría activa
  bool get _enModoFiltro {
    final f = CatalogoRepositorio().filtrosActivos;
    return _terminoBusqueda.isNotEmpty ||
        _categoriaSeleccionada != null ||
        f.precioMinimo != null ||
        f.precioMaximo != null ||
        f.calificacion != null ||
        f.ventaPorKilo ||
        f.ventaPorCaja ||
        f.soloDisponibles ||
        f.distanciaMaximaKm != null ||
        f.modalidad != 'TODOS';
  }

  final List<Map<String, dynamic>> _categorias = [
    {
      'nombre': 'Verduras',
      'icono': SvgPicture.asset(
        'assets/icons/lettuce.svg',
        width: 28,
        height: 28,
      ),
      'colorFondo': const Color(0xFFE8F5E9),
    },
    {
      'nombre': 'Frutas',
      'icono': SvgPicture.asset(
        'assets/icons/apple.svg',
        width: 28,
        height: 28,
      ),
      'colorFondo': const Color(0xFFFFF3E0),
    },
    {
      'nombre': 'Hierbas',
      'icono': SvgPicture.asset('assets/icons/herb.svg', width: 28, height: 28),
      'colorFondo': const Color(0xFFE8F8F5),
    },
    {
      'nombre': 'Tubérculos',
      'icono': SvgPicture.asset(
        'assets/icons/potato.svg',
        width: 28,
        height: 28,
      ),
      'colorFondo': const Color(0xFFEFEBE9),
    },
    {
      'nombre': 'Granos y cereales',
      'icono': SvgPicture.asset(
        'assets/icons/wheat.svg',
        width: 28,
        height: 28,
      ),
      'colorFondo': const Color(0xFFFAF3E0),
    },
  ];

  @override
  void initState() {
    super.initState();
    if (SessionManager().rol == 'CONSUMIDOR') {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _ensureDiscoveryPreferences(),
      );
    }
    if (SessionManager().rol != 'AGRICULTOR') {
      _cargarProductosHome();
    }
  }

  Future<void> _ensureDiscoveryPreferences() async {
    try {
      final preference = await OrganizationService().getDiscoveryPreferences();
      if (mounted && preference['configured'] != true) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/consumer_discovery_update',
          (_) => false,
        );
      }
    } catch (_) {
      // Existing installations may briefly run against an older backend.
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _cargarProductosHome() async {
    setState(() => _cargandoHome = true);
    var feedFailed = false;
    var lists = <PilotFeedList>[];
    PilotSeasonContext? season;
    var recommended = <Producto>[];
    var popular = <Producto>[];
    var wholesale = <Map<String, dynamic>>[];

    try {
      final feed = await PilotFeedService().load();
      lists = feed.lists;
      season = feed.season;
    } catch (error) {
      feedFailed = true;
      debugPrint('[HomePage] Pilot feed unavailable: $error');
      try {
        recommended = await _catalogService.obtenerRecomendados();
      } catch (fallbackError) {
        debugPrint(
          '[HomePage] Recommended fallback unavailable: $fallbackError',
        );
      }
      try {
        popular = await _catalogService.obtenerPopulares();
      } catch (fallbackError) {
        debugPrint('[HomePage] Popular fallback unavailable: $fallbackError');
      }
    }

    try {
      wholesale = await WholesaleService().products();
    } catch (error) {
      debugPrint('[HomePage] Wholesale products unavailable: $error');
    }

    if (mounted) {
      setState(() {
        _pilotLists = lists;
        _pilotSeason = season;
        _recomendados = recommended;
        _tendencias = popular;
        _feedFailed = feedFailed;
        _wholesaleProducts = wholesale;
        _cargandoHome = false;
      });
    }
  }

  void _onSearchChanged(String val) {
    setState(() => _terminoBusqueda = val);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), _buscarProductos);
  }

  void _limpiarTodo() {
    _debounceTimer?.cancel();
    _searchCtrl.clear();
    CatalogoRepositorio().limpiarFiltros();
    setState(() {
      _terminoBusqueda = '';
      _categoriaSeleccionada = null;
      _resultadosBusqueda = [];
    });
  }

  Future<void> _buscarProductos() async {
    setState(() => _buscando = true);
    try {
      final categoriaEnum = _categoriaSeleccionada != null
          ? labelToCategory(_categoriaSeleccionada)
          : null;
      final filtros = CatalogoRepositorio().filtrosActivos;
      final resultados = filtros.modalidad == 'MAYORISTA'
          ? <Producto>[]
          : await _catalogService.buscarProductos(
              termino: _terminoBusqueda.isEmpty ? null : _terminoBusqueda,
              categoria: categoriaEnum?.isNotEmpty == true
                  ? categoriaEnum
                  : null,
              precioMin: filtros.precioMinimo,
              precioMax: filtros.precioMaximo,
              calificacion: filtros.calificacion,
              ventaPorKilo: filtros.ventaPorKilo ? true : null,
              ventaPorCaja: filtros.ventaPorCaja ? true : null,
            );
      final filteredRetail = filtros.soloDisponibles
          ? resultados
                .where((p) => p.purchasable && p.stockDisponible > 0)
                .toList()
          : resultados;
      var wholesale = await WholesaleService().products();
      if (filtros.modalidad == 'MINORISTA') wholesale = [];
      final term = _terminoBusqueda.toLowerCase();
      wholesale = wholesale.where((p) {
        final matchesTerm =
            term.isEmpty ||
            (p['name'] ?? '').toString().toLowerCase().contains(term);
        final category =
            _categoriaSeleccionada == null ||
            (p['category'] ?? '')
                .toString()
                .replaceAll('_', ' ')
                .toLowerCase()
                .contains(
                  _categoriaSeleccionada!.toLowerCase().replaceAll(' y ', ' '),
                );
        final price = (p['referencePrice'] as num?)?.toDouble() ?? 0;
        return matchesTerm &&
            category &&
            (!filtros.soloDisponibles ||
                ((p['stock'] as num?)?.toDouble() ?? 0) > 0) &&
            (filtros.distanciaMaximaKm == null ||
                ((p['distanceKm'] as num?)?.toDouble() ?? double.infinity) <=
                    filtros.distanciaMaximaKm!) &&
            (filtros.precioMinimo == null || price >= filtros.precioMinimo!) &&
            (filtros.precioMaximo == null || price <= filtros.precioMaximo!);
      }).toList();
      setState(() {
        _resultadosBusqueda = filteredRetail;
        _wholesaleProducts = wholesale;
        _buscando = false;
      });
    } catch (_) {
      setState(() => _buscando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: _buildCuerpoPagina(),
      bottomNavigationBar: SafeArea(
        top: false,
        child: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildCuerpoPagina() {
    final isFarmer = SessionManager().rol == 'AGRICULTOR';
    final activeIndex = isFarmer ? _indicePestana.clamp(0, 3) : _indicePestana;

    if (isFarmer) {
      switch (activeIndex) {
        case 0:
          return const FarmerProductsPage();
        case 1:
          return const FarmerOrdersPage();
        case 2:
          return const FarmerEntregasPage();
        case 3:
          return FarmerProfilePage(
            onTabSwitch: (i) => setState(() => _indicePestana = i),
          );
        default:
          return const FarmerProductsPage();
      }
    } else {
      switch (activeIndex) {
        case 0:
          return _buildInicioTab();
        case 1:
          return const PaginaFavoritos();
        case 2:
          return const CarritoPage();
        case 3:
          return const ConsumerActivityPage();
        case 4:
          return ConsumerProfilePage(
            onTabSwitch: (i) => setState(() => _indicePestana = i),
          );
        default:
          return _buildInicioTab();
      }
    }
  }

  Widget _buildBottomNavigationBar() {
    final isFarmer = SessionManager().rol == 'AGRICULTOR';
    final activeIndex = isFarmer ? _indicePestana.clamp(0, 3) : _indicePestana;

    final items = isFarmer
        ? const [
            BottomNavigationBarItem(
              icon: Icon(Icons.eco_outlined, size: 26),
              activeIcon: Icon(Icons.eco, size: 26),
              label: 'Productos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined, size: 26),
              activeIcon: Icon(Icons.receipt_long, size: 26),
              label: 'Actividad',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_shipping_outlined, size: 26),
              activeIcon: Icon(Icons.local_shipping, size: 26),
              label: 'Entregas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 26),
              activeIcon: Icon(Icons.person, size: 26),
              label: 'Perfil',
            ),
          ]
        : const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled, size: 26),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border, size: 26),
              activeIcon: Icon(Icons.favorite, size: 26),
              label: 'Favoritos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined, size: 26),
              activeIcon: Icon(Icons.shopping_cart, size: 26),
              label: 'Carrito',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_basket_outlined, size: 26),
              activeIcon: Icon(Icons.shopping_basket, size: 26),
              label: 'Pedidos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 26),
              activeIcon: Icon(Icons.person, size: 26),
              label: 'Perfil',
            ),
          ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: activeIndex,
        onTap: (index) => setState(() => _indicePestana = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedItemColor: isFarmer
            ? const Color(0xFF5CA399)
            : const Color(0xFF8CAF3F),
        unselectedItemColor: Colors.grey.shade400,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        items: items,
      ),
    );
  }

  // --- PESTAÑA INICIO (CONSUMIDOR) ---
  Widget _buildInicioTab() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _enModoFiltro ? _buscarProductos : _cargarProductosHome,
        color: const Color(0xFF5CA399),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TINKIAGRO',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A32),
                      letterSpacing: 0.5,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.notifications_none,
                            color: Colors.black87,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NotificationsPage(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () async {
                          final aplicar = await Navigator.pushNamed(
                            context,
                            '/filtros',
                          );
                          if (aplicar == true) _buscarProductos();
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color:
                                _enModoFiltro &&
                                    (CatalogoRepositorio()
                                                .filtrosActivos
                                                .precioMinimo !=
                                            null ||
                                        CatalogoRepositorio()
                                                .filtrosActivos
                                                .precioMaximo !=
                                            null ||
                                        CatalogoRepositorio()
                                            .filtrosActivos
                                            .ventaPorKilo ||
                                        CatalogoRepositorio()
                                            .filtrosActivos
                                            .ventaPorCaja)
                                ? const Color(0xFF1E3A32)
                                : const Color(0xFF5CA399),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.filter_alt,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Barra de búsqueda
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF5CA399),
                      size: 24,
                    ),
                    hintText: '¿Qué estás buscando?',
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                    suffixIcon: _terminoBusqueda.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: Colors.grey,
                              size: 20,
                            ),
                            onPressed: () {
                              _searchCtrl.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Categorías
              const Text(
                'Categorias',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 104,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categorias.length,
                  itemBuilder: (context, index) {
                    final cat = _categorias[index];
                    final esSeleccionada =
                        _categoriaSeleccionada == cat['nombre'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 18.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _categoriaSeleccionada = esSeleccionada
                                ? null
                                : cat['nombre'] as String;
                          });
                          _buscarProductos();
                        },
                        child: Column(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: cat['colorFondo'] as Color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: esSeleccionada
                                      ? const Color(0xFF5CA399)
                                      : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                              child: Center(child: cat['icono'] as Widget),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              cat['nombre'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: esSeleccionada
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: esSeleccionada
                                    ? const Color(0xFF5CA399)
                                    : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Contenido principal: resultados o secciones
              if (_enModoFiltro)
                _buildResultadosFiltro()
              else
                ..._buildExperimentalSections(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildExperimentalSections() {
    return [
      if (_cargandoHome)
        const Center(child: CircularProgressIndicator())
      else if (_feedFailed) ...[
        TextButton.icon(
          onPressed: _cargarProductosHome,
          icon: const Icon(Icons.refresh),
          label: const Text(
            'No se pudo cargar el feed personalizado. Reintentar',
          ),
        ),
        _buildSeccionProductos(
          titulo: 'Recomendados para ti',
          productos: _recomendados,
          cargando: false,
          routeName: 'Recomendados para ti',
        ),
        const SizedBox(height: 24),
        _buildSeccionProductos(
          titulo: 'Productos populares',
          productos: _tendencias,
          cargando: false,
          routeName: 'Productos populares',
        ),
        const SizedBox(height: 24),
        _buildWholesaleFallback(),
      ] else
        PilotFeedView(lists: _pilotLists, season: _pilotSeason),
      const SizedBox(height: 30),
    ];
  }

  Widget _buildWholesaleFallback() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Organizaciones de productores',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      const Text('Compra por volumen, con cotización'),
      const SizedBox(height: 16),
      _buildWholesaleCarousel('Recomendados para ti', _wholesaleProducts),
      const SizedBox(height: 20),
      _buildWholesaleCarousel('Populares', _wholesaleProducts),
    ],
  );

  Widget _buildWholesaleCarousel(
    String title,
    List<Map<String, dynamic>> products,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 12),
      if (products.isEmpty)
        const Text('No hay productos disponibles en tu zona.')
      else
        SizedBox(
          height: 250,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: products
                .take(6)
                .map((p) => WholesaleProductCard(product: p, compact: true))
                .toList(),
          ),
        ),
    ],
  );

  Widget _buildResultadosFiltro() {
    final filtros = CatalogoRepositorio().filtrosActivos;
    final etiquetas = <String>[
      if (_terminoBusqueda.isNotEmpty) 'Búsqueda: $_terminoBusqueda',
      if (_categoriaSeleccionada != null) _categoriaSeleccionada!,
      if (filtros.modalidad != 'TODOS')
        filtros.modalidad == 'MINORISTA' ? 'Compra directa' : 'Mayorista',
      if (filtros.precioMinimo != null) 'Desde S/ ${filtros.precioMinimo}',
      if (filtros.precioMaximo != null) 'Hasta S/ ${filtros.precioMaximo}',
      if (filtros.calificacion != null) '${filtros.calificacion}+ estrellas',
      if (filtros.ventaPorKilo) 'Por kilo',
      if (filtros.ventaPorCaja) 'Por caja',
      if (filtros.soloDisponibles) 'Disponibles',
      if (filtros.distanciaMaximaKm != null)
        'Hasta ${filtros.distanciaMaximaKm!.round()} km',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _buscando
                  ? 'Buscando...'
                  : '${_resultadosBusqueda.length + _wholesaleProducts.length} resultado${_resultadosBusqueda.length + _wholesaleProducts.length != 1 ? "s" : ""}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            TextButton.icon(
              onPressed: _limpiarTodo,
              icon: const Icon(
                Icons.clear_all,
                size: 18,
                color: Color(0xFF5CA399),
              ),
              label: const Text(
                'Limpiar',
                style: TextStyle(
                  color: Color(0xFF5CA399),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        if (etiquetas.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: etiquetas
                .map(
                  (label) => Chip(
                    label: Text(label),
                    backgroundColor: const Color(0xFFE0F2ED),
                    side: BorderSide.none,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 12),
        if (_buscando)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(color: Color(0xFF5CA399)),
            ),
          )
        else if (_resultadosBusqueda.isEmpty && _wholesaleProducts.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 56, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    'No se encontraron productos.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          if (_resultadosBusqueda.isNotEmpty)
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.76,
              ),
              itemCount: _resultadosBusqueda.length,
              itemBuilder: (context, index) =>
                  _buildTarjetaProductoHome(_resultadosBusqueda[index]),
            ),
          if (_wholesaleProducts.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text(
              'Al por mayor',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ..._wholesaleProducts.map((p) => WholesaleProductCard(product: p)),
          ],
        ],
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildSeccionProductos({
    required String titulo,
    required List<Producto> productos,
    required bool cargando,
    required String routeName,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.black54,
              ),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/seccion_productos',
                  arguments: {'titulo': routeName, 'productos': productos},
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (cargando)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: CircularProgressIndicator(color: Color(0xFF5CA399)),
            ),
          )
        else if (productos.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40.0),
              child: Text(
                'No se encontraron productos.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
        else
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.76,
            ),
            itemCount: productos.length > 4 ? 4 : productos.length,
            itemBuilder: (context, index) {
              final producto = productos[index];
              return _instrumentedProductCard(
                producto,
                _buildTarjetaProductoHome(producto),
              );
            },
          ),
      ],
    );
  }

  String? _productStatusLabel(Producto p) {
    if (p.purchasable) return null;
    return p.availabilityMessage.isNotEmpty
        ? p.availabilityMessage
        : 'No disponible';
  }

  Color _productStatusColor(Producto p) {
    if (p.purchaseStatus.toUpperCase() == 'OUT_OF_STOCK') {
      return const Color(0xFFE57373);
    }
    return const Color(0xFFFF9800);
  }

  Widget _buildTarjetaProductoHome(Producto producto) {
    final statusLabel = _productStatusLabel(producto);
    final bool unavailable = statusLabel != null;
    return GestureDetector(
      onTap: unavailable
          ? null
          : () {
              unawaited(
                EvaluationAnalyticsService.instance.click(
                  productId: producto.id,
                  farmer: producto.farmerUsername,
                  section: producto.sourceSection,
                  position: producto.sourcePosition,
                  requestId: producto.recommendationRequestId,
                ),
              );
              Navigator.pushNamed(
                context,
                '/detalle_producto',
                arguments: producto,
              );
            },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: producto.urlImagen.isNotEmpty
                                ? Image.network(
                                    producto.urlImagen,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.eco_outlined,
                                      size: 32,
                                      color: Color(0xFF5CA399),
                                    ),
                                  )
                                : const Icon(
                                    Icons.eco_outlined,
                                    size: 32,
                                    color: Color(0xFF5CA399),
                                  ),
                          ),
                        ),
                        // Botón favorito
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _toggleFavorito(producto),
                            child: Container(
                              width: 32,
                              height: 32,
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                producto.esFavorito
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: producto.esFavorito
                                    ? Colors.red
                                    : Colors.grey.shade400,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 14),
                    child: Column(
                      children: [
                        Text(
                          's/. ${producto.precio.toStringAsFixed(2)} x ${producto.unidad}',
                          style: const TextStyle(
                            color: Color(0xFF4A7C73),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          producto.nombre,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          producto.textoPesoUnidad,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (unavailable)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(color: Colors.black.withValues(alpha: 0.35)),
                ),
              ),
            if (statusLabel != null)
              Positioned.fill(
                child: Align(
                  alignment: const Alignment(0, -0.3),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _productStatusColor(producto),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _instrumentedProductCard(Producto producto, Widget child) {
    if (producto.sourceSection.isEmpty || producto.sourcePosition < 1) {
      return child;
    }
    return VisibilityDetector(
      key: ValueKey(
        'evaluation-${producto.sourceSection}-${producto.id}-${producto.sourcePosition}',
      ),
      onVisibilityChanged: (info) {
        if (info.visibleFraction < 0.5) return;
        unawaited(
          EvaluationAnalyticsService.instance.impression(
            productId: producto.id,
            farmer: producto.farmerUsername,
            section: producto.sourceSection,
            position: producto.sourcePosition,
            requestId: producto.recommendationRequestId,
          ),
        );
      },
      child: child,
    );
  }

  Future<void> _toggleFavorito(Producto producto) async {
    final nuevoEstado = !producto.esFavorito;
    setState(() => _actualizarFavoritoEnListas(producto.id, nuevoEstado));
    if (nuevoEstado) {
      FavoritosCache().agregarOptimista(producto);
    } else {
      FavoritosCache().quitarOptimista(producto.id);
    }
    try {
      if (nuevoEstado) {
        await _catalogService.agregarFavorito(producto.id);
      } else {
        await _catalogService.quitarFavorito(producto.id);
      }
    } catch (_) {
      setState(() => _actualizarFavoritoEnListas(producto.id, !nuevoEstado));
      if (nuevoEstado) {
        FavoritosCache().quitarOptimista(producto.id);
      } else {
        FavoritosCache().agregarOptimista(producto.copiarCon(esFavorito: true));
      }
    }
  }

  void _actualizarFavoritoEnListas(String id, bool nuevoValor) {
    Producto toggle(Producto p) =>
        p.id == id ? (p..esFavorito = nuevoValor) : p;
    _recomendados = _recomendados.map(toggle).toList();
    _tendencias = _tendencias.map(toggle).toList();
    _resultadosBusqueda = _resultadosBusqueda.map(toggle).toList();
  }
}
