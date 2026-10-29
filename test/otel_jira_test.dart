// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_jira/otel_jira.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_jira-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('issue.create records CLIENT span', () async {
    await tracedJira<String>(
      resource: 'issue',
      action: 'create',
      site: 'acme.atlassian.net',
      projectKey: 'OPS',
      invoke: () async => 'OPS-1',
    );
    final a = attrsOf(spans.findSpanByName('jira issue.create')!);
    expect(a['jira.resource'], 'issue');
    expect(a['jira.action'], 'create');
    expect(a['jira.operation'], 'issue.create');
    expect(a['jira.site'], 'acme.atlassian.net');
    expect(a['jira.project.key'], 'OPS');
  });

  test('suppression skips spans', () async {
    await runWithoutJiraInstrumentationAsync(() async {
      await tracedJira<String>(
        resource: 'issue',
        action: 'create',
        site: 's',
        invoke: () async => 'k',
      );
    });
    expect(spans.findSpansStartingWith('jira '), isEmpty);
  });
}
