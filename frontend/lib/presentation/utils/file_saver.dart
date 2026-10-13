// Browser download on web; a no-op elsewhere (callers hide the action when
// `canSaveFiles` is false).
export 'file_saver_stub.dart' if (dart.library.js_interop) 'file_saver_web.dart';
