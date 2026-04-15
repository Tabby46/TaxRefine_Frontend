import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:taxrefine/core/models/bank_connection.dart';
import 'package:taxrefine/core/network/api_service.dart';

part 'bank_connection_state.dart';

class BankConnectionCubit extends Cubit<BankConnectionState> {
  final ApiService apiService;

  BankConnectionCubit({required this.apiService})
      : super(BankConnectionInitial());

  Future<void> loadConnections() async {
    try {
      emit(BankConnectionLoading());
      final connections = await apiService.fetchBankConnections();
      emit(BankConnectionLoaded(connections: connections));
    } catch (e) {
      emit(BankConnectionError(message: e.toString()));
    }
  }

  Future<void> unlinkBank(String id) async {
    try {
      final currentState = state;
      if (currentState is BankConnectionLoaded) {
        emit(BankConnectionLoading());
        await apiService.deleteBankConnection(id);
        final updatedConnections = currentState.connections
            .where((connection) => connection.id != id)
            .toList();
        emit(BankConnectionLoaded(connections: updatedConnections));
      }
    } catch (e) {
      emit(BankConnectionError(message: e.toString()));
    }
  }
}