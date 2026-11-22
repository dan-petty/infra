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
{{- /*
"true" when the services entry has the secret store (secrets.store), else an empty string.
*/ -}}
{{- define "service-tenant.store" -}}
{{- if and .Values.name (.Values.secrets | default dict).store }}true{{ end }}
{{- end }}
{{- /*
The store namespace of the service: <name>-secrets.
*/ -}}
{{- define "service-tenant.storeNamespace" -}}
{{- printf "%s-secrets" .Values.name }}
{{- end }}
