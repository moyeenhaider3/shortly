import 'package:flutter/foundation.dart';

/// App-wide commands triggered by keyboard shortcuts in the shell and
/// handled by whichever page owns the target (e.g. the links search field).
abstract final class ShellCommands {
  /// Incremented when the user presses ⌘/Ctrl+K.
  static final ValueNotifier<int> focusSearch = ValueNotifier(0);
}
