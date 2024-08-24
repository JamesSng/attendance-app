import 'package:attendance_app/util/logger.dart';
import 'package:attendance_app/view/eventsview.dart';
import 'package:attendance_app/view/settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    Logger.init();
    return MaterialApp(
      title: 'CBC Attendance App',
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurpleAccent),
        useMaterial3: true,
      ),
      home: HomePageView(),
    );
  }
}

class HomePageView extends StatefulWidget {
  HomePageView({super.key});

  final auth = FirebaseAuth.instance;
  final db = FirebaseFirestore.instance;

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<HomePageView> createState() => _HomePageViewState();
}

class _HomePageViewState extends State<HomePageView> {
  var selectedIndex = 0;
  var loggedin = false;
  var initialized = false;
  var admin = false;

  @override
  Widget build(BuildContext context) {
    if (!initialized) {
      initialized = true;
      widget.auth.authStateChanges().listen(
        (User? user) {
          if (user == null) {
            setState(() {
              loggedin = false;
            });
          } else {
            String? uid = widget.auth.currentUser?.uid;
            if (uid != null) {
              widget.db.collection("users").doc(uid).get().then((res) {
                if (!res.exists) {
                  res.reference.set({"admin": false});
                } else if (res.get('admin') == true) {
                  admin = true;
                }
                setState(() {
                  loggedin = true;
                });
              });
            }
          }
        }
      );
    }

    if (!loggedin) {
      return showLogin(context);
    }
    return showHomePage(context);
  }

  Widget showLogin(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
          'CBC Attendance App',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      body: SizedBox.expand(
        child: Container(
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 300,
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(30),
                  child: Image.asset("assets/icon.png"),
                ),
              ),
              Text(
                "Welcome!",
                style: TextStyle(
                  fontSize: Theme.of(context).textTheme.headlineLarge?.fontSize,
                )
              ),
              FilledButton(
                onPressed: () { signInWithGoogle(context); },
                child: const Text("Sign In"),
              ),
            ]
          ),
        ),
      ),
    );
  }

  void signInWithGoogle(BuildContext context) async{
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth = await googleUser
        ?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    // Once signed in, return the UserCredential
    await widget.auth.signInWithCredential(credential);

    if (widget.auth.currentUser != null) {
      String? name = widget.auth.currentUser?.displayName;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: (name != null) ? Text('Welcome $name!') : const Text('Welcome!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget showHomePage(BuildContext context) {
    // This method is rerun every time setState is called
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = EventsView();
        break;
      case 1:
        page = SettingsView(admin: admin);
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(
          'CBC Attendance App',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      body: Container(
        color: Theme.of(context).colorScheme.surface,
        child: page,
      ),
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.event),
            label: 'Events',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        selectedIndex: selectedIndex,    // ← Change to this.
        onDestinationSelected: (value) {
          setState(() {
            selectedIndex = value;
          });
        },
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
    );
  }
}
