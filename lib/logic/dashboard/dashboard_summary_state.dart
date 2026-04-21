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
  const DashboardSummaryLoaded(this.summary, {this.refreshCount = 0});

  final DeductionSummary summary;
  // Incremented on each refresh so Equatable treats identical-value reloads as
  // a new state, ensuring BlocListeners always fire after a swipe.
  final int refreshCount;

  @override
  List<Object?> get props => [summary, refreshCount];
}

class DashboardSummaryError extends DashboardSummaryState {
  const DashboardSummaryError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
