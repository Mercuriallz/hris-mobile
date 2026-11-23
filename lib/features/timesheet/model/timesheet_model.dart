/// Satu catatan kerja harian. Cermin dari TimesheetRow di backend.
class TimesheetActivity {
  final String id;
  final String employeeName;
  final String? departmentName;
  final String title;
  final String? output;
  final String workDate; // YYYY-MM-DD
  final String startTime; // HH:mm
  final String endTime;
  final int durationMinutes;
  final String shiftMode; // shift | non_shift
  final String workLocation;
  final String workType;
  final String? approvedBy;
  final String visibility; // private | team | all

  const TimesheetActivity({
    required this.id,
    required this.employeeName,
    required this.departmentName,
    required this.title,
    required this.output,
    required this.workDate,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.shiftMode,
    required this.workLocation,
    required this.workType,
    required this.approvedBy,
    required this.visibility,
  });

  factory TimesheetActivity.fromJson(Map<String, dynamic> j) => TimesheetActivity(
        id: j['id'] as String,
        employeeName: (j['employeeName'] ?? '') as String,
        departmentName: j['departmentName'] as String?,
        title: (j['title'] ?? '') as String,
        output: j['output'] as String?,
        workDate: (j['workDate'] ?? '') as String,
        startTime: (j['startTime'] ?? '') as String,
        endTime: (j['endTime'] ?? '') as String,
        durationMinutes: (j['durationMinutes'] as num?)?.toInt() ?? 0,
        shiftMode: (j['shiftMode'] ?? 'non_shift') as String,
        workLocation: (j['workLocation'] ?? '') as String,
        workType: (j['workType'] ?? '') as String,
        approvedBy: j['approvedBy'] as String?,
        visibility: (j['visibility'] ?? 'private') as String,
      );
}

class TimesheetPageData {
  final List<TimesheetActivity> rows;
  final int page;
  final int totalPages;
  final int total;

  const TimesheetPageData(this.rows, this.page, this.totalPages, this.total);

  factory TimesheetPageData.fromJson(Map<String, dynamic> data) {
    final meta = (data['meta'] as Map?) ?? const {};
    return TimesheetPageData(
      ((data['data'] as List?) ?? const [])
          .map((e) => TimesheetActivity.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      (meta['page'] as num?)?.toInt() ?? 1,
      (meta['totalPages'] as num?)?.toInt() ?? 1,
      (meta['total'] as num?)?.toInt() ?? 0,
    );
  }
}

class TimesheetOptions {
  final List<String> workLocations;
  final List<String> workTypes;
  final List<String> approverSuggestions;

  const TimesheetOptions(this.workLocations, this.workTypes, this.approverSuggestions);

  factory TimesheetOptions.fromJson(Map<String, dynamic> j) => TimesheetOptions(
        List<String>.from((j['workLocations'] as List?) ?? const []),
        List<String>.from((j['workTypes'] as List?) ?? const []),
        ((j['approverSuggestions'] as List?) ?? const [])
            .map((e) => (e as Map)['name'] as String)
            .toList(),
      );
}

/// Jumlah aktivitas per bulan (12 angka) untuk tahun ini dan tahun lalu.
class TimesheetSeries {
  final List<int> previous;
  final List<int> current;
  const TimesheetSeries(this.previous, this.current);

  factory TimesheetSeries.fromJson(Map<String, dynamic> j) => TimesheetSeries(
        List<int>.from(((j['previous'] as List?) ?? List.filled(12, 0)).map((e) => (e as num).toInt())),
        List<int>.from(((j['current'] as List?) ?? List.filled(12, 0)).map((e) => (e as num).toInt())),
      );
}

/// Total aktivitas satu anggota departemen, tahun ini dan tahun lalu.
class TimesheetMemberTotal {
  final String name;
  final int current;
  final int previous;
  const TimesheetMemberTotal(this.name, this.current, this.previous);

  factory TimesheetMemberTotal.fromJson(Map<String, dynamic> j) => TimesheetMemberTotal(
        (j['name'] ?? '') as String,
        (j['current'] as num?)?.toInt() ?? 0,
        (j['previous'] as num?)?.toInt() ?? 0,
      );
}

class TimesheetDashboardData {
  final int year;
  final TimesheetSeries summary;
  final TimesheetSeries mine;
  final TimesheetSeries? department;
  final List<TimesheetMemberTotal> team;

  const TimesheetDashboardData(this.year, this.summary, this.mine, this.department, [this.team = const []]);

  factory TimesheetDashboardData.fromJson(Map<String, dynamic> j) => TimesheetDashboardData(
        (j['year'] as num).toInt(),
        TimesheetSeries.fromJson(Map<String, dynamic>.from(j['summary'] as Map)),
        TimesheetSeries.fromJson(Map<String, dynamic>.from(j['mine'] as Map)),
        j['department'] == null ? null : TimesheetSeries.fromJson(Map<String, dynamic>.from(j['department'] as Map)),
        ((j['team'] as List?) ?? const [])
            .map((e) => TimesheetMemberTotal.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

/// Isi satu baris formulir.
class TimesheetDraft {
  String title = '';
  String output = '';
  DateTime date = DateTime.now();
  int startMinutes;
  int endMinutes;
  String shiftMode = 'non_shift';
  String workLocation;
  String workType;
  String approvedBy = '';
  String visibility = 'private';

  /// Bawaan: satu jam terakhir. Jam mulai dan selesai yang sama (bawaan
  /// lama) membuat formulir baru langsung tidak valid.
  TimesheetDraft({required this.workLocation, required this.workType})
      : startMinutes = _defaultStart(),
        endMinutes = _defaultEnd();

  static int _defaultEnd() {
    final n = DateTime.now();
    final m = n.hour * 60 + n.minute;
    return m < 1 ? 1 : m;
  }

  static int _defaultStart() {
    final end = _defaultEnd();
    return end >= 60 ? end - 60 : 0;
  }

  int get durationMinutes => endMinutes - startMinutes;
  bool get timeValid => endMinutes > startMinutes;

  factory TimesheetDraft.from(TimesheetActivity a) {
    int mins(String t) => int.parse(t.substring(0, 2)) * 60 + int.parse(t.substring(3, 5));
    final d = TimesheetDraft(workLocation: a.workLocation, workType: a.workType)
      ..title = a.title
      ..output = a.output ?? ''
      ..date = DateTime.parse(a.workDate)
      ..startMinutes = mins(a.startTime)
      ..endMinutes = mins(a.endTime)
      ..shiftMode = a.shiftMode
      ..approvedBy = a.approvedBy ?? ''
      ..visibility = a.visibility;
    return d;
  }

  static String hhmm(int m) =>
      '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson({double? lat, double? lng}) => {
        'title': title.trim(),
        if (output.trim().isNotEmpty) 'output': output.trim(),
        'workDate':
            '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'startTime': hhmm(startMinutes),
        'endTime': hhmm(endMinutes),
        'shiftMode': shiftMode,
        'workLocation': workLocation,
        'workType': workType,
        if (approvedBy.trim().isNotEmpty) 'approvedBy': approvedBy.trim(),
        'visibility': visibility,
        'latitude': ?lat,
        'longitude': ?lng,
      };
}
