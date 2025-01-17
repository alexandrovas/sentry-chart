{{- define "sentry.snuba.config" -}}
{{- $redisPass := include "sentry.redis.password" . -}}
settings.py: |
  import os

  from snuba.settings import *

  env = os.environ.get

  DEBUG = env("DEBUG", "0").lower() in ("1", "true")

  # Clickhouse Options
  CLUSTERS = [
    {
      "host": env("CLICKHOUSE_HOST", {{ include "sentry.clickhouse.host" . | quote }}),
      "port": int({{ include "sentry.clickhouse.port" . }}),
      "user":  env("CLICKHOUSE_USER", "default"),
      "password": env("CLICKHOUSE_PASSWORD", ""),
      "max_connections": int(os.environ.get("CLICKHOUSE_MAX_CONNECTIONS", 100)),
      "database": env("CLICKHOUSE_DATABASE", "default"),
      "http_port": {{ include "sentry.clickhouse.http_port" . }},
      "storage_sets": {
          "cdc",
          "discover",
          "events",
          "events_ro",
          "metrics",
          "metrics_summaries",
          "migrations",
          "outcomes",
          "querylog",
          "sessions",
          "transactions",
          "profiles",
          "functions",
          "replays",
          "generic_metrics_sets",
          "generic_metrics_distributions",
          "search_issues",
          "generic_metrics_counters",
          "spans",
          "group_attributes",
          "generic_metrics_gauges",
      },
      {{- /*
        The default clickhouse installation runs in distributed mode, while the external
        clickhouse configured can be configured any way you choose
      */}}
      {{- if and .Values.externalClickhouse.singleNode (not .Values.clickhouse.enabled) }}
      "single_node": True,
      {{- else }}
      "single_node": False,
      {{- end }}
      {{- if or .Values.clickhouse.enabled (not .Values.externalClickhouse.singleNode) }}
      "cluster_name": {{ include "sentry.clickhouse.cluster.name" . | quote }},
      "distributed_cluster_name": {{ include "sentry.clickhouse.cluster.name" . | quote }},
      {{- end }}
    },
  ]

  # Redis Options
  REDIS_HOST = {{ include "sentry.redis.host" . | quote }}
  REDIS_PORT = {{ include "sentry.redis.port" . }}
  {{- if $redisPass }}
  REDIS_PASSWORD = {{ $redisPass | quote }}
  {{- end }}
  REDIS_DB = int(env("REDIS_DB", 1))

{{- if .Values.metrics.enabled }}
  DOGSTATSD_HOST = "{{ template "sentry.fullname" . }}-metrics"
  DOGSTATSD_PORT = 9125
{{- end }}

  {{ .Values.config.snubaSettingsPy | nindent 2 }}
{{- end -}}
