import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Removed Firebase import
import '../../services/auth_service.dart'; // Corrected path
import '../../utils/logger.dart'; // Corrected path
import '../call_history_page.dart'; // Import da página de histórico
import '../profile_screen.dart'; // Import da tela de perfil

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configurações',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          
          // Seção VoIP
          _buildSection(
            context,
            'VoIP',
            [
              _buildSettingItem(
                context,
                icon: Icons.history,
                title: 'Histórico de Chamadas',
                subtitle: 'Ver chamadas realizadas e recebidas',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CallHistoryPage(),
                    ),
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Seção Conta
          _buildSection(
            context,
            'Conta',
            [
              _buildSettingItem(
                context,
                icon: Icons.person,
                title: 'Perfil',
                subtitle: 'Editar informações do perfil',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
              ),
              _buildSettingItem(
                context,
                icon: Icons.security,
                title: 'Privacidade',
                subtitle: 'Configurações de privacidade',
                onTap: () {
                  // TODO: Implementar navegação para privacidade
                },
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Seção App
          _buildSection(
            context,
            'Aplicativo',
            [
              _buildSettingItem(
                context,
                icon: Icons.notifications,
                title: 'Notificações',
                subtitle: 'Configurar notificações',
                onTap: () {
                  // TODO: Implementar configurações de notificação
                },
              ),
              _buildSettingItem(
                context,
                icon: Icons.info,
                title: 'Sobre',
                subtitle: 'Informações do aplicativo',
                onTap: () {
                  // TODO: Implementar página sobre
                },
              ),
            ],
          ),
          
          const Spacer(),
          
          // Botão de logout
          Center(
            child: ElevatedButton.icon(
              onPressed: () async {
                try {
                  final authService = Provider.of<AuthService>(context, listen: false);
                  Logger.info("Attempting logout via AuthService...");
                  await authService.logout();
                  Logger.info("Logout successful via AuthService.");
                } catch (e) {
                  Logger.error("Error during logout", error: e);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao fazer logout: ${e.toString()}')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sair'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 12,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
      onTap: onTap,
    );
  }
}

