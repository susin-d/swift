import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';

class SupportInboxScreen extends StatefulWidget {
  const SupportInboxScreen({
    super.key,
    this.loadTicketsOverride,
    this.updateTicketOverride,
  });

  final Future<List<Map<String, dynamic>>> Function()? loadTicketsOverride;
  final Future<void> Function(String ticketId, String status)?
      updateTicketOverride;

  @override
  State<SupportInboxScreen> createState() => _SupportInboxScreenState();
}

class _SupportInboxScreenState extends State<SupportInboxScreen> {
  final Dio _dio = ApiClient.instance.dio;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _tickets = const [];
  String? _statusFilter;
  String? _priorityFilter;
  Map<String, dynamic>? _summary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = widget.loadTicketsOverride != null
          ? await widget.loadTicketsOverride!()
          : await _loadRemoteTickets();
      if (!mounted) return;
      setState(() {
        _tickets = list;
        _loading = false;
      });
      if (widget.loadTicketsOverride == null) {
        await _loadSummary();
      } else if (mounted) {
        setState(() {
          _summary = <String, dynamic>{'total': list.length};
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<List<Map<String, dynamic>>> _loadRemoteTickets() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/admin/support/tickets',
      queryParameters: {
        if (_statusFilter != null) 'status': _statusFilter,
        if (_priorityFilter != null) 'priority': _priorityFilter,
      },
    );
    final payload = response.data ?? const <String, dynamic>{};
    final list = payload['tickets'] as List<dynamic>? ?? const [];
    return list
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  Future<void> _loadSummary() async {
    final response = await _dio.get<Map<String, dynamic>>('/admin/support/summary');
    if (!mounted) return;
    setState(() {
      _summary = response.data?['summary'] as Map<String, dynamic>?;
    });
  }

  Future<void> _updateTicket(
    String ticketId,
    String status,
  ) async {
    try {
      if (widget.updateTicketOverride != null) {
        await widget.updateTicketOverride!(ticketId, status);
      } else {
        await _dio.patch(
          '/admin/support/tickets/$ticketId',
          data: <String, dynamic>{'status': status},
        );
      }
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ticket moved to $status')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    if (_tickets.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: const [
            SizedBox(height: 200),
            Center(child: Text('No support tickets in queue')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        children: [
          if (_summary != null)
            Card(
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Total: ${_summary!['total'] ?? 0} | Open: ${(_summary!['status'] as Map?)?['open'] ?? 0} | In Progress: ${(_summary!['status'] as Map?)?['in_progress'] ?? 0}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Material(
              color: Colors.transparent,
              child: Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: 160,
                    child: DropdownButtonFormField<String?>(
                      initialValue: _statusFilter,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem<String?>(value: null, child: Text('All')),
                        DropdownMenuItem<String?>(value: 'open', child: Text('Open')),
                        DropdownMenuItem<String?>(value: 'in_progress', child: Text('In Progress')),
                        DropdownMenuItem<String?>(value: 'resolved', child: Text('Resolved')),
                        DropdownMenuItem<String?>(value: 'closed', child: Text('Closed')),
                      ],
                      onChanged: (value) async {
                        setState(() => _statusFilter = value);
                        await _load();
                      },
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: DropdownButtonFormField<String?>(
                      initialValue: _priorityFilter,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem<String?>(value: null, child: Text('All')),
                        DropdownMenuItem<String?>(value: 'low', child: Text('Low')),
                        DropdownMenuItem<String?>(value: 'normal', child: Text('Normal')),
                        DropdownMenuItem<String?>(value: 'high', child: Text('High')),
                        DropdownMenuItem<String?>(value: 'urgent', child: Text('Urgent')),
                      ],
                      onChanged: (value) async {
                        setState(() => _priorityFilter = value);
                        await _load();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          ..._tickets.map((ticket) {
            final id = ticket['id']?.toString() ?? '';
            final subject = ticket['subject']?.toString() ?? 'No subject';
            final status = ticket['status']?.toString() ?? 'open';
            final priority = ticket['priority']?.toString() ?? 'normal';
            final description = ticket['description']?.toString() ?? '';
            return Card(
              margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            subject,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          priority.toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(description),
                    const SizedBox(height: 8),
                    Text(
                      'Status: ${status.toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: () => _updateTicket(id, 'in_progress'),
                          child: const Text('Start'),
                        ),
                        OutlinedButton(
                          onPressed: () => _updateTicket(id, 'resolved'),
                          child: const Text('Resolve'),
                        ),
                        OutlinedButton(
                          onPressed: () => _updateTicket(id, 'closed'),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
