{{- define "projeto-final.name" -}}
{{- .Chart.Name -}}
{{- end -}}

{{- define "projeto-final.labels" -}}
app.kubernetes.io/part-of: {{ include "projeto-final.name" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
environment: {{ .Values.environment }}
{{- end -}}

{{- define "projeto-final.serviceFQDN" -}}
{{- printf "%s.%s.svc.cluster.local" .name .context.Release.Namespace -}}
{{- end -}}
