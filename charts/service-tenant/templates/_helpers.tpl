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
{{- /*
The SeaweedFS store resources for a backup bucket (Bucket, S3Identity, S3Policy, S3PolicyBinding,
S3Credentials). Called for each namespace that sets backup.quotaGiB, or for one platform namespace.
Takes a dict with:
- namespace: the namespace of the backup client
- quotaGiB: the quota of the bucket in GiB
- secretName (optional): the name of the Secret in object-store (default: object-store-backup)
- root: the chart context
*/ -}}
{{- define "service-tenant.backupStore" -}}
{{- $ns := .namespace -}}
{{- $quota := .quotaGiB -}}
{{- $secret := .secretName | default "object-store-backup" -}}
{{- $root := .root }}

---
apiVersion: seaweed.seaweedfs.com/v1
kind: Bucket
metadata:
  name: backups-{{ $ns }}
  namespace: object-store
  labels:
    {{- include "service-tenant.labels" $root | nindent 4 }}
spec:
  name: backups-{{ $ns }}
  clusterRef:
    name: seaweedfs
  quota:
    size: {{ $quota }}Gi
    enforce: true
  reclaimPolicy: Retain
---
apiVersion: seaweed.seaweedfs.com/v1
kind: S3Identity
metadata:
  name: backups-{{ $ns }}
  namespace: object-store
  labels:
    {{- include "service-tenant.labels" $root | nindent 4 }}
spec:
  seaweedRef:
    name: seaweedfs
---
apiVersion: seaweed.seaweedfs.com/v1
kind: S3Policy
metadata:
  name: backups-{{ $ns }}
  namespace: object-store
  labels:
    {{- include "service-tenant.labels" $root | nindent 4 }}
spec:
  seaweedRef:
    name: seaweedfs
  statements:
    - effect: Allow
      actions:
        - "s3:*"
      resources:
        - "backups-{{ $ns }}"
        - "backups-{{ $ns }}/*"
---
apiVersion: seaweed.seaweedfs.com/v1
kind: S3PolicyBinding
metadata:
  name: backups-{{ $ns }}
  namespace: object-store
  labels:
    {{- include "service-tenant.labels" $root | nindent 4 }}
spec:
  seaweedRef:
    name: seaweedfs
  policyRef:
    name: backups-{{ $ns }}
  subjects:
    - kind: S3Identity
      name: backups-{{ $ns }}
---
apiVersion: seaweed.seaweedfs.com/v1
kind: S3Credentials
metadata:
  name: backups-{{ $ns }}
  namespace: object-store
  labels:
    {{- include "service-tenant.labels" $root | nindent 4 }}
spec:
  seaweedRef:
    name: seaweedfs
  identityRef:
    name: backups-{{ $ns }}
  secretRef:
    name: {{ $secret }}
{{- end }}
