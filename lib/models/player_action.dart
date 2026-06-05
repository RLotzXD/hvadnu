class PlayerAction {
  final String type; // 'photo' or 'speech'
  final String content; // base64 image or transcribed text
  final DateTime timestamp;

  const PlayerAction({
    required this.type,
    required this.content,
    required this.timestamp,
  });

  bool get isPhoto => type == 'photo';
  bool get isSpeech => type == 'speech';

  Map<String, dynamic> toJson() => {
        'type': type,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
      };

  factory PlayerAction.fromJson(Map<String, dynamic> json) {
    return PlayerAction(
      type: json['type'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  factory PlayerAction.photo(String base64Image) {
    return PlayerAction(
      type: 'photo',
      content: base64Image,
      timestamp: DateTime.now(),
    );
  }

  factory PlayerAction.speech(String transcribedText) {
    return PlayerAction(
      type: 'speech',
      content: transcribedText,
      timestamp: DateTime.now(),
    );
  }
}
