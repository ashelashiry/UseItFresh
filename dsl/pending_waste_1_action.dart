/// What you used, and what you did not.
///
/// Every "I used it" and "Throw it out" has been writing to food_item_events
/// since the first migration and nothing has ever read it back. This is the
/// payoff for all that logging: the one screen that can say whether the app is
/// actually working.
///
/// Rules this screen holds to, from the guides:
///
///   * Never invent. With nothing settled it says nothing settled, rather than
///     drawing an empty chart or a zero that looks like a score.
///   * Never scold. The number is reported, not judged. Nobody needs an app
///     telling them off about a cucumber.
///   * Say what the window is. "Most thrown out: vegetables" is meaningless
///     without "of the 14 things you finished with in the last 30 days".
///
/// The reasoning lives in Dart rather than the UI, because the awkward parts —
/// too little data to have an opinion, a tie between categories, the first
/// month having no previous month to compare against — are all judgement, and
/// judgement in widget bindings is where this project has lost the most time.
void buildStarterEditFlow(App app) {
  app.state('wasteHeadline', string.withDefault(''));
  app.state('wasteDetail', string.withDefault(''));
  app.state('wasteWorst', string.withDefault(''));
  app.state('wasteTrend', string.withDefault(''));
  app.state('wasteUsedCount', int_.withDefault(0));
  app.state('wasteBinnedCount', int_.withDefault(0));
  app.state('wasteHasData', bool_.withDefault(false));
  app.state('wasteLoaded', bool_.withDefault(false));

  app.customAction(
    'LoadWasteSummary',
    args: {},
    returns: string,
    description:
        'Reads the settled-item history for this household and works out what '
        'was used, what was thrown, and what is thrown most. Returns an empty '
        'string on success, or a message explaining why not.',
    code: r'''
import 'package:supabase_flutter/supabase_flutter.dart';

/// Works out the household's use-versus-waste picture over the last 30 days.
///
/// Reads events rather than the items table because an item's current status
/// says what it is now; the event says what happened and when. Only the two
/// settling events count — 'created' and 'moved' are not outcomes.
Future<String> loadWasteSummary() async {
  final household = FFAppState().currentHouseholdId;
  if (household.isEmpty) {
    return 'No household yet. Create or join one first.';
  }

  // Reset first, so a failed reload cannot leave the previous household's
  // numbers on screen looking like this one's.
  FFAppState().wasteHeadline = '';
  FFAppState().wasteDetail = '';
  FFAppState().wasteWorst = '';
  FFAppState().wasteTrend = '';
  FFAppState().wasteUsedCount = 0;
  FFAppState().wasteBinnedCount = 0;
  FFAppState().wasteHasData = false;

  final now = DateTime.now().toUtc();
  final windowStart = now.subtract(const Duration(days: 30));
  final priorStart = now.subtract(const Duration(days: 60));

  List<dynamic> rows;
  try {
    // The embedded food_items select is what scopes this to the household and
    // brings the category along; row security already limits it to households
    // this person belongs to, and the filter picks the one they are looking at.
    rows = await SupaFlow.client
        .from('food_item_events')
        .select('event_type, created_at, food_items!inner(category, household_id)')
        .eq('food_items.household_id', household)
        .inFilter('event_type', ['consumed', 'discarded'])
        .gte('created_at', priorStart.toIso8601String());
  } on PostgrestException catch (error) {
    return error.message;
  } catch (error) {
    return 'Could not read your history. $error';
  }

  var used = 0;
  var binned = 0;
  var priorUsed = 0;
  var priorBinned = 0;
  final binnedByCategory = <String, int>{};

  for (final row in rows) {
    final at = DateTime.tryParse((row['created_at'] ?? '').toString());
    if (at == null) continue;
    final recent = at.isAfter(windowStart);
    final consumed = row['event_type'] == 'consumed';

    if (recent) {
      if (consumed) {
        used++;
      } else {
        binned++;
        final item = row['food_items'];
        final category =
            (item is Map ? (item['category'] ?? '') : '').toString().trim();
        if (category.isNotEmpty) {
          binnedByCategory[category] = (binnedByCategory[category] ?? 0) + 1;
        }
      }
    } else {
      if (consumed) {
        priorUsed++;
      } else {
        priorBinned++;
      }
    }
  }

  final settled = used + binned;
  FFAppState().wasteUsedCount = used;
  FFAppState().wasteBinnedCount = binned;
  FFAppState().wasteHasData = settled > 0;

  if (settled == 0) {
    FFAppState().wasteHeadline = 'Nothing finished with yet.';
    FFAppState().wasteDetail =
        'When you mark something used up or thrown out, the pattern shows up '
        'here.';
    return '';
  }

  final pct = ((used / settled) * 100).round();
  FFAppState().wasteHeadline = '$used of $settled used up.';
  FFAppState().wasteDetail = settled == 1
      ? 'One thing finished with in the last 30 days.'
      : '$settled things finished with in the last 30 days. $pct% used, '
          '${100 - pct}% thrown out.';

  // The worst category, but only when there is enough to mean anything. Two
  // thrown-out items is not a pattern, and naming one would be inventing a
  // conclusion the data cannot carry.
  if (binned >= 3 && binnedByCategory.isNotEmpty) {
    final ranked = binnedByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = ranked.first;
    // A tie is not a worst.
    final tied = ranked.length > 1 && ranked[1].value == top.value;
    if (!tied && top.value >= 2) {
      FFAppState().wasteWorst = _label(top.key);
    }
  }

  // A comparison needs a previous month with something in it, or the first
  // month reads as a dramatic improvement over nothing.
  final priorSettled = priorUsed + priorBinned;
  if (priorSettled >= 3) {
    final priorPct = (priorUsed / priorSettled) * 100;
    final diff = pct - priorPct;
    if (diff >= 5) {
      FFAppState().wasteTrend = 'Better than the month before.';
    } else if (diff <= -5) {
      FFAppState().wasteTrend = 'Down on the month before.';
    } else {
      FFAppState().wasteTrend = 'About the same as the month before.';
    }
  }

  return '';
}

/// The words the picker offered, so this screen never shows a stored code.
String _label(String code) {
  const names = <String, String>{
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
  return names[code] ?? code.replaceAll('_', ' ');
}
''',
  );
}
