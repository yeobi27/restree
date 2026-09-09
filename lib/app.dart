import 'package:flutter/material.dart';
import 'package:restree/core/router/app_router.dart';
import 'package:restree/core/theme/app_theme.dart';

class RestreeApp extends StatelessWidget {
  const RestreeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RESTREE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
