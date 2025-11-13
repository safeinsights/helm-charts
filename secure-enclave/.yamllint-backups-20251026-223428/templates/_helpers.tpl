{{/*
Expand the name of the chart.
*/}}
{{- define "secure-enclave.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "secure-enclave.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "secure-enclave.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "secure-enclave.labels" -}}
helm.sh/chart: {{ include "secure-enclave.chart" . }}
{{ include "secure-enclave.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "secure-enclave.selectorLabels" -}}
app.kubernetes.io/name: {{ include "secure-enclave.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "secure-enclave.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "secure-enclave.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Component-aware selector labels
*/}}
{{- define "secure-enclave.selectorLabelsFor" -}}
{{- $root := index . "root" -}}
{{- $name := index . "name" -}}
app.kubernetes.io/name: {{ $name | default (include "secure-enclave.name" $root) }}
app.kubernetes.io/instance: {{ $root.Release.Name }}
{{- end }}

{{/*
Component-aware full labels
*/}}
{{- define "secure-enclave.labelsFor" -}}
{{- $root := index . "root" -}}
{{- $name := index . "name" -}}
helm.sh/chart: {{ include "secure-enclave.chart" $root }}
{{ include "secure-enclave.selectorLabelsFor" (dict "root" $root "name" $name) }}
{{- if $root.Chart.AppVersion }}
app.kubernetes.io/version: {{ $root.Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ $root.Release.Service }}
{{- end }}

{{/*
Get the admin namespace
*/}}
{{- define "secure-enclave.adminNamespace" -}}
{{- .Values.adminNamespace | default "enclave-admin-ns" }}
{{- end }}

{{/*
Get the research namespace
*/}}
{{- define "secure-enclave.researchNamespace" -}}
{{- required "values.researchNamespace is required" .Values.researchNamespace }}
{{- end }}

{{/*
Default-deny NetworkPolicy template
*/}}
{{- define "secure-enclave.defaultDenyNetworkPolicy" }}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: {{ .namespace }}
  labels:
    {{- include "secure-enclave.labels" .root | nindent 4 }}
spec:
  podSelector: {}
  policyTypes: ["Ingress","Egress"]
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
          podSelector:
            matchLabels:
              k8s-app: kube-dns
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
{{- end }}

{{/*
Get the service account name for setup-app
*/}}
{{- define "secure-enclave.setupAppServiceAccountName" -}}
{{- if .Values.setupApp.serviceAccount.name -}}
{{- .Values.setupApp.serviceAccount.name }}
{{- else -}}
{{- printf "%s-sa" .Values.setupApp.name }}
{{- end }}
{{- end }}

{{/*
Get the service account name for trusted-output-app
*/}}
{{- define "secure-enclave.trustedOutputAppServiceAccountName" -}}
{{- if .Values.trustedOutputApp.serviceAccount.name -}}
{{- .Values.trustedOutputApp.serviceAccount.name }}
{{- else -}}
{{- printf "%s-sa" .Values.trustedOutputApp.name }}
{{- end }}
{{- end }}
