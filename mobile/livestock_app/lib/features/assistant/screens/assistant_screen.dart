import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/assistant_provider.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _sendQuestion(AssistantProvider provider) {
    final question = _textController.text.trim();
    if (question.isEmpty) return;
    _textController.clear();
    provider.ask(question).then((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssistantProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.psychology),
        title: const Text('AI Health Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear history',
            onPressed: () => provider.clearHistory(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Non-dismissible disclaimer banner
          Container(
            width: double.infinity,
            color: Colors.amber.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('⚠', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'General information only — not a diagnosis or professional advice. '
                    'Always consult a qualified veterinarian for health decisions.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Message list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              padding: const EdgeInsets.all(12),
              itemCount: provider.messages.length + (provider.thinking ? 1 : 0),
              itemBuilder: (context, index) {
                // Thinking indicator at index 0 when reversed
                if (provider.thinking && index == 0) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Thinking…',
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final messageIndex = provider.messages.length -
                    1 -
                    (index - (provider.thinking ? 1 : 0));
                final message = provider.messages[messageIndex];

                if (message.isUser) {
                  return _UserBubble(text: message.displayText);
                }

                return _AiBubble(message: message);
              },
            ),
          ),

          // Input row
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      maxLines: 3,
                      minLines: 1,
                      decoration: const InputDecoration(
                        hintText: 'Ask a livestock health question…',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onSubmitted: provider.thinking
                          ? null
                          : (_) => _sendQuestion(provider),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: provider.thinking
                        ? null
                        : () => _sendQuestion(provider),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  final String text;

  const _UserBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: Colors.green.shade600,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class _AiBubble extends StatelessWidget {
  final AssistantMessage message;

  const _AiBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final response = message.response;

    if (response == null) {
      // Plain error text
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                message.displayText,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ),
      );
    }

    if (response.isDisabled) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Card(
            color: Colors.grey.shade200,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Currently unavailable',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Answer text
                Text(response.answer),

                const SizedBox(height: 8),

                // Source badge
                Chip(
                  label: Text(
                    response.answerSource,
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: Colors.grey.shade200,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),

                // Escalation banner
                if (response.escalation) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade300),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '⚠ Urgent — contact a vet',
                      style: TextStyle(
                        color: Colors.red.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],

                // Disclaimer
                const SizedBox(height: 8),
                Text(
                  response.disclaimer,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
