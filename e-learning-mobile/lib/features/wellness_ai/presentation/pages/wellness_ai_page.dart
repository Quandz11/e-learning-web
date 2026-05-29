import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/app_scaffold.dart';
import '../../data/repositories/wellness_ai_repository.dart';

class WellnessAiPage extends ConsumerStatefulWidget {
  const WellnessAiPage({super.key});

  @override
  ConsumerState<WellnessAiPage> createState() => _WellnessAiPageState();
}

class _WellnessAiPageState extends ConsumerState<WellnessAiPage> {
  final _promptController = TextEditingController();
  String? _aiReply;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(wellnessAiRepositoryProvider);

    return AppScaffold(
      title: 'Wellness & AI',
      child: FutureBuilder(
        future: Future.wait([
          repository.getAiStatus(),
          repository.getWellnessDashboard(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load wellness/AI: ${snapshot.error}'),
            );
          }

          final results = snapshot.data!;
          final aiStatus = results[0] as dynamic;
          final dashboard = results[1] as Map<String, dynamic>;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                title: const Text('AI enabled'),
                subtitle: Text('${aiStatus.isEnabled}'),
              ),
              ListTile(
                title: const Text('Wellness plan'),
                subtitle: Text(
                  dashboard['plan'] == null ? 'Not configured' : 'Configured',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _promptController,
                decoration: const InputDecoration(labelText: 'Ask AI coach'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () async {
                  final prompt = _promptController.text.trim();
                  if (prompt.isEmpty) return;
                  final result = await repository.aiChat(prompt);
                  setState(() => _aiReply = result['response']?.toString());
                },
                child: const Text('Send to AI'),
              ),
              if (_aiReply != null) ...[
                const SizedBox(height: 12),
                Text(_aiReply!),
              ],
            ],
          );
        },
      ),
    );
  }
}
