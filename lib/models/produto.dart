class Produto {
  final int? codigoProduto;
  final String sku;
  final String cor;
  final String tamanho;
  final int quantidadeDisponivel;
  final String variacao;
  final String localizacao;

  Produto({
    this.codigoProduto,
    required this.sku,
    required this.cor,
    required this.tamanho,
    required this.quantidadeDisponivel,
    required this.variacao,
    required this.localizacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'codigo_produto': codigoProduto,
      'sku': sku,
      'cor': cor,
      'tamanho': tamanho,
      'quantidade_disponivel': quantidadeDisponivel,
      'variacao': variacao,
      'localizacao': localizacao,
    };
  }

  factory Produto.fromMap(Map<String, dynamic> map) {
    return Produto(
      codigoProduto: map['codigo_produto'],
      sku: map['sku'],
      cor: map['cor'],
      tamanho: map['tamanho'],
      quantidadeDisponivel: map['quantidade_disponivel'],
      variacao: map['variacao'],
      localizacao: map['localizacao'],
    );
  }
}
