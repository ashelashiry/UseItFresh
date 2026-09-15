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

/// Adding a food you already have asks: add one more to it, keep separate
/// (the default when dates differ) or cancel. Joining a household while in
/// one asks first and says plainly that the app switches to the new
/// household and the current one stays.
void buildStarterEditFlow(App app) {
  app.raw((project) {
    updateCustomAction(project, name: 'CreateFoodItem', code: _aCreateFoodItem);
    updateCustomAction(project, name: 'JoinHousehold', code: _aJoinHousehold);
  });
}

const _aCreateFoodItem = r'''
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Adds a food item, and says why if it could not.
///
/// household_id is not null in the schema and has no default, so it has to be
/// supplied here; created_by records who added it. Both come from the session
/// rather than the form, so neither can be left out by a screen that forgets.
Future<String> createFoodItem(
  String? name,
  String? category,
  String? locationId,
  DateTime? printedDate,
  String? printedDateType,
  String? imageUrl,
  String? barcode,
) async {
  final trimmed = (name ?? '').trim();
  if (trimmed.isEmpty) return 'Give it a name first.';
  if ((locationId ?? '').isEmpty) return 'Choose where it is kept.';

  final household = FFAppState().currentHouseholdId;
  if (household.isEmpty) {
    return 'No household yet. Create or join one before adding food.';
  }

  // Already in the kitchen? Ask before adding a second one.
  final twin = await _sameFood(household, trimmed);
  if (twin != null) {
    final choice = await _askAboutTwin(twin, trimmed, printedDate);
    if (choice == null) return 'Nothing added.';
    if (choice == 'more') {
      try {
        final q = twin['quantity'];
        final now = q is num ? q.toDouble() : 1.0;
        await SupaFlow.client
            .from('food_items')
            .update({'quantity': now + 1}).eq('id', twin['id']);
        return '';
      } catch (_) {
        return 'Could not update it. Check your signal and try again.';
      }
    }
  }

  final code = (barcode ?? '').trim();
  var photo = (imageUrl ?? '').trim();
  if (photo.contains('openfoodfacts.org/')) {
    photo = await _keepOwnCopy(photo, household);
  }

  // How it was added, most specific first. A barcode is a stronger claim
  // about what the thing IS than a photograph, so it wins when both are
  // present — which is exactly what happens when a lookup supplies the
  // product picture too.
  final source =
      code.isNotEmpty ? 'barcode' : (photo.isNotEmpty ? 'photo' : 'manual');

  try {
    await SupaFlow.client.from('food_items').insert({
      'household_id': household,
      'storage_location_id': locationId,
      'created_by': SupaFlow.client.auth.currentUser?.id,
      'name': trimmed,
      if ((category ?? '').isNotEmpty) 'category': category,
      if (photo.isNotEmpty) 'image_url': photo,
      if (code.isNotEmpty) 'barcode': code,
      if (printedDate != null)
        'printed_date': printedDate.toIso8601String().substring(0, 10),
      // A date type without a date says nothing and reads as though a date
      // was recorded, so it is only stored alongside one.
      if (printedDate != null && (printedDateType ?? '').isNotEmpty)
        'printed_date_type': printedDateType,
      'source_type': source,
    });
    return '';
  } on PostgrestException catch (error) {
    if (error.code == '42501') {
      return 'Your account is not allowed to add to this household.';
    }
    return error.message;
  } catch (error) {
    return 'Could not add it. $error';
  }
}

/// Our own copy of an Open Food Facts photo, or their link if it cannot be
/// made. A picture that may one day go stale is better than none, so a failed
/// copy never stops the food being added.
Future<String> _keepOwnCopy(String url, String household) async {
  // The lookup returns the 200px thumbnail. The item screen shows the photo
  // large, so the 400px display size is fetched when it exists.
  final larger = url.replaceFirst(RegExp(r'\.200\.jpg$'), '.400.jpg');
  try {
    var res =
        await http.get(Uri.parse(larger)).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200 && larger != url) {
      res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
    }
    if (res.statusCode != 200 || res.bodyBytes.isEmpty) return url;

    final path = '$household/product-${const Uuid().v4()}.jpg';
    final storage = SupaFlow.client.storage.from('food-images');
    await storage.uploadBinary(
      path,
      res.bodyBytes,
      fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: false),
    );
    // A year, the same as a photo taken in the app.
    return await storage.createSignedUrl(path, 60 * 60 * 24 * 365);
  } catch (_) {
    return url;
  }
}

/// The same food already in this household's kitchen (not used up or thrown
/// out): the same name once case, spacing and a plural "s" are ignored.
Future<Map<String, dynamic>?> _sameFood(String household, String name) async {
  String key(String v) {
    final words = v
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w.length > 3 && w.endsWith('es')
            ? w.substring(0, w.length - 2)
            : (w.length > 2 && w.endsWith('s') ? w.substring(0, w.length - 1) : w));
    return words.join(' ');
  }

  final want = key(name);
  if (want.isEmpty) return null;
  try {
    final rows = await SupaFlow.client
        .from('food_items')
        .select('id, name, quantity, unit, printed_date, status, storage_locations(name)')
        .eq('household_id', household)
        .isFilter('archived_at', null)
        .order('created_at', ascending: false)
        .limit(400);
    for (final r in rows as List) {
      final row = Map<String, dynamic>.from(r as Map);
      final status = '${row['status'] ?? ''}';
      if (status == 'consumed' || status == 'discarded') continue;
      if (key('${row['name'] ?? ''}') == want) return row;
    }
  } catch (_) {
    // Offline or the check failed: never block adding food.
  }
  return null;
}

/// 'more' (one more on the food you have), 'separate', or null (cancel).
Future<String?> _askAboutTwin(
    Map<String, dynamic> twin, String name, DateTime? printedDate) async {
  final context = appNavigatorKey.currentContext;
  if (context == null) return 'separate';
  final t = FlutterFlowTheme.of(context);
  const forest = Color(0xFF07533A);
  final place = twin['storage_locations'] is Map
      ? '${(twin['storage_locations'] as Map)['name'] ?? ''}'
      : '';
  final q = twin['quantity'];
  final amount = quantityLabel(q is num ? q.toDouble() : null, '${twin['unit'] ?? ''}') ?? '';
  final date = DateTime.tryParse('${twin['printed_date'] ?? ''}');
  final details = [
    if (place.isNotEmpty) 'In the $place',
    if (amount.isNotEmpty) amount,
    if (date != null) 'dated ${DateFormat('d MMM').format(date)}',
  ].join(' · ');
  final datesDiffer = printedDate != null &&
      (date == null || DateUtils.dateOnly(date) != DateUtils.dateOnly(printedDate));

  Widget button(BuildContext sheet, String text, String? value,
      {bool primary = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        height: 52,
        child: primary
            ? FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: forest,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
                onPressed: () => Navigator.of(sheet).pop(value),
                child: Text(text,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              )
            : OutlinedButton(
                style: OutlinedButton.styleFrom(
                    foregroundColor: forest,
                    side: const BorderSide(color: Color(0xFFCCD7C2)),
                    backgroundColor: const Color(0xFFFFFEFA),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
                onPressed: () => Navigator.of(sheet).pop(value),
                child: Text(text,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
      ),
    );
  }

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFF7F7F0),
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (sheet) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.inventory_2_outlined, color: forest, size: 30),
            const SizedBox(height: 10),
            Text('You already have ${twin['name']}',
                style: t.headlineSmall.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF202C24))),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(details,
                  style: t.bodyMedium.copyWith(
                      color: const Color(0xFF59665D), fontSize: 15)),
            ],
            const SizedBox(height: 6),
            Text(
                datesDiffer
                    ? 'This one has a different date, so keeping it separate keeps both dates right.'
                    : 'Add it to the one you have, or keep it as its own item.',
                style: t.bodyMedium
                    .copyWith(color: const Color(0xFF59665D), fontSize: 14)),
            const SizedBox(height: 6),
            if (datesDiffer) ...[
              button(sheet, 'Keep separate', 'separate', primary: true),
              button(sheet, 'Add one more to the one I have', 'more'),
            ] else ...[
              button(sheet, 'Add one more to the one I have', 'more',
                  primary: true),
              button(sheet, 'Keep separate', 'separate'),
            ],
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: TextButton(
                onPressed: () => Navigator.of(sheet).pop(),
                style: TextButton.styleFrom(foregroundColor: forest),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
''';

const _aJoinHousehold = r'''
import 'package:supabase_flutter/supabase_flutter.dart';

/// Joins a household with its invite code, and makes it the household the
/// app shows.
///
/// The code is checked by the database (join_household_by_code, a security
/// definer function), because someone outside a household cannot read it.
/// Returns '' when joined, and otherwise a sentence saying why not.
///
/// Someone already in a household is told first, plainly, that joining
/// switches the app to the new household and that their current one stays
/// (hybrid brief, P1).
Future<String> joinHousehold(String? code) async {
  const noMatch = 'That code didn’t match a household. Check it and try again.';
  final typed = (code ?? '').replaceAll(RegExp(r'\s+'), '').toUpperCase();
  if (typed.isEmpty) return 'Type the invite code first.';
  final current = FFAppState().currentHouseholdId;
  if (current.isNotEmpty && !await _confirmSwitch(current)) {
    return 'Not joined. You’re still in your household.';
  }
  try {
    final joined = await SupaFlow.client
        .rpc('join_household_by_code', params: {'code': typed});
    final id = (joined ?? '').toString();
    if (id.isEmpty) return noMatch;
    FFAppState().update(() => FFAppState().currentHouseholdId = id);
    await _sayWhere(id, current);
    return '';
  } on PostgrestException catch (error) {
    final said = error.message.toLowerCase();
    if (said.contains('invalid invite code')) return noMatch;
    if (said.contains('not authenticated')) return 'Sign in first.';
    return error.message;
  } catch (_) {
    return 'Could not reach your kitchen. Check your signal and try again.';
  }
}

Future<String> _householdName(String id) async {
  try {
    final row = await SupaFlow.client
        .from('households')
        .select('name')
        .eq('id', id)
        .maybeSingle();
    return '${row?['name'] ?? ''}'.trim();
  } catch (_) {
    return '';
  }
}

Future<bool> _confirmSwitch(String current) async {
  final context = appNavigatorKey.currentContext;
  if (context == null) return true;
  final name = await _householdName(current);
  final here = name.isEmpty ? 'your household' : name;
  const forest = Color(0xFF07533A);
  final ok = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: const Color(0xFFF7F7F0),
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (sheet) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.swap_horiz_rounded, color: forest, size: 30),
            const SizedBox(height: 10),
            const Text('Join and switch households?',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF202C24))),
            const SizedBox(height: 6),
            Text(
                'The app will show the new household’s kitchen, shopping list and plans. You stay a member of $here and can switch back any time in Profile → Household.',
                style: const TextStyle(fontSize: 15, color: Color(0xFF59665D), height: 1.4)),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: forest,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
                onPressed: () => Navigator.of(sheet).pop(true),
                child: const Text('Join and switch',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.of(sheet).pop(false),
              style: TextButton.styleFrom(foregroundColor: forest),
              child: Text('Stay in $here'),
            ),
          ],
        ),
      ),
    ),
  );
  return ok == true;
}

/// After joining: a clear note of which household the app now shows.
Future<void> _sayWhere(String id, String previous) async {
  final context = appNavigatorKey.currentContext;
  if (context == null) return;
  final name = await _householdName(id);
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  // Shown after the page's own "You've joined" note.
  Future.delayed(const Duration(milliseconds: 4200), () {
    messenger.showSnackBar(SnackBar(
      duration: const Duration(seconds: 5),
      content: Text(name.isEmpty
          ? 'The app now shows your new household.'
          : 'The app now shows $name.${previous.isEmpty ? '' : ' Switch back in Profile → Household.'}'),
    ));
  });
}
''';

