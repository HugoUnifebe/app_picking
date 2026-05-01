class Pedido {
  final int? codigoPedido;
  final int? codigoUsuarioResponsavel;
  final int? codigoStatusPedido;
  final DateTime? criadoEm;
  final DateTime? editadoEm;

  Pedido({
    this.codigoPedido,
    this.codigoUsuarioResponsavel,
    this.codigoStatusPedido,
    this.criadoEm,
    this.editadoEm,
  });

  Map<String, dynamic> toMap() {
    return {
      'codigo_pedido': codigoPedido,
      'codigo_usuario_responsavel': codigoUsuarioResponsavel,
      'codigo_status_pedido': codigoStatusPedido,
      'criado_em': criadoEm?.toIso8601String(),
      'editado_em': editadoEm?.toIso8601String(),
    };
  }

  factory Pedido.fromMap(Map<String, dynamic> map) {
    return Pedido(
      codigoPedido: map['codigo_pedido'],
      codigoUsuarioResponsavel: map['codigo_usuario_responsavel'],
      codigoStatusPedido: map['codigo_status_pedido'],
      criadoEm: map['criado_em'] != null ? DateTime.parse(map['criado_em']) : null,
      editadoEm: map['editado_em'] != null ? DateTime.parse(map['editado_em']) : null,
    );
  }
}
