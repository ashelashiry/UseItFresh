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

/// Food pictures (owner, 15 Sep): "fresh photos first" by default — a fresh,
/// appetising photo of the food when one matches it and its form, otherwise
/// the person's own photo or scan — with "my photos first" in Profile → Food
/// pictures. A food's screen can switch to the other picture when both exist.
void buildStarterEditFlow(App app) {
  app.state('photoPreference', string.withDefault('stock'), persisted: true);
  app.raw((project) {
    updateCustomWidget(project, name: 'HomeKitchen', code: _wHomeKitchen);
    updateCustomWidget(project, name: 'InventoryKitchen', code: _wInventoryKitchen);
    updateCustomWidget(project, name: 'FoodDetail', code: _wFoodDetail);
    updateCustomWidget(project, name: 'UseSoonList', code: _wUseSoonList);
    updateCustomWidget(project, name: 'ProfileMenu', code: _wProfileMenu);
  });
}

const _wHomeKitchen = r'''
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Home, in the hybrid design (brief, 15 Sep).
///
/// "Good food. Great possibilities." Then one photographic meal — what the
/// household planned for today, or an idea from its own food — with one
/// clear action; a small, calm note when foods need using soon; the next foods
/// to use as a two-column grid with honest date badges; and Shopping list and
/// Add food within reach.
///
/// Reads the household's food itself and stays silent when there is no
/// household or no signal: the page already has a card for each of those.
class HomeKitchen extends StatefulWidget {
  const HomeKitchen({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<HomeKitchen> createState() => _HomeKitchenState();
}

class _HomeKitchenState extends State<HomeKitchen> {
  String _for = '';
  bool _loading = true;
  bool _failed = false;
  bool _busy = false;
  List<Map<String, dynamic>> _items = const [];
  int _soon = 0;
  Map<String, dynamic>? _kept;
  Map<String, dynamic>? _planned;
  bool _saved = false;

  Future<void> _load(String household) async {
    if (mounted) {
      setState(() {
        _loading = true;
        _failed = false;
      });
    }
    try {
      final client = SupaFlow.client;
      final rows = await client
          .from('food_items_status')
          .select(
              'id, name, quantity, unit, image_url, computed_status, days_left, printed_date, printed_date_type, status_basis, urgency_rank')
          .eq('household_id', household)
          .order('urgency_rank', ascending: true)
          .order('days_left', ascending: true)
          .limit(300);
      final all = [
        for (final r in rows as List)
          if (!const ['consumed', 'discarded']
              .contains('${(r as Map)['computed_status']}'))
            Map<String, dynamic>.from(r)
      ];
      Map<String, dynamic>? kept;
      try {
        final ideas = await client
            .from('saved_recipes')
            .select('title, recipe_data')
            .eq('household_id', household)
            .order('created_at', ascending: false)
            .limit(1);
        if ((ideas as List).isNotEmpty) {
          kept = Map<String, dynamic>.from(ideas.first as Map);
        }
      } catch (_) {}
      Map<String, dynamic>? planned;
      try {
        final n = DateTime.now();
        final today =
            '${n.year.toString().padLeft(4, '0')}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
        final meals = await client
            .from('meal_plan_entries')
            .select('id, meal, title, recipe_data, servings')
            .eq('household_id', household)
            .eq('plan_date', today)
            .eq('status', 'planned');
        const order = ['dinner', 'lunch', 'snack', 'breakfast'];
        final list = [
          for (final m in meals as List) Map<String, dynamic>.from(m as Map)
        ]..sort((a, b) => order
            .indexOf('${a['meal']}')
            .compareTo(order.indexOf('${b['meal']}')));
        if (list.isNotEmpty) planned = list.first;
      } catch (_) {}
      if (!mounted || household != _for) return;
      setState(() {
        _items = all;
        _soon = all.where(_uSoon).length;
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
    if (mounted && _for.isNotEmpty) _load(_for);
  }

  Future<void> _open(String route, {Map<String, String>? query}) async {
    await context.pushNamed(route, queryParameters: query ?? const {});
    if (mounted && _for.isNotEmpty) _load(_for);
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
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: _uForest,
        height: 1.08,
        letterSpacing: -0.8);

    return SizedBox(
      width: widget.width,
      child: _loading
          ? _skeleton()
          : AnimatedSwitcher(
              duration: _uStill(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
              child: _items.isEmpty ? _empty(t, title) : _populated(t, title),
            ),
    );
  }

  Widget _skeleton() {
    Widget block(double h) => Container(
          height: h,
          decoration: BoxDecoration(
            color: const Color(0xAAE6EDDF),
            borderRadius: BorderRadius.circular(22),
          ),
        );
    return Semantics(
      label: 'Loading your kitchen',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: 260, child: block(70)),
          const SizedBox(height: 20),
          block(360),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: block(200)),
            const SizedBox(width: 12),
            Expanded(child: block(200)),
          ]),
        ],
      ),
    );
  }

  // ---- empty kitchen -------------------------------------------------------

  Widget _empty(FlutterFlowTheme t, TextStyle title) {
    const base =
        'https://cdn.jsdelivr.net/gh/ashelashiry/UseItFresh@b50424f12bd372d81c9cd44d895b62c25d1329e7/design/v3/food';
    return Column(
      key: const ValueKey('empty'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Fresh starts here.', style: title),
        const SizedBox(height: 20),
        _USurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 190,
                child: Image.network('$base/tomatoes.webp',
                    fit: BoxFit.cover,
                    semanticLabel: '',
                    errorBuilder: (_, __, ___) =>
                        Container(color: const Color(0xFFE4E9D9))),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Let’s stock your kitchen',
                        style: t.headlineSmall.copyWith(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            color: _uInk,
                            height: 1.15)),
                    const SizedBox(height: 6),
                    Text('Photograph a shelf, scan a receipt, or type it in.',
                        style: t.bodyMedium
                            .copyWith(color: _uMuted, fontSize: 14)),
                    const SizedBox(height: 14),
                    _UButton('Add food',
                        icon: Icons.add,
                        busy: _busy,
                        onTap: () => _run(_addFood)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _UButton('Scan a receipt',
                  kind: 'secondary',
                  icon: Icons.receipt_long_outlined,
                  onTap: _busy
                      ? null
                      : () => _open('CameraPage', query: {'mode': 'receipt'})),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _UButton('Shopping list',
                  kind: 'secondary',
                  icon: Icons.shopping_cart_outlined,
                  onTap: () => _open('ShoppingListPage')),
            ),
          ],
        ),
      ],
    );
  }

  // ---- food in the kitchen -------------------------------------------------

  Widget _populated(FlutterFlowTheme t, TextStyle title) {
    final next = _items.take(4).toList();
    return Column(
      key: const ValueKey('populated'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Good food.\nGreat possibilities.', style: title),
        const SizedBox(height: 20),
        _meal(t),
        if (_soon > 0) ...[
          const SizedBox(height: 14),
          _soonNote(t),
        ],
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text('Use these next',
                    style: t.titleLarge.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _uInk)),
              ),
            ),
            TextButton(
              onPressed: () => _open('InventoryPage'),
              style: TextButton.styleFrom(
                  minimumSize: const Size(48, 44), foregroundColor: _uForest),
              child: Text('View all ${_items.length}',
                  style: t.bodyMedium
                      .copyWith(color: _uForest, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (context, box) {
          final w = (box.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final item in next)
                SizedBox(
                  width: w,
                  child: _uFoodCard(context, item,
                      onTap: () => _open('FoodItemPage',
                          query: {'itemId': '${item['id']}'})),
                ),
            ],
          );
        }),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _UButton('Shopping list',
                  kind: 'secondary',
                  icon: Icons.shopping_cart_outlined,
                  onTap: () => _open('ShoppingListPage')),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _UButton('Add food',
                  kind: 'secondary',
                  icon: Icons.add,
                  onTap: _busy ? null : () => _run(_addFood)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _soonNote(FlutterFlowTheme t) {
    final n = _soon;
    return _USurface(
      radius: 18,
      onTap: () => _open('UseSoonPage'),
      label:
          '$n ${n == 1 ? 'food needs' : 'foods need'} using soon. View foods.',
      tint: const [Color(0xFFFFF6EA), Color(0xFFFBEBD8)],
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Row(
        children: [
          const Icon(Icons.schedule, color: Color(0xFF884311), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
                n == 1 ? '1 food needs using soon' : '$n foods need using soon',
                style: t.bodyMedium.copyWith(
                    color: const Color(0xFF5C2A04),
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ),
          Text('View foods',
              style: t.bodyMedium
                  .copyWith(color: _uForest, fontWeight: FontWeight.w700)),
          const Icon(Icons.chevron_right, color: _uForest, size: 20),
        ],
      ),
    );
  }

  /// The one meal Home leads with: today's plan, a fresh idea, or a kept one.
  Widget _meal(FlutterFlowTheme t) {
    String label;
    String name = '';
    String meta = '';
    List<String> uses = const [];
    String action;
    VoidCallback go;
    Map? keep;
    final plan = _planned;
    if (plan != null) {
      final d =
          plan['recipe_data'] is Map ? plan['recipe_data'] as Map : const {};
      final mins = d['minutes'] is num ? (d['minutes'] as num).round() : 0;
      final buy = d['extras'] is List ? (d['extras'] as List).length : 0;
      uses = d['uses'] is List
          ? [for (final u in d['uses'] as List) '$u']
          : const [];
      label = 'PLANNED FOR TODAY';
      name = '${plan['title']}';
      meta = [
        if (mins > 0) '$mins min',
        buy == 0
            ? 'Everything in your kitchen'
            : (buy == 1 ? '1 thing to buy' : '$buy things to buy'),
      ].join(' · ');
      action = 'Let’s cook';
      go = () => _open('PlanWeekPage');
    } else if (FFAppState().mealIdeas.isNotEmpty) {
      final idea = FFAppState().mealIdeas.first;
      label = 'TONIGHT, SORTED';
      name = idea.title;
      uses = idea.uses;
      meta = [
        if (idea.minutes > 0) '${idea.minutes} min',
        if (idea.uses.isNotEmpty)
          idea.uses.length == 1
              ? 'Uses 1 food in your kitchen'
              : 'Uses ${idea.uses.length} foods in your kitchen',
      ].join(' · ');
      action = 'Let’s cook';
      go = () => _open('RecipesPage');
      keep = {
        'title': idea.title,
        'recipe_data': {
          'uses': idea.uses,
          'extras': idea.extras,
          'steps': idea.steps,
          'minutes': idea.minutes,
          'servings': idea.servings,
          if (idea.calories > 0) 'calories': idea.calories,
          if (idea.protein > 0) 'protein': idea.protein,
        },
      };
    } else if (_kept != null) {
      final d = _kept!['recipe_data'] is Map
          ? _kept!['recipe_data'] as Map
          : const {};
      final mins = d['minutes'] is num ? (d['minutes'] as num).round() : 0;
      uses = d['uses'] is List
          ? [for (final u in d['uses'] as List) '$u']
          : const [];
      label = 'ONE OF YOUR RECIPES';
      name = '${_kept!['title']}';
      meta = [if (mins > 0) '$mins min', 'Kept by your household'].join(' · ');
      action = 'Let’s cook';
      go = () => _open('RecipeCollectionPage');
    } else {
      label = 'TONIGHT';
      name = 'What can you make tonight?';
      meta = 'Ideas from the food you already have';
      action = 'Find meals';
      go = () => _open('RecipesPage');
    }

    // An illustrative photo of a real ingredient of this meal, when one fits.
    var photo = '';
    for (final u in uses) {
      photo = foodPhoto(u, '') ?? '';
      if (photo.isNotEmpty) break;
    }
    final lower = name.toLowerCase();
    if (photo.isEmpty &&
        (lower.contains('pasta') ||
            lower.contains('spaghetti') ||
            lower.contains('linguine'))) {
      photo =
          'https://cdn.jsdelivr.net/gh/ashelashiry/UseItFresh@b50424f12bd372d81c9cd44d895b62c25d1329e7/design/v3/food/pasta.webp';
    }

    Widget chip(String text) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
              color: const Color(0xF0FFFFFF),
              borderRadius: BorderRadius.circular(10)),
          child: Text(text,
              style: t.bodySmall.copyWith(
                  color: _uForest,
                  fontSize: 11,
                  letterSpacing: 0.9,
                  fontWeight: FontWeight.w800)),
        );

    return _USurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: photo.isEmpty ? 64 : 200,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (photo.isEmpty)
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFE4E9D9), Color(0xFFD9E6D1)],
                      ),
                    ),
                  )
                else
                  Image.network(photo,
                      fit: BoxFit.cover,
                      cacheWidth: 900,
                      semanticLabel: '',
                      errorBuilder: (_, __, ___) =>
                          Container(color: const Color(0xFFE4E9D9))),
                Positioned(left: 14, top: 14, child: chip(label)),
                if (keep != null)
                  Positioned(
                    right: 14,
                    top: 10,
                    child: _UPress(
                      label: _saved ? 'Saved' : 'Save this idea',
                      onTap: () async {
                        if (_saved) return;
                        try {
                          await SupaFlow.client.from('saved_recipes').insert({
                            ...keep!,
                            'household_id': _for,
                            'profile_id': SupaFlow.client.auth.currentUser?.id,
                          });
                          if (mounted) setState(() => _saved = true);
                        } catch (_) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Could not save it. Check your signal.')));
                          }
                        }
                      },
                      child: Container(
                        constraints:
                            const BoxConstraints(minHeight: 44, minWidth: 56),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFDF5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(_saved ? 'Saved' : 'Save',
                            style: t.bodySmall.copyWith(
                                color: _uForest,
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(name,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: t.headlineSmall.copyWith(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        color: _uInk,
                        height: 1.15)),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(meta,
                      style:
                          t.bodyMedium.copyWith(color: _uMuted, fontSize: 14)),
                ],
                const SizedBox(height: 14),
                _UButton(action,
                    icon: Icons.arrow_forward, trailing: true, onTap: go),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Hybrid material (design brief, 15 Sep) --------------------------------
// Cream canvas over a blurred food background (set on the page), sculpted
// cream surfaces, forest gradient primary buttons, calm date badges.

const _uForest = Color(0xFF07533A);
const _uForestTop = Color(0xFF176C50);
const _uInk = Color(0xFF202C24);
const _uMuted = Color(0xFF59665D);
const _uSage = Color(0xFFE6EDDF);
const _uLine = Color(0xFFCDD4C3);
const _uCream = Color(0xFFF7F7F0);

bool _uStill(BuildContext c) => MediaQuery.of(c).disableAnimations;

/// A sculpted cream surface: warm diagonal gradient, thin sage border, a
/// narrow white top highlight, a 2px lower edge and a soft shadow.
class _USurface extends StatelessWidget {
  const _USurface({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = 22,
    this.onTap,
    this.label,
    this.tint,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final String? label;
  final List<Color>? tint;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    final body = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: tint ?? const [Color(0xFFFFFEF9), Color(0xFFF3F3E9)],
        ),
        borderRadius: r,
        border: Border.all(color: _uLine),
        boxShadow: const [
          BoxShadow(color: Color(0xFFD2D8C9), offset: Offset(0, 2)),
          BoxShadow(
              color: Color(0x14263824), offset: Offset(0, 8), blurRadius: 16),
        ],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: Stack(
          children: [
            Padding(padding: padding, child: child),
            // The narrow white highlight along the top edge.
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 1.5,
              child: ColoredBox(color: Color(0xCCFFFFFF)),
            ),
          ],
        ),
      ),
    );
    if (onTap == null) return body;
    return _UPress(onTap: onTap!, label: label, radius: radius, child: body);
  }
}

/// A tap target that sinks 1px while pressed (tonal only with reduced motion).
class _UPress extends StatefulWidget {
  const _UPress({
    required this.child,
    required this.onTap,
    this.label,
    this.radius = 16,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback onTap;
  final String? label;
  final double radius;
  final bool enabled;

  @override
  State<_UPress> createState() => _UPressState();
}

class _UPressState extends State<_UPress> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final still = _uStill(context);
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown:
            widget.enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: widget.enabled ? (_down && still ? 0.85 : 1) : 0.55,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 100),
            offset: _down && !still ? const Offset(0, 0.01) : Offset.zero,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Buttons: one forest primary per task, cream secondaries, quiet text links.
class _UButton extends StatelessWidget {
  const _UButton(
    this.text, {
    required this.onTap,
    this.icon,
    this.kind = 'primary',
    this.busy = false,
    this.trailing = false,
  });

  final String text;
  final VoidCallback? onTap;
  final IconData? icon;
  final String kind; // primary | secondary | danger
  final bool busy;
  final bool trailing;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final primary = kind == 'primary';
    final danger = kind == 'danger';
    final fg = primary
        ? Colors.white
        : (danger ? const Color(0xFFB42318) : _uForest);
    final iconW = icon == null ? null : Icon(icon, size: 20, color: fg);
    final label = Text(text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: t.bodyLarge.copyWith(
            color: fg,
            fontSize: primary ? 16 : 15,
            fontWeight: primary ? FontWeight.w700 : FontWeight.w600));
    final content = busy
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: fg))
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (iconW != null && !trailing) ...[iconW, const SizedBox(width: 8)],
              Flexible(child: label),
              if (iconW != null && trailing) ...[const SizedBox(width: 8), iconW],
            ],
          );
    final box = Container(
      constraints: BoxConstraints(minHeight: primary ? 52 : 48),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: primary
              ? const [_uForestTop, _uForest]
              : const [Color(0xFFFFFEFA), Color(0xFFEDF0E4)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: primary
                ? const Color(0xFF06422E)
                : (danger ? const Color(0xFFEBC5BF) : const Color(0xFFCCD7C2))),
        boxShadow: primary
            ? const [
                BoxShadow(color: Color(0xFF033C29), offset: Offset(0, 3)),
                BoxShadow(
                    color: Color(0x2007533A),
                    offset: Offset(0, 6),
                    blurRadius: 10),
              ]
            : const [BoxShadow(color: Color(0xFFD6DFCC), offset: Offset(0, 2))],
      ),
      child: content,
    );
    return _UPress(
      onTap: onTap ?? () {},
      enabled: onTap != null && !busy,
      label: text,
      child: box,
    );
  }
}

/// The date badge from dateBadge(): "Label|tone".
Widget _uBadge(BuildContext context, String spec, {double size = 12}) {
  if (spec.isEmpty) return const SizedBox.shrink();
  final parts = spec.split('|');
  final tone = parts.length > 1 ? parts[1] : 'calm';
  const tones = <String, (Color, Color)>{
    'urgent': (Color(0xFFFDE3E0), Color(0xFFB42318)),
    'warm': (Color(0xFFFFEAD4), Color(0xFF884311)),
    'calm': (Color(0xFFE6EDDF), Color(0xFF335837)),
    'cold': (Color(0xFFE1ECF7), Color(0xFF285E8E)),
  };
  final c = tones[tone] ?? tones['calm']!;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
        color: c.$1, borderRadius: BorderRadius.circular(8)),
    child: Text(parts.first,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: FlutterFlowTheme.of(context).bodySmall.copyWith(
            color: c.$2, fontSize: size, fontWeight: FontWeight.w600)),
  );
}

/// A compact picture stand-in when no suitable photo exists: the food's name
/// set small and calm, never a borrowed photo of a different food or form.
Widget _uFallback(BuildContext context, String name, {double height = 110}) {
  final t = FlutterFlowTheme.of(context);
  return Container(
    height: height,
    color: const Color(0xFFE4E9D9),
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Text(name.toUpperCase(),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: t.bodyMedium.copyWith(
            color: const Color(0xFF526845),
            letterSpacing: 2,
            fontSize: 14,
            fontWeight: FontWeight.w600)),
  );
}

/// The back control on ordinary pages: a cream square with a forest arrow.
Widget _uBack(BuildContext context, VoidCallback onTap) => _UPress(
      onTap: onTap,
      label: 'Back',
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFCDD6C4)),
          boxShadow: const [
            BoxShadow(color: Color(0xFFD6DFCC), offset: Offset(0, 2))
          ],
        ),
        child: const Icon(Icons.arrow_back, color: _uForest, size: 22),
      ),
    );

/// Which picture a food shows (owner, 15 Sep): by default a fresh-looking
/// photo of that food when one matches it and its form, otherwise the
/// person's own photo or scan. "My photos first" in Profile swaps the order.
String _uPicture(String name, String own) {
  final mine = own.trim();
  final fresh = foodPhoto(name, '') ?? '';
  if (FFAppState().photoPreference == 'own') {
    return mine.isNotEmpty ? mine : fresh;
  }
  return fresh.isNotEmpty ? fresh : mine;
}

/// A food card for the two-column grids: picture, two-line name, amount and
/// the date badge.
Widget _uFoodCard(BuildContext context, Map item, {required VoidCallback onTap}) {
  final t = FlutterFlowTheme.of(context);
  final name = '${item['name'] ?? ''}';
  final photo = _uPicture(name, '${item['image_url'] ?? ''}');
  final qty = item['quantity'] is num ? (item['quantity'] as num).toDouble() : null;
  final amount = quantityLabel(qty, '${item['unit'] ?? ''}') ?? '';
  final badge = dateBadge(
        '${item['computed_status'] ?? ''}',
        item['days_left'] is num ? (item['days_left'] as num).round() : null,
        DateTime.tryParse('${item['printed_date'] ?? ''}'),
        '${item['printed_date_type'] ?? ''}',
        '${item['status_basis'] ?? ''}',
      ) ??
      '';
  return _USurface(
    radius: 20,
    onTap: onTap,
    label: '$name. ${badge.split('|').first}',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 110,
          child: photo.isEmpty
              ? _uFallback(context, name)
              : Image.network(photo,
                  fit: BoxFit.cover,
                  cacheWidth: 480,
                  errorBuilder: (_, __, ___) => _uFallback(context, name)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.titleSmall.copyWith(
                      fontSize: 16,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      color: _uInk)),
              const SizedBox(height: 4),
              Text(amount.isEmpty ? ' ' : amount,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall.copyWith(color: _uMuted, fontSize: 13)),
              const SizedBox(height: 8),
              _uBadge(context, badge),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Food close to its date, the one rule Home, Inventory and Use soon share:
/// past or at its limit, "use soon", or three days or fewer; never frozen.
bool _uSoon(Map item) {
  final status = '${item['computed_status'] ?? ''}';
  if (status == 'frozen' || status == 'consumed' || status == 'discarded') {
    return false;
  }
  if (const {'past_use_by', 'use_today', 'use_soon', 'past_best_before'}
      .contains(status)) {
    return true;
  }
  final d = item['days_left'];
  return d is num && d <= 3;
}

/// The sculpted card as a decoration, for existing layouts.
BoxDecoration _uCard(double radius) => BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFEF9), Color(0xFFF3F3E9)],
      ),
      borderRadius: BorderRadius.circular(radius < 18 ? radius : 22),
      border: Border.all(color: _uLine),
      boxShadow: const [
        BoxShadow(color: Color(0xFFD2D8C9), offset: Offset(0, 2)),
        BoxShadow(color: Color(0x14263824), offset: Offset(0, 8), blurRadius: 16),
      ],
    );

/// The ordinary back control: a cream square with a forest arrow.
BoxDecoration _uBackDeco() => BoxDecoration(
      color: const Color(0xFFFFFDF4),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFCDD6C4)),
      boxShadow: const [BoxShadow(color: Color(0xFFD6DFCC), offset: Offset(0, 2))],
    );
''';

const _wInventoryKitchen = r'''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Everything below "Your kitchen.": where the food is, and what to use first.
///
/// Hybrid design (brief, 15 Sep): a segmented place control with counts, an
/// always-visible search field, and the two-column grid of sculpted food
/// cards with two-line names, amounts and date badges that say their basis.
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
              'id, name, category, category_display_name, quantity, unit, image_url, location_type, computed_status, status_label, status_detail, days_left, printed_date, printed_date_type, status_basis')
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
    final soon = _items.where(_uSoon).length;
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
        if (_items.isNotEmpty) ...[
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
        color: const Color(0xFFDEE6D5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD6BF)),
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
            color: on ? const Color(0xFFFFFDF7) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: on
                ? const [
                    BoxShadow(
                        color: Color(0x1A254221),
                        blurRadius: 5,
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
        fillColor: const Color(0xFFFFFDF7),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _uLine),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _uLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
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
        children: [
          for (final i in items)
            SizedBox(
                width: w, child: _uFoodCard(context, i, onTap: () => _open(i))),
        ],
      );
    });
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
    return _USurface(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
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
          _UButton(action,
              icon: actionIcon, busy: _busy, onTap: _busy ? null : onAction),
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
        _USurface(
          child: SizedBox(
            height: 190,
            child: Image.network('$_food/tomatoes.webp',
                fit: BoxFit.cover,
                semanticLabel: '',
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
        _UButton('Add food',
            icon: Icons.add,
            busy: _busy,
            onTap: _busy ? null : () => _run(_photographShelf)),
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

// ---- Hybrid material (design brief, 15 Sep) --------------------------------
// Cream canvas over a blurred food background (set on the page), sculpted
// cream surfaces, forest gradient primary buttons, calm date badges.

const _uForest = Color(0xFF07533A);
const _uForestTop = Color(0xFF176C50);
const _uInk = Color(0xFF202C24);
const _uMuted = Color(0xFF59665D);
const _uSage = Color(0xFFE6EDDF);
const _uLine = Color(0xFFCDD4C3);
const _uCream = Color(0xFFF7F7F0);

bool _uStill(BuildContext c) => MediaQuery.of(c).disableAnimations;

/// A sculpted cream surface: warm diagonal gradient, thin sage border, a
/// narrow white top highlight, a 2px lower edge and a soft shadow.
class _USurface extends StatelessWidget {
  const _USurface({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = 22,
    this.onTap,
    this.label,
    this.tint,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final String? label;
  final List<Color>? tint;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    final body = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: tint ?? const [Color(0xFFFFFEF9), Color(0xFFF3F3E9)],
        ),
        borderRadius: r,
        border: Border.all(color: _uLine),
        boxShadow: const [
          BoxShadow(color: Color(0xFFD2D8C9), offset: Offset(0, 2)),
          BoxShadow(
              color: Color(0x14263824), offset: Offset(0, 8), blurRadius: 16),
        ],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: Stack(
          children: [
            Padding(padding: padding, child: child),
            // The narrow white highlight along the top edge.
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 1.5,
              child: ColoredBox(color: Color(0xCCFFFFFF)),
            ),
          ],
        ),
      ),
    );
    if (onTap == null) return body;
    return _UPress(onTap: onTap!, label: label, radius: radius, child: body);
  }
}

/// A tap target that sinks 1px while pressed (tonal only with reduced motion).
class _UPress extends StatefulWidget {
  const _UPress({
    required this.child,
    required this.onTap,
    this.label,
    this.radius = 16,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback onTap;
  final String? label;
  final double radius;
  final bool enabled;

  @override
  State<_UPress> createState() => _UPressState();
}

class _UPressState extends State<_UPress> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final still = _uStill(context);
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown:
            widget.enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: widget.enabled ? (_down && still ? 0.85 : 1) : 0.55,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 100),
            offset: _down && !still ? const Offset(0, 0.01) : Offset.zero,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Buttons: one forest primary per task, cream secondaries, quiet text links.
class _UButton extends StatelessWidget {
  const _UButton(
    this.text, {
    required this.onTap,
    this.icon,
    this.kind = 'primary',
    this.busy = false,
    this.trailing = false,
  });

  final String text;
  final VoidCallback? onTap;
  final IconData? icon;
  final String kind; // primary | secondary | danger
  final bool busy;
  final bool trailing;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final primary = kind == 'primary';
    final danger = kind == 'danger';
    final fg = primary
        ? Colors.white
        : (danger ? const Color(0xFFB42318) : _uForest);
    final iconW = icon == null ? null : Icon(icon, size: 20, color: fg);
    final label = Text(text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: t.bodyLarge.copyWith(
            color: fg,
            fontSize: primary ? 16 : 15,
            fontWeight: primary ? FontWeight.w700 : FontWeight.w600));
    final content = busy
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: fg))
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (iconW != null && !trailing) ...[iconW, const SizedBox(width: 8)],
              Flexible(child: label),
              if (iconW != null && trailing) ...[const SizedBox(width: 8), iconW],
            ],
          );
    final box = Container(
      constraints: BoxConstraints(minHeight: primary ? 52 : 48),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: primary
              ? const [_uForestTop, _uForest]
              : const [Color(0xFFFFFEFA), Color(0xFFEDF0E4)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: primary
                ? const Color(0xFF06422E)
                : (danger ? const Color(0xFFEBC5BF) : const Color(0xFFCCD7C2))),
        boxShadow: primary
            ? const [
                BoxShadow(color: Color(0xFF033C29), offset: Offset(0, 3)),
                BoxShadow(
                    color: Color(0x2007533A),
                    offset: Offset(0, 6),
                    blurRadius: 10),
              ]
            : const [BoxShadow(color: Color(0xFFD6DFCC), offset: Offset(0, 2))],
      ),
      child: content,
    );
    return _UPress(
      onTap: onTap ?? () {},
      enabled: onTap != null && !busy,
      label: text,
      child: box,
    );
  }
}

/// The date badge from dateBadge(): "Label|tone".
Widget _uBadge(BuildContext context, String spec, {double size = 12}) {
  if (spec.isEmpty) return const SizedBox.shrink();
  final parts = spec.split('|');
  final tone = parts.length > 1 ? parts[1] : 'calm';
  const tones = <String, (Color, Color)>{
    'urgent': (Color(0xFFFDE3E0), Color(0xFFB42318)),
    'warm': (Color(0xFFFFEAD4), Color(0xFF884311)),
    'calm': (Color(0xFFE6EDDF), Color(0xFF335837)),
    'cold': (Color(0xFFE1ECF7), Color(0xFF285E8E)),
  };
  final c = tones[tone] ?? tones['calm']!;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
        color: c.$1, borderRadius: BorderRadius.circular(8)),
    child: Text(parts.first,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: FlutterFlowTheme.of(context).bodySmall.copyWith(
            color: c.$2, fontSize: size, fontWeight: FontWeight.w600)),
  );
}

/// A compact picture stand-in when no suitable photo exists: the food's name
/// set small and calm, never a borrowed photo of a different food or form.
Widget _uFallback(BuildContext context, String name, {double height = 110}) {
  final t = FlutterFlowTheme.of(context);
  return Container(
    height: height,
    color: const Color(0xFFE4E9D9),
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Text(name.toUpperCase(),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: t.bodyMedium.copyWith(
            color: const Color(0xFF526845),
            letterSpacing: 2,
            fontSize: 14,
            fontWeight: FontWeight.w600)),
  );
}

/// The back control on ordinary pages: a cream square with a forest arrow.
Widget _uBack(BuildContext context, VoidCallback onTap) => _UPress(
      onTap: onTap,
      label: 'Back',
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFCDD6C4)),
          boxShadow: const [
            BoxShadow(color: Color(0xFFD6DFCC), offset: Offset(0, 2))
          ],
        ),
        child: const Icon(Icons.arrow_back, color: _uForest, size: 22),
      ),
    );

/// Which picture a food shows (owner, 15 Sep): by default a fresh-looking
/// photo of that food when one matches it and its form, otherwise the
/// person's own photo or scan. "My photos first" in Profile swaps the order.
String _uPicture(String name, String own) {
  final mine = own.trim();
  final fresh = foodPhoto(name, '') ?? '';
  if (FFAppState().photoPreference == 'own') {
    return mine.isNotEmpty ? mine : fresh;
  }
  return fresh.isNotEmpty ? fresh : mine;
}

/// A food card for the two-column grids: picture, two-line name, amount and
/// the date badge.
Widget _uFoodCard(BuildContext context, Map item, {required VoidCallback onTap}) {
  final t = FlutterFlowTheme.of(context);
  final name = '${item['name'] ?? ''}';
  final photo = _uPicture(name, '${item['image_url'] ?? ''}');
  final qty = item['quantity'] is num ? (item['quantity'] as num).toDouble() : null;
  final amount = quantityLabel(qty, '${item['unit'] ?? ''}') ?? '';
  final badge = dateBadge(
        '${item['computed_status'] ?? ''}',
        item['days_left'] is num ? (item['days_left'] as num).round() : null,
        DateTime.tryParse('${item['printed_date'] ?? ''}'),
        '${item['printed_date_type'] ?? ''}',
        '${item['status_basis'] ?? ''}',
      ) ??
      '';
  return _USurface(
    radius: 20,
    onTap: onTap,
    label: '$name. ${badge.split('|').first}',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 110,
          child: photo.isEmpty
              ? _uFallback(context, name)
              : Image.network(photo,
                  fit: BoxFit.cover,
                  cacheWidth: 480,
                  errorBuilder: (_, __, ___) => _uFallback(context, name)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.titleSmall.copyWith(
                      fontSize: 16,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      color: _uInk)),
              const SizedBox(height: 4),
              Text(amount.isEmpty ? ' ' : amount,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall.copyWith(color: _uMuted, fontSize: 13)),
              const SizedBox(height: 8),
              _uBadge(context, badge),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Food close to its date, the one rule Home, Inventory and Use soon share:
/// past or at its limit, "use soon", or three days or fewer; never frozen.
bool _uSoon(Map item) {
  final status = '${item['computed_status'] ?? ''}';
  if (status == 'frozen' || status == 'consumed' || status == 'discarded') {
    return false;
  }
  if (const {'past_use_by', 'use_today', 'use_soon', 'past_best_before'}
      .contains(status)) {
    return true;
  }
  final d = item['days_left'];
  return d is num && d <= 3;
}

/// The sculpted card as a decoration, for existing layouts.
BoxDecoration _uCard(double radius) => BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFEF9), Color(0xFFF3F3E9)],
      ),
      borderRadius: BorderRadius.circular(radius < 18 ? radius : 22),
      border: Border.all(color: _uLine),
      boxShadow: const [
        BoxShadow(color: Color(0xFFD2D8C9), offset: Offset(0, 2)),
        BoxShadow(color: Color(0x14263824), offset: Offset(0, 8), blurRadius: 16),
      ],
    );

/// The ordinary back control: a cream square with a forest arrow.
BoxDecoration _uBackDeco() => BoxDecoration(
      color: const Color(0xFFFFFDF4),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFCDD6C4)),
      boxShadow: const [BoxShadow(color: Color(0xFFD6DFCC), offset: Offset(0, 2))],
    );
''';

const _wFoodDetail = r'''
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Everything about one food (hybrid design, brief 15 Sep).
///
/// A smaller photo so the facts and actions sit in the first screen: the name
/// and a date badge that says its basis, quantity and place, a date note with
/// Edit date, "Use some" (choose how many) and Edit, "Add to shopping list" as
/// its own action, and More details. Throw out is separate, asks how many and
/// confirms, and every recorded change can be undone.
class FoodDetail extends StatefulWidget {
  const FoodDetail({super.key, this.width, this.height, this.itemId});

  final double? width;
  final double? height;
  final String? itemId;

  @override
  State<FoodDetail> createState() => _FoodDetailState();
}

class _FoodDetailState extends State<FoodDetail> {
  static const _forest = Color(0xFF07533A);
  static const _ink = Color(0xFF202C24);
  static const _muted = Color(0xFF59665D);
  static const _sage = Color(0xFFEDF2E8);
  static const _border = Color(0xFFDCE3D7);

  static const _food =
      'https://cdn.jsdelivr.net/gh/ashelashiry/UseItFresh@b50424f12bd372d81c9cd44d895b62c25d1329e7/design/v3/food';

  List<FoodItemsStatusRow> _rows = const [];
  bool _loading = true;
  bool _offline = false;
  bool _listed = false;
  bool _moreOpen = false;
  bool _busy = false;
  bool _photoBusy = false;

  String get _id => (widget.itemId ?? '').trim();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool quiet = false}) async {
    if (!quiet && mounted) {
      setState(() {
        _loading = true;
        _offline = false;
      });
    }
    try {
      final rows = await FoodItemsStatusTable()
          .queryRows(queryFn: (q) => q.eqOrNull('id', _id));
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
        _offline = false;
      });
    } catch (_) {
      if (!mounted) return;
      if (quiet && _rows.isNotEmpty) return;
      setState(() {
        _loading = false;
        _offline = true;
      });
    }
  }

  String _field(String name) => itemField(_rows, name) ?? '';

  // Shows the other picture when both a fresh photo and your own exist.
  bool _otherPicture = false;

  String get _ownPicture =>
      _rows.isEmpty ? '' : (_rows.first.imageUrl ?? '').trim();

  String get _freshPicture =>
      _rows.isEmpty ? '' : (foodPhoto(_rows.first.name ?? '', '') ?? '');

  bool get _bothPictures =>
      _ownPicture.isNotEmpty && _freshPicture.isNotEmpty;

  String? get _photo {
    if (_rows.isEmpty) return null;
    final preferred = _uPicture(_rows.first.name ?? '', _ownPicture);
    if (_otherPicture && _bothPictures) {
      return preferred == _ownPicture ? _freshPicture : _ownPicture;
    }
    return preferred.isEmpty ? null : preferred;
  }

  String get _badge {
    if (_rows.isEmpty) return '';
    final r = _rows.first;
    return dateBadge(r.computedStatus ?? '', r.daysLeft, r.printedDate,
            r.printedDateType ?? '', r.statusBasis ?? '') ??
        '';
  }

  double get _quantity {
    final q = _rows.isEmpty ? null : _rows.first.quantity;
    return q == null || q <= 0 ? 1 : q;
  }

  // ---- actions ---------------------------------------------------------------

  bool get _hasOwnPhoto =>
      _rows.isNotEmpty && (_rows.first.imageUrl ?? '').trim().isNotEmpty;

  /// Take a photo, choose one, or remove the one it has.
  Future<void> _changePhoto() async {
    if (_photoBusy || _busy) return;
    final t = FlutterFlowTheme.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final own = _hasOwnPhoto;
    Widget option(BuildContext c, IconData icon, String label, String value,
            {Color colour = _ink}) =>
        ListTile(
          minVerticalPadding: 14,
          leading: Icon(icon, color: colour == _ink ? _forest : colour),
          title: Text(label,
              style: t.bodyLarge.copyWith(
                  fontSize: 16, color: colour, fontWeight: FontWeight.w600)),
          onTap: () => Navigator.of(c).pop(value),
        );
    final source = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(own ? 'Change the photo' : 'Add a photo',
                    style: t.titleLarge.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _ink)),
              ),
              option(c, Icons.photo_camera_outlined, 'Take a photo', 'camera'),
              option(c, Icons.photo_library_outlined, 'Choose from your photos',
                  'gallery'),
              option(
                  c, Icons.travel_explore, 'Find the product photo', 'product'),
              if (own)
                option(
                    c, Icons.hide_image_outlined, 'Remove the photo', 'remove',
                    colour: const Color(0xFFB42318)),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;
    if (source == 'product') {
      final used = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFFF7F7F0),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (sheet) => ConstrainedBox(
          constraints:
              BoxConstraints(maxHeight: MediaQuery.of(sheet).size.height * 0.9),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, 20 + MediaQuery.of(sheet).viewInsets.bottom),
              child: ProductPhotoPicker(itemId: _id, foodName: _field('name')),
            ),
          ),
        ),
      );
      if (used == true && mounted) await _load(quiet: true);
      return;
    }
    setState(() => _photoBusy = true);
    try {
      final said = await changeFoodPhoto(_id, source);
      if (said == 'ok') {
        messenger.showSnackBar(SnackBar(
            content:
                Text(source == 'remove' ? 'Photo removed.' : 'Photo saved.')));
        await _load(quiet: true);
      } else if (said.isNotEmpty) {
        messenger.showSnackBar(SnackBar(content: Text(said)));
      }
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  void _back() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.goNamed('InventoryPage');
    }
  }

  Future<void> _edit() async {
    await context.pushNamed('EditItemPage', queryParameters: {'itemId': _id});
    if (mounted) _load(quiet: true);
  }

  /// Record that some or all of it was used or thrown out. Part of it only
  /// lowers the amount; all of it settles the food. Both can be undone.
  Future<void> _settle(String outcome, {double? amount}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final id = _id;
    final name = _field('name');
    final before = _quantity;
    final unit = _rows.isEmpty ? '' : (_rows.first.unit ?? '');
    try {
      if (amount != null && amount < before) {
        final left = before - amount;
        await SupaFlow.client
            .from('food_items')
            .update({'quantity': left}).eq('id', id);
        try {
          await SupaFlow.client.from('food_item_events').insert({
            'food_item_id': id,
            'profile_id': SupaFlow.client.auth.currentUser?.id,
            'event_type': 'quantity_changed',
            'from_value': {'quantity': before},
            'to_value': {'quantity': left, 'reason': outcome},
          });
        } catch (_) {}
        await _load(quiet: true);
        messenger.showSnackBar(SnackBar(
          duration: const Duration(seconds: 6),
          content: Text(
              '${outcome == 'consumed' ? 'Used' : 'Thrown out'} ${quantityLabel(amount, unit)}. ${quantityLabel(left, unit)} left.'),
          action: SnackBarAction(
            label: 'Undo',
            textColor: const Color(0xFFB9E08F),
            onPressed: () async {
              try {
                await SupaFlow.client
                    .from('food_items')
                    .update({'quantity': before}).eq('id', id);
                if (mounted) _load(quiet: true);
              } catch (_) {
                messenger.showSnackBar(const SnackBar(
                    content: Text('Could not undo. Check your signal.')));
              }
            },
          ),
        ));
        return;
      }
      final said = await settleFoodItem(id, outcome);
      if (said.isNotEmpty) {
        messenger.showSnackBar(SnackBar(content: Text(said)));
        return;
      }
      messenger.showSnackBar(SnackBar(
        duration: const Duration(seconds: 6),
        content: Text(outcome == 'consumed'
            ? 'Marked as used.'
            : 'Thrown out and recorded.'),
        action: SnackBarAction(
          label: 'Undo',
          textColor: const Color(0xFFB9E08F),
          onPressed: () async {
            final back = await unsettleFoodItem(id);
            messenger.showSnackBar(SnackBar(
                content: Text(back.isEmpty
                    ? '${name.isEmpty ? 'It' : name} is back in your kitchen.'
                    : back)));
            if (back.isEmpty) {
              router.pushNamed('FoodItemPage', queryParameters: {'itemId': id});
            }
          },
        ),
      ));
      router.pushNamed('InventoryPage');
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Could not save that. Check your signal.')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// "Use some" or "Throw out": how much, then record it.
  Future<void> _howMuch(String outcome) async {
    final t = FlutterFlowTheme.of(context);
    final q = _quantity;
    final unit = _rows.isEmpty ? '' : (_rows.first.unit ?? '');
    final whole = q == q.roundToDouble();
    final step = whole ? 1.0 : q / 4;
    final used = outcome == 'consumed';
    // One item: nothing to choose.
    if (q <= 1) {
      if (!used) {
        final sure = await _confirmThrow(t, quantityLabel(q, unit) ?? '');
        if (sure != true) return;
      }
      await _settle(outcome);
      return;
    }
    var amount = step;
    final choice = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _uCream,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, redraw) => SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                    used
                        ? 'How much did you use?'
                        : 'How much are you throwing out?',
                    style: t.headlineSmall.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _uInk)),
                const SizedBox(height: 4),
                Text('You have ${quantityLabel(q, unit)}.',
                    style: t.bodyLarge.copyWith(color: _uMuted, fontSize: 16)),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _stepButton(Icons.remove, amount > step,
                        () => redraw(() => amount -= step)),
                    SizedBox(
                      width: 140,
                      child: Text(quantityLabel(amount, unit) ?? '',
                          textAlign: TextAlign.center,
                          style: t.titleLarge.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: _uInk)),
                    ),
                    _stepButton(
                        Icons.add,
                        amount < q,
                        () => redraw(
                            () => amount = (amount + step).clamp(step, q))),
                  ],
                ),
                const SizedBox(height: 20),
                _UButton(
                    amount >= q
                        ? (used ? 'Used all of it' : 'Throw all of it out')
                        : (used
                            ? 'Used ${quantityLabel(amount, unit)}'
                            : 'Throw out ${quantityLabel(amount, unit)}'),
                    kind: used ? 'primary' : 'danger',
                    onTap: () => Navigator.of(sheet).pop(amount)),
                const SizedBox(height: 10),
                if (amount < q)
                  _UButton(used ? 'Used all of it' : 'Throw all of it out',
                      kind: 'secondary',
                      onTap: () => Navigator.of(sheet).pop(q)),
              ],
            ),
          ),
        ),
      ),
    );
    if (choice == null || !mounted) return;
    if (!used) {
      final sure = await _confirmThrow(t, quantityLabel(choice, unit) ?? '');
      if (sure != true) return;
    }
    await _settle(outcome, amount: choice);
  }

  Future<bool?> _confirmThrow(FlutterFlowTheme t, String what) =>
      showDialog<bool>(
        context: context,
        builder: (d) => AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Throw out $what?'),
          content: const Text(
              'It is recorded in What you used. You can undo straight after.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(d).pop(false),
                child: const Text('Keep it')),
            TextButton(
                onPressed: () => Navigator.of(d).pop(true),
                child: const Text('Throw out',
                    style: TextStyle(color: Color(0xFFB42318)))),
          ],
        ),
      );

  Widget _stepButton(IconData icon, bool enabled, VoidCallback onTap) =>
      _UPress(
        enabled: enabled,
        onTap: onTap,
        label: icon == Icons.add ? 'More' : 'Less',
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFFFDF6),
            border: Border.all(color: const Color(0xFFCAD4BF)),
          ),
          child: Icon(icon, color: _uForest, size: 22),
        ),
      );

  Future<void> _addToList() async {
    if (_listed || _busy) return;
    final messenger = ScaffoldMessenger.of(context);
    final said = await addItemToShoppingList(_id);
    if (!mounted) return;
    if (said.isEmpty) {
      setState(() => _listed = true);
      messenger.showSnackBar(
          const SnackBar(content: Text('Added to your shopping list.')));
    } else {
      messenger.showSnackBar(SnackBar(content: Text(said)));
    }
  }

  // ---- page ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    Widget body;
    if (_loading) {
      body = _skeleton();
    } else if (_offline) {
      body = _message(t,
          icon: Icons.cloud_off_outlined,
          title: 'Can’t reach your kitchen.',
          text:
              'No signal, or the connection dropped. This item will show again as soon as you are back online.',
          action: 'Try again',
          onAction: _load);
    } else if (_rows.isEmpty) {
      body = _message(t,
          icon: Icons.kitchen_outlined,
          title: 'Not in your kitchen.',
          text: 'This food has been used, thrown out or removed.',
          action: 'Back to your kitchen',
          onAction: () => context.goNamed('InventoryPage'));
    } else {
      body = _food_(t);
    }
    return SizedBox(
      width: widget.width,
      child: AnimatedSwitcher(
        duration: MediaQuery.of(context).disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 200),
        child: KeyedSubtree(
          key: ValueKey(
              _loading ? 'l' : (_offline ? 'o' : (_rows.isEmpty ? 'e' : 'f'))),
          child: body,
        ),
      ),
    );
  }

  Widget _backButton({bool onPhoto = true}) => _uBack(context, _back);

  // Top right of the photo: a camera, with words while there is no picture so
  // the empty tile says what to do.
  Widget _photoButton(FlutterFlowTheme t) {
    final own = _hasOwnPhoto;
    return Semantics(
      button: true,
      label: own ? 'Change the photo' : 'Add a photo',
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: _photoBusy ? null : _changePhoto,
        child: Container(
          height: 44,
          padding: EdgeInsets.symmetric(horizontal: own ? 0 : 14),
          width: own ? 44 : null,
          decoration: BoxDecoration(
            color: const Color(0xF2FFFDF5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFCDD6C4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.photo_camera_outlined,
                  color: _uForest, size: 21),
              if (!own) ...[
                const SizedBox(width: 6),
                Text('Add a photo',
                    style: t.bodyMedium.copyWith(
                        color: _uForest,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _food_(FlutterFlowTheme t) {
    final name = _field('name');
    final photo = _photo;
    final badge = _badge;
    final illustrative = photo != null && photo.contains('/design/v3/food/');
    final product = photo != null && photo.contains('/product-');
    final quantity = _field('quantity');
    final where = _field('where');
    final dateLine = _field('date');
    final source = _field('dateSource');
    final advice = _field('detail');
    final status = _field('status');
    final more = <(String, String)>[
      ('Category', _field('category')),
      ('How the date was worked out', _field('basis')),
      ('Added', _field('added').replaceFirst('Added ', '')),
      if (illustrative) ('Picture', 'An illustrative photo, not your food'),
      if (product) ('Picture', 'Photo: Open Food Facts'),
    ].where((r) => r.$2.trim().isNotEmpty).toList();

    Widget fact(String label, String value) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFBFCFB7))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: t.bodySmall.copyWith(color: _uMuted, fontSize: 13)),
                const SizedBox(height: 2),
                Text(value.isEmpty ? 'Not recorded' : value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodyLarge.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _uInk)),
              ],
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _backButton(onPhoto: false),
              const Spacer(),
              _photoButton(t),
            ],
          ),
          const SizedBox(height: 14),
          _USurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: photo == null ? 96 : 195,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      photo == null
                          ? _uFallback(context, name, height: 96)
                          : Image.network(photo,
                              fit: BoxFit.cover,
                              cacheWidth: 900,
                              semanticLabel:
                                  illustrative ? 'Illustrative photo' : name,
                              errorBuilder: (_, __, ___) =>
                                  _uFallback(context, name, height: 195)),
                      if (_photoBusy)
                        const ColoredBox(
                          color: Color(0x66000000),
                          child: Center(
                            child: SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                  strokeWidth: 3, color: Colors.white),
                            ),
                          ),
                        ),
                      if (_bothPictures)
                        Positioned(
                          left: 10,
                          bottom: 10,
                          child: _UPress(
                            label: illustrative
                                ? 'Show my photo'
                                : 'Show a fresh photo',
                            onTap: () =>
                                setState(() => _otherPicture = !_otherPicture),
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 32),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xE6FFFDF5),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                  illustrative
                                      ? 'Show my photo'
                                      : 'Show a fresh photo',
                                  style: t.bodySmall.copyWith(
                                      color: _uForest,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                      if (illustrative || product)
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0x99000000),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                                product
                                    ? 'Photo: Open Food Facts'
                                    : 'Illustrative photo',
                                style: t.bodySmall.copyWith(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: t.headlineMedium.copyWith(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: _uForest,
                              height: 1.1)),
                      if (badge.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _uBadge(context, badge, size: 13),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              fact('Quantity', quantity),
              const SizedBox(width: 16),
              fact('Stored in', where),
            ],
          ),
          const SizedBox(height: 16),
          // The date, what it is based on, and a way to set it.
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
            decoration: BoxDecoration(
              color: const Color(0xF2F4F7EA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFCAD7BF)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dateLine,
                          style: t.bodyLarge.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _uInk)),
                      const SizedBox(height: 2),
                      Text(source,
                          style: t.bodySmall
                              .copyWith(color: _uMuted, fontSize: 13)),
                      if ((status == 'past_use_by' ||
                              status == 'past_best_before') &&
                          advice.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(advice,
                            style: t.bodyMedium.copyWith(
                                color: _uInk,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                      minimumSize: const Size(48, 44),
                      foregroundColor: _uForest),
                  onPressed: _busy ? null : _edit,
                  child: Text(
                      _rows.first.printedDate == null
                          ? 'Add date'
                          : 'Edit date',
                      style: t.bodyMedium.copyWith(
                          color: _uForest, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _UButton('Use some',
                    busy: _busy,
                    onTap: _busy ? null : () => _howMuch('consumed')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _UButton('Edit',
                    kind: 'secondary',
                    icon: Icons.edit_outlined,
                    onTap: _busy ? null : _edit),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _UButton(_listed ? 'On your shopping list' : 'Add to shopping list',
              kind: 'secondary',
              icon: _listed ? Icons.check : Icons.add_shopping_cart,
              onTap: _listed || _busy ? null : _addToList),
          const SizedBox(height: 14),
          if (more.isNotEmpty)
            _USurface(
              radius: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _UPress(
                    label: _moreOpen ? 'Hide details' : 'More details',
                    onTap: () => setState(() => _moreOpen = !_moreOpen),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Icon(
                              _moreOpen ? Icons.expand_less : Icons.expand_more,
                              color: _uForest),
                          const SizedBox(width: 8),
                          Text('More details',
                              style: t.bodyLarge.copyWith(
                                  color: _uForest,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                  if (_moreOpen)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final r in more)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.$1,
                                      style: t.bodySmall.copyWith(
                                          color: _uMuted, fontSize: 13)),
                                  Text(r.$2,
                                      style: t.bodyLarge.copyWith(
                                          color: _uInk, fontSize: 15)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 18),
          // Kept apart from everyday actions, and always asks first.
          Center(
            child: TextButton.icon(
              style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: const Color(0xFFB42318)),
              onPressed: _busy ? null : () => _howMuch('discarded'),
              icon: const Icon(Icons.delete_outline, size: 20),
              label: Text('Throw out',
                  style: t.bodyLarge.copyWith(
                      color: const Color(0xFFB42318),
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeleton() {
    Widget block(double h, {double r = 20}) => Container(
          height: h,
          decoration: BoxDecoration(
              color: _sage, borderRadius: BorderRadius.circular(r)),
        );
    return Semantics(
      label: 'Loading this food',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                      alignment: Alignment.centerLeft,
                      child: _backButton(onPhoto: false)),
                  const SizedBox(height: 14),
                  block(290),
                  const SizedBox(height: 12),
                  block(92),
                ]),
          ),
        ],
      ),
    );
  }

  Widget _message(FlutterFlowTheme t,
      {required IconData icon,
      required String title,
      required String text,
      required String action,
      required VoidCallback onAction}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _backButton(onPhoto: false),
          const SizedBox(height: 24),
          _USurface(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _ink)),
                const SizedBox(height: 6),
                Text(text,
                    style: t.bodyLarge
                        .copyWith(fontSize: 16, color: _muted, height: 1.4)),
                const SizedBox(height: 16),
                _UButton(action, onTap: onAction),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Hybrid material (design brief, 15 Sep) --------------------------------
// Cream canvas over a blurred food background (set on the page), sculpted
// cream surfaces, forest gradient primary buttons, calm date badges.

const _uForest = Color(0xFF07533A);
const _uForestTop = Color(0xFF176C50);
const _uInk = Color(0xFF202C24);
const _uMuted = Color(0xFF59665D);
const _uSage = Color(0xFFE6EDDF);
const _uLine = Color(0xFFCDD4C3);
const _uCream = Color(0xFFF7F7F0);

bool _uStill(BuildContext c) => MediaQuery.of(c).disableAnimations;

/// A sculpted cream surface: warm diagonal gradient, thin sage border, a
/// narrow white top highlight, a 2px lower edge and a soft shadow.
class _USurface extends StatelessWidget {
  const _USurface({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = 22,
    this.onTap,
    this.label,
    this.tint,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final String? label;
  final List<Color>? tint;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    final body = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: tint ?? const [Color(0xFFFFFEF9), Color(0xFFF3F3E9)],
        ),
        borderRadius: r,
        border: Border.all(color: _uLine),
        boxShadow: const [
          BoxShadow(color: Color(0xFFD2D8C9), offset: Offset(0, 2)),
          BoxShadow(
              color: Color(0x14263824), offset: Offset(0, 8), blurRadius: 16),
        ],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: Stack(
          children: [
            Padding(padding: padding, child: child),
            // The narrow white highlight along the top edge.
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 1.5,
              child: ColoredBox(color: Color(0xCCFFFFFF)),
            ),
          ],
        ),
      ),
    );
    if (onTap == null) return body;
    return _UPress(onTap: onTap!, label: label, radius: radius, child: body);
  }
}

/// A tap target that sinks 1px while pressed (tonal only with reduced motion).
class _UPress extends StatefulWidget {
  const _UPress({
    required this.child,
    required this.onTap,
    this.label,
    this.radius = 16,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback onTap;
  final String? label;
  final double radius;
  final bool enabled;

  @override
  State<_UPress> createState() => _UPressState();
}

class _UPressState extends State<_UPress> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final still = _uStill(context);
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown:
            widget.enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: widget.enabled ? (_down && still ? 0.85 : 1) : 0.55,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 100),
            offset: _down && !still ? const Offset(0, 0.01) : Offset.zero,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Buttons: one forest primary per task, cream secondaries, quiet text links.
class _UButton extends StatelessWidget {
  const _UButton(
    this.text, {
    required this.onTap,
    this.icon,
    this.kind = 'primary',
    this.busy = false,
    this.trailing = false,
  });

  final String text;
  final VoidCallback? onTap;
  final IconData? icon;
  final String kind; // primary | secondary | danger
  final bool busy;
  final bool trailing;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final primary = kind == 'primary';
    final danger = kind == 'danger';
    final fg = primary
        ? Colors.white
        : (danger ? const Color(0xFFB42318) : _uForest);
    final iconW = icon == null ? null : Icon(icon, size: 20, color: fg);
    final label = Text(text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: t.bodyLarge.copyWith(
            color: fg,
            fontSize: primary ? 16 : 15,
            fontWeight: primary ? FontWeight.w700 : FontWeight.w600));
    final content = busy
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: fg))
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (iconW != null && !trailing) ...[iconW, const SizedBox(width: 8)],
              Flexible(child: label),
              if (iconW != null && trailing) ...[const SizedBox(width: 8), iconW],
            ],
          );
    final box = Container(
      constraints: BoxConstraints(minHeight: primary ? 52 : 48),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: primary
              ? const [_uForestTop, _uForest]
              : const [Color(0xFFFFFEFA), Color(0xFFEDF0E4)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: primary
                ? const Color(0xFF06422E)
                : (danger ? const Color(0xFFEBC5BF) : const Color(0xFFCCD7C2))),
        boxShadow: primary
            ? const [
                BoxShadow(color: Color(0xFF033C29), offset: Offset(0, 3)),
                BoxShadow(
                    color: Color(0x2007533A),
                    offset: Offset(0, 6),
                    blurRadius: 10),
              ]
            : const [BoxShadow(color: Color(0xFFD6DFCC), offset: Offset(0, 2))],
      ),
      child: content,
    );
    return _UPress(
      onTap: onTap ?? () {},
      enabled: onTap != null && !busy,
      label: text,
      child: box,
    );
  }
}

/// The date badge from dateBadge(): "Label|tone".
Widget _uBadge(BuildContext context, String spec, {double size = 12}) {
  if (spec.isEmpty) return const SizedBox.shrink();
  final parts = spec.split('|');
  final tone = parts.length > 1 ? parts[1] : 'calm';
  const tones = <String, (Color, Color)>{
    'urgent': (Color(0xFFFDE3E0), Color(0xFFB42318)),
    'warm': (Color(0xFFFFEAD4), Color(0xFF884311)),
    'calm': (Color(0xFFE6EDDF), Color(0xFF335837)),
    'cold': (Color(0xFFE1ECF7), Color(0xFF285E8E)),
  };
  final c = tones[tone] ?? tones['calm']!;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
        color: c.$1, borderRadius: BorderRadius.circular(8)),
    child: Text(parts.first,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: FlutterFlowTheme.of(context).bodySmall.copyWith(
            color: c.$2, fontSize: size, fontWeight: FontWeight.w600)),
  );
}

/// A compact picture stand-in when no suitable photo exists: the food's name
/// set small and calm, never a borrowed photo of a different food or form.
Widget _uFallback(BuildContext context, String name, {double height = 110}) {
  final t = FlutterFlowTheme.of(context);
  return Container(
    height: height,
    color: const Color(0xFFE4E9D9),
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Text(name.toUpperCase(),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: t.bodyMedium.copyWith(
            color: const Color(0xFF526845),
            letterSpacing: 2,
            fontSize: 14,
            fontWeight: FontWeight.w600)),
  );
}

/// The back control on ordinary pages: a cream square with a forest arrow.
Widget _uBack(BuildContext context, VoidCallback onTap) => _UPress(
      onTap: onTap,
      label: 'Back',
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFCDD6C4)),
          boxShadow: const [
            BoxShadow(color: Color(0xFFD6DFCC), offset: Offset(0, 2))
          ],
        ),
        child: const Icon(Icons.arrow_back, color: _uForest, size: 22),
      ),
    );

/// Which picture a food shows (owner, 15 Sep): by default a fresh-looking
/// photo of that food when one matches it and its form, otherwise the
/// person's own photo or scan. "My photos first" in Profile swaps the order.
String _uPicture(String name, String own) {
  final mine = own.trim();
  final fresh = foodPhoto(name, '') ?? '';
  if (FFAppState().photoPreference == 'own') {
    return mine.isNotEmpty ? mine : fresh;
  }
  return fresh.isNotEmpty ? fresh : mine;
}

/// A food card for the two-column grids: picture, two-line name, amount and
/// the date badge.
Widget _uFoodCard(BuildContext context, Map item, {required VoidCallback onTap}) {
  final t = FlutterFlowTheme.of(context);
  final name = '${item['name'] ?? ''}';
  final photo = _uPicture(name, '${item['image_url'] ?? ''}');
  final qty = item['quantity'] is num ? (item['quantity'] as num).toDouble() : null;
  final amount = quantityLabel(qty, '${item['unit'] ?? ''}') ?? '';
  final badge = dateBadge(
        '${item['computed_status'] ?? ''}',
        item['days_left'] is num ? (item['days_left'] as num).round() : null,
        DateTime.tryParse('${item['printed_date'] ?? ''}'),
        '${item['printed_date_type'] ?? ''}',
        '${item['status_basis'] ?? ''}',
      ) ??
      '';
  return _USurface(
    radius: 20,
    onTap: onTap,
    label: '$name. ${badge.split('|').first}',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 110,
          child: photo.isEmpty
              ? _uFallback(context, name)
              : Image.network(photo,
                  fit: BoxFit.cover,
                  cacheWidth: 480,
                  errorBuilder: (_, __, ___) => _uFallback(context, name)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.titleSmall.copyWith(
                      fontSize: 16,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      color: _uInk)),
              const SizedBox(height: 4),
              Text(amount.isEmpty ? ' ' : amount,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall.copyWith(color: _uMuted, fontSize: 13)),
              const SizedBox(height: 8),
              _uBadge(context, badge),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Food close to its date, the one rule Home, Inventory and Use soon share:
/// past or at its limit, "use soon", or three days or fewer; never frozen.
bool _uSoon(Map item) {
  final status = '${item['computed_status'] ?? ''}';
  if (status == 'frozen' || status == 'consumed' || status == 'discarded') {
    return false;
  }
  if (const {'past_use_by', 'use_today', 'use_soon', 'past_best_before'}
      .contains(status)) {
    return true;
  }
  final d = item['days_left'];
  return d is num && d <= 3;
}

/// The sculpted card as a decoration, for existing layouts.
BoxDecoration _uCard(double radius) => BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFEF9), Color(0xFFF3F3E9)],
      ),
      borderRadius: BorderRadius.circular(radius < 18 ? radius : 22),
      border: Border.all(color: _uLine),
      boxShadow: const [
        BoxShadow(color: Color(0xFFD2D8C9), offset: Offset(0, 2)),
        BoxShadow(color: Color(0x14263824), offset: Offset(0, 8), blurRadius: 16),
      ],
    );

/// The ordinary back control: a cream square with a forest arrow.
BoxDecoration _uBackDeco() => BoxDecoration(
      color: const Color(0xFFFFFDF4),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFCDD6C4)),
      boxShadow: const [BoxShadow(color: Color(0xFFD6DFCC), offset: Offset(0, 2))],
    );
''';

const _wUseSoonList = r'''
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Use soon: what is close to its date, to deal with in a few taps.
class UseSoonList extends StatefulWidget {
  const UseSoonList({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<UseSoonList> createState() => _UseSoonListState();
}

class _UseSoonListState extends State<UseSoonList> {
  static const _forest = Color(0xFF07533A);
  static const _ink = Color(0xFF202C24);
  static const _muted = Color(0xFF59665D);
  static const _sage = Color(0xFFEDF2E8);
  static const _border = Color(0xFFDCE3D7);

  static const _food =
      'https://cdn.jsdelivr.net/gh/ashelashiry/UseItFresh@b50424f12bd372d81c9cd44d895b62c25d1329e7/design/v3/food';

  String _for = '';
  bool _loading = true;
  bool _offline = false;
  List<Map<String, dynamic>> _items = const [];
  final Set<String> _busy = {};

  /// Close to its date: past it, today, "use soon", or three days or fewer.
  /// Frozen food is not counting down, so it is never here.
  static bool isSoon(Map<String, dynamic> i) {
    final status = (i['computed_status'] ?? '').toString();
    if (status == 'frozen' || status == 'consumed' || status == 'discarded') {
      return false;
    }
    if (const {'past_use_by', 'use_today', 'use_soon', 'past_best_before'}
        .contains(status)) {
      return true;
    }
    final d = i['days_left'];
    return d is num && d <= 3;
  }

  Future<void> _load(String household, {bool quiet = false}) async {
    if (!quiet && mounted) {
      setState(() {
        _loading = true;
        _offline = false;
      });
    }
    try {
      final rows = await SupaFlow.client
          .from('food_items_status')
          .select(
              'id, name, quantity, unit, image_url, location_name, computed_status, status_detail, days_left, printed_date, printed_date_type, status_basis')
          .eq('household_id', household)
          .order('urgency_rank', ascending: true)
          .order('days_left', ascending: true);
      if (!mounted || household != _for) return;
      setState(() {
        _items = List<Map<String, dynamic>>.from(rows as List)
            .where(isSoon)
            .toList();
        _loading = false;
        _offline = false;
      });
    } catch (_) {
      if (!mounted) return;
      if (quiet && _items.isNotEmpty) return;
      setState(() {
        _loading = false;
        _offline = true;
      });
    }
  }

  Future<void> _settle(Map<String, dynamic> item, String outcome) async {
    final id = item['id'].toString();
    if (_busy.contains(id)) return;
    setState(() => _busy.add(id));
    final messenger = ScaffoldMessenger.of(context);
    final name = (item['name'] ?? '').toString();
    final said = await settleFoodItem(id, outcome);
    if (!mounted) return;
    setState(() => _busy.remove(id));
    if (said.isNotEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(said)));
      return;
    }
    setState(
        () => _items = _items.where((i) => i['id'].toString() != id).toList());
    messenger.showSnackBar(SnackBar(
      duration: const Duration(seconds: 6),
      content: Text(outcome == 'consumed'
          ? 'Good. Nothing wasted.'
          : 'Thrown out and recorded.'),
      action: SnackBarAction(
        label: 'Undo',
        textColor: const Color(0xFFB9E08F),
        onPressed: () async {
          final back = await unsettleFoodItem(id);
          messenger.showSnackBar(SnackBar(
              content: Text(back.isEmpty
                  ? '${name.isEmpty ? 'It' : name} is back in your kitchen.'
                  : back)));
          if (mounted && back.isEmpty) _load(_for, quiet: true);
        },
      ),
    ));
  }

  void _back() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.goNamed('HomePage');
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final t = FlutterFlowTheme.of(context);
    final household = FFAppState().currentHouseholdId;
    if (household.isNotEmpty && household != _for) {
      _for = household;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load(household));
    }

    final count = _items.length;
    Widget content;
    if (_loading) {
      content = Column(children: [
        for (var i = 0; i < 3; i++) ...[
          Container(
            height: 120,
            decoration: BoxDecoration(
                color: _sage, borderRadius: BorderRadius.circular(20)),
          ),
          const SizedBox(height: 12),
        ],
      ]);
    } else if (_offline) {
      content = _message(
          t,
          Icons.cloud_off_outlined,
          'Can’t reach your kitchen.',
          'No signal, or the connection dropped. Try again when you are back online.',
          'Try again',
          () => _load(_for));
    } else if (_items.isEmpty) {
      content = _message(
          t,
          Icons.check_circle_outline,
          'Nothing needs using right now.',
          'When food gets close to its date, it shows here with a quick way to mark it used.',
          'Back to your kitchen',
          () => GoRouter.of(context).goNamed('InventoryPage'));
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in _items) ...[
            _row(t, item),
            const SizedBox(height: 12),
          ],
        ],
      );
    }

    return _uPageBackground(SizedBox(
      width: widget.width,
      height: widget.height,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Semantics(
                button: true,
                label: 'Back',
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _back,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: _uBackDeco(),
                    child:
                        const Icon(Icons.arrow_back, color: _uForest, size: 22),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Use soon.',
                style: t.headlineMedium.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: _uForest)),
            if (!_loading && !_offline && count > 0) ...[
              const SizedBox(height: 4),
              Text(
                  count == 1
                      ? '1 food close to its date'
                      : '$count foods close to their dates',
                  style: t.bodyLarge.copyWith(color: _muted, fontSize: 16)),
              const SizedBox(height: 14),
              _UButton('Find meals that use them',
                  icon: Icons.restaurant_menu,
                  onTap: () => context.pushNamed('RecipesPage')),
            ],
            const SizedBox(height: 20),
            AnimatedSize(
              duration: MediaQuery.of(context).disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              child: content,
            ),
          ],
        ),
      ),
    ));
  }

  /// One compact row: picture, name, amount and place, and the date badge.
  /// Tapping opens the food; the actions sit in a sheet, so the page is not a
  /// wall of equal Used / Throw out buttons (hybrid brief, 15 Sep).
  Widget _row(FlutterFlowTheme t, Map<String, dynamic> item) {
    final id = item['id'].toString();
    final name = (item['name'] ?? '').toString();
    final qty =
        item['quantity'] is num ? (item['quantity'] as num).toDouble() : null;
    final amount = quantityLabel(qty, (item['unit'] ?? '').toString()) ?? '';
    final where = (item['location_name'] ?? '').toString();
    final photo = _uPicture(name, (item['image_url'] ?? '').toString());
    final badge = dateBadge(
          (item['computed_status'] ?? '').toString(),
          item['days_left'] is num ? (item['days_left'] as num).round() : null,
          DateTime.tryParse('${item['printed_date'] ?? ''}'),
          '${item['printed_date_type'] ?? ''}',
          '${item['status_basis'] ?? ''}',
        ) ??
        '';
    final busy = _busy.contains(id);
    return _USurface(
      radius: 20,
      label: '$name. ${badge.split('|').first}',
      onTap: () async {
        await context
            .pushNamed('FoodItemPage', queryParameters: {'itemId': id});
        if (mounted) _load(_for, quiet: true);
      },
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 64,
              height: 64,
              child: photo.isEmpty
                  ? _uFallback(context, name.isEmpty ? '' : name[0], height: 64)
                  : Image.network(photo,
                      fit: BoxFit.cover,
                      cacheWidth: 200,
                      errorBuilder: (_, __, ___) => _uFallback(
                          context, name.isEmpty ? '' : name[0],
                          height: 64)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.titleMedium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _ink)),
                const SizedBox(height: 2),
                Text(
                    [if (amount.isNotEmpty) amount, if (where.isNotEmpty) where]
                        .join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall.copyWith(color: _muted, fontSize: 13)),
                const SizedBox(height: 6),
                _uBadge(context, badge),
              ],
            ),
          ),
          busy
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _uForest)),
                )
              : IconButton(
                  tooltip: 'Actions for $name',
                  icon: const Icon(Icons.more_horiz, color: _uForest),
                  onPressed: () => _actions(t, item),
                ),
        ],
      ),
    );
  }

  Future<void> _actions(FlutterFlowTheme t, Map<String, dynamic> item) async {
    final name = (item['name'] ?? '').toString();
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _uCream,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheet) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(name,
                  style: t.headlineSmall.copyWith(
                      fontSize: 22, fontWeight: FontWeight.w800, color: _uInk)),
              const SizedBox(height: 16),
              _UButton('Used all of it',
                  icon: Icons.check,
                  onTap: () => Navigator.of(sheet).pop('consumed')),
              const SizedBox(height: 10),
              _UButton('Use some, or change details',
                  kind: 'secondary',
                  icon: Icons.tune,
                  onTap: () => Navigator.of(sheet).pop('open')),
              const SizedBox(height: 18),
              Center(
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      foregroundColor: const Color(0xFFB42318)),
                  onPressed: () => Navigator.of(sheet).pop('discarded'),
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: Text('Throw it out',
                      style: t.bodyLarge.copyWith(
                          color: const Color(0xFFB42318),
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'open') {
      await context.pushNamed('FoodItemPage',
          queryParameters: {'itemId': item['id'].toString()});
      if (mounted) _load(_for, quiet: true);
      return;
    }
    if (choice == 'discarded') {
      final sure = await showDialog<bool>(
        context: context,
        builder: (d) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Throw out $name?'),
          content: const Text(
              'It is recorded in What you used. You can undo straight after.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(d).pop(false),
                child: const Text('Keep it')),
            TextButton(
                onPressed: () => Navigator.of(d).pop(true),
                child: const Text('Throw out',
                    style: TextStyle(color: Color(0xFFB42318)))),
          ],
        ),
      );
      if (sure != true || !mounted) return;
    }
    await _settle(item, choice);
  }

  Widget _message(FlutterFlowTheme t, IconData icon, String title, String text,
      String action, VoidCallback onAction) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: _uCard(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          Text(text,
              style: t.bodyLarge
                  .copyWith(fontSize: 16, color: _muted, height: 1.4)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(
                elevation: 3,
                shadowColor: const Color(0x99033C29),
                backgroundColor: _forest,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: onAction,
              child: Text(action,
                  style: t.bodyLarge.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

/// The blurred food background, painted by a screen whose page cannot carry it.
Widget _uPageBackground(Widget child) => Container(
      constraints: const BoxConstraints.expand(),
      decoration: const BoxDecoration(
        color: _uCream,
        image: DecorationImage(
          fit: BoxFit.cover,
          image: NetworkImage(
              'https://cdn.jsdelivr.net/gh/ashelashiry/UseItFresh@66ba49e719ed0981db97df35c60113b284bc8f80/design/hybrid/background.webp'),
        ),
      ),
      child: child,
    );

// ---- Hybrid material (design brief, 15 Sep) --------------------------------
// Cream canvas over a blurred food background (set on the page), sculpted
// cream surfaces, forest gradient primary buttons, calm date badges.

const _uForest = Color(0xFF07533A);
const _uForestTop = Color(0xFF176C50);
const _uInk = Color(0xFF202C24);
const _uMuted = Color(0xFF59665D);
const _uSage = Color(0xFFE6EDDF);
const _uLine = Color(0xFFCDD4C3);
const _uCream = Color(0xFFF7F7F0);

bool _uStill(BuildContext c) => MediaQuery.of(c).disableAnimations;

/// A sculpted cream surface: warm diagonal gradient, thin sage border, a
/// narrow white top highlight, a 2px lower edge and a soft shadow.
class _USurface extends StatelessWidget {
  const _USurface({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = 22,
    this.onTap,
    this.label,
    this.tint,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final String? label;
  final List<Color>? tint;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    final body = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: tint ?? const [Color(0xFFFFFEF9), Color(0xFFF3F3E9)],
        ),
        borderRadius: r,
        border: Border.all(color: _uLine),
        boxShadow: const [
          BoxShadow(color: Color(0xFFD2D8C9), offset: Offset(0, 2)),
          BoxShadow(
              color: Color(0x14263824), offset: Offset(0, 8), blurRadius: 16),
        ],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: Stack(
          children: [
            Padding(padding: padding, child: child),
            // The narrow white highlight along the top edge.
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 1.5,
              child: ColoredBox(color: Color(0xCCFFFFFF)),
            ),
          ],
        ),
      ),
    );
    if (onTap == null) return body;
    return _UPress(onTap: onTap!, label: label, radius: radius, child: body);
  }
}

/// A tap target that sinks 1px while pressed (tonal only with reduced motion).
class _UPress extends StatefulWidget {
  const _UPress({
    required this.child,
    required this.onTap,
    this.label,
    this.radius = 16,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback onTap;
  final String? label;
  final double radius;
  final bool enabled;

  @override
  State<_UPress> createState() => _UPressState();
}

class _UPressState extends State<_UPress> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final still = _uStill(context);
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown:
            widget.enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: widget.enabled ? (_down && still ? 0.85 : 1) : 0.55,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 100),
            offset: _down && !still ? const Offset(0, 0.01) : Offset.zero,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Buttons: one forest primary per task, cream secondaries, quiet text links.
class _UButton extends StatelessWidget {
  const _UButton(
    this.text, {
    required this.onTap,
    this.icon,
    this.kind = 'primary',
    this.busy = false,
    this.trailing = false,
  });

  final String text;
  final VoidCallback? onTap;
  final IconData? icon;
  final String kind; // primary | secondary | danger
  final bool busy;
  final bool trailing;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final primary = kind == 'primary';
    final danger = kind == 'danger';
    final fg = primary
        ? Colors.white
        : (danger ? const Color(0xFFB42318) : _uForest);
    final iconW = icon == null ? null : Icon(icon, size: 20, color: fg);
    final label = Text(text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: t.bodyLarge.copyWith(
            color: fg,
            fontSize: primary ? 16 : 15,
            fontWeight: primary ? FontWeight.w700 : FontWeight.w600));
    final content = busy
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: fg))
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (iconW != null && !trailing) ...[iconW, const SizedBox(width: 8)],
              Flexible(child: label),
              if (iconW != null && trailing) ...[const SizedBox(width: 8), iconW],
            ],
          );
    final box = Container(
      constraints: BoxConstraints(minHeight: primary ? 52 : 48),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: primary
              ? const [_uForestTop, _uForest]
              : const [Color(0xFFFFFEFA), Color(0xFFEDF0E4)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: primary
                ? const Color(0xFF06422E)
                : (danger ? const Color(0xFFEBC5BF) : const Color(0xFFCCD7C2))),
        boxShadow: primary
            ? const [
                BoxShadow(color: Color(0xFF033C29), offset: Offset(0, 3)),
                BoxShadow(
                    color: Color(0x2007533A),
                    offset: Offset(0, 6),
                    blurRadius: 10),
              ]
            : const [BoxShadow(color: Color(0xFFD6DFCC), offset: Offset(0, 2))],
      ),
      child: content,
    );
    return _UPress(
      onTap: onTap ?? () {},
      enabled: onTap != null && !busy,
      label: text,
      child: box,
    );
  }
}

/// The date badge from dateBadge(): "Label|tone".
Widget _uBadge(BuildContext context, String spec, {double size = 12}) {
  if (spec.isEmpty) return const SizedBox.shrink();
  final parts = spec.split('|');
  final tone = parts.length > 1 ? parts[1] : 'calm';
  const tones = <String, (Color, Color)>{
    'urgent': (Color(0xFFFDE3E0), Color(0xFFB42318)),
    'warm': (Color(0xFFFFEAD4), Color(0xFF884311)),
    'calm': (Color(0xFFE6EDDF), Color(0xFF335837)),
    'cold': (Color(0xFFE1ECF7), Color(0xFF285E8E)),
  };
  final c = tones[tone] ?? tones['calm']!;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
        color: c.$1, borderRadius: BorderRadius.circular(8)),
    child: Text(parts.first,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: FlutterFlowTheme.of(context).bodySmall.copyWith(
            color: c.$2, fontSize: size, fontWeight: FontWeight.w600)),
  );
}

/// A compact picture stand-in when no suitable photo exists: the food's name
/// set small and calm, never a borrowed photo of a different food or form.
Widget _uFallback(BuildContext context, String name, {double height = 110}) {
  final t = FlutterFlowTheme.of(context);
  return Container(
    height: height,
    color: const Color(0xFFE4E9D9),
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Text(name.toUpperCase(),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: t.bodyMedium.copyWith(
            color: const Color(0xFF526845),
            letterSpacing: 2,
            fontSize: 14,
            fontWeight: FontWeight.w600)),
  );
}

/// The back control on ordinary pages: a cream square with a forest arrow.
Widget _uBack(BuildContext context, VoidCallback onTap) => _UPress(
      onTap: onTap,
      label: 'Back',
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFCDD6C4)),
          boxShadow: const [
            BoxShadow(color: Color(0xFFD6DFCC), offset: Offset(0, 2))
          ],
        ),
        child: const Icon(Icons.arrow_back, color: _uForest, size: 22),
      ),
    );

/// Which picture a food shows (owner, 15 Sep): by default a fresh-looking
/// photo of that food when one matches it and its form, otherwise the
/// person's own photo or scan. "My photos first" in Profile swaps the order.
String _uPicture(String name, String own) {
  final mine = own.trim();
  final fresh = foodPhoto(name, '') ?? '';
  if (FFAppState().photoPreference == 'own') {
    return mine.isNotEmpty ? mine : fresh;
  }
  return fresh.isNotEmpty ? fresh : mine;
}

/// A food card for the two-column grids: picture, two-line name, amount and
/// the date badge.
Widget _uFoodCard(BuildContext context, Map item, {required VoidCallback onTap}) {
  final t = FlutterFlowTheme.of(context);
  final name = '${item['name'] ?? ''}';
  final photo = _uPicture(name, '${item['image_url'] ?? ''}');
  final qty = item['quantity'] is num ? (item['quantity'] as num).toDouble() : null;
  final amount = quantityLabel(qty, '${item['unit'] ?? ''}') ?? '';
  final badge = dateBadge(
        '${item['computed_status'] ?? ''}',
        item['days_left'] is num ? (item['days_left'] as num).round() : null,
        DateTime.tryParse('${item['printed_date'] ?? ''}'),
        '${item['printed_date_type'] ?? ''}',
        '${item['status_basis'] ?? ''}',
      ) ??
      '';
  return _USurface(
    radius: 20,
    onTap: onTap,
    label: '$name. ${badge.split('|').first}',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 110,
          child: photo.isEmpty
              ? _uFallback(context, name)
              : Image.network(photo,
                  fit: BoxFit.cover,
                  cacheWidth: 480,
                  errorBuilder: (_, __, ___) => _uFallback(context, name)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.titleSmall.copyWith(
                      fontSize: 16,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      color: _uInk)),
              const SizedBox(height: 4),
              Text(amount.isEmpty ? ' ' : amount,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall.copyWith(color: _uMuted, fontSize: 13)),
              const SizedBox(height: 8),
              _uBadge(context, badge),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Food close to its date, the one rule Home, Inventory and Use soon share:
/// past or at its limit, "use soon", or three days or fewer; never frozen.
bool _uSoon(Map item) {
  final status = '${item['computed_status'] ?? ''}';
  if (status == 'frozen' || status == 'consumed' || status == 'discarded') {
    return false;
  }
  if (const {'past_use_by', 'use_today', 'use_soon', 'past_best_before'}
      .contains(status)) {
    return true;
  }
  final d = item['days_left'];
  return d is num && d <= 3;
}

/// The sculpted card as a decoration, for existing layouts.
BoxDecoration _uCard(double radius) => BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFEF9), Color(0xFFF3F3E9)],
      ),
      borderRadius: BorderRadius.circular(radius < 18 ? radius : 22),
      border: Border.all(color: _uLine),
      boxShadow: const [
        BoxShadow(color: Color(0xFFD2D8C9), offset: Offset(0, 2)),
        BoxShadow(color: Color(0x14263824), offset: Offset(0, 8), blurRadius: 16),
      ],
    );

/// The ordinary back control: a cream square with a forest arrow.
BoxDecoration _uBackDeco() => BoxDecoration(
      color: const Color(0xFFFFFDF4),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFCDD6C4)),
      boxShadow: const [BoxShadow(color: Color(0xFFD6DFCC), offset: Offset(0, 2))],
    );
''';

const _wProfileMenu = r'''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Profile settings, grouped and compact.
class ProfileMenu extends StatelessWidget {
  const ProfileMenu({super.key, this.width, this.height});

  final double? width;
  final double? height;

  static const _forest = Color(0xFF07533A);
  static const _ink = Color(0xFF202C24);
  static const _muted = Color(0xFF59665D);
  static const _sage = Color(0xFFEDF2E8);
  static const _border = Color(0xFFDCE3D7);

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    context.watch<FFAppState>();
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _group(context, t, 'You', [
            _Row('My details', Icons.badge_outlined, 'OnboardingPage'),
            _Row('Diet & allergies', Icons.no_food_outlined,
                'FoodPreferencesPage'),
            _Row('Security', Icons.lock_outline, 'UpdatePasswordPage'),
          ]),
          const SizedBox(height: 20),
          _group(context, t, 'Kitchen', [
            _Row('Household', Icons.group_outlined, 'HouseholdSetupPage'),
            _Row('Storage', Icons.kitchen_outlined, 'StorageLocationsPage'),
            _Row('Shopping list', Icons.shopping_cart_outlined,
                'ShoppingListPage'),
            _Row('Receipts', Icons.receipt_long_outlined, 'ReceiptsPage'),
            _Row('Reminders', Icons.notifications_none, 'RemindersPage'),
            _Row('What you used', Icons.insights_outlined, 'WasteHistoryPage'),
          ]),
          const SizedBox(height: 20),
          _group(context, t, 'App', [
            _Row(
                FFAppState().photoPreference == 'own'
                    ? 'Food pictures: my photos first'
                    : 'Food pictures: fresh photos first',
                Icons.image_outlined,
                _pictures),
          ]),
        ],
      ),
    );
  }

  static const _pictures = 'food-pictures';

  /// Owner, 15 Sep: a fresh-looking photo of the food first, or your own
  /// photo or scan first, for everyone's food on this phone.
  Future<void> _openPictures(BuildContext context, FlutterFlowTheme t) async {
    Widget option(BuildContext sheet, String value, String title, String text) {
      final on = (FFAppState().photoPreference == 'own' ? 'own' : 'stock') == value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _USurface(
          radius: 18,
          onTap: () {
            FFAppState().update(() => FFAppState().photoPreference = value);
            Navigator.of(sheet).pop();
          },
          label: title,
          tint: on ? const [Color(0xFFF1F7EC), Color(0xFFE0ECD6)] : null,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(on ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: _uForest),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: t.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700, color: _uInk)),
                    const SizedBox(height: 2),
                    Text(text,
                        style: t.bodySmall
                            .copyWith(color: _uMuted, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _uCream,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheet) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Food pictures',
                  style: t.headlineSmall.copyWith(
                      fontSize: 22, fontWeight: FontWeight.w800, color: _uInk)),
              const SizedBox(height: 14),
              option(sheet, 'stock', 'Fresh photos first',
                  'A fresh, appetising photo of the food when we have one. Your own photo or scan otherwise.'),
              option(sheet, 'own', 'My photos first',
                  'The photo you took or scanned. A fresh photo when there is none.'),
              Text(
                  'Fresh photos are illustrations of the food, not your food. On a food’s screen you can always switch to see the other picture.',
                  style: t.bodySmall.copyWith(color: _uMuted, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _group(BuildContext context, FlutterFlowTheme t, String heading,
      List<_Row> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Semantics(
            header: true,
            child: Text(heading,
                style: t.bodyMedium.copyWith(
                    fontSize: 14, fontWeight: FontWeight.w700, color: _muted)),
          ),
        ),
        Container(
          decoration: _uCard(20),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0)
                  const Divider(
                      height: 1, thickness: 1, indent: 64, color: _border),
                _tile(context, t, rows[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _tile(BuildContext context, FlutterFlowTheme t, _Row row) {
    return Semantics(
      button: true,
      label: row.title,
      excludeSemantics: true,
      child: InkWell(
        onTap: () => row.route == _pictures
            ? _openPictures(context, t)
            : context.pushNamed(row.route),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: _sage, borderRadius: BorderRadius.circular(12)),
                  child: Icon(row.icon, color: _forest, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(row.title,
                      style: t.bodyLarge.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _ink)),
                ),
                const Icon(Icons.chevron_right, color: _muted, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Row {
  const _Row(this.title, this.icon, this.route);
  final String title;
  final IconData icon;
  final String route;
}

// ---- Hybrid material (design brief, 15 Sep) --------------------------------
// Cream canvas over a blurred food background (set on the page), sculpted
// cream surfaces, forest gradient primary buttons, calm date badges.

const _uForest = Color(0xFF07533A);
const _uForestTop = Color(0xFF176C50);
const _uInk = Color(0xFF202C24);
const _uMuted = Color(0xFF59665D);
const _uSage = Color(0xFFE6EDDF);
const _uLine = Color(0xFFCDD4C3);
const _uCream = Color(0xFFF7F7F0);

bool _uStill(BuildContext c) => MediaQuery.of(c).disableAnimations;

/// A sculpted cream surface: warm diagonal gradient, thin sage border, a
/// narrow white top highlight, a 2px lower edge and a soft shadow.
class _USurface extends StatelessWidget {
  const _USurface({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = 22,
    this.onTap,
    this.label,
    this.tint,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final String? label;
  final List<Color>? tint;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    final body = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: tint ?? const [Color(0xFFFFFEF9), Color(0xFFF3F3E9)],
        ),
        borderRadius: r,
        border: Border.all(color: _uLine),
        boxShadow: const [
          BoxShadow(color: Color(0xFFD2D8C9), offset: Offset(0, 2)),
          BoxShadow(
              color: Color(0x14263824), offset: Offset(0, 8), blurRadius: 16),
        ],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: Stack(
          children: [
            Padding(padding: padding, child: child),
            // The narrow white highlight along the top edge.
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 1.5,
              child: ColoredBox(color: Color(0xCCFFFFFF)),
            ),
          ],
        ),
      ),
    );
    if (onTap == null) return body;
    return _UPress(onTap: onTap!, label: label, radius: radius, child: body);
  }
}

/// A tap target that sinks 1px while pressed (tonal only with reduced motion).
class _UPress extends StatefulWidget {
  const _UPress({
    required this.child,
    required this.onTap,
    this.label,
    this.radius = 16,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback onTap;
  final String? label;
  final double radius;
  final bool enabled;

  @override
  State<_UPress> createState() => _UPressState();
}

class _UPressState extends State<_UPress> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final still = _uStill(context);
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown:
            widget.enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: widget.enabled ? (_down && still ? 0.85 : 1) : 0.55,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 100),
            offset: _down && !still ? const Offset(0, 0.01) : Offset.zero,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Buttons: one forest primary per task, cream secondaries, quiet text links.
class _UButton extends StatelessWidget {
  const _UButton(
    this.text, {
    required this.onTap,
    this.icon,
    this.kind = 'primary',
    this.busy = false,
    this.trailing = false,
  });

  final String text;
  final VoidCallback? onTap;
  final IconData? icon;
  final String kind; // primary | secondary | danger
  final bool busy;
  final bool trailing;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final primary = kind == 'primary';
    final danger = kind == 'danger';
    final fg = primary
        ? Colors.white
        : (danger ? const Color(0xFFB42318) : _uForest);
    final iconW = icon == null ? null : Icon(icon, size: 20, color: fg);
    final label = Text(text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: t.bodyLarge.copyWith(
            color: fg,
            fontSize: primary ? 16 : 15,
            fontWeight: primary ? FontWeight.w700 : FontWeight.w600));
    final content = busy
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: fg))
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (iconW != null && !trailing) ...[iconW, const SizedBox(width: 8)],
              Flexible(child: label),
              if (iconW != null && trailing) ...[const SizedBox(width: 8), iconW],
            ],
          );
    final box = Container(
      constraints: BoxConstraints(minHeight: primary ? 52 : 48),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: primary
              ? const [_uForestTop, _uForest]
              : const [Color(0xFFFFFEFA), Color(0xFFEDF0E4)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: primary
                ? const Color(0xFF06422E)
                : (danger ? const Color(0xFFEBC5BF) : const Color(0xFFCCD7C2))),
        boxShadow: primary
            ? const [
                BoxShadow(color: Color(0xFF033C29), offset: Offset(0, 3)),
                BoxShadow(
                    color: Color(0x2007533A),
                    offset: Offset(0, 6),
                    blurRadius: 10),
              ]
            : const [BoxShadow(color: Color(0xFFD6DFCC), offset: Offset(0, 2))],
      ),
      child: content,
    );
    return _UPress(
      onTap: onTap ?? () {},
      enabled: onTap != null && !busy,
      label: text,
      child: box,
    );
  }
}

/// The date badge from dateBadge(): "Label|tone".
Widget _uBadge(BuildContext context, String spec, {double size = 12}) {
  if (spec.isEmpty) return const SizedBox.shrink();
  final parts = spec.split('|');
  final tone = parts.length > 1 ? parts[1] : 'calm';
  const tones = <String, (Color, Color)>{
    'urgent': (Color(0xFFFDE3E0), Color(0xFFB42318)),
    'warm': (Color(0xFFFFEAD4), Color(0xFF884311)),
    'calm': (Color(0xFFE6EDDF), Color(0xFF335837)),
    'cold': (Color(0xFFE1ECF7), Color(0xFF285E8E)),
  };
  final c = tones[tone] ?? tones['calm']!;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
        color: c.$1, borderRadius: BorderRadius.circular(8)),
    child: Text(parts.first,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: FlutterFlowTheme.of(context).bodySmall.copyWith(
            color: c.$2, fontSize: size, fontWeight: FontWeight.w600)),
  );
}

/// A compact picture stand-in when no suitable photo exists: the food's name
/// set small and calm, never a borrowed photo of a different food or form.
Widget _uFallback(BuildContext context, String name, {double height = 110}) {
  final t = FlutterFlowTheme.of(context);
  return Container(
    height: height,
    color: const Color(0xFFE4E9D9),
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Text(name.toUpperCase(),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: t.bodyMedium.copyWith(
            color: const Color(0xFF526845),
            letterSpacing: 2,
            fontSize: 14,
            fontWeight: FontWeight.w600)),
  );
}

/// The back control on ordinary pages: a cream square with a forest arrow.
Widget _uBack(BuildContext context, VoidCallback onTap) => _UPress(
      onTap: onTap,
      label: 'Back',
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFCDD6C4)),
          boxShadow: const [
            BoxShadow(color: Color(0xFFD6DFCC), offset: Offset(0, 2))
          ],
        ),
        child: const Icon(Icons.arrow_back, color: _uForest, size: 22),
      ),
    );

/// Which picture a food shows (owner, 15 Sep): by default a fresh-looking
/// photo of that food when one matches it and its form, otherwise the
/// person's own photo or scan. "My photos first" in Profile swaps the order.
String _uPicture(String name, String own) {
  final mine = own.trim();
  final fresh = foodPhoto(name, '') ?? '';
  if (FFAppState().photoPreference == 'own') {
    return mine.isNotEmpty ? mine : fresh;
  }
  return fresh.isNotEmpty ? fresh : mine;
}

/// A food card for the two-column grids: picture, two-line name, amount and
/// the date badge.
Widget _uFoodCard(BuildContext context, Map item, {required VoidCallback onTap}) {
  final t = FlutterFlowTheme.of(context);
  final name = '${item['name'] ?? ''}';
  final photo = _uPicture(name, '${item['image_url'] ?? ''}');
  final qty = item['quantity'] is num ? (item['quantity'] as num).toDouble() : null;
  final amount = quantityLabel(qty, '${item['unit'] ?? ''}') ?? '';
  final badge = dateBadge(
        '${item['computed_status'] ?? ''}',
        item['days_left'] is num ? (item['days_left'] as num).round() : null,
        DateTime.tryParse('${item['printed_date'] ?? ''}'),
        '${item['printed_date_type'] ?? ''}',
        '${item['status_basis'] ?? ''}',
      ) ??
      '';
  return _USurface(
    radius: 20,
    onTap: onTap,
    label: '$name. ${badge.split('|').first}',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 110,
          child: photo.isEmpty
              ? _uFallback(context, name)
              : Image.network(photo,
                  fit: BoxFit.cover,
                  cacheWidth: 480,
                  errorBuilder: (_, __, ___) => _uFallback(context, name)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.titleSmall.copyWith(
                      fontSize: 16,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      color: _uInk)),
              const SizedBox(height: 4),
              Text(amount.isEmpty ? ' ' : amount,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall.copyWith(color: _uMuted, fontSize: 13)),
              const SizedBox(height: 8),
              _uBadge(context, badge),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Food close to its date, the one rule Home, Inventory and Use soon share:
/// past or at its limit, "use soon", or three days or fewer; never frozen.
bool _uSoon(Map item) {
  final status = '${item['computed_status'] ?? ''}';
  if (status == 'frozen' || status == 'consumed' || status == 'discarded') {
    return false;
  }
  if (const {'past_use_by', 'use_today', 'use_soon', 'past_best_before'}
      .contains(status)) {
    return true;
  }
  final d = item['days_left'];
  return d is num && d <= 3;
}

/// The sculpted card as a decoration, for existing layouts.
BoxDecoration _uCard(double radius) => BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFEF9), Color(0xFFF3F3E9)],
      ),
      borderRadius: BorderRadius.circular(radius < 18 ? radius : 22),
      border: Border.all(color: _uLine),
      boxShadow: const [
        BoxShadow(color: Color(0xFFD2D8C9), offset: Offset(0, 2)),
        BoxShadow(color: Color(0x14263824), offset: Offset(0, 8), blurRadius: 16),
      ],
    );

/// The ordinary back control: a cream square with a forest arrow.
BoxDecoration _uBackDeco() => BoxDecoration(
      color: const Color(0xFFFFFDF4),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFCDD6C4)),
      boxShadow: const [BoxShadow(color: Color(0xFFD6DFCC), offset: Offset(0, 2))],
    );
''';

