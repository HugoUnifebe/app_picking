class Log {
  final int? codigoLog;
  final int codigoUsuario;
  final String acao;
  final String detalhes;
  final DateTime? criadoEm;

  Log({
    this.codigoLog,
    required this.codigoUsuario,
    required this.acao,
    required this.detalhes,
    this.criadoEm,
  });

  Map<String, dynamic> toMap() {
    return {
      'codigo_log': codigoLog,
      'codigo_usuario': codigoUsuario,
      'acao': acao,
      'detalhes': detalhes,
      'criado_em': criadoEm?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  factory Log.fromMap(Map<String, dynamic> map) {
    return Log(
      codigoLog: map['codigo_log'],
      codigoUsuario: map['codigo_usuario'],
      acao: map['acao'],
      detalhes: map['detalhes'],
      criadoEm: map['criado_em'] != null ? DateTime.tryParse(map['criado_em']) : null,
    );
  }
}
