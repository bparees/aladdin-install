{{/*
Expand the name of the chart.
*/}}
{{- define "aladdin-backend.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "aladdin-backend.fullname" -}}
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
{{- define "aladdin-backend.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "aladdin-backend.labels" -}}
helm.sh/chart: {{ include "aladdin-backend.chart" . }}
{{ include "aladdin-backend.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "aladdin-backend.selectorLabels" -}}
app.kubernetes.io/name: {{ include "aladdin-backend.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
LLM labels
*/}}
{{- define "aladdin-backend.llm.labels" -}}
app: llm-api
{{- end }}

{{/*
K8S MCP labels
*/}}
{{- define "aladdin-backend.k8sMcp.labels" -}}
app: mcp-kubernetes
{{- end }}

{{/*
K8S MCP selector labels
*/}}
{{- define "aladdin-backend.k8sMcp.selectorLabels" -}}
app: mcp-kubernetes
{{- end }}

{{/*
Obs MCP labels
*/}}
{{- define "aladdin-backend.obsMcp.labels" -}}
app: genie-obs-mcp-server
{{- end }}

{{/*
Obs MCP selector labels
*/}}
{{- define "aladdin-backend.obsMcp.selectorLabels" -}}
app: genie-obs-mcp-server
{{- end }}

{{/*
NGUI MCP labels
*/}}
{{- define "aladdin-backend.nguiMcp.labels" -}}
app: ngui-mcp
{{- end }}

{{/*
NGUI MCP selector labels
*/}}
{{- define "aladdin-backend.nguiMcp.selectorLabels" -}}
app: ngui-mcp
{{- end }}

{{/*
Lightspeed Core labels
*/}}
{{- define "aladdin-backend.lightspeedCore.labels" -}}
app: lightspeed-core
{{- end }}

{{/*
Lightspeed Core selector labels
*/}}
{{- define "aladdin-backend.lightspeedCore.selectorLabels" -}}
app: lightspeed-core
{{- end }}

