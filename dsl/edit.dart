library;

import 'dart:io';

import 'package:flutterflow_ai/flutterflow_ai.dart';
// setPageRoute is the documented way to change a page's route, but it is not
// re-exported from the barrel (only findPage/findComponent are). Reaching into
// src/ is the workaround; the alternative -- poking routePath on
// ensurePageRouteSettings() -- skips route normalisation and is explicitly
// warned against.
// ignore: implementation_imports
import 'package:flutterflow_ai/src/helpers/routing_helpers.dart';
// ignore: implementation_imports
import 'package:flutterflow_ai/src/helpers/project_helpers.dart' show setInitialPage;
// ignore: implementation_imports
import 'package:flutterflow_ai/src/helpers/ensure_helpers.dart' show ensureDataStructField;
// ignore: implementation_imports
import 'package:flutterflow_ai/src/helpers/data_type_helpers.dart' show stringType;

import 'package:ff_agent_useitfresh_fridge_wise_gvpy0s/flutterflow_project.dart'
    as ff;


Future<void> main(List<String> args) async {
  final options = _parseCliOptions(args);
  try {
    await flutterFlowAI(
      buildStarterEditFlow,
      apiKey: options.apiKey,
      baseUrl: options.baseUrl,
      projectName: options.projectName,
      projectId: options.projectId,
      findOrCreate: options.findOrCreate,
      allowNewProject: options.allowNewProject,
      dryRun: options.dryRun,
      commitMessage: options.commitMessage,
    );
  } catch (error) {
    stderr.writeln('Error: ${formatFlutterFlowAIError(error)}');
    exit(1);
  }
}

final class _CliOptions {
  const _CliOptions({
    this.apiKey,
    this.baseUrl,
    this.projectName,
    this.projectId,
    this.findOrCreate = false,
    this.allowNewProject = false,
    this.dryRun = false,
    this.commitMessage,
  });

  final String? apiKey;
  final String? baseUrl;
  final String? projectName;
  final String? projectId;
  final bool findOrCreate;
  final bool allowNewProject;
  final bool dryRun;
  final String? commitMessage;
}

_CliOptions _parseCliOptions(List<String> args) {
  String? apiKey;
  String? baseUrl;
  String? projectName;
  String? projectId;
  String? commitMessage;
  var findOrCreate = false;
  var allowNewProject = false;
  var dryRun = false;

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    switch (arg) {
      case '--help':
      case '-h':
        _printUsage();
        exit(0);
      case '--api-key':
        apiKey = _requireValue(args, ++i, '--api-key');
      case '--base-url':
        baseUrl = _requireValue(args, ++i, '--base-url');
      case '--project-name':
        projectName = _requireValue(args, ++i, '--project-name');
      case '--project-id':
        projectId = _requireValue(args, ++i, '--project-id');
      case '--commit-message':
        commitMessage = _requireValue(args, ++i, '--commit-message');
      case '--find-or-create':
        findOrCreate = true;
      case '--allow-new-project':
        allowNewProject = true;
      case '--dry-run':
        dryRun = true;
      default:
        stderr.writeln('Unknown option: $arg');
        _printUsage();
        exit(64);
    }
  }

  return _CliOptions(
    apiKey: apiKey,
    baseUrl: baseUrl,
    projectName: projectName,
    projectId: projectId,
    findOrCreate: findOrCreate,
    allowNewProject: allowNewProject,
    dryRun: dryRun,
    commitMessage: commitMessage,
  );
}

String _requireValue(List<String> args, int index, String flag) {
  if (index >= args.length) {
    stderr.writeln('Missing value for $flag.');
    _printUsage();
    exit(64);
  }
  return args[index];
}

void _printUsage() {
  stdout.writeln('''
Run the starter FlutterFlow AI edit flow.

Usage:
  dart run dsl/edit.dart [options]

Options:
  --api-key <key>           FlutterFlow API key. Defaults to FF_API_KEY.
  --base-url <url>          Override the FlutterFlow API base URL.
  --project-name <name>     Create a new project with this name.
  --project-id <id>         Push into an existing project by ID.
  --find-or-create          Retry by reusing a same-name project before creating.
  --allow-new-project       Bypass the workspace binding guard and create a different project.
  --commit-message <text>   Commit message for the push.
  --dry-run                 Compile and validate without pushing.
  --help, -h                Show this help.
''');
}

// ---------------------------------------------------------------------------
// Home: the feature panel from the design pack.
//
// The panel component was built days ago and never placed. The pack puts it
// directly under the greeting, above "Use first" — a graphite block that gives
// the screen a centre of gravity instead of a list starting at the top.
//
// Its supporting line counts the real items rather than repeating the pack's
// example copy. A hero that says "3 items to check first today" when there are
// none is worse than no hero: it is the first thing anyone reads, and being
// wrong there costs more trust than the panel buys in polish.
// ---------------------------------------------------------------------------

/// Big thing 4, Storage, step 2 of 2: StorageLocationsLive.
///
/// This household's places only, with how many foods each holds; a loading
/// placeholder instead of a blank moment; removing a place asks first and says
/// what happens to the food kept there; adding a place keeps the same words
/// ("Add location", "Location added.").
void buildStarterEditFlow(App app) {
  app.customWidget(
    'StorageLocationsLive',
    parameters: {},
    description:
        "This household's storage places, with food counts; add one, or remove "
        'one after confirming.',
    code: _storageLocationsLive,
  );

  final storage = ff.Pages.storageLocationsPage;
  app.editPage(storage, (page) {
    page.ensureInsertedAfter(
      storage.widgets.byKey('Text_j2h1yoxh').single, // the intro line
      CustomWidget(widgetName: 'StorageLocationsLive', name: 'StoragePlaces', arguments: {}),
    );
  });
}

const _storageLocationsLive = r'''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Where this household keeps food.
class StorageLocationsLive extends StatefulWidget {
  const StorageLocationsLive({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<StorageLocationsLive> createState() => _StorageLocationsLiveState();
}

class _StorageLocationsLiveState extends State<StorageLocationsLive> {
  static const _forest = Color(0xFF07533A);
  static const _ink = Color(0xFF202C24);
  static const _muted = Color(0xFF59665D);
  static const _sage = Color(0xFFEDF2E8);
  static const _border = Color(0xFFDCE3D7);

  static const _types = <String, String>{
    'fridge': 'Fridge',
    'freezer': 'Freezer',
    'pantry': 'Pantry',
    'other': 'Somewhere else',
  };

  String _for = '';
  bool _loading = true;
  bool _offline = false;
  bool _adding = false;
  List<Map<String, dynamic>> _places = const [];
  Map<String, int> _counts = const {};
  final _name = TextEditingController();
  String _type = 'other';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _load({bool quiet = false}) async {
    final household = _for;
    if (household.isEmpty) return;
    if (!quiet && mounted) {
      setState(() {
        _loading = true;
        _offline = false;
      });
    }
    try {
      final rows = await SupaFlow.client
          .from('storage_locations')
          .select('id, name, location_type, is_default')
          .eq('household_id', household)
          .order('location_type')
          .order('name');
      final kept = await SupaFlow.client
          .from('food_items_status')
          .select('storage_location_id')
          .eq('household_id', household);
      final counts = <String, int>{};
      for (final k in kept as List) {
        final id = (k['storage_location_id'] ?? '').toString();
        if (id.isNotEmpty) counts[id] = (counts[id] ?? 0) + 1;
      }
      if (!mounted || household != _for) return;
      setState(() {
        _places = List<Map<String, dynamic>>.from(rows as List);
        _counts = counts;
        _loading = false;
        _offline = false;
      });
    } catch (_) {
      if (!mounted) return;
      if (quiet && _places.isNotEmpty) return;
      setState(() {
        _loading = false;
        _offline = true;
      });
    }
  }

  void _say(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _add() async {
    if (_adding) return;
    setState(() => _adding = true);
    final said = await addStorageLocation(_name.text, _type);
    if (!mounted) return;
    setState(() => _adding = false);
    if (said.isNotEmpty) {
      _say(said);
      return;
    }
    _name.clear();
    _say('Location added.');
    _load(quiet: true);
  }

  Future<void> _remove(Map<String, dynamic> place) async {
    final id = place['id'].toString();
    final name = (place['name'] ?? '').toString();
    final n = _counts[id] ?? 0;
    final sure = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Remove $name?'),
        content: Text(n == 0
            ? 'Nothing is kept there at the moment.'
            : (n == 1
                ? 'The 1 food kept there stays in your kitchen, with no place recorded.'
                : 'The $n foods kept there stay in your kitchen, with no place recorded.')),
        actions: [
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: () => Navigator.of(dialog).pop(false),
            child: const Text('Keep it'),
          ),
          TextButton(
            style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: const Color(0xFFB42318)),
            onPressed: () => Navigator.of(dialog).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    try {
      await SupaFlow.client.from('storage_locations').delete().eq('id', id);
      _say('$name removed.');
    } catch (_) {
      _say('Could not remove it. Check your signal and try again.');
    }
    _load(quiet: true);
  }

  static IconData _icon(String type) {
    switch (type) {
      case 'fridge':
        return Icons.kitchen_outlined;
      case 'freezer':
        return Icons.ac_unit;
      case 'pantry':
        return Icons.inventory_2_outlined;
      default:
        return Icons.shelves;
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final t = FlutterFlowTheme.of(context);
    final household = FFAppState().currentHouseholdId;
    if (household.isNotEmpty && household != _for) {
      _for = household;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }

    Widget list;
    if (_loading) {
      list = Column(children: [
        for (var i = 0; i < 3; i++) ...[
          Container(
            height: 64,
            decoration:
                BoxDecoration(color: _sage, borderRadius: BorderRadius.circular(14)),
          ),
          const SizedBox(height: 8),
        ],
      ]);
    } else if (_offline) {
      list = Text('Can’t reach your kitchen. Your places will show when you are back online.',
          style: t.bodyLarge.copyWith(color: _muted));
    } else if (_places.isEmpty) {
      list = Text('No places yet. Add where you keep food below.',
          style: t.bodyLarge.copyWith(color: _muted));
    } else {
      list = Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
        ),
        child: Column(
          children: [
            for (var i = 0; i < _places.length; i++) ...[
              if (i > 0) const Divider(height: 1, thickness: 1, indent: 64, color: _border),
              _row(t, _places[i]),
            ],
          ],
        ),
      );
    }

    return SizedBox(
      width: widget.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          list,
          const SizedBox(height: 28),
          Text('Add a location',
              style: t.titleLarge.copyWith(
                  fontSize: 20, fontWeight: FontWeight.w800, color: _ink)),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            style: t.bodyLarge.copyWith(fontSize: 16, color: _ink),
            decoration: InputDecoration(
              labelText: 'Name',
              hintText: 'Garage freezer, fruit bowl…',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _forest, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Type',
              style: t.bodyMedium.copyWith(
                  fontSize: 14, fontWeight: FontWeight.w700, color: _muted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in _types.entries)
                Semantics(
                  button: true,
                  selected: _type == e.key,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => setState(() => _type = e.key),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 44),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _type == e.key ? _forest : Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: _type == e.key ? _forest : _border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_icon(e.key),
                              size: 18, color: _type == e.key ? Colors.white : _forest),
                          const SizedBox(width: 6),
                          Text(e.value,
                              style: t.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: _type == e.key ? Colors.white : _ink)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _forest,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _adding ? null : _add,
              icon: const Icon(Icons.add, size: 20),
              label: Text('Add location',
                  style: t.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _row(FlutterFlowTheme t, Map<String, dynamic> place) {
    final id = place['id'].toString();
    final name = (place['name'] ?? '').toString();
    final type = (place['location_type'] ?? '').toString();
    final n = _counts[id] ?? 0;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration:
                  BoxDecoration(color: _sage, borderRadius: BorderRadius.circular(12)),
              child: Icon(_icon(type), color: _forest, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: t.bodyLarge.copyWith(
                          fontSize: 16, fontWeight: FontWeight.w700, color: _ink)),
                  Text(
                    '${_types[type] ?? 'Somewhere else'} · ${n == 1 ? '1 food' : '$n foods'}',
                    style: t.bodySmall.copyWith(color: _muted, fontSize: 13),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Remove $name',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: () => _remove(place),
              icon: const Icon(Icons.delete_outline, color: _muted),
            ),
          ],
        ),
      ),
    );
  }
}
''';
