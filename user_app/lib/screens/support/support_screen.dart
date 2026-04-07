import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/responsive_content.dart';
import '../../services/support_service.dart';

typedef SupportUriLauncher = Future<bool> Function(Uri uri);

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key, this.uriLauncher, this.supportGateway});

  final SupportUriLauncher? uriLauncher;
  final SupportTicketGateway? supportGateway;

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  static const String _supportEmail = String.fromEnvironment(
    'SUPPORT_EMAIL',
    defaultValue: 'support@example.com',
  );
  static const String _supportEmailSubject = String.fromEnvironment(
    'SUPPORT_EMAIL_SUBJECT',
    defaultValue: 'Support Request',
  );
  static const String _supportPhoneRaw = String.fromEnvironment(
    'SUPPORT_PHONE',
    defaultValue: '+10000000000',
  );
  static const String _supportPhoneDisplay = String.fromEnvironment(
    'SUPPORT_PHONE_DISPLAY',
    defaultValue: '+1 000-000-0000',
  );

  static final Uri _emailUri = Uri(
    scheme: 'mailto',
    path: _supportEmail,
    queryParameters: <String, String>{'subject': _supportEmailSubject},
  );

  static final Uri _phoneUri = Uri(scheme: 'tel', path: _supportPhoneRaw);
  static const List<String> _priorityOptions = <String>[
    'low',
    'normal',
    'high',
    'urgent',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Help & Support',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: ResponsiveContent(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.support_agent_rounded,
                      size: 64,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'How can we help you?',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Our team is here 24/7 to assist you.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildSupportOption(
                context,
                'Submit Ticket',
                'Create a tracked support request',
                Icons.chat_bubble_rounded,
                () => _showTicketComposer(context),
              ),
              _buildSupportOption(
                context,
                'My Tickets',
                'Track status of submitted requests',
                Icons.receipt_long_rounded,
                () => _showTicketTimeline(context),
              ),
              _buildSupportOption(
                context,
                'Email Us',
                _supportEmail,
                Icons.email_rounded,
                () => _openEmailSupport(context),
              ),
              _buildSupportOption(
                context,
                'FAQs',
                'Find answers to common questions',
                Icons.help_center_rounded,
                () => _showFaqSheet(context),
              ),
              _buildSupportOption(
                context,
                'Call Us',
                _supportPhoneDisplay,
                Icons.phone_rounded,
                () => _openPhoneSupport(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: ListTile(
          onTap: onTap,
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          title: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontSize: 12),
          ),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
        ),
      ),
    );
  }

  Future<void> _openEmailSupport(BuildContext context) async {
    await _openUriOrNotify(
      context: context,
      uri: _emailUri,
      failureMessage: 'Unable to open email right now.',
    );
  }

  Future<void> _openPhoneSupport(BuildContext context) async {
    await _openUriOrNotify(
      context: context,
      uri: _phoneUri,
      failureMessage: 'Unable to open phone dialer right now.',
    );
  }

  Future<void> _openUriOrNotify({
    required BuildContext context,
    required Uri uri,
    required String failureMessage,
  }) async {
    final launcher = widget.uriLauncher ?? launchUrl;
    final opened = await launcher(uri);
    if (opened || !context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(failureMessage)));
  }

  Future<void> _showFaqSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FAQ Center',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Quick answers for common delivery and ordering questions.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                const _SupportFaqItem(
                  question: 'How long does delivery take?',
                  answer:
                      'Most campus deliveries arrive in 20-35 minutes. Check the ETA card in tracking for live confidence updates.',
                ),
                const _SupportFaqItem(
                  question: 'Can I cancel after placing an order?',
                  answer:
                      'Yes, while the order is pending or accepted. Use the Cancel button in your tracking screen.',
                ),
                const _SupportFaqItem(
                  question: 'What if my item is missing?',
                  answer:
                      'Open Chat or Email support with your order ID and we will resolve it quickly.',
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (mounted) {
                        this.context.push('/legal');
                      }
                    },
                    icon: const Icon(Icons.menu_book_rounded),
                    label: const Text('Open Terms'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showTicketComposer(BuildContext context) async {
    final subjectController = TextEditingController();
    final descriptionController = TextEditingController();
    final orderController = TextEditingController();
    var priority = 'normal';
    var isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 20, 24, 20 + bottomInset),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Submit Support Ticket',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: subjectController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Subject',
                          hintText: 'Missing item in my order',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: descriptionController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Describe the issue',
                          hintText: 'What happened and what help do you need?',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: orderController,
                        decoration: const InputDecoration(
                          labelText: 'Order ID (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: priority,
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                          border: OutlineInputBorder(),
                        ),
                        items: _priorityOptions
                            .map(
                              (value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(value.toUpperCase()),
                              ),
                            )
                            .toList(),
                        onChanged: isSubmitting
                            ? null
                            : (value) {
                                if (value == null) return;
                                setSheetState(() => priority = value);
                              },
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  final sheetNavigator = Navigator.of(
                                    sheetContext,
                                  );
                                  final subject = subjectController.text.trim();
                                  final description = descriptionController.text
                                      .trim();
                                  final orderId = orderController.text.trim();

                                  if (subject.isEmpty || description.isEmpty) {
                                    _showSupportSnack(
                                      'Subject and description are required.',
                                    );
                                    return;
                                  }

                                  setSheetState(() => isSubmitting = true);
                                  try {
                                    final gateway =
                                        widget.supportGateway ??
                                        SupportService();
                                    final ticketId = await gateway.createTicket(
                                      subject: subject,
                                      description: description,
                                      priority: priority,
                                      orderId: orderId.isEmpty ? null : orderId,
                                    );

                                    if (!mounted) return;
                                    sheetNavigator.pop();
                                    _showSupportSnack(
                                      ticketId == null
                                          ? 'Support ticket submitted.'
                                          : 'Support ticket submitted: $ticketId',
                                    );
                                  } catch (e) {
                                    if (!mounted) return;
                                    setSheetState(() => isSubmitting = false);
                                    _showSupportSnack(
                                      'Ticket submission failed: $e',
                                    );
                                  }
                                },
                          icon: isSubmitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                          label: Text(
                            isSubmitting
                                ? 'Submitting...'
                                : 'Submit Support Ticket',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

  }

  Future<void> _showTicketTimeline(BuildContext context) async {
    final gateway = widget.supportGateway ?? SupportService();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final maxSheetHeight = MediaQuery.of(sheetContext).size.height * 0.78;
        return SafeArea(
          child: SizedBox(
            height: maxSheetHeight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: FutureBuilder<List<SupportTicket>>(
                future: gateway.getMyTickets(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Unable to load tickets',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(snapshot.error.toString(), textAlign: TextAlign.center),
                      ],
                    );
                  }

                  final tickets = snapshot.data ?? const <SupportTicket>[];
                  if (tickets.isEmpty) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'No tickets yet',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text('Submit your first ticket from this support page.'),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Support Tickets',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.separated(
                          itemCount: tickets.length,
                          separatorBuilder: (_, itemIndex) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final ticket = tickets[index];
                            final canClose = ticket.status != 'closed';
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                ticket.subject,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                'Status: ${ticket.status.toUpperCase()} | Priority: ${ticket.priority.toUpperCase()}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: canClose
                                  ? TextButton(
                                      onPressed: () async {
                                        await gateway.updateTicketStatus(
                                          ticketId: ticket.id,
                                          status: 'closed',
                                        );
                                        if (sheetContext.mounted) {
                                          Navigator.of(sheetContext).pop();
                                          await _showTicketTimeline(context);
                                        }
                                      },
                                      child: const Text('Close'),
                                    )
                                  : const Text('Closed'),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSupportSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SupportFaqItem extends StatelessWidget {
  const _SupportFaqItem({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 12),
      title: Text(
        question,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            answer,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
