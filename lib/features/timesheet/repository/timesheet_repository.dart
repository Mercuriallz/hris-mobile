import 'package:fpdart/fpdart.dart';

import '../../../helper/dio_service.dart';
import '../../../helper/error_message.dart';
import '../model/timesheet_model.dart';

/// scope: mine | team | shared
class TimesheetRepository {
  Future<Either<String, T>> _run<T>(Future<T> Function() call) async {
    try {
      return Right(await call());
    } catch (e) {
      return left(errorMessage(e));
    }
  }

  Future<Either<String, TimesheetPageData>> list(
    String scope, {
    int page = 1,
    int limit = 30,
    String? search,
    String? visibility,
    String? from,
    String? to,
  }) =>
      _run(() async {
        final dio = await DioService.getInstance();
        final path = scope == 'mine' ? '/me/timesheets' : '/me/timesheets/$scope';
        final res = await dio.get(path, queryParameters: {
          'page': page,
          'limit': limit,
          // Urut menurut tanggal kerja supaya daftar bisa dikelompokkan per hari.
          'sortBy': 'workDate',
          'order': 'desc',
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
          'visibility': ?visibility,
          'from': ?from,
          'to': ?to,
        });
        return TimesheetPageData.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
      });

  Future<Either<String, TimesheetOptions>> options() => _run(() async {
        final dio = await DioService.getInstance();
        final res = await dio.get('/me/timesheets/options');
        return TimesheetOptions.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
      });

  Future<Either<String, TimesheetDashboardData>> dashboard() => _run(() async {
        final dio = await DioService.getInstance();
        final res = await dio.get('/me/timesheets/dashboard');
        return TimesheetDashboardData.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
      });

  Future<Either<String, Unit>> create(List<Map<String, dynamic>> activities) => _run(() async {
        final dio = await DioService.getInstance();
        await dio.post('/me/timesheets', data: {'activities': activities});
        return unit;
      });

  Future<Either<String, Unit>> update(String id, Map<String, dynamic> activity) => _run(() async {
        final dio = await DioService.getInstance();
        await dio.patch('/me/timesheets/$id', data: activity);
        return unit;
      });

  Future<Either<String, Unit>> remove(String id) => _run(() async {
        final dio = await DioService.getInstance();
        await dio.delete('/me/timesheets/$id');
        return unit;
      });
}
