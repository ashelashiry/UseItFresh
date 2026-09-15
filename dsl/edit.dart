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

/// Hybrid design, batch 2 (brief 15 Sep): the theme's surfaces become warm
/// cream with sage lines, so every FlutterFlow-built page and theme-coloured
/// widget follows; sculpted cards, buttons and back controls on Plan my week,
/// Your recipes, Household, What you used, the photo map and the edit form.
void buildStarterEditFlow(App app) {
  // Warm cream surfaces, sage lines and wash (hybrid material).
  app.themeColor('secondaryBackground', 0xFFFFFEF9);
  app.themeColor('alternate', 0xFFCDD4C3);
  app.themeColor('accent1', 0xFFE6EDDF);
  app.raw((project) {
    updateCustomWidget(project, name: 'WeekPlan', code: _wWeekPlan);
    updateCustomWidget(project, name: 'RecipeCollection', code: _wRecipeCollection);
    updateCustomWidget(project, name: 'ItemEditFields', code: _wItemEditFields);
    updateCustomWidget(project, name: 'HouseholdMembers', code: _wHouseholdMembers);
    updateCustomWidget(project, name: 'HouseholdSwitcher', code: _wHouseholdSwitcher);
    updateCustomWidget(project, name: 'LeaveHouseholdButton', code: _wLeaveHouseholdButton);
    updateCustomWidget(project, name: 'PutItBack', code: _wPutItBack);
    updateCustomWidget(project, name: 'ShelfReview', code: _wShelfReview);
  });
}

const _wWeekPlan = r'''
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
///
/// Household planning (a Plus feature): who eats at home — everyone in the
/// household, and people without the app such as children — each with a
/// portion size and their allergies. Each planned meal says who is eating, its
/// servings add up from their portions, and a meal that mentions something one
/// of them avoids says so. Ideas found here leave out everyone's allergies.
///
/// Budget (a Plus feature): a weekly amount for the household, what the
/// week's shopping should cost from the last prices paid (receipts, or typed),
/// what receipts say was spent in the last seven days, and a price on each
/// idea when adding a meal. Always "about", and honest about missing prices.
///
/// Your day (with "Fits my goals" on): today's estimated calories and
/// protein from the meals this person marked as eaten, against targets
/// they choose. Private to them, and never shown to anyone who has not
/// turned goals on.
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
  int number(String key) => data[key] is num ? (data[key] as num).round() : 0;
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
    'Dec'
  ];

  String _for = '';
  bool _loading = true;
  bool _offline = false;
  bool _notReady = false;
  bool _busy = false;
  List<_Entry> _entries = const [];
  List<MealIdeaStruct> _kept = const [];
  // Your day: what this person ate today, and their own targets.
  List<Map> _eaten = const [];
  int? _kcalTarget;
  int? _proteinTarget;
  bool _targetsReady = true;
  // Budget: the household's weekly amount, known prices, recent spending.
  double? _budget;
  String _currency = 'AUD';
  final Map<String, double> _prices = {};
  double _spent = 0;
  bool _budgetReady = true;
  // Household planning: who eats at home, and who eats each planned meal.
  List<Map> _diners = const [];
  final Map<String, Map<String, double>> _plates = {};
  bool _dinersReady = true;

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

  static DateTime _dayAt(int i) =>
      DateTime(_today.year, _today.month, _today.day + i);

  /// Whole-word match either way ("egg" in "Free-range eggs"), so "egg" is
  /// never "eggplant" and "milk" never "coconut milk" alone.
  static bool _wordIn(String hay, String word) {
    final w = word.trim().toLowerCase();
    if (w.length < 2) return false;
    return RegExp('(^|[^a-z])${RegExp.escape(w)}(es|s)?([^a-z]|\$)')
        .hasMatch(hay.toLowerCase());
  }

  static String _dayName(DateTime d) {
    final diff = DateTime.utc(d.year, d.month, d.day)
        .difference(DateTime.utc(_today.year, _today.month, _today.day))
        .inDays;
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
          .lte('plan_date', _iso(_dayAt(6)))
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
              : _mealOrder
                  .indexOf(a.meal)
                  .compareTo(_mealOrder.indexOf(b.meal));
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
      _loadDay();
      _loadBudget();
      _loadDiners(seed: true);
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

  Future<void> _loadDay() async {
    final uid = SupaFlow.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final log = await SupaFlow.client
          .from('meal_log_entries')
          .select(
              'id, meal, title, portions, calories_per_serving, protein_per_serving, plan_entry_id, household_id')
          .eq('profile_id', uid)
          .eq('eaten_on', _iso(DateTime.now()))
          .order('created_at');
      Map? settings;
      var ready = true;
      try {
        settings = await SupaFlow.client
            .from('user_settings')
            .select('daily_calorie_target, daily_protein_target')
            .eq('profile_id', uid)
            .maybeSingle();
      } on PostgrestException {
        ready = false;
      }
      if (!mounted) return;
      int? whole(Object? v) => v is num ? v.round() : null;
      setState(() {
        _eaten = [for (final r in log as List) r as Map];
        _kcalTarget = whole(settings?['daily_calorie_target']);
        _proteinTarget = whole(settings?['daily_protein_target']);
        _targetsReady = ready;
      });
    } catch (_) {
      // Your day is extra: the plan still shows without it.
    }
  }

  static double _portions(Map r) =>
      r['portions'] is num ? (r['portions'] as num).toDouble() : 1;

  int get _kcalToday => _eaten
      .fold<double>(
          0,
          (sum, r) =>
              sum +
              (r['calories_per_serving'] is num
                      ? (r['calories_per_serving'] as num).toDouble()
                      : 0) *
                  _portions(r))
      .round();

  int get _proteinToday => _eaten
      .fold<double>(
          0,
          (sum, r) =>
              sum +
              (r['protein_per_serving'] is num
                      ? (r['protein_per_serving'] as num).toDouble()
                      : 0) *
                  _portions(r))
      .round();

  Future<void> _unlog(Map r) async {
    try {
      await SupaFlow.client
          .from('meal_log_entries')
          .delete()
          .eq('id', r['id'].toString());
      await _loadDay();
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final back = Map<String, dynamic>.from(r)..remove('id');
      messenger.showSnackBar(SnackBar(
        content: const Text('Taken off your day. Your kitchen is unchanged.'),
        action: SnackBarAction(
          label: 'Undo',
          textColor: const Color(0xFFB9E08F),
          onPressed: () async {
            try {
              await SupaFlow.client.from('meal_log_entries').insert({
                ...back,
                'profile_id': SupaFlow.client.auth.currentUser?.id,
                'eaten_on': _iso(DateTime.now()),
              });
              if (mounted) _loadDay();
            } catch (_) {
              messenger.showSnackBar(const SnackBar(
                  content: Text('Could not undo. Check your signal.')));
            }
          },
        ),
      ));
    } catch (_) {
      if (mounted) _say('Could not change your day. Check your signal.');
    }
  }

  Future<void> _openTargets(FlutterFlowTheme t) async {
    if (!_targetsReady) {
      _say('Daily targets are almost ready. Try again soon.');
      return;
    }
    var kcal = _kcalTarget ?? 2000;
    var protein = _proteinTarget ?? 60;
    final choice = await _sheet<String>((sheet, redraw) {
      Widget row(String label, String value, VoidCallback less,
              VoidCallback more, bool canLess, bool canMore) =>
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(child: _label(t, label)),
                _stepper(Icons.remove, canLess, less),
                SizedBox(
                  width: 96,
                  child: Text(value,
                      textAlign: TextAlign.center,
                      style: t.titleSmall.copyWith(color: _ink)),
                ),
                _stepper(Icons.add, canMore, more),
              ],
            ),
          );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Your daily targets',
              style: t.headlineSmall.copyWith(
                  fontSize: 24, fontWeight: FontWeight.w800, color: _ink)),
          const SizedBox(height: 4),
          Text('Your own numbers, private to you.',
              style: t.bodyLarge.copyWith(color: _muted, fontSize: 16)),
          const SizedBox(height: 20),
          row('Calories', '$kcal kcal', () => redraw(() => kcal -= 50),
              () => redraw(() => kcal += 50), kcal > 1000, kcal < 4500),
          row('Protein', '$protein g', () => redraw(() => protein -= 5),
              () => redraw(() => protein += 5), protein > 0, protein < 300),
          Text(
              'Not medical or diet advice. A dietitian or doctor can suggest targets that suit you.',
              style: t.bodySmall.copyWith(color: _muted, fontSize: 13)),
          const SizedBox(height: 20),
          SizedBox(
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
              onPressed: () => Navigator.of(sheet).pop('save'),
              child: Text('Save targets',
                  style: t.bodyLarge.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
          if (_kcalTarget != null || _proteinTarget != null)
            TextButton(
              style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48), foregroundColor: _forest),
              onPressed: () => Navigator.of(sheet).pop('clear'),
              child: Text('No targets, just totals',
                  style: t.bodyLarge
                      .copyWith(color: _forest, fontWeight: FontWeight.w700)),
            ),
        ],
      );
    });
    if (choice == null || !mounted) return;
    final uid = SupaFlow.client.auth.currentUser?.id;
    try {
      await SupaFlow.client.from('user_settings').upsert({
        'profile_id': uid,
        'daily_calorie_target': choice == 'save' ? kcal : null,
        'daily_protein_target': choice == 'save' ? protein : null,
      });
      await _loadDay();
      if (mounted) {
        _say(choice == 'save' ? 'Targets saved.' : 'Targets cleared.');
      }
    } catch (_) {
      if (mounted) _say('Could not save your targets. Check your signal.');
    }
  }

  static String _thousands(int n) {
    final s = n.abs().toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return n < 0 ? '-$b' : b.toString();
  }

  Widget _dayProgress(FlutterFlowTheme t) {
    final kcal = _kcalToday;
    final protein = _proteinToday;
    Widget bar(String text, int value, int? target, String unit) {
      final over = target != null && value > target;
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
                target == null
                    ? '${_thousands(value)} $unit so far'
                    : (over
                        ? '${_thousands(value)} $unit · ${_thousands(value - target)} over your $text target'
                        : '${_thousands(value)} of ${_thousands(target)} $unit'),
                style: t.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700, color: _ink, fontSize: 16)),
            if (target != null && target > 0) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: (value / target).clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: Colors.white,
                  valueColor: AlwaysStoppedAnimation(
                      over ? const Color(0xFFB54708) : _forest),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
      decoration: BoxDecoration(
        color: _sage,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Your day',
                    style: t.titleMedium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _ink)),
              ),
              TextButton(
                style: TextButton.styleFrom(
                    minimumSize: const Size(48, 44), foregroundColor: _forest),
                onPressed: () => _openTargets(t),
                child: Text(
                    _kcalTarget == null && _proteinTarget == null
                        ? 'Set targets'
                        : 'Change targets',
                    style: t.bodyMedium
                        .copyWith(color: _forest, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                bar('calorie', kcal, _kcalTarget, 'kcal'),
                bar('protein', protein, _proteinTarget, 'g protein'),
                const SizedBox(height: 12),
                if (_eaten.isEmpty)
                  Text(
                      'Nothing logged today. Open a planned meal and tap «I ate this».',
                      style: t.bodyMedium.copyWith(color: _muted, fontSize: 14))
                else
                  for (final r in _eaten)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                              '${r['title']} · ${_portions(r) == 1 ? '1 portion' : '${_portions(r) == _portions(r).roundToDouble() ? _portions(r).round() : _portions(r)} portions'}${r['calories_per_serving'] is num ? ' · ${((r['calories_per_serving'] as num) * _portions(r)).round()} kcal' : ''}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodyMedium
                                  .copyWith(color: _ink, fontSize: 14)),
                        ),
                        IconButton(
                          tooltip: 'Take off your day',
                          onPressed: () => _unlog(r),
                          icon:
                              const Icon(Icons.close, color: _muted, size: 20),
                        ),
                      ],
                    ),
                const SizedBox(height: 4),
                Text(
                    'Estimated from the meals you marked as eaten. A guide only, not diet or medical advice.',
                    style: t.bodySmall.copyWith(color: _muted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
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
    final ok =
        await _write(() => SupaFlow.client.from('meal_plan_entries').insert({
              'household_id': _for,
              'plan_date': _iso(day),
              'meal': meal,
              'title': idea.title.length > 120
                  ? idea.title.substring(0, 120)
                  : idea.title,
              'recipe_data': _data(idea),
              'servings': idea.servings > 0
                  ? idea.servings.clamp(1, 12)
                  : (people < 1 ? 2 : (people > 12 ? 12 : people)),
              'created_by': SupaFlow.client.auth.currentUser?.id,
            }));
    if (ok && mounted) _say('${idea.title} planned for ${_onDay(day)}.');
  }

  Future<void> _swap(_Entry entry, MealIdeaStruct idea) async {
    final ok =
        await _write(() => SupaFlow.client.from('meal_plan_entries').update({
              'title': idea.title.length > 120
                  ? idea.title.substring(0, 120)
                  : idea.title,
              'recipe_data': _data(idea)
            }).eq('id', entry.id));
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
    final next =
        DateTime(entry.date.year, entry.date.month, entry.date.day + 1);
    final ok =
        await _write(() => SupaFlow.client.from('meal_plan_entries').insert({
              'household_id': _for,
              'plan_date': _iso(next),
              'meal': 'lunch',
              'title': 'Leftover ${entry.title}'.length > 120
                  ? entry.title
                  : 'Leftover ${entry.title}',
              'recipe_data': {
                ...entry.data,
                'uses': <String>[],
                'extras': <String>[],
                'leftoverOf': entry.id,
                'steps': [
                  'Reheat the extra portions from ${_dayName(entry.date)}.'
                ],
              },
              'servings': entry.extra.clamp(1, 12),
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

  Future<void> _loadBudget() async {
    final household = _for;
    if (household.isEmpty) return;
    try {
      final budget = await SupaFlow.client
          .from('household_budgets')
          .select('weekly_amount, currency')
          .eq('household_id', household)
          .maybeSingle();
      final prices = await SupaFlow.client
          .from('known_prices')
          .select('name_key, price, currency')
          .eq('household_id', household)
          .limit(1000);
      final since = DateTime.now().subtract(const Duration(days: 7));
      final receipts = await SupaFlow.client
          .from('receipts')
          .select('total_amount, purchased_at, scanned_at')
          .eq('household_id', household)
          .gte('scanned_at', since.toUtc().toIso8601String());
      if (!mounted || household != _for) return;
      var spent = 0.0;
      for (final r in receipts as List) {
        final m = r as Map;
        if (m['total_amount'] is num)
          spent += (m['total_amount'] as num).toDouble();
      }
      setState(() {
        _budget = budget?['weekly_amount'] is num
            ? (budget!['weekly_amount'] as num).toDouble()
            : null;
        _currency = '${budget?['currency'] ?? 'AUD'}';
        _prices
          ..clear()
          ..addEntries([
            for (final p in prices as List)
              if ((p as Map)['price'] is num)
                MapEntry('${p['name_key']}', (p['price'] as num).toDouble()),
          ]);
        _spent = spent;
        _budgetReady = true;
      });
    } on PostgrestException {
      if (mounted) setState(() => _budgetReady = false);
    } catch (_) {}
  }

  /// The last price paid for something, matched on its name.
  double? _priceOf(String name) {
    final key = name.trim().toLowerCase();
    if (key.isEmpty) return null;
    final exact = _prices[key];
    if (exact != null) return exact;
    for (final e in _prices.entries) {
      if (e.key.length > 2 && (key.contains(e.key) || e.key.contains(key))) {
        return e.value;
      }
    }
    return null;
  }

  String _money(double amount) {
    const symbols = {
      'AUD': r'$',
      'NZD': r'$',
      'USD': r'$',
      'CAD': r'$',
      'GBP': '£',
      'EUR': '€'
    };
    final symbol = symbols[_currency] ?? '$_currency ';
    return amount >= 100
        ? '$symbol${amount.round()}'
        : '$symbol${amount.toStringAsFixed(2)}';
  }

  /// About what an idea's missing things cost, and how many have no price.
  (double, int) _costOf(List<String> extras) {
    var sum = 0.0;
    var unknown = 0;
    for (final x in extras) {
      final p = _priceOf(x);
      if (p == null) {
        unknown++;
      } else {
        sum += p;
      }
    }
    return (sum, unknown);
  }

  Future<void> _openBudget(FlutterFlowTheme t, List<String> needed) async {
    if (!_budgetReady) {
      _say('Budgets are almost ready. Try again soon.');
      return;
    }
    final amount = TextEditingController(
        text: _budget == null ? '' : _budget!.toStringAsFixed(0));
    final unpriced = [
      for (final n in needed)
        if (_priceOf(n) == null) n
    ];
    final typed = {for (final n in unpriced) n: TextEditingController()};
    InputDecoration look(String label) => InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFFFFDF7),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _border),
          ),
        );
    final save = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cream,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheet) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(sheet).viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheet).size.height * 0.88),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Weekly budget',
                      style: t.headlineSmall.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: _ink)),
                  const SizedBox(height: 4),
                  Text('For the whole household’s food shopping.',
                      style: t.bodyLarge.copyWith(color: _muted, fontSize: 16)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amount,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: look('Amount a week ($_currency)'),
                  ),
                  if (unpriced.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _label(t, 'Prices we don’t know yet'),
                    Text(
                        'Scanning receipts fills these in. Or type what you usually pay.',
                        style:
                            t.bodySmall.copyWith(color: _muted, fontSize: 13)),
                    const SizedBox(height: 8),
                    for (final n in unpriced)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TextField(
                          controller: typed[n],
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: look(n),
                        ),
                      ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
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
                      onPressed: () => Navigator.of(sheet).pop(true),
                      child: Text('Save',
                          style: t.bodyLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    double? number(String s) =>
        double.tryParse(s.replaceAll(RegExp(r'[^0-9.]'), ''));
    final weekly = number(amount.text);
    final newPrices = <Map<String, dynamic>>[
      for (final e in typed.entries)
        if ((number(e.value.text) ?? 0) > 0)
          {
            'household_id': _for,
            'name_key': e.key.trim().toLowerCase(),
            'display_name': e.key.trim(),
            'price': (number(e.value.text)! * 100).round() / 100,
            'currency': _currency,
            'source': 'typed',
            'seen_at': DateTime.now().toUtc().toIso8601String(),
          }
    ];
    Future.delayed(const Duration(milliseconds: 500), amount.dispose);
    Future.delayed(const Duration(milliseconds: 500), () {
      for (final c in typed.values) {
        c.dispose();
      }
    });
    if (save != true || !mounted) return;
    try {
      await SupaFlow.client.from('household_budgets').upsert({
        'household_id': _for,
        'weekly_amount': weekly,
        'currency': _currency,
        'updated_by': SupaFlow.client.auth.currentUser?.id,
      });
      if (newPrices.isNotEmpty) {
        await SupaFlow.client
            .from('known_prices')
            .upsert(newPrices, onConflict: 'household_id,name_key');
      }
      await _loadBudget();
      if (mounted) _say('Budget saved.');
    } catch (_) {
      if (mounted) _say('Could not save the budget. Check your signal.');
    }
  }

  Widget _budgetCard(FlutterFlowTheme t, List<String> needed) {
    final (cost, unknown) = _costOf(needed);
    final budget = _budget;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
      decoration: _uCard(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Budget',
                    style: t.titleMedium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _ink)),
              ),
              TextButton(
                style: TextButton.styleFrom(
                    minimumSize: const Size(48, 44), foregroundColor: _forest),
                onPressed: () => _openBudget(t, needed),
                child: Text(budget == null ? 'Set a weekly budget' : 'Change',
                    style: t.bodyMedium
                        .copyWith(color: _forest, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                    needed.isEmpty
                        ? 'The planned meals need nothing to buy.'
                        : 'About ${_money(cost)} to buy for the planned meals${budget == null ? '' : ', of ${_money(budget)} a week'}.',
                    style: t.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _ink,
                        fontSize: 16)),
                if (budget != null && budget > 0) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: ((cost + _spent) / budget).clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: _sage,
                      valueColor: AlwaysStoppedAnimation(
                          (cost + _spent) > budget
                              ? const Color(0xFFB54708)
                              : _forest),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                    [
                      if (_spent > 0)
                        '${_money(_spent)} spent in the last 7 days, from receipts.',
                      if (budget != null && (cost + _spent) > budget)
                        'That is about ${_money(cost + _spent - budget)} over the budget. Swapping a meal for one that uses only your food helps.',
                      if (unknown > 0)
                        '${unknown == 1 ? '1 thing has' : '$unknown things have'} no price yet, so it may cost more.',
                      'Estimated from the last prices you paid. Prices change.',
                    ].join(' '),
                    style: t.bodySmall.copyWith(color: _muted, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static List<String> _words(Object? v) => v is List
      ? [
          for (final x in v)
            if ('$x'.trim().isNotEmpty) '$x'.trim()
        ]
      : <String>[];

  static String _stem(String w) {
    final s = w.trim().toLowerCase();
    if (s.length > 4 && s.endsWith('es')) return s.substring(0, s.length - 2);
    if (s.length > 3 && s.endsWith('s')) return s.substring(0, s.length - 1);
    return s;
  }

  static double _portionOf(Object? v) => v is num ? v.toDouble() : 1;

  static String _portionName(double p) =>
      p <= 0.5 ? 'small' : (p >= 1.5 ? 'large' : 'regular');

  Future<void> _loadDiners({bool seed = false}) async {
    final household = _for;
    if (household.isEmpty) return;
    try {
      if (seed) await _seedMembers(household);
      final diners = await SupaFlow.client
          .from('household_diners')
          .select('id, profile_id, name, default_portion, allergens')
          .eq('household_id', household)
          .order('created_at');
      final ids = [for (final e in _entries) e.id];
      final plates = ids.isEmpty
          ? const []
          : await SupaFlow.client
              .from('meal_plan_diners')
              .select('plan_entry_id, diner_id, portions')
              .inFilter('plan_entry_id', ids);
      if (!mounted || household != _for) return;
      final list = [for (final d in diners as List) d as Map];
      setState(() {
        _diners = list;
        _plates.clear();
        for (final p in plates as List) {
          final m = p as Map;
          _plates.putIfAbsent(
                  '${m['plan_entry_id']}', () => {})['${m['diner_id']}'] =
              _portionOf(m['portions']);
        }
        _dinersReady = true;
      });
      // Ideas found for the household leave out everyone's allergies.
      final avoid = <String>{
        for (final d in list)
          ..._words(d['allergens']).map((a) => a.toLowerCase())
      }.join(', ');
      if (FFAppState().ideasHouseholdAvoid != avoid) {
        FFAppState().update(() => FFAppState().ideasHouseholdAvoid = avoid);
      }
    } on PostgrestException {
      if (mounted) setState(() => _dinersReady = false);
    } catch (_) {}
  }

  /// Everyone in the household with an account is someone who eats at home.
  /// Their name and allergies follow their own profile.
  Future<void> _seedMembers(String household) async {
    final members = await SupaFlow.client
        .from('household_members')
        .select('profile_id')
        .eq('household_id', household);
    final ids = [
      for (final m in members as List) '${(m as Map)['profile_id']}'
    ];
    if (ids.isEmpty) return;
    final profiles = await SupaFlow.client
        .from('profiles')
        .select('id, display_name, allergens, dietary_preferences')
        .inFilter('id', ids);
    final existing = await SupaFlow.client
        .from('household_diners')
        .select('id, profile_id, name, allergens')
        .eq('household_id', household)
        .not('profile_id', 'is', null);
    final byProfile = {
      for (final d in existing as List) '${(d as Map)['profile_id']}': d
    };
    for (final p in profiles as List) {
      final m = p as Map;
      final id = '${m['id']}';
      final name = '${m['display_name'] ?? ''}'.trim();
      final allergens = _words(m['allergens']);
      final had = byProfile[id];
      if (had == null) {
        await SupaFlow.client.from('household_diners').upsert({
          'household_id': household,
          'profile_id': id,
          'name': name.isEmpty ? 'Someone' : name,
          'allergens': allergens,
          'dietary_preferences': _words(m['dietary_preferences']),
          'created_by': SupaFlow.client.auth.currentUser?.id,
        }, onConflict: 'household_id,profile_id', ignoreDuplicates: true);
      } else if (_words(had['allergens']).join(',') != allergens.join(',') ||
          (name.isNotEmpty && '${had['name']}' != name)) {
        await SupaFlow.client.from('household_diners').update({
          if (name.isNotEmpty) 'name': name,
          'allergens': allergens,
        }).eq('id', '${had['id']}');
      }
    }
  }

  /// Who eats this meal, by name, or '' when nobody has been chosen.
  String _eaters(_Entry e) {
    final plate = _plates[e.id];
    if (plate == null || plate.isEmpty) return '';
    return [
      for (final d in _diners)
        if (plate.containsKey('${d['id']}'))
          '${d['name']}${plate['${d['id']}']! <= 0.5 ? ' (small)' : ''}'
    ].join(', ');
  }

  /// "Mia avoids eggs" for each eater whose allergy the meal mentions.
  List<String> _clashes(_Entry e) {
    final plate = _plates[e.id];
    final eaters = [
      for (final d in _diners)
        if (plate == null || plate.isEmpty || plate.containsKey('${d['id']}')) d
    ];
    final text = [e.title, ...e.list('uses'), ...e.list('extras')]
        .join('\n')
        .toLowerCase();
    return [
      for (final d in eaters)
        for (final a in _words(d['allergens']))
          if (_stem(a).length > 1 && text.contains(_stem(a)))
            '${d['name']} avoids ${a.toLowerCase()}'
    ];
  }

  Future<void> _setEater(_Entry e, Map d, bool eating) async {
    final dinerId = '${d['id']}';
    try {
      if (eating) {
        await SupaFlow.client.from('meal_plan_diners').upsert({
          'plan_entry_id': e.id,
          'diner_id': dinerId,
          'household_id': _for,
          'portions': _portionOf(d['default_portion']),
        });
      } else {
        await SupaFlow.client
            .from('meal_plan_diners')
            .delete()
            .eq('plan_entry_id', e.id)
            .eq('diner_id', dinerId);
      }
      final plate = Map<String, double>.of(_plates[e.id] ?? {});
      if (eating) {
        plate[dinerId] = _portionOf(d['default_portion']);
      } else {
        plate.remove(dinerId);
      }
      if (mounted) setState(() => _plates[e.id] = plate);
      if (plate.isNotEmpty) {
        final total = plate.values.fold<double>(0, (a, b) => a + b);
        await SupaFlow.client
            .from('meal_plan_entries')
            .update({'servings': total.ceil().clamp(1, 12)}).eq('id', e.id);
      }
      await _load(_for, quiet: true);
    } catch (_) {
      if (mounted) _say('Could not change who is eating. Check your signal.');
    }
  }

  Future<void> _openDiners(FlutterFlowTheme t) async {
    if (!_dinersReady) {
      _say('Household planning is almost ready. Try again soon.');
      return;
    }
    final name = TextEditingController();
    // Allergy text typed but not yet saved, by diner id.
    final edits = <String, String>{};
    List<String> allergyList(String v) => [
          for (final a in v.split(RegExp(r'[,;\n]')))
            if (a.trim().length > 1) a.trim()
        ];
    await _sheet<void>((sheet, redraw) {
      Future<void> change(Future<void> Function() write) async {
        try {
          await write();
          await _loadDiners();
        } catch (_) {
          if (mounted) _say('Could not save that. Check your signal.');
        }
        try {
          redraw(() {});
        } catch (_) {}
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Who eats at home',
              style: t.headlineSmall.copyWith(
                  fontSize: 24, fontWeight: FontWeight.w800, color: _ink)),
          const SizedBox(height: 4),
          Text(
              'Portions add up to a meal’s servings. Allergies are left out of ideas found for the household.',
              style: t.bodyMedium.copyWith(color: _muted, fontSize: 14)),
          const SizedBox(height: 16),
          for (final d in _diners)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
              decoration: _uCard(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('${d['name']}',
                            style: t.bodyLarge.copyWith(
                                fontWeight: FontWeight.w700, color: _ink)),
                      ),
                      if (d['profile_id'] == null)
                        IconButton(
                          tooltip: 'Remove ${d['name']}',
                          icon: const Icon(Icons.close, color: _muted),
                          onPressed: () => change(() => SupaFlow.client
                              .from('household_diners')
                              .delete()
                              .eq('id', '${d['id']}')),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final p in const [0.5, 1.0, 1.5])
                      _choice(
                          t,
                          p == 0.5
                              ? 'Small portion'
                              : (p == 1.0 ? 'Regular' : 'Large portion'),
                          _portionName(_portionOf(d['default_portion'])) ==
                              _portionName(p),
                          () => change(() => SupaFlow.client
                              .from('household_diners')
                              .update({'default_portion': p}).eq(
                                  'id', '${d['id']}'))),
                  ]),
                  const SizedBox(height: 6),
                  if (d['profile_id'] == null)
                    TextFormField(
                      key: ValueKey('allergy-${d['id']}'),
                      initialValue: _words(d['allergens']).join(', '),
                      onChanged: (v) => edits['${d['id']}'] = v,
                      decoration: const InputDecoration(
                          labelText: 'Allergies or foods to avoid',
                          hintText: 'e.g. peanuts, eggs'),
                      onFieldSubmitted: (v) {
                        edits.remove('${d['id']}');
                        change(() => SupaFlow.client
                            .from('household_diners')
                            .update({'allergens': allergyList(v)}).eq(
                                'id', '${d['id']}'));
                      },
                    )
                  else
                    Text(
                        _words(d['allergens']).isEmpty
                            ? 'No allergies saved in their profile'
                            : 'Avoids ${_words(d['allergens']).join(', ')} (from their profile)',
                        style:
                            t.bodySmall.copyWith(color: _muted, fontSize: 13)),
                ],
              ),
            ),
          const SizedBox(height: 8),
          _label(t, 'Add someone without the app'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(hintText: 'Name, e.g. Mia'),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(
  elevation: 3,
  shadowColor: const Color(0x99033C29),
                  backgroundColor: _forest,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(64, 48),
                ),
                onPressed: () {
                  final n = name.text.trim();
                  if (n.isEmpty) return;
                  name.clear();
                  change(() => SupaFlow.client.from('household_diners').insert({
                        'household_id': _for,
                        'name': n,
                        'created_by': SupaFlow.client.auth.currentUser?.id,
                      }));
                },
                child: const Text('Add'),
              ),
            ],
          ),
        ],
      );
    });
    Future.delayed(const Duration(milliseconds: 500), name.dispose);
    if (edits.isNotEmpty) {
      try {
        for (final e in edits.entries) {
          await SupaFlow.client
              .from('household_diners')
              .update({'allergens': allergyList(e.value)}).eq('id', e.key);
        }
        await _loadDiners();
      } catch (_) {
        if (mounted) _say('Could not save the allergies. Check your signal.');
      }
    }
  }

  Widget _dinersCard(FlutterFlowTheme t) {
    final names = [
      for (final d in _diners)
        '${d['name']}${_portionOf(d['default_portion']) <= 0.5 ? ' (small)' : ''}'
    ];
    return Semantics(
      button: true,
      label: 'Who eats at home',
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openDiners(t),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: _uCard(16),
          child: Row(
            children: [
              const Icon(Icons.groups_outlined, color: _forest, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Who eats at home',
                        style: t.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700, color: _ink)),
                    Text(
                        names.isEmpty
                            ? 'Add the people you cook for'
                            : names.join(', '),
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
          if (FFAppState().ideasGoals) ...[
            _dayProgress(t),
            const SizedBox(height: 16),
          ],
          if (_dinersReady) ...[
            _dinersCard(t),
            const SizedBox(height: 12),
          ],
          for (var i = 0; i < 7; i++) ...[
            _dayCard(t, _dayAt(i)),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
          _shoppingCard(t, needed),
          if (_budgetReady) ...[
            const SizedBox(height: 12),
            _budgetCard(t, needed),
          ],
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
                    decoration: _uBackDeco(),
                    child: const Icon(Icons.arrow_back, color: _uForest, size: 22),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Plan my week.',
                style: t.headlineMedium.copyWith(
                    fontSize: 32, fontWeight: FontWeight.w800, color: _uForest)),
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
                    minimumSize: const Size(48, 44), foregroundColor: _forest),
                onPressed: _busy ? null : () => _openPicker(t, day: day),
                icon: const Icon(Icons.add, size: 18),
                label: Text('Add a meal',
                    style: t.bodyMedium
                        .copyWith(color: _forest, fontWeight: FontWeight.w700)),
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
      if (_eaters(e).isNotEmpty) 'for ${_eaters(e)}',
      if (_clashes(e).isNotEmpty) '⚠ check allergies',
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
                            : (e.status == 'skipped'
                                ? 'Skipped · $meta'
                                : meta),
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
  elevation: 3,
  shadowColor: const Color(0x99033C29),
                  backgroundColor: _forest,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
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
          builder: (sheet, redraw) => Padding(
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(sheet).viewInsets.bottom),
            child: ConstrainedBox(
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
                decoration: _uCard(14),
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
                                if (idea.extras.isNotEmpty &&
                                    _costOf(idea.extras).$2 <
                                        idea.extras.length)
                                  'about ${_money(_costOf(idea.extras).$1)} to buy',
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
                        FFAppState()
                            .update(() => FFAppState().ideasMeal = meal);
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
              label: Text(
                  finding ? 'Looking through your kitchen…' : 'Find new ideas',
                  style: t.bodyLarge
                      .copyWith(color: _forest, fontWeight: FontWeight.w700)),
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
          if (_clashes(e).isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFDE3E0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                  '${_clashes(e).join('. ')}. Check the ingredients before cooking; this is not a medical check.',
                  style: t.bodyMedium.copyWith(
                      color: const Color(0xFFB42318),
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
            ),
          ],
          if (_diners.isNotEmpty) ...[
            const SizedBox(height: 16),
            _label(t, 'Who’s eating'),
            StatefulBuilder(
              builder: (context, again) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final d in _diners)
                    _choice(t, '${d['name']}',
                        _plates[e.id]?.containsKey('${d['id']}') ?? false,
                        () async {
                      await _setEater(e, d,
                          !(_plates[e.id]?.containsKey('${d['id']}') ?? false));
                      try {
                        again(() {});
                      } catch (_) {}
                    }),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text('Servings follow who’s eating and their portions.',
                style: t.bodySmall.copyWith(color: _muted, fontSize: 13)),
          ],
          if (e.status == 'planned' || e.status == 'cooked') ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
  elevation: 3,
  shadowColor: const Color(0x99033C29),
                  backgroundColor: _forest,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
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
            decoration: _uCard(14),
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
                    _stepper(
                        Icons.remove,
                        e.extra > 0,
                        () => act(
                            () => _update(e, {'extra_portions': e.extra - 1}))),
                    SizedBox(
                      width: 36,
                      child: Text('${e.extra}',
                          textAlign: TextAlign.center,
                          style: t.titleMedium.copyWith(color: _ink)),
                    ),
                    _stepper(
                        Icons.add,
                        e.extra < 6,
                        () => act(
                            () => _update(e, {'extra_portions': e.extra + 1}))),
                  ],
                ),
                if (e.extra > 0 &&
                    e.data['leftoverOf'] == null &&
                    !_entries.any((x) => x.data['leftoverOf'] == e.id))
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                          minimumSize: const Size(48, 44),
                          foregroundColor: _forest),
                      onPressed: () => act(() => _planLeftovers(e)),
                      icon: const Icon(Icons.event_repeat, size: 18),
                      label: Text(
                          'Plan the leftovers for ${_onDay(DateTime(e.date.year, e.date.month, e.date.day + 1))}’s lunch',
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
            action(
                Icons.undo,
                'Mark as still to cook',
                () => act(() async {
                      // Your own log of this meal goes too; the kitchen
                      // is left as it is (Undo on the message restores food).
                      final uid = SupaFlow.client.auth.currentUser?.id;
                      if (uid != null) {
                        try {
                          await SupaFlow.client
                              .from('meal_log_entries')
                              .delete()
                              .eq('plan_entry_id', e.id)
                              .eq('profile_id', uid);
                        } catch (_) {}
                      }
                      await _update(
                          e, {'status': 'planned', 'cooked_at': null});
                    })),
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
                _choice(t, _dayName(_dayAt(i)), _sameDay(e.date, _dayAt(i)),
                    () {
                  Navigator.of(sheet).pop();
                  _update(e, {'plan_date': _iso(_dayAt(i))});
                }),
            ]),
          ],
        ));
  }

  /// Pick a meal → cook it → confirm portions → "I ate this".
  Future<void> _openAte(FlutterFlowTheme t, _Entry e) async {
    // The kitchen foods this meal uses, ticked to leave the kitchen.
    var foods = <({String id, String name})>[];
    final exact = <String>{};
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
        if (uses.any((u) => n == u || _wordIn(n, u) || _wordIn(u, n))) {
          foods.add((id: m['id'].toString(), name: name));
          if (uses.contains(n)) exact.add(m['id'].toString());
        }
      }
    } catch (_) {
      foods = [];
    }
    if (!mounted) return;
    // Exact names start ticked; near matches are offered unticked. When the
    // meal was already eaten by someone else, nothing is ticked: the food
    // most likely left the kitchen then.
    final ticked = e.status == 'cooked'
        ? <String>{}
        : {
            for (final f in foods)
              if (exact.contains(f.id) || foods.length <= 3) f.id
          };
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
                    portions == 1
                        ? '1 portion'
                        : '${amount(portions)} portions',
                    textAlign: TextAlign.center,
                    style: t.titleSmall.copyWith(color: _ink)),
              ),
              _stepper(
                  Icons.add, portions < 4, () => redraw(() => portions += 0.5)),
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
                onChanged: (v) => redraw(
                    () => v == true ? ticked.add(f.id) : ticked.remove(f.id)),
              ),
            Text('Untick anything with some left.',
                style: t.bodySmall.copyWith(color: _muted, fontSize: 13)),
          ],
          const SizedBox(height: 20),
          SizedBox(
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
          if (retry != null) ...[
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

/// A food card for the two-column grids: picture, two-line name, amount and
/// the date badge.
Widget _uFoodCard(BuildContext context, Map item, {required VoidCallback onTap}) {
  final t = FlutterFlowTheme.of(context);
  final name = '${item['name'] ?? ''}';
  final photo = foodPhoto(name, '${item['image_url'] ?? ''}') ?? '';
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

const _wRecipeCollection = r'''
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Recipe collection (owner, 14 Sep; a Plus feature): "save favourite recipes
/// and connect their ingredients to inventory and shopping".
///
/// Kept ideas and the household's own recipes in one place. Each says how
/// many of its ingredients are in the kitchen now; "Can cook now" shows only
/// the ones with everything. A recipe opens to its ingredients (in the kitchen
/// or not), one tap for the missing ones onto the shopping list, its steps,
/// notes, a favourite star, and "Add to my week". Your own recipes can be
/// typed in, edited and deleted.
class RecipeCollection extends StatefulWidget {
  const RecipeCollection({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<RecipeCollection> createState() => _RecipeCollectionState();
}

class _RecipeCollectionState extends State<RecipeCollection> {
  static const _forest = Color(0xFF07533A);
  static const _ink = Color(0xFF202C24);
  static const _muted = Color(0xFF59665D);
  static const _sage = Color(0xFFEDF2E8);
  static const _border = Color(0xFFDCE3D7);
  static const _cream = Color(0xFFF7F7F0);
  static const _red = Color(0xFFB42318);
  static const _gold = Color(0xFFB54708);

  static const _filters = <String, String>{
    'all': 'All',
    'favourites': 'Favourites',
    'own': 'Your own',
    'ready': 'Can cook now',
  };
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
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
    'Dec'
  ];

  String _for = '';
  bool _loading = true;
  bool _offline = false;
  String _filter = 'all';
  List<Map> _recipes = const [];
  List<String> _kitchen = const [];
  final Set<String> _listed = {};

  Future<void> _load(String household, {bool quiet = false}) async {
    if (!quiet && mounted) {
      setState(() {
        _loading = true;
        _offline = false;
      });
    }
    try {
      List rows;
      try {
        rows = await SupaFlow.client
            .from('saved_recipes')
            .select(
                'id, title, recipe_data, source, servings, is_favourite, notes, created_at')
            .eq('household_id', household)
            .order('created_at', ascending: false)
            .limit(200);
      } on PostgrestException {
        // Before migration 8: the collection still shows kept ideas.
        rows = await SupaFlow.client
            .from('saved_recipes')
            .select('id, title, recipe_data, created_at')
            .eq('household_id', household)
            .order('created_at', ascending: false)
            .limit(200);
      }
      final foods = await SupaFlow.client
          .from('food_items_status')
          .select('name, computed_status')
          .eq('household_id', household)
          .limit(300);
      if (!mounted || household != _for) return;
      setState(() {
        _recipes = [for (final r in rows) r as Map];
        _kitchen = [
          for (final f in foods as List)
            if (!const ['consumed', 'discarded', 'past_use_by']
                .contains('${(f as Map)['computed_status']}'))
              '${f['name'] ?? ''}'.trim().toLowerCase()
        ];
        _loading = false;
        _offline = false;
      });
    } catch (_) {
      if (!mounted) return;
      if (quiet && _recipes.isNotEmpty) return;
      setState(() {
        _loading = false;
        _offline = true;
      });
    }
  }

  static List<String> _words(Object? v) => v is List
      ? [
          for (final x in v)
            if ('$x'.trim().isNotEmpty) '$x'.trim()
        ]
      : <String>[];

  static String _stem(String w) {
    final s = w.trim().toLowerCase();
    if (s.length > 4 && s.endsWith('es')) return s.substring(0, s.length - 2);
    if (s.length > 3 && s.endsWith('s')) return s.substring(0, s.length - 1);
    return s;
  }

  static Map _data(Map r) =>
      r['recipe_data'] is Map ? r['recipe_data'] as Map : const {};

  /// Every ingredient: for an idea, what it used and what it needed.
  static List<String> _ingredients(Map r) {
    final d = _data(r);
    final own = _words(d['ingredients']);
    if (own.isNotEmpty) return own;
    return [..._words(d['uses']), ..._words(d['extras'])];
  }

  /// Whole-word match either way ("egg" in "Free-range eggs"), so "egg" is
  /// never "eggplant" and "milk" never "coconut milk" alone.
  static bool _wordIn(String hay, String word) {
    final w = word.trim().toLowerCase();
    if (w.length < 2) return false;
    return RegExp('(^|[^a-z])${RegExp.escape(w)}(es|s)?([^a-z]|\$)')
        .hasMatch(hay.toLowerCase());
  }

  bool _inKitchen(String ingredient) {
    final i = ingredient.toLowerCase();
    final si = _stem(i);
    for (final k in _kitchen) {
      if (k.isEmpty) continue;
      final sk = _stem(k);
      if (k == i ||
          (sk.length > 2 && _wordIn(i, sk)) ||
          (si.length > 2 && _wordIn(k, si))) {
        return true;
      }
    }
    return false;
  }

  (int, int) _have(Map r) {
    final all = _ingredients(r);
    return (all.where(_inKitchen).length, all.length);
  }

  List<Map> get _shown {
    final list = _recipes.where((r) {
      switch (_filter) {
        case 'favourites':
          return r['is_favourite'] == true;
        case 'own':
          return r['source'] == 'own';
        case 'ready':
          final (have, all) = _have(r);
          return all > 0 && have == all;
      }
      return true;
    }).toList();
    list.sort((a, b) {
      final fa = a['is_favourite'] == true ? 0 : 1;
      final fb = b['is_favourite'] == true ? 0 : 1;
      if (fa != fb) return fa - fb;
      final (ha, aa) = _have(a);
      final (hb, ab) = _have(b);
      final ra = aa == 0 ? 0.0 : ha / aa;
      final rb = ab == 0 ? 0.0 : hb / ab;
      return rb.compareTo(ra);
    });
    return list;
  }

  void _say(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  String _why(Object error) {
    if (error is PostgrestException && error.code == '42501') {
      return 'Your account is not allowed to change this household’s recipes.';
    }
    if (error is PostgrestException &&
        (error.code == '42703' || error.code == 'PGRST204')) {
      return 'Your own recipes are almost ready. Try again soon.';
    }
    return 'Could not save that. Check your signal and try again.';
  }

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
    final shown = _shown;

    Widget content;
    if (_loading) {
      content = Column(children: [
        for (var i = 0; i < 3; i++) ...[
          Container(
            height: 88,
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
          'Can’t reach your recipes.',
          'No signal, or the connection dropped. Try again when you are back online.',
          retry: () => _load(_for));
    } else if (_recipes.isEmpty) {
      content = _message(t, Icons.menu_book_outlined, 'No recipes yet.',
          'Keep ideas you like on Recipes, or add a recipe of your own.');
    } else if (shown.isEmpty) {
      content = _message(
          t,
          Icons.filter_alt_off_outlined,
          'Nothing here.',
          _filter == 'ready'
              ? 'No recipe has everything in your kitchen right now.'
              : 'Try another filter.');
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final r in shown) ...[
            _card(t, r),
            const SizedBox(height: 12),
          ],
        ],
      );
    }

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
                    decoration: _uBackDeco(),
                    child: const Icon(Icons.arrow_back, color: _uForest, size: 22),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Your recipes.',
                style: t.headlineMedium.copyWith(
                    fontSize: 32, fontWeight: FontWeight.w800, color: _uForest)),
            const SizedBox(height: 4),
            Text('Kept ideas and your own, shared with your household.',
                style: t.bodyLarge.copyWith(color: _muted, fontSize: 16)),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
  elevation: 3,
  shadowColor: const Color(0x99033C29),
                  backgroundColor: _forest,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => _edit(t, null),
                icon: const Icon(Icons.add, size: 20),
                label: Text('Add your own recipe',
                    style: t.bodyLarge.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                children: [
                  for (final e in _filters.entries) ...[
                    _choice(t, e.value, _filter == e.key,
                        () => setState(() => _filter = e.key)),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _card(FlutterFlowTheme t, Map r) {
    final (have, all) = _have(r);
    final minutes =
        _data(r)['minutes'] is num ? (_data(r)['minutes'] as num).round() : 0;
    final fav = r['is_favourite'] == true;
    return Semantics(
      button: true,
      label: '${r['title']}',
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _open(t, r),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 6, 12),
          decoration: _uCard(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${r['title']}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodyLarge.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: _ink)),
                    const SizedBox(height: 4),
                    Wrap(spacing: 6, runSpacing: 4, children: [
                      if (all > 0)
                        _pill(
                            t,
                            have == all
                                ? 'Everything in your kitchen'
                                : 'You have $have of $all',
                            have == all ? _forest : _muted,
                            have == all ? const Color(0xFFDDF0E2) : _sage),
                      if (minutes > 0) _pill(t, '$minutes min', _muted, _sage),
                      if (r['source'] == 'own')
                        _pill(t, 'Your own', _muted, _sage),
                    ]),
                  ],
                ),
              ),
              IconButton(
                tooltip: fav ? 'Take out of favourites' : 'Add to favourites',
                onPressed: () => _favourite(r),
                icon: Icon(fav ? Icons.star : Icons.star_border,
                    color: fav ? _gold : _muted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _favourite(Map r) async {
    try {
      await SupaFlow.client.from('saved_recipes').update(
          {'is_favourite': r['is_favourite'] != true}).eq('id', '${r['id']}');
      await _load(_for, quiet: true);
    } catch (error) {
      if (mounted) _say(_why(error));
    }
  }

  Future<void> _open(FlutterFlowTheme t, Map r) async {
    final all = _ingredients(r);
    final missing = [
      for (final i in all)
        if (!_inKitchen(i)) i
    ];
    final d = _data(r);
    final steps = _words(d['steps']);
    final notes = TextEditingController(text: '${r['notes'] ?? ''}');
    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cream,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, redraw) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(sheet).viewInsets.bottom),
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheet).size.height * 0.9),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('${r['title']}',
                        style: t.headlineSmall.copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                            height: 1.15)),
                    const SizedBox(height: 16),
                    _label(t, 'Ingredients'),
                    for (final i in all)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(
                                _inKitchen(i)
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: _inKitchen(i) ? _forest : _muted,
                                size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(i,
                                  style: t.bodyLarge
                                      .copyWith(fontSize: 16, color: _ink)),
                            ),
                            Text(_inKitchen(i) ? 'In your kitchen' : '',
                                style: t.bodySmall
                                    .copyWith(color: _muted, fontSize: 12)),
                          ],
                        ),
                      ),
                    if (missing.isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                              minimumSize: const Size(48, 48),
                              foregroundColor: _forest),
                          onPressed: _listed.contains('${r['id']}')
                              ? null
                              : () async {
                                  for (final m in missing) {
                                    final said = await addNameToShoppingList(m);
                                    if (said.isNotEmpty) {
                                      if (mounted) _say(said);
                                      return;
                                    }
                                  }
                                  _listed.add('${r['id']}');
                                  try {
                                    redraw(() {});
                                  } catch (_) {}
                                  if (mounted) {
                                    _say(missing.length == 1
                                        ? '1 thing added to your shopping list.'
                                        : '${missing.length} things added to your shopping list.');
                                  }
                                },
                          icon: Icon(
                              _listed.contains('${r['id']}')
                                  ? Icons.check
                                  : Icons.add_shopping_cart,
                              size: 18),
                          label: Text(
                              _listed.contains('${r['id']}')
                                  ? 'On your shopping list'
                                  : 'Add ${missing.length} missing to the shopping list',
                              style: t.bodyLarge.copyWith(
                                  color: _listed.contains('${r['id']}')
                                      ? _muted
                                      : _forest,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    if (steps.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _label(t, 'Steps'),
                      for (var i = 0; i < steps.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text('${i + 1}. ${steps[i]}',
                              style: t.bodyLarge.copyWith(
                                  fontSize: 16, color: _ink, height: 1.4)),
                        ),
                    ],
                    if (r.containsKey('notes')) ...[
                      const SizedBox(height: 12),
                      _label(t, 'Notes'),
                      TextField(
                        controller: notes,
                        maxLines: 3,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: 'e.g. Kids like it with extra cheese',
                          filled: true,
                          fillColor: const Color(0xFFFFFDF7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: _border),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
  elevation: 3,
  shadowColor: const Color(0x99033C29),
                          backgroundColor: _forest,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () => Navigator.of(sheet).pop('week'),
                        icon:
                            const Icon(Icons.calendar_month_outlined, size: 20),
                        label: Text('Add to my week',
                            style: t.bodyLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                    if (r['source'] == 'own')
                      TextButton.icon(
                        style: TextButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            foregroundColor: _forest),
                        onPressed: () => Navigator.of(sheet).pop('edit'),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: Text('Edit this recipe',
                            style: t.bodyLarge.copyWith(
                                color: _forest, fontWeight: FontWeight.w700)),
                      ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          foregroundColor: _red),
                      onPressed: () => Navigator.of(sheet).pop('delete'),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: Text(
                          r['source'] == 'own'
                              ? 'Delete this recipe'
                              : 'Remove from your recipes',
                          style: t.bodyLarge.copyWith(
                              color: _red, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final note = notes.text.trim();
    Future.delayed(const Duration(milliseconds: 500), notes.dispose);
    if (!mounted) return;
    if (r.containsKey('notes') && note != '${r['notes'] ?? ''}'.trim()) {
      try {
        await SupaFlow.client.from('saved_recipes').update(
            {'notes': note.isEmpty ? null : note}).eq('id', '${r['id']}');
        await _load(_for, quiet: true);
      } catch (error) {
        if (mounted) _say(_why(error));
      }
    }
    if (!mounted) return;
    switch (action) {
      case 'week':
        await _toWeek(t, r);
        break;
      case 'edit':
        await _edit(t, r);
        break;
      case 'delete':
        final sure = await showDialog<bool>(
          context: context,
          builder: (dlg) => AlertDialog(
            title: Text(r['source'] == 'own'
                ? 'Delete this recipe?'
                : 'Remove this recipe?'),
            content: const Text(
                'It goes for everyone in your household. Meals already planned keep their steps.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(dlg).pop(false),
                  child: const Text('Keep it')),
              TextButton(
                  onPressed: () => Navigator.of(dlg).pop(true),
                  child: const Text('Delete', style: TextStyle(color: _red))),
            ],
          ),
        );
        if (sure != true) return;
        try {
          await SupaFlow.client
              .from('saved_recipes')
              .delete()
              .eq('id', '${r['id']}');
          await _load(_for, quiet: true);
          if (mounted) _say('Removed from your recipes.');
        } catch (error) {
          if (mounted) _say(_why(error));
        }
    }
  }

  Future<void> _toWeek(FlutterFlowTheme t, Map r) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    String name(int i) {
      if (i == 0) return 'Today';
      if (i == 1) return 'Tomorrow';
      final d = DateTime(today.year, today.month, today.day + i);
      return '${_days[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';
    }

    var day = 0;
    var meal = 'dinner';
    final go = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: _cream,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, redraw) => SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Add to my week',
                    style: t.headlineSmall.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: _ink)),
                const SizedBox(height: 16),
                _label(t, 'Day'),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (var i = 0; i < 7; i++)
                    _choice(t, name(i), day == i, () => redraw(() => day = i)),
                ]),
                const SizedBox(height: 16),
                _label(t, 'Meal'),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final m in const [
                    'breakfast',
                    'lunch',
                    'dinner',
                    'snack'
                  ])
                    _choice(t, m[0].toUpperCase() + m.substring(1), meal == m,
                        () => redraw(() => meal = m)),
                ]),
                const SizedBox(height: 20),
                SizedBox(
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
                    onPressed: () => Navigator.of(sheet).pop(true),
                    child: Text('Add',
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
    final d = DateTime(today.year, today.month, today.day + day);
    final all = _ingredients(r);
    final data = _data(r);
    try {
      await SupaFlow.client.from('meal_plan_entries').insert({
        'household_id': _for,
        'plan_date':
            '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
        'meal': meal,
        'title': '${r['title']}'.length > 120
            ? '${r['title']}'.substring(0, 120)
            : '${r['title']}',
        // What is in the kitchen now, and what the week's shopping needs.
        'recipe_data': {
          'uses': [
            for (final i in all)
              if (_inKitchen(i)) i
          ],
          'extras': [
            for (final i in all)
              if (!_inKitchen(i)) i
          ],
          'steps': _words(data['steps']),
          'minutes': data['minutes'] is num ? data['minutes'] : 0,
          if (data['calories'] is num) 'calories': data['calories'],
          if (data['protein'] is num) 'protein': data['protein'],
        },
        'servings': r['servings'] is num
            ? (r['servings'] as num).round().clamp(1, 12)
            : (data['servings'] is num && (data['servings'] as num) > 0
                ? data['servings']
                : 2),
        'created_by': SupaFlow.client.auth.currentUser?.id,
      });
      if (!mounted) return;
      final router = GoRouter.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Planned for ${day < 2 ? name(day).toLowerCase() : name(day)}.'),
        action: SnackBarAction(
          label: 'See the week',
          textColor: const Color(0xFFB9E08F),
          onPressed: () => router.pushNamed('PlanWeekPage'),
        ),
      ));
    } catch (error) {
      if (mounted) _say(_why(error));
    }
  }

  /// Add (r == null) or edit one of your own recipes.
  Future<void> _edit(FlutterFlowTheme t, Map? r) async {
    final d = r == null ? const {} : _data(r);
    final title = TextEditingController(text: r == null ? '' : '${r['title']}');
    final ingredients =
        TextEditingController(text: _words(d['ingredients']).join('\n'));
    final steps = TextEditingController(text: _words(d['steps']).join('\n'));
    var servings = r?['servings'] is num ? (r!['servings'] as num).round() : 2;
    var minutes = d['minutes'] is num ? (d['minutes'] as num).round() : 30;
    InputDecoration look(String label, String hint) => InputDecoration(
          labelText: label,
          hintText: hint,
          alignLabelWithHint: true,
          filled: true,
          fillColor: const Color(0xFFFFFDF7),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _border),
          ),
        );
    final save = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cream,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, redraw) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(sheet).viewInsets.bottom),
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheet).size.height * 0.92),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(r == null ? 'Your own recipe' : 'Edit recipe',
                        style: t.headlineSmall.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: _ink)),
                    const SizedBox(height: 16),
                    TextField(
                        controller: title,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: look('Name', 'e.g. Nan’s lentil soup')),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _label(t, 'Serves')),
                        _stepper(Icons.remove, servings > 1,
                            () => redraw(() => servings--)),
                        SizedBox(
                            width: 40,
                            child: Text('$servings',
                                textAlign: TextAlign.center,
                                style: t.titleMedium.copyWith(color: _ink))),
                        _stepper(Icons.add, servings < 12,
                            () => redraw(() => servings++)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _label(t, 'Minutes')),
                        _stepper(Icons.remove, minutes > 5,
                            () => redraw(() => minutes -= 5)),
                        SizedBox(
                            width: 40,
                            child: Text('$minutes',
                                textAlign: TextAlign.center,
                                style: t.titleMedium.copyWith(color: _ink))),
                        _stepper(Icons.add, minutes < 240,
                            () => redraw(() => minutes += 5)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                        controller: ingredients,
                        minLines: 4,
                        maxLines: 10,
                        decoration: look('Ingredients, one per line',
                            'Red lentils\nOnion\nCarrots')),
                    const SizedBox(height: 12),
                    TextField(
                        controller: steps,
                        minLines: 4,
                        maxLines: 12,
                        decoration: look('Steps, one per line',
                            'Soften the onion\nAdd lentils and water')),
                    const SizedBox(height: 16),
                    SizedBox(
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
                        onPressed: () {
                          if (title.text.trim().isEmpty) return;
                          Navigator.of(sheet).pop(true);
                        },
                        child: Text('Save recipe',
                            style: t.bodyLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    List<String> lines(TextEditingController c) => [
          for (final l in c.text.split('\n'))
            if (l.trim().isNotEmpty) l.trim()
        ];
    final row = {
      'title': title.text.trim().length > 120
          ? title.text.trim().substring(0, 120)
          : title.text.trim(),
      'source': 'own',
      'servings': servings,
      'recipe_data': {
        'ingredients': lines(ingredients),
        'steps': lines(steps),
        'minutes': minutes,
        'servings': servings,
      },
    };
    Future.delayed(const Duration(milliseconds: 500), () {
      title.dispose();
      ingredients.dispose();
      steps.dispose();
    });
    if (save != true || !mounted) return;
    try {
      if (r == null) {
        await SupaFlow.client.from('saved_recipes').insert({
          ...row,
          'household_id': _for,
          'profile_id': SupaFlow.client.auth.currentUser?.id,
        });
      } else {
        await SupaFlow.client
            .from('saved_recipes')
            .update(row)
            .eq('id', '${r['id']}');
      }
      await _load(_for, quiet: true);
      if (mounted) _say(r == null ? 'Recipe saved.' : 'Recipe updated.');
    } catch (error) {
      if (mounted) _say(_why(error));
    }
  }

  Widget _pill(FlutterFlowTheme t, String text, Color fg, Color bg) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Text(text,
            style: t.bodySmall.copyWith(
                color: fg, fontWeight: FontWeight.w700, fontSize: 12)),
      );

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
      {VoidCallback? retry}) {
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
          if (retry != null) ...[
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
                onPressed: retry,
                child: const Text('Try again'),
              ),
            ),
          ],
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

/// A food card for the two-column grids: picture, two-line name, amount and
/// the date badge.
Widget _uFoodCard(BuildContext context, Map item, {required VoidCallback onTap}) {
  final t = FlutterFlowTheme.of(context);
  final name = '${item['name'] ?? ''}';
  final photo = foodPhoto(name, '${item['image_url'] ?? ''}') ?? '';
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

const _wItemEditFields = r'''
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

  static String _iso(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
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
      initialDate:
          now.isBefore(first) ? first : (now.isAfter(last) ? last : now),
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
    final counted =
        FFAppState().editQuantity < 1 ? 1 : FFAppState().editQuantity;
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
            onChanged: (v) => _set(() => FFAppState().editCategory = v ?? ''),
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
            onChanged: (v) => _set(() => FFAppState().editLocationId = v ?? ''),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _label(t, 'How many')),
              _step(
                  t,
                  Icons.remove,
                  'One fewer',
                  counted > 1
                      ? () =>
                          _set(() => FFAppState().editQuantity = counted - 1)
                      : null),
              SizedBox(
                width: 56,
                child: Text('$counted',
                    textAlign: TextAlign.center, style: t.titleSmall),
              ),
              _step(
                  t,
                  Icons.add,
                  'One more',
                  counted < 99
                      ? () =>
                          _set(() => FFAppState().editQuantity = counted + 1)
                      : null),
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

/// A food card for the two-column grids: picture, two-line name, amount and
/// the date badge.
Widget _uFoodCard(BuildContext context, Map item, {required VoidCallback onTap}) {
  final t = FlutterFlowTheme.of(context);
  final name = '${item['name'] ?? ''}';
  final photo = foodPhoto(name, '${item['image_url'] ?? ''}') ?? '';
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

const _wHouseholdMembers = r'''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// One line saying who is in the household the app is showing: "Just you so
/// far." or "2 members: Ash and you". A member whose name is not visible is
/// "someone".
class HouseholdMembers extends StatefulWidget {
  const HouseholdMembers({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<HouseholdMembers> createState() => _HouseholdMembersState();
}

class _HouseholdMembersState extends State<HouseholdMembers> {
  String _for = '';
  Future<List<String>>? _names;

  Future<List<String>> _load(String household) async {
    final members = await SupaFlow.client
        .from('household_members')
        .select('profile_id')
        .eq('household_id', household)
        .order('joined_at');
    final ids = [
      for (final m in members as List) (m as Map)['profile_id'].toString(),
    ];
    final me = SupaFlow.client.auth.currentUser?.id;
    final names = <String>[];
    for (final id in ids) {
      if (id == me) {
        names.add('you');
        continue;
      }
      var name = '';
      try {
        final p = await SupaFlow.client
            .from('profiles')
            .select('display_name')
            .eq('id', id)
            .maybeSingle();
        name = (p?['display_name'] ?? '').toString().trim();
      } catch (_) {}
      names.add(name.isEmpty ? 'someone' : name);
    }
    return names;
  }

  static String _join(List<String> n) => n.length < 2
      ? n.join()
      : '${n.sublist(0, n.length - 1).join(', ')} and ${n.last}';

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final household = FFAppState().currentHouseholdId;
    if (household.isEmpty) return const SizedBox.shrink();
    if (household != _for) {
      _for = household;
      _names = _load(household);
    }
    final t = FlutterFlowTheme.of(context);
    return FutureBuilder<List<String>>(
      future: _names,
      builder: (context, snap) {
        final names = snap.data;
        if (names == null || names.isEmpty) return const SizedBox.shrink();
        final line = names.length == 1
            ? 'Just you so far.'
            : '${names.length} members: ${_join(names)}';
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Icon(Icons.group_outlined, size: 18, color: t.secondaryText),
              const SizedBox(width: 6),
              Expanded(
                child: Text(line,
                    style: t.bodyMedium.copyWith(color: t.secondaryText)),
              ),
            ],
          ),
        );
      },
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

/// A food card for the two-column grids: picture, two-line name, amount and
/// the date badge.
Widget _uFoodCard(BuildContext context, Map item, {required VoidCallback onTap}) {
  final t = FlutterFlowTheme.of(context);
  final name = '${item['name'] ?? ''}';
  final photo = foodPhoto(name, '${item['image_url'] ?? ''}') ?? '';
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

const _wHouseholdSwitcher = r'''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// For someone in more than one household: each household, the one the app is
/// showing marked, and a tap to show another. Nothing at all for someone in
/// one household.
///
/// Switching sets the household every screen follows, and clears meal ideas,
/// which were built from the other kitchen's food.
class HouseholdSwitcher extends StatefulWidget {
  const HouseholdSwitcher({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<HouseholdSwitcher> createState() => _HouseholdSwitcherState();
}

class _HouseholdSwitcherState extends State<HouseholdSwitcher> {
  List<Map<String, dynamic>> _households = const [];
  bool _loading = false;
  String _reloadedFor = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    _loading = true;
    try {
      final rows = await SupaFlow.client
          .from('households')
          .select('id, name')
          .order('created_at', ascending: true);
      if (!mounted) return;
      setState(
          () => _households = List<Map<String, dynamic>>.from(rows as List));
    } catch (_) {
      // No signal: the screen's own card still says which household it is.
    } finally {
      _loading = false;
    }
  }

  void _show(String id, String name) {
    FFAppState().update(() {
      FFAppState().currentHouseholdId = id;
      FFAppState().mealIdeas = [];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Now showing $name.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final t = FlutterFlowTheme.of(context);
    final current = FFAppState().currentHouseholdId;
    final ids = [for (final h in _households) h['id'].toString()];

    // A household created or joined since this loaded: read the list again,
    // once per new id, so it appears here.
    if (current.isNotEmpty &&
        !ids.contains(current) &&
        _reloadedFor != current) {
      _reloadedFor = current;
      _load();
    }
    if (_households.length < 2) return const SizedBox.shrink();

    return Container(
      width: widget.width ?? double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      decoration: _uCard(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Your households', style: t.titleMedium),
          const SizedBox(height: 2),
          Text(
            'Choose which kitchen the app shows.',
            style: t.bodySmall.copyWith(color: t.secondaryText),
          ),
          const SizedBox(height: 8),
          for (final h in _households) _row(t, h, current),
        ],
      ),
    );
  }

  Widget _row(FlutterFlowTheme t, Map<String, dynamic> h, String current) {
    final id = h['id'].toString();
    final name = (h['name'] ?? '').toString();
    final on = id == current;
    return Semantics(
      button: !on,
      selected: on,
      label: on ? '$name, showing now' : 'Show $name',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: on ? null : () => _show(id, name),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(
                on ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                size: 22,
                color: on ? t.primary : t.secondaryText,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodyLarge.copyWith(
                    fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (on)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: t.accent1,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Showing',
                    style: t.bodySmall.copyWith(
                        color: t.primary, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
        ),
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

/// A food card for the two-column grids: picture, two-line name, amount and
/// the date badge.
Widget _uFoodCard(BuildContext context, Map item, {required VoidCallback onTap}) {
  final t = FlutterFlowTheme.of(context);
  final name = '${item['name'] ?? ''}';
  final photo = foodPhoto(name, '${item['image_url'] ?? ''}') ?? '';
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

const _wLeaveHouseholdButton = r'''
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// "Leave this household", with the second tap as the confirmation.
///
/// Nothing is shown to the owner of the household: they cannot leave their own
/// kitchen, and a button that only ever refuses is worse than no button.
class LeaveHouseholdButton extends StatefulWidget {
  const LeaveHouseholdButton({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<LeaveHouseholdButton> createState() => _LeaveHouseholdButtonState();
}

class _LeaveHouseholdButtonState extends State<LeaveHouseholdButton> {
  String _for = '';
  bool _owner = true; // assume owner until told otherwise: shows nothing
  bool _asking = false;
  bool _leaving = false;
  Timer? _forget;

  @override
  void dispose() {
    _forget?.cancel();
    super.dispose();
  }

  Future<void> _whoOwns(String household) async {
    try {
      final row = await SupaFlow.client
          .from('households')
          .select('owner_id')
          .eq('id', household)
          .maybeSingle();
      final uid = SupaFlow.client.auth.currentUser?.id;
      if (!mounted || household != _for) return;
      setState(() =>
          _owner = row == null || (row['owner_id'] ?? '').toString() == uid);
    } catch (_) {
      // Leave it hidden rather than offer something that will refuse.
    }
  }

  Future<void> _leave() async {
    setState(() {
      _leaving = true;
      _asking = false;
    });
    final said = await leaveHousehold();
    if (!mounted) return;
    setState(() => _leaving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(said.isEmpty ? 'You have left that household.' : said),
    ));
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final household = FFAppState().currentHouseholdId;
    if (household.isEmpty) return const SizedBox.shrink();
    if (household != _for) {
      _for = household;
      _owner = true;
      _asking = false;
      _whoOwns(household);
    }
    if (_owner) return const SizedBox.shrink();

    final t = FlutterFlowTheme.of(context);
    final label = _leaving
        ? 'Leaving…'
        : (_asking ? 'Tap again to leave' : 'Leave this household');

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: _leaving
              ? null
              : () {
                  if (_asking) {
                    _forget?.cancel();
                    _leave();
                    return;
                  }
                  setState(() => _asking = true);
                  _forget?.cancel();
                  _forget = Timer(const Duration(seconds: 4), () {
                    if (mounted) setState(() => _asking = false);
                  });
                },
          style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
          icon: Icon(Icons.logout, size: 18, color: t.error),
          label: Text(
            label,
            style: t.bodyMedium
                .copyWith(color: t.error, fontWeight: FontWeight.w700),
          ),
        ),
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

/// A food card for the two-column grids: picture, two-line name, amount and
/// the date badge.
Widget _uFoodCard(BuildContext context, Map item, {required VoidCallback onTap}) {
  final t = FlutterFlowTheme.of(context);
  final name = '${item['name'] ?? ''}';
  final photo = foodPhoto(name, '${item['image_url'] ?? ''}') ?? '';
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

const _wPutItBack = r'''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The last few foods marked used or thrown out, each with a way back.
///
/// It sits on "What you used", which is where someone goes after a mistaken
/// tap. Shows nothing at all when nothing has been settled.
class PutItBack extends StatefulWidget {
  const PutItBack({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<PutItBack> createState() => _PutItBackState();
}

class _PutItBackState extends State<PutItBack> {
  List<Map<String, dynamic>> _settled = const [];
  String _for = '';
  String _busy = '';

  Future<void> _load(String household) async {
    try {
      final rows = await SupaFlow.client
          .from('food_items')
          .select('id, name, status, archived_at')
          .eq('household_id', household)
          .not('archived_at', 'is', null)
          .order('archived_at', ascending: false)
          .limit(5);
      if (!mounted || household != _for) return;
      setState(() => _settled = List<Map<String, dynamic>>.from(rows as List));
    } catch (_) {
      // No signal: the figures above still read, this simply does not show.
    }
  }

  Future<void> _back(Map<String, dynamic> row) async {
    final id = row['id'].toString();
    if (_busy.isNotEmpty) return;
    setState(() => _busy = id);
    final said = await unsettleFoodItem(id);
    if (!mounted) return;
    setState(() => _busy = '');
    final name = (row['name'] ?? 'It').toString();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(said.isEmpty ? '$name is back in your kitchen.' : said),
    ));
    if (said.isEmpty) await _load(_for);
  }

  static String _when(Object? at) {
    final t = DateTime.tryParse((at ?? '').toString())?.toLocal();
    if (t == null) return '';
    final gap = DateTime.now().difference(t);
    if (gap.inMinutes < 1) return 'just now';
    if (gap.inMinutes < 60) return '${gap.inMinutes} min ago';
    if (gap.inHours < 24) return '${gap.inHours} h ago';
    if (gap.inDays == 1) return 'yesterday';
    return '${gap.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final household = FFAppState().currentHouseholdId;
    if (household.isNotEmpty && household != _for) {
      _for = household;
      _load(household);
    }
    if (_settled.isEmpty) return const SizedBox.shrink();
    final t = FlutterFlowTheme.of(context);

    return Container(
      width: widget.width ?? double.infinity,
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      decoration: _uCard(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Changed your mind?', style: t.titleMedium),
          const SizedBox(height: 2),
          Text(
            'The last few you marked used or thrown out.',
            style: t.bodySmall.copyWith(color: t.secondaryText),
          ),
          const SizedBox(height: 6),
          for (final row in _settled) _row(t, row),
        ],
      ),
    );
  }

  Widget _row(FlutterFlowTheme t, Map<String, dynamic> row) {
    final name = (row['name'] ?? '').toString();
    final used = (row['status'] ?? '').toString() == 'consumed';
    final when = _when(row['archived_at']);
    final busy = _busy == row['id'].toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(used ? Icons.done_all : Icons.delete_outline,
              size: 18, color: t.secondaryText),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodyLarge),
                Text(
                  [used ? 'Used' : 'Thrown out', if (when.isNotEmpty) when]
                      .join(' - '),
                  style: t.bodySmall.copyWith(color: t.secondaryText),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: busy ? null : () => _back(row),
            style: TextButton.styleFrom(minimumSize: const Size(0, 44)),
            child: Text(
              busy ? 'Putting back...' : 'Put it back',
              style: t.bodySmall
                  .copyWith(color: t.primary, fontWeight: FontWeight.w700),
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

/// A food card for the two-column grids: picture, two-line name, amount and
/// the date badge.
Widget _uFoodCard(BuildContext context, Map item, {required VoidCallback onTap}) {
  final t = FlutterFlowTheme.of(context);
  final name = '${item['name'] ?? ''}';
  final photo = foodPhoto(name, '${item['image_url'] ?? ''}') ?? '';
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

const _wShelfReview = r'''
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
          String? useBy,
          int? quantity}) =>
      MapFoodStruct(
        name: name ?? f.name,
        category: category ?? f.category,
        quantity: quantity ?? f.quantity,
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
      '${f.quantity < 1 ? 1 : f.quantity}×',
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

  Widget _count(FlutterFlowTheme t, IconData icon, String label, bool enabled,
          VoidCallback onTap) =>
      Semantics(
        button: true,
        enabled: enabled,
        label: label,
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: enabled ? onTap : null,
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: t.secondaryBackground,
                border: Border.all(color: t.alternate),
              ),
              child: Icon(icon, color: t.primary, size: 20),
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
          // Owner, 14 Sep: the photo read 5 cans of tuna, there were 4, and
          // there was no way to change it.
          Container(
            padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
            decoration: BoxDecoration(
              color: t.primaryBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: t.alternate),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text('How many',
                      style: t.bodyMedium.copyWith(color: t.secondaryText)),
                ),
                _count(t, Icons.remove, 'One fewer', f.quantity > 1, () {
                  _change(
                      i,
                      (x) =>
                          _copy(x, quantity: x.quantity - 1, decision: 'yes'));
                }),
                SizedBox(
                  width: 44,
                  child: Text(
                    '${f.quantity < 1 ? 1 : f.quantity}',
                    textAlign: TextAlign.center,
                    style: t.titleMedium.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                _count(t, Icons.add, 'One more', f.quantity < 99, () {
                  _change(
                      i,
                      (x) => _copy(x,
                          quantity: (x.quantity < 1 ? 1 : x.quantity) + 1,
                          decision: 'yes'));
                }),
              ],
            ),
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

/// A food card for the two-column grids: picture, two-line name, amount and
/// the date badge.
Widget _uFoodCard(BuildContext context, Map item, {required VoidCallback onTap}) {
  final t = FlutterFlowTheme.of(context);
  final name = '${item['name'] ?? ''}';
  final photo = foodPhoto(name, '${item['image_url'] ?? ''}') ?? '';
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

