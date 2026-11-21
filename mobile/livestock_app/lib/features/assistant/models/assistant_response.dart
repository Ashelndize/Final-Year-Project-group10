class AssistantResponse {
  final int id;
  final String answer;
  final String answerSource;
  final String kbVersion;
  final bool escalation;
  final List<String> safetyFlags;
  final String disclaimer;
  final DateTime createdAt;

  const AssistantResponse({
    required this.id,
    required this.answer,
    required this.answerSource,
    required this.kbVersion,
    required this.escalation,
    required this.safetyFlags,
    required this.disclaimer,
    required this.createdAt,
  });

  factory AssistantResponse.fromJson(Map<String, dynamic> json) {
    return AssistantResponse(
      id: json['id'] as int,
      answer: json['answer'] as String? ?? '',
      answerSource: json['answer_source'] as String? ?? '',
      kbVersion: json['kb_version'] as String? ?? '',
      escalation: json['escalation'] as bool? ?? false,
      safetyFlags: (json['safety_flags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      disclaimer: json['disclaimer'] as String? ??
          'General information — not a diagnosis.',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isDisabled => answerSource == 'DISABLED';
  bool get isRefused => answerSource == 'REFUSED';
  bool get isFromKB => answerSource == 'KB';
}
