import 'package:dio/dio.dart';

class DioHelper {
  static late Dio dio;

  static void init({required String baseUrl, required String serviceRoleKey}) {
    // Replace https with http if needed
    final httpUrl = baseUrl.replaceFirst('https://', 'http://');

    dio = Dio(
      BaseOptions(
        baseUrl: httpUrl,
        receiveDataWhenStatusError: true,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Authorization': 'Bearer $serviceRoleKey',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  static Future<Response> getData({
    required String url,
    Map<String, dynamic>? query,
  }) async {
    return await dio.get(
      url,
      queryParameters: query,
    );
  }

  static Future<Response> postData({
    required String url,
    required Map<String, dynamic> data,
    Map<String, dynamic>? query,
  }) async {
    return await dio.post(
      url,
      queryParameters: query,
      data: data,
    );
  }

  static Future<Response> putData({
    required String url,
    required Map<String, dynamic> data,
    Map<String, dynamic>? query,
  }) async {
    return await dio.put(
      url,
      queryParameters: query,
      data: data,
    );
  }

  static Future<Response> deleteData({
    required String url,
    Map<String, dynamic>? query,
  }) async {
    return await dio.delete(
      url,
      queryParameters: query,
    );
  }
}
