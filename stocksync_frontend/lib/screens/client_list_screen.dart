import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api_client.dart';
import '../auth/auth_provider.dart';
import 'client_form_screen.dart';

class ClientListScreen extends StatefulWidget {
  const ClientListScreen({super.key});
  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  bool _isLoading = false;
  List<dynamic> _clients = [];
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiClient.get('/clients');
      if (data is Map<String, dynamic>) {
        final list = data['data'];
        if (list is List) _clients = list;
      } else if (data is List) {
        _clients = data;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _delete(String id) async {
    try {
      await ApiClient.delete('/clients/$id');
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  String _getName(Map m) {
    for (final k in ['name','customerName','customer_name','customerFullName','clientName','customer','customerNameEn']) {
      final v = m[k];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString();
    }
    return '';
  }

  List<dynamic> get _filtered {
    if (_search.isEmpty) return _clients;
    final q = _search.toLowerCase();
    return _clients.where((c) {
      final name = _getName(c as Map).toLowerCase();
      return name.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isAdmin = auth.currentUser?.role == 'admin';
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(
                hintText: 'Search clients...',
                prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF4361EE)),
              ),
            ),
          ),
          Container(
            color: const Color(0xFFEEF2FF),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.people_alt_rounded, size: 16, color: Color(0xFF4361EE)),
                const SizedBox(width: 6),
                Text('${filtered.length} client${filtered.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF4361EE))),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFF4361EE),
              onRefresh: _load,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF4361EE)))
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 80, height: 80,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Icon(Icons.people_outline_rounded,
                                    size: 40, color: Color(0xFF4361EE)),
                              ),
                              const SizedBox(height: 16),
                              const Text('No clients found',
                                  style: TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0D1B2A))),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) {
                            final client = filtered[i] as Map<String, dynamic>;
                            final idVal = client['customerCode'] ?? client['customer_code'] ?? client['clientCode'] ?? client['code'] ?? client['_id'] ?? client['id'];
                            final id = idVal?.toString() ?? '';
                            final name = _getName(client);
                            final spec = (client['specialization'] ?? client['dealerType'])?.toString() ?? '';
                            final contact = (client['contact'] ?? client['customerContact'] ?? client['phone'] ?? client['mobile'])?.toString() ?? '—';
                            final address = (client['address'] ?? client['customerAddress'] ?? client['customer_address'] ?? client['addressLine'] ?? '')?.toString() ?? '';
                            final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4361EE).withOpacity(0.05),
                                    blurRadius: 10, offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onTap: () => _showDetails(client['_id']?.toString() ?? ''),
                                      child: Container(
                                        width: 48, height: 48,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                              colors: [Color(0xFF4361EE), Color(0xFF7B9EFF)]),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Center(
                                          child: Text(initials,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 18)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => _showDetails(client['_id']?.toString() ?? ''),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(name.isNotEmpty ? name : 'Unnamed',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 15,
                                                    color: Color(0xFF0D1B2A))),
                                            if (id.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text('Code: $id',
                                                  style: const TextStyle(
                                                      fontSize: 12, color: Color(0xFF6B7A9D))),
                                            ],
                                            if (spec.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFEEF2FF),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(spec,
                                                    style: const TextStyle(
                                                        fontSize: 11,
                                                        color: Color(0xFF4361EE),
                                                        fontWeight: FontWeight.w600)),
                                              ),
                                            ],
                                            if (contact.isNotEmpty && contact != '—') ...[
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(Icons.phone_outlined,
                                                      size: 13, color: Color(0xFF6B7A9D)),
                                                  const SizedBox(width: 4),
                                                  Text(contact,
                                                      style: const TextStyle(
                                                          fontSize: 12, color: Color(0xFF6B7A9D))),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (isAdmin)
                                      Row(
                                        children: [
                                          _iconBtn(Icons.edit_rounded, const Color(0xFF4361EE), () async {
                                            final updated = await Navigator.push<bool>(context,
                                              MaterialPageRoute(builder: (_) => ClientFormScreen(client: client)));
                                            if (updated == true) _load();
                                          }),
                                          _iconBtn(Icons.delete_outline_rounded, const Color(0xFFEF233C), () async {
                                            final ok = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                                title: const Text('Delete Client'),
                                                content: const Text('Are you sure you want to delete this client?'),
                                                actions: [
                                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                                  ElevatedButton(
                                                    onPressed: () => Navigator.pop(ctx, true),
                                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF233C)),
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (ok == true) await _delete(id);
                                          }),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () async {
                final created = await Navigator.push<bool>(context,
                    MaterialPageRoute(builder: (_) => const ClientFormScreen()));
                if (created == true) _load();
              },
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Add Client'),
            )
          : null,
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34, height: 34,
        margin: const EdgeInsets.only(left: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 17, color: color),
      ),
    );
  }

  Future<void> _showDetails(String id) async {
    if (!mounted || id.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: FutureBuilder<dynamic>(
                future: ApiClient.get('/clients/$id'),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF4361EE)));
                  }
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Failed to load details'),
                          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                        ],
                      ),
                    );
                  }
                  final data = snapshot.data;
                  Map<String, dynamic> client = {};
                  if (data is Map<String, dynamic>) client = data['data'] ?? data;

                  String r(List<String> keys) {
                    for (final k in keys) {
                      final v = client[k];
                      if (v != null && v.toString().trim().isNotEmpty) return v.toString();
                    }
                    return '';
                  }

                  final cname = r(['name','customerName','customer_name','customerFullName','clientName']);
                  final contact = r(['contact','customerContact','phone','mobile']);
                  final address = r(['address','customerAddress','customer_address','addressLine']);
                  final spec = r(['specialization','dealerType']);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 56, height: 56,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF4361EE), Color(0xFF7B9EFF)]),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(child: Text(
                                cname.isNotEmpty ? cname[0].toUpperCase() : '?',
                                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                              )),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(cname.isNotEmpty ? cname : 'Unknown',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0D1B2A))),
                                  if (spec.isNotEmpty)
                                    Text(spec, style: const TextStyle(color: Color(0xFF4361EE), fontSize: 13)),
                                ],
                              ),
                            ),
                            IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _detailRow(Icons.phone_rounded, 'Contact', contact),
                        const SizedBox(height: 16),
                        _detailRow(Icons.location_on_rounded, 'Address', address),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Close'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF4361EE)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7A9D))),
              const SizedBox(height: 2),
              Text(value.isNotEmpty ? value : '—',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0D1B2A))),
            ],
          ),
        ),
      ],
    );
  }
}
