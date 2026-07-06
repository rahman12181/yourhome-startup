import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';

class RoleGuard extends StatelessWidget {
  final Widget child;
  final List<String> allowedRoles;
  final Widget? unauthorizedWidget;

  const RoleGuard({
    super.key,
    required this.child,
    required this.allowedRoles,
    this.unauthorizedWidget,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.user?.role ?? 'STUDENT';

    if (!allowedRoles.contains(userRole)) {
      if (unauthorizedWidget != null) {
        return unauthorizedWidget!;
      }
      // Show unauthorized message
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.block,
                size: 64,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Access Denied',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[300],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You don\'t have permission to view this page',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    return child;
  }
}

class AdminOnlyGuard extends StatelessWidget {
  final Widget child;

  const AdminOnlyGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRoles: ['ADMIN'],
      child: child,
    );
  }
}

class OwnerOnlyGuard extends StatelessWidget {
  final Widget child;

  const OwnerOnlyGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRoles: ['OWNER', 'ADMIN'],
      child: child,
    );
  }
}

class UserOnlyGuard extends StatelessWidget {
  final Widget child;

  const UserOnlyGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRoles: ['STUDENT', 'OWNER', 'ADMIN'],
      child: child,
    );
  }
}