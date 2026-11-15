import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' show Get, Inst;

import '../availability/app_availability_controller.dart';

import '../services/debug/debug_service.dart';
import 'exceptions.dart';
import 'failure.dart';

base class BaseRepository {
  Future<Either<DataCRUDFailure, T>> asyncTryCatch<T>({
    required Future<T> Function() tryFunc,
  }) async {
    try {
      return await tryFunc().then((value) => Right(value));
    } on ServerException {
      return Left(
        DataCRUDFailure(
          failure: Failure.severFailure,
          fullError: 'Server failed!',
        ),
      );
    } on NoDataException {
      return Left(
        DataCRUDFailure(failure: Failure.noData, fullError: "Doesn't exist!"),
      );
    } on SocketException {
      return Left(
        DataCRUDFailure(
          failure: Failure.socketFailure,
          fullError: 'Internet connection failed!',
        ),
      );
    } on DioException catch (e) {
      //debugger?.dekhao("DioFailure $e");
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          return Left(
            DataCRUDFailure(
              failure: Failure.timeout,
              fullError: 'Connection timeout! Make sure internet is connected!',
            ),
          );
        case DioExceptionType.receiveTimeout:
          return Left(
            DataCRUDFailure(
              failure: Failure.timeout,
              fullError: 'Connection timeout! Make sure internet is connected!',
            ),
          );
        case DioExceptionType.sendTimeout:
          return Left(
            DataCRUDFailure(
              failure: Failure.timeout,
              fullError: 'Connection timeout! Make sure internet is connected!',
            ),
          );
        case DioExceptionType.connectionError:
          return Left(
            DataCRUDFailure(
              failure: Failure.socketFailure,
              fullError:
                  'No internet connection. Check your connection and '
                  'try again.',
            ),
          );
        case DioExceptionType.cancel:
          return Left(
            DataCRUDFailure(
              failure: Failure.unknownFailure,
              uiMessage: "Request cancelled!",
              fullError: 'Some error occured. ${'\n'} Error: ${e.toString()}',
            ),
          );
        default:
          final statusCode = e.response?.statusCode;
          final responseData = e.response?.data;
          debugPrint('DioException [$statusCode]: $responseData');
          // Maintenance: keep the session, and let the availability banner
          // learn about it now rather than at its next poll.
          if (statusCode == 503 &&
              Get.isRegistered<AppAvailabilityController>()) {
            unawaited(AppAvailabilityController.instance.check());
          }
          final message = responseData is Map
              ? (responseData['message'] ?? 'Some error occured.').toString()
              : 'Some error occured.';
          return Left(
            DataCRUDFailure(
              failure: switch (statusCode) {
                401 => Failure.authFailure,
                403 => Failure.forbidden,
                404 => Failure.notFound,
                _ => Failure.unknownFailure,
              },
              uiMessage: message,
              fullError: 'Some error occured. ${'\n'} Error: ${e.toString()}',
            ),
          );
      }
    } catch (e, stackTrace) {
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());
      //debugger?.dekhao(e);
      return Left(
        DataCRUDFailure(
          failure: Failure.unknownFailure,
          uiMessage: 'Some error occured.',
          fullError: "Some error occured. ${'\n'} Error: ${e.toString()}",
        ),
      );
    }
  }

  Either<DataCRUDFailure, T> tryCatch<T>({required T Function() tryFunc}) {
    try {
      return Right(tryFunc());
    } on ServerException {
      return Left(
        DataCRUDFailure(failure: Failure.severFailure, fullError: ''),
      );
    } on SocketException {
      return Left(
        DataCRUDFailure(
          failure: Failure.socketFailure,
          fullError: 'Internet connection failed!',
        ),
      );
    } catch (e) {
      return Left(
        DataCRUDFailure(
          failure: Failure.unknownFailure,
          fullError: 'Some error occured. Error: ${e.toString()}',
        ),
      );
    }
  }

  dynamic extractBodyData(Response<dynamic> response) {
    return response.data["data"];
  }

  String? extractSuccessMessage(
    Response<dynamic> response, {
    Debugger? debugger,
  }) {
    debugger?.dekhao(response);
    try {
      // The envelope flags success as `status` (`{status, message, data}`).
      final body = response.data;
      if (body is! Map || body['status'] != true) return null;
      final message = body['message']?.toString() ?? '';
      return message.isEmpty ? null : message;
    } catch (e) {
      debugger?.dekhao("Error from parsing success message: $e");
      return null;
    }
  }
}
