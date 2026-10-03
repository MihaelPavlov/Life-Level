/// Short count for space-limited headers, with up to one decimal place.
String compactCount(int count) {
  if (count < 1000 && count > -1000) return count.toString();

  const suffixes = ['K', 'M', 'B', 'T'];
  var value = count.toDouble();
  var unit = -1;
  do {
    value /= 1000;
    unit++;
  } while (value.abs() >= 1000 && unit < suffixes.length - 1);

  var rounded = double.parse(value.toStringAsFixed(1));
  if (rounded.abs() >= 1000 && unit < suffixes.length - 1) {
    rounded /= 1000;
    unit++;
  }
  final number = rounded == rounded.truncateToDouble()
      ? rounded.toStringAsFixed(0)
      : rounded.toStringAsFixed(1);
  return '$number${suffixes[unit]}';
}
