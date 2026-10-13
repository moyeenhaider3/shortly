import 'package:intl/intl.dart';

abstract final class Fmt {
  static final _compact = NumberFormat.compact();
  static final _grouped = NumberFormat.decimalPattern();
  static final _dateTime = DateFormat('MMM d, yyyy · h:mm a');
  static final _date = DateFormat('MMM d, yyyy');

  /// 1,284 below 10k, then 12K / 1.2M.
  static String count(num n) => n < 10000 ? _grouped.format(n) : _compact.format(n);

  static String date(DateTime d) => _date.format(d);
  static String dateTime(DateTime d) => _dateTime.format(d);

  static String relative(DateTime d, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(d);
    if (diff.isNegative || diff.inSeconds < 45) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

  /// "3 days", "5 months" — used for link age.
  static String age(DateTime since, {DateTime? now}) {
    final days = (now ?? DateTime.now()).difference(since).inDays;
    if (days < 1) return 'Today';
    if (days < 30) return '$days ${days == 1 ? 'day' : 'days'}';
    final months = (days / 30).floor();
    if (days < 365) return '$months ${months == 1 ? 'month' : 'months'}';
    final years = (days / 365).floor();
    return '$years ${years == 1 ? 'year' : 'years'}';
  }

  /// Host without `www.`, falling back to the raw string.
  static String host(String url) {
    final h = Uri.tryParse(url)?.host ?? '';
    if (h.isEmpty) return url;
    return h.startsWith('www.') ? h.substring(4) : h;
  }

  /// `https://sho.rt/abc` → `sho.rt/abc` for compact display.
  static String stripScheme(String url) => url.replaceFirst(RegExp(r'^https?://'), '');
}
