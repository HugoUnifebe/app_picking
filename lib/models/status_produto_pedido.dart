class StatusProdutoPedido {
  final int? codigoStatusProdutoPedido;
  final String descricao;
  final String corHex;

  StatusProdutoPedido({
    this.codigoStatusProdutoPedido,
    required this.descricao,
    required this.corHex,
  });

  Map<String, dynamic> toMap() {
    return {
      'codigo_status_produto_pedido': codigoStatusProdutoPedido,
      'descricao': descricao,
      'cor_hex': corHex,
    };
  }

  factory StatusProdutoPedido.fromMap(Map<String, dynamic> map) {
    return StatusProdutoPedido(
      codigoStatusProdutoPedido: map['codigo_status_produto_pedido'],
      descricao: map['descricao'],
      corHex: map['cor_hex'],
    );
  }
}
