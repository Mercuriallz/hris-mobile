import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../constant/theme/app_color.dart';
import '../../../constant/theme/app_text.dart';
import '../../../helper/location_helper.dart';
import '../model/timesheet_model.dart';
import '../repository/timesheet_repository.dart';
import 'timesheet_widgets.dart';

/// Formulir catatan kerja. Bisa memuat beberapa aktivitas sekaligus; saat
/// mengubah satu catatan hanya ada satu.
class TimesheetFormPage extends StatefulWidget {
  final TimesheetActivity? editing;

  /// Pembaca lokasi. Bisa diganti untuk uji; bawaannya GPS perangkat.
  final Future<LocationReading> Function()? readLocation;

  const TimesheetFormPage({super.key, this.editing, this.readLocation});

  @override
  State<TimesheetFormPage> createState() => _TimesheetFormPageState();
}

class _TimesheetFormPageState extends State<TimesheetFormPage> {
  final _repo = TimesheetRepository();
  TimesheetOptions? _options;
  final List<TimesheetDraft> _drafts = [];
  double? _lat;
  double? _lng;
  bool _locating = true;
  String? _loadError;
  String? _error;
  bool _saving = false;

  bool get _editing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  TimesheetDraft _blank(TimesheetOptions o) => TimesheetDraft(
        workLocation: o.workLocations.isNotEmpty ? o.workLocations.first : '',
        workType: o.workTypes.isNotEmpty ? o.workTypes.first : '',
      );

  Future<void> _load() async {
    setState(() => _loadError = null);
    final res = await _repo.options();
    if (!mounted) return;
    res.fold((l) => setState(() => _loadError = l), (o) {
      setState(() {
        _options = o;
        if (_drafts.isEmpty) _drafts.add(_editing ? TimesheetDraft.from(widget.editing!) : _blank(o));
      });
    });
    // Lokasi opsional: gagal membacanya tidak boleh menghalangi pencatatan.
    try {
      final r = await (widget.readLocation ?? LocationService().read)();
      if (mounted) {
        setState(() {
          _lat = r.latitude;
          _lng = r.longitude;
        });
      }
    } catch (_) {
      // dibiarkan: kartu lokasi menampilkan "tidak tersedia"
    }
    if (mounted) setState(() => _locating = false);
  }

  String? _validate() {
    for (var i = 0; i < _drafts.length; i++) {
      final d = _drafts[i];
      final n = _drafts.length > 1 ? 'Aktivitas ${i + 1}: ' : '';
      if (d.title.trim().isEmpty) return '${n}Isi dulu apa yang dikerjakan.';
      if (!d.timeValid) return '${n}Jam selesai harus setelah jam mulai.';
    }
    return null;
  }

  Future<void> _submit() async {
    final problem = _validate();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final payload = _drafts.map((d) => d.toJson(lat: _lat, lng: _lng)).toList();
    final res = _editing
        ? await _repo.update(widget.editing!.id, payload.first)
        : await _repo.create(payload);
    if (!mounted) return;
    res.fold(
      (l) => setState(() {
        _error = l;
        _saving = false;
      }),
      (_) => Navigator.pop(context, true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final o = _options;
    final count = _drafts.length;

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(title: Text(_editing ? 'Ubah aktivitas' : 'Catat aktivitas')),
      body: _loadError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_loadError!, textAlign: TextAlign.center, style: AppText.body),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _load,
                    style: OutlinedButton.styleFrom(minimumSize: const Size(140, 44)),
                    child: const Text('Coba lagi'),
                  ),
                ]),
              ),
            )
          : o == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    _LocationNote(locating: _locating, lat: _lat, lng: _lng),
                    const SizedBox(height: 14),
                    for (var i = 0; i < count; i++) ...[
                      _DraftCard(
                        key: ObjectKey(_drafts[i]),
                        index: i,
                        total: count,
                        draft: _drafts[i],
                        options: o,
                        onChanged: () => setState(() => _error = null),
                        onRemove: count > 1 ? () => setState(() => _drafts.removeAt(i)) : null,
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (!_editing && count < 20)
                      OutlinedButton.icon(
                        onPressed: () => setState(() => _drafts.add(_blank(o))),
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('Tambah aktivitas lain'),
                      ),
                  ],
                ),
      bottomNavigationBar: o == null
          ? null
          : Container(
              decoration: BoxDecoration(
                color: AppColor.surface,
                border: Border(top: BorderSide(color: AppColor.border)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_error != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColor.dangerSurface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.error_outline, size: 18, color: AppColor.danger),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_error!, style: AppText.caption.copyWith(color: AppColor.danger))),
                            ],
                          ),
                        ),
                      FilledButton(
                        onPressed: _saving ? null : _submit,
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(_editing
                                ? 'Simpan perubahan'
                                : count > 1
                                    ? 'Simpan $count aktivitas'
                                    : 'Simpan aktivitas'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _LocationNote extends StatelessWidget {
  final bool locating;
  final double? lat;
  final double? lng;
  const _LocationNote({required this.locating, required this.lat, required this.lng});

  @override
  Widget build(BuildContext context) {
    final ok = lat != null;
    final bg = ok ? AppColor.successSurface : AppColor.background;
    final fg = ok ? AppColor.success : AppColor.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ok ? bg : AppColor.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ok ? Colors.transparent : AppColor.border),
      ),
      child: Row(
        children: [
          locating
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(ok ? Icons.my_location : Icons.location_off_outlined, size: 18, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              locating
                  ? 'Membaca lokasi Anda…'
                  : ok
                      ? 'Lokasi tercatat (${lat!.toStringAsFixed(4)}, ${lng!.toStringAsFixed(4)})'
                      : 'Lokasi tidak tersedia. Aktivitas tetap bisa disimpan.',
              style: AppText.caption.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftCard extends StatefulWidget {
  final int index;
  final int total;
  final TimesheetDraft draft;
  final TimesheetOptions options;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  const _DraftCard({
    super.key,
    required this.index,
    required this.total,
    required this.draft,
    required this.options,
    required this.onChanged,
    this.onRemove,
  });

  @override
  State<_DraftCard> createState() => _DraftCardState();
}

class _DraftCardState extends State<_DraftCard> {
  late final _title = TextEditingController(text: widget.draft.title);
  late final _output = TextEditingController(text: widget.draft.output);
  late final _approver = TextEditingController(text: widget.draft.approvedBy);

  TimesheetDraft get d => widget.draft;

  @override
  void dispose() {
    _title.dispose();
    _output.dispose();
    _approver.dispose();
    super.dispose();
  }

  void _set(VoidCallback fn) {
    setState(fn);
    widget.onChanged();
  }

  DateTime get _today => DateUtils.dateOnly(DateTime.now());
  bool get _isToday => DateUtils.isSameDay(d.date, _today);

  Future<void> _pickTime(bool start) async {
    final cur = start ? d.startMinutes : d.endMinutes;
    final p = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: cur ~/ 60, minute: cur % 60),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (p == null) return;
    _set(() {
      final m = p.hour * 60 + p.minute;
      if (start) {
        d.startMinutes = m;
      } else {
        d.endMinutes = m;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.options;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.total > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(children: [
                  Expanded(child: Text('AKTIVITAS ${widget.index + 1}', style: AppText.label)),
                  if (widget.onRemove != null)
                    TextButton.icon(
                      onPressed: widget.onRemove,
                      style: TextButton.styleFrom(foregroundColor: AppColor.danger, visualDensity: VisualDensity.compact),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Hapus'),
                    ),
                ]),
              ),

            _Label('Apa yang dikerjakan?', required: true),
            TextField(
              controller: _title,
              maxLength: 500,
              minLines: 1,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Mis. Menyusun laporan mingguan', counterText: ''),
              onChanged: (v) {
                d.title = v;
                widget.onChanged();
              },
            ),
            const SizedBox(height: 12),
            _Label('Hasil / output'),
            TextField(
              controller: _output,
              maxLength: 500,
              minLines: 1,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Opsional, mis. Laporan PDF', counterText: ''),
              onChanged: (v) => d.output = v,
            ),

            const _Divider(),
            _Label('Kapan?'),
            // Aktivitas hanya boleh dicatat untuk hari ini (aturan server), jadi tanggal tidak bisa diubah.
            Wrap(spacing: 8, runSpacing: 8, children: [
              _Choice(
                label: _isToday ? 'Hari ini' : DateFormat('d MMM yyyy', 'id_ID').format(d.date),
                icon: Icons.calendar_today_outlined,
                selected: true,
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 6),
            Text('Hanya bisa dicatat untuk hari ini.', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _TimeTile(label: 'Mulai', value: TimesheetDraft.hhmm(d.startMinutes), onTap: () => _pickTime(true))),
              const SizedBox(width: 10),
              Expanded(child: _TimeTile(label: 'Selesai', value: TimesheetDraft.hhmm(d.endMinutes), onTap: () => _pickTime(false))),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Icon(
                d.timeValid ? Icons.timelapse : Icons.error_outline,
                size: 16,
                color: d.timeValid ? AppColor.textSecondary : AppColor.danger,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  d.timeValid ? 'Durasi ${formatDuration(d.durationMinutes)}' : 'Jam selesai harus setelah jam mulai',
                  style: AppText.caption.copyWith(color: d.timeValid ? AppColor.textSecondary : AppColor.danger),
                ),
              ),
            ]),

            const _Divider(),
            _Label('Jam kerja'),
            _TwoWay(
              leftLabel: 'Non-shift',
              rightLabel: 'Shift',
              rightSelected: d.shiftMode == 'shift',
              onChanged: (right) => _set(() => d.shiftMode = right ? 'shift' : 'non_shift'),
            ),
            const SizedBox(height: 14),
            _Label('Lokasi kerja'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final l in o.workLocations)
                _Choice(label: l, selected: d.workLocation == l, onTap: () => _set(() => d.workLocation = l)),
            ]),
            const SizedBox(height: 14),
            _Label('Jenis pekerjaan'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final t in o.workTypes)
                _Choice(label: t, selected: d.workType == t, onTap: () => _set(() => d.workType = t)),
            ]),

            const _Divider(),
            _Label('Disetujui oleh'),
            TextField(
              controller: _approver,
              maxLength: 255,
              decoration: const InputDecoration(hintText: 'Opsional, nama atasan', counterText: ''),
              onChanged: (v) {
                d.approvedBy = v;
                setState(() {});
              },
            ),
            if (o.approverSuggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final s in o.approverSuggestions)
                  _Choice(
                    label: s,
                    icon: Icons.person_outline,
                    selected: d.approvedBy == s,
                    onTap: () => _set(() {
                      d.approvedBy = s;
                      _approver.text = s;
                    }),
                  ),
              ]),
            ],

            const _Divider(),
            _Label('Siapa yang boleh melihat?'),
            for (final v in const ['private', 'team', 'all']) ...[
              _VisibilityTile(
                value: v,
                selected: d.visibility == v,
                onTap: () => _set(() => d.visibility = v),
              ),
              if (v != 'all') const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final bool required;
  const _Label(this.text, {this.required = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text.rich(TextSpan(children: [
        TextSpan(text: text, style: AppText.bodyStrong),
        if (required) TextSpan(text: ' *', style: AppText.bodyStrong.copyWith(color: AppColor.danger)),
      ])),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Divider(color: AppColor.border, height: 1));
}

/// Pilihan tunggal berbentuk pil (lokasi, jenis, tanggal, penyetuju).
class _Choice extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _Choice({required this.label, this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColor.primarySurface : AppColor.surface,
      shape: StadiumBorder(side: BorderSide(color: selected ? AppColor.primary : AppColor.border, width: selected ? 1.5 : 1)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: selected ? AppColor.primary : AppColor.textSecondary),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.bodyStrong.copyWith(
                  fontSize: 13,
                  color: selected ? AppColor.primary : AppColor.textPrimary,
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _TimeTile({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColor.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: AppText.label),
            const SizedBox(height: 2),
            Row(children: [
              Text(value, style: AppText.h2.copyWith(fontSize: 20, fontFeatures: const [FontFeature.tabularFigures()])),
              const Spacer(),
              Icon(Icons.schedule, size: 18, color: AppColor.textSecondary),
            ]),
          ],
        ),
      ),
    );
  }
}

class _TwoWay extends StatelessWidget {
  final String leftLabel;
  final String rightLabel;
  final bool rightSelected;
  final ValueChanged<bool> onChanged;

  const _TwoWay({required this.leftLabel, required this.rightLabel, required this.rightSelected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget seg(String text, bool selected, VoidCallback tap) => Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: tap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColor.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                text,
                style: AppText.bodyStrong.copyWith(
                  fontSize: 13,
                  color: selected ? Colors.white : AppColor.textSecondary,
                ),
              ),
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColor.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.border),
      ),
      child: Row(children: [
        seg(leftLabel, !rightSelected, () => onChanged(false)),
        seg(rightLabel, rightSelected, () => onChanged(true)),
      ]),
    );
  }
}

class _VisibilityTile extends StatelessWidget {
  final String value;
  final bool selected;
  final VoidCallback onTap;
  const _VisibilityTile({required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final v = visibilityInfo(value);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColor.primarySurface : AppColor.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColor.primary : AppColor.border, width: selected ? 1.5 : 1),
        ),
        child: Row(children: [
          Icon(v.icon, size: 20, color: selected ? AppColor.primary : AppColor.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(v.label, style: AppText.bodyStrong),
                Text(v.hint, style: AppText.caption),
              ],
            ),
          ),
          Icon(
            selected ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 20,
            color: selected ? AppColor.primary : AppColor.textDisabled,
          ),
        ]),
      ),
    );
  }
}
