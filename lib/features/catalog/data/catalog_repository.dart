import 'package:flutter/material.dart';
import 'product_model.dart';

class FiltrosCriterio {
  double? precioMinimo;
  double? precioMaximo;
  double? calificacion;
  bool envioGratis;
  bool ventaPorKilo;
  bool ventaPorCaja;
  bool soloDisponibles;
  double? distanciaMaximaKm;
  String modalidad;

  FiltrosCriterio({
    this.precioMinimo,
    this.precioMaximo,
    this.calificacion,
    this.envioGratis = false,
    this.ventaPorKilo = false,
    this.ventaPorCaja = false,
    this.soloDisponibles = false,
    this.distanciaMaximaKm,
    this.modalidad = 'TODOS',
  });

  void limpiar() {
    precioMinimo = null;
    precioMaximo = null;
    calificacion = null;
    envioGratis = false;
    ventaPorKilo = false;
    ventaPorCaja = false;
    soloDisponibles = false;
    distanciaMaximaKm = null;
    modalidad = 'TODOS';
  }

  FiltrosCriterio clonar() {
    return FiltrosCriterio(
      precioMinimo: precioMinimo,
      precioMaximo: precioMaximo,
      calificacion: calificacion,
      envioGratis: envioGratis,
      ventaPorKilo: ventaPorKilo,
      ventaPorCaja: ventaPorCaja,
      soloDisponibles: soloDisponibles,
      distanciaMaximaKm: distanciaMaximaKm,
      modalidad: modalidad,
    );
  }
}

class CatalogoRepositorio extends ChangeNotifier {
  // Singleton Pattern
  static final CatalogoRepositorio _instancia = CatalogoRepositorio._interno();
  factory CatalogoRepositorio() => _instancia;
  CatalogoRepositorio._interno();

  // Lista en memoria inicializada según las imágenes del usuario
  final List<Producto> _productos = [
    Producto(
      id: '1',
      nombre: 'Naranja para jugo',
      precio: 3.80,
      unidad: 'Kg',
      pesoUnidadAprox: 0.25,
      textoPesoUnidad: '1 Und. = 0.25 Kg aprox.',
      urlImagen:
          'https://images.unsplash.com/photo-1611080626919-7cf5a9dbab5b?q=80&w=600&auto=format&fit=crop',
      esFavorito: false,
      calificacion: 4.5,
      cantidadResenas: 89,
      nombreVendedor: 'Sebastian Paredes',
      calificacionVendedor: 4.8,
      urlAvatarVendedor:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=200&auto=format&fit=crop',
      stockDisponible: 50.0,
      descripcion:
          'Naranjas frescas y jugosas seleccionadas, ideales para preparar un delicioso jugo natural. Cosechadas de manera artesanal y empacadas con cuidado.',
      categoria: 'Frutas',
      envioGratis: true,
      ventaPorKilo: true,
      ventaPorCaja: false,
    ),
    Producto(
      id: '2',
      nombre: 'Papa Blanca Yungay',
      precio: 3.50,
      unidad: 'Kg',
      pesoUnidadAprox: 0.4,
      textoPesoUnidad: '1 Und. = 0.4 Kg aprox.',
      urlImagen:
          'https://images.unsplash.com/photo-1518977676601-b53f82aba655?q=80&w=600&auto=format&fit=crop',
      esFavorito: true,
      calificacion: 4.6,
      cantidadResenas: 120,
      nombreVendedor: 'Sebastian Paredes',
      calificacionVendedor: 4.7,
      urlAvatarVendedor:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=200&auto=format&fit=crop',
      stockDisponible: 120.0,
      descripcion:
          'Papa Blanca Yungay cosechada en tierras altoandinas. Excelente textura harinosa, perfectas para sancochar, freír o preparar purés.',
      categoria: 'Tubérculos',
      envioGratis: false,
      ventaPorKilo: true,
      ventaPorCaja: true,
      precioCaja: 47.25,
      stockCaja: 8.0,
      unidadesCajaReferencial: 15.0,
    ),
    Producto(
      id: '3',
      nombre: 'Palta Hass',
      precio: 5.19,
      unidad: 'Kg',
      pesoUnidadAprox: 2.0,
      textoPesoUnidad: '1 Und. = 2 Kg aprox.',
      urlImagen:
          'https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?q=80&w=600&auto=format&fit=crop',
      esFavorito: false,
      calificacion: 4.8,
      cantidadResenas: 64,
      nombreVendedor: 'María Ccopa',
      calificacionVendedor: 4.9,
      urlAvatarVendedor:
          'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?q=80&w=200&auto=format&fit=crop',
      stockDisponible: 80.0,
      descripcion:
          'Palta Hass extra cremosa de maduración uniforme. Ideal para untar en el pan, acompañar ensaladas o preparar guacamole.',
      categoria: 'Frutas',
      envioGratis: true,
      ventaPorKilo: true,
      ventaPorCaja: true,
      precioCaja: 70.00,
      stockCaja: 5.0,
      unidadesCajaReferencial: 15.0,
    ),
    Producto(
      id: '4',
      nombre: 'Piña Golden',
      precio: 3.50,
      unidad: 'Kg',
      pesoUnidadAprox: 0.4,
      textoPesoUnidad: '1 Und. = 0.4 Kg aprox.',
      urlImagen:
          'https://images.unsplash.com/photo-1550258987-190a2d41a8ba?q=80&w=600&auto=format&fit=crop',
      esFavorito: false,
      calificacion: 4.4,
      cantidadResenas: 45,
      nombreVendedor: 'María Ccopa',
      calificacionVendedor: 4.6,
      urlAvatarVendedor:
          'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?q=80&w=200&auto=format&fit=crop',
      stockDisponible: 60.0,
      descripcion:
          'Piña Golden dulce y aromática cosechada en Chanchamayo. Con su característico color amarillo intenso y gran cantidad de jugo.',
      categoria: 'Frutas',
      envioGratis: false,
      ventaPorKilo: true,
      ventaPorCaja: true,
      precioCaja: 20.00,
      stockCaja: 10.0,
      unidadesCajaReferencial: 6.0,
    ),
    Producto(
      id: '5',
      nombre: 'Granadilla',
      precio: 0.90,
      unidad: 'Und.',
      pesoUnidadAprox: 0.1,
      textoPesoUnidad: '1 Und.',
      urlImagen:
          'https://images.unsplash.com/photo-1596436889106-be35e843f974?q=80&w=600&auto=format&fit=crop',
      esFavorito: true,
      calificacion: 4.7,
      cantidadResenas: 30,
      nombreVendedor: 'Elena Ruiz',
      calificacionVendedor: 4.7,
      urlAvatarVendedor:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=200&auto=format&fit=crop',
      stockDisponible: 200.0,
      descripcion:
          'Granadilla súper dulce, fresca y llena de nutrientes digestivos. Ideal para loncheras escolares o postres saludables.',
      categoria: 'Frutas',
      envioGratis: true,
      ventaPorKilo: false,
      ventaPorCaja: false,
    ),
    Producto(
      id: '6',
      nombre: 'Pimiento Morron',
      precio: 8.80,
      unidad: 'Kg',
      pesoUnidadAprox: 0.2,
      textoPesoUnidad: '1 Und. = 0.2 Kg aprox.',
      urlImagen:
          'https://images.unsplash.com/photo-1563565312-3aab44e27f91?q=80&w=600&auto=format&fit=crop',
      esFavorito: true,
      calificacion: 4.5,
      cantidadResenas: 42,
      nombreVendedor: 'Sebastian Paredes',
      calificacionVendedor: 4.8,
      urlAvatarVendedor:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=200&auto=format&fit=crop',
      stockDisponible: 45.0,
      descripcion:
          'Pimientos morrones de color rojo intenso, carnosos y con un toque de dulzor natural. Perfectos para parrillas, guisos o ensaladas frescas.',
      categoria: 'Verduras',
      envioGratis: true,
      ventaPorKilo: true,
      ventaPorCaja: true,
      precioCaja: 118.80,
      stockCaja: 3.0,
      unidadesCajaReferencial: 15.0,
    ),
    // Productos adicionales para otras categorías y robustez
    Producto(
      id: '7',
      nombre: 'Culantro fresco',
      precio: 1.20,
      unidad: 'Und.',
      pesoUnidadAprox: 0.1,
      textoPesoUnidad: '1 atado aprox.',
      urlImagen:
          'https://images.unsplash.com/photo-1515002246390-7bf7e8f87b54?q=80&w=600&auto=format&fit=crop',
      esFavorito: false,
      calificacion: 4.3,
      cantidadResenas: 15,
      nombreVendedor: 'Elena Ruiz',
      calificacionVendedor: 4.7,
      urlAvatarVendedor:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=200&auto=format&fit=crop',
      stockDisponible: 100.0,
      descripcion:
          'Culantro recién cosechado de hojas verdes intensas y aroma penetrante. Básico en la cocina criolla.',
      categoria: 'Hierbas',
      envioGratis: true,
      ventaPorKilo: false,
      ventaPorCaja: false,
    ),
    Producto(
      id: '8',
      nombre: 'Lechuga Orgánica',
      precio: 2.00,
      unidad: 'Und.',
      pesoUnidadAprox: 0.3,
      textoPesoUnidad: '1 cabeza aprox.',
      urlImagen:
          'https://images.unsplash.com/photo-1622484211148-7170a45e2c56?q=80&w=600&auto=format&fit=crop',
      esFavorito: false,
      calificacion: 4.7,
      cantidadResenas: 25,
      nombreVendedor: 'Juan Quispe',
      calificacionVendedor: 4.7,
      urlAvatarVendedor:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=200&auto=format&fit=crop',
      stockDisponible: 90.0,
      descripcion:
          'Lechuga crespa hidropónica libre de pesticidas. Hojas crujientes y frescas listas para consumir.',
      categoria: 'Verduras',
      envioGratis: false,
      ventaPorKilo: false,
      ventaPorCaja: false,
    ),
    Producto(
      id: '9',
      nombre: 'Quinua Blanca',
      precio: 10.50,
      unidad: 'Kg',
      pesoUnidadAprox: 1.0,
      textoPesoUnidad: '1 bolsa de 1 Kg',
      urlImagen:
          'https://images.unsplash.com/photo-1586201375761-83865001e31c?q=80&w=600&auto=format&fit=crop',
      esFavorito: false,
      calificacion: 4.9,
      cantidadResenas: 58,
      nombreVendedor: 'María Flores',
      calificacionVendedor: 4.9,
      urlAvatarVendedor:
          'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=200&auto=format&fit=crop',
      stockDisponible: 150.0,
      descripcion:
          'Quinua blanca orgánica lavada de la región de Puno. Alto valor nutricional, lista para sancochar.',
      categoria: 'Granos y cereales',
      envioGratis: true,
      ventaPorKilo: true,
      ventaPorCaja: true,
      precioCaja: 140.00,
      stockCaja: 10.0,
      unidadesCajaReferencial: 15.0,
    ),
  ];

  final FiltrosCriterio filtrosActivos = FiltrosCriterio();

  List<Producto> get productos => List.unmodifiable(_productos);

  // Obtiene los productos aplicando la búsqueda por término, categoría y filtros activos
  List<Producto> obtenerProductosFiltrados({
    String? terminoBusqueda,
    String? categoriaSeleccionada,
  }) {
    return _productos.where((p) {
      // 1. Filtrar por término de búsqueda
      if (terminoBusqueda != null && terminoBusqueda.isNotEmpty) {
        if (!p.nombre.toLowerCase().contains(terminoBusqueda.toLowerCase()) &&
            !p.descripcion.toLowerCase().contains(
              terminoBusqueda.toLowerCase(),
            )) {
          return false;
        }
      }

      // 2. Filtrar por categoría
      if (categoriaSeleccionada != null && categoriaSeleccionada.isNotEmpty) {
        if (p.categoria != categoriaSeleccionada) {
          return false;
        }
      }

      // 3. Filtrar por precio mínimo
      if (filtrosActivos.precioMinimo != null &&
          p.precio < filtrosActivos.precioMinimo!) {
        return false;
      }

      // 4. Filtrar por precio máximo
      if (filtrosActivos.precioMaximo != null &&
          p.precio > filtrosActivos.precioMaximo!) {
        return false;
      }

      // 5. Filtrar por calificación mínima
      if (filtrosActivos.calificacion != null &&
          p.calificacion < filtrosActivos.calificacion!) {
        return false;
      }

      // 6. Filtrar por Envío Gratis
      if (filtrosActivos.envioGratis && !p.envioGratis) {
        return false;
      }

      // 7. Filtrar por Venta por Kilo
      if (filtrosActivos.ventaPorKilo && !p.ventaPorKilo) {
        return false;
      }

      // 8. Filtrar por Venta por Caja
      if (filtrosActivos.ventaPorCaja && !p.ventaPorCaja) {
        return false;
      }

      return true;
    }).toList();
  }

  // Obtiene la lista de favoritos
  List<Producto> obtenerFavoritos() {
    return _productos.where((p) => p.esFavorito).toList();
  }

  // Alterna el estado de favorito de un producto y notifica a los escuchas
  void alternarFavorito(String id) {
    final index = _productos.indexWhere((p) => p.id == id);
    if (index != -1) {
      _productos[index].esFavorito = !_productos[index].esFavorito;
      notifyListeners();
    }
  }

  // Aplica nuevos criterios de filtro
  void aplicarFiltros(FiltrosCriterio nuevosFiltros) {
    filtrosActivos.precioMinimo = nuevosFiltros.precioMinimo;
    filtrosActivos.precioMaximo = nuevosFiltros.precioMaximo;
    filtrosActivos.calificacion = nuevosFiltros.calificacion;
    filtrosActivos.envioGratis = nuevosFiltros.envioGratis;
    filtrosActivos.ventaPorKilo = nuevosFiltros.ventaPorKilo;
    filtrosActivos.ventaPorCaja = nuevosFiltros.ventaPorCaja;
    filtrosActivos.soloDisponibles = nuevosFiltros.soloDisponibles;
    filtrosActivos.distanciaMaximaKm = nuevosFiltros.distanciaMaximaKm;
    filtrosActivos.modalidad = nuevosFiltros.modalidad;
    notifyListeners();
  }

  // Limpia los filtros activos
  void limpiarFiltros() {
    filtrosActivos.limpiar();
    notifyListeners();
  }

  // Agrega un producto a la lista en memoria y notifica a los escuchas
  void agregarProducto(Producto producto) {
    _productos.add(producto);
    notifyListeners();
  }

  // Modifica un producto de la lista en memoria y notifica a los escuchas
  void editarProducto(Producto producto) {
    final index = _productos.indexWhere((p) => p.id == producto.id);
    if (index != -1) {
      _productos[index] = producto;
      notifyListeners();
    }
  }

  // Elimina un producto de la lista en memoria por su ID y notifica a los escuchas
  void eliminarProducto(String id) {
    _productos.removeWhere((p) => p.id == id);
    notifyListeners();
  }
}
