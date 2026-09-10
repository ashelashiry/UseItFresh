/// The screen that says whether any of this is working.
///
/// Two numbers and a sentence. No chart: with a household's worth of data a
/// chart would be four bars pretending to be a trend, and the guide's rule
/// against inventing applies to shapes as much as to inventory.
///
/// The thrown-out number is not styled as an alarm. It is red-adjacent only
/// where the app already uses that colour for discard, and the copy reports
/// rather than judges — a person who wasted three things this month does not
/// need an app to feel worse about it.
void buildStarterEditFlow(App app) {
  DslWidget figure(String name, Object value, Object label, ColorToken tone) =>
      Container(
        name: '${name}Tile',
        color: Colors.secondaryBackground,
        borderColor: Colors.alternate,
        borderWidth: 1,
        borderRadius: 16,
        padding:
            const EdgeInsets.only(left: 18, right: 18, top: 18, bottom: 18),
        child: Column(
          crossAxis: CrossAxis.start,
          spacing: 2,
          children: [
            Text(value,
                name: '${name}Value',
                style: Styles.headlineMedium,
                color: tone),
            Text(label,
                name: '${name}Label',
                style: Styles.bodySmall,
                color: Colors.secondaryText),
          ],
        ),
      );

  app.ensurePage(
    'WasteHistoryPage',
    description:
        'What this household used up and what it threw out over the last '
        'thirty days, and which category goes in the bin most.',
    route: 'history',
    state: const {},
    onLoad: [
      CallCustomAction.named(
        'LoadWasteSummary',
        args: {},
        returnType: string,
        arguments: {},
        outputAs: 'wasteOutcome',
      ),
      If(
        Equals(ActionOutput('wasteOutcome'), ''),
        then: [UpdateAppState.set(ff.AppState.wasteLoaded, true)],
        orElse: [Snackbar(ActionOutput('wasteOutcome'))],
      ),
    ],
    body: Scaffold(
      body: Container(
        name: 'WasteBody',
        padding:
            const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 20),
        child: Column(
          scrollable: true,
          crossAxis: CrossAxis.stretch,
          spacing: 14,
          children: [
            Row(
              name: 'WasteBackRow',
              mainAxis: MainAxis.start,
              children: [
                Container(
                  name: 'WasteBack',
                  onTap: [NavigateBack()],
                  width: 48,
                  height: 48,
                  color: Colors.secondaryBackground,
                  borderColor: Colors.alternate,
                  borderWidth: 1,
                  borderRadius: 999,
                  child:
                      Icon('arrow_back', size: 20, color: Colors.primaryText),
                ),
              ],
            ),

            Text('What you used.',
                name: 'WasteHeadline',
                style: Styles.headlineMedium,
                color: Colors.primary),
            Text(AppState(ff.AppState.wasteHeadline),
                name: 'WasteSummary',
                style: Styles.titleMedium,
                color: Colors.primaryText),
            Text(AppState(ff.AppState.wasteDetail),
                name: 'WasteDetail',
                style: Styles.bodyMedium,
                color: Colors.secondaryText),

            // The two figures, side by side, only once there is something to
            // count. A pair of zeroes reads as a score you lost.
            Row(
              name: 'WasteFigures',
              visible: AppState(ff.AppState.wasteHasData),
              crossAxis: CrossAxis.stretch,
              spacing: 12,
              children: [
                Expanded(figure('WasteUsed',
                    AppState(ff.AppState.wasteUsedCount), 'used up',
                    Colors.primary)),
                Expanded(figure('WasteBinned',
                    AppState(ff.AppState.wasteBinnedCount), 'thrown out',
                    Colors.error)),
              ],
            ),

            Container(
              name: 'WasteWorstCard',
              visible: Not(Equals(AppState(ff.AppState.wasteWorst), '')),
              color: Colors.accent1,
              borderRadius: 14,
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 14, bottom: 14),
              child: Column(
                crossAxis: CrossAxis.start,
                spacing: 3,
                children: [
                  Text('MOST OFTEN THROWN OUT',
                      name: 'WasteWorstLabel',
                      style: Styles.labelSmall,
                      color: Colors.secondaryText),
                  Text(AppState(ff.AppState.wasteWorst),
                      name: 'WasteWorstValue',
                      style: Styles.titleMedium,
                      color: Colors.primaryText),
                  Text('Worth buying less of, or freezing sooner.',
                      name: 'WasteWorstHint',
                      style: Styles.bodySmall,
                      color: Colors.secondaryText),
                ],
              ),
            ),

            Container(
              name: 'WasteTrendCard',
              visible: Not(Equals(AppState(ff.AppState.wasteTrend), '')),
              color: Colors.secondaryBackground,
              borderColor: Colors.alternate,
              borderWidth: 1,
              borderRadius: 14,
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 14, bottom: 14),
              child: Text(AppState(ff.AppState.wasteTrend),
                  name: 'WasteTrendText',
                  style: Styles.bodyMedium,
                  color: Colors.primaryText),
            ),

            // Said plainly rather than implied by an empty chart.
            Container(
              name: 'WasteEmptyNote',
              visible: Not(AppState(ff.AppState.wasteHasData)),
              color: Colors.accent1,
              borderRadius: 14,
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 16, bottom: 16),
              child: Text('This counts only things you have finished with — '
                  'marked used up, or thrown out — from the item screen.',
                  name: 'WasteEmptyText',
                  style: Styles.bodySmall,
                  color: Colors.secondaryText),
            ),
          ],
        ),
      ),
    ),
  );
}
