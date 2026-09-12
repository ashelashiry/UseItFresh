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

/// Design guide v4, section 6: Profile.
///
/// Eight separate cards, each with a sentence beneath its title, become two
/// grouped cards of compact rows with the guide's labels:
///
///   You      My details · Diet & allergies · Security
///   Kitchen  Household · Storage · Shopping list · Reminders · What you used
///
/// Every row opens the same screen it did. The identity row above, the safety
/// note, the version and Sign out below are unchanged.
void buildStarterEditFlow(App app) {
  app.customWidget(
    'ProfileMenu',
    parameters: {},
    description:
        'Profile settings as two grouped cards of compact rows: My details, '
        'Diet & allergies, Security; Household, Storage, Shopping list, '
        'Reminders, What you used.',
    code: _profileMenu,
  );

  final profile = ff.Pages.profilePage;
  app.editPage(profile, (page) {
    for (final key in [
      'Container_k6ji4lje', // Reminders (children[9])
      'Container_pxukv1g3', // What you used (children[8])
      'Container_kc7jzzk5', // Shopping list (children[7])
      'Container_nm6yylvz', // Security (children[6])
      'Container_2sbghpgj', // Storage locations (children[5])
      'Container_895szec5', // Household (children[4])
      'Container_74x3budk', // What you leave out (children[3])
      'Container_p89i895i', // Profile and units (children[2])
    ]) {
      page.ensureRemoved(profile.widgets.byKey(key).single);
    }
    page.ensureInsertedAfter(
      profile.widgets.byKey('Row_b5rptfl4').single, // avatar, name, household
      CustomWidget(widgetName: 'ProfileMenu', name: 'ProfileRows', arguments: {}),
    );
  });
}

const _profileMenu = r'''
import 'package:flutter/material.dart';

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
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _group(context, t, 'You', const [
            _Row('My details', Icons.badge_outlined, 'OnboardingPage'),
            _Row('Diet & allergies', Icons.no_food_outlined,
                'FoodPreferencesPage'),
            _Row('Security', Icons.lock_outline, 'UpdatePasswordPage'),
          ]),
          const SizedBox(height: 20),
          _group(context, t, 'Kitchen', const [
            _Row('Household', Icons.group_outlined, 'HouseholdSetupPage'),
            _Row('Storage', Icons.kitchen_outlined, 'StorageLocationsPage'),
            _Row('Shopping list', Icons.shopping_cart_outlined,
                'ShoppingListPage'),
            _Row('Reminders', Icons.notifications_none, 'RemindersPage'),
            _Row('What you used', Icons.insights_outlined, 'WasteHistoryPage'),
          ]),
        ],
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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
          ),
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
        onTap: () => context.pushNamed(row.route),
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
''';
