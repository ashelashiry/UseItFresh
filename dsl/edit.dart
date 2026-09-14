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

/// Paid feature: Household meal planning (owner, 14 Sep: "shared meals with
/// different serving sizes and individual preferences").
///
/// Plan my week gets "Who eats at home": everyone in the household (names and
/// allergies from their profiles) and people without the app, like children,
/// each with a small, regular or large portion. A planned meal says who is
/// eating; its servings add up from their portions. A meal that mentions
/// something one of them avoids is flagged. Meal ideas leave out everyone's
/// allergies (ideasHouseholdAvoid). Needs migration 8.
void buildStarterEditFlow(App app) {
  app.state('ideasHouseholdAvoid', string, persisted: true);
  app.raw((project) {
    updateCustomWidget(project, name: 'WeekPlan', code: _weekPlan);
    updateCustomAction(project, name: 'GetMealIdeas', code: _getMealIdeas);
  });
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
                backgroundColor: _forest,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
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
                'extras': <String>[],
                'leftoverOf': entry.id,
                'steps': [
                  'Reheat the extra portions from ${_dayName(entry.date)}.'
                ],
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
          fillColor: Colors.white,
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
                        backgroundColor: _forest,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
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
    amount.dispose();
    for (final c in typed.values) {
      c.dispose();
    }
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
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

  static String _portionName(double p) => p <= 0.5
      ? 'small'
      : (p >= 1.5 ? 'large' : 'regular');

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
          _plates.putIfAbsent('${m['plan_entry_id']}', () => {})['${m['diner_id']}'] =
              _portionOf(m['portions']);
        }
        _dinersReady = true;
      });
      // Ideas found for the household leave out everyone's allergies.
      final avoid = <String>{
        for (final d in list) ..._words(d['allergens']).map((a) => a.toLowerCase())
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
    final ids = [for (final m in members as List) '${(m as Map)['profile_id']}'];
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
        await SupaFlow.client.from('household_diners').insert({
          'household_id': household,
          'profile_id': id,
          'name': name.isEmpty ? 'Someone' : name,
          'allergens': allergens,
          'dietary_preferences': _words(m['dietary_preferences']),
          'created_by': SupaFlow.client.auth.currentUser?.id,
        });
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
      if (plate.isNotEmpty) {
        final total = plate.values.fold<double>(0, (a, b) => a + b);
        await SupaFlow.client.from('meal_plan_entries').update(
            {'servings': total.ceil().clamp(1, 12)}).eq('id', e.id);
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
                      initialValue: _words(d['allergens']).join(', '),
                      decoration: const InputDecoration(
                          labelText: 'Allergies or foods to avoid',
                          hintText: 'e.g. peanuts, eggs'),
                      onFieldSubmitted: (v) => change(() => SupaFlow.client
                          .from('household_diners')
                          .update({
                        'allergens': [
                          for (final a in v.split(RegExp(r'[,;\n]')))
                            if (a.trim().length > 1) a.trim()
                        ]
                      }).eq('id', '${d['id']}')),
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
    name.dispose();
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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
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
                    Text(names.isEmpty ? 'Add the people you cook for' : names.join(', '),
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
            _dayCard(t, _today.add(Duration(days: i))),
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
                    _choice(
                        t,
                        '${d['name']}',
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
            action(
                Icons.undo,
                'Mark as still to cook',
                () => act(() =>
                    _update(e, {'status': 'planned', 'cooked_at': null}))),
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
                _choice(t, _dayName(_today.add(Duration(days: i))),
                    _sameDay(e.date, _today.add(Duration(days: i))), () {
                  Navigator.of(sheet).pop();
                  _update(
                      e, {'plan_date': _iso(_today.add(Duration(days: i)))});
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

const _getMealIdeas = r'''
import 'package:supabase_flutter/supabase_flutter.dart';

/// Asks for meal ideas built from the food in this kitchen, soonest-to-go
/// first and shaped by the Recipes filters, and keeps them in app state.
///
/// What to leave out is two things joined: what was typed into "Leave out",
/// and what the person's allergies and diet add. "Use my food" asks for ideas
/// that need nothing beyond the kitchen and the basics. "Fits my goals" sends
/// the calorie range and high protein, and every idea comes back with its
/// estimated calories and protein per serving.
///
/// Returns '' when there are ideas to show, and otherwise a sentence saying
/// why not. It only runs on a tap: each ask is a Gemini call.
Future<String> getMealIdeas() async {
  const sorry = 'Could not come up with ideas just now. Try again in a minute.';
  final household = FFAppState().currentHouseholdId;
  if (household.isEmpty) {
    return 'No household yet. Create or join one first.';
  }
  // A second tap while the first ask is still thinking.
  if (FFAppState().ideasLoading) return '';

  // Household allergies too (Plan my week → Who eats at home).
  final leaveOut = [
    FFAppState().ideasLeaveOut,
    FFAppState().ideasAvoid,
    FFAppState().ideasHouseholdAvoid
  ]
      .map((w) => w.trim())
      .where((w) => w.isNotEmpty)
      .join(', ');

  FFAppState().update(() => FFAppState().ideasLoading = true);
  try {
    final res = await SupaFlow.client.functions.invoke(
      'recognise-food',
      body: {
        'mode': 'ideas',
        'householdId': household,
        'meal': FFAppState().ideasMeal,
        'minutes': FFAppState().ideasMinutes,
        'servings': FFAppState().ideasServings,
        'leaveOut': leaveOut,
        'kitchenOnly': FFAppState().ideasKitchenOnly,
        'calories': FFAppState().ideasGoals ? FFAppState().ideasCalories : '',
        'highProtein': FFAppState().ideasGoals && FFAppState().ideasHighProtein,
      },
    );
    final data = res.data;
    if (data is! Map) return sorry;
    if (data['error'] != null) return data['error'].toString();
    final raw = data['ideas'] is List ? data['ideas'] as List : const [];

    List<String> words(Object? v) => v is List
        ? [
            for (final w in v)
              if ('$w'.trim().isNotEmpty) '$w'.trim(),
          ]
        : <String>[];

    final ideas = <MealIdeaStruct>[];
    for (final r in raw) {
      if (r is! Map) continue;
      final title = (r['title'] ?? '').toString().trim();
      final uses = words(r['uses']);
      if (title.isEmpty || uses.isEmpty) continue;
      ideas.add(MealIdeaStruct(
        title: title,
        uses: uses,
        extras: words(r['extras']),
        steps: words(r['steps']),
        minutes: r['minutes'] is num ? (r['minutes'] as num).round() : 0,
        servings: r['servings'] is num ? (r['servings'] as num).round() : 0,
        soon: r['soon'] == true,
        calories: r['calories'] is num ? (r['calories'] as num).round() : 0,
        protein: r['protein'] is num ? (r['protein'] as num).round() : 0,
      ));
    }
    if (ideas.isEmpty) {
      final note = (data['note'] ?? '').toString();
      return note.isNotEmpty ? note : sorry;
    }
    FFAppState().update(() => FFAppState().mealIdeas = ideas);
    return '';
  } on FunctionException catch (error) {
    final details = error.details;
    if (details is Map && details['error'] != null) {
      return details['error'].toString();
    }
    return sorry;
  } catch (_) {
    return 'Could not reach your kitchen. Check your signal and try again.';
  } finally {
    FFAppState().update(() => FFAppState().ideasLoading = false);
  }
}
''';
