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

/// One smart camera: the Scan tab's camera recognises a receipt by itself.
///
/// The Scan tab opens a camera straight away, and that camera reads a fridge
/// shelf. A receipt photographed with it came back as "No food I could name
/// in that photo." (13 Sep: the owner did exactly this before finding the
/// Receipt tile). Now the first photo of a map is also checked for being a
/// receipt, by the function (2026-09-14.1), and a receipt opens the receipt
/// review with its lines, as if Receipt had been chosen.
void buildStarterEditFlow(App app) {
  app.state('receiptFromCamera', bool_, persisted: false);
  app.raw((project) {
    updateCustomAction(project, name: 'ReadShelfPhoto', code: _readShelfPhoto);
    updateCustomWidget(project, name: 'ShelfReview', code: _shelfReview);
  });
}

const _readShelfPhoto = r'''
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Photographs one shelf, has the foods on it read and outlined, and adds them
/// to the photo map.
///
/// The Scan tab's camera takes whatever it is pointed at, so on the first photo
/// of a map the function is also asked whether the photo is a receipt. When it
/// is, its lines go straight into the receipt review (as the Receipt tile
/// would), `receiptFromCamera` is set, and the photo map opens that review.
///
/// Returns 'ok' when there is something to review, '' when the person backed
/// out of the camera (not an error, so nothing is said), and otherwise a
/// sentence saying why not.
///
/// The photo is kept until the map is saved or cleared, because the map is
/// drawn on it. A photo that gave nothing to review, or was a receipt, is
/// deleted straight away: a receipt carries the shop, the time and part of a
/// card number, and none of it is needed.
Future<String> readShelfPhoto() async {
  const sorry = 'Could not read that photo. Try again closer up.';
  final household = FFAppState().currentHouseholdId;
  if (household.isEmpty) {
    return 'No household yet. Create or join one before adding food.';
  }

  // Only the first photo of a map can turn out to be a receipt.
  final first = FFAppState().mapFoods.isEmpty;
  final shot = await ImagePicker().pickImage(
    source: ImageSource.camera,
    // A receipt is long and its print small, so a possible one gets more pixels.
    maxWidth: first ? 2000 : 1600,
    maxHeight: first ? 3200 : 1600,
    imageQuality: 85,
  );
  if (shot == null) return '';

  FFAppState().update(() => FFAppState().mapReading = true);
  final storage = SupaFlow.client.storage.from('food-images');
  final path = '$household/shelf-${const Uuid().v4()}.jpg';
  var uploaded = false;
  var keep = false;
  try {
    final Uint8List bytes = await shot.readAsBytes();
    await storage.uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: false),
    );
    uploaded = true;
    // An hour: long enough to go through the map. It is deleted on save.
    final url = await storage.createSignedUrl(path, 3600);

    final res = await SupaFlow.client.functions.invoke('recognise-food',
        body: {'imageUrl': url, 'mode': 'shelf', 'detectReceipt': first});
    final data = res.data;
    if (data is! Map) return sorry;
    if (data['error'] != null) return data['error'].toString();
    final raw = data['items'] is List ? data['items'] as List : const [];

    if (data['receipt'] == true) {
      final lines = await _receiptLines(raw, household);
      if (lines.isEmpty) {
        final note = (data['note'] ?? '').toString();
        return note.isNotEmpty
            ? note
            : 'Could not read that receipt. Try a flatter, brighter photo.';
      }
      FFAppState().update(() {
        FFAppState().scannedFoods = lines;
        FFAppState().scannedFrom = 'receipt';
        FFAppState().receiptFromCamera = true;
      });
      return 'ok';
    }

    final foods = <MapFoodStruct>[];
    for (final r in raw) {
      if (r is! Map) continue;
      final said = (r['name'] ?? '').toString().trim();
      if (said.isEmpty) continue;
      final counted = r['quantity'] is num ? (r['quantity'] as num).round() : 1;
      foods.add(MapFoodStruct(
        // Sentence case, as the rest of the app writes food names.
        name: said[0].toUpperCase() + said.substring(1),
        category: (r['category'] ?? '').toString(),
        quantity: counted < 1 ? 1 : counted,
        kind: (r['kind'] ?? '').toString(),
        box: (r['box'] ?? '').toString(),
        photo: url,
        decision: '',
        place: '',
      ));
    }
    if (foods.isEmpty) {
      final note = (data['note'] ?? '').toString();
      return note.isNotEmpty ? note : sorry;
    }

    keep = true;
    FFAppState().update(() {
      FFAppState().mapPhotos = [...FFAppState().mapPhotos, url];
      FFAppState().mapFoods = [...FFAppState().mapFoods, ...foods];
    });
    return 'ok';
  } on FunctionException catch (error) {
    final details = error.details;
    if (details is Map && details['error'] != null) {
      return details['error'].toString();
    }
    return sorry;
  } catch (_) {
    return sorry;
  } finally {
    FFAppState().update(() => FFAppState().mapReading = false);
    if (uploaded && !keep) {
      try {
        await storage.remove([path]);
      } catch (_) {}
    }
  }
}

/// Receipt lines as the receipt review shows them: the same words, the same
/// place for each kind of food, and the same detail line as the Receipt tile.
Future<List<ScannedFoodStruct>> _receiptLines(
    List raw, String household) async {
  const labels = <String, String>{
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
  const homes = <String, String>{
    'dairy': 'fridge',
    'meat_poultry': 'fridge',
    'seafood': 'fridge',
    'eggs': 'fridge',
    'cooked_leftovers': 'fridge',
    'fruit': 'fridge',
    'vegetables': 'fridge',
    'frozen': 'freezer',
    'bread_bakery': 'pantry',
    'pantry_dry': 'pantry',
    'condiments_sauces': 'pantry',
    'infant_food': 'pantry',
  };

  final rows = await SupaFlow.client
      .from('storage_locations')
      .select('id, name, location_type, is_default')
      .eq('household_id', household);
  final places = List<Map<String, dynamic>>.from(rows as List);
  Map<String, dynamic>? fallback;
  for (final p in places) {
    if (p['is_default'] == true) {
      fallback = p;
      break;
    }
  }
  fallback ??= places.isNotEmpty ? places.first : null;
  Map<String, dynamic>? placeFor(String category) {
    final type = homes[category];
    if (type != null) {
      for (final p in places) {
        if (p['location_type'] == type) return p;
      }
    }
    return fallback;
  }

  final lines = <ScannedFoodStruct>[];
  for (final r in raw) {
    if (r is! Map) continue;
    final said = (r['name'] ?? '').toString().trim();
    if (said.isEmpty) continue;
    final name = said[0].toUpperCase() + said.substring(1);
    final category = (r['category'] ?? '').toString();
    final counted = r['quantity'] is num ? (r['quantity'] as num).round() : 1;
    final quantity = counted < 1 ? 1 : counted;
    final place = placeFor(category);
    final detail = <String>[
      if (quantity > 1) '$quantity of them',
      labels[category] ?? 'No category',
      if (place != null) (place['name'] ?? '').toString(),
    ].where((s) => s.isNotEmpty).join(' · ');
    lines.add(ScannedFoodStruct(
      name: name,
      category: labels.containsKey(category) ? category : '',
      quantity: quantity,
      place: place == null ? '' : place['id'].toString(),
      detail: detail,
    ));
  }
  return lines;
}
''';

const _shelfReview = r'''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

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
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  int _selected = -1;
  int _editing = -1;

  // What the kitchen already holds, so the map can say so before the same
  // food is added twice. Lower case, and plurals dropped, because a photo
  // says "Eggs" where the kitchen says "Egg".
  Set<String> _have = {};
  String _haveFor = '';
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
  static String _iso(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
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
    var start =
        DateTime.tryParse(f.useBy) ?? today.add(const Duration(days: 3));
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

  static String _plain(String name) {
    final n = name.trim().toLowerCase();
    if (n.length > 4 && n.endsWith('es')) return n.substring(0, n.length - 2);
    if (n.length > 3 && n.endsWith('s')) return n.substring(0, n.length - 1);
    return n;
  }

  Future<void> _loadHave(String household) async {
    try {
      final rows = await SupaFlow.client
          .from('food_items_status')
          .select('name')
          .eq('household_id', household)
          .limit(200);
      if (!mounted || household != _haveFor) return;
      final names = <String>{};
      for (final r in rows as List) {
        final plain = _plain(((r as Map)['name'] ?? '').toString());
        if (plain.isNotEmpty) names.add(plain);
      }
      setState(() => _have = names);
    } catch (_) {
      // No signal: the map still works, it just cannot warn about duplicates.
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    // The Scan camera's first photo was a receipt: its lines are already in
    // the receipt review, so open that instead of an empty photo map.
    if (FFAppState().receiptFromCamera) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !FFAppState().receiptFromCamera) return;
        FFAppState().receiptFromCamera = false;
        GoRouter.of(context).pushReplacementNamed('ScanReviewPage');
      });
    }
    final t = FlutterFlowTheme.of(context);
    final household = FFAppState().currentHouseholdId;
    if (household.isNotEmpty && household != _haveFor) {
      _haveFor = household;
      _loadHave(household);
    }
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
                        // Said, not decided: photographing the same shelf
                        // every week should not quietly stack up five milks,
                        // and a second one is often exactly right.
                        if (_have.contains(_plain(f.name)))
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: t.accent1,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Already in your kitchen',
                                style: t.bodySmall.copyWith(
                                    color: t.primary,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
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
                  value: _categoryNames.containsKey(f.category)
                      ? f.category
                      : null,
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
                for (final e in widget.entries)
                  ..._outline(t, e.key, e.value, w, h),
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
