import 'package:tinkiyagro_app/core/constants/app_constants.dart';

class Producto {
  final String id;
  final int version;
  final String nombre;
  final double precio;
  final String unidad; // 'Kg' o 'Und.'
  final double pesoUnidadAprox; // e.g., 0.25, 0.4
  final String textoPesoUnidad; // e.g., "1 Und. = 0.25 Kg aprox."
  final String urlImagen;
  bool esFavorito;
  final double calificacion;
  final int cantidadResenas;
  final String nombreVendedor;
  final double calificacionVendedor;
  final String urlAvatarVendedor;
  final double stockDisponible;
  final String descripcion;
  final String
  categoria; // 'Verduras', 'Frutas', 'Hierbas', 'Tubérculos', 'Granos y cereales', 'Cereales'
  final bool envioGratis;
  final bool ventaPorKilo;
  final bool ventaPorCaja;
  final double? precioCaja;
  final double? stockCaja;
  final double? unidadesCajaReferencial;
  final String farmerDescription;
  final String farmerPhone;
  final String productStatus;
  final bool purchasable;
  final String availabilityMessage;
  final String purchaseStatus;

  Producto({
    required this.id,
    this.version = 0,
    required this.nombre,
    required this.precio,
    required this.unidad,
    required this.pesoUnidadAprox,
    required this.textoPesoUnidad,
    required this.urlImagen,
    this.esFavorito = false,
    required this.calificacion,
    required this.cantidadResenas,
    required this.nombreVendedor,
    required this.calificacionVendedor,
    required this.urlAvatarVendedor,
    required this.stockDisponible,
    required this.descripcion,
    required this.categoria,
    required this.envioGratis,
    required this.ventaPorKilo,
    required this.ventaPorCaja,
    this.precioCaja,
    this.stockCaja,
    this.unidadesCajaReferencial,
    this.farmerDescription = '',
    this.farmerPhone = '',
    this.productStatus = '',
    this.purchasable = true,
    this.availabilityMessage = '',
    this.purchaseStatus = '',
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    final farmerObj = json['farmer'];
    final farmerMap = farmerObj is Map
        ? farmerObj.cast<String, dynamic>()
        : null;

    double asDouble(dynamic value, [double fallback = 0.0]) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? fallback;
    }

    int asInt(dynamic value, [int fallback = 0]) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? fallback;
    }

    final rawSaleFormats = json['saleFormats'];
    final saleFormats = rawSaleFormats is List
        ? rawSaleFormats
              .whereType<Map>()
              .map((e) => e.cast<String, dynamic>())
              .toList()
        : <Map<String, dynamic>>[];

    Map<String, dynamic>? findSaleFormat(String saleFormat) {
      for (final format in saleFormats) {
        if (format['saleFormat']?.toString().toUpperCase() == saleFormat) {
          return format;
        }
      }
      return null;
    }

    final kiloFormat = findSaleFormat('KILO');
    final boxFormat = findSaleFormat('CAJA');
    final firstFormat = saleFormats.isNotEmpty ? saleFormats.first : null;

    return Producto(
      id: json['id']?.toString() ?? '',
      version: asInt(json['version']),
      nombre: json['nombre'] ?? json['name'] ?? '',
      // Card: priceFrom | Detail/Farmer: per-format | fallback
      precio: asDouble(
        json['priceFrom'] ??
            json['precio'] ??
            json['price'] ??
            kiloFormat?['price'] ??
            boxFormat?['price'] ??
            firstFormat?['price'],
      ),
      // Card: priceUnit | Detail: per-format
      unidad:
          json['priceUnit'] ??
          json['unidad'] ??
          json['unit'] ??
          (kiloFormat != null
              ? 'Kg'
              : boxFormat != null
              ? 'Und.'
              : 'Kg'),
      pesoUnidadAprox: asDouble(
        json['pesoUnidadAprox'] ??
            json['referenceUnitWeightKg'] ??
            json['unitWeight'] ??
            kiloFormat?['referenceUnitWeightKg'] ??
            firstFormat?['referenceUnitWeightKg'] ??
            0.4,
      ),
      textoPesoUnidad:
          json['textoPesoUnidad'] ??
          json['unitWeightText'] ??
          (kiloFormat != null
              ? '1 Und. = ${asDouble(kiloFormat['referenceUnitWeightKg'], 0.4)} Kg aprox.'
              : ''),
      urlImagen: resolveMediaUrl(json['urlImagen'] ?? json['imageUrl'] ?? ''),
      // Card/Detail: 'favorite' | legacy: isFavorite/esFavorito
      esFavorito:
          json['favorite'] ?? json['esFavorito'] ?? json['isFavorite'] ?? false,
      // Card/Detail: averageRating | legacy: calificacion/rating
      calificacion: asDouble(
        json['averageRating'] ?? json['calificacion'] ?? json['rating'] ?? 0,
      ),
      cantidadResenas: asInt(
        json['cantidadResenas'] ?? json['reviewCount'] ?? 0,
      ),
      // Detail: farmer.fullName | farmerUsername | legacy fields
      nombreVendedor:
          farmerMap?['fullName']?.toString() ??
          json['farmerUsername'] ??
          json['nombreVendedor'] ??
          json['sellerName'] ??
          '',
      calificacionVendedor: asDouble(
        farmerMap?['averageRating'] ??
            json['farmerAverageRating'] ??
            json['calificacionVendedor'] ??
            json['sellerRating'] ??
            0,
      ),
      urlAvatarVendedor: resolveMediaUrl(
        farmerMap?['profileImageUrl']?.toString() ??
            json['urlAvatarVendedor'] ??
            json['sellerAvatarUrl'] ??
            '',
      ),
      farmerDescription:
          farmerMap?['description']?.toString() ??
          json['farmerDescription']?.toString() ??
          '',
      farmerPhone:
          farmerMap?['phoneNumber']?.toString() ??
          json['farmerPhone']?.toString() ??
          '',
      stockDisponible: asDouble(
        json['stockDisponible'] ??
            json['stock'] ??
            kiloFormat?['stock'] ??
            boxFormat?['stock'] ??
            firstFormat?['stock'] ??
            0,
      ),
      descripcion: json['descripcion'] ?? json['description'] ?? '',
      categoria: categoryToLabel(json['categoria'] ?? json['category'] ?? ''),
      envioGratis: json['envioGratis'] ?? json['freeShipping'] ?? false,
      ventaPorKilo:
          json['ventaPorKilo'] ?? json['sellByKg'] ?? kiloFormat != null,
      ventaPorCaja:
          json['ventaPorCaja'] ?? json['sellByBox'] ?? boxFormat != null,
      precioCaja: json['precioCaja'] != null
          ? asDouble(json['precioCaja'])
          : boxFormat?['price'] != null
          ? asDouble(boxFormat?['price'])
          : null,
      stockCaja: json['stockCaja'] != null
          ? asDouble(json['stockCaja'])
          : boxFormat?['stock'] != null
          ? asDouble(boxFormat?['stock'])
          : null,
      unidadesCajaReferencial: json['unidadesCajaReferencial'] != null
          ? asDouble(json['unidadesCajaReferencial'])
          : boxFormat?['unitsPerBox'] != null
          ? asDouble(boxFormat?['unitsPerBox'])
          : null,
      productStatus:
          json['productStatus']?.toString() ?? json['status']?.toString() ?? '',
      purchasable: json['purchasable'] as bool? ?? true,
      availabilityMessage: json['availabilityMessage']?.toString() ?? '',
      purchaseStatus: json['purchaseStatus']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'nombre': nombre,
    'precio': precio,
    'unidad': unidad,
    'pesoUnidadAprox': pesoUnidadAprox,
    'textoPesoUnidad': textoPesoUnidad,
    'urlImagen': urlImagen,
    'calificacion': calificacion,
    'cantidadResenas': cantidadResenas,
    'nombreVendedor': nombreVendedor,
    'calificacionVendedor': calificacionVendedor,
    'urlAvatarVendedor': urlAvatarVendedor,
    'stockDisponible': stockDisponible,
    'descripcion': descripcion,
    'categoria': categoria,
    'envioGratis': envioGratis,
    'ventaPorKilo': ventaPorKilo,
    'ventaPorCaja': ventaPorCaja,
    if (precioCaja != null) 'precioCaja': precioCaja,
    if (stockCaja != null) 'stockCaja': stockCaja,
    if (unidadesCajaReferencial != null)
      'unidadesCajaReferencial': unidadesCajaReferencial,
  };

  // Copia el producto modificando ciertos atributos
  Producto copiarCon({
    String? id,
    int? version,
    String? nombre,
    double? precio,
    String? unidad,
    double? pesoUnidadAprox,
    String? textoPesoUnidad,
    String? urlImagen,
    bool? esFavorito,
    double? calificacion,
    int? cantidadResenas,
    String? nombreVendedor,
    double? calificacionVendedor,
    String? urlAvatarVendedor,
    double? stockDisponible,
    String? descripcion,
    String? categoria,
    bool? envioGratis,
    bool? ventaPorKilo,
    bool? ventaPorCaja,
    double? precioCaja,
    double? stockCaja,
    double? unidadesCajaReferencial,
    String? farmerDescription,
    String? farmerPhone,
    String? productStatus,
    bool? purchasable,
    String? availabilityMessage,
    String? purchaseStatus,
  }) {
    return Producto(
      id: id ?? this.id,
      version: version ?? this.version,
      nombre: nombre ?? this.nombre,
      precio: precio ?? this.precio,
      unidad: unidad ?? this.unidad,
      pesoUnidadAprox: pesoUnidadAprox ?? this.pesoUnidadAprox,
      textoPesoUnidad: textoPesoUnidad ?? this.textoPesoUnidad,
      urlImagen: urlImagen ?? this.urlImagen,
      esFavorito: esFavorito ?? this.esFavorito,
      calificacion: calificacion ?? this.calificacion,
      cantidadResenas: cantidadResenas ?? this.cantidadResenas,
      nombreVendedor: nombreVendedor ?? this.nombreVendedor,
      calificacionVendedor: calificacionVendedor ?? this.calificacionVendedor,
      urlAvatarVendedor: urlAvatarVendedor ?? this.urlAvatarVendedor,
      stockDisponible: stockDisponible ?? this.stockDisponible,
      descripcion: descripcion ?? this.descripcion,
      categoria: categoria ?? this.categoria,
      envioGratis: envioGratis ?? this.envioGratis,
      ventaPorKilo: ventaPorKilo ?? this.ventaPorKilo,
      ventaPorCaja: ventaPorCaja ?? this.ventaPorCaja,
      precioCaja: precioCaja ?? this.precioCaja,
      stockCaja: stockCaja ?? this.stockCaja,
      unidadesCajaReferencial:
          unidadesCajaReferencial ?? this.unidadesCajaReferencial,
      farmerDescription: farmerDescription ?? this.farmerDescription,
      farmerPhone: farmerPhone ?? this.farmerPhone,
      productStatus: productStatus ?? this.productStatus,
      purchasable: purchasable ?? this.purchasable,
      availabilityMessage: availabilityMessage ?? this.availabilityMessage,
      purchaseStatus: purchaseStatus ?? this.purchaseStatus,
    );
  }
}

String resolveMediaUrl(dynamic rawValue) {
  final value = rawValue?.toString().trim() ?? '';
  if (value.isEmpty) return '';

  final baseUri = Uri.tryParse(AppConstants.baseUrl);
  final mediaUri = Uri.tryParse(value);

  if (mediaUri != null && mediaUri.hasScheme) {
    if ((mediaUri.host == 'localhost' || mediaUri.host == '127.0.0.1') &&
        baseUri != null) {
      return mediaUri
          .replace(
            scheme: baseUri.scheme,
            host: baseUri.host,
            port: baseUri.hasPort ? baseUri.port : mediaUri.port,
          )
          .toString();
    }
    return mediaUri.toString();
  }

  if (baseUri == null) return value;
  if (value.startsWith('/')) return baseUri.resolve(value).toString();
  return baseUri.resolve('/$value').toString();
}

String categoryToLabel(dynamic value) {
  final normalized = value?.toString().toUpperCase() ?? '';
  switch (normalized) {
    case 'VERDURAS':
      return 'Verduras';
    case 'FRUTAS':
      return 'Frutas';
    case 'HIERBAS':
      return 'Hierbas';
    case 'TUBERCULOS':
      return 'Tubérculos';
    case 'GRANOS_CEREALES':
      return 'Granos y cereales';
    default:
      return value?.toString() ?? '';
  }
}

String labelToCategory(String? value) {
  switch (value) {
    case 'Verduras':
      return 'VERDURAS';
    case 'Frutas':
      return 'FRUTAS';
    case 'Hierbas':
      return 'HIERBAS';
    case 'Tubérculos':
      return 'TUBERCULOS';
    case 'Granos y cereales':
      return 'GRANOS_CEREALES';
    default:
      return value?.toString().toUpperCase() ?? '';
  }
}
