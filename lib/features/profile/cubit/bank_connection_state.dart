part of 'bank_connection_cubit.dart';

abstract class BankConnectionState extends Equatable {
  const BankConnectionState();

  @override
  List<Object> get props => [];
}

class BankConnectionInitial extends BankConnectionState {}

class BankConnectionLoading extends BankConnectionState {}

class BankConnectionLoaded extends BankConnectionState {
  final List<BankConnection> connections;

  const BankConnectionLoaded({required this.connections});

  @override
  List<Object> get props => [connections];
}

class BankConnectionError extends BankConnectionState {
  final String message;

  const BankConnectionError({required this.message});

  @override
  List<Object> get props => [message];
}