part of 'dashboard_summary_cubit.dart';

abstract class DashboardSummaryState extends Equatable {
  const DashboardSummaryState();

  @override
  List<Object?> get props => [];
}

class DashboardSummaryInitial extends DashboardSummaryState {
  const DashboardSummaryInitial();
}

class DashboardSummaryLoading extends DashboardSummaryState {
  const DashboardSummaryLoading();
}

class DashboardSummaryLoaded extends DashboardSummaryState {
  const DashboardSummaryLoaded(this.summary);

  final DeductionSummary summary;

  @override
  List<Object?> get props => [summary];
}

class DashboardSummaryError extends DashboardSummaryState {
  const DashboardSummaryError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
