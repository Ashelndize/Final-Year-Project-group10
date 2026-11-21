import 'package:flutter/foundation.dart';
import '../models/assistant_response.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';

class AssistantMessage {
  final bool isUser;
  final String? text;
  final AssistantResponse? response;

  AssistantMessage({required this.isUser, this.text, this.response});

  String get displayText => text ?? response?.answer ?? '';
}

class AssistantProvider extends ChangeNotifier {
  final List<AssistantMessage> _messages = [];
  bool _thinking = false;
  String? _error;

  List<AssistantMessage> get messages => List.unmodifiable(_messages);
  bool get thinking => _thinking;
  String? get error => _error;

  Future<void> ask(String question) async {
    _messages.add(AssistantMessage(isUser: true, text: question));
    _thinking = true;
    _error = null;
    notifyListeners();
    try {
      final data = await ApiClient.post(
        ApiEndpoints.assistantAsk,
        {'question': question},
      );
      final response = AssistantResponse.fromJson(data);
      _messages.add(AssistantMessage(isUser: false, response: response));
    } catch (e) {
      _error = e.toString();
      _messages.add(
        AssistantMessage(
          isUser: false,
          text: 'Unable to get a response. Please try again.',
        ),
      );
    } finally {
      _thinking = false;
      notifyListeners();
    }
  }

  void clearHistory() {
    _messages.clear();
    _error = null;
    notifyListeners();
  }
}
