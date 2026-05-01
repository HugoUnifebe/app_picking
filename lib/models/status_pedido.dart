class StatusPedido {
  final int? codigoStatusPedido;
  final String descricao;
  final String corHex;

  StatusPedido({
    this.codigoStatusPedido,
    required this.descricao,
    required this.corHex,
  });

  Map<String, dynamic> toMap() {
    return {
      'codigo_status_pedido': codigoStatusPedido,
      'descricao': descricao,
      'cor_hex': corHex,
    };
  }

  factory StatusPedido.fromMap(Map<String, dynamic> map) {
    return StatusPedido(
      codigoStatusPedido: map['codigo_status_pedido'],
      descricao: map['descricao'],
      corHex: map['cor_hex'],
    );
  }
}
