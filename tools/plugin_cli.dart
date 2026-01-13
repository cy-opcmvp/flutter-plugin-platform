import 'dart:io';
import 'dart:convert';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';

void main(List<String> args) async {
  final p = ArgParser()
    ..addCommand('create-internal')..addCommand('create-external')..addCommand('list-templates')
    ..addCommand('build')..addCommand('test')..addCommand('package')..addCommand('validate')..addCommand('publish')
    ..addFlag('help', abbr: 'h', negatable: false)..addFlag('version', abbr: 'v', negatable: false);
  p.commands['create-internal']!..addOption('name', abbr: 'n', mandatory: true)..addOption('type', abbr: 't', defaultsTo: 'tool')..addOption('author', abbr: 'a')..addOption('output', abbr: 'o');
  p.commands['create-external']!..addOption('name', abbr: 'n', mandatory: true)..addOption('language', abbr: 'l', defaultsTo: 'dart')..addOption('author', abbr: 'a')..addOption('output', abbr: 'o');
  p.commands['build']!..addOption('plugin', abbr: 'p')..addOption('platform', defaultsTo: 'current');
  p.commands['test']!..addOption('plugin', abbr: 'p')..addFlag('verbose', abbr: 'V', negatable: false);
  p.commands['package']!..addOption('plugin', abbr: 'p')..addOption('output', abbr: 'o')..addOption('platform', defaultsTo: 'all');
  p.commands['validate']!.addOption('plugin', abbr: 'p', mandatory: true);
  p.commands['publish']!..addOption('plugin', abbr: 'p', mandatory: true)..addOption('registry', abbr: 'r', defaultsTo: 'local');
  try {
    final r = p.parse(args);
    if (r['help'] as bool) { _help(); return; }
    if (r['version'] as bool) { print('CLI v1.0.0'); return; }
    if (r.command == null) { print('Error: specify command'); _help(); exit(1); }
    await _run(r.command!);
  } catch (e) { print('Error: $e'); exit(1); }
}

String _root() => path.dirname(path.dirname(Platform.script.toFilePath()));
String _pascal(String s) => s.split(RegExp(r'[_\s-]+')).map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase()).join('');
String _snake(String s) => s.toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_');

Future<void> _run(ArgResults c) async {
  switch (c.name) {
    case 'create-internal': await _createInt(c); break;
    case 'create-external': await _createExt(c); break;
    case 'list-templates': print('Templates: internal(tool/game), external(dart/python/web)'); break;
    case 'build': await _build(c); break;
    case 'test': await _test(c); break;
    case 'package': await _pkg(c); break;
    case 'validate': await _val(c); break;
    case 'publish': await _pub(c); break;
  }
}

Future<void> _createInt(ArgResults a) async {
  final n = a['name'] as String, t = a['type'] as String, au = a['author'] as String? ?? 'Dev', o = a['output'] as String? ?? 'lib/plugins';
  print('Creating internal plugin: $n');
  final id = 'com.example.${_snake(n)}', cls = _pascal(n), f = _snake(n), d = path.join(o, f);
  await Directory(d).create(recursive: true);
  await Directory(path.join(d, 'widgets')).create();
  await Directory(path.join(d, 'models')).create();
  final td = path.join(_root(), 'docs', 'templates', 'internal-plugin');
  final pt = File(path.join(td, 'plugin-template.dart')), ft = File(path.join(td, 'factory-template.dart'));
  if (!await pt.exists() || !await ft.exists()) { print('Template not found'); exit(1); }
  final r = {'{{PLUGIN_NAME}}': n, '{{PLUGIN_ID}}': id, '{{PLUGIN_CLASS}}': cls, '{{PLUGIN_FILE_NAME}}': f, '{{AUTHOR_NAME}}': au, '{{AUTHOR_EMAIL}}': 'dev@example.com', '{{PLUGIN_DESCRIPTION}}': 'Plugin', '{{PLUGIN_CATEGORY}}': t == 'game' ? 'entertainment' : 'productivity', '{{PLUGIN_TAGS}}': t == 'game' ? "'game'" : "'tool'", '{{PLUGIN_ICON}}': t == 'game' ? 'games' : 'extension', '{{LICENSE}}': 'MIT', '{{CREATION_DATE}}': DateTime.now().toString().split(' ')[0]};
  var pc = await pt.readAsString(), fc = await ft.readAsString();
  r.forEach((k, v) { pc = pc.replaceAll(k, v); fc = fc.replaceAll(k, v); });
  await File(path.join(d, '${f}_plugin.dart')).writeAsString(pc);
  await File(path.join(d, '${f}_plugin_factory.dart')).writeAsString(fc);
  await File(path.join(d, 'README.md')).writeAsString('# $n\n');
  print('Created: $d');
}

Future<void> _createExt(ArgResults a) async {
  final n = a['name'] as String, l = a['language'] as String, au = a['author'] as String? ?? 'Dev', o = a['output'] as String? ?? 'external_plugins';
  print('Creating external plugin: $n ($l)');
  final id = 'com.example.${_snake(n)}', f = _snake(n), d = path.join(o, f);
  await Directory(d).create(recursive: true);
  final ts = l == 'python' ? 'python' : l == 'web' ? 'web' : 'dart';
  final td = path.join(_root(), 'docs', 'templates', 'external-plugin', ts);
  if (!await Directory(td).exists()) { print('Template not found: $td'); exit(1); }
  final r = {'{{PLUGIN_NAME}}': n, '{{PLUGIN_ID}}': id, '{{PLUGIN_FILE_NAME}}': f, '{{PLUGIN_DESCRIPTION}}': 'Plugin', '{{AUTHOR_NAME}}': au, '{{AUTHOR_EMAIL}}': 'dev@example.com', '{{PLUGIN_CATEGORY}}': 'productivity'};
  await for (final e in Directory(td).list()) {
    if (e is File) { var c = await e.readAsString(); r.forEach((k, v) { c = c.replaceAll(k, v); }); await File(path.join(d, path.basename(e.path))).writeAsString(c); }
  }
  print('Created: $d');
}

Future<void> _build(ArgResults a) async {
  final p = a['plugin'] as String? ?? '.', pl = a['platform'] as String;
  print('Building: $p ($pl)');
  final mf = File(path.join(p, 'manifest.json'));
  if (await mf.exists()) {
    final m = jsonDecode(await mf.readAsString()); print('  ${m['name']} v${m['version']}');
    if (await File(path.join(p, 'main.dart')).exists()) {
      await Directory(path.join(p, 'bin')).create(recursive: true);
      final r = await Process.run('dart', ['compile', 'exe', 'main.dart', '-o', 'bin/plugin'], workingDirectory: p);
      if (r.exitCode != 0) { print('Failed: ${r.stderr}'); exit(1); }
    }
    print('Done');
  } else if (await File(path.join(p, 'pubspec.yaml')).exists()) {
    final cp = pl == 'current' ? (Platform.isWindows ? 'windows' : Platform.isMacOS ? 'macos' : 'linux') : pl;
    final r = await Process.run('flutter', ['build', cp]); if (r.exitCode != 0) { print('Failed'); exit(1); }
    print('Done');
  } else { print('No manifest.json or pubspec.yaml'); exit(1); }
}

Future<void> _test(ArgResults a) async {
  final p = a['plugin'] as String?, v = a['verbose'] as bool;
  print('Testing...');
  if (p != null && p.endsWith('.pkg')) { await _val(a); }
  else { final r = await Process.run('flutter', ['test', p ?? 'test', if (v) '--verbose']); print(r.stdout); if (r.exitCode != 0) { print(r.stderr); exit(1); } }
  print('Passed');
}

Future<void> _pkg(ArgResults a) async {
  final p = a['plugin'] as String? ?? '.', pl = a['platform'] as String; var o = a['output'] as String?;
  print('Packaging: $p');
  final mf = File(path.join(p, 'manifest.json'));
  if (!await mf.exists()) { print('No manifest.json'); exit(1); }
  final m = jsonDecode(await mf.readAsString()) as Map<String, dynamic>;
  final id = m['id'] as String, v = m['version'] as String;
  o ??= '${id.split('.').last}-$v.pkg';
  print('  ${m['name']} v$v ($pl)');
  final arc = Archive();
  arc.addFile(ArchiveFile('manifest.json', await mf.length(), await mf.readAsBytes()));
  await for (final e in Directory(p).list(recursive: true)) {
    if (e is File) { final r = path.relative(e.path, from: p); if (!r.startsWith('.') && !r.contains('/.')) { arc.addFile(ArchiveFile(r, await e.length(), await e.readAsBytes())); } }
  }
  final h = sha256.convert(utf8.encode(arc.files.map((f) => f.name).join('\n'))).toString();
  arc.addFile(ArchiveFile('signature.txt', h.length, utf8.encode(h)));
  final z = ZipEncoder().encode(arc);
  if (z != null) { await File(o).writeAsBytes(z); print('Done: $o (${(z.length / 1024).toStringAsFixed(1)} KB)'); }
}

Future<void> _val(ArgResults a) async {
  final p = a['plugin'] as String;
  print('Validating: $p');
  if (!await File(p).exists()) { print('File not found'); exit(1); }
  final errs = <String>[], warns = <String>[];
  try {
    final b = await File(p).readAsBytes(), arc = ZipDecoder().decodeBytes(b), ns = arc.files.map((f) => f.name).toSet();
    if (!ns.contains('manifest.json')) { errs.add('Missing manifest.json'); }
    else { final mf = arc.files.firstWhere((f) => f.name == 'manifest.json'); final m = jsonDecode(utf8.decode(mf.content as List<int>)) as Map<String, dynamic>;
      for (final f in ['id', 'name', 'version', 'type', 'runtimeType', 'supportedPlatforms', 'entryPoints']) { if (!m.containsKey(f)) errs.add('Missing: $f'); }
      print('  ${m['name']} v${m['version']} (${m['runtimeType']})'); }
    if (!ns.contains('signature.txt')) warns.add('No signature');
    print('  Files: ${arc.files.length}, Size: ${(b.length / 1024).toStringAsFixed(1)} KB');
  } catch (e) { errs.add('Parse error: $e'); }
  if (errs.isNotEmpty) { print('Errors:'); for (final e in errs) { print('  - $e'); } exit(1); }
  if (warns.isNotEmpty) { print('Warnings:'); for (final w in warns) { print('  - $w'); } }
  print('Valid');
}

Future<void> _pub(ArgResults a) async {
  final p = a['plugin'] as String, rg = a['registry'] as String;
  print('Publishing: $p ($rg)');
  await _val(a);
  final b = await File(p).readAsBytes(), arc = ZipDecoder().decodeBytes(b);
  final mf = arc.files.firstWhere((f) => f.name == 'manifest.json');
  final m = jsonDecode(utf8.decode(mf.content as List<int>)) as Map<String, dynamic>;
  final id = m['id'] as String, v = m['version'] as String;
  if (rg == 'local') {
    final h = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.';
    final rd = path.join(h, '.flutter-plugins', 'registry', id, v);
    await Directory(rd).create(recursive: true);
    await File(p).copy(path.join(rd, path.basename(p)));
    final ix = File(path.join(h, '.flutter-plugins', 'registry', 'index.json'));
    Map<String, dynamic> idx = {};
    if (await ix.exists()) idx = jsonDecode(await ix.readAsString());
    idx[id] ??= {'versions': <String>[]};
    final vs = (idx[id]['versions'] as List).cast<String>();
    if (!vs.contains(v)) vs.add(v);
    idx[id]['latest'] = v; idx[id]['name'] = m['name'];
    await ix.writeAsString(const JsonEncoder.withIndent('  ').convert(idx));
    print('Published: $rd');
  } else { print('Remote publish requires API key'); }
}

void _help() {
  print('Flutter Plugin CLI v1.0.0\n\nCommands:\n  create-internal -n <name> [-t tool|game]\n  create-external -n <name> [-l dart|python|web]\n  list-templates\n  build [-p dir]\n  test [-p path]\n  package [-p dir] [-o file.pkg]\n  validate -p <file.pkg>\n  publish -p <file.pkg> [-r local]');
}
