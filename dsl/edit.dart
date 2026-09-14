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

/// Paid feature, first: Plan my week, with Cook once, eat twice and
/// "I ate this" (owner, 14 Sep).
///
/// PlanWeekPage shows the next seven days. Meals are added from ideas already
/// on Recipes or kept ideas, or found for that meal there and then; they can
/// be swapped, moved, skipped, cooked with extra portions (and the leftovers
/// planned for the next day's lunch), or taken off. One button adds what the
/// week's meals still need to the shopping list.
///
/// "I ate this": confirm portions, untick any food with some left, confirm.
/// The meal is logged for this person only, the plan marks it eaten, and the
/// ticked foods leave the kitchen, with Undo for all of it.
///
/// Recipes gets a "Plan my week" link above the filters and "Add to my week"
/// on every idea. Needs migration 7 (meal_plan_entries, meal_log_entries);
/// until it is run, the screen says it is almost ready instead of failing.
void buildStarterEditFlow(App app) {
  app.customWidget(
    'WeekPlan',
    parameters: {},
    description:
        'Plan my week: the next seven days of meals for the household, swaps, '
        'extra portions, the week\'s shopping, and "I ate this".',
    code: _weekPlan,
  );
  app.raw((project) {
    updateCustomWidget(project, name: 'RecipesHome', code: _recipesHome);
  });
  app.ensurePage(
    'PlanWeekPage',
    route: '/plan-week',
    description: 'Plan my week: meals for the next seven days.',
    body: Scaffold(
      body: CustomWidget(
        widgetName: 'WeekPlan',
        name: 'WeekPlanView',
        arguments: {},
      ),
    ),
  );
}

const _weekPlan = r'''
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Plan my week (owner, 14 Sep; a Plus feature).
///
/// The next seven days, one card each. Meals come from ideas already on
/// Recipes or kept ideas, so every plan starts from the food in the kitchen.
/// A planned meal can be swapped, moved, cooked with extra portions for
/// another day, or removed. One button puts everything the week still needs
/// on the shopping list.
///
/// "I ate this" is where planned becomes eaten: portions are confirmed, the
/// meal is logged for this person only, and the foods it used up leave the
/// kitchen — each one can be unticked first, and all of it can be undone.
/// Planned and eaten are kept in separate tables and never mixed.
class WeekPlan extends StatefulWidget {
  const WeekPlan({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<WeekPlan> createState() => _WeekPlanState();
}

class _Entry {
  _Entry(Map m)
      : id = m['id'].toString(),
        date = DateTime.parse(m['plan_date'].toString()),
        meal = (m['meal'] ?? 'dinner').toString(),
        title = (m['title'] ?? '').toString(),
        data = m['recipe_data'] is Map ? m['recipe_data'] as Map : const {},
        servings = m['servings'] is num ? (m['servings'] as num).round() : 2,
        extra = m['extra_portions'] is num
            ? (m['extra_portions'] as num).round()
            : 0,
        status = (m['status'] ?? 'planned').toString();

  final String id;
  final DateTime date;
  final String meal;
  final String title;
  final Map data;
  final int servings;
  final int extra;
  final String status;

  List<String> list(String key) => data[key] is List
      ? [
          for (final w in data[key] as List)
            if ('$w'.trim().isNotEmpty) '$w'.trim()
        ]
      : <String>[];
  int number(String key) =>
      data[key] is num ? (data[key] as num).round() : 0;
}

class _WeekPlanState extends State<WeekPlan> {
  static const _forest = Color(0xFF07533A);
  static const _ink = Color(0xFF202C24);
  static const _muted = Color(0xFF59665D);
  static const _sage = Color(0xFFEDF2E8);
  static const _border = Color(0xFFDCE3D7);
  static const _cream = Color(0xFFF7F7F0);
  static const _red = Color(0xFFB42318);

  static const _meals = <String, String>{
    'breakfast': 'Breakfast',
    'lunch': 'Lunch',
    'dinner': 'Dinner',
    'snack': 'Snack',
  };
  static const _mealOrder = ['breakfast', 'lunch', 'dinner', 'snack'];
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  String _for = '';
  bool _loading = true;
  bool _offline = false;
  bool _notReady = false;
  bool _busy = false;
  List<_Entry> _entries = const [];
  List<MealIdeaStruct> _kept = const [];

  static DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// "today", "tomorrow" or "Wed 17 Sep", for the middle of a sentence.
  static String _onDay(DateTime d) {
    final name = _dayName(d);
    return name == 'Today' || name == 'Tomorrow' ? name.toLowerCase() : name;
  }

  static String _dayName(DateTime d) {
    final diff = d.difference(_today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return '${_days[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';
  }

  // ---- data ----------------------------------------------------------------

  Future<void> _load(String household, {bool quiet = false}) async {
    if (!quiet && mounted) {
      setState(() {
        _loading = true;
        _offline = false;
      });
    }
    try {
      final rows = await SupaFlow.client
          .from('meal_plan_entries')
          .select(
              'id, plan_date, meal, title, recipe_data, servings, extra_portions, status')
          .eq('household_id', household)
          .gte('plan_date', _iso(_today))
          .lte('plan_date', _iso(_today.add(const Duration(days: 6))))
          .order('plan_date');
      final kept = await SupaFlow.client
          .from('saved_recipes')
          .select('title, recipe_data')
          .eq('household_id', household)
          .order('created_at', ascending: false)
          .limit(20);
      final entries = [for (final r in rows as List) _Entry(r as Map)]
        ..sort((a, b) {
          final byDay = a.date.compareTo(b.date);
          return byDay != 0
              ? byDay
              : _mealOrder.indexOf(a.meal).compareTo(_mealOrder.indexOf(b.meal));
        });
      final ideas = <MealIdeaStruct>[];
      for (final r in kept as List) {
        final m = r as Map;
        final d = m['recipe_data'] is Map ? m['recipe_data'] as Map : const {};
        ideas.add(_idea((m['title'] ?? '').toString(), d));
      }
      if (!mounted || household != _for) return;
      setState(() {
        _entries = entries;
        _kept = ideas;
        _loading = false;
        _offline = false;
        _notReady = false;
      });
    } on PostgrestException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        // The table is created by a one-off database step.
        _notReady = error.code == '42P01' || error.code == 'PGRST205';
        _offline = !_notReady;
      });
    } catch (_) {
      if (!mounted) return;
      if (quiet && _entries.isNotEmpty) return;
      setState(() {
        _loading = false;
        _offline = true;
      });
    }
  }

  static MealIdeaStruct _idea(String title, Map d) {
    List<String> words(Object? v) => v is List
        ? [
            for (final w in v)
              if ('$w'.trim().isNotEmpty) '$w'.trim()
          ]
        : <String>[];
    int n(Object? v) => v is num ? v.round() : 0;
    return MealIdeaStruct(
      title: title,
      uses: words(d['uses']),
      extras: words(d['extras']),
      steps: words(d['steps']),
      minutes: n(d['minutes']),
      servings: n(d['servings']),
      calories: n(d['calories']),
      protein: n(d['protein']),
    );
  }

  static Map<String, dynamic> _data(MealIdeaStruct idea) => {
        'uses': idea.uses,
        'extras': idea.extras,
        'steps': idea.steps,
        'minutes': idea.minutes,
        if (idea.calories > 0) 'calories': idea.calories,
        if (idea.protein > 0) 'protein': idea.protein,
      };

  void _say(String text, {SnackBarAction? action}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(text),
          action: action,
          duration: Duration(seconds: action == null ? 4 : 6)));

  String _why(Object error) {
    if (error is PostgrestException && error.code == '42501') {
      return 'Your account is not allowed to change this household’s plan.';
    }
    return 'Could not save that. Check your signal and try again.';
  }

  Future<bool> _write(Future<void> Function() change) async {
    if (_busy) return false;
    setState(() => _busy = true);
    try {
      await change();
      await _load(_for, quiet: true);
      return true;
    } catch (error) {
      if (mounted) _say(_why(error));
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _add(DateTime day, String meal, MealIdeaStruct idea) async {
    final people = FFAppState().ideasServings;
    final ok = await _write(() => SupaFlow.client.from('meal_plan_entries').insert({
          'household_id': _for,
          'plan_date': _iso(day),
          'meal': meal,
          'title': idea.title,
          'recipe_data': _data(idea),
          'servings': idea.servings > 0
              ? idea.servings
              : (people < 1 ? 2 : (people > 12 ? 12 : people)),
          'created_by': SupaFlow.client.auth.currentUser?.id,
        }));
    if (ok && mounted) _say('${idea.title} planned for ${_onDay(day)}.');
  }

  Future<void> _swap(_Entry entry, MealIdeaStruct idea) async {
    final ok = await _write(() => SupaFlow.client
        .from('meal_plan_entries')
        .update({'title': idea.title, 'recipe_data': _data(idea)}).eq(
            'id', entry.id));
    if (ok && mounted) _say('Swapped for ${idea.title}.');
  }

  Future<void> _update(_Entry entry, Map<String, dynamic> change) =>
      _write(() => SupaFlow.client
          .from('meal_plan_entries')
          .update(change)
          .eq('id', entry.id));

  Future<void> _remove(_Entry entry) async {
    final ok = await _write(() =>
        SupaFlow.client.from('meal_plan_entries').delete().eq('id', entry.id));
    if (ok && mounted) _say('${entry.title} taken off the plan.');
  }

  /// Cook once, eat twice: the leftovers become a lunch the next day.
  Future<void> _planLeftovers(_Entry entry) async {
    final next = entry.date.add(const Duration(days: 1));
    final ok = await _write(() => SupaFlow.client.from('meal_plan_entries').insert({
          'household_id': _for,
          'plan_date': _iso(next),
          'meal': 'lunch',
          'title': 'Leftover ${entry.title}'.length > 120
              ? entry.title
              : 'Leftover ${entry.title}',
          'recipe_data': {
            ...entry.data,
            'extras': <String>[],
            'leftoverOf': entry.id,
            'steps': ['Reheat the extra portions from ${_dayName(entry.date)}.'],
          },
          'servings': entry.extra < 1 ? 1 : entry.extra,
          'created_by': SupaFlow.client.auth.currentUser?.id,
        }));
    if (ok && mounted) _say('Leftovers planned for ${_onDay(next)}’s lunch.');
  }

  /// Everything the planned meals still need, once each.
  List<String> get _needed {
    final seen = <String>{};
    final out = <String>[];
    for (final e in _entries.where((e) => e.status == 'planned')) {
      for (final x in e.list('extras')) {
        if (seen.add(x.toLowerCase())) out.add(x);
      }
    }
    return out;
  }

  Future<void> _shop() async {
    final needed = _needed;
    if (needed.isEmpty || _busy) return;
    setState(() => _busy = true);
    var added = 0;
    try {
      for (final name in needed) {
        final said = await addNameToShoppingList(name);
        if (said.isNotEmpty) {
          if (mounted) _say(said);
          return;
        }
        added++;
      }
      if (mounted) {
        _say(added == 1
            ? '1 thing is on your shopping list.'
            : '$added things are on your shopping list.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---- page ----------------------------------------------------------------

  void _back() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.goNamed('RecipesPage');
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

    Widget content;
    if (household.isEmpty) {
      content = _message(t, Icons.group_outlined, 'No household yet.',
          'Create or join a household first, then plan meals together.', null);
    } else if (_loading) {
      content = Column(children: [
        for (var i = 0; i < 4; i++) ...[
          Container(
            height: 96,
            decoration: BoxDecoration(
                color: _sage, borderRadius: BorderRadius.circular(20)),
          ),
          const SizedBox(height: 12),
        ],
      ]);
    } else if (_notReady) {
      content = _message(
          t,
          Icons.construction_outlined,
          'Plan my week is almost ready.',
          'It needs one more setup step on our side. Try again soon.',
          () => _load(_for));
    } else if (_offline) {
      content = _message(
          t,
          Icons.cloud_off_outlined,
          'Can’t reach your plan.',
          'No signal, or the connection dropped. Try again when you are back online.',
          () => _load(_for));
    } else {
      final needed = _needed;
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < 7; i++) ...[
            _dayCard(t, _today.add(Duration(days: i))),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
          _shoppingCard(t, needed),
        ],
      );
    }

    final planned = _entries.where((e) => e.status == 'planned').length;
    return SizedBox(
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
                    decoration: const BoxDecoration(
                        color: _forest, shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Plan my week.',
                style: t.headlineMedium.copyWith(
                    fontSize: 32, fontWeight: FontWeight.w800, color: _ink)),
            const SizedBox(height: 4),
            Text(
                _loading || _offline || _notReady
                    ? 'The next seven days, shared with your household.'
                    : (planned == 0
                        ? 'Nothing planned yet. Add a meal to any day.'
                        : (planned == 1
                            ? '1 meal planned, shared with your household.'
                            : '$planned meals planned, shared with your household.')),
                style: t.bodyLarge.copyWith(color: _muted, fontSize: 16)),
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
    );
  }

  Widget _dayCard(FlutterFlowTheme t, DateTime day) {
    final meals = _entries.where((e) => _sameDay(e.date, day)).toList();
    final isToday = _sameDay(day, _today);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isToday ? _forest : _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(_dayName(day),
                    style: t.titleMedium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _ink)),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                    minimumSize: const Size(48, 44),
                    foregroundColor: _forest),
                onPressed: _busy ? null : () => _openPicker(t, day: day),
                icon: const Icon(Icons.add, size: 18),
                label: Text('Add a meal',
                    style: t.bodyMedium.copyWith(
                        color: _forest, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          if (meals.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, right: 8),
              child: Text('Nothing planned',
                  style: t.bodyMedium.copyWith(color: _muted, fontSize: 14)),
            ),
          for (final e in meals) _entryRow(t, e),
        ],
      ),
    );
  }

  Widget _entryRow(FlutterFlowTheme t, _Entry e) {
    final goals = FFAppState().ideasGoals;
    final minutes = e.number('minutes');
    final kcal = e.number('calories');
    final meta = [
      _meals[e.meal] ?? 'Dinner',
      if (minutes > 0) '$minutes min',
      'Serves ${e.servings}',
      if (e.extra > 0) '+${e.extra} extra',
      if (goals && kcal > 0) '$kcal kcal',
    ].join(' · ');
    final done = e.status != 'planned';
    return Semantics(
      button: true,
      label: e.title,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _busy ? null : () => _openEntry(t, e),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: done ? _forest : _sage,
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(
                    e.status == 'cooked'
                        ? Icons.check
                        : (e.status == 'skipped'
                            ? Icons.remove
                            : Icons.restaurant_outlined),
                    color: done ? Colors.white : _forest,
                    size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodyLarge.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                            decoration:
                                done ? TextDecoration.lineThrough : null)),
                    Text(
                        e.status == 'cooked'
                            ? 'Eaten · $meta'
                            : (e.status == 'skipped' ? 'Skipped · $meta' : meta),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            t.bodySmall.copyWith(color: _muted, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _muted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shoppingCard(FlutterFlowTheme t, List<String> needed) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _sage,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Shopping for the week',
              style: t.titleMedium.copyWith(
                  fontSize: 18, fontWeight: FontWeight.w800, color: _ink)),
          const SizedBox(height: 4),
          Text(
              needed.isEmpty
                  ? 'The planned meals need nothing beyond your kitchen.'
                  : needed.join(', '),
              style: t.bodyMedium.copyWith(color: _muted, fontSize: 14)),
          if (needed.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _forest,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _busy ? null : _shop,
                icon: const Icon(Icons.add_shopping_cart, size: 20),
                label: Text(
                    needed.length == 1
                        ? 'Add 1 thing to the shopping list'
                        : 'Add ${needed.length} things to the shopping list',
                    style: t.bodyLarge.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---- sheets --------------------------------------------------------------

  Future<T?> _sheet<T>(Widget Function(BuildContext, StateSetter) build) =>
      showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        backgroundColor: _cream,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (sheet) => StatefulBuilder(
          builder: (sheet, redraw) => ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheet).size.height * 0.88),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: _border,
                            borderRadius: BorderRadius.circular(999)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    build(sheet, redraw),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  /// Add a meal to a day, or (with [swapFor]) pick what replaces one.
  Future<void> _openPicker(FlutterFlowTheme t,
      {required DateTime day, _Entry? swapFor}) async {
    var meal = swapFor?.meal ?? 'dinner';
    var finding = false;
    await _sheet<void>((sheet, redraw) {
      final now = FFAppState().mealIdeas;
      Widget ideaTile(MealIdeaStruct idea) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.of(sheet).pop();
                if (swapFor != null) {
                  _swap(swapFor, idea);
                } else {
                  _add(day, meal, idea);
                }
              },
              child: Container(
                constraints: const BoxConstraints(minHeight: 56),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(idea.title,
                              style: t.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w700, color: _ink)),
                          Text(
                              [
                                if (idea.minutes > 0) '${idea.minutes} min',
                                if (idea.extras.isEmpty)
                                  'Only your food'
                                else
                                  'Needs ${idea.extras.length} more',
                                if (FFAppState().ideasGoals &&
                                    idea.calories > 0)
                                  '${idea.calories} kcal',
                              ].join(' · '),
                              style: t.bodySmall
                                  .copyWith(color: _muted, fontSize: 13)),
                        ],
                      ),
                    ),
                    const Icon(Icons.add_circle_outline, color: _forest),
                  ],
                ),
              ),
            ),
          );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
              swapFor != null
                  ? 'Swap ${swapFor.title}'
                  : 'Add to ${_onDay(day)}',
              style: t.headlineSmall.copyWith(
                  fontSize: 24, fontWeight: FontWeight.w800, color: _ink)),
          if (swapFor == null) ...[
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final e in _meals.entries)
                _choice(t, e.value, meal == e.key,
                    () => redraw(() => meal = e.key)),
            ]),
          ],
          const SizedBox(height: 20),
          if (now.isNotEmpty) ...[
            _label(t, 'Ideas from your food now'),
            for (final idea in now) ideaTile(idea),
            const SizedBox(height: 12),
          ],
          if (_kept.isNotEmpty) ...[
            _label(t, 'Kept ideas'),
            for (final idea in _kept) ideaTile(idea),
            const SizedBox(height: 12),
          ],
          if (now.isEmpty && _kept.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                  'No ideas yet. Find some from the food in your kitchen.',
                  style: t.bodyLarge.copyWith(color: _muted, fontSize: 16)),
            ),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: _forest,
                backgroundColor: Colors.white,
                side: const BorderSide(color: _border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: finding
                  ? null
                  : () async {
                      redraw(() => finding = true);
                      if (swapFor == null) {
                        FFAppState().update(() => FFAppState().ideasMeal = meal);
                      }
                      final said = await getMealIdeas();
                      if (!mounted) return;
                      if (said.isNotEmpty) _say(said);
                      try {
                        redraw(() => finding = false);
                      } catch (_) {}
                    },
              icon: finding
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _forest))
                  : const Icon(Icons.auto_awesome_outlined, size: 20),
              label: Text(finding ? 'Looking through your kitchen…' : 'Find new ideas',
                  style: t.bodyLarge.copyWith(
                      color: _forest, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      );
    });
  }

  Future<void> _openEntry(FlutterFlowTheme t, _Entry e) async {
    final uses = e.list('uses');
    final extras = e.list('extras');
    final steps = e.list('steps');
    await _sheet<void>((sheet, redraw) {
      void act(VoidCallback then) {
        Navigator.of(sheet).pop();
        then();
      }

      Widget action(IconData icon, String label, VoidCallback onTap,
              {Color colour = _forest}) =>
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            minVerticalPadding: 12,
            leading: Icon(icon, color: colour),
            title: Text(label,
                style: t.bodyLarge.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colour == _forest ? _ink : colour)),
            onTap: onTap,
          );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(e.title,
              style: t.headlineSmall.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                  height: 1.15)),
          const SizedBox(height: 4),
          Text(
              [
                '${_meals[e.meal] ?? 'Dinner'}, ${_onDay(e.date)}',
                if (e.number('minutes') > 0) '${e.number('minutes')} min',
                'Serves ${e.servings}',
              ].join(' · '),
              style: t.bodyMedium.copyWith(color: _muted, fontSize: 14)),
          if (e.status == 'planned') ...[
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
                onPressed: () => act(() => _openAte(t, e)),
                icon: const Icon(Icons.check, size: 20),
                label: Text('I ate this',
                    style: t.bodyLarge.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Cook once, eat twice.
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cook extra portions',
                              style: t.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w700, color: _ink)),
                          Text('Cook once, eat twice',
                              style: t.bodySmall
                                  .copyWith(color: _muted, fontSize: 13)),
                        ],
                      ),
                    ),
                    _stepper(Icons.remove, e.extra > 0,
                        () => act(() => _update(e, {'extra_portions': e.extra - 1}))),
                    SizedBox(
                      width: 36,
                      child: Text('${e.extra}',
                          textAlign: TextAlign.center,
                          style: t.titleMedium.copyWith(color: _ink)),
                    ),
                    _stepper(Icons.add, e.extra < 6,
                        () => act(() => _update(e, {'extra_portions': e.extra + 1}))),
                  ],
                ),
                if (e.extra > 0 && e.data['leftoverOf'] == null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                          minimumSize: const Size(48, 44),
                          foregroundColor: _forest),
                      onPressed: () => act(() => _planLeftovers(e)),
                      icon: const Icon(Icons.event_repeat, size: 18),
                      label: Text(
                          'Plan the leftovers for ${_onDay(e.date.add(const Duration(days: 1)))}’s lunch',
                          style: t.bodyMedium.copyWith(
                              color: _forest, fontWeight: FontWeight.w700)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (e.status == 'planned')
            action(Icons.swap_horiz, 'Swap for another idea',
                () => act(() => _openPicker(t, day: e.date, swapFor: e))),
          action(Icons.event_outlined, 'Move to another day',
              () => act(() => _openMove(t, e))),
          if (e.status != 'planned')
            action(Icons.undo, 'Mark as still to cook',
                () => act(() => _update(e, {'status': 'planned', 'cooked_at': null}))),
          if (e.status == 'planned')
            action(Icons.remove_circle_outline, 'Skip it this time',
                () => act(() => _update(e, {'status': 'skipped'}))),
          action(Icons.delete_outline, 'Take off the plan',
              () => act(() => _remove(e)),
              colour: _red),
          if (uses.isNotEmpty) ...[
            const SizedBox(height: 12),
            _label(t, 'From your kitchen'),
            Text(uses.join(', '),
                style: t.bodyLarge.copyWith(color: _ink, fontSize: 16)),
          ],
          if (extras.isNotEmpty) ...[
            const SizedBox(height: 12),
            _label(t, 'You would also need'),
            Text(extras.join(', '),
                style: t.bodyLarge.copyWith(color: _ink, fontSize: 16)),
          ],
          if (steps.isNotEmpty) ...[
            const SizedBox(height: 12),
            _label(t, 'Steps'),
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('${i + 1}. ${steps[i]}',
                    style: t.bodyLarge
                        .copyWith(color: _ink, fontSize: 16, height: 1.4)),
              ),
          ],
        ],
      );
    });
  }

  Future<void> _openMove(FlutterFlowTheme t, _Entry e) async {
    await _sheet<void>((sheet, redraw) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Move ${e.title}',
                style: t.headlineSmall.copyWith(
                    fontSize: 24, fontWeight: FontWeight.w800, color: _ink)),
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (var i = 0; i < 7; i++)
                _choice(
                    t,
                    _dayName(_today.add(Duration(days: i))),
                    _sameDay(e.date, _today.add(Duration(days: i))), () {
                  Navigator.of(sheet).pop();
                  _update(e, {'plan_date': _iso(_today.add(Duration(days: i)))});
                }),
            ]),
          ],
        ));
  }

  /// Pick a meal → cook it → confirm portions → "I ate this".
  Future<void> _openAte(FlutterFlowTheme t, _Entry e) async {
    // The kitchen foods this meal uses, ticked to leave the kitchen.
    var foods = <({String id, String name})>[];
    try {
      final rows = await SupaFlow.client
          .from('food_items_status')
          .select('id, name, computed_status')
          .eq('household_id', _for)
          .limit(200);
      final uses = e.list('uses').map((u) => u.toLowerCase()).toList();
      for (final r in rows as List) {
        final m = r as Map;
        final status = (m['computed_status'] ?? '').toString();
        if (status == 'consumed' || status == 'discarded') continue;
        final name = (m['name'] ?? '').toString();
        final n = name.toLowerCase();
        if (n.isEmpty) continue;
        if (uses.any((u) => n == u || n.contains(u) || u.contains(n))) {
          foods.add((id: m['id'].toString(), name: name));
        }
      }
    } catch (_) {
      foods = [];
    }
    if (!mounted) return;
    final ticked = {for (final f in foods) f.id};
    var portions = 1.0;
    final kcal = e.number('calories');
    final protein = e.number('protein');
    final goals = FFAppState().ideasGoals;

    final confirmed = await _sheet<bool>((sheet, redraw) {
      String amount(double p) =>
          p == p.roundToDouble() ? p.round().toString() : p.toStringAsFixed(1);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('I ate this',
              style: t.headlineSmall.copyWith(
                  fontSize: 26, fontWeight: FontWeight.w800, color: _ink)),
          const SizedBox(height: 4),
          Text(e.title,
              style: t.bodyLarge.copyWith(color: _muted, fontSize: 16)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _label(t, 'How much did you have?')),
              _stepper(Icons.remove, portions > 0.5,
                  () => redraw(() => portions -= 0.5)),
              SizedBox(
                width: 96,
                child: Text(
                    portions == 1 ? '1 portion' : '${amount(portions)} portions',
                    textAlign: TextAlign.center,
                    style: t.titleSmall.copyWith(color: _ink)),
              ),
              _stepper(Icons.add, portions < 4,
                  () => redraw(() => portions += 0.5)),
            ],
          ),
          if (goals && kcal > 0) ...[
            const SizedBox(height: 8),
            Text(
                'About ${(kcal * portions).round()} kcal${protein > 0 ? ' · ${(protein * portions).round()} g protein' : ''}, estimated. A guide only.',
                style: t.bodyMedium.copyWith(color: _muted, fontSize: 14)),
          ],
          const SizedBox(height: 20),
          _label(t, 'Used up in cooking'),
          if (foods.isEmpty)
            Text('No matching foods in your kitchen, so nothing changes there.',
                style: t.bodyMedium.copyWith(color: _muted, fontSize: 14))
          else ...[
            for (final f in foods)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: _forest,
                value: ticked.contains(f.id),
                title: Text(f.name,
                    style: t.bodyLarge.copyWith(fontSize: 16, color: _ink)),
                onChanged: (v) => redraw(() =>
                    v == true ? ticked.add(f.id) : ticked.remove(f.id)),
              ),
            Text('Untick anything with some left.',
                style: t.bodySmall.copyWith(color: _muted, fontSize: 13)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _forest,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => Navigator.of(sheet).pop(true),
              child: Text('Confirm',
                  style: t.bodyLarge.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      );
    });
    if (confirmed != true || !mounted) return;
    await _ate(e, portions, ticked.toList());
  }

  Future<void> _ate(_Entry e, double portions, List<String> used) async {
    if (_busy) return;
    setState(() => _busy = true);
    final uid = SupaFlow.client.auth.currentUser?.id;
    String? logId;
    final settled = <String>[];
    try {
      final row = await SupaFlow.client
          .from('meal_log_entries')
          .insert({
            'profile_id': uid,
            'household_id': _for,
            'plan_entry_id': e.id,
            'eaten_on': _iso(DateTime.now()),
            'meal': e.meal,
            'title': e.title,
            'portions': portions,
            if (e.number('calories') > 0)
              'calories_per_serving': e.number('calories'),
            if (e.number('protein') > 0)
              'protein_per_serving': e.number('protein'),
          })
          .select('id')
          .single();
      logId = row['id'].toString();
      await SupaFlow.client.from('meal_plan_entries').update({
        'status': 'cooked',
        'cooked_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', e.id);
      for (final id in used) {
        final said = await settleFoodItem(id, 'consumed');
        if (said.isEmpty) settled.add(id);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        _say(logId == null
            ? _why(error)
            : 'Logged, but the kitchen could not be updated. Check your signal.');
      }
      if (logId == null) return;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    await _load(_for, quiet: true);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final id = logId!;
    _say(
        settled.isEmpty
            ? 'Logged. Enjoy.'
            : (settled.length == 1
                ? 'Logged, and 1 food has left your kitchen.'
                : 'Logged, and ${settled.length} foods have left your kitchen.'),
        action: SnackBarAction(
          label: 'Undo',
          textColor: const Color(0xFFB9E08F),
          onPressed: () async {
            try {
              await SupaFlow.client
                  .from('meal_log_entries')
                  .delete()
                  .eq('id', id);
              await SupaFlow.client.from('meal_plan_entries').update(
                  {'status': 'planned', 'cooked_at': null}).eq('id', e.id);
              for (final f in settled) {
                await unsettleFoodItem(f);
              }
              messenger.showSnackBar(
                  const SnackBar(content: Text('Undone. Nothing changed.')));
              if (mounted) _load(_for, quiet: true);
            } catch (_) {
              messenger.showSnackBar(const SnackBar(
                  content: Text('Could not undo. Check your signal.')));
            }
          },
        ));
  }

  // ---- pieces --------------------------------------------------------------

  Widget _label(FlutterFlowTheme t, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: t.bodyMedium.copyWith(
                color: _muted, fontWeight: FontWeight.w700, fontSize: 14)),
      );

  Widget _choice(
          FlutterFlowTheme t, String label, bool on, VoidCallback onTap) =>
      Semantics(
        button: true,
        selected: on,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: on ? _forest : Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: on ? _forest : _border),
            ),
            child: Text(label,
                style: t.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: on ? Colors.white : _ink)),
          ),
        ),
      );

  Widget _stepper(IconData icon, bool enabled, VoidCallback onTap) => Opacity(
        opacity: enabled ? 1 : 0.4,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: _border),
            ),
            child: Icon(icon, color: _forest, size: 20),
          ),
        ),
      );

  Widget _message(FlutterFlowTheme t, IconData icon, String title, String text,
      VoidCallback? retry) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
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
          if (retry != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _forest,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: retry,
                child: Text('Try again',
                    style: t.bodyLarge.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
''';

const _recipesHome = r'''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Recipes below the title "What looks good?", as design guide v4 lays out.
///
/// Controls first and compact: Quick meals and Use my food toggle real
/// filters; Filters opens the rest in a sheet. Then an invitation, or the
/// ideas as cards that open to their details. Kept ideas last.
///
/// "Fits my goals" (a Plus feature, owner 14 Sep) is optional and off until
/// turned on: calories and protein per serving on each idea, and only ideas
/// in the chosen calorie range or high in protein. The numbers are estimates
/// and always say so.
class RecipesHome extends StatefulWidget {
  const RecipesHome({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<RecipesHome> createState() => _RecipesHomeState();
}

class _Kept {
  const _Kept(this.id, this.idea);
  final String id;
  final MealIdeaStruct idea;
}

class _RecipesHomeState extends State<RecipesHome> {
  static const _forest = Color(0xFF07533A);
  static const _leaf = Color(0xFF83BD43);
  static const _ink = Color(0xFF202C24);
  static const _muted = Color(0xFF59665D);
  static const _sage = Color(0xFFEDF2E8);
  static const _border = Color(0xFFDCE3D7);
  static const _cream = Color(0xFFF7F7F0);

  static const _food =
      'https://cdn.jsdelivr.net/gh/ashelashiry/UseItFresh@b50424f12bd372d81c9cd44d895b62c25d1329e7/design/v3/food';

  static const _meals = <String, String>{
    'any': 'Any',
    'breakfast': 'Breakfast',
    'lunch': 'Lunch',
    'dinner': 'Dinner',
    'snack': 'Snack',
  };
  static const _calorieRanges = <String, String>{
    '': 'Any',
    'under400': 'Under 400',
    '400to600': '400–600',
    '600to800': '600–800',
  };
  static const _times = <int, String>{
    0: 'Any',
    15: '15 min',
    30: '30 min',
    60: '1 hour',
  };

  String _for = '';
  bool? _hasFood;
  List<_Kept> _kept = const [];
  final Set<String> _listed = {};
  bool _keeping = false;

  static String _same(String s) => s.trim().toLowerCase();

  // ---- data ----------------------------------------------------------------

  Future<void> _load(String household) async {
    try {
      final any = await SupaFlow.client
          .from('food_items_status')
          .select('id')
          .eq('household_id', household)
          .limit(1);
      final rows = await SupaFlow.client
          .from('saved_recipes')
          .select('id, title, recipe_data')
          .eq('household_id', household)
          .order('created_at', ascending: false)
          .limit(20);
      final kept = <_Kept>[];
      for (final r in rows as List) {
        final m = r as Map;
        final d = m['recipe_data'] is Map ? m['recipe_data'] as Map : const {};
        List<String> words(Object? v) => v is List
            ? [
                for (final w in v)
                  if ('$w'.trim().isNotEmpty) '$w'.trim()
              ]
            : <String>[];
        kept.add(_Kept(
          m['id'].toString(),
          MealIdeaStruct(
            title: (m['title'] ?? '').toString(),
            uses: words(d['uses']),
            extras: words(d['extras']),
            steps: words(d['steps']),
            minutes: d['minutes'] is num ? (d['minutes'] as num).round() : 0,
            servings: d['servings'] is num ? (d['servings'] as num).round() : 0,
            calories: d['calories'] is num ? (d['calories'] as num).round() : 0,
            protein: d['protein'] is num ? (d['protein'] as num).round() : 0,
          ),
        ));
      }
      if (!mounted || household != _for) return;
      setState(() {
        _hasFood = (any as List).isNotEmpty;
        _kept = kept;
      });
    } catch (_) {
      // No signal: the invitation still shows; asking will say why not.
    }
  }

  bool _isKept(MealIdeaStruct idea) =>
      _kept.any((k) => _same(k.idea.title) == _same(idea.title));

  Future<void> _ask() async {
    final said = await getMealIdeas();
    if (!mounted) return;
    if (said.isNotEmpty) _say(said);
  }

  void _say(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _keep(MealIdeaStruct idea) async {
    final household = FFAppState().currentHouseholdId;
    if (household.isEmpty || _keeping || _isKept(idea)) return;
    setState(() => _keeping = true);
    try {
      await SupaFlow.client.from('saved_recipes').insert({
        'household_id': household,
        'profile_id': SupaFlow.client.auth.currentUser?.id,
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
      });
      await _load(household);
      if (mounted) _say('Kept for your household.');
    } on PostgrestException catch (error) {
      if (mounted) {
        _say(error.code == '42501'
            ? 'Your account is not allowed to keep ideas in this household.'
            : error.message);
      }
    } catch (_) {
      if (mounted) _say('Could not keep it. Check your signal and try again.');
    } finally {
      if (mounted) setState(() => _keeping = false);
    }
  }

  Future<void> _remove(_Kept kept) async {
    try {
      await SupaFlow.client.from('saved_recipes').delete().eq('id', kept.id);
      await _load(_for);
    } catch (_) {
      if (mounted)
        _say('Could not remove it. Check your signal and try again.');
    }
  }

  Future<String> _addExtras(MealIdeaStruct idea) async {
    for (final name in idea.extras) {
      final said = await addNameToShoppingList(name);
      if (said.isNotEmpty) return said;
    }
    return '';
  }

  /// A photo of an ingredient the idea really uses, when there is one.
  static ({String url, String cue})? _ingredientPhoto(MealIdeaStruct idea) {
    const exact = {
      'spinach': 'spinach',
      'mushroom': 'mushrooms',
      'tomato': 'tomatoes',
      'egg': 'eggs',
      'yogurt': 'yogurt',
      'yoghurt': 'yogurt',
      'pasta': 'pasta',
    };
    for (final use in idea.uses) {
      final n = use.toLowerCase();
      for (final e in exact.entries) {
        if (n.contains(e.key)) {
          return (
            url: '$_food/${e.value}.webp',
            cue: 'Uses your ${use.toLowerCase()}'
          );
        }
      }
    }
    return null;
  }

  static String _cue(MealIdeaStruct idea) {
    final photo = _ingredientPhoto(idea);
    if (photo != null) return photo.cue;
    if (idea.uses.isNotEmpty)
      return 'Uses your ${idea.uses.first.toLowerCase()}';
    return '';
  }

  static bool get _goalsOn => FFAppState().ideasGoals;

  /// "520 kcal · 32 g protein", per serving, or '' when there is no estimate.
  static String _nutrition(MealIdeaStruct idea) => [
        if (idea.calories > 0) '${idea.calories} kcal',
        if (idea.protein > 0) '${idea.protein} g protein',
      ].join(' · ');

  int get _activeFilters {
    var n = 0;
    final s = FFAppState();
    if (s.ideasMeal.isNotEmpty && s.ideasMeal != 'any') n++;
    if (s.ideasMinutes != 0) n++;
    if (s.ideasServings != 2 && s.ideasServings != 0) n++;
    if (s.ideasLeaveOut.trim().isNotEmpty) n++;
    return n;
  }

  // ---- page ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final t = FlutterFlowTheme.of(context);
    final household = FFAppState().currentHouseholdId;
    if (household.isNotEmpty && household != _for) {
      _for = household;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load(household));
    }
    final ideas = FFAppState().mealIdeas;
    final loading = FFAppState().ideasLoading;
    final still = MediaQuery.of(context).disableAnimations;

    Widget body;
    if (loading) {
      body = _thinking(t);
    } else if (ideas.isEmpty) {
      body = _invitation(t);
    } else {
      body = _results(t, ideas);
    }

    return SizedBox(
      width: widget.width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _weekLink(t),
          const SizedBox(height: 12),
          _controls(t),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: still ? Duration.zero : const Duration(milliseconds: 220),
            child: KeyedSubtree(
              key: ValueKey(loading
                  ? 'loading'
                  : (ideas.isEmpty
                      ? 'invite'
                      : 'ideas${ideas.length}${ideas.first.title}')),
              child: body,
            ),
          ),
          if (_kept.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Kept ideas',
                style: t.titleLarge.copyWith(
                    fontSize: 22, fontWeight: FontWeight.w800, color: _ink)),
            const SizedBox(height: 12),
            SizedBox(
              height: 128,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: _kept.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) =>
                    _smallCard(t, _kept[i].idea, kept: _kept[i], width: 200),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---- controls ------------------------------------------------------------

  Widget _controls(FlutterFlowTheme t) {
    final s = FFAppState();
    final quick = s.ideasMinutes == 15 || s.ideasMinutes == 30;
    final active = _activeFilters;
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: [
          _chip(t, 'Quick meals', quick, Icons.bolt_outlined, () {
            FFAppState()
                .update(() => FFAppState().ideasMinutes = quick ? 0 : 30);
          }),
          const SizedBox(width: 8),
          _chip(t, 'Use my food', s.ideasKitchenOnly, Icons.kitchen_outlined,
              () {
            FFAppState().update(() =>
                FFAppState().ideasKitchenOnly = !FFAppState().ideasKitchenOnly);
          }),
          const SizedBox(width: 8),
          _chip(t, 'Fits my goals', s.ideasGoals, Icons.track_changes, () {
            final turningOn = !FFAppState().ideasGoals;
            FFAppState().update(() => FFAppState().ideasGoals = turningOn);
            // First time on, with nothing chosen yet: show where goals are set.
            if (turningOn &&
                FFAppState().ideasCalories.isEmpty &&
                !FFAppState().ideasHighProtein) {
              _openFilters(t);
            }
          }),
          const SizedBox(width: 8),
          _chip(t, active > 0 ? 'Filters · $active' : 'Filters', active > 0,
              Icons.tune, () => _openFilters(t)),
        ],
      ),
    );
  }

  Widget _weekLink(FlutterFlowTheme t) => Semantics(
        button: true,
        label: 'Plan my week',
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.pushNamed('PlanWeekPage'),
          child: Container(
            constraints: const BoxConstraints(minHeight: 60),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _sage,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.calendar_month_outlined,
                      color: _forest, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Plan my week',
                          style: t.bodyLarge.copyWith(
                              fontWeight: FontWeight.w800, color: _ink)),
                      Text('Meals for the next 7 days, and one shopping list',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodySmall
                              .copyWith(color: _muted, fontSize: 13)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: _forest),
              ],
            ),
          ),
        ),
      );

  /// Puts an idea on a day of the household's week.
  Future<void> _addToWeek(FlutterFlowTheme t, MealIdeaStruct idea) async {
    final household = FFAppState().currentHouseholdId;
    if (household.isEmpty) return;
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    String name(int i) {
      if (i == 0) return 'Today';
      if (i == 1) return 'Tomorrow';
      final d = today.add(Duration(days: i));
      return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
    }

    var day = 0;
    var meal = _meals.containsKey(FFAppState().ideasMeal) &&
            FFAppState().ideasMeal != 'any'
        ? FFAppState().ideasMeal
        : 'dinner';
    final go = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cream,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, redraw) => SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Add to my week',
                    style: t.headlineSmall.copyWith(
                        fontSize: 24, fontWeight: FontWeight.w800, color: _ink)),
                const SizedBox(height: 4),
                Text(idea.title,
                    style: t.bodyLarge.copyWith(color: _muted, fontSize: 16)),
                const SizedBox(height: 20),
                _sheetLabel(t, 'Day'),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (var i = 0; i < 7; i++)
                    _choice(t, name(i), day == i, () => redraw(() => day = i)),
                ]),
                const SizedBox(height: 20),
                _sheetLabel(t, 'Meal'),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final e in _meals.entries)
                    if (e.key != 'any')
                      _choice(t, e.value, meal == e.key,
                          () => redraw(() => meal = e.key)),
                ]),
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _forest,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.of(sheet).pop(true),
                    child: Text('Add to ${name(day) == 'Today' || name(day) == 'Tomorrow' ? name(day).toLowerCase() : name(day)}',
                        style: t.bodyLarge.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (go != true || !mounted) return;
    final d = today.add(Duration(days: day));
    final iso =
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    try {
      await SupaFlow.client.from('meal_plan_entries').insert({
        'household_id': household,
        'plan_date': iso,
        'meal': meal,
        'title': idea.title,
        'recipe_data': {
          'uses': idea.uses,
          'extras': idea.extras,
          'steps': idea.steps,
          'minutes': idea.minutes,
          if (idea.calories > 0) 'calories': idea.calories,
          if (idea.protein > 0) 'protein': idea.protein,
        },
        'servings': idea.servings > 0 ? idea.servings : 2,
        'created_by': SupaFlow.client.auth.currentUser?.id,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Planned for ${name(day) == 'Today' || name(day) == 'Tomorrow' ? name(day).toLowerCase() : name(day)}.'),
        action: SnackBarAction(
          label: 'See the week',
          textColor: const Color(0xFFB9E08F),
          onPressed: () => context.pushNamed('PlanWeekPage'),
        ),
      ));
    } on PostgrestException catch (error) {
      if (!mounted) return;
      _say(error.code == '42P01' || error.code == 'PGRST205'
          ? 'Plan my week is almost ready. Try again soon.'
          : (error.code == '42501'
              ? 'Your account is not allowed to plan meals in this household.'
              : error.message));
    } catch (_) {
      if (mounted) _say('Could not add it. Check your signal and try again.');
    }
  }

  Widget _chip(FlutterFlowTheme t, String label, bool on, IconData icon,
          VoidCallback onTap) =>
      Semantics(
        button: true,
        selected: on,
        label: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: on ? _forest : Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: on ? _forest : _border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: on ? Colors.white : _forest),
                const SizedBox(width: 6),
                Text(label,
                    style: t.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: on ? Colors.white : _ink)),
              ],
            ),
          ),
        ),
      );

  void _openFilters(FlutterFlowTheme t) {
    final leaveOut = TextEditingController(text: FFAppState().ideasLeaveOut);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cream,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheet) {
        return StatefulBuilder(builder: (sheet, redraw) {
          final s = FFAppState();
          final meal = _meals.containsKey(s.ideasMeal) ? s.ideasMeal : 'any';
          final minutes =
              _times.containsKey(s.ideasMinutes) ? s.ideasMinutes : 0;
          final people = s.ideasServings < 1
              ? 2
              : (s.ideasServings > 8 ? 8 : s.ideasServings);
          final avoid = s.ideasAvoid.trim();
          void set(void Function() change) {
            FFAppState().update(change);
            redraw(() {});
          }

          return Padding(
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(sheet).viewInsets.bottom),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: _border,
                            borderRadius: BorderRadius.circular(999)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Filters',
                        style: t.headlineSmall.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: _ink)),
                    const SizedBox(height: 20),
                    _sheetLabel(t, 'Meal'),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final e in _meals.entries)
                        _choice(t, e.value, meal == e.key,
                            () => set(() => FFAppState().ideasMeal = e.key)),
                    ]),
                    const SizedBox(height: 20),
                    _sheetLabel(t, 'Time'),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final e in _times.entries)
                        _choice(t, e.value, minutes == e.key,
                            () => set(() => FFAppState().ideasMinutes = e.key)),
                    ]),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _sheetLabel(t, 'Servings')),
                        _stepper(
                            Icons.remove,
                            people > 1,
                            () => set(
                                () => FFAppState().ideasServings = people - 1)),
                        SizedBox(
                          width: 84,
                          child: Text(
                              people == 1 ? '1 person' : '$people people',
                              textAlign: TextAlign.center,
                              style: t.titleSmall.copyWith(color: _ink)),
                        ),
                        _stepper(
                            Icons.add,
                            people < 8,
                            () => set(
                                () => FFAppState().ideasServings = people + 1)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _goals(t, set),
                    const SizedBox(height: 20),
                    _sheetLabel(t, 'Leave out'),
                    TextField(
                      controller: leaveOut,
                      style: t.bodyLarge.copyWith(fontSize: 16, color: _ink),
                      decoration: InputDecoration(
                        hintText: 'e.g. mushrooms, nuts',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _border),
                        ),
                      ),
                      onChanged: (v) => FFAppState()
                          .update(() => FFAppState().ideasLeaveOut = v),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.of(sheet).pop();
                        context.pushNamed('FoodPreferencesPage');
                      },
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 56),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.no_food_outlined,
                                color: _forest, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Diet & allergies',
                                      style: t.bodyLarge.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: _ink)),
                                  Text(
                                    avoid.isEmpty
                                        ? 'None saved'
                                        : 'Always left out: $avoid',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: t.bodySmall
                                        .copyWith(color: _muted, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: _muted),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _forest,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          Navigator.of(sheet).pop();
                          _ask();
                        },
                        child: Text('Show ideas',
                            style: t.bodyLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    ).whenComplete(leaveOut.dispose);
  }

  // Off by default: people who only want to waste less never see calories.
  Widget _goals(FlutterFlowTheme t, void Function(void Function()) set) {
    final s = FFAppState();
    final range =
        _calorieRanges.containsKey(s.ideasCalories) ? s.ideasCalories : '';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: s.ideasGoals ? _forest : _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.track_changes, color: _forest, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fits my goals',
                        style: t.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700, color: _ink)),
                    Text('Calories and protein on each idea, estimated',
                        style:
                            t.bodySmall.copyWith(color: _muted, fontSize: 14)),
                  ],
                ),
              ),
              Switch(
                value: s.ideasGoals,
                activeTrackColor: _forest,
                onChanged: (v) => set(() => FFAppState().ideasGoals = v),
              ),
            ],
          ),
          if (s.ideasGoals) ...[
            const SizedBox(height: 14),
            _sheetLabel(t, 'Calories per serving'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final e in _calorieRanges.entries)
                _choice(t, e.value, range == e.key,
                    () => set(() => FFAppState().ideasCalories = e.key)),
            ]),
            const SizedBox(height: 14),
            Row(
              children: [
                _choice(
                    t,
                    'High protein',
                    s.ideasHighProtein,
                    () => set(() => FFAppState().ideasHighProtein =
                        !FFAppState().ideasHighProtein)),
              ],
            ),
            const SizedBox(height: 6),
            Text('At least 25 g a serving; 15 g for breakfasts and snacks.',
                style: t.bodySmall.copyWith(color: _muted, fontSize: 13)),
          ],
        ],
      ),
    );
  }

  // Small, quiet badges: the photo stays first.
  Widget _badges(FlutterFlowTheme t, MealIdeaStruct idea) {
    Widget badge(String text) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xE6FFFFFF),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(text,
              style: t.bodySmall.copyWith(
                  color: _forest, fontWeight: FontWeight.w800, fontSize: 12)),
        );
    return Wrap(spacing: 6, runSpacing: 6, children: [
      if (idea.calories > 0) badge('${idea.calories} kcal'),
      if (idea.protein > 0) badge('${idea.protein} g protein'),
    ]);
  }

  Widget _sheetLabel(FlutterFlowTheme t, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: t.bodyMedium.copyWith(
                color: _muted, fontWeight: FontWeight.w700, fontSize: 14)),
      );

  Widget _choice(
          FlutterFlowTheme t, String label, bool on, VoidCallback onTap) =>
      Semantics(
        button: true,
        selected: on,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: on ? _forest : Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: on ? _forest : _border),
            ),
            child: Text(label,
                style: t.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: on ? Colors.white : _ink)),
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

  // ---- states --------------------------------------------------------------

  Widget _invitation(FlutterFlowTheme t) {
    final empty = _hasFood == false;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 250,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Illustrative ingredients, not a recipe result.
            Image.network(
              '$_food/spinach.webp',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: _sage),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xC0000000)],
                  stops: [0.3, 1],
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
                    empty
                        ? 'Ideas come from your food'
                        : 'Ideas from your food',
                    style: t.headlineSmall.copyWith(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.15),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _forest,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: empty
                          ? () async {
                              await clearShelfScan();
                              if (mounted) context.pushNamed('MapReviewPage');
                            }
                          : _ask,
                      icon: Icon(
                          empty ? Icons.add : Icons.auto_awesome_outlined,
                          size: 20),
                      label: Text(empty ? 'Add food' : 'Find ideas',
                          style: t.bodyLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thinking(FlutterFlowTheme t) {
    Widget block(double h) => Container(
          height: h,
          decoration: BoxDecoration(
              color: _sage, borderRadius: BorderRadius.circular(20)),
        );
    return Semantics(
      label: 'Finding ideas from your kitchen',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          block(220),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: block(128)),
            const SizedBox(width: 12),
            Expanded(child: block(128)),
          ]),
          const SizedBox(height: 12),
          Text('Looking through your kitchen…',
              style: t.bodyMedium.copyWith(color: _muted, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _results(FlutterFlowTheme t, List<MealIdeaStruct> ideas) {
    final lead = ideas.first;
    final rest = ideas.skip(1).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _leadCard(t, lead),
        if (rest.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 128,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: rest.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _smallCard(t, rest[i], width: 220),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _ask,
            style: TextButton.styleFrom(
                minimumSize: const Size(48, 48), foregroundColor: _forest),
            icon: const Icon(Icons.refresh, size: 18),
            label: Text('New ideas',
                style: t.bodyLarge
                    .copyWith(color: _forest, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _leadCard(FlutterFlowTheme t, MealIdeaStruct idea) {
    final photo = _ingredientPhoto(idea);
    final meta = [
      if (idea.minutes > 0) '${idea.minutes} min',
      if (_cue(idea).isNotEmpty) _cue(idea),
    ].join(' · ');
    final text = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(idea.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: t.headlineSmall.copyWith(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1.15)),
        if (meta.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(meta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.bodyMedium.copyWith(
                  color: Colors.white.withOpacity(0.9), fontSize: 14)),
        ],
        if (_goalsOn && _nutrition(idea).isNotEmpty) ...[
          const SizedBox(height: 8),
          _badges(t, idea),
        ],
      ],
    );
    return _tap(
      label: idea.title,
      onTap: () => _openIdea(t, idea),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 220,
          child: photo == null
              ? Container(
                  color: _forest,
                  padding: const EdgeInsets.all(20),
                  alignment: Alignment.bottomLeft,
                  child: text,
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(photo.url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: _forest)),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x00000000), Color(0xC8000000)],
                          stops: [0.25, 1],
                        ),
                      ),
                    ),
                    Positioned(left: 20, right: 20, bottom: 20, child: text),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _smallCard(FlutterFlowTheme t, MealIdeaStruct idea,
      {_Kept? kept, required double width}) {
    final meta = [
      if (idea.minutes > 0) '${idea.minutes} min',
      if (_goalsOn && _nutrition(idea).isNotEmpty)
        _nutrition(idea)
      else if (kept == null && _cue(idea).isNotEmpty)
        _cue(idea),
    ].join(' · ');
    return _tap(
      label: idea.title,
      onTap: () => _openIdea(t, idea, kept: kept),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kept == null ? Colors.white : _sage,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kept == null ? _border : _sage),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(idea.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: t.titleMedium.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                    height: 1.2)),
            const Spacer(),
            if (meta.isNotEmpty)
              Text(meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall.copyWith(color: _muted, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _tap(
          {required String label,
          required VoidCallback onTap,
          required Widget child}) =>
      Semantics(
        button: true,
        label: label,
        child: GestureDetector(onTap: onTap, child: child),
      );

  // ---- one idea, in full -----------------------------------------------------

  void _openIdea(FlutterFlowTheme t, MealIdeaStruct idea, {_Kept? kept}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cream,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheet) {
        return StatefulBuilder(builder: (sheet, redraw) {
          final avoid = [FFAppState().ideasAvoid, FFAppState().ideasLeaveOut]
              .map((w) => w.trim())
              .where((w) => w.isNotEmpty)
              .join(', ');
          final meta = [
            if (idea.minutes > 0) '${idea.minutes} min',
            if (idea.servings > 0) 'Serves ${idea.servings}',
          ].join(' · ');
          final listed = _listed.contains(_same(idea.title));
          return ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheet).size.height * 0.88),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: _border,
                            borderRadius: BorderRadius.circular(999)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(idea.title,
                        style: t.headlineSmall.copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                            height: 1.15)),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(meta,
                          style: t.bodyMedium
                              .copyWith(color: _muted, fontSize: 14)),
                    ],
                    if (_goalsOn && idea.calories > 0) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _sage,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                for (final n in [
                                  ('${idea.calories}', 'kcal a serving'),
                                  if (idea.protein > 0)
                                    ('${idea.protein} g', 'protein a serving'),
                                ])
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(n.$1,
                                            style: t.headlineSmall.copyWith(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w800,
                                                color: _forest)),
                                        Text(n.$2,
                                            style: t.bodySmall.copyWith(
                                                color: _muted, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Estimated from typical amounts of these ingredients, not measured. A guide only, not diet or medical advice.',
                              style: t.bodySmall.copyWith(
                                  color: _ink, fontSize: 13, height: 1.35),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    _section(t, kept == null ? 'From your kitchen' : 'Uses'),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final u in idea.uses) _pill(t, u, _sage, _forest),
                    ]),
                    if (kept == null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Only food that is not past its use-by or best-before date.',
                        style:
                            t.bodySmall.copyWith(color: _muted, fontSize: 13),
                      ),
                    ],
                    if (idea.extras.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _section(t, 'You would also need'),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        for (final e in idea.extras)
                          _pill(t, e, Colors.white, _ink),
                      ]),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                              minimumSize: const Size(48, 48),
                              foregroundColor: _forest),
                          onPressed: listed
                              ? null
                              : () async {
                                  final said = await _addExtras(idea);
                                  if (!mounted) return;
                                  if (said.isEmpty) {
                                    _listed.add(_same(idea.title));
                                    redraw(() {});
                                    _say('Added to your shopping list.');
                                  } else {
                                    _say(said);
                                  }
                                },
                          icon: Icon(
                              listed ? Icons.check : Icons.add_shopping_cart,
                              size: 18),
                          label: Text(
                              listed
                                  ? 'On your shopping list'
                                  : 'Add to shopping list',
                              style: t.bodyLarge.copyWith(
                                  color: listed ? _muted : _forest,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                    if (idea.steps.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _section(t, 'Steps'),
                      for (var i = 0; i < idea.steps.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                    color: _forest, shape: BoxShape.circle),
                                child: Text('${i + 1}',
                                    style: t.bodySmall.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(idea.steps[i],
                                    style: t.bodyLarge.copyWith(
                                        fontSize: 16,
                                        color: _ink,
                                        height: 1.45)),
                              ),
                            ],
                          ),
                        ),
                    ],
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline,
                              color: _forest, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              avoid.isEmpty
                                  ? 'Not checked for allergies or diets. Read the label on anything you cook with.'
                                  : 'Left out for you: $avoid. Not a medical check: read the label on anything you cook with.',
                              style: t.bodyMedium.copyWith(
                                  color: _ink, fontSize: 14, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _forest,
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: _forest),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          Navigator.of(sheet).pop();
                          _addToWeek(t, idea);
                        },
                        icon: const Icon(Icons.calendar_month_outlined,
                            size: 20),
                        label: Text('Add to my week',
                            style: t.bodyLarge.copyWith(
                                color: _forest, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 52,
                      child: kept != null
                          ? OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _forest,
                                side: const BorderSide(color: _border),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () {
                                Navigator.of(sheet).pop();
                                _remove(kept);
                              },
                              icon: const Icon(Icons.close, size: 18),
                              label: Text('Remove from kept ideas',
                                  style: t.bodyLarge.copyWith(
                                      color: _forest,
                                      fontWeight: FontWeight.w700)),
                            )
                          : FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: _forest,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: _leaf.withOpacity(0.5),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: _isKept(idea)
                                  ? null
                                  : () async {
                                      await _keep(idea);
                                      redraw(() {});
                                    },
                              icon: Icon(
                                  _isKept(idea)
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                  size: 20),
                              label: Text(
                                  _isKept(idea) ? 'Kept' : 'Keep this idea',
                                  style: t.bodyLarge.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700)),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  Widget _section(FlutterFlowTheme t, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: t.titleMedium.copyWith(
                fontSize: 18, fontWeight: FontWeight.w800, color: _ink)),
      );

  Widget _pill(FlutterFlowTheme t, String text, Color bg, Color fg) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: bg == Colors.white ? _border : bg),
        ),
        child: Text(text,
            style: t.bodyMedium.copyWith(
                color: fg, fontWeight: FontWeight.w600, fontSize: 14)),
      );
}
''';
