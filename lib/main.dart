import 'dart:async';
import 'dart:math' as math;

import 'package:attendance_app/util/logger.dart';
import 'package:attendance_app/util/responsive.dart';
import 'package:attendance_app/util/theme.dart';
import 'package:attendance_app/util/theme_controller.dart';
import 'package:attendance_app/view/eventsview.dart';
import 'package:attendance_app/view/historyview.dart';
import 'package:attendance_app/view/settingsview.dart';
import 'package:attendance_app/view/widgets/empty_state.dart';
import 'package:attendance_app/view/widgets/google_sign_in_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Web OAuth 2.0 client ID from Firebase / google-services.json (client_type: 3).
// Required as `serverClientId` so Google Sign-In returns an idToken we can
// exchange for a Firebase credential on Android.
const String _googleServerClientId =
    '1017067702131-ssslbd1im492smpljmm1j4prs06o5ji6.apps.googleusercontent.com';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await GoogleSignIn.instance.initialize(
    serverClientId: _googleServerClientId,
  );
  await themeController.load();
  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    Logger.init();
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeController,
      builder: (context, mode, _) => MaterialApp(
        title: 'CBC Attendance',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: mode,
        home: HomePageView(),
      ),
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
  bool loggedIn = false, initialized = false, authLoading = true;
  String role = "disabled";
  List<Widget> pages = [];
  List<NavigationDestination> tabs = [];
  StreamSubscription<GoogleSignInAuthenticationEvent>? _googleEventsSub;

  void buildPages() {
    final eventPage = EventsView();
    const historyPage = HistoryView();
    final settingsPage = SettingsView(role: role);

    const eventTab = NavigationDestination(
      icon: Icon(Icons.event_outlined),
      selectedIcon: Icon(Icons.event_rounded),
      label: 'Events',
    );
    const historyTab = NavigationDestination(
      icon: Icon(Icons.history_outlined),
      selectedIcon: Icon(Icons.history_rounded),
      label: 'History',
    );
    const settingsTab = NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings_rounded),
      label: 'Settings',
    );

    switch (role) {
      case "admin":
        pages = [eventPage, const HistoryView(), settingsPage];
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

    if (selectedIndex >= pages.length) selectedIndex = 0;
  }

  @override
  void initState() {
    super.initState();
    widget.auth.authStateChanges().listen((User? user) {
      if (!mounted) return;
      if (user == null) {
        setState(() {
          loggedIn = false;
          authLoading = false;
        });
      } else {
        final uid = user.uid;
        widget.db.collection("users").doc(uid).get().then((res) {
          if (!mounted) return;
          if (!res.exists) {
            res.reference.set({"email": user.email, "role": "disabled"});
          } else {
            role = res.get("role");
          }
          setState(() {
            loggedIn = true;
            authLoading = false;
            buildPages();
          });
        });
      }
    });

    // Centralised Google Sign-In event handling. On Android/iOS this fires
    // after `authenticate()`; on web it fires when the user clicks the
    // Google-rendered button. Either way we exchange the idToken for a
    // Firebase credential here.
    _googleEventsSub = GoogleSignIn.instance.authenticationEvents.listen(
      _handleGoogleAuthEvent,
      onError: (Object e) =>
          debugPrint('Google authentication event error: $e'),
    );
  }

  @override
  void dispose() {
    _googleEventsSub?.cancel();
    super.dispose();
  }

  Future<void> _handleGoogleAuthEvent(
    GoogleSignInAuthenticationEvent event,
  ) async {
    switch (event) {
      case GoogleSignInAuthenticationEventSignIn(:final user):
        final idToken = user.authentication.idToken;
        if (idToken == null) {
          debugPrint('Google Sign-In returned a null idToken.');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sign-in failed: missing idToken from Google.'),
            ),
          );
          return;
        }
        try {
          final credential = GoogleAuthProvider.credential(idToken: idToken);
          await widget.auth.signInWithCredential(credential);
          if (!mounted) return;
          final name = widget.auth.currentUser?.displayName;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: name != null
                  ? Text('Welcome $name!')
                  : const Text('Welcome!'),
            ),
          );
        } catch (e) {
          debugPrint('Firebase sign-in failed: $e');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sign-in failed: $e')),
          );
        }
      case GoogleSignInAuthenticationEventSignOut():
        // Google revoked / signed out — keep Firebase in sync.
        if (widget.auth.currentUser != null) {
          await widget.auth.signOut();
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (authLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!loggedIn) return _LoginScreen(onSignIn: signInWithGoogle);
    return _showHomePage(context);
  }

  /// Mobile entry point for the sign-in flow. The web flow is driven
  /// entirely by Google's rendered button (see [GoogleSignInButton]) and
  /// arrives via [_handleGoogleAuthEvent]. On mobile, [authenticate] also
  /// fires that same event, so we don't exchange the credential here —
  /// we only surface user-cancellation and platform errors to the UI.
  Future<void> signInWithGoogle(BuildContext context) async {
    if (kIsWeb) return;
    try {
      await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return;
      debugPrint('Google sign-in failed: ${e.code} ${e.description}');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign-in failed: ${e.description ?? e.code.name}'),
        ),
      );
    } catch (e) {
      debugPrint('Google sign-in failed: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-in failed: $e')),
      );
    }
  }

  Widget _showHomePage(BuildContext context) {
    final theme = Theme.of(context);

    if (role == "disabled") {
      return Scaffold(
        appBar: AppBar(title: const Text('CBC Attendance')),
        body: EmptyState(
          icon: Icons.lock_clock_rounded,
          title: 'Hang tight — your access is pending',
          message: 'An administrator needs to grant your account a role. '
              'Once that\'s done, the app will unlock automatically.',
          action: OutlinedButton.icon(
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
          ),
        ),
      );
    }

    final page = (selectedIndex >= 0 && selectedIndex < pages.length)
        ? pages[selectedIndex]
        : pages.first;
    final boundedPage = ContentBounds(child: page);
    final useRail = windowSizeOf(context).isWide;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CBC Attendance'),
      ),
      body: useRail
          ? Row(
              children: [
                _HomeNavRail(
                  destinations: tabs,
                  selectedIndex: selectedIndex,
                  onSelected: (i) => setState(() => selectedIndex = i),
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: theme.colorScheme.outlineVariant
                      .withValues(alpha: 0.5),
                ),
                Expanded(child: boundedPage),
              ],
            )
          : boundedPage,
      bottomNavigationBar: useRail
          ? null
          : NavigationBar(
              backgroundColor: theme.colorScheme.surface,
              destinations: tabs,
              selectedIndex: selectedIndex,
              onDestinationSelected: (value) {
                setState(() => selectedIndex = value);
              },
            ),
    );
  }
}

/// Side rail used as the primary navigation on medium+ screens.
class _HomeNavRail extends StatelessWidget {
  const _HomeNavRail({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<NavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final isExpanded =
        windowSizeOf(context) == WindowSizeClass.expanded ||
            windowSizeOf(context) == WindowSizeClass.large;
    return NavigationRail(
      extended: isExpanded,
      minWidth: 72,
      minExtendedWidth: 200,
      groupAlignment: -0.9,
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      labelType: isExpanded ? NavigationRailLabelType.none : null,
      destinations: [
        for (final d in destinations)
          NavigationRailDestination(
            icon: d.icon,
            selectedIcon: d.selectedIcon,
            label: Text(d.label),
          ),
      ],
    );
  }
}

class _LoginScreen extends StatefulWidget {
  const _LoginScreen({required this.onSignIn});

  final Future<void> Function(BuildContext context) onSignIn;

  @override
  State<_LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<_LoginScreen> {
  bool busy = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // Use a side-by-side layout whenever the window has reasonable
    // horizontal room *or* is wider than it is tall (phone landscape,
    // tablet landscape, desktop browser).
    final useSideBySide = size.width >= 720 || size.width > size.height;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Top of photo is sky (light) → dark status bar icons read best.
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: useSideBySide
            ? _buildSideBySide(context)
            : _buildStacked(context, size),
      ),
    );
  }

  /// Tall/portrait windows: hero photo on top (capped so it never crowds
  /// the button on short or landscape-phone windows), sign-in centred in
  /// the remaining space.
  Widget _buildStacked(BuildContext context, Size size) {
    // Don't let the hero exceed its natural full-width aspect (5:4) — that
    // way phones still see the whole photo and tablets in portrait don't
    // get a stretched-looking band.
    final heroHeight = math.min(size.height * 0.55, size.width * 1.25);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: heroHeight,
          child: _buildHero(context),
        ),
        Expanded(
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Center(child: _buildSignInColumn()),
            ),
          ),
        ),
      ],
    );
  }

  /// Wide/landscape windows: photo fills the left half, sign-in lives in
  /// a max-width column on the right so the button doesn't sprawl across
  /// a full desktop browser.
  Widget _buildSideBySide(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _buildHero(context)),
        Expanded(
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildSignInColumn(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Hero photo with the soft bottom gradient and overlaid title.
  /// Always fills its parent; the parent is responsible for sizing it.
  Widget _buildHero(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/cbc_church.png',
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x00000000), Color(0xB3000000)],
              stops: [0.55, 1.0],
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Attendance',
                style: textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Changi Baptist Church',
                style: textTheme.titleMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSignInColumn() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (busy) ...[
          const Center(
            child: SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          ),
          const SizedBox(height: 16),
        ],
        GoogleSignInButton(
          onPressed: busy
              ? () {}
              : () async {
                  setState(() => busy = true);
                  try {
                    await widget.onSignIn(context);
                  } finally {
                    if (mounted) setState(() => busy = false);
                  }
                },
        ),
      ],
    );
  }
}
