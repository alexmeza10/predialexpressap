class Adeudo {
  String anio;
  String bim;
  String impuesto;
  String actualizacion;
  String recargos;
  String gastosNot;
  String gastosEjec;
  String multas;
  String prontoPago;
  String descRecarg;
  String descMulta;
  String acumulado;
  String idPredio;
  String cuenta;
  String curt;
  String propietario;
  String domicilio;
  String valFiscal;
  String edoEdificacion;
  String bimestredesde;
  String opd;
  String seguro;

  Adeudo({
    required this.anio,
    required this.bim,
    required this.impuesto,
    required this.actualizacion,
    required this.recargos,
    required this.gastosNot,
    required this.gastosEjec,
    required this.multas,
    required this.prontoPago,
    required this.descRecarg,
    required this.descMulta,
    required this.acumulado,
    required this.idPredio,
    required this.cuenta,
    required this.curt,
    required this.propietario,
    required this.domicilio,
    required this.valFiscal,
    required this.edoEdificacion,
    required this.bimestredesde,
    required this.opd,
    required this.seguro,
  });

  factory Adeudo.fromJson(Map<String, dynamic> json) {
    return Adeudo(
      anio: json['ANIO'].toString(),
      bim: json['BIM'].toString(),
      impuesto: json['IMPUESTO'].toString(),
      actualizacion: json['ACTUALIZACION'].toString(),
      recargos: json['RECARGOS'].toString(),
      gastosNot: json['GASTOS_NOT'].toString(),
      gastosEjec: json['GASTOS_EJEC'].toString(),
      multas: json['MULTAS'].toString(),
      prontoPago: json['PRONTO_PAGO'].toString(),
      descRecarg: json['DESC_RECARG'].toString(),
      descMulta: json['DESC_MULTA'].toString(),
      acumulado: json['ACUMULADO'].toString(),
      idPredio: json['ID_PREDIO'].toString(),
      cuenta: json['CUENTA'].toString(),
      curt: json['CURT'].toString(),
      propietario: json['PROPIETARIO'].toString(),
      domicilio: json['DOMICILIO'].toString(),
      valFiscal: json['VAL_FISCAL'].toString(),
      edoEdificacion: json['EDO_EDIFICACION'].toString(),
      bimestredesde: json['BIMESTRE_DESDE'].toString(),
      opd: json['OPD'].toString(),
      seguro: json['SEGURO'].toString(),
    );
  }

  get bimestreDesde => null;

  Map<String, dynamic> toMap() {
    return {
      'ANIO': anio,
      'BIM': bim,
      'IMPUESTO': impuesto,
      'ACTUALIZACION': actualizacion,
      'RECARGOS': recargos,
      'GASTOS_NOT': gastosNot,
      'GASTOS_EJEC': gastosEjec,
      'MULTAS': multas,
      'PRONTO_PAGO': prontoPago,
      'DESC_RECARG': descRecarg,
      'DESC_MULTA': descMulta,
      'ACUMULADO': acumulado,
      'ID_PREDIO': idPredio,
      'CUENTA': cuenta,
      'CURT': curt,
      'PROPIETARIO': propietario,
      'DOMICILIO': domicilio,
      'VAL_FISCAL': valFiscal,
      'EDO_EDIFICACION': edoEdificacion,
      'BIMESTRE_DESDE': '$anio-$bim',
      'OPD': opd,
      'SEGURO': seguro,
    };
  }
}
