/// Masks the host part of an IP so visitor addresses aren't shown by default.
///   203.0.113.42        → 203.0.•.•
///   ::ffff:203.0.113.42 → 203.0.•.•
///   2001:db8:85a3::7334 → 2001:db8:•:•
String maskIp(String? ip) {
  if (ip == null || ip.isEmpty || ip == 'Unknown') return 'Unknown';
  final v4 = ip.startsWith('::ffff:') ? ip.substring(7) : ip;
  final octets = v4.split('.');
  if (octets.length == 4) return '${octets[0]}.${octets[1]}.•.•';
  final groups = ip.split(':').where((g) => g.isNotEmpty).toList();
  if (groups.length >= 2) return '${groups[0]}:${groups[1]}:•:•';
  return '•••';
}

/// Strips the IPv4-mapped prefix for display.
String displayIp(String? ip) {
  if (ip == null || ip.isEmpty) return 'Unknown';
  return ip.startsWith('::ffff:') ? ip.substring(7) : ip;
}
