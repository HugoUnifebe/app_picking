class Usuario {
  final int? codigoUsuario;
  final String nome;
  final String email;
  final String? codigoBarraUsuario;
  final int? codigoTipo;
  final bool ativo;
  final DateTime? criadoEm;
  final DateTime? editadoEm;

  Usuario({
    this.codigoUsuario,
    required this.nome,
    required this.email,
    this.codigoBarraUsuario,
    this.codigoTipo,
    this.ativo = true,
    this.criadoEm,
    this.editadoEm,
  });

  Map<String, dynamic> toMap() {
    return {
      'codigo_usuario': codigoUsuario,
      'nome': nome,
      'email': email,
      'codigo_barra_usuario': codigoBarraUsuario,
      'codigo_tipo': codigoTipo,
      'ativo': ativo ? 1 : 0,
      'criado_em': criadoEm?.toIso8601String(),
      'editado_em': editadoEm?.toIso8601String(),
    };
  }

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      codigoUsuario: map['codigo_usuario'],
      nome: map['nome'],
      email: map['email'],
      codigoBarraUsuario: map['codigo_barra_usuario'],
      codigoTipo: map['codigo_tipo'],
      ativo: map['ativo'] == 1,
      criadoEm: map['criado_em'] != null ? DateTime.parse(map['criado_em']) : null,
      editadoEm: map['editado_em'] != null ? DateTime.parse(map['editado_em']) : null,
    );
  }
}
