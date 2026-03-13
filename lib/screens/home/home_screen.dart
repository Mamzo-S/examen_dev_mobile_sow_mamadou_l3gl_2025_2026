import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sunu_task/core/constants/app_colors.dart';
import 'package:sunu_task/core/constants/app_strings.dart';
import 'package:sunu_task/screens/home/tabs/dashboard_tab.dart';
import 'package:sunu_task/screens/home/tabs/projects_tab.dart';
import 'package:sunu_task/screens/home/tabs/profile_tab.dart';
import 'package:sunu_task/screens/home/tabs/tasks_tab.dart';

import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../projects/project_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // exemple de donnee pour le drawer
  final String userName = "Mamadou Sow";
  final String userEmail = "test@gmail.com";

  // Liste des ecrans pour chaque onglet
  final List<Widget> _screens = const [
    const DashboardTab(),
    const ProjectsTab(),
    const TasksTab(),
    const ProfileTab(),
  ];

  // on verifie si le FloatingActionButton doit etre afficher
  bool get _showFAB => _currentIndex == 0 || _currentIndex == 1;

  // pour changer l'onglet selectionne sur BottomNavigationBar et Drawer
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onFABPressed(BuildContext context) {
    if (_currentIndex == 0 || _currentIndex == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ProjectFormScreen(),
        ),
      );
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Deconnexion'),
          content: const Text('Voulez-vous vraiment vous deconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text(AppStrings.logout),
            ),
          ],
        );
      },
    );
    if (confirm != true) return;

    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.appName),
        backgroundColor: AppColors.primary,
      ),

      // le drawer (menu lateral)
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Entete du drawer affichant nom, email et avatar
            UserAccountsDrawerHeader(
              accountName: Text(user?.name ?? ''),
              accountEmail: Text(user?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                child: Text(
                  user?.name.isNotEmpty == true ? user!.name[0] : '?',
                ),
              ),
              decoration: BoxDecoration(color: AppColors.primary),
            ),

            //liste des options de navigations
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text("Dashboard"),
              onTap: () {
                _onTabTapped(0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text("Projets"),
              onTap: () {
                _onTabTapped(1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text("Tâches"),
              onTap: () {
                _onTabTapped(2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Profil"),
              onTap: () {
                _onTabTapped(3);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Déconnexion"),
              onTap: () async {
                Navigator.pop(context);
                if (!context.mounted) return;
                await _logout(context);
              },
            ),
          ],
        ),
      ),

      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      floatingActionButton: _showFAB
          ? FloatingActionButton(
        onPressed: () => _onFABPressed(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      )
          : null,

      // bar de navigations en bas...
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder),
            label: "Projets",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: "Tâches",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profil",
          ),
        ],
      ),
    );
  }
}
