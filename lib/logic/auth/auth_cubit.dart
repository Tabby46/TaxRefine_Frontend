import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:taxrefine/core/auth/auth_session.dart';
import 'package:taxrefine/core/constants/app_strings.dart';
import 'package:taxrefine/data/repositories/auth_repository.dart';
import 'package:taxrefine/logic/auth/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthInitial());

  final AuthRepository _repository;

  void restoreSession() {
    if (AuthSession.isAuthenticated) {
      emit(const Authenticated());
      return;
    }
    emit(const Unauthenticated());
  }

  Future<void> signInWithGoogle() async {
    emit(const AuthLoading());
    try {
      await _repository.signInWithGoogle();
      emit(const Authenticated());
    } on GoogleSignInException catch (ex) {
      if (ex.code == GoogleSignInExceptionCode.canceled) {
        emit(
          const Unauthenticated(errorMessage: AppStrings.googleSignInCancelled),
        );
        return;
      }
      if (ex.code == GoogleSignInExceptionCode.clientConfigurationError) {
        emit(
          const Unauthenticated(
            errorMessage: AppStrings.googleSignInConfigurationError,
          ),
        );
        return;
      }
      emit(const Unauthenticated(errorMessage: AppStrings.loginFailed));
    } on DioException {
      emit(const Unauthenticated(errorMessage: AppStrings.loginFailed));
    } on AuthException catch (ex) {
      emit(Unauthenticated(errorMessage: ex.message));
    } catch (_) {
      emit(const Unauthenticated(errorMessage: AppStrings.loginFailed));
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    emit(const Unauthenticated());
  }
}
