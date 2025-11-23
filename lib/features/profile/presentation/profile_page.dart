import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/routes.dart';
import '../../auth/data/auth_repository.dart';
import 'widgets/profile_menu_item.dart';
import 'widgets/hero_menu_item.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ListView(
        children: [
          const SizedBox(height: 60),
          HeroMenuItem(
            title: 'Premium Membership',
            subtitle: 'Unlock full features',
            onTap: () {},
          ),
          ProfileMenuItem(
            title: 'Edit Profile',
            icon: Icons.person_outline,
            onTap: () {
              context.push(AppRoutes.editProfile);
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