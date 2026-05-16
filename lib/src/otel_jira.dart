// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_jira_suppression.dart';

const _tracerName = 'dartastic_otel_libs_jira';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

/// Wraps any Jira Cloud REST call in a CLIENT span.
Future<T> tracedJira<T>({
  required String resource,
  required String action,
  required String site,
  required Future<T> Function() invoke,
  String? issueKey,
  String? projectKey,
}) async {
  if (jiraInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'jira.resource': resource,
    'jira.action': action,
    'jira.operation': '$resource.$action',
    'jira.site': site,
  };
  if (issueKey != null) m['jira.issue.key'] = issueKey;
  if (projectKey != null) m['jira.project.key'] = projectKey;

  final span = _tracer().startSpan(
    'jira $resource.$action',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
