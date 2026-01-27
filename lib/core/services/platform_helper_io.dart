// Platform helper for dart:io environments (native platforms)
import 'dart:io';

bool get isWindows => Platform.isWindows;
bool get isMacOS => Platform.isMacOS;
bool get isLinux => Platform.isLinux;
String get operatingSystem => Platform.operatingSystem;
