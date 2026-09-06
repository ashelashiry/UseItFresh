library;

import 'dart:io';

import 'package:flutterflow_ai/flutterflow_ai.dart';

import 'create.dart' as phase1;


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

/// Teardown of the FridgeWise prototype ahead of the Use It Fresh rebuild.
/// Removes every prototype page, component, custom function, and local
/// collection so the Phase 1 foundation (dsl/create.dart) can land cleanly
/// in the same project without name/route collisions.
void buildStarterEditFlow(App app) {
  // Pages (9) — removed first since they reference components + functions.
  for (final page in [
    'AddFoodItem',
    'AIRecipeGenerator',
    'FoodDetailSafety',
    'InventoryDashboard',
    'Onboarding',
    'RecipeInstructions',
    'Settings',
    'ShoppingList',
    'WasteAnalytics',
  ]) {
    app.removePage(page);
  }

  // Components (17).
  for (final component in [
    'Button',
    'CategoryChip',
    'ChartLegend',
    'ImpactItem',
    'IngredientCheck',
    'IngredientChip',
    'InputLabel',
    'InventoryItem',
    'PieChart',
    'RecipeCard',
    'RecipeSource',
    'SafetyTip',
    'ShoppingItem',
    'StatCard',
    'StepCard',
    'StorageStat',
    'TextField',
  ]) {
    app.removeComponent(component);
  }

  // Custom functions (13).
  for (final fn in [
    'currentIngredients',
    'currentItem',
    'currentRecipe',
    'currentSteps',
    'expiringSoonItems',
    'expiryLabel',
    'freshItems',
    'freshnessLabel',
    'freshnessValue',
    'ingredientStats',
    'quantityLabel',
    'shoppingListItems',
    'totalImpactKg',
  ]) {
    app.removeCustomFunction(fn);
  }

  // Local collections (5) — superseded by the Supabase schema.
  for (final collection in [
    'food_items',
    'recipe_ingredients',
    'recipe_steps',
    'recipes',
    'shopping_items',
  ]) {
    app.removeCollection(collection);
  }

  // ------------------------------------------------------------------
  // Rebuild: land the Use It Fresh Phase 1 foundation in the same push
  // so the project never has an empty (page-less) state.
  // ------------------------------------------------------------------
  phase1.buildUseItFreshCreateFlow(app);
}
