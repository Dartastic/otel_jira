// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_jira/otel_jira.dart';

/// Traces Jira calls with OpenTelemetry.
///
/// `otel_jira` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Jira call in
/// [tracedJira]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'jira-example');

  // Wraps any Jira Cloud REST call in a CLIENT span.
  final jiraId = await tracedJira<String>(
    resource: 'Order',
    action: 'example',
    site: 'example',
    issueKey: 'orders/2026/inv-1042.pdf',
    projectKey: 'orders/2026/inv-1042.pdf',
    invoke: () async {
      // Make the Jira call here, then report what it returned.
      return 'jira_8f3a2c';
    },
  );
  OTelLog.info('tracedJira returned $jiraId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutJiraInstrumentationAsync.
  await runWithoutJiraInstrumentationAsync(
    () => tracedJira<String>(
      resource: 'Order',
      action: 'example',
      site: 'example',
      issueKey: 'orders/2026/inv-1042.pdf',
      projectKey: 'orders/2026/inv-1042.pdf',
      invoke: () async {
        return 'jira_8f3a2c';
      },
    ),
  );

  await OTel.shutdown();
}
