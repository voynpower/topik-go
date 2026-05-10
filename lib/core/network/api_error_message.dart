import 'package:dio/dio.dart';

String apiErrorMessage(Object error, {String? missingApiMessage}) {
  if (error is DioException) {
    final statusCode = error.response?.statusCode;

    if (statusCode == 404) {
      return missingApiMessage ?? '요청한 데이터를 찾을 수 없습니다.';
    }

    if (statusCode == 401) {
      return '로그인이 필요합니다.';
    }

    if (statusCode == 403) {
      return '접근 권한이 없습니다.';
    }

    if (statusCode != null && statusCode >= 500) {
      return '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return '서버 응답이 지연되고 있습니다. 잠시 후 다시 시도해주세요.';
      case DioExceptionType.connectionError:
        return '서버에 연결할 수 없습니다. 백엔드가 실행 중인지 확인해주세요.';
      case DioExceptionType.cancel:
        return '요청이 취소되었습니다.';
      case DioExceptionType.badCertificate:
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        break;
    }

    final responseMessage = _responseMessage(error.response?.data);
    if (responseMessage != null) return responseMessage;
  }

  return error.toString();
}

String? _responseMessage(Object? data) {
  if (data is Map && data.containsKey('message')) {
    final message = data['message'];
    if (message is List) {
      return message.map((item) => item.toString()).join(', ');
    }
    return message?.toString();
  }
  return null;
}
