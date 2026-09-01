/// Curated IANA names for the timezone dropdown. The current company value is
/// always included even if it is not in this list. Django validates IANA names.
const List<String> kIanaTimezoneOptions = <String>[
  'UTC',
  'Africa/Cairo',
  'Africa/Johannesburg',
  'America/Chicago',
  'America/Denver',
  'America/Los_Angeles',
  'America/New_York',
  'America/Sao_Paulo',
  'America/Toronto',
  'Asia/Dubai',
  'Asia/Hong_Kong',
  'Asia/Karachi',
  'Asia/Kolkata',
  'Asia/Riyadh',
  'Asia/Singapore',
  'Asia/Tokyo',
  'Australia/Sydney',
  'Europe/Berlin',
  'Europe/London',
  'Europe/Paris',
];

List<String> timezoneOptionsFor(String current) {
  final String value = current.trim();
  if (value.isEmpty || kIanaTimezoneOptions.contains(value)) {
    return List<String>.from(kIanaTimezoneOptions);
  }
  return <String>[value, ...kIanaTimezoneOptions];
}
