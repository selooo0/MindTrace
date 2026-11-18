class ChatMessage {
  final String role;
  final bool? isClue;
  final String text;

  ChatMessage({
    required this.role,
    this.isClue,
    required this.text,
  });
}
