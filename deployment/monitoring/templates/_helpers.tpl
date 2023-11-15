{{/*
Expand the name of the chart.
*/}}
{{- define "monitoring.name" -}}
{{- default .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "monitoring.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "monitoring.labels" -}}
helm.sh/chart: {{ include "monitoring.chart" . }}
{{ include "monitoring.selectorLabels" . }}
{{ include "monitoring.workloadLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/part-of: opentelemetry-demo
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}



{{/*
Workload (Pod) labels
*/}}
{{- define "monitoring.workloadLabels" -}}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .name }}
app.kubernetes.io/component: {{ .name}}
app.kubernetes.io/name: {{ include "monitoring.name" . }}-{{ .name }}
{{- else }}
app.kubernetes.io/name: {{ include "monitoring.name" . }}
{{- end }}
{{- end }}




{{/*
Selector labels
*/}}
{{- define "monitoring.selectorLabels" -}}
{{- if .name }}
opentelemetry.io/name: {{ include "monitoring.name" . }}-{{ .name }}
{{- else }}
opentelemetry.io/name: {{ include "monitoring.name" . }}
{{- end }}
{{- end }}

{{- define "monitoring.envOverriden" -}}
{{- $mergedEnvs := list }}
{{- $envOverrides := default (list) .envOverrides }}

{{- range .env }}
{{-   $currentEnv := . }}
{{-   $hasOverride := false }}
{{-   range $envOverrides }}
{{-     if eq $currentEnv.name .name }}
{{-       $mergedEnvs = append $mergedEnvs . }}
{{-       $envOverrides = without $envOverrides . }}
{{-       $hasOverride = true }}
{{-     end }}
{{-   end }}
{{-   if not $hasOverride }}
{{-     $mergedEnvs = append $mergedEnvs $currentEnv }}
{{-   end }}
{{- end }}
{{- $mergedEnvs = concat $mergedEnvs $envOverrides }}
{{- mustToJson $mergedEnvs }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "monitoring.serviceAccountName" -}}
{{- if .serviceAccount.create }}
{{- default (include "monitoring.name" .) .serviceAccount.name }}
{{- else }}
{{- default "default" .serviceAccount.name }}
{{- end }}
{{- end }}