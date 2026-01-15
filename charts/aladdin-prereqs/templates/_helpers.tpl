{{/*
Expand the name of the chart.
*/}}
{{- define "aladdin-prereqs.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "aladdin-prereqs.fullname" -}}
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
{{- define "aladdin-prereqs.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "aladdin-prereqs.labels" -}}
helm.sh/chart: {{ include "aladdin-prereqs.chart" . }}
{{ include "aladdin-prereqs.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "aladdin-prereqs.selectorLabels" -}}
app.kubernetes.io/name: {{ include "aladdin-prereqs.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
LLM labels
*/}}
{{- define "aladdin-prereqs.llm.labels" -}}
app: llm-api
{{- end }}

{{/*
K8S MCP labels
*/}}
{{- define "aladdin-prereqs.k8sMcp.labels" -}}
app: mcp-kubernetes
{{- end }}

{{/*
K8S MCP selector labels
*/}}
{{- define "aladdin-prereqs.k8sMcp.selectorLabels" -}}
app: mcp-kubernetes
{{- end }}

{{/*
Obs MCP labels
*/}}
{{- define "aladdin-prereqs.obsMcp.labels" -}}
app: genie-obs-mcp-server
{{- end }}

{{/*
Obs MCP selector labels
*/}}
{{- define "aladdin-prereqs.obsMcp.selectorLabels" -}}
app: genie-obs-mcp-server
{{- end }}

{{/*
NGUI MCP labels
*/}}
{{- define "aladdin-prereqs.nguiMcp.labels" -}}
app: ngui-mcp
{{- end }}

{{/*
NGUI MCP selector labels
*/}}
{{- define "aladdin-prereqs.nguiMcp.selectorLabels" -}}
app: ngui-mcp
{{- end }}

{{/*
Lightspeed Core labels
*/}}
{{- define "aladdin-prereqs.lightspeedCore.labels" -}}
app: lightspeed-core
{{- end }}

{{/*
Lightspeed Core selector labels
*/}}
{{- define "aladdin-prereqs.lightspeedCore.selectorLabels" -}}
app: lightspeed-core
{{- end }}

