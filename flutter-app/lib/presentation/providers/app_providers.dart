import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medcin_app/presentation/providers/auth_provider.dart';

class AppProviders extends StatelessWidget {
  const AppProviders({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthProvider>.value(
      value: AuthProvider.instance,
      child: child,
    );
  }
}