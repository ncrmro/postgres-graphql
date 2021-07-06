{{/*
Create the database hostname
*/}}
{{- define "postgres.hostname" -}}
{{ template "common.names.fullname" . }}.{{ .Release.Namespace }}.svc.cluster.local
{{- end }}


{{/*
Create the database URI
*/}}
{{- define "postgres.databaseURI" -}}
{{- printf "postgres://%s:%s@%s/%s" .Values.database.owner.username .Values.database.owner.password (include "postgres.hostname" .) .Values.database.name }}
{{- end }}
