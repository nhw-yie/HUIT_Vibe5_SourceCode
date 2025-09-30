// import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/home/presentation/pages/home_page.dart';
// import '../features/map/presentation/pages/map_page.dart';
// import '../features/details/presentation/pages/details_page.dart';
// import '../features/settings/presentation/pages/settings_page.dart';

final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    // GoRoute(
    //   path: '/map',
    //   builder: (context, state) => const MapPage(),
    // ),
    // GoRoute(
    //   path: '/details',
    //   builder: (context, state) => const DetailsPage(),
    // ),
    // GoRoute(
    //   path: '/settings',
    //   builder: (context, state) => const SettingsPage(),
    // ),
  ],
);
