// Platform helper for web environments
// All platform checks return false on web

bool get isWindows => false;
bool get isMacOS => false;
bool get isLinux => false;
String get operatingSystem => 'Web';
