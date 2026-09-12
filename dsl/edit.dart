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

/// Fixing a food after it has been added.
///
/// The photo map adds food deliberately fast: no date typed, and sometimes no
/// category. Until now there was no way to correct any of it — the only route
/// was to throw the item out and add it again, which also writes a "thrown
/// out" event that never happened. That undercuts the whole photo-first idea,
/// because the quick add is only quick if fixing it later is easy.
///
/// One screen, reached from the food's own screen: name, category, where it is
/// kept, how many, and the printed date with what kind of date it is. A date
/// with no kind is not allowed to happen — the status engine reads the kind to
/// decide what "past" means — so a date saved without one is stored as
/// "unknown", which the engine already handles.
///
/// The fields live in app state and the page's buttons call actions, the same
/// shape as the photo map: a custom widget cannot be read by the page, so the
/// widget writes what it collects and the action reads it back.
void buildStarterEditFlow(App app) {
  app.state('editItemId', string);
  app.state('editName', string);
  app.state('editCategory', string);
  app.state('editLocationId', string);
  app.state('editQuantity', int_.withDefault(1));
  app.state('editPrintedDate', string);
  app.state('editDateType', string);

  app.customAction(
    'LoadItemForEdit',
    args: {'itemId': string},
    returns: string,
    description:
        "Reads one food into the edit fields. Returns '' when loaded, or a "
        'message saying why not.',
    code: _loadItemForEdit,
  );

  app.customAction(
    'SaveItemEdits',
    args: {},
    returns: string,
    description:
        "Writes the edit fields back to the food. Returns '' when saved, or a "
        'message saying why not.',
    code: _saveItemEdits,
  );

  app.customWidget(
    'ItemEditFields',
    parameters: {},
    description:
        'The editable details of one food — name, category, where it is kept, '
        'how many, and the printed date — held in app state.',
    code: _itemEditFields,
  );

  app.ensurePage(
    'EditItemPage',
    description:
        'Fix a food that is already in the kitchen: its name, category, place, '
        'how many, and the date printed on it.',
    route: 'edit-item',
    params: {'itemId': string},
    onLoad: [
      CallCustomAction.named(
        'LoadItemForEdit',
        args: {'itemId': string},
        returnType: string,
        arguments: {'itemId': PageParam('itemId')},
        outputAs: 'editLoaded',
      ),
      If(
        Not(Equals(ActionOutput('editLoaded'), '')),
        then: [Snackbar(ActionOutput('editLoaded')), NavigateBack()],
      ),
    ],
    body: Scaffold(
      body: Container(
        name: 'EditItemBody',
        padding:
            const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 24),
        child: Column(
          scrollable: true,
          crossAxis: CrossAxis.stretch,
          spacing: 12,
          children: [
            Row(
              name: 'EditItemBackRow',
              mainAxis: MainAxis.start,
              children: [
                Container(
                  name: 'EditItemBack',
                  onTap: [NavigateBack()],
                  width: 44,
                  height: 44,
                  color: Colors.secondaryBackground,
                  borderColor: Colors.alternate,
                  borderWidth: 1,
                  borderRadius: 999,
                  child: Icon('arrow_back', size: 20, color: Colors.primaryText),
                ),
              ],
            ),
            Text('Fix the details.',
                name: 'EditItemHeadline',
                style: Styles.headlineMedium,
                color: Colors.primary),
            Text(
              'Anything the app guessed, or left blank when you added it in a '
              'hurry.',
              name: 'EditItemLede',
              style: Styles.bodyMedium,
              color: Colors.secondaryText,
            ),
            CustomWidget(
              widgetName: 'ItemEditFields',
              name: 'EditItemPanel',
              arguments: {},
            ),
            Button(
              'Save changes',
              name: 'EditItemSave',
              width: double.infinity,
              height: 50,
              borderRadius: 14,
              color: Colors.primary,
              textColor: Colors.secondaryBackground,
              onTap: [
                CallCustomAction.named(
                  'SaveItemEdits',
                  args: {},
                  returnType: string,
                  arguments: {},
                  outputAs: 'editSaved',
                ),
                If(
                  Equals(ActionOutput('editSaved'), ''),
                  then: [
                    Snackbar('Saved.'),
                    // Reopening the food's screen so it shows what was saved,
                    // and so Back does not land on the editor again.
                    Navigate(
                      ff.Pages.foodItemPage,
                      params: {'itemId': PageParam('itemId')},
                      replaceRoute: true,
                    ),
                  ],
                  orElse: [Snackbar(ActionOutput('editSaved'))],
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  final item = ff.Pages.foodItemPage;
  app.editPage(item, (page) {
    page.ensureInsertedBefore(
      item.widgets.byKey('Button_q7rrsu3l').single,
      Button(
        'Edit details',
        name: 'ItemEdit',
        width: double.infinity,
        height: 48,
        borderRadius: 14,
        color: Colors.secondaryBackground,
        textColor: Colors.primary,
        onTap: [
          Navigate('EditItemPage', params: {'itemId': PageParam('itemId')}),
        ],
      ),
    );
  });
}

const _loadItemForEdit = r'''
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads one food into the edit fields.
///
/// Everything is read as a string, including the date (Postgres hands back
/// yyyy-mm-dd), because that is what the fields hold and what goes back.
/// Returns '' when loaded, and otherwise a sentence saying why not.
Future<String> loadItemForEdit(String? itemId) async {
  final id = (itemId ?? '').trim();
  if (id.isEmpty) return 'Could not find that food.';
  try {
    final row = await SupaFlow.client
        .from('food_items')
        .select(
            'name, category, quantity, storage_location_id, printed_date, printed_date_type')
        .eq('id', id)
        .maybeSingle();
    if (row == null) return 'Could not find that food.';
    final counted =
        row['quantity'] is num ? (row['quantity'] as num).round() : 1;
    FFAppState().update(() {
      FFAppState().editItemId = id;
      FFAppState().editName = (row['name'] ?? '').toString();
      FFAppState().editCategory = (row['category'] ?? '').toString();
      FFAppState().editLocationId =
          (row['storage_location_id'] ?? '').toString();
      FFAppState().editQuantity = counted < 1 ? 1 : counted;
      FFAppState().editPrintedDate = (row['printed_date'] ?? '').toString();
      FFAppState().editDateType = (row['printed_date_type'] ?? '').toString();
    });
    return '';
  } on PostgrestException catch (error) {
    return error.message;
  } catch (_) {
    return 'Could not reach your kitchen. Check your signal and try again.';
  }
}
''';

const _saveItemEdits = r'''
import 'package:supabase_flutter/supabase_flutter.dart';

/// Writes the edit fields back to the food.
///
/// A date saved without saying what kind it is becomes "unknown" rather than
/// nothing: the status engine reads the kind to decide what being past it
/// means, and a date it cannot interpret is worse than a date it knows it
/// cannot interpret. Clearing the date clears the kind with it.
///
/// Returns '' when saved, and otherwise a sentence saying why not.
Future<String> saveItemEdits() async {
  final id = FFAppState().editItemId;
  if (id.isEmpty) return 'Nothing to save.';
  final name = FFAppState().editName.trim();
  if (name.isEmpty) return 'Give it a name first.';

  final date = FFAppState().editPrintedDate.trim();
  final kind = FFAppState().editDateType.trim();
  final category = FFAppState().editCategory.trim();
  final place = FFAppState().editLocationId.trim();
  final counted = FFAppState().editQuantity;

  try {
    await SupaFlow.client.from('food_items').update({
      'name': name,
      'category': category.isEmpty ? null : category,
      'storage_location_id': place.isEmpty ? null : place,
      'quantity': counted < 1 ? 1 : counted,
      'printed_date': date.isEmpty ? null : date,
      'printed_date_type':
          date.isEmpty ? null : (kind.isEmpty ? 'unknown' : kind),
    }).eq('id', id);
    return '';
  } on PostgrestException catch (error) {
    if (error.code == '42501') {
      return 'Your account is not allowed to change this food.';
    }
    return error.message;
  } catch (_) {
    return 'Could not save. Check your signal and try again.';
  }
}
''';

const _itemEditFields = r'''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The editable details of one food, held in app state so the page's Save
/// button can read them: FlutterFlow cannot read a custom widget.
///
/// The places come from the household's own storage locations, so this never
/// offers somewhere the food cannot go.
class ItemEditFields extends StatefulWidget {
  const ItemEditFields({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<ItemEditFields> createState() => _ItemEditFieldsState();
}

class _ItemEditFieldsState extends State<ItemEditFields> {
  // The same words the rest of the app uses for a category.
  static const _categories = <String, String>{
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
  static const _dateKinds = <String, String>{
    'use_by': 'Use by',
    'best_before': 'Best before',
    'sell_by': 'Sell by',
    'unknown': 'Not sure',
  };
  static const _months = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  TextEditingController? _name;
  String _nameFor = '';
  List<Map<String, dynamic>> _places = const [];
  String _placesFor = '';

  @override
  void dispose() {
    _name?.dispose();
    super.dispose();
  }

  Future<void> _loadPlaces(String household) async {
    try {
      final rows = await SupaFlow.client
          .from('storage_locations')
          .select('id, name, location_type')
          .eq('household_id', household)
          .order('location_type')
          .order('name');
      if (!mounted || household != _placesFor) return;
      setState(() => _places = List<Map<String, dynamic>>.from(rows as List));
    } catch (_) {
      // No signal: the other fields still work, and saving keeps the place
      // the food already had.
    }
  }

  void _set(void Function() change) => FFAppState().update(change);

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String _said(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    return '${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final now = DateTime.tryParse(FFAppState().editPrintedDate) ?? today;
    final first = today.subtract(const Duration(days: 730));
    final last = today.add(const Duration(days: 1095));
    final picked = await showDatePicker(
      context: context,
      initialDate: now.isBefore(first) ? first : (now.isAfter(last) ? last : now),
      firstDate: first,
      lastDate: last,
      helpText: 'The date printed on the pack',
    );
    if (picked == null || !mounted) return;
    _set(() {
      FFAppState().editPrintedDate = _iso(picked);
      if (FFAppState().editDateType.isEmpty) {
        FFAppState().editDateType = 'use_by';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final t = FlutterFlowTheme.of(context);
    final household = FFAppState().currentHouseholdId;
    if (household.isNotEmpty && household != _placesFor) {
      _placesFor = household;
      _loadPlaces(household);
    }
    // The controller follows whichever food was loaded, not every keystroke.
    final id = FFAppState().editItemId;
    if (id != _nameFor) {
      _nameFor = id;
      _name?.dispose();
      _name = TextEditingController(text: FFAppState().editName);
    }
    final date = FFAppState().editPrintedDate;
    final kind = FFAppState().editDateType;
    final counted = FFAppState().editQuantity < 1 ? 1 : FFAppState().editQuantity;
    final placeId = FFAppState().editLocationId;
    final known = _places.any((p) => p['id'].toString() == placeId);

    return SizedBox(
      width: widget.width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _label(t, 'Name'),
          TextField(
            controller: _name,
            decoration: _look(t, 'What it is'),
            onChanged: (v) => _set(() => FFAppState().editName = v),
          ),
          const SizedBox(height: 16),
          _label(t, 'Category'),
          DropdownButtonFormField<String>(
            value: _categories.containsKey(FFAppState().editCategory)
                ? FFAppState().editCategory
                : null,
            isExpanded: true,
            decoration: _look(t, 'Not set'),
            items: [
              for (final e in _categories.entries)
                DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) =>
                _set(() => FFAppState().editCategory = v ?? ''),
          ),
          const SizedBox(height: 16),
          _label(t, 'Where it is kept'),
          DropdownButtonFormField<String>(
            value: known ? placeId : null,
            isExpanded: true,
            decoration: _look(t, _places.isEmpty ? 'Loading…' : 'Not set'),
            items: [
              for (final p in _places)
                DropdownMenuItem(
                  value: p['id'].toString(),
                  child: Text((p['name'] ?? '').toString(),
                      overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) =>
                _set(() => FFAppState().editLocationId = v ?? ''),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _label(t, 'How many')),
              _step(t, Icons.remove, 'One fewer',
                  counted > 1 ? () => _set(() => FFAppState().editQuantity = counted - 1) : null),
              SizedBox(
                width: 56,
                child: Text('$counted',
                    textAlign: TextAlign.center, style: t.titleSmall),
              ),
              _step(t, Icons.add, 'One more',
                  counted < 99 ? () => _set(() => FFAppState().editQuantity = counted + 1) : null),
            ],
          ),
          const SizedBox(height: 16),
          _label(t, 'Date on the pack'),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: Icon(Icons.event, size: 18, color: t.primary),
                  label: Text(
                    date.isEmpty ? 'No date' : _said(date),
                    overflow: TextOverflow.ellipsis,
                    style: t.bodyMedium.copyWith(color: t.primaryText),
                  ),
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    minimumSize: const Size(0, 48),
                    backgroundColor: t.secondaryBackground,
                    side: BorderSide(color: t.alternate),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              if (date.isNotEmpty)
                IconButton(
                  tooltip: 'Take the date off',
                  onPressed: () => _set(() {
                    FFAppState().editPrintedDate = '';
                    FFAppState().editDateType = '';
                  }),
                  icon: Icon(Icons.close, color: t.secondaryText),
                ),
            ],
          ),
          if (date.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final e in _dateKinds.entries)
                  _chip(t, e.value, kind == e.key,
                      () => _set(() => FFAppState().editDateType = e.key)),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Text(
            date.isEmpty
                ? 'With no date, this food gets a typical keep time for its '
                    'category.'
                : 'Use by is a safety date; best before is about quality. The '
                    'app treats them differently.',
            style: t.bodySmall.copyWith(color: t.secondaryText),
          ),
        ],
      ),
    );
  }

  InputDecoration _look(FlutterFlowTheme t, String hint) => InputDecoration(
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: t.secondaryBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: t.alternate),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: t.alternate),
        ),
      );

  Widget _label(FlutterFlowTheme t, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: t.bodySmall
              .copyWith(color: t.secondaryText, fontWeight: FontWeight.w700),
        ),
      );

  Widget _chip(FlutterFlowTheme t, String text, bool on, VoidCallback onTap) =>
      Semantics(
        button: true,
        selected: on,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: on ? t.primary : t.secondaryBackground,
              border: Border.all(color: on ? t.primary : t.alternate),
            ),
            child: Text(
              text,
              style: t.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: on ? Colors.white : t.primaryText,
              ),
            ),
          ),
        ),
      );

  Widget _step(FlutterFlowTheme t, IconData icon, String label,
          VoidCallback? onTap) =>
      Semantics(
        button: true,
        enabled: onTap != null,
        label: label,
        child: Opacity(
          opacity: onTap == null ? 0.4 : 1,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: t.secondaryBackground,
                border: Border.all(color: t.alternate),
              ),
              child: Icon(icon, size: 20, color: t.primary),
            ),
          ),
        ),
      );
}
''';
