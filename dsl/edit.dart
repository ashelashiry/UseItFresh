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

/// Design guide v4, section 1: Home.
///
/// The nearly blank screen becomes a kitchen to explore, in two states, both
/// drawn from real data only:
///
///   Empty kitchen    "Fresh starts here." over a large photo hero with "Add
///                    food"; two shortcuts, "Scan a receipt" and "Take a
///                    photo"; then a kept idea as "A little inspiration" when
///                    the household has one, or a prompt to photograph a
///                    shelf when it has none. No counts, warnings or savings.
///   Food in it       "Use these next": photo cards of the actual foods,
///                    soonest first, each with its quantity and its worded
///                    status; then "Tonight, sorted." with a real idea and its
///                    real time when there is one, or a way to find one.
///
/// Truthfulness rules from the guide, kept in code:
///   * a card shows the food's own photo, or a photo of that very food (by
///     name), or a neutral tile — never a different food standing in for its
///     category (the old cards showed yoghurt for cheese);
///   * the illustrative hero photo is never presented as the person's food;
///   * no prep time or recipe is shown unless an idea really exists.
///
/// The greeting stays FlutterFlow's own; the title moves into the widget
/// because it changes with the state. Offline and no-household keep their
/// existing cards on the page — the widget stays silent in both, rather than
/// saying the same thing twice. Old pieces are removed bottom-up: several
/// removals in one push otherwise skip every second widget (HANDOVER §5).
void buildStarterEditFlow(App app) {
  app.customWidget(
    'HomeKitchen',
    parameters: {},
    description:
        'Home below the greeting: an empty-kitchen hero with shortcuts, or the '
        'foods to use next and tonight\'s meal — all from real data.',
    code: _homeKitchen,
  );

  final home = ff.Pages.homePage;
  app.editPage(home, (page) {
    for (final key in [
      'Button_gpb5q4p0', // "Add food" at the bottom (children[5])
      'GridView_pmh36not', // the use-first grid (children[4])
      'Container_m5nwt3o5', // the "Use these next" hero (children[3])
      'Text_oafkeib3', // "Fresh today." in the greeting block
    ]) {
      page.ensureRemoved(home.widgets.byKey(key).single);
    }
    page.ensureInsertedAfter(
      home.widgets.byKey('Container_y8xn4win').single, // household prompt
      CustomWidget(widgetName: 'HomeKitchen', name: 'HomeKitchenBody', arguments: {}),
    );
  });
}

const _homeKitchen = r'''
import 'package:flutter/material.dart';
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
              'id, name, category, quantity, unit, image_url, computed_status, status_label, status_detail')
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
    context.pushNamed('MapReviewPage');
  }

  Future<void> _receiptTap() async {
    final said = await readPhotoFoods('receipt');
    if (!mounted) return;
    if (said == 'ok') {
      context.pushNamed('ScanReviewPage');
    } else if (said.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(said)));
    }
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
              child: _items.isEmpty
                  ? _empty(t, title)
                  : _populated(t, title),
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
              child: _shortcut(t, 'Scan a receipt', SvgPicture.string(_receipt, width: 32, height: 32),
                  () => _run(_receiptTap)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _shortcut(t, 'Take a photo', SvgPicture.string(_camera, width: 32, height: 32),
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
                  _primaryButton(t, 'Add food', Icons.add, () => _run(_addFood)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _primaryButton(
          FlutterFlowTheme t, String label, IconData icon, VoidCallback onTap) =>
      SizedBox(
        height: 48,
        child: FilledButton.icon(
          onPressed: _busy ? null : onTap,
          style: FilledButton.styleFrom(
            backgroundColor: _forest,
            foregroundColor: Colors.white,
            disabledBackgroundColor: _forest.withOpacity(0.6),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: Icon(icon, size: 20),
          label: Text(label,
              style: t.bodyLarge.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w700)),
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
    final data = kept['recipe_data'] is Map ? kept['recipe_data'] as Map : const {};
    final minutes = data['minutes'] is num ? (data['minutes'] as num).round() : 0;
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
                          color: _forest, fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 6),
                  Text('Photograph one shelf',
                      style: t.titleLarge.copyWith(
                          fontSize: 22, fontWeight: FontWeight.w800, color: _ink)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

  Widget _foodCard(FlutterFlowTheme t, Map<String, dynamic> item) {
    final name = (item['name'] ?? '').toString();
    final photo = _photoFor(item);
    final status = (item['computed_status'] ?? '').toString();
    final label = (item['status_label'] ?? '').toString();
    final detail = (item['status_detail'] ?? '').toString();
    final qty = item['quantity'] is num ? (item['quantity'] as num).toDouble() : null;
    final amount = quantityLabel(qty, (item['unit'] ?? '').toString()) ?? '';
    final colour = _statusColour(status);

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
                      child: const Icon(Icons.restaurant, color: _forest, size: 36),
                    )
                  : Image.network(
                      photo,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: _sage,
                        alignment: Alignment.center,
                        child: const Icon(Icons.restaurant, color: _forest, size: 36),
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
                          fontSize: 16, fontWeight: FontWeight.w700, color: _ink)),
                  const SizedBox(height: 2),
                  Text(
                    [if (amount.isNotEmpty) amount, if (detail.isNotEmpty) detail]
                        .join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall.copyWith(color: _muted, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  if (label.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colour.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodySmall.copyWith(
                              color: colour, fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
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
      if (fresh.first.uses.isNotEmpty) cue = 'Uses your ${fresh.first.uses.first.toLowerCase()}';
    } else if (_kept != null) {
      ideaTitle = (_kept!['title'] ?? '').toString();
      final data = _kept!['recipe_data'] is Map ? _kept!['recipe_data'] as Map : const {};
      minutes = data['minutes'] is num ? (data['minutes'] as num).round() : 0;
      cue = 'One of your kept ideas';
    }

    return _Pressable(
      enabled: true,
      label: ideaTitle.isEmpty ? 'Find a meal from your food' : 'Tonight: $ideaTitle',
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
                    fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
            if (ideaTitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                [if (minutes > 0) '$minutes min', if (cue.isNotEmpty) cue].join(' · '),
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
