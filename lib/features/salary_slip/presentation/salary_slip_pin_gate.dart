import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../constant/theme/app_color.dart';
import '../../../constant/theme/app_text.dart';
import '../../../constant/theme/app_widget.dart';
import '../helper/slip_unlock.dart';
import '../repository/salary_slip_pin_repository.dart';

const int kSlipPinLength = 6;

/// Pintu masuk Slip Gaji: karyawan wajib membuat PIN dulu, dan setelah itu slip
/// hanya terbuka dengan PIN tersebut.
///
/// Setiap kali halaman ini dibuka, PIN diminta lagi. Token buka-kunci hanya
/// hidup di memori dan dibuang begitu pengguna keluar dari Slip Gaji.
class SalarySlipGate extends StatefulWidget {
  final Widget child;
  final SalarySlipPinRepository? repository;

  const SalarySlipGate({super.key, required this.child, this.repository});

  @override
  State<SalarySlipGate> createState() => _SalarySlipGateState();
}

enum _Phase { loading, error, create, enter, unlocked }

class _SalarySlipGateState extends State<SalarySlipGate> {
  late final SalarySlipPinRepository _repo = widget.repository ?? SalarySlipPinRepository();
  _Phase _phase = _Phase.loading;
  StreamSubscription<void>? _expiredSub;

  @override
  void initState() {
    super.initState();
    SlipUnlock.instance.clear();
    _expiredSub = SlipUnlock.instance.onExpired.listen((_) {
      if (mounted) setState(() => _phase = _Phase.enter);
    });
    _load();
  }

  @override
  void dispose() {
    _expiredSub?.cancel();
    SlipUnlock.instance.clear();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _phase = _Phase.loading);
    final status = await _repo.status();
    if (!mounted) return;
    setState(() => _phase = status == null ? _Phase.error : (status.hasPin ? _Phase.enter : _Phase.create));
  }

  void _unlocked() {
    if (mounted) setState(() => _phase = _Phase.unlocked);
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _Phase.unlocked:
        return widget.child;
      case _Phase.loading:
        return Scaffold(
          appBar: AppBar(title: const Text('Slip Gaji')),
          body: const Center(child: CircularProgressIndicator()),
        );
      case _Phase.error:
        return Scaffold(
          appBar: AppBar(title: const Text('Slip Gaji')),
          body: ErrorState(message: 'Tidak bisa memeriksa PIN. Periksa koneksi Anda.', onRetry: _load),
        );
      case _Phase.create:
        return SlipPinCreateView(repository: _repo, onDone: _unlocked);
      case _Phase.enter:
        return SlipPinEnterView(repository: _repo, onDone: _unlocked);
    }
  }
}

// ---------------------------------------------------------------- Buat PIN

class SlipPinCreateView extends StatefulWidget {
  final SalarySlipPinRepository repository;
  final VoidCallback onDone;

  const SlipPinCreateView({super.key, required this.repository, required this.onDone});

  @override
  State<SlipPinCreateView> createState() => _SlipPinCreateViewState();
}

class _SlipPinCreateViewState extends State<SlipPinCreateView> {
  String _first = '';
  String _value = '';
  String? _error;
  bool _busy = false;

  bool get _confirming => _first.isNotEmpty;

  Future<void> _onChanged(String v) async {
    setState(() {
      _value = v;
      _error = null;
    });
    if (v.length < kSlipPinLength) return;

    if (!_confirming) {
      setState(() {
        _first = v;
        _value = '';
      });
      return;
    }
    if (v != _first) {
      setState(() {
        _first = '';
        _value = '';
        _error = 'PIN tidak sama. Ulangi dari awal.';
      });
      return;
    }
    setState(() => _busy = true);
    final r = await widget.repository.create(v);
    if (!mounted) return;
    if (r.ok) {
      widget.onDone();
      return;
    }
    setState(() {
      _busy = false;
      _first = '';
      _value = '';
      _error = r.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Slip Gaji')),
      body: SafeArea(
        child: PinPad(
          icon: Icons.lock_outline_rounded,
          title: _confirming ? 'Ulangi PIN' : 'Buat PIN slip gaji',
          subtitle: _confirming
              ? 'Masukkan PIN yang sama sekali lagi.'
              : 'Slip gaji hanya bisa dibuka dengan PIN $kSlipPinLength angka buatan Anda. Jangan pakai angka kembar atau berurutan.',
          value: _value,
          error: _error,
          busy: _busy,
          onChanged: _onChanged,
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ Masukkan PIN

class SlipPinEnterView extends StatefulWidget {
  final SalarySlipPinRepository repository;
  final VoidCallback onDone;

  const SlipPinEnterView({super.key, required this.repository, required this.onDone});

  @override
  State<SlipPinEnterView> createState() => _SlipPinEnterViewState();
}

class _SlipPinEnterViewState extends State<SlipPinEnterView> {
  String _value = '';
  String? _error;
  bool _busy = false;
  bool _locked = false;

  Future<void> _onChanged(String v) async {
    setState(() {
      _value = v;
      _error = null;
    });
    if (v.length < kSlipPinLength) return;

    setState(() => _busy = true);
    final r = await widget.repository.verify(v);
    if (!mounted) return;
    if (r.ok) {
      widget.onDone();
      return;
    }
    setState(() {
      _busy = false;
      _value = '';
      _locked = r.locked;
      _error = r.message;
    });
    HapticFeedback.mediumImpact();
  }

  Future<void> _forgot() async {
    final done = await showDialog<bool>(
      context: context,
      builder: (_) => SlipPinResetDialog(repository: widget.repository),
    );
    if (done == true && mounted) widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Slip Gaji')),
      body: SafeArea(
        child: PinPad(
          icon: Icons.lock_outline_rounded,
          title: 'Masukkan PIN',
          subtitle: 'Slip gaji dilindungi PIN yang Anda buat.',
          value: _value,
          error: _error,
          busy: _busy,
          disabled: _locked,
          footer: TextButton(onPressed: _forgot, child: const Text('Lupa PIN?')),
          onChanged: _onChanged,
        ),
      ),
    );
  }
}

// ------------------------------------------------------------- Lupa / ganti

/// Lupa PIN: buktikan dengan kata sandi akun, lalu buat PIN baru.
class SlipPinResetDialog extends StatefulWidget {
  final SalarySlipPinRepository repository;

  const SlipPinResetDialog({super.key, required this.repository});

  @override
  State<SlipPinResetDialog> createState() => _SlipPinResetDialogState();
}

class _SlipPinResetDialogState extends State<SlipPinResetDialog> {
  final _password = TextEditingController();
  final _pin = TextEditingController();
  final _pin2 = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    _pin.dispose();
    _pin2.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_password.text.isEmpty) return setState(() => _error = 'Kata sandi wajib diisi.');
    if (_pin.text.length != kSlipPinLength) return setState(() => _error = 'PIN baru harus $kSlipPinLength angka.');
    if (_pin.text != _pin2.text) return setState(() => _error = 'PIN baru dan ulangannya tidak sama.');
    setState(() {
      _busy = true;
      _error = null;
    });
    final r = await widget.repository.reset(_password.text, _pin.text);
    if (!mounted) return;
    if (r.ok) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _busy = false;
      _error = r.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Atur ulang PIN'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Masukkan kata sandi akun Anda untuk membuat PIN baru.', style: AppText.caption),
            const SizedBox(height: 14),
            TextField(
              key: const Key('reset-password'),
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Kata sandi akun'),
            ),
            const SizedBox(height: 12),
            _PinField(key: const Key('reset-pin'), controller: _pin, label: 'PIN baru'),
            const SizedBox(height: 12),
            _PinField(key: const Key('reset-pin2'), controller: _pin2, label: 'Ulangi PIN baru'),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: AppText.caption.copyWith(color: AppColor.danger)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: const Text('Batal')),
        FilledButton(onPressed: _busy ? null : _submit, child: Text(_busy ? 'Menyimpan...' : 'Simpan')),
      ],
    );
  }
}

/// Ganti PIN (PIN lama diketahui). Dipanggil dari menu di halaman daftar slip.
class SlipPinChangeDialog extends StatefulWidget {
  final SalarySlipPinRepository? repository;

  const SlipPinChangeDialog({super.key, this.repository});

  @override
  State<SlipPinChangeDialog> createState() => _SlipPinChangeDialogState();
}

class _SlipPinChangeDialogState extends State<SlipPinChangeDialog> {
  late final SalarySlipPinRepository _repo = widget.repository ?? SalarySlipPinRepository();
  final _current = TextEditingController();
  final _pin = TextEditingController();
  final _pin2 = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _pin.dispose();
    _pin2.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_current.text.length != kSlipPinLength) return setState(() => _error = 'PIN lama harus $kSlipPinLength angka.');
    if (_pin.text.length != kSlipPinLength) return setState(() => _error = 'PIN baru harus $kSlipPinLength angka.');
    if (_pin.text != _pin2.text) return setState(() => _error = 'PIN baru dan ulangannya tidak sama.');
    setState(() {
      _busy = true;
      _error = null;
    });
    final r = await _repo.change(_current.text, _pin.text);
    if (!mounted) return;
    if (r.ok) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _busy = false;
      _error = r.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ganti PIN'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PinField(key: const Key('change-current'), controller: _current, label: 'PIN lama'),
            const SizedBox(height: 12),
            _PinField(key: const Key('change-new'), controller: _pin, label: 'PIN baru'),
            const SizedBox(height: 12),
            _PinField(key: const Key('change-new2'), controller: _pin2, label: 'Ulangi PIN baru'),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: AppText.caption.copyWith(color: AppColor.danger)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: const Text('Batal')),
        FilledButton(onPressed: _busy ? null : _submit, child: Text(_busy ? 'Menyimpan...' : 'Simpan')),
      ],
    );
  }
}

class _PinField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _PinField({super.key, required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: true,
      keyboardType: TextInputType.number,
      maxLength: kSlipPinLength,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label, counterText: ''),
    );
  }
}

// ---------------------------------------------------------------- Keypad

/// Titik PIN dan papan angka. Papan sendiri (bukan keyboard sistem) supaya
/// angkanya tidak tersimpan di riwayat keyboard dan tidak bisa ditempel.
class PinPad extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final String? error;
  final bool busy;
  final bool disabled;
  final Widget? footer;
  final ValueChanged<String> onChanged;

  const PinPad({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.error,
    this.busy = false,
    this.disabled = false,
    this.footer,
  });

  void _tap(String d) {
    if (busy || disabled || value.length >= kSlipPinLength) return;
    HapticFeedback.selectionClick();
    onChanged(value + d);
  }

  void _back() {
    if (busy || disabled || value.isEmpty) return;
    onChanged(value.substring(0, value.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: AppColor.primarySurface, shape: BoxShape.circle),
                  child: Icon(icon, color: AppColor.primary, size: 28),
                ),
                const SizedBox(height: 18),
                Text(title, style: AppText.h2, textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Text(subtitle, style: AppText.caption, textAlign: TextAlign.center),
                const SizedBox(height: 26),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  key: const Key('pin-dots'),
                  children: List.generate(kSlipPinLength, (i) {
                    final filled = i < value.length;
                    return Container(
                      width: 14,
                      height: 14,
                      margin: const EdgeInsets.symmetric(horizontal: 7),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled ? AppColor.primary : Colors.transparent,
                        border: Border.all(color: error != null ? AppColor.danger : (filled ? AppColor.primary : AppColor.border), width: 1.6),
                      ),
                    );
                  }),
                ),
                SizedBox(
                  height: 44,
                  child: Center(
                    child: busy
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : (error != null
                            ? Text(error!, key: const Key('pin-error'), style: AppText.caption.copyWith(color: AppColor.danger), textAlign: TextAlign.center)
                            : null),
                  ),
                ),
                const SizedBox(height: 4),
                for (final row in const [
                  ['1', '2', '3'],
                  ['4', '5', '6'],
                  ['7', '8', '9'],
                ])
                  _KeyRow(children: [for (final d in row) _Key(label: d, onTap: () => _tap(d))]),
                _KeyRow(children: [
                  const SizedBox(width: 72, height: 56),
                  _Key(label: '0', onTap: () => _tap('0')),
                  _Key(icon: Icons.backspace_outlined, keyName: 'pin-back', onTap: _back),
                ]),
                if (footer != null) ...[const SizedBox(height: 8), footer!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KeyRow extends StatelessWidget {
  final List<Widget> children;

  const _KeyRow({required this.children});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: children),
      );
}

class _Key extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final String? keyName;
  final VoidCallback onTap;

  const _Key({this.label, this.icon, this.keyName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: InkResponse(
        key: Key(keyName ?? 'pin-$label'),
        onTap: onTap,
        radius: 36,
        child: Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: label == null ? Colors.transparent : AppColor.surface, shape: BoxShape.circle, border: label == null ? null : Border.all(color: AppColor.border)),
          child: label != null
              ? Text(label!, style: AppText.h1.copyWith(fontSize: 22))
              : Icon(icon, color: AppColor.textSecondary, size: 22),
        ),
      ),
    );
  }
}
