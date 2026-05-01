class ProdutoPedido {
  final int? codigoProdutoPedido;
  final int codigoPedido;
  final int codigoProduto;
  final int codigoStatusProdutoPedido;

  ProdutoPedido({
    this.codigoProdutoPedido,
    required this.codigoPedido,
    required this.codigoProduto,
    required this.codigoStatusProdutoPedido,
  });

  Map<String, dynamic> toMap() {
    return {
      'codigo_produto_pedido': codigoProdutoPedido,
      'codigo_pedido': codigoPedido,
      'codigo_produto': codigoProduto,
      'codigo_status_produto_pedido': codigoStatusProdutoPedido,
    };
  }

  factory ProdutoPedido.fromMap(Map<String, dynamic> map) {
    return ProdutoPedido(
      codigoProdutoPedido: map['codigo_produto_pedido'],
      codigoPedido: map['codigo_pedido'],
      codigoProduto: map['codigo_produto'],
      codigoStatusProdutoPedido: map['codigo_status_produto_pedido'],
    );
  }
}
