import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/routes.dart';
import '../../auth/data/auth_repository.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_menu_item.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String userName = "Nicole DLP"; // Initial user name

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ListView(
        children: [
          const SizedBox(height: 20),
          ProfileHeader(name: userName),
          const SizedBox(height: 40),
          ProfileMenuItem(
            title: 'Edit Profile',
            icon: Icons.person_outline,
            onTap: () async {
              final newName = await context.push(AppRoutes.editProfile, extra: userName);
              if (newName != null && newName is String) {
                setState(() {
                  userName = newName;
                });
              }
            },
          ),
          ProfileMenuItem(
            title: 'Terms & Conditions',
            icon: Icons.article_outlined,
            onTap: () {
              context.push(AppRoutes.terms);
            },
          ),
          ProfileMenuItem(
            title: 'Privacy Policy',
            icon: Icons.privacy_tip_outlined,
            onTap: () {
              context.push(AppRoutes.privacyPolicy);
            },
          ),
          ProfileMenuItem(
            title: 'Sign Out',
            icon: Icons.logout,
            onTap: () async {
              await AuthRepository().signOut();
              if (mounted) {
                context.go(AppRoutes.login);
              }
            },
          ),
        ],
      ),
    );
  }
}