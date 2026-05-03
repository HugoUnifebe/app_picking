class Caixa {
  final int? codigoCaixa;
  final String nomeCaixa;
  final int? codigoStatusCaixa;
  final String localizacao;
  final DateTime? criadoEm;
  final DateTime? editadoEm;

  Caixa({
    this.codigoCaixa,
    required this.nomeCaixa,
    this.codigoStatusCaixa,
    required this.localizacao,
    this.criadoEm,
    this.editadoEm,
  });

  Map<String, dynamic> toMap() {
    return {
      'codigo_caixa': codigoCaixa,
      'nome_caixa': nomeCaixa,
      'codigo_status_caixa': codigoStatusCaixa,
      'localizacao': localizacao,
      'criado_em': criadoEm?.toIso8601String(),
      'editado_em': editadoEm?.toIso8601String(),
    };
  }

  factory Caixa.fromMap(Map<String, dynamic> map) {
    return Caixa(
      codigoCaixa: map['codigo_caixa'],
      nomeCaixa: map['nome_caixa'] ?? '',
      codigoStatusCaixa: map['codigo_status_caixa'],
      localizacao: map['localizacao'] ?? '',
      criadoEm: map['criado_em'] != null ? DateTime.parse(map['criado_em']) : null,
      editadoEm: map['editado_em'] != null ? DateTime.parse(map['editado_em']) : null,
    );
  }
}
