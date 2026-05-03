class Produto {
  final int? codigoProduto;
  final String nomeProduto;
  final String? codigoBarraProduto;
  final String sku;
  final String cor;
  final String tamanho;
  final int quantidadeDisponivel;
  final String variacao;
  final String localizacao;

  Produto({
    this.codigoProduto,
    required this.nomeProduto,
    this.codigoBarraProduto,
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
      'nome_produto': nomeProduto,
      'codigo_barra_produto': codigoBarraProduto,
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
      nomeProduto: map['nome_produto'] ?? '',
      codigoBarraProduto: map['codigo_barra_produto'],
      sku: map['sku'] ?? '',
      cor: map['cor'] ?? '',
      tamanho: map['tamanho'] ?? '',
      quantidadeDisponivel: map['quantidade_disponivel'] ?? 0,
      variacao: map['variacao'] ?? '',
      localizacao: map['localizacao'] ?? '',
    );
  }
}
