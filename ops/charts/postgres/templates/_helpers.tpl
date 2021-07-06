{{/*
Create the database hostname
*/}}
{{- define "postgres.hostname" -}}
postgres-postgresql.{{ .Release.Namespace }}.svc.cluster.local
{{- end }}

{{/*
Create the database owner URI
*/}}
{{- define "postgres.owner.databaseURI" -}}
{{- printf "postgres://%s:%s@%s/%s" .Values.database.owner.username .Values.database.owner.password (include "postgres.hostname" .) .Values.database.name }}
{{- end }}

{{/*
Create the database authenticator URI
*/}}
{{- define "postgres.authenticator.databaseURI" -}}
{{- printf "postgres://%s:%s@%s/%s" .Values.database.authenticator.username .Values.database.authenticator.password (include "postgres.hostname" .) .Values.database.name }}
{{- end }}
