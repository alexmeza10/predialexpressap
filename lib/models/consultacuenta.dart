class Cuenta {
  int? idConsulta;
  String? observaciones;
  dynamic adeudo;

  Cuenta({this.idConsulta, this.observaciones, this.adeudo});

  factory Cuenta.fromJson(Map<String, dynamic> json) {
    return Cuenta(
      idConsulta: int.tryParse(json['idConsulta']),
      observaciones: json['observaciones'],
      adeudo: json['adeudo'] ?? [],
    );
  }
}
