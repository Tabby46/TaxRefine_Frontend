import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';
import 'package:taxrefine/core/models/deduction_summary.dart';
import 'package:taxrefine/data/providers/transaction_api_provider.dart';

part 'dashboard_summary_state.dart';

class DashboardSummaryCubit extends Cubit<DashboardSummaryState> {
  DashboardSummaryCubit(this._apiProvider)
    : super(const DashboardSummaryInitial());

  final TransactionApiProvider _apiProvider;

  Future<void> loadSummary(String userId) async {
    emit(const DashboardSummaryLoading());
    try {
      final response = await _apiProvider.fetchDeductionSummary(userId: userId);
      final payload = response.data;
      if (payload is! Map<String, dynamic>) {
        throw const FormatException('Invalid summary response');
      }
      final summary = DeductionSummary.fromJson(payload);
      emit(DashboardSummaryLoaded(summary));
    } on DioException catch (ex) {
      emit(DashboardSummaryError(_resolveDioError(ex)));
    } catch (ex) {
      emit(DashboardSummaryError('Failed to load summary: $ex'));
    }
  }

  Future<void> refreshSummary(String userId) async {
    // Determine current refresh count to force a new emission even if totals
    // are numerically identical (Equatable would otherwise suppress the emit).
    final currentCount = state is DashboardSummaryLoaded
        ? (state as DashboardSummaryLoaded).refreshCount
        : 0;
    try {
      final response = await _apiProvider.fetchDeductionSummary(userId: userId);
      final payload = response.data;
      if (payload is! Map<String, dynamic>) {
        throw const FormatException('Invalid summary response');
      }
      final summary = DeductionSummary.fromJson(payload);
      emit(DashboardSummaryLoaded(summary, refreshCount: currentCount + 1));
    } on DioException {
      // Silently ignore refresh errors — keep the existing loaded state visible.
    } catch (_) {
      // Silently ignore refresh errors.
    }
  }

  String _resolveDioError(DioException ex) {
    if (ex.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout. Please try again.';
    }
    if (ex.type == DioExceptionType.receiveTimeout) {
      return 'Server timeout. Please try again.';
    }
    if (ex.type == DioExceptionType.badResponse) {
      return 'Server error (${ex.response?.statusCode}). Please try again.';
    }
    if (ex.type == DioExceptionType.connectionError) {
      return 'Connection error. Please check your network.';
    }
    return 'Failed to load summary. Please try again.';
  }
}
