{{/*
Expand the name of the chart.
*/}}
{{- define "secure-enclave.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
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
Get VPC CIDR from ConfigMap
*/}}
{{- define "secure-enclave.svcCidr" -}}
{{- $configMap := lookup "v1" "ConfigMap" .Release.Namespace "enclave-config" }}
{{- if $configMap }}
{{- $vpcCidr := index $configMap.data "cluster-ip" }}
{{- $vpcCidr }}
{{- else }}
1.1.1.1/16
{{- end }}
{{- end }}

{{/*
kube-dns service ClusterIP. With GKE NodeLocal DNSCache, pods query the kube-dns *service* IP
(intercepted by the node-local cache) rather than a kube-dns pod, so a pod-selector egress rule
isn't enough — callers also allow egress to this /32 on port 53. The kube-dns service pre-exists,
so this lookup resolves at render time (unlike enclave-config, which a pre-install hook creates).
*/}}
{{- define "secure-enclave.kubeDnsClusterIP" -}}
{{- $svc := lookup "v1" "Service" "kube-system" "kube-dns" -}}
{{- if $svc }}{{ $svc.spec.clusterIP }}{{ end -}}
{{- end }}

{{/*
Get allowed external endpoints from ConfigMap
*/}}
{{- define "secure-enclave.allowedExternalEndpoints" -}}
{{- $configMap := lookup "v1" "ConfigMap" .Release.Namespace "enclave-config" }}
{{- if $configMap }}
{{- $endpoints := index $configMap.data "allowed-external-endpoints" }}
{{- if $endpoints }}
{{- $endpoints }}
{{- else }}
{{- end }}
{{- else }}
{{- end }}
{{- end }}



{{/*
Convert comma separated string to array
*/}}
{{- define "secure-enclave.commaSepToStringArray" -}}
{{- splitList "," . -}}
{{- end }}

{{/*
Validate enclave configuration 
*/}}
{{- define "secure-enclave.validateConfiguration" -}}
{{- if and .Values.aws.enabled .Values.gcp.enabled }}
{{- fail "aws.enabled and gcp.enabled are mutually exclusive; enable only one cloud" }}
{{- end }}
{{- if not .Values.managementApp }}
{{- fail "managementApp section is required in values" }}
{{- else if not .Values.managementApp.memberId }}
{{- fail "managementApp.memberId is required and cannot be empty" }}
{{- else if not .Values.managementApp.endpoint }}
{{- fail "managementApp.endpoint is required and cannot be empty" }}
{{- end }}
{{- end }}

{{/*
Extract host from URL
*/}}
{{- define "secure-enclave.extractHostFromUrl" -}}
{{- $url := . -}}
{{- $host := regexReplaceAll "^(?:https?://)?([^/]+).*" $url "${1}" -}}
{{- $host }}
{{- end }}

