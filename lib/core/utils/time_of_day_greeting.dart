/// Morning / afternoon / evening label from local hour in `[0, 23]`.
String timeOfDayGreeting(int hour) {
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}
