String cleanErrorMessage(dynamic error) {
  if (error == null) return '';
  final message = error.toString();
  return message.replaceFirst(RegExp(r'^Exception:\s*'), '');
}
