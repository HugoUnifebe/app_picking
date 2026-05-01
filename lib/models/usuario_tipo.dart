class UsuarioTipo {
  final int? codigoTipo;
  final String nome;

  UsuarioTipo({this.codigoTipo, required this.nome});

  Map<String, dynamic> toMap() {
    return {
      'codigo_tipo': codigoTipo,
      'nome': nome,
    };
  }

  factory UsuarioTipo.fromMap(Map<String, dynamic> map) {
    return UsuarioTipo(
      codigoTipo: map['codigo_tipo'],
      nome: map['nome'],
    );
  }
}
