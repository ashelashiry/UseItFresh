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

/// Owner, 14 Sep: a receipt put mandarins in the fridge, and "Fix this line."
/// could not move them — only the name could change.
///
/// The line editor becomes ScanLineEditor: name, how many, category and where
/// it is kept, choosing from this household's own places (a fruit bowl added
/// under Profile → Storage shows up here), with a way to add a place. Save
/// writes the whole line back, detail included, exactly as the review list
/// shows it.
void buildStarterEditFlow(App app) {
  app.customWidget(
    'ScanLineEditor',
    parameters: {'lineIndex': int_},
    description:
        'Fix one line of a receipt or photo review: name, how many, category '
        'and where it is kept.',
    code: _scanLineEditor,
  );

  final line = ff.Pages.scanLinePage;
  app.editPage(line, (page) {
    // The old detail line, Save button and note go in a second push.
    page.ensureReplaced(
      line.widgets.byKey('TextField_4n8kqca4').single, // the name field
      CustomWidget(
        widgetName: 'ScanLineEditor',
        name: 'ScanLineFields',
        arguments: {'lineIndex': PageParam('index')},
      ),
    );
  });
}

const _scanLineEditor = r'''
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// One line of the scan review, fixed in place.
class ScanLineEditor extends StatefulWidget {
  const ScanLineEditor({super.key, this.width, this.height, this.lineIndex});

  final double? width;
  final double? height;
  final int? lineIndex;

  @override
  State<ScanLineEditor> createState() => _ScanLineEditorState();
}

class _ScanLineEditorState extends State<ScanLineEditor> {
  static const _forest = Color(0xFF07533A);
  static const _ink = Color(0xFF202C24);
  static const _muted = Color(0xFF59665D);
  static const _border = Color(0xFFDCE3D7);

  // The same words the category picker uses.
  static const _labels = <String, String>{
    'dairy': 'Dairy',
    'meat_poultry': 'Meat & poultry',
    'seafood': 'Seafood',
    'eggs': 'Eggs',
    'cooked_leftovers': 'Cooked leftovers',
    'fruit': 'Fruit',
    'vegetables': 'Vegetables',
    'bread_bakery': 'Bread & bakery',
    'pantry_dry': 'Pantry & dry goods',
    'frozen': 'Frozen food',
    'condiments_sauces': 'Condiments & sauces',
    'infant_food': 'Infant food & formula',
  };

  final _name = TextEditingController();
  String _category = '';
  int _quantity = 1;
  String _place = '';
  List<Map<String, dynamic>> _places = const [];
  bool _placesLoaded = false;
  bool _started = false;

  int get _i => widget.lineIndex ?? -1;

  @override
  void initState() {
    super.initState();
    final foods = FFAppState().scannedFoods;
    if (_i >= 0 && _i < foods.length) {
      final f = foods[_i];
      _name.text = f.name;
      _category = f.category;
      _quantity = f.quantity < 1 ? 1 : f.quantity;
      _place = f.place;
      _started = true;
    }
    _loadPlaces();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _loadPlaces() async {
    final household = FFAppState().currentHouseholdId;
    if (household.isEmpty) return;
    try {
      final rows = await SupaFlow.client
          .from('storage_locations')
          .select('id, name, location_type')
          .eq('household_id', household)
          .order('location_type')
          .order('name');
      if (!mounted) return;
      setState(() {
        _places = List<Map<String, dynamic>>.from(rows as List);
        _placesLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _placesLoaded = true);
    }
  }

  static IconData _placeIcon(String type) {
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

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Give it a name first.')));
      return;
    }
    String placeName = '';
    for (final p in _places) {
      if (p['id'].toString() == _place) placeName = (p['name'] ?? '').toString();
    }
    final detail = <String>[
      if (_quantity > 1) '$_quantity of them',
      _labels[_category] ?? 'No category',
      if (placeName.isNotEmpty) placeName,
    ].join(' · ');
    if (_i >= 0 && _i < FFAppState().scannedFoods.length) {
      FFAppState().update(() {
        FFAppState().updateScannedFoodsAtIndex(
          _i,
          (_) => ScannedFoodStruct(
            name: name[0].toUpperCase() + name.substring(1),
            category: _category,
            quantity: _quantity,
            place: _place,
            detail: detail,
          ),
        );
      });
    }
    GoRouter.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    if (!_started) {
      return Text('This line is no longer on the list.',
          style: t.bodyLarge.copyWith(color: _muted));
    }
    return SizedBox(
      width: widget.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _label(t, 'Name'),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            style: t.bodyLarge.copyWith(fontSize: 16, color: _ink),
            decoration: _box('e.g. Mandarins'),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _label(t, 'How many')),
              _stepper(Icons.remove, _quantity > 1,
                  () => setState(() => _quantity--)),
              SizedBox(
                width: 48,
                child: Text('$_quantity',
                    textAlign: TextAlign.center,
                    style: t.titleMedium
                        .copyWith(fontSize: 18, fontWeight: FontWeight.w800, color: _ink)),
              ),
              _stepper(Icons.add, _quantity < 24,
                  () => setState(() => _quantity++)),
            ],
          ),
          const SizedBox(height: 20),
          _label(t, 'Kept in'),
          if (!_placesLoaded)
            Text('Loading your places…',
                style: t.bodyMedium.copyWith(color: _muted, fontSize: 14))
          else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in _places)
                  _choice(
                    t,
                    (p['name'] ?? '').toString(),
                    _place == p['id'].toString(),
                    () => setState(() => _place = p['id'].toString()),
                    icon: _placeIcon((p['location_type'] ?? '').toString()),
                  ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48), foregroundColor: _forest),
                onPressed: () async {
                  await context.pushNamed('StorageLocationsPage');
                  if (mounted) _loadPlaces();
                },
                icon: const Icon(Icons.add, size: 18),
                label: Text('Add a place, like a fruit bowl',
                    style: t.bodyMedium
                        .copyWith(color: _forest, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
          const SizedBox(height: 12),
          _label(t, 'Category'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in _labels.entries)
                _choice(t, e.value, _category == e.key,
                    () => setState(() => _category = e.key)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _forest,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _save,
              child: Text('Save this line',
                  style: t.bodyLarge.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(FlutterFlowTheme t, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: t.bodyMedium.copyWith(
                fontSize: 14, fontWeight: FontWeight.w700, color: _muted)),
      );

  InputDecoration _box(String hint) => InputDecoration(
        hintText: hint,
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
      );

  Widget _choice(FlutterFlowTheme t, String label, bool on, VoidCallback onTap,
          {IconData? icon}) =>
      Semantics(
        button: true,
        selected: on,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: on ? _forest : Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: on ? _forest : _border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: on ? Colors.white : _forest),
                  const SizedBox(width: 6),
                ],
                Text(label,
                    style: t.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: on ? Colors.white : _ink)),
              ],
            ),
          ),
        ),
      );

  Widget _stepper(IconData icon, bool enabled, VoidCallback onTap) => Opacity(
        opacity: enabled ? 1 : 0.4,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: _border),
            ),
            child: Icon(icon, color: _forest, size: 20),
          ),
        ),
      );
}
''';
