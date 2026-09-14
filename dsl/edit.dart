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

/// Big thing 2, wired in: Home says how many foods need using and opens Use
/// soon; a tapped reminder opens Use soon from Home or Inventory; Home keeps
/// the daily notes in step with the kitchen each time it loads.
void buildStarterEditFlow(App app) {
  app.raw((project) {
    updateCustomWidget(project, name: 'HomeKitchen', code: _homeKitchen);
    updateCustomWidget(project, name: 'InventoryKitchen', code: _inventoryKitchen);
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
      if (!mounted || household != _for) return;
      setState(() {
        _items = List<Map<String, dynamic>>.from(rows as List);
        _kept = kept;
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
          const SizedBox(height: 20),
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
      label: '$n ${n == 1 ? 'food needs' : 'foods need'} using soon. Sort them.',
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
                    n == 1 ? '1 food needs using soon' : '$n foods need using soon',
                    style: t.bodyLarge.copyWith(
                        color: const Color(0xFF5C2A04), fontWeight: FontWeight.w800)),
              ),
              Text('Sort them',
                  style: t.bodyMedium.copyWith(
                      color: const Color(0xFFB54708), fontWeight: FontWeight.w800)),
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
    // A real idea only: the one just asked for, or one the household kept.
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

const _inventoryKitchen = r'''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Everything below "Your kitchen.": where the food is, and what to use first.
class InventoryKitchen extends StatefulWidget {
  const InventoryKitchen({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<InventoryKitchen> createState() => _InventoryKitchenState();
}

class _InventoryKitchenState extends State<InventoryKitchen> {
  static const _forest = Color(0xFF07533A);
  static const _ink = Color(0xFF202C24);
  static const _muted = Color(0xFF59665D);
  static const _sage = Color(0xFFEDF2E8);
  static const _border = Color(0xFFDCE3D7);

  static const _food =
      'https://cdn.jsdelivr.net/gh/ashelashiry/UseItFresh@b50424f12bd372d81c9cd44d895b62c25d1329e7/design/v3/food';

  static const _places = <String, String>{
    'all': 'All',
    'fridge': 'Fridge',
    'freezer': 'Freezer',
    'pantry': 'Pantry',
  };

  // Enough food that scanning the grid by eye gets slow.
  static const _searchFrom = 7;

  String _for = '';
  bool _loading = true;
  bool _failed = false;
  bool _busy = false;
  List<Map<String, dynamic>> _items = const [];
  String _place = 'all';
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // ---- data ----------------------------------------------------------------

  Future<void> _load(String household, {bool quiet = false}) async {
    if (mounted && !quiet) {
      setState(() {
        _loading = true;
        _failed = false;
      });
    }
    try {
      final rows = await SupaFlow.client
          .from('food_items_status')
          .select(
              'id, name, category, category_display_name, quantity, unit, image_url, location_type, computed_status, status_label, status_detail, days_left')
          .eq('household_id', household)
          .order('urgency_rank', ascending: true)
          .order('days_left', ascending: true);
      if (!mounted || household != _for) return;
      setState(() {
        _items = List<Map<String, dynamic>>.from(rows as List);
        _loading = false;
        _failed = false;
      });
    } catch (_) {
      if (!mounted || household != _for) return;
      // A quiet reload keeps what is on screen rather than blanking it.
      if (quiet && _items.isNotEmpty) return;
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

  Future<void> _open(Map<String, dynamic> item) async {
    await context.pushNamed('FoodItemPage',
        queryParameters: {'itemId': item['id'].toString()});
    if (mounted && _for.isNotEmpty) _load(_for, quiet: true);
  }

  Future<void> _photographShelf() async {
    await clearShelfScan();
    if (!mounted) return;
    await context.pushNamed('CameraPage', queryParameters: {'mode': 'shelf'});
    if (mounted && _for.isNotEmpty) _load(_for, quiet: true);
  }

  Future<void> _addByHand() async {
    await context.pushNamed('AddFoodItemPage');
    if (mounted && _for.isNotEmpty) _load(_for, quiet: true);
  }

  static String _place0(Map<String, dynamic> i) =>
      (i['location_type'] ?? '').toString().toLowerCase();

  static bool _soon(Map<String, dynamic> i) {
    switch ((i['computed_status'] ?? '').toString()) {
      case 'use_today':
      case 'use_soon':
      case 'past_use_by':
      case 'past_best_before':
        return true;
      default:
        return false;
    }
  }

  List<Map<String, dynamic>> get _inPlace => _place == 'all'
      ? _items
      : _items.where((i) => _place0(i) == _place).toList();

  List<Map<String, dynamic>> get _shown {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _inPlace;
    return _inPlace.where((i) {
      final name = (i['name'] ?? '').toString().toLowerCase();
      final cat = (i['category_display_name'] ?? '').toString().toLowerCase();
      return name.contains(q) || cat.contains(q);
    }).toList();
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

  static IconData _placeIcon(String place) {
    switch (place) {
      case 'fridge':
        return Icons.kitchen_outlined;
      case 'freezer':
        return Icons.ac_unit;
      case 'pantry':
        return Icons.inventory_2_outlined;
      default:
        return Icons.restaurant;
    }
  }

  // ---- page ----------------------------------------------------------------

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
    final t = FlutterFlowTheme.of(context);
    if (household.isEmpty) {
      // The page's on-load is still choosing the household.
      return SizedBox(width: widget.width, child: _skeleton());
    }
    if (household != _for) {
      _for = household;
      _place = 'all';
      _search.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) => _load(household));
    }

    Widget body;
    String key;
    if (_loading) {
      body = _skeleton();
      key = 'loading';
    } else if (_failed) {
      body = _offline(t);
      key = 'offline';
    } else if (_items.isEmpty) {
      body = _emptyKitchen(t);
      key = 'empty';
    } else {
      body = _kitchen(t);
      key = 'kitchen';
    }

    return SizedBox(
      width: widget.width,
      child: AnimatedSwitcher(
        duration: MediaQuery.of(context).disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 200),
        child: KeyedSubtree(key: ValueKey(key), child: body),
      ),
    );
  }

  Widget _kitchen(FlutterFlowTheme t) {
    final soon = _items.where(_soon).length;
    final count = _items.length == 1 ? '1 item' : '${_items.length} items';
    final shown = _shown;
    final searching = _search.text.trim().isNotEmpty;

    Widget results;
    if (shown.isNotEmpty) {
      results = _grid(t, shown);
    } else if (searching) {
      results = _noMatches(t);
    } else {
      results = _emptyPlace(t);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          soon == 0 ? count : '$count · $soon to use soon',
          style: t.bodyLarge.copyWith(color: _muted, fontSize: 16),
        ),
        const SizedBox(height: 16),
        _placeControl(t),
        if (_items.length >= _searchFrom || searching) ...[
          const SizedBox(height: 12),
          _searchField(t),
        ],
        const SizedBox(height: 16),
        results,
      ],
    );
  }

  // ---- controls ------------------------------------------------------------

  Widget _placeControl(FlutterFlowTheme t) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _sage,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (final e in _places.entries)
            Expanded(child: _segment(t, e.key, e.value)),
        ],
      ),
    );
  }

  Widget _segment(FlutterFlowTheme t, String place, String label) {
    final on = _place == place;
    final n = place == 'all'
        ? _items.length
        : _items.where((i) => _place0(i) == place).length;
    return Semantics(
      button: true,
      selected: on,
      label: '$label, $n',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _place = place),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: on
                ? const [
                    BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 6,
                        offset: Offset(0, 2))
                  ]
                : null,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: t.bodyMedium.copyWith(
                          fontSize: 15,
                          fontWeight: on ? FontWeight.w800 : FontWeight.w600,
                          color: on ? _forest : _ink)),
                  const SizedBox(width: 4),
                  Text('$n',
                      style: t.bodySmall.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _muted)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _searchField(FlutterFlowTheme t) {
    return TextField(
      controller: _search,
      onChanged: (_) => setState(() {}),
      textInputAction: TextInputAction.search,
      style: t.bodyLarge.copyWith(fontSize: 16, color: _ink),
      decoration: InputDecoration(
        hintText: 'Search your food',
        hintStyle: t.bodyLarge.copyWith(fontSize: 16, color: _muted),
        prefixIcon: const Icon(Icons.search, color: _muted),
        suffixIcon: _search.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.close, color: _muted),
                onPressed: () => setState(_search.clear),
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
    );
  }

  // ---- grid ----------------------------------------------------------------

  Widget _grid(FlutterFlowTheme t, List<Map<String, dynamic>> items) {
    return LayoutBuilder(builder: (context, box) {
      const gap = 12.0;
      final w = (box.maxWidth - gap) / 2;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [for (final i in items) _card(t, i, w)],
      );
    });
  }

  Widget _card(FlutterFlowTheme t, Map<String, dynamic> item, double width) {
    final name = (item['name'] ?? '').toString();
    final photo = _photoFor(item);
    final status = (item['computed_status'] ?? '').toString();
    final label = (item['status_label'] ?? '').toString();
    final qty =
        item['quantity'] is num ? (item['quantity'] as num).toDouble() : null;
    final amount = quantityLabel(qty, (item['unit'] ?? '').toString()) ?? '';
    final pill = _timePill(status, item['days_left']);
    Widget tile() => Container(
          color: _sage,
          alignment: Alignment.center,
          child: Icon(_placeIcon(_place0(item)), color: _forest, size: 34),
        );

    return _Pressable(
      label: [name, if (label.isNotEmpty) label].join(', '),
      onTap: () => _open(item),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1.25,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  photo == null
                      ? tile()
                      : Image.network(photo,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => tile()),
                  if (pill != null)
                    Positioned(
                      left: 8,
                      top: 8,
                      right: 8,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _pill(t, pill, size: 12),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
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
                    amount.isNotEmpty
                        ? amount
                        : (item['category_display_name'] ?? '').toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall.copyWith(color: _muted, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- states --------------------------------------------------------------

  Widget _skeleton() {
    return LayoutBuilder(builder: (context, box) {
      const gap = 12.0;
      final w = box.maxWidth.isFinite ? (box.maxWidth - gap) / 2 : 160.0;
      Widget block(double width, double h, double r) => Container(
            width: width,
            height: h,
            decoration: BoxDecoration(
                color: _sage, borderRadius: BorderRadius.circular(r)),
          );
      return Semantics(
        label: 'Loading your kitchen',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            block(140, 18, 8),
            const SizedBox(height: 16),
            block(double.infinity, 56, 16),
            const SizedBox(height: 16),
            Wrap(spacing: gap, runSpacing: gap, children: [
              for (var i = 0; i < 4; i++) block(w, w * 0.8 + 56, 20),
            ]),
          ],
        ),
      );
    });
  }

  Widget _message(
    FlutterFlowTheme t, {
    required IconData icon,
    required String title,
    required String body,
    required String action,
    required IconData actionIcon,
    required VoidCallback onAction,
    String? second,
    VoidCallback? onSecond,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: _sage, borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: _forest, size: 28),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: t.titleLarge.copyWith(
                  fontSize: 22, fontWeight: FontWeight.w800, color: _ink)),
          const SizedBox(height: 6),
          Text(body,
              style: t.bodyLarge
                  .copyWith(fontSize: 16, color: _muted, height: 1.4)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _forest,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _busy ? null : onAction,
              icon: Icon(actionIcon, size: 20),
              label: Text(action,
                  style: t.bodyLarge.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
          if (second != null && onSecond != null)
            Center(
              child: TextButton(
                style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48), foregroundColor: _forest),
                onPressed: _busy ? null : onSecond,
                child: Text(second,
                    style: t.bodyLarge
                        .copyWith(color: _forest, fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _offline(FlutterFlowTheme t) => _message(
        t,
        icon: Icons.cloud_off_outlined,
        title: 'Can’t reach your kitchen.',
        body:
            'No signal, or the connection dropped. Your food will show again as soon as you are back online.',
        action: 'Try again',
        actionIcon: Icons.refresh,
        onAction: () => _load(_for),
      );

  Widget _emptyKitchen(FlutterFlowTheme t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 200,
            child: Image.network('$_food/tomatoes.webp',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: _sage)),
          ),
        ),
        const SizedBox(height: 20),
        Text('Your fresh start.',
            style: t.titleLarge.copyWith(
                fontSize: 24, fontWeight: FontWeight.w800, color: _ink)),
        const SizedBox(height: 6),
        Text(
            'Add a few things you already have and this is where they will live.',
            style:
                t.bodyLarge.copyWith(fontSize: 16, color: _muted, height: 1.4)),
        const SizedBox(height: 16),
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: _forest,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _busy ? null : () => _run(_photographShelf),
            icon: const Icon(Icons.add, size: 20),
            label: Text('Add food',
                style: t.bodyLarge.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ),
        Center(
          child: TextButton(
            style: TextButton.styleFrom(
                minimumSize: const Size(48, 48), foregroundColor: _forest),
            onPressed: _busy ? null : () => _run(_addByHand),
            child: Text('Enter manually',
                style: t.bodyLarge
                    .copyWith(color: _forest, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _emptyPlace(FlutterFlowTheme t) {
    final name = (_places[_place] ?? '').toLowerCase();
    switch (_place) {
      case 'fridge':
        return _message(t,
            icon: _placeIcon(_place),
            title: 'Nothing in the fridge yet.',
            body: 'Photograph a shelf to add what is on it.',
            action: 'Photograph a shelf',
            actionIcon: Icons.photo_camera_outlined,
            onAction: () => _run(_photographShelf),
            second: 'Enter manually',
            onSecond: () => _run(_addByHand));
      default:
        return _message(t,
            icon: _placeIcon(_place),
            title: 'Nothing in the $name yet.',
            body: _place == 'freezer'
                ? 'Food you freeze shows here, with how long it keeps.'
                : 'Dry food, tins and jars show here.',
            action: 'Add food',
            actionIcon: Icons.add,
            onAction: () => _run(_addByHand),
            second: 'See everything',
            onSecond: () => setState(() => _place = 'all'));
    }
  }

  Widget _noMatches(FlutterFlowTheme t) {
    final q = _search.text.trim();
    final where =
        _place == 'all' ? '' : ' in the ${_places[_place]!.toLowerCase()}';
    return _message(t,
        icon: Icons.search_off,
        title: 'Nothing matches “$q”$where.',
        body: 'Check the spelling, or search everywhere.',
        action: 'Clear search',
        actionIcon: Icons.close,
        onAction: () => setState(_search.clear),
        second: _place == 'all' ? null : 'Search everywhere',
        onSecond:
            _place == 'all' ? null : () => setState(() => _place = 'all'));
  }
}

/// A card that answers a press straight away (skipped with reduced motion).
class _Pressable extends StatefulWidget {
  const _Pressable(
      {required this.label, required this.onTap, required this.child});

  final String label;
  final VoidCallback onTap;
  final Widget child;

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
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: (_down && !still) ? 0.97 : 1,
          duration: const Duration(milliseconds: 150),
          child: widget.child,
        ),
      ),
    );
  }
}
''';
