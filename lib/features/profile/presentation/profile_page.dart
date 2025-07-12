import 'package:flutter/material.dart';
import '../../legal/privacy_policy_page.dart';
import '../../legal/terms_page.dart';
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
              final newName = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfilePage(currentName: userName),
                ),
              );
              if (newName != null && newName is String) {
                setState(() {
                  userName = newName;
                });
              }
            },
          ),
          ProfileMenuItem(
            title: 'Terms & Conditions',
            icon: Icons.description_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TermsPage()),
              );
            },
          ),
          ProfileMenuItem(
            title: 'Privacy Policy',
            icon: Icons.privacy_tip_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}