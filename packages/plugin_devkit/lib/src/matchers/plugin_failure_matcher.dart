import 'package:matcher/matcher.dart';
import 'package:plugin_contracts/plugin_contracts.dart';

Matcher hasPluginFailureCode(String code) {
  if (code.trim().isEmpty) {
    throw ArgumentError.value(code, 'code', 'must not be blank');
  }

  return _PluginFailureCodeMatcher(code);
}

final class _PluginFailureCodeMatcher extends Matcher {
  _PluginFailureCodeMatcher(this._expectedCode);

  final String _expectedCode;

  @override
  bool matches(dynamic item, Map<Object?, Object?> matchState) {
    return item is PluginFailure && item.code == _expectedCode;
  }

  @override
  Description describe(Description description) {
    return description
        .add('a PluginFailure with code ')
        .addDescriptionOf(_expectedCode);
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map<Object?, Object?> matchState,
    bool verbose,
  ) {
    if (item is! PluginFailure) {
      return mismatchDescription.add(
        'was not a PluginFailure (actual type: ${item.runtimeType})',
      );
    }

    return mismatchDescription.add(
      'had failure code ${item.code}, expected $_expectedCode',
    );
  }
}
