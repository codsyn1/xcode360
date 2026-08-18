import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'admin_support_cubit.dart';
import 'admin_support_state.dart';

class AdminSupportScreen extends StatelessWidget {
  const AdminSupportScreen({super.key});

  static const categories = [
    '',
    'Live Chat',
    'General Inquiries',
    'Technical Issues',
    'Account & Profile',
    'Payments & Billing',
    'Exchange Order Support',
    'Report a User',
    'Privacy & Security',
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminSupportCubit()..init(),
      child: Scaffold(
        backgroundColor: const Color(0xFF232323),
        appBar: AppBar(
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
              tooltip: 'Open chat list',
            ),
          ),
          title: const Text('Admin • Support'),
          backgroundColor: const Color(0xFF2C2C2C),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        // Drawer holds the sidebar on small screens
        drawer: Drawer(
          backgroundColor: const Color(0xFF2C2C2C),
          child: SafeArea(
            child: BlocBuilder<AdminSupportCubit, AdminSupportState>(
              builder: (context, state) {
                return _Sidebar(state: state, inDrawer: true);
              },
            ),
          ),
        ),
        body: BlocConsumer<AdminSupportCubit, AdminSupportState>(
          listenWhen: (p, c) => p.error != c.error || p.message != c.message,
          listener: (context, state) {
            if (state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error!, style: const TextStyle(color: Colors.white)),
                  backgroundColor: Colors.redAccent,
                ),
              );
            } else if (state.message != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message!, style: const TextStyle(color: Colors.white))),
              );
            }
          },
          builder: (context, state) {
            final tickets = state.filteredTickets;
            final isWide = MediaQuery.of(context).size.width >= 900;
            Widget sidebar = SizedBox(
              width: 300,
              child: _Sidebar(state: state),
            );

            Widget messagesPane = Expanded(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      state.selectedTicket == null
                          ? 'Select a ticket to view messages'
                          : '${state.selectedTicket!.userName} • PIN: ${state.selectedTicket!.userPin}',
                      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Divider(height: 1, color: Colors.white10),
                  Expanded(
                    child: state.selectedTicket == null
                        ? const Center(child: Text('No ticket selected', style: TextStyle(color: Colors.white38)))
                        : state.messagesLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: state.messages.length,
                                itemBuilder: (context, index) {
                                  final m = state.messages[index];
                                  final isAdmin = m.senderId == 'admin';
                                  final name = isAdmin ? 'Admin' : (state.selectedTicket?.userName.isNotEmpty == true ? state.selectedTicket!.userName : 'User');
                                  final ts = DateFormat('yyyy-MM-dd HH:mm').format(m.timestamp.toLocal());
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Column(
                                      crossAxisAlignment: isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                      children: [
                                        Align(
                                          alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: isAdmin ? Colors.amber : Colors.white10,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              m.text,
                                              style: TextStyle(color: isAdmin ? Colors.black : Colors.white),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$name • $ts',
                                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                  ),
                  if (state.selectedTicket != null)
                    _MessageComposer(onSend: (text) => context.read<AdminSupportCubit>().sendAdminMessage(text)),
                ],
              ),
            );
            if (isWide) {
              return Row(
                children: [
                  sidebar,
                  const VerticalDivider(width: 1, color: Colors.white10),
                  messagesPane,
                ],
              );
            } else {
              // On small screens, use Drawer for sidebar and only show messages here
              return messagesPane;
            }
          },
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final AdminSupportState state;
  final bool inDrawer;
  const _Sidebar({required this.state, this.inDrawer = false});

  @override
  Widget build(BuildContext context) {
    final tickets = state.filteredTickets;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.category, color: Colors.white70),
              SizedBox(width: 8),
              Text('Categories', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: AdminSupportScreen.categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final c = AdminSupportScreen.categories[i];
              final selected = state.selectedCategory == c;
              return ChoiceChip(
                label: Text(c.isEmpty ? 'All' : c),
                selected: selected,
                onSelected: (_) => context.read<AdminSupportCubit>().setCategoryFilter(c),
              );
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: Text('User Tickets', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: state.loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: tickets.length,
                  itemBuilder: (context, index) {
                    final t = tickets[index];
                    final isSelected = state.selectedTicket?.id == t.id;
                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: Colors.white10,
                      leading: CircleAvatar(child: Text(t.userName.isNotEmpty ? t.userName[0].toUpperCase() : '?')),
                      title: Text(t.userName.isEmpty ? '(no name)' : t.userName, style: const TextStyle(color: Colors.white)),
                      subtitle: Text('PIN: ${t.userPin} • ${t.category}', style: const TextStyle(color: Colors.white60)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                      onTap: () {
                        context.read<AdminSupportCubit>().selectTicket(t);
                        // Close drawer if we're in it
                        if (inDrawer) {
                          Navigator.of(context).maybePop();
                        }
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _MessageComposer extends StatefulWidget {
  final ValueChanged<String> onSend;
  const _MessageComposer({required this.onSend});

  @override
  State<_MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<_MessageComposer> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(color: Color(0xFF2C2C2C), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, -2))]),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Type a reply...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.amber),
              onPressed: _send,
            ),
          ],
        ),
      ),
    );
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
  }
}
