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

/// Use-by dates on the photo map, optional.
///
/// The typical keep time for each food's category already works with no
/// date at all. For an exact reminder, tapping a food's name on the photo map
/// now also offers "Add use-by date": a date picker, with a cross to take it
/// off again. Saved foods carry it as the printed date, type use-by, which the
/// status engine and the reminders already read.
///
/// MapFood, ShelfReview and SaveMapFoods all exist, so this goes through the
/// brownfield helpers: one field added to the struct, and the two pieces of
/// custom code replaced whole. ReadShelfPhoto is untouched: a food read from
/// a photo starts with no date.
void buildStarterEditFlow(App app) {
  app.raw((project) {
    ensureDataStructField(
      project,
      structName: 'MapFood',
      fieldName: 'useBy',
      type: stringType,
      description: "The pack's use-by date as yyyy-mm-dd, or empty when none "
          'was added.',
    );
    updateCustomWidget(project, name: 'ShelfReview', code: _shelfReview);
    updateCustomAction(project, name: 'SaveMapFoods', code: _saveMapFoods);
  });
}

const _saveMapFoods = r'''
import 'package:supabase_flutter/supabase_flutter.dart';

/// Adds every ticked food on the photo map, in one insert, then deletes the
/// photos the map was drawn on.
///
/// One insert, so it is all or nothing. The map is emptied before the write,
/// so a second tap while the first is still saving finds nothing to add twice;
/// if the write fails, everything comes back.
///
/// A food given a use-by date on the map is saved with it as the printed
/// date; the rest get the typical keep time for their category.
Future<String> saveMapFoods() async {
  final all = List<MapFoodStruct>.of(FFAppState().mapFoods);
  final photos = List<String>.of(FFAppState().mapPhotos);
  final ticked = all.where((f) => f.decision == 'yes').toList();
  if (ticked.isEmpty) return 'Tick at least one food to add.';

  final household = FFAppState().currentHouseholdId;
  if (household.isEmpty) {
    return 'No household yet. Create or join one before adding food.';
  }
  final photoPlace =
      FFAppState().mapPlace.isEmpty ? 'fridge' : FFAppState().mapPlace;
  final uid = SupaFlow.client.auth.currentUser?.id;

  void putBack() => FFAppState().update(() {
        FFAppState().mapFoods = all;
        FFAppState().mapPhotos = photos;
      });

  FFAppState().update(() {
    FFAppState().mapFoods = [];
    FFAppState().mapPhotos = [];
  });
  try {
    final rows = await SupaFlow.client
        .from('storage_locations')
        .select('id, location_type, is_default')
        .eq('household_id', household);
    final locations = List<Map<String, dynamic>>.from(rows as List);
    String? locationFor(String type) {
      for (final l in locations) {
        if (l['location_type'] == type) return l['id'].toString();
      }
      for (final l in locations) {
        if (l['is_default'] == true) return l['id'].toString();
      }
      return locations.isEmpty ? null : locations.first['id'].toString();
    }

    await SupaFlow.client.from('food_items').insert([
      for (final f in ticked)
        {
          'household_id': household,
          'storage_location_id':
              locationFor(f.place.isEmpty ? photoPlace : f.place),
          'created_by': uid,
          'name': f.name,
          if (f.category.isNotEmpty) 'category': f.category,
          'quantity': f.quantity < 1 ? 1 : f.quantity,
          'source_type': 'fridge_scan',
          if (DateTime.tryParse(f.useBy) != null) ...{
            'printed_date': f.useBy,
            'printed_date_type': 'use_by',
          },
        },
    ]);
  } on PostgrestException catch (error) {
    putBack();
    if (error.code == '42501') {
      return 'Your account is not allowed to add to this household.';
    }
    return error.message;
  } catch (_) {
    putBack();
    return 'Could not add them. Check your signal and try again.';
  }

  // The photos were only needed for the map.
  final paths = [for (final u in photos) _storagePath(u)]
      .whereType<String>()
      .toList();
  if (paths.isNotEmpty) {
    try {
      await SupaFlow.client.storage.from('food-images').remove(paths);
    } catch (_) {}
  }
  return '';
}

/// The object path inside the food-images bucket, from a signed URL.
String? _storagePath(String signedUrl) {
  const marker = '/object/sign/food-images/';
  final at = signedUrl.indexOf(marker);
  if (at < 0) return null;
  final rest = signedUrl.substring(at + marker.length);
  final q = rest.indexOf('?');
  return Uri.decodeComponent(q < 0 ? rest : rest.substring(0, q));
}
''';

const _shelfReview = r'''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The photo map: each shelf photo with its foods outlined and numbered, and
/// the list below to tick (yes), cross (no) or fix each one in place,
/// including an optional use-by date.
///
/// Reads the map from app state rather than taking it as a parameter:
/// FlutterFlow cannot pass a list to a custom widget.
class ShelfReview extends StatefulWidget {
  const ShelfReview({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<ShelfReview> createState() => _ShelfReviewState();
}

class _ShelfReviewState extends State<ShelfReview> {
  // The same words the category picker uses.
  static const _categoryNames = <String, String>{
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
  static const _places = <String, String>{
    'fridge': 'Fridge',
    'freezer': 'Freezer',
    'pantry': 'Pantry',
  };
  static const _months = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  int _selected = -1;
  int _editing = -1;
  final Map<int, TextEditingController> _names = {};

  @override
  void dispose() {
    for (final c in _names.values) {
      c.dispose();
    }
    super.dispose();
  }

  MapFoodStruct _copy(MapFoodStruct f,
          {String? name,
          String? category,
          String? decision,
          String? place,
          String? useBy}) =>
      MapFoodStruct(
        name: name ?? f.name,
        category: category ?? f.category,
        quantity: f.quantity,
        kind: f.kind,
        box: f.box,
        photo: f.photo,
        decision: decision ?? f.decision,
        place: place ?? f.place,
        useBy: useBy ?? f.useBy,
      );

  void _change(int i, MapFoodStruct Function(MapFoodStruct) change) {
    FFAppState().update(() => FFAppState().updateMapFoodsAtIndex(i, change));
  }

  void _decide(int i, String decision) {
    final now = FFAppState().mapFoods[i].decision == decision ? '' : decision;
    _change(i, (f) => _copy(f, decision: now));
    final next = FFAppState().mapFoods.indexWhere((f) => f.decision.isEmpty);
    setState(() => _selected = next >= 0 ? next : i);
  }

  void _yesToTheRest() {
    FFAppState().update(() {
      final foods = FFAppState().mapFoods;
      for (var i = 0; i < foods.length; i++) {
        if (foods[i].decision.isEmpty) {
          FFAppState()
              .updateMapFoodsAtIndex(i, (f) => _copy(f, decision: 'yes'));
        }
      }
    });
  }

  // yyyy-mm-dd, as the database stores a date.
  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  // "14 Sep", with the year only when it is not this year.
  static String _said(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    final day = '${d.day} ${_months[d.month - 1]}';
    return d.year == DateTime.now().year ? day : '$day ${d.year}';
  }

  Future<void> _pickUseBy(int i, MapFoodStruct f) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final first = today.subtract(const Duration(days: 60));
    final last = today.add(const Duration(days: 730));
    var start = DateTime.tryParse(f.useBy) ?? today.add(const Duration(days: 3));
    if (start.isBefore(first)) start = first;
    if (start.isAfter(last)) start = last;
    final picked = await showDatePicker(
      context: context,
      initialDate: start,
      firstDate: first,
      lastDate: last,
      helpText: 'Use-by date on the pack',
    );
    if (picked == null || !mounted) return;
    _change(i, (x) => _copy(x, useBy: _iso(picked), decision: 'yes'));
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final t = FlutterFlowTheme.of(context);
    final foods = FFAppState().mapFoods;
    final photos = FFAppState().mapPhotos;
    final place =
        FFAppState().mapPlace.isEmpty ? 'fridge' : FFAppState().mapPlace;
    if (_selected >= foods.length) _selected = -1;
    final checked = foods.where((f) => f.decision.isNotEmpty).length;

    return SizedBox(
      width: widget.width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _placeChips(t, place),
          const SizedBox(height: 12),
          for (final url in photos) ...[
            _PhotoMap(
              url: url,
              selected: _selected,
              entries: [
                for (var i = 0; i < foods.length; i++)
                  if (foods[i].photo == url) MapEntry(i, foods[i]),
              ],
              onTap: (i) => setState(() => _selected = i),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  '$checked of ${foods.length} checked',
                  style: t.bodySmall.copyWith(color: t.secondaryText),
                ),
              ),
              if (checked < foods.length)
                TextButton(
                  onPressed: _yesToTheRest,
                  child: Text(
                    'Yes to the rest',
                    style: t.bodySmall.copyWith(
                        color: t.primary, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          for (var i = 0; i < foods.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _row(t, i, foods[i], place),
            ),
        ],
      ),
    );
  }

  Widget _placeChips(FlutterFlowTheme t, String place) => Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('This is the',
              style: t.bodySmall.copyWith(color: t.secondaryText)),
          for (final e in _places.entries)
            Semantics(
              button: true,
              selected: place == e.key,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () =>
                    FFAppState().update(() => FFAppState().mapPlace = e.key),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: place == e.key ? t.primary : t.secondaryBackground,
                    border: Border.all(
                        color: place == e.key ? t.primary : t.alternate),
                  ),
                  child: Text(
                    e.value,
                    style: t.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: place == e.key ? Colors.white : t.primaryText,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );

  Widget _row(FlutterFlowTheme t, int i, MapFoodStruct f, String place) {
    final yes = f.decision == 'yes';
    final no = f.decision == 'no';
    final selected = i == _selected;
    final where = _places[f.place.isEmpty ? place : f.place] ?? 'Fridge';
    final useBy = _said(f.useBy);
    final detail = <String>[
      if (f.quantity > 1) '${f.quantity}',
      if (f.kind.isNotEmpty) f.kind,
      _categoryNames[f.category] ?? 'No category',
      where,
      if (useBy.isNotEmpty) 'use by $useBy',
    ].join(' · ');

    return Opacity(
      opacity: no ? 0.55 : 1,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        decoration: BoxDecoration(
          color: t.secondaryBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? t.primary : t.alternate,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: yes
                        ? t.primary
                        : (no ? t.error.withOpacity(0.15) : t.accent1),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: yes ? Colors.white : (no ? t.error : t.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() {
                      _selected = i;
                      _editing = _editing == i ? -1 : i;
                    }),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.titleSmall.copyWith(
                            decoration: no ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        Text(
                          detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodySmall.copyWith(color: t.secondaryText),
                        ),
                      ],
                    ),
                  ),
                ),
                _round(t, '✓', yes, t.primary, () => _decide(i, 'yes'),
                    'Yes, add ${f.name}'),
                const SizedBox(width: 6),
                _round(t, '✕', no, t.error, () => _decide(i, 'no'),
                    'No, leave out ${f.name}'),
              ],
            ),
            if (_editing == i) _editor(t, i, f, place),
          ],
        ),
      ),
    );
  }

  Widget _round(FlutterFlowTheme t, String glyph, bool on, Color colour,
          VoidCallback onTap, String label) =>
      Semantics(
        button: true,
        label: label,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: on ? colour : t.secondaryBackground,
              border: Border.all(color: on ? colour : t.alternate),
            ),
            child: Text(
              glyph,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: on ? Colors.white : t.secondaryText,
              ),
            ),
          ),
        ),
      );

  Widget _editor(FlutterFlowTheme t, int i, MapFoodStruct f, String place) {
    final controller =
        _names.putIfAbsent(i, () => TextEditingController(text: f.name));
    InputDecoration look(String label) => InputDecoration(
          labelText: label,
          isDense: true,
          filled: true,
          fillColor: t.primaryBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: t.alternate),
          ),
        );
    final useBy = _said(f.useBy);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            decoration: look('Name'),
            onChanged: (v) {
              if (v.trim().isNotEmpty) {
                _change(i, (x) => _copy(x, name: v.trim(), decision: 'yes'));
              }
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value:
                      _categoryNames.containsKey(f.category) ? f.category : null,
                  isExpanded: true,
                  decoration: look('Category'),
                  items: [
                    for (final e in _categoryNames.entries)
                      DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      _change(i, (x) => _copy(x, category: v, decision: 'yes'));
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: f.place.isEmpty ? place : f.place,
                  isExpanded: true,
                  decoration: look('Kept in'),
                  items: [
                    for (final e in _places.entries)
                      DropdownMenuItem(value: e.key, child: Text(e.value)),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      _change(i, (x) => _copy(x, place: v, decision: 'yes'));
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickUseBy(i, f),
                  icon: Icon(Icons.event, size: 18, color: t.primary),
                  label: Text(
                    useBy.isEmpty
                        ? 'Add use-by date (optional)'
                        : 'Use by $useBy',
                    overflow: TextOverflow.ellipsis,
                    style: t.bodyMedium.copyWith(color: t.primaryText),
                  ),
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    minimumSize: const Size(0, 44),
                    backgroundColor: t.primaryBackground,
                    side: BorderSide(color: t.alternate),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              if (useBy.isNotEmpty)
                IconButton(
                  tooltip: 'Take the date off',
                  onPressed: () => _change(i, (x) => _copy(x, useBy: '')),
                  icon: Icon(Icons.close, color: t.secondaryText),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One photo with its foods outlined. The photo is shown at its own shape,
/// so an outline given on a 0-1000 scale lands where the food is.
class _PhotoMap extends StatefulWidget {
  const _PhotoMap({
    required this.url,
    required this.entries,
    required this.selected,
    required this.onTap,
  });

  final String url;
  final List<MapEntry<int, MapFoodStruct>> entries;
  final int selected;
  final void Function(int) onTap;

  @override
  State<_PhotoMap> createState() => _PhotoMapState();
}

class _PhotoMapState extends State<_PhotoMap> {
  double? _aspect;
  ImageStream? _stream;
  ImageStreamListener? _listener;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(_PhotoMap old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) _resolve();
  }

  void _resolve() {
    _stop();
    final stream = NetworkImage(widget.url).resolve(ImageConfiguration.empty);
    final listener = ImageStreamListener((info, _) {
      if (!mounted) return;
      setState(() => _aspect = info.image.width / info.image.height);
    }, onError: (_, __) {});
    stream.addListener(listener);
    _stream = stream;
    _listener = listener;
  }

  void _stop() {
    final stream = _stream, listener = _listener;
    if (stream != null && listener != null) stream.removeListener(listener);
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: _aspect ?? 3 / 4,
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth, h = c.maxHeight;
            return Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    widget.url,
                    fit: BoxFit.fill,
                    errorBuilder: (_, __, ___) => Container(color: t.alternate),
                  ),
                ),
                for (final e in widget.entries) ..._outline(t, e.key, e.value, w, h),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _outline(
      FlutterFlowTheme t, int i, MapFoodStruct f, double w, double h) {
    final p = f.box.split(',').map((s) => double.tryParse(s.trim())).toList();
    if (p.length != 4 || p.any((v) => v == null)) return const [];
    final top = p[0]! / 1000 * h, left = p[1]! / 1000 * w;
    final bh = (p[2]! - p[0]!) / 1000 * h, bw = (p[3]! - p[1]!) / 1000 * w;
    if (bw < 6 || bh < 6) return const [];

    final yes = f.decision == 'yes', no = f.decision == 'no';
    final selected = i == widget.selected;
    final edge = yes
        ? const Color(0xFF3FD08B)
        : (no ? const Color(0xFFFF8E78) : Colors.white);
    final mark = yes ? '✓ ' : (no ? '✕ ' : '');
    final label = bw < 90 ? '${i + 1}' : '${i + 1} ${f.name}';

    return [
      Positioned(
        left: left,
        top: top,
        width: bw,
        height: bh,
        child: Semantics(
          button: true,
          label: '${i + 1}. ${f.name}',
          child: GestureDetector(
            onTap: () => widget.onTap(i),
            child: Container(
              alignment: Alignment.topLeft,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: no
                    ? Colors.black.withOpacity(0.45)
                    : (yes ? t.primary.withOpacity(0.14) : Colors.transparent),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: edge, width: yes ? 3 : 2),
                boxShadow: [
                  if (selected)
                    const BoxShadow(color: Colors.white, spreadRadius: 3)
                  else
                    const BoxShadow(color: Color(0x55000000), blurRadius: 2),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: yes ? t.primary : (no ? t.error : Colors.white),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$mark$label',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: (yes || no) ? Colors.white : t.primaryText,
                    decoration: no ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ];
  }
}
''';
