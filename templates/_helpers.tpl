{{/*
Expand the name of the chart.
*/}}
{{- define "uptime-kuma.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "uptime-kuma.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart label.
*/}}
{{- define "uptime-kuma.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "uptime-kuma.labels" -}}
helm.sh/chart: {{ include "uptime-kuma.chart" . }}
{{ include "uptime-kuma.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "uptime-kuma.selectorLabels" -}}
app.kubernetes.io/name: {{ include "uptime-kuma.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
MySQL name.
*/}}
{{- define "uptime-kuma.mysql.fullname" -}}
{{- printf "%s-mysql" (include "uptime-kuma.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
MySQL selector labels.
*/}}
{{- define "uptime-kuma.mysql.selectorLabels" -}}
app.kubernetes.io/name: {{ include "uptime-kuma.name" . }}-mysql
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: mysql
{{- end }}

{{/*
MySQL labels.
*/}}
{{- define "uptime-kuma.mysql.labels" -}}
helm.sh/chart: {{ include "uptime-kuma.chart" . }}
{{ include "uptime-kuma.mysql.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Service account name.
*/}}
{{- define "uptime-kuma.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "uptime-kuma.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Resolve the database host.
When mysql.enabled=true, use the internal service; otherwise use externalDatabase.host.
*/}}
{{- define "uptime-kuma.databaseHost" -}}
{{- if .Values.mysql.enabled }}
{{- include "uptime-kuma.mysql.fullname" . }}
{{- else }}
{{- required "externalDatabase.host is required when mysql.enabled=false" .Values.externalDatabase.host }}
{{- end }}
{{- end }}

{{/*
Resolve the database port.
*/}}
{{- define "uptime-kuma.databasePort" -}}
{{- if .Values.mysql.enabled }}
{{- .Values.mysql.service.port | toString }}
{{- else }}
{{- .Values.externalDatabase.port | toString }}
{{- end }}
{{- end }}

{{/*
Resolve the database name.
*/}}
{{- define "uptime-kuma.databaseName" -}}
{{- if .Values.mysql.enabled }}
{{- .Values.mysql.auth.database }}
{{- else }}
{{- .Values.externalDatabase.database }}
{{- end }}
{{- end }}

{{/*
Resolve the database user.
*/}}
{{- define "uptime-kuma.databaseUser" -}}
{{- if .Values.mysql.enabled }}
{{- .Values.mysql.auth.username }}
{{- else }}
{{- .Values.externalDatabase.username }}
{{- end }}
{{- end }}

{{/*
Name of the secret holding DB credentials for Uptime Kuma.
*/}}
{{- define "uptime-kuma.databaseSecretName" -}}
{{- if .Values.mysql.enabled }}
  {{- if .Values.mysql.auth.existingSecret }}
    {{- .Values.mysql.auth.existingSecret }}
  {{- else }}
    {{- printf "%s-db-credentials" (include "uptime-kuma.fullname" .) }}
  {{- end }}
{{- else }}
  {{- if .Values.externalDatabase.existingSecret }}
    {{- .Values.externalDatabase.existingSecret }}
  {{- else }}
    {{- printf "%s-db-credentials" (include "uptime-kuma.fullname" .) }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Name of the MySQL secret (used by the MySQL StatefulSet).
*/}}
{{- define "uptime-kuma.mysql.secretName" -}}
{{- if .Values.mysql.auth.existingSecret }}
{{- .Values.mysql.auth.existingSecret }}
{{- else }}
{{- printf "%s-mysql-secret" (include "uptime-kuma.fullname" .) }}
{{- end }}
{{- end }}
