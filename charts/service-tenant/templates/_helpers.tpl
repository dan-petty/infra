{{/*
The labels of each object of the chart.
*/}}
{{- define "service-tenant.labels" -}}
app.kubernetes.io/name: service-tenant
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: {{ .Values.name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end }}
