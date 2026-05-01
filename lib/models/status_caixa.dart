class StatusCaixa {
  final int? codigoStatusCaixa;
  final String descricao;
  final String corHex;

  StatusCaixa({
    this.codigoStatusCaixa,
    required this.descricao,
    required this.corHex,
  });

  Map<String, dynamic> toMap() {
    return {
      'codigo_status_caixa': codigoStatusCaixa,
      'descricao': descricao,
      'cor_hex': corHex,
    };
  }

  factory StatusCaixa.fromMap(Map<String, dynamic> map) {
    return StatusCaixa(
      codigoStatusCaixa: map['codigo_status_caixa'],
      descricao: map['descricao'],
      corHex: map['cor_hex'],
    );
  }
}
