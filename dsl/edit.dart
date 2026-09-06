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
// Reusable components, from the design handoff.
//
// The handoff's own priority is "reusable theme/components and navigation".
// The theme landed in n7Q5WS0QYlYcKGlDUAaH; these are the pieces every
// everyday screen is assembled from, so Home and Inventory become composition
// rather than a fresh build each time.
//
// Colours come from theme slots, not hexes. Hard-coding is what produced two
// different brand greens in the first place.
// ---------------------------------------------------------------------------

void buildStarterEditFlow(App app) {
  // ================================================================
  // StatusBadge — the §10 status, as a pill.
  //
  // `label` and `detail` are passed in from the food_items_status view, which
  // computes them in SQL. That keeps the nine-way mapping in one place instead
  // of repeating nine conditionals in every list that shows an item.
  //
  // KNOWN GAP: no icon. Icon() takes a literal string and cannot be bound to a
  // param, so the view's status_icon column has nothing to drive. §10 wants
  // text AND an icon; the text is here and colour is never the only signal, so
  // the colour-alone rule holds — but the icon is still owed. It needs nine
  // visibility-switched Icons or a small custom widget mapping name -> IconData.
  // ================================================================
  app.component(
    'StatusBadge',
    description:
        'One of the nine §10 food statuses as a pill. Label comes from the '
        'food_items_status view so the wording stays consistent everywhere.',
    params: {
      'label': string.withDefault('Fresh'),
      // No `tone` param: ColorToken is not an expression, so a colour cannot be
      // driven from a component param any more than an icon name can. Per-status
      // colouring needs either nine variants or a custom widget. Recorded, not
      // faked -- the label alone still satisfies the never-colour-alone rule.
    },
    body: Container(
      name: 'StatusBadgeShell',
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      borderRadius: 999,
      color: Colors.accent3,
      child: Text(
        Param('label'),
        name: 'StatusBadgeLabel',
        style: Styles.labelMedium,
        maxLines: 1,
      ),
    ),
  );

  // ================================================================
  // FoodCard — the row used by Home's "Use first" and by Inventory.
  //
  // Four lines, in the order the handoff draws them:
  //   name · "1 bag · Fridge" · status badge · the date line
  //
  // That last line matters more than it looks. Spec §5.2 requires a printed
  // manufacturer date and an app estimate to be visually distinguishable, and
  // the handoff does it with wording: "Best-before · 8 Sep" versus
  // "Window ends 9 Sep · estimate". `dateLine` carries whichever applies,
  // already worded by the view's status_basis.
  // ================================================================
  app.component(
    'FoodCard',
    description:
        'One food item in a list. Shows what it is, where it lives, its §10 '
        'status and the date it is judged on — printed dates and app estimates '
        'worded differently, per §5.2.',
    params: {
      'itemName': string.withDefault('Baby spinach'),
      'meta': string.withDefault('Fridge'),
      'statusLabel': string.withDefault('Use soon'),
      'dateLine': string.withDefault('Best-before · 8 Sep'),
    },
    body: Container(
      name: 'FoodCardShell',
      padding: 14,
      borderRadius: 14,
      color: Colors.secondaryBackground,
      child: Row(
        crossAxis: CrossAxis.center,
        spacing: 12,
        children: [
          // Category tile. A flat token rather than a photo: most items are
          // added by hand with no image, and an empty photo frame on every row
          // looks broken.
          Container(
            name: 'FoodCardTile',
            width: 46,
            height: 46,
            borderRadius: 12,
            color: Colors.accent1,
            child: Icon('eco', size: 22, name: 'FoodCardTileIcon'),
          ),
          Flexible(
            Column(
              crossAxis: CrossAxis.start,
              spacing: 3,
              children: [
                Text(
                  Param('itemName'),
                  name: 'FoodCardName',
                  style: Styles.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  Param('meta'),
                  name: 'FoodCardMeta',
                  style: Styles.bodySmall,
                  color: Colors.secondaryText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Inlined rather than ff.Components.statusBadge(...): the
                // typed SDK is generated from the LAST push, so a component
                // created in this same script cannot be referenced yet. Swap
                // it for the component reference on the next pass.
                Container(
                  name: 'FoodCardStatus',
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  borderRadius: 999,
                  color: Colors.accent3,
                  child: Text(
                    Param('statusLabel'),
                    name: 'FoodCardStatusLabel',
                    style: Styles.labelMedium,
                    maxLines: 1,
                  ),
                ),
                Text(
                  Param('dateLine'),
                  name: 'FoodCardDateLine',
                  style: Styles.bodySmall,
                  color: Colors.secondaryText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            flex: 1,
          ),
          Icon('chevron_right', size: 22, name: 'FoodCardChevron'),
        ],
      ),
    ),
  );

  // ================================================================
  // SectionHeading — "Use first" / "See all", the pattern on Home.
  // ================================================================
  app.component(
    'SectionHeading',
    description: 'A section title with an optional trailing action, as used '
        'above the Use first list on Home.',
    params: {
      'title': string.withDefault('Use first'),
      'action': string.withDefault('See all'),
    },
    body: Row(
      name: 'SectionHeadingRow',
      mainAxis: MainAxis.spaceBetween,
      crossAxis: CrossAxis.center,
      children: [
        Text(
          Param('title'),
          name: 'SectionHeadingTitle',
          style: Styles.titleLarge,
          maxLines: 1,
        ),
        Text(
          Param('action'),
          name: 'SectionHeadingAction',
          style: Styles.labelMedium,
          color: Colors.primary,
          maxLines: 1,
        ),
      ],
    ),
  );

  // ================================================================
  // FeaturePanel — the graphite card at the top of Home.
  //
  // The one place the dark fridge palette carries into the everyday screens,
  // which is what keeps the entrance and the app feeling like one product.
  // ================================================================
  app.component(
    'FeaturePanel',
    description:
        'The graphite hero card on Home. Carries the next useful action, not '
        'decoration.',
    params: {
      'eyebrow': string.withDefault('SMALL HABITS, FRESH STARTS'),
      'headline': string.withDefault('Make room for something delicious.'),
      'supporting': string.withDefault('3 items to check first today.'),
      'cta': string.withDefault('See what to use first'),
    },
    body: Container(
      name: 'FeaturePanelShell',
      padding: 22,
      borderRadius: 20,
      color: Colors.tertiary,
      child: Column(
        crossAxis: CrossAxis.start,
        spacing: 10,
        children: [
          Text(
            Param('eyebrow'),
            name: 'FeaturePanelEyebrow',
            style: Styles.labelSmall,
            color: Colors.secondary,
            maxLines: 1,
          ),
          Text(
            Param('headline'),
            name: 'FeaturePanelHeadline',
            style: Styles.headlineSmall,
            color: Colors.accent2,
            maxLines: 3,
          ),
          Text(
            Param('supporting'),
            name: 'FeaturePanelSupporting',
            style: Styles.bodyMedium,
            color: Colors.accent1,
            maxLines: 2,
          ),
          Button(
            Param('cta'),
            name: 'FeaturePanelCta',
            height: 48,
            borderRadius: 12,
            color: Colors.accent3,
            textColor: Colors.primary,
          ),
        ],
      ),
    ),
  );
}
