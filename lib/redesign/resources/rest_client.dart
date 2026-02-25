import 'package:politicsstatements/redesign/resources/models/top_chart.dart';
import 'package:retrofit/retrofit.dart';
import 'package:dio/dio.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:politicsstatements/redesign/resources/prefs.dart';

import 'models/medias.dart';
import 'models/media_item.dart';
import 'models/migrate_request.dart';
import 'models/user.dart';
import 'models/favorites_response.dart';
import 'models/notification_request.dart';
import 'models/notification_response.dart';

part 'rest_client.g.dart';

// Base URLs for different environments
const String STAGING_BASE_URL = "https://staging.bolola.org";
const String PROD_BASE_URL = "https://production.bolola.org";

// Get the appropriate base URL based on user preference
String get baseUrl => isProductionEnvironment ? PROD_BASE_URL : STAGING_BASE_URL;

@RestApi()
abstract class RestClient {
  factory RestClient(Dio dio, {String? baseUrl}) = _RestClient;

  @GET("/categories")
  Future<Medias> fetchCategories();

  @GET("/top-chart")
  Future<TopChart> getTopChart();

  @POST("/update-chart-item")
  Future<void> updateChartItem(@Header("x-api-key") String apiKey, @Body() MediaItem item);

  @POST("/update-media")
  Future<void> updateMedia(@Header("x-api-key") String apiKey, @Body() MediaItem? item);

  @POST("/update-user")
  Future<User> updateUser(@Header("x-api-key") String apiKey, @Body() User user);

  @POST("/create-user")
  Future<User> createUser(@Header("x-api-key") String apiKey, @Body() User? user);

  @GET("/user/{firebaseUid}")
  Future<User> getUserByFirebaseUid(@Path("firebaseUid") String firebaseUid);

  // Favorites endpoints
  @POST("/user/{firebaseUid}/favorites/add")
  Future<AddToFavoritesResponse> addToFavorites(@Path("firebaseUid") String firebaseUid, @Body() MediaItem mediaItem);

  @POST("/user/{firebaseUid}/favorites/remove")
  Future<RemoveFromFavoritesResponse> removeFromFavorites(@Path("firebaseUid") String firebaseUid, @Body() MediaItem mediaItem);

  @GET("/user/favorites")
  Future<GetUserFavoritesResponse> getUserFavorites(@Query("firebaseUid") String firebaseUid);

  // Database migration endpoint
  @POST("/migrate-db")
  Future<void> migrateDatabase(@Header("x-api-key") String apiKey, @Body() MigrateRequest migrateRequest);

  // Send notification endpoint
  @POST("/send-notification")
  Future<NotificationResponse> sendNotification(@Header("x-api-key") String apiKey, @Body() NotificationRequest notificationRequest);
}
