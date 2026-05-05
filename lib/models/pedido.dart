class Pedido {
  final int? codigoPedido;
  final int? codigoUsuarioResponsavel;
  final String? codigoBarraCaixa;
  final int? codigoStatusPedido;
  final DateTime? criadoEm;
  final DateTime? editadoEm;
  final DateTime? finalizadoEm;

  Pedido({
    this.codigoPedido,
    this.codigoUsuarioResponsavel,
    this.codigoBarraCaixa,
    this.codigoStatusPedido,
    this.criadoEm,
    this.editadoEm,
    this.finalizadoEm,
  });

  Map<String, dynamic> toMap() {
    return {
      'codigo_pedido': codigoPedido,
      'codigo_usuario_responsavel': codigoUsuarioResponsavel,
      'codigo_barra_caixa': codigoBarraCaixa,
      'codigo_status_pedido': codigoStatusPedido,
      'criado_em': criadoEm?.toIso8601String(),
      'editado_em': editadoEm?.toIso8601String(),
      'finalizado_em': finalizadoEm?.toIso8601String(),
    };
  }

  factory Pedido.fromMap(Map<String, dynamic> map) {
    return Pedido(
      codigoPedido: map['codigo_pedido'],
      codigoUsuarioResponsavel: map['codigo_usuario_responsavel'],
      codigoBarraCaixa: map['codigo_barra_caixa'],
      codigoStatusPedido: map['codigo_status_pedido'],
      criadoEm: map['criado_em'] != null ? DateTime.tryParse(map['criado_em'].toString()) : null,
      editadoEm: map['editado_em'] != null ? DateTime.tryParse(map['editado_em'].toString()) : null,
      finalizadoEm: map['finalizado_em'] != null ? DateTime.tryParse(map['finalizado_em'].toString()) : null,
    );
  }
}
