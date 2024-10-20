import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class AuthService {
  final FlutterAppAuth _appAuth = FlutterAppAuth();

  final String clientId = 'officer'; // Replace with your client ID
  final String redirectUrl = 'com.testapp://login'; // Replace with your redirect URL
  final String discoveryUrl = 'https://e-oidc.dot.go.th/realms/dot-officer/.well-known/openid-configuration';

  Future<void> login(BuildContext context) async {
    try {
      final AuthorizationTokenResponse? result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          clientId,
          redirectUrl,
          discoveryUrl: discoveryUrl,
          scopes: ['openid', 'profile', 'email'], // Adjust the scopes as needed
        ),
      );

      if (result != null) {
        final String accessToken = result.accessToken!;
        final String refreshToken = result.refreshToken!;
        //print('Access Token: $accessToken');

        // Save the access token to local storage
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', accessToken);
        await prefs.setString('refresh_token', refreshToken);

          // Fetch user info after successful login
        await fetchUserInfo(accessToken, context);
      }
    } catch (e) {
      print('Error during authentication: $e');
    }
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? accessToken = prefs.getString('access_token');
    final String? refreshToken = prefs.getString('refresh_token');
    final String logoutUrl = 'https://e-oidc.dot.go.th/realms/dot-officer/protocol/openid-connect/logout';

    if (accessToken != null) {
      try {
        final response = await http.post(
          Uri.parse(logoutUrl),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {
            'client_id': clientId,
            'refresh_token': refreshToken
          },
        );

        if (response.statusCode == 204 || response.statusCode == 200) {
          print('Logged out successfully');

          // Clear the token locally after successful logout
          await clearAccessToken();
        } else {
          print('Failed to log out: ${response}');
        }
      } catch (e) {
        print('Error during logout: $e');
      }
    }
  }

  Future<Map<String, dynamic>?> fetchUserInfo(String accessToken, BuildContext context) async {
    final String userInfoUrl = 'https://e-oidc.dot.go.th/realms/dot-officer/protocol/openid-connect/userinfo'; // Adjust the URL as needed

    try {
      final response = await http.get(
        Uri.parse(userInfoUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final userInfo = json.decode(response.body);
        //print('User Info: $userInfo');
        return userInfo;
        // Now you can use this data in your Flutter app
      } else {
        clearAccessToken();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MyHomePage(title: 'Test Login Page')),
        );
        print('Failed to load user info: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user info: $e');
    }
  }


  // Check if token is already saved locally
  Future<String?> getAccessToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');  // Return the saved token
  }

  // Clear the token (for logging out)
  Future<void> clearAccessToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');  // Remove the token
  }
}