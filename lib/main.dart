import 'package:flutter/material.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Test Login Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  
  final AuthService _authService = AuthService();
  String? _accessToken;  // To store the access token
  Map<String, dynamic>? _userInfo;  // To store user info

  @override
  void initState() {
    super.initState();
    // Call the async function after initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForSavedToken();
    });
  }
  // Check if access token is already saved locally
  Future<void> _checkForSavedToken() async {
    final token = await _authService.getAccessToken();
    if (token != null) {
      setState(() {
        _accessToken = token;
      });
      _fetchUserInfo(token);
    }
  }

  // Fetch user info using the access token
  Future<void> _fetchUserInfo(String token) async {
    final userInfo = await _authService.fetchUserInfo(token, context);
    print('User Info: $userInfo');
    if (userInfo != null) {
      setState(() {
        _userInfo = userInfo;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: _accessToken == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.only(bottom: 40),
                    child: Image.asset(
                      'assets/keycloak-logo.png', // Path to your PNG file
                      width: 300,        // Set width as needed
                      height: 100,       // Set height as needed
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await _authService.login(context); // Ensure logout functionality clears the session
                    
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => MyHomePage(title: 'Test Login Page')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      textStyle: TextStyle(fontSize: 20),
                    ),
                    child: Text('Keycloak Login'),
                  ),
                ],
              )
            : _userInfo != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        margin: EdgeInsets.only(bottom: 40),
                        child: Image.asset(
                          'assets/keycloak-logo.png', // Path to your PNG file
                          width: 300,
                          height: 100,
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(bottom: 40),
                        child: Column(
                          children: [
                            Text('Name: ${_userInfo!['preferred_username'] ?? 'N/A'}'),
                            Text('Email: ${_userInfo!['email'] ?? 'N/A'}'),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await _authService.logout(); // Ensure logout functionality clears the session
                          setState(() {
                            _accessToken = null; // Clear access token
                            _userInfo = null; // Clear user info
                          });
                          // Navigate to login screen or refresh the UI
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => MyHomePage(title: 'Test Login Page')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          textStyle: TextStyle(fontSize: 20),
                        ),
                        child: Text('Logout'),
                      ),
                    ],
                  )
                : CircularProgressIndicator(), // Show a loader while fetching data
      ),
    );
  }
}
