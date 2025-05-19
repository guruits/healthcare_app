// import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// import '../controller/start.controller.dart';
// import '../widgets/language.widgets.dart';
// import 'home.dart';
//
// class Start extends StatefulWidget {
//   @override
//   _StartScreenState createState() => _StartScreenState();
// }
//
// class _StartScreenState extends State<Start> {
//   final StartController _controller = StartController();
//   late Future<String> _userRoleFuture;
//   late Future<List<Map<String, dynamic>>> _roleOptionsFuture;
//
//   @override
//   void initState() {
//     super.initState();
//     _userRoleFuture = _controller.getUserRole();
//     _roleOptionsFuture = _initializeRoleOptions();
//   }
//
//   Future<List<Map<String, dynamic>>> _initializeRoleOptions() async {
//     final role = await _controller.getUserRole();
//     return _controller.getOptionsForRole(role);
//   }
//
//   void navigateToScreen(Widget screen) {
//     Navigator.of(context).pushReplacement(
//       MaterialPageRoute(builder: (_) => screen),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;
//     final screenWidth = MediaQuery.of(context).size.width;
//
//     int crossAxisCount = screenWidth > 600 ? 4 : 2;
//     double fontSize = screenWidth > 600 ? 16.0 : 12.0;
//     double imageSize = screenWidth > 600 ? 150.0 : 100.0;
//
//     return FutureBuilder<List<Map<String, dynamic>>>(
//       future: _roleOptionsFuture,
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Scaffold(
//             body: Center(child: CircularProgressIndicator()),
//           );
//         }
//
//         if (snapshot.hasError) {
//           return Scaffold(
//             body: Center(child: Text('Error loading screens: ${snapshot.error}')),
//           );
//         }
//
//         final roleOptions = snapshot.data ?? [];
//
//         return Scaffold(
//           appBar: AppBar(
//             leading: IconButton(
//               icon: Icon(Icons.logout),
//               tooltip: l10n.logout,
//               onPressed: () async {
//                 // Show confirmation dialog
//                 bool? confirmLogout = await showDialog<bool>(
//                   context: context,
//                   builder: (BuildContext context) {
//                     return AlertDialog(
//                       title: Text('Confirm Logout'),
//                       content: Text('Are you sure you want to log out?'),
//                       actions: <Widget>[
//                         TextButton(
//                           onPressed: () {
//                             Navigator.of(context).pop(false);
//                           },
//                           child: Text('Cancel'),
//                         ),
//                         TextButton(
//                           onPressed: () {
//                             Navigator.of(context).pop(true);
//                           },
//                           child: Text('Logout'),
//                         ),
//                       ],
//                     );
//                   },
//                 );
//
//                 if (confirmLogout == true) {
//                   await _controller.clearUserData();
//                   navigateToScreen(Home());
//                 }
//               },
//
//             ),
//             actions: [
//               LanguageToggle(),
//             ],
//           ),
//           backgroundColor: Colors.white,
//           body: Padding(
//             padding: EdgeInsets.all(10.0),
//             child: roleOptions.isEmpty
//                 ? Center(child: Text('No screens available for your role'))
//                 : GridView.builder(
//               gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: crossAxisCount,
//                 crossAxisSpacing: 10,
//                 mainAxisSpacing: 10,
//                 childAspectRatio: 1.0,
//               ),
//               itemCount: roleOptions.length,
//               itemBuilder: (context, index) {
//                 final option = roleOptions[index];
//                 final localizedTitle = _controller.getLocalizedTitle(
//                     context, option['title']);
//                 return _buildGridItem(
//                     localizedTitle,
//                     option['screen'],
//                     option['imageTitle'],
//                     fontSize,
//                     imageSize);
//               },
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildGridItem(String localizedTitle, Widget screen, String imageTitle,
//       double fontSize, double imageSize) {
//     return GestureDetector(
//       onTap: () => navigateToScreen(screen),
//       child: Card(
//         elevation: 5,
//         color: Colors.white,
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Flexible(
//               child: Padding(
//                 padding: EdgeInsets.all(25.0),
//                 child: Image.asset(
//                   'assets/images/${imageTitle.toLowerCase()}.png',
//                   height: imageSize,
//                   width: imageSize,
//                   fit: BoxFit.contain,
//                 ),
//               ),
//             ),
//             Padding(
//               padding: EdgeInsets.all(8.0),
//               child: Text(
//                 localizedTitle,
//                 style: TextStyle(
//                     fontSize: fontSize,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black),
//                 textAlign: TextAlign.center,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../controller/start.controller.dart';
import '../widgets/language.widgets.dart';
import 'home.dart';

class Start extends StatefulWidget {
  @override
  _StartScreenState createState() => _StartScreenState();
}

class _StartScreenState extends State<Start> with SingleTickerProviderStateMixin {
  final StartController _controller = StartController();
  late Future<String> _userRoleFuture;
  late Future<List<Map<String, dynamic>>> _roleOptionsFuture;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _userRoleFuture = _controller.getUserRole();
    _roleOptionsFuture = _initializeRoleOptions();

    // Setup fade-in animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn)
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _initializeRoleOptions() async {
    final role = await _controller.getUserRole();
    return _controller.getOptionsForRole(role);
  }

  void navigateToScreen(Widget screen) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: Duration(milliseconds: 300),
      ),
    );
  }

  Future<void> _showLogoutDialog() async {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width > 600 ? 400.0 : screenSize.width * 0.85;

    bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            width: dialogWidth,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: theme.dialogBackgroundColor,
              elevation: 24,
              title: Row(
                children: [
                  Icon(
                    Icons.logout,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Confirm Logout',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Are you sure you want to log out?',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'You will need to sign in again to access your dashboard.',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Logout',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
              actionsPadding: EdgeInsets.only(right: 16, bottom: 16, top: 8),
              contentPadding: EdgeInsets.fromLTRB(24, 20, 24, 16),
              titlePadding: EdgeInsets.fromLTRB(24, 24, 24, 8),
            ),
          ),
        );
      },
    );

    if (confirmLogout == true) {
      await _controller.clearUserData();
      navigateToScreen(Home());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDarkMode = theme.brightness == Brightness.dark;

    // Responsive breakpoints
    int crossAxisCount = screenWidth > 1200 ? 5 : (screenWidth > 900 ? 4 : (screenWidth > 600 ? 3 : 2));
    double fontSize = screenWidth > 1200 ? 18.0 : (screenWidth > 600 ? 16.0 : 14.0);
    double imageSize = screenWidth > 1200 ? 160.0 : (screenWidth > 600 ? 130.0 : 90.0);
    double gridPadding = screenWidth > 600 ? 24.0 : 16.0;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _roleOptionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Custom branded loading indicator
                  Container(
                    width: 100,
                    height: 100,
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: isDarkMode
                              ? Colors.black26
                              : Colors.black12,
                          blurRadius: 20,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                      strokeWidth: 6.0,
                    ),
                  ),
                  SizedBox(height: 32),
                  Text(
                    'Loading your dashboard...',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Center(
              child: Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode
                          ? Colors.black26
                          : Colors.black12,
                      blurRadius: 20,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                width: screenWidth > 600 ? 500 : screenWidth * 0.85,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                        Icons.error_outline,
                        size: 70,
                        color: theme.colorScheme.error
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Error Loading Dashboard',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '${snapshot.error}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _roleOptionsFuture = _initializeRoleOptions();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Retry',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final roleOptions = snapshot.data ?? [];

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: isDarkMode
                ? theme.appBarTheme.backgroundColor?.withOpacity(0.85)
                : theme.appBarTheme.backgroundColor?.withOpacity(0.92),
            // title: Row(
            //   children: [
            //     Container(
            //       height: 32,
            //       width: 32,
            //       decoration: BoxDecoration(
            //         color: theme.colorScheme.primary,
            //         shape: BoxShape.circle,
            //       ),
            //       child: Icon(
            //         Icons.dashboard_customize,
            //         color: theme.colorScheme.onPrimary,
            //         size: 16,
            //       ),
            //     ),
            //     SizedBox(width: 12),
            //     Text(
            //       'My Dashboard',
            //       style: TextStyle(
            //         fontWeight: FontWeight.bold,
            //         fontSize: 20,
            //       ),
            //     ),
            //   ],
            // ),
            leading: IconButton(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? theme.colorScheme.surface.withOpacity(0.5)
                      : theme.colorScheme.surface.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              tooltip: l10n.logout,
              onPressed: _showLogoutDialog,
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: LanguageToggle(),
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode
                    ? [
                  theme.scaffoldBackgroundColor,
                  theme.scaffoldBackgroundColor.withOpacity(0.95),
                ]
                    : [
                  Color(0xFFF8F9FA),
                  Color(0xFFE9ECEF),
                ],
              ),
            ),
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: EdgeInsets.all(gridPadding),
                  child: roleOptions.isEmpty
                      ? Center(
                    child: Container(
                      width: screenWidth > 600 ? 400 : screenWidth * 0.85,
                      padding: EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode
                                ? Colors.black26
                                : Colors.black12,
                            blurRadius: 20,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                              Icons.apps_outlined,
                              size: 80,
                              color: theme.disabledColor
                          ),
                          SizedBox(height: 24),
                          Text(
                            'No modules available',
                            style: theme.textTheme.headlineSmall,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'There are no modules assigned to your current role. Please contact support if you believe this is an error.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                      : GridView.builder(
                    padding: EdgeInsets.only(top: 12, bottom: 24),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: roleOptions.length,
                    itemBuilder: (context, index) {
                      final option = roleOptions[index];
                      final localizedTitle = _controller.getLocalizedTitle(
                          context, option['title']);
                      return _buildGridItem(
                          localizedTitle,
                          option['screen'],
                          option['imageTitle'],
                          fontSize,
                          imageSize);
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridItem(String localizedTitle, Widget screen, String imageTitle,
      double fontSize, double imageSize) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Generate a unique color based on the title
    final titleHash = localizedTitle.hashCode;
    final hue = (titleHash % 360).abs().toDouble();
    final accentColor = HSLColor.fromAHSL(
        1.0,
        hue,
        isDarkMode ? 0.5 : 0.7,
        isDarkMode ? 0.5 : 0.7
    ).toColor();

    return Hero(
      tag: 'menu-$imageTitle',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => navigateToScreen(screen),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode
                    ? [
                  theme.cardColor,
                  theme.cardColor.withOpacity(0.8),
                ]
                    : [
                  Colors.white,
                  Color(0xFFF8F9FA),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode
                      ? Colors.black26
                      : Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Colored header strip
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 18.0, horizontal: 24.0),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Subtle icon background
                        Opacity(
                          opacity: 0.07,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accentColor,
                            ),
                            width: imageSize * 1.5,
                            height: imageSize * 1.5,
                          ),
                        ),
                        // Main image
                        Image.asset(
                          'assets/images/${imageTitle.toLowerCase()}.png',
                          height: imageSize,
                          width: imageSize,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ),
                ),
                // Divider
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: isDarkMode
                        ? theme.dividerColor.withOpacity(0.2)
                        : theme.dividerColor.withOpacity(0.1),
                  ),
                ),
                // Title
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        localizedTitle,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.titleMedium?.color,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}