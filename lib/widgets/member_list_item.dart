import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/models/member_model.dart';
import 'package:lucasbeatsfederacao/models/user_model.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart';
import 'package:lucasbeatsfederacao/services/voip_service.dart';
import 'package:lucasbeatsfederacao/screens/call_screen.dart';
import 'package:lucasbeatsfederacao/models/call_model.dart';

class MemberListItem extends StatelessWidget {
  final Member member;
  final UserModel currentUser;
  final Function(Member, String) onMemberAction;

  const MemberListItem({
    super.key,
    required this.member,
    required this.currentUser,
    required this.onMemberAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.grey.shade800.withOpacity(0.8),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: _getRoleColor(member.role),
              backgroundImage: member.avatar != null 
                ? NetworkImage(member.avatar!)
                : null,
              child: member.avatar == null
                ? Text(
                    member.username.isNotEmpty ? member.username[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
            ),
            if (member.isOnline)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                member.username,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getRoleColor(member.role),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getRoleDisplayName(member.role),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          member.isOnline ? 'Online' : 'Offline',
          style: TextStyle(
            color: member.isOnline ? Colors.green : Colors.grey.shade400,
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botão de chamada (apenas se o membro estiver online e não for o próprio usuário)
            if (member.isOnline && member.userId != currentUser.id)
              IconButton(
                icon: const Icon(Icons.call, color: Colors.green, size: 20),
                onPressed: () => _initiateCall(context),
                tooltip: 'Fazer chamada',
              ),
            
            // Menu de opções (apenas se pode gerenciar o membro)
            if (_canManageMember())
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (action) => onMemberAction(member, action),
                itemBuilder: (context) => _buildMenuItems(),
              ),
          ],
        ),
      ),
    );
  }

  void _initiateCall(BuildContext context) async {
    final voipService = Provider.of<VoipService>(context, listen: false);
    
    // Verificar se já está em uma chamada
    if (voipService.isInCall) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você já está em uma chamada.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Mostrar diálogo de confirmação
    final bool? shouldCall = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Fazer Chamada',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Deseja fazer uma chamada para ${member.username}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Chamar'),
          ),
        ],
      ),
    );

    if (shouldCall == true) {
      // Iniciar a chamada
      final success = await voipService.initiateCall(member.userId, member.username);
      
      if (success) {
        // Navegar para a tela de chamada
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CallScreen(
              call: Call(
                id: voipService.currentCall!.id,
                callerId: currentUser.id,
                receiverId: member.userId,
                type: CallType.audio,
                status: CallStatus.pending,
                startTime: DateTime.now(),
              ),
              isIncoming: false,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Falha ao iniciar a chamada. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _canManageMember() {
    // Verifica se o usuário atual pode gerenciar este membro
    if (currentUser.id == member.userId) return false; // Não pode gerenciar a si mesmo
    
    // ADM pode gerenciar todos
    if (currentUser.role == Role.federationAdmin) return true;
    
    // Líder pode gerenciar sub-líderes e membros
    if (currentUser.role == Role.clanLeader && 
        (member.role == Role.clanSubLeader || member.role == Role.clanMember)) {
      return true;
    }
    
    // Sub-líder pode gerenciar apenas membros
    if (currentUser.role == Role.clanSubLeader && member.role == Role.clanMember) {
      return true;
    }
    
    return false;
  }

  List<PopupMenuEntry<String>> _buildMenuItems() {
    List<PopupMenuEntry<String>> items = [];
    
    // Opções baseadas no role do usuário atual e do membro
    if (currentUser.role == Role.federationAdmin || currentUser.role == Role.clanLeader) {
      if (member.role == Role.clanMember) {
        items.add(const PopupMenuItem(
          value: 'promote',
          child: Row(
            children: [
              Icon(Icons.arrow_upward, color: Colors.green),
              SizedBox(width: 8),
              Text('Promover'),
            ],
          ),
        ));
      }
      
      if (member.role == Role.clanSubLeader) {
        items.add(const PopupMenuItem(
          value: 'demote',
          child: Row(
            children: [
              Icon(Icons.arrow_downward, color: Colors.orange),
              SizedBox(width: 8),
              Text('Rebaixar'),
            ],
          ),
        ));
      }
      
      items.add(const PopupMenuItem(
        value: 'remove',
        child: Row(
          children: [
            Icon(Icons.person_remove, color: Colors.red),
            SizedBox(width: 8),
            Text('Remover'),
          ],
        ),
      ));
    }
    
    // Todos podem enviar mensagem
    items.add(const PopupMenuItem(
      value: 'message',
      child: Row(
        children: [
          Icon(Icons.message, color: Colors.blue),
          SizedBox(width: 8),
          Text('Mensagem'),
        ],
      ),
    ));
    
    return items;
  }

  Color _getRoleColor(Role role) {
    switch (role) {
      case Role.federationAdmin:
        return Colors.red;
      case Role.clanLeader:
        return Colors.orange;
      case Role.clanSubLeader:
        return Colors.yellow.shade600;
      case Role.clanMember:
        return Colors.blue;
      case Role.guest:
        return Colors.grey;
      case Role.adm:
        return Colors.purple;
      case Role.user:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _getRoleDisplayName(Role role) {
    switch (role) {
      case Role.federationAdmin:
        return 'ADM FEDERAÇÃO';
      case Role.clanLeader:
        return 'LÍDER CLÃ';
      case Role.clanSubLeader:
        return 'SUB-LÍDER CLÃ';
      case Role.clanMember:
        return 'MEMBRO CLÃ';
      case Role.guest:
        return 'CONVIDADO';
      case Role.adm:
        return 'ADMINISTRADOR';
      case Role.user:
        return 'USUÁRIO';
      default:
        return role.toString().split('.').last.toUpperCase();
    }
  }
}

