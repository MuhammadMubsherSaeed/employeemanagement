class WorkingDuration {
  WorkingDuration._();

  static String format(int? totalMinutes) {
    if (totalMinutes == null) {
      return '—';
    }
    final int hours = totalMinutes ~/ 60;
    final int minutes = totalMinutes % 60;
    final String padded = minutes.toString().padLeft(2, '0');
    return '${hours}h ${padded}m';
  }
}
