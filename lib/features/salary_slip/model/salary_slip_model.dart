/// Slip gaji milik sendiri. Server hanya mengirim slip yang sudah final,
/// jadi aplikasi tidak perlu menyaring status draf.
///
/// Angka uang bisa datang sebagai string (kolom numeric di database), jadi
/// semuanya diurai lewat [_num] supaya tidak gagal di tengah jalan.
class SalarySlip {
  final String id;
  final String month;
  final String startDate;
  final String endDate;
  final String structureName;
  final String employeeName;
  final String employeeNumber;
  final String departmentName;
  final String positionTitle;
  final String bankName;
  final String bankAccountNumber;
  final int totalWorkingDays;
  final double paymentDays;
  final double lwpDays;
  final double grossPay;
  final double totalDeduction;
  final double totalEmployerContribution;
  final double netPay;
  final double roundedNetPay;
  final List<SalarySlipLine> earnings;
  final List<SalarySlipLine> deductions;
  final List<SalarySlipLine> employerContributions;

  const SalarySlip({
    required this.id,
    required this.month,
    required this.startDate,
    required this.endDate,
    this.structureName = '',
    this.employeeName = '',
    this.employeeNumber = '',
    this.departmentName = '',
    this.positionTitle = '',
    this.bankName = '',
    this.bankAccountNumber = '',
    this.totalWorkingDays = 0,
    this.paymentDays = 0,
    this.lwpDays = 0,
    this.grossPay = 0,
    this.totalDeduction = 0,
    this.totalEmployerContribution = 0,
    this.netPay = 0,
    this.roundedNetPay = 0,
    this.earnings = const [],
    this.deductions = const [],
    this.employerContributions = const [],
  });

  factory SalarySlip.fromJson(Map<String, dynamic> json) {
    final lines = json['lines'] is Map ? json['lines'] as Map : const {};
    List<SalarySlipLine> parseLines(String key) => ((lines[key] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => SalarySlipLine.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return SalarySlip(
      id: json['id'].toString(),
      month: json['month'] as String? ?? '',
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      structureName: json['structureName'] as String? ?? '',
      employeeName: json['employeeName'] as String? ?? '',
      employeeNumber: json['employeeNumber'] as String? ?? '',
      departmentName: json['departmentName'] as String? ?? '',
      positionTitle: json['positionTitle'] as String? ?? '',
      bankName: json['bankName'] as String? ?? '',
      bankAccountNumber: json['bankAccountNumber'] as String? ?? '',
      totalWorkingDays: _num(json['totalWorkingDays']).round(),
      paymentDays: _num(json['paymentDays']),
      lwpDays: _num(json['lwpDays']),
      grossPay: _num(json['grossPay']),
      totalDeduction: _num(json['totalDeduction']),
      totalEmployerContribution: _num(json['totalEmployerContribution']),
      netPay: _num(json['netPay']),
      roundedNetPay: _num(json['roundedNetPay']),
      earnings: parseLines('earnings'),
      deductions: parseLines('deductions'),
      employerContributions: parseLines('employerContributions'),
    );
  }

  /// Yang benar-benar ditransfer. Kalau pembulatan belum diisi, pakai netPay.
  double get takeHomePay => roundedNetPay != 0 ? roundedNetPay : netPay;
}

class SalarySlipLine {
  final String componentId;
  final String name;
  final String abbr;
  final String type;
  final double amount;
  final double fullAmount;
  final bool statistical;
  final bool excludedFromTotal;

  const SalarySlipLine({
    required this.componentId,
    required this.name,
    this.abbr = '',
    this.type = '',
    this.amount = 0,
    this.fullAmount = 0,
    this.statistical = false,
    this.excludedFromTotal = false,
  });

  factory SalarySlipLine.fromJson(Map<String, dynamic> json) => SalarySlipLine(
        componentId: json['componentId']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        abbr: json['abbr'] as String? ?? '',
        type: json['type'] as String? ?? '',
        amount: _num(json['amount']),
        fullAmount: _num(json['fullAmount']),
        statistical: json['statistical'] == true,
        excludedFromTotal: json['excludedFromTotal'] == true,
      );

  /// Komponen bantu perhitungan: tidak dibayarkan dan tidak masuk total.
  bool get isHelper => statistical || excludedFromTotal;
}

double _num(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}
