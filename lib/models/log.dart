class Log {
  final int? codigoLog;
  final int codigoUsuario;

  Log({this.codigoLog, required this.codigoUsuario});

  Map<String, dynamic> toMap() {
    return {
      'codigo_log': codigoLog,
      'codigo_usuario': codigoUsuario,
    };
  }

  factory Log.fromMap(Map<String, dynamic> map) {
    return Log(
      codigoLog: map['codigo_log'],
      codigoUsuario: map['codigo_usuario'],
    );
  }
}
