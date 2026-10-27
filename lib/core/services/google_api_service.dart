import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Handles API calls to Google Maps services.
class GoogleApiService {
  final String apiKey = dotenv.env['GOOGLE_MAPS_API_KEY']!;

  Future<String?> getPlacePhotoUrl(String locationName) async {
    try {
      final searchUrl = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/findplacefromtext/json'
        '?input=${Uri.encodeComponent(locationName)}'
        '&inputtype=textquery'
        '&fields=photos'
        '&key=$apiKey',
      );

      final response = await http.get(searchUrl);
      final data = json.decode(response.body);

      if (data['status'] != 'OK') {
        print('Google API Error Status: ${data['status']}');
        print(
          'Google API Error Message: ${data['error_message'] ?? 'No message'}',
        );
      }

      if (data['candidates'] != null && data['candidates'].isNotEmpty) {
        final photos = data['candidates'][0]['photos'];
        if (photos != null && photos.isNotEmpty) {
          final photoReference = photos[0]['photo_reference'];
          return 'https://maps.googleapis.com/maps/api/place/photo'
              '?maxwidth=800'
              '&photo_reference=$photoReference'
              '&key=$apiKey';
        }
      }
    } catch (e) {
      print('Error fetching Google Photo: $e');
    }
    return null;
  }

  Future<List<String>> getPlaceSuggestions(
    String input, {
    String? types,
    double? lat,
    double? lng,
    int radius = 50000,
  }) async {
    if (input.isEmpty) return [];
    try {
      final typeQuery = types != null ? '&types=$types' : '';
      final locationQuery = (lat != null && lng != null)
          ? '&location=$lat,$lng&radius=$radius'
          : '';
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(input)}'
        '$typeQuery'
        '$locationQuery'
        '&key=$apiKey',
      );

      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        return (data['predictions'] as List)
            .map((p) => p['description'] as String)
            .toList();
      }
    } catch (e) {
      print('Autocomplete error: $e');
    }
    return [];
  }

  String getStaticMapUrl(String destination) {
    return 'https://maps.googleapis.com/maps/api/staticmap'
        '?center=${Uri.encodeComponent(destination)}'
        '&zoom=12&size=600x300'
        '&key=$apiKey';
  }

  Future<Map<String, double>?> getCoordinates(String locationName) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?address=${Uri.encodeComponent(locationName)}'
        '&key=$apiKey',
      );

      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
        final location = data['results'][0]['geometry']['location'];
        return {
          'lat': (location['lat'] as num).toDouble(),
          'lng': (location['lng'] as num).toDouble(),
        };
      }
    } catch (e) {
      print('Error fetching coordinates: $e');
    }
    return null;
  }
}
