import 'package:attendance_app/util/logger.dart';
import 'package:attendance_app/view/eventsview.dart';
import 'package:attendance_app/view/historyview.dart';
import 'package:attendance_app/view/settingsview.dart';
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

  @override
  State<HomePageView> createState() => _HomePageViewState();
}

class _HomePageViewState extends State<HomePageView> {
  int selectedIndex = 0;
  bool loggedIn = false, initialized = false;
  String role = "disabled";
  List<Widget> pages = [];
  List<Widget> tabs = [];

  void buildPages() {
    Widget eventPage = EventsView(), historyPage = const HistoryView(), settingsPage = SettingsView(role: role);
    Widget eventTab = const NavigationDestination(
      icon: Icon(Icons.event),
      label: 'Events',
    );
    Widget historyTab = const NavigationDestination(
      icon: Icon(Icons.history),
      label: 'History'
    );
    Widget settingsTab = const NavigationDestination(
      icon: Icon(Icons.settings),
      label: 'Settings',
    );

    switch (role) {
      case "admin":
        pages = [eventPage, historyPage, settingsPage];
        tabs = [eventTab, historyTab, settingsTab];
      case "usher":
        pages = [eventPage, settingsPage];
        tabs = [eventTab, settingsTab];
      case "auditor":
        pages = [historyPage, settingsPage];
        tabs = [historyTab, settingsTab];
      default:
        pages = [settingsPage];
        tabs = [settingsTab];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!initialized) {
      widget.auth.authStateChanges().listen(
        (User? user) {
          print("hello");
          if (user == null) {
            setState(() {
              loggedIn = false;
            });
          } else {
            String? uid = widget.auth.currentUser?.uid;
            if (uid != null) {
              widget.db.collection("users").doc(uid).get().then((res) {
                if (!res.exists) {
                  res.reference.set({"role": "disabled"});
                } else {
                  role = res.get("role");
                }
                setState(() {
                  loggedIn = true;
                  print("logged in");
                  buildPages();
                });
              });
            }
          }
        }
      );
      setState(() {
        initialized = true;
      });
    }

    if (!loggedIn) {
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
    Widget page;
    if (0 <= selectedIndex && selectedIndex < pages.length) {
      page = pages[selectedIndex];
    } else {
      throw UnimplementedError('no widget for $selectedIndex');
    }

    return role != "disabled" ? Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
        destinations: tabs,
        selectedIndex: selectedIndex,    // ← Change to this.
        onDestinationSelected: (value) {
          setState(() {
            selectedIndex = value;
          });
        },
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
    ) : Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
          'CBC Attendance App',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      body: Container(
        color: Theme.of(context).colorScheme.surface,
        child: SettingsView(role: role),
      ),
    );
  }
}
