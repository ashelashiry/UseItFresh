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

/// Home ties the week together: the Tonight card shows what the household
/// planned for today (dinner first) and opens Plan my week; with nothing
/// planned it still offers an idea. Under "N foods need using soon", a link to
/// find a meal that uses them.
void buildStarterEditFlow(App app) {
  app.raw((project) {
    updateCustomWidget(project, name: 'HomeKitchen', code: _homeKitchen);
  });
}

const _homeKitchen = r'''
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

/// Home below the greeting, in the two states design guide v4 describes.
///
/// Reads the household's food itself (the page's own lists cannot be passed
/// to a custom widget) and stays silent when there is no household or no
/// signal: the page already has a card for each of those.
class HomeKitchen extends StatefulWidget {
  const HomeKitchen({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<HomeKitchen> createState() => _HomeKitchenState();
}

class _HomeKitchenState extends State<HomeKitchen> {
  static const _forest = Color(0xFF07533A);
  static const _ink = Color(0xFF202C24);
  static const _muted = Color(0xFF59665D);
  static const _sage = Color(0xFFEDF2E8);
  static const _border = Color(0xFFDCE3D7);

  static const _food =
      'https://cdn.jsdelivr.net/gh/ashelashiry/UseItFresh@b50424f12bd372d81c9cd44d895b62c25d1329e7/design/v3/food';

  // The supplied v3 line icons, drawn in forest.
  static const _camera =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#07533A" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h5l2-3h4l2 3h5v15H3zM16 13a4 4 0 1 1-8 0 4 4 0 0 1 8 0Z"/></svg>';
  static const _receipt =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#07533A" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M5 2v20l3-2 4 2 4-2 3 2V2l-3 2-4-2-4 2zM8 8h8m-8 4h8m-8 4h5"/></svg>';

  String _for = '';
  bool _loading = true;
  bool _failed = false;
  bool _busy = false;
  List<Map<String, dynamic>> _items = const [];
  Map<String, dynamic>? _kept;
  // Today's planned meal from Plan my week, dinner first.
  Map<String, dynamic>? _planned;

  Future<void> _load(String household) async {
    if (mounted) {
      setState(() {
        _loading = true;
        _failed = false;
      });
    }
    try {
      final rows = await SupaFlow.client
          .from('food_items_status')
          .select(
              'id, name, category, quantity, unit, image_url, computed_status, status_label, status_detail, days_left')
          .eq('household_id', household)
          .order('urgency_rank', ascending: true)
          .order('days_left', ascending: true)
          .limit(12);
      Map<String, dynamic>? kept;
      try {
        final ideas = await SupaFlow.client
            .from('saved_recipes')
            .select('title, recipe_data')
            .eq('household_id', household)
            .order('created_at', ascending: false)
            .limit(1);
        if ((ideas as List).isNotEmpty) {
          kept = Map<String, dynamic>.from(ideas.first as Map);
        }
      } catch (_) {
        // A kept idea is a nicety; the kitchen still shows without one.
      }
      Map<String, dynamic>? planned;
      try {
        final n = DateTime.now();
        final today =
            '${n.year.toString().padLeft(4, '0')}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
        final meals = await SupaFlow.client
            .from('meal_plan_entries')
            .select('id, meal, title, recipe_data, servings')
            .eq('household_id', household)
            .eq('plan_date', today)
            .eq('status', 'planned');
        const order = ['dinner', 'lunch', 'snack', 'breakfast'];
        final list = [
          for (final m in meals as List) Map<String, dynamic>.from(m as Map)
        ]..sort((a, b) =>
            order.indexOf('${a['meal']}').compareTo(order.indexOf('${b['meal']}')));
        if (list.isNotEmpty) planned = list.first;
      } catch (_) {
        // No plan, or planning not set up: Tonight falls back to an idea.
      }
      if (!mounted || household != _for) return;
      setState(() {
        _items = List<Map<String, dynamic>>.from(rows as List);
        _kept = kept;
        _planned = planned;
        _loading = false;
      });
      // Keep the daily reminder notes in step with the kitchen.
      scheduleExpiryReminders();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  Future<void> _run(Future<void> Function() go) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await go();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addFood() async {
    await clearShelfScan();
    if (!mounted) return;
    await context.pushNamed('CameraPage', queryParameters: {'mode': 'shelf'});
  }

  // The in-app camera, already set to Receipt: it reads the photo and opens
  // the receipt review itself, or explains why nothing was added.
  Future<void> _receiptTap() async {
    await context.pushNamed('CameraPage', queryParameters: {'mode': 'receipt'});
  }

  /// Why a receipt was not read, in the middle of the screen until dismissed.
  static Future<void> _explainReceipt(BuildContext host, String said) {
    return showDialog<void>(
      context: host,
      builder: (dialog) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Receipt not added'),
        content: Text(said),
        actions: [
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: () => Navigator.of(dialog).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// The food's own photo, or a photo of that very food; otherwise null, and
  /// the card draws a neutral tile. Never a different food for its category.
  static String? _photoFor(Map<String, dynamic> item) {
    final own = (item['image_url'] ?? '').toString().trim();
    if (own.isNotEmpty) return own;
    final n = (item['name'] ?? '').toString().toLowerCase();
    const exact = {
      'spinach': 'spinach',
      'mushroom': 'mushrooms',
      'tomato': 'tomatoes',
      'egg': 'eggs',
      'yogurt': 'yogurt',
      'yoghurt': 'yogurt',
      'pasta': 'pasta',
    };
    for (final e in exact.entries) {
      if (n.contains(e.key)) return '$_food/${e.value}.webp';
    }
    return null;
  }

  /// How long a food has, in words, on a colour that says how soon (owner,
  /// 14 Sep: "bold, on a coloured pill"). Red: past its use-by, use today, or
  /// two days or less. Orange: three to seven days, or past best-before. Green:
  /// more than a week. Blue: frozen, with no countdown — the clock does not
  /// run in the freezer, so there is nothing to count.
  static (String, Color, Color)? _timePill(String status, Object? daysLeft) {
    const red = (Color(0xFFB42318), Color(0xFFFDE3E0));
    const orange = (Color(0xFFB54708), Color(0xFFFFE9D1));
    const green = (Color(0xFF1E6B3A), Color(0xFFDDF0E2));
    const blue = (Color(0xFF285E8E), Color(0xFFE1ECF7));
    const grey = (Color(0xFF59665D), Color(0xFFEDF2E8));
    switch (status) {
      case 'frozen':
        return ('Frozen', blue.$1, blue.$2);
      case 'past_use_by':
        return ('Past use-by', red.$1, red.$2);
      case 'past_best_before':
        return ('Past best before', orange.$1, orange.$2);
      case 'use_today':
        return ('Use today', red.$1, red.$2);
      case 'unknown':
        return ('No date', grey.$1, grey.$2);
      case 'consumed':
      case 'discarded':
        return null;
    }
    final days = daysLeft is num ? daysLeft.round() : null;
    if (days == null) return null;
    final label = days <= 0
        ? 'Use today'
        : (days == 1 ? '1 day left' : '$days days left');
    final c = days <= 2 ? red : (days <= 7 ? orange : green);
    return (label, c.$1, c.$2);
  }

  static Widget _pill(FlutterFlowTheme t, (String, Color, Color) p,
          {double size = 13}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: p.$3, borderRadius: BorderRadius.circular(999)),
        child: Text(p.$1,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.bodySmall.copyWith(
                color: p.$2, fontWeight: FontWeight.w800, fontSize: size)),
      );

  static Color _statusColour(String status) {
    switch (status) {
      case 'past_use_by':
        return const Color(0xFFC44536);
      case 'use_today':
      case 'use_soon':
      case 'past_best_before':
        return const Color(0xFFB0621A);
      case 'frozen':
        return const Color(0xFF3B78B5);
      case 'fresh':
        return _forest;
      default:
        return _muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    // A reminder was tapped: open Use soon.
    if (FFAppState().openUseSoon) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !FFAppState().openUseSoon) return;
        FFAppState().openUseSoon = false;
        context.pushNamed('UseSoonPage');
      });
    }
    final household = FFAppState().currentHouseholdId;
    // No household: the page's own prompt says what to do.
    if (household.isEmpty) return const SizedBox.shrink();
    if (household != _for) {
      _for = household;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load(household));
    }
    // No signal: the page's own card says so, with Try again.
    if (_failed) return const SizedBox.shrink();

    final t = FlutterFlowTheme.of(context);
    final title = t.headlineLarge.copyWith(
        fontSize: 32, fontWeight: FontWeight.w800, color: _ink, height: 1.1);

    return SizedBox(
      width: widget.width,
      child: _loading
          ? _skeleton()
          : AnimatedSwitcher(
              duration: MediaQuery.of(context).disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
              child: _items.isEmpty ? _empty(t, title) : _populated(t, title),
            ),
    );
  }

  // ---- loading -------------------------------------------------------------

  Widget _skeleton() {
    Widget block(double h) => Container(
          height: h,
          decoration: BoxDecoration(
            color: _sage,
            borderRadius: BorderRadius.circular(20),
          ),
        );
    return Semantics(
      label: 'Loading your kitchen',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: 220, child: block(34)),
          const SizedBox(height: 16),
          block(240),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: block(112)),
            const SizedBox(width: 12),
            Expanded(child: block(112)),
          ]),
        ],
      ),
    );
  }

  // ---- empty kitchen -------------------------------------------------------

  Widget _empty(FlutterFlowTheme t, TextStyle title) {
    return Column(
      key: const ValueKey('empty'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Fresh starts here.', style: title),
        const SizedBox(height: 16),
        _hero(t),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _shortcut(
                  t,
                  'Scan a receipt',
                  SvgPicture.string(_receipt, width: 32, height: 32),
                  () => _run(_receiptTap)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _shortcut(
                  t,
                  'Take a photo',
                  SvgPicture.string(_camera, width: 32, height: 32),
                  () => _run(() async => context.pushNamed('AddFoodItemPage'))),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _kept != null ? _inspiration(t, _kept!) : _shelfPrompt(t),
      ],
    );
  }

  Widget _hero(FlutterFlowTheme t) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 240,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Illustrative: a photo to set the scene, not the person's food.
            Image.network(
              '$_food/tomatoes.webp',
              fit: BoxFit.cover,
              semanticLabel: '',
              errorBuilder: (_, __, ___) => Container(color: _sage),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xB3000000)],
                  stops: [0.35, 1],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Let’s stock your kitchen',
                    style: t.headlineSmall.copyWith(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.15),
                  ),
                  const SizedBox(height: 12),
                  _primaryButton(
                      t, 'Add food', Icons.add, () => _run(_addFood)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _primaryButton(FlutterFlowTheme t, String label, IconData icon,
          VoidCallback onTap) =>
      SizedBox(
        height: 48,
        child: FilledButton.icon(
          onPressed: _busy ? null : onTap,
          style: FilledButton.styleFrom(
            backgroundColor: _forest,
            foregroundColor: Colors.white,
            disabledBackgroundColor: _forest.withOpacity(0.6),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: Icon(icon, size: 20),
          label: Text(label,
              style: t.bodyLarge
                  .copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      );

  Widget _shortcut(
      FlutterFlowTheme t, String label, Widget icon, VoidCallback onTap) {
    return _Pressable(
      enabled: !_busy,
      label: label,
      onTap: onTap,
      child: Container(
        height: 112,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: _sage, borderRadius: BorderRadius.circular(16)),
              child: icon,
            ),
            const Spacer(),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.titleSmall.copyWith(
                    fontSize: 16, fontWeight: FontWeight.w700, color: _ink)),
          ],
        ),
      ),
    );
  }

  Widget _inspiration(FlutterFlowTheme t, Map<String, dynamic> kept) {
    final data =
        kept['recipe_data'] is Map ? kept['recipe_data'] as Map : const {};
    final minutes =
        data['minutes'] is num ? (data['minutes'] as num).round() : 0;
    return _Pressable(
      enabled: true,
      label: 'A little inspiration: ${kept['title']}',
      onTap: () => context.pushNamed('RecipesPage'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _sage,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('A little inspiration',
                style: t.bodySmall.copyWith(
                    color: _forest, fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 6),
            Text((kept['title'] ?? '').toString(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: t.titleLarge.copyWith(
                    fontSize: 22, fontWeight: FontWeight.w800, color: _ink)),
            if (minutes > 0) ...[
              const SizedBox(height: 4),
              Text('$minutes min · one of your kept ideas',
                  style: t.bodyMedium.copyWith(color: _muted, fontSize: 14)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _shelfPrompt(FlutterFlowTheme t) {
    return _Pressable(
      enabled: !_busy,
      label: 'Photograph a shelf',
      onTap: () => _run(_addFood),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _sage,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quickest start',
                      style: t.bodySmall.copyWith(
                          color: _forest,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  const SizedBox(height: 6),
                  Text('Photograph one shelf',
                      style: t.titleLarge.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _ink)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _forest, size: 28),
          ],
        ),
      ),
    );
  }

  // ---- food in the kitchen -------------------------------------------------

  Widget _populated(FlutterFlowTheme t, TextStyle title) {
    return Column(
      key: const ValueKey('populated'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Fresh today.', style: title),
        const SizedBox(height: 20),
        if (_soonCount > 0) ...[
          _soonBanner(t),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                  minimumSize: const Size(48, 44), foregroundColor: _forest),
              onPressed: () => context.pushNamed('RecipesPage'),
              icon: const Icon(Icons.restaurant_menu, size: 18),
              label: Text('Find a meal that uses them',
                  style: t.bodyMedium
                      .copyWith(color: _forest, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: Text('Use these next',
                  style: t.titleLarge.copyWith(
                      fontSize: 22, fontWeight: FontWeight.w800, color: _ink)),
            ),
            TextButton(
              onPressed: () => context.pushNamed('InventoryPage'),
              style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48), foregroundColor: _forest),
              child: Text('See all',
                  style: t.bodyLarge
                      .copyWith(color: _forest, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 226,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _foodCard(t, _items[i]),
          ),
        ),
        const SizedBox(height: 24),
        _tonight(t),
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _busy ? null : () => _run(_addFood),
            style: OutlinedButton.styleFrom(
              foregroundColor: _forest,
              side: const BorderSide(color: _border),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.add, size: 20),
            label: Text('Add food',
                style: t.bodyLarge
                    .copyWith(color: _forest, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  /// Foods close to their date — the same rule as Use soon: past it, today,
  /// "use soon", or three days or fewer, and never frozen food.
  int get _soonCount => _items.where((i) {
        final status = (i['computed_status'] ?? '').toString();
        if (status == 'frozen') return false;
        if (const {'past_use_by', 'use_today', 'use_soon', 'past_best_before'}
            .contains(status)) {
          return true;
        }
        final d = i['days_left'];
        return d is num && d <= 3;
      }).length;

  Widget _soonBanner(FlutterFlowTheme t) {
    final n = _soonCount;
    return Semantics(
      button: true,
      label:
          '$n ${n == 1 ? 'food needs' : 'foods need'} using soon. Sort them.',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          await context.pushNamed('UseSoonPage');
          if (mounted && _for.isNotEmpty) _load(_for);
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFE9D1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                    color: Color(0xFFB54708), shape: BoxShape.circle),
                child: Text('$n',
                    style: t.titleMedium.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                    n == 1
                        ? '1 food needs using soon'
                        : '$n foods need using soon',
                    style: t.bodyLarge.copyWith(
                        color: const Color(0xFF5C2A04),
                        fontWeight: FontWeight.w800)),
              ),
              Text('Sort them',
                  style: t.bodyMedium.copyWith(
                      color: const Color(0xFFB54708),
                      fontWeight: FontWeight.w800)),
              const Icon(Icons.chevron_right, color: Color(0xFFB54708)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _foodCard(FlutterFlowTheme t, Map<String, dynamic> item) {
    final name = (item['name'] ?? '').toString();
    final photo = _photoFor(item);
    final status = (item['computed_status'] ?? '').toString();
    final label = (item['status_label'] ?? '').toString();
    final qty =
        item['quantity'] is num ? (item['quantity'] as num).toDouble() : null;
    final amount = quantityLabel(qty, (item['unit'] ?? '').toString()) ?? '';
    final pill = _timePill(status, item['days_left']);

    return _Pressable(
      enabled: true,
      label: '$name, $label',
      onTap: () => context.pushNamed('FoodItemPage',
          queryParameters: {'itemId': item['id'].toString()}),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 128,
              child: photo == null
                  ? Container(
                      color: _sage,
                      alignment: Alignment.center,
                      child: const Icon(Icons.restaurant,
                          color: _forest, size: 36),
                    )
                  : Image.network(
                      photo,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: _sage,
                        alignment: Alignment.center,
                        child: const Icon(Icons.restaurant,
                            color: _forest, size: 36),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.titleSmall.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _ink)),
                  const SizedBox(height: 2),
                  Text(
                    amount.isNotEmpty ? amount : ' ',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall.copyWith(color: _muted, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  if (pill != null) _pill(t, pill, size: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tonight(FlutterFlowTheme t) {
    // What the household planned for today comes first (Plan my week).
    final plan = _planned;
    if (plan != null) {
      final data =
          plan['recipe_data'] is Map ? plan['recipe_data'] as Map : const {};
      final mins = data['minutes'] is num ? (data['minutes'] as num).round() : 0;
      final buy = data['extras'] is List ? (data['extras'] as List).length : 0;
      const meals = {
        'breakfast': 'Breakfast',
        'lunch': 'Lunch',
        'dinner': 'Dinner',
        'snack': 'Snack'
      };
      return _Pressable(
        enabled: true,
        label: 'Planned today: ${plan['title']}',
        onTap: () async {
          await context.pushNamed('PlanWeekPage');
          if (mounted && _for.isNotEmpty) _load(_for);
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _forest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Planned for today',
                  style: t.bodySmall.copyWith(
                      color: const Color(0xFFCFE3B8),
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
              const SizedBox(height: 6),
              Text('${plan['title']}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.titleLarge.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              const SizedBox(height: 4),
              Text(
                [
                  meals['${plan['meal']}'] ?? 'Dinner',
                  if (mins > 0) '$mins min',
                  if (plan['servings'] is num) 'Serves ${plan['servings']}',
                  buy == 0
                      ? 'Everything in your kitchen'
                      : (buy == 1 ? '1 thing to buy' : '$buy things to buy'),
                ].join(' · '),
                style: t.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.8), fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }
    // Otherwise a real idea only: the one just asked for, or one kept.
    String ideaTitle = '';
    int minutes = 0;
    String cue = '';
    final fresh = FFAppState().mealIdeas;
    if (fresh.isNotEmpty) {
      ideaTitle = fresh.first.title;
      minutes = fresh.first.minutes;
      if (fresh.first.uses.isNotEmpty)
        cue = 'Uses your ${fresh.first.uses.first.toLowerCase()}';
    } else if (_kept != null) {
      ideaTitle = (_kept!['title'] ?? '').toString();
      final data = _kept!['recipe_data'] is Map
          ? _kept!['recipe_data'] as Map
          : const {};
      minutes = data['minutes'] is num ? (data['minutes'] as num).round() : 0;
      cue = 'One of your kept ideas';
    }

    return _Pressable(
      enabled: true,
      label: ideaTitle.isEmpty
          ? 'Find a meal from your food'
          : 'Tonight: $ideaTitle',
      onTap: () => context.pushNamed('RecipesPage'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _forest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tonight, sorted.',
                style: t.bodySmall.copyWith(
                    color: const Color(0xFFCFE3B8),
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
            const SizedBox(height: 6),
            Text(ideaTitle.isEmpty ? 'Find a meal from your food' : ideaTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: t.titleLarge.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
            if (ideaTitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                [if (minutes > 0) '$minutes min', if (cue.isNotEmpty) cue]
                    .join(' · '),
                style: t.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.8), fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A whole-card tap target with an immediate pressed response (skipped when
/// reduced motion is on).
class _Pressable extends StatefulWidget {
  const _Pressable({
    required this.child,
    required this.onTap,
    required this.label,
    required this.enabled,
  });

  final Widget child;
  final VoidCallback onTap;
  final String label;
  final bool enabled;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.of(context).disableAnimations;
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedScale(
          scale: (_down && !still) ? 0.98 : 1,
          duration: const Duration(milliseconds: 150),
          child: widget.child,
        ),
      ),
    );
  }
}
''';
