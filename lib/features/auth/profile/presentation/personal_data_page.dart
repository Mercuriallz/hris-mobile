import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../constant/theme/app_color.dart';
import '../../../../constant/theme/app_text.dart';
import '../../../../constant/theme/app_widget.dart';
import '../cubit/my_profile_cubit.dart';
import '../cubit/my_profile_state.dart';
import '../model/my_profile_model.dart';
import 'personal_data_format.dart';

/// Data diri lengkap, hanya-baca. Isinya sama dengan halaman Profil Saya di
/// portal karyawan web.
///
/// Nomor sensitif (NIK, KK, NPWP, rekening, BPJS) disamarkan dulu dan dibuka
/// satu per satu: halaman ini sering dibuka untuk menyalin satu nomor, dan
/// orang di sebelah tidak perlu ikut membaca lima nomor lainnya.
class PersonalDataPage extends StatefulWidget {
  const PersonalDataPage({super.key});

  @override
  State<PersonalDataPage> createState() => _PersonalDataPageState();
}

class _PersonalDataPageState extends State<PersonalDataPage> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<MyProfileCubit>();
    // Sudah pernah dimuat → perbarui diam-diam, tanpa layar putar.
    cubit.fetch(silent: cubit.state is MyProfileLoaded);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Diri')),
      body: BlocBuilder<MyProfileCubit, MyProfileState>(
        builder: (context, state) {
          if (state is MyProfileLoading || state is MyProfileInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is MyProfileError) {
            return ErrorState(
              message: state.message,
              onRetry: () => context.read<MyProfileCubit>().fetch(),
            );
          }

          final data = (state as MyProfileLoaded).profile;

          return RefreshIndicator(
            onRefresh: () =>
                context.read<MyProfileCubit>().fetch(silent: true),
            child: PersonalDataView(data: data),
          );
        },
      ),
    );
  }
}

/// Isi halaman, dipisah dari cubit supaya bisa diuji langsung dengan data.
class PersonalDataView extends StatelessWidget {
  final MyProfileData data;

  const PersonalDataView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final p = data.profile;
    final isContract = data.employmentType == 'contract' ||
        (data.contractStartDate?.isNotEmpty ?? false) ||
        (data.contractEndDate?.isNotEmpty ?? false);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _Summary(data: data),
        const SizedBox(height: 20),

        _Card(
          title: 'KEPEGAWAIAN',
          children: [
            _Field(label: 'Perusahaan', value: data.companyName),
            _Field(label: 'Departemen', value: data.departmentName),
            _Field(label: 'Jabatan', value: data.positionTitle),
            _Field(label: 'Golongan', value: data.jobGrade),
            _Field(label: 'Atasan langsung', value: data.reportsToName),
            _Field(label: 'Kantor utama', value: data.officeLocationName),
            _Field(
              label: 'Tanggal bergabung',
              value: formatProfileDate(data.joinDate),
            ),
            _Field(label: 'Masa kerja', value: formatTenure(data.joinDate)),
            _Field(
              label: 'Tipe kepegawaian',
              value: enumLabel(employmentTypeLabels, data.employmentType),
            ),
            if (isContract)
              _Field(
                label: 'Masa kontrak',
                value: formatContractPeriod(
                  data.contractStartDate,
                  data.contractEndDate,
                ),
              ),
            _Field(
              label: 'Status',
              value: enumLabel(employmentStatusLabels, data.employmentStatus),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _Card(
          title: 'DATA PRIBADI',
          children: [
            _SensitiveField(
              label: 'NIK (KTP)',
              copyName: 'NIK',
              value: p?.nationalId,
            ),
            _SensitiveField(
              label: 'Nomor Kartu Keluarga',
              copyName: 'Nomor KK',
              value: p?.familyCardNumber,
            ),
            _SensitiveField(
              label: 'NPWP',
              copyName: 'NPWP',
              value: p?.taxId,
              display: formatNpwp,
            ),
            _Field(
              label: 'Tempat, tanggal lahir',
              value: formatBirth(p?.birthPlace, p?.dateOfBirth),
            ),
            _Field(
              label: 'Jenis kelamin',
              value: enumLabel(genderLabels, p?.gender),
            ),
            _Field(
              label: 'Status pernikahan',
              value: enumLabel(maritalStatusLabels, p?.maritalStatus),
            ),
            _Field(
              label: 'Agama',
              value: enumLabel(religionLabels, p?.religion),
            ),
            _Field(
              label: 'Golongan darah',
              value: enumLabel(bloodTypeLabels, p?.bloodType),
            ),
            _Field(
              label: 'Pendidikan terakhir',
              value: enumLabel(educationLabels, p?.education),
            ),
            _Field(label: 'Nama ibu kandung', value: p?.motherName),
          ],
        ),
        const SizedBox(height: 16),

        _Card(
          title: 'ALAMAT & KONTAK',
          children: [
            _Field(label: 'Alamat sesuai KTP', value: p?.idCardAddress),
            _Field(label: 'Alamat domisili', value: p?.personalAddress),
            _Field(label: 'Email pribadi', value: p?.personalEmail),
            _Field(label: 'Nomor telepon', value: p?.personalPhone),
          ],
        ),
        const SizedBox(height: 16),

        _Card(
          title: 'KONTAK DARURAT',
          children: [
            _Field(label: 'Nama', value: p?.emergencyContactName),
            _Field(label: 'Hubungan', value: p?.emergencyContactRelationship),
            _Field(label: 'Nomor telepon', value: p?.emergencyContactPhone),
          ],
        ),
        const SizedBox(height: 16),

        _Card(
          title: 'BPJS & REKENING',
          caption: 'Cek lagi nomor rekening. Kalau salah, gaji bisa masuk ke '
              'rekening orang lain.',
          children: [
            _SensitiveField(
              label: 'BPJS Ketenagakerjaan',
              copyName: 'Nomor BPJS Ketenagakerjaan',
              value: p?.bpjsEmploymentNumber,
            ),
            _SensitiveField(
              label: 'BPJS Kesehatan',
              copyName: 'Nomor BPJS Kesehatan',
              value: p?.bpjsHealthNumber,
            ),
            _Field(label: 'Bank', value: p?.bankName),
            _SensitiveField(
              label: 'Nomor rekening',
              copyName: 'Nomor rekening',
              value: p?.bankAccountNumber,
            ),
            _Field(label: 'Nama pemilik rekening', value: p?.bankAccountHolder),
          ],
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColor.infoSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 18, color: AppColor.info),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Semua data di sini diatur HR. Hubungi HR kalau ada yang '
                  'salah.',
                  style: AppText.caption.copyWith(color: AppColor.info),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  final MyProfileData data;

  const _Summary({required this.data});

  @override
  Widget build(BuildContext context) {
    final sub = [
      if (data.employeeNumber?.isNotEmpty ?? false) data.employeeNumber!,
      if (data.workEmail?.isNotEmpty ?? false) data.workEmail!,
    ].join(' · ');
    final status = enumLabel(employmentStatusLabels, data.employmentStatus);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.primarySurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(orDash(data.fullName), style: AppText.h2),
          if (sub.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(sub, style: AppText.caption),
          ],
          if (status != null || data.isFlexibleLocation) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (status != null)
                  StatusBadge(
                    label: status,
                    tone: data.employmentStatus == 'active'
                        ? StatusTone.success
                        : StatusTone.neutral,
                  ),
                if (data.isFlexibleLocation)
                  const StatusBadge(
                    label: 'Lokasi fleksibel',
                    tone: StatusTone.info,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final String? caption;
  final List<Widget> children;

  const _Card({required this.title, this.caption, required this.children});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) rows.add(const Divider(height: 1, indent: 16));
      rows.add(children[i]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text(title, style: AppText.label),
        ),
        if (caption != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(caption!, style: AppText.caption),
          ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColor.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColor.border),
          ),
          child: Column(children: rows),
        ),
      ],
    );
  }
}

/// Label di atas nilai, bukan berdampingan: alamat panjang dan nama kantor
/// tetap terbaca utuh di layar sempit, tidak terpotong jadi dua kolom kurus.
class _Field extends StatelessWidget {
  final String label;
  final String? value;

  const _Field({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final v = orDash(value);
    final empty = v == kEmptyValue;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppText.caption),
            const SizedBox(height: 2),
            Text(
              v,
              style: empty
                  ? AppText.body.copyWith(color: AppColor.textDisabled)
                  : AppText.body,
            ),
          ],
        ),
      ),
    );
  }
}

/// Nomor sensitif: tersamar sampai ikon mata diketuk, dan bisa disalin.
///
/// Yang disalin selalu nilai aslinya, apa pun yang sedang tampil — menyalin
/// "3201 •••• 0001" tidak berguna bagi siapa pun.
class _SensitiveField extends StatefulWidget {
  final String label;

  /// Nama untuk pesan "… disalin".
  final String copyName;
  final String? value;

  /// Format saat dibuka (mis. NPWP diberi titik). Default: apa adanya.
  final String? Function(String?)? display;

  const _SensitiveField({
    required this.label,
    required this.copyName,
    required this.value,
    this.display,
  });

  @override
  State<_SensitiveField> createState() => _SensitiveFieldState();
}

class _SensitiveFieldState extends State<_SensitiveField> {
  bool _revealed = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.value!.trim()));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('${widget.copyName} disalin')));
  }

  @override
  Widget build(BuildContext context) {
    final raw = widget.value?.trim() ?? '';
    final empty = raw.isEmpty;
    final shown = empty
        ? kEmptyValue
        : _revealed
            ? orDash(widget.display?.call(raw) ?? raw)
            : maskSensitive(raw);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, empty ? 16 : 4, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.label, style: AppText.caption),
                const SizedBox(height: 2),
                Text(
                  shown,
                  style: empty
                      ? AppText.body.copyWith(color: AppColor.textDisabled)
                      : AppText.body.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                ),
              ],
            ),
          ),
          if (!empty) ...[
            IconButton(
              tooltip: _revealed
                  ? 'Sembunyikan ${widget.label}'
                  : 'Tampilkan ${widget.label}',
              icon: Icon(
                _revealed
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: AppColor.textSecondary,
              ),
              onPressed: () => setState(() => _revealed = !_revealed),
            ),
            IconButton(
              tooltip: 'Salin ${widget.label}',
              icon: Icon(
                Icons.copy_rounded,
                size: 18,
                color: AppColor.textSecondary,
              ),
              onPressed: _copy,
            ),
          ],
        ],
      ),
    );
  }
}
