class Usuario {
  final int? codigoUsuario;
  final String? nome;
  final String? email;
  final String? codigoBarraUsuario;
  final int? codigoTipo;
  final int? ativo; // 0 ou 1 para o SQLite
  final String? criadoEm;
  final String? editadoEm;

  Usuario({
    this.codigoUsuario,
    this.nome,
    this.email,
    this.codigoBarraUsuario,
    this.codigoTipo,
    this.ativo = 1,
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
      'ativo': ativo,
      'criado_em': criadoEm,
      'editado_em': editadoEm,
    };
  }

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      codigoUsuario: map['codigo_usuario'],
      nome: map['nome'],
      email: map['email'],
      codigoBarraUsuario: map['codigo_barra_usuario'],
      codigoTipo: map['codigo_tipo'],
      ativo: map['ativo'],
      criadoEm: map['criado_em'],
      editadoEm: map['editado_em'],
    );
  }
}
