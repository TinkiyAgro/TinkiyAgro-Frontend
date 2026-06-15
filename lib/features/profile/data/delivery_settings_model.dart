class ConfiguracionEntrega {
  bool ofrecePuntoRecojo;
  double costoRecojo;
  bool ofreceDelivery;
  double costoDelivery;

  ConfiguracionEntrega({
    this.ofrecePuntoRecojo = false,
    this.costoRecojo = 0.0,
    this.ofreceDelivery = false,
    this.costoDelivery = 0.0,
  });

  factory ConfiguracionEntrega.fromJson(Map<String, dynamic> json) {
    double asDouble(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;

    return ConfiguracionEntrega(
      ofrecePuntoRecojo: json['pickupEnabled'] ?? json['ofrecePuntoRecojo'] ?? false,
      costoRecojo: asDouble(json['pickupCost'] ?? json['costoRecojo'] ?? 0),
      ofreceDelivery: json['deliveryEnabled'] ?? json['ofreceDelivery'] ?? false,
      costoDelivery: asDouble(json['deliveryCost'] ?? json['costoDelivery'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() => {
    'pickupEnabled': ofrecePuntoRecojo,
    'pickupCost': costoRecojo,
    'deliveryEnabled': ofreceDelivery,
    'deliveryCost': costoDelivery,
  };
}
