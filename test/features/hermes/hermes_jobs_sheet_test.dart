import 'package:conduit/features/hermes/widgets/hermes_jobs_sheet.dart';
import 'package:conduit/l10n/app_localizations_en.dart';
import 'package:conduit/shared/services/navigation_service.dart';
import 'package:conduit_core/features/hermes/models/hermes_capabilities.dart';
import 'package:conduit_core/features/hermes/models/hermes_job.dart';
import 'package:conduit_core/features/hermes/providers/hermes_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  final l10n = AppLocalizationsEn();

  testWidgets('showHermesJobsSheet displays scheduled jobs and handles manage action', (
    tester,
  ) async {
    final controller = _TestJobsController([
      const HermesJob(
        id: 'job-1',
        name: 'Daily summary',
        prompt: 'Summarize updates',
        schedule: '0 9 * * *',
      ),
    ]);

    var navigatedToManage = false;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => showHermesJobsSheet(ctx),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
        GoRoute(
          name: RouteNames.hermesJobs,
          path: '/hermes-jobs',
          builder: (context, state) {
            navigatedToManage = true;
            return const Scaffold(body: Text('Hermes Jobs Manager'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesJobsProvider.overrideWith(() => controller),
          hermesCapabilitiesProvider.overrideWith(
            (ref) async => const HermesCapabilities(),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text(l10n.hermesScheduledAgentsTitle), findsOneWidget);
    expect(find.text('Daily summary'), findsOneWidget);
    expect(find.text(l10n.manage), findsOneWidget);

    await tester.tap(find.text(l10n.manage));
    await tester.pumpAndSettle();

    expect(navigatedToManage, isTrue);
    expect(find.text('Hermes Jobs Manager'), findsOneWidget);
  });

  testWidgets('showHermesJobsSheet renders empty state properly without layout errors', (
    tester,
  ) async {
    final controller = _TestJobsController(const []);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesJobsProvider.overrideWith(() => controller),
          hermesCapabilitiesProvider.overrideWith(
            (ref) async => const HermesCapabilities(),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showHermesJobsSheet(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text(l10n.hermesScheduledAgentsTitle), findsOneWidget);
    expect(find.text(l10n.hermesNoSchedulesYet), findsOneWidget);
  });

  testWidgets('showHermesJobsSheet renders error state without layout errors', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesJobsProvider.overrideWith(() => _ErrorJobsController()),
          hermesCapabilitiesProvider.overrideWith(
            (ref) async => const HermesCapabilities(),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showHermesJobsSheet(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text(l10n.hermesScheduledAgentsTitle), findsOneWidget);
    expect(find.text(l10n.hermesJobLoadFailed), findsOneWidget);
  });

  testWidgets('HermesJobsSheet mounts inside an unbounded parent without throwing', (
    tester,
  ) async {
    final controller = _TestJobsController([
      const HermesJob(
        id: 'job-1',
        name: 'Daily summary',
        prompt: 'Summarize updates',
        schedule: '0 9 * * *',
      ),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesJobsProvider.overrideWith(() => controller),
          hermesCapabilitiesProvider.overrideWith(
            (ref) async => const HermesCapabilities(),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HermesJobsSheet(),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.hermesScheduledAgentsTitle), findsOneWidget);
    expect(find.text('Daily summary'), findsOneWidget);
  });

  testWidgets('HermesJobsSheet mounts inside a bounded parent', (
    tester,
  ) async {
    final controller = _TestJobsController([
      const HermesJob(
        id: 'job-1',
        name: 'Daily summary',
        prompt: 'Summarize updates',
        schedule: '0 9 * * *',
      ),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesJobsProvider.overrideWith(() => controller),
          hermesCapabilitiesProvider.overrideWith(
            (ref) async => const HermesCapabilities(),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 500,
              child: HermesJobsSheet(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.hermesScheduledAgentsTitle), findsOneWidget);
    expect(find.text('Daily summary'), findsOneWidget);
  });
}

class _TestJobsController extends HermesJobsController {
  _TestJobsController(this._jobs);
  final List<HermesJob> _jobs;

  @override
  Future<List<HermesJob>> build() async => _jobs;
}

class _ErrorJobsController extends HermesJobsController {
  @override
  Future<List<HermesJob>> build() async {
    throw StateError('failed to fetch jobs');
  }
}
