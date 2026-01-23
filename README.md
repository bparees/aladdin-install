# Aladdin Prerequisites Helm Chart

This Helm chart installs the prerequisite components required for the Aladdin (Genie) AI assistant on OpenShift.

## Overview

The chart deploys the following components:

| Component | Description |
|-----------|-------------|
| **LLM API Secret** | API key secret for LLM provider access |
| **Obs MCP Server** | Observability MCP server for cluster metrics and monitoring data |
| **K8S MCP Server** | Kubernetes MCP server for cluster resource access |
| **NextGenUI MCP Server** | UI component generation MCP server |
| **Lightspeed Core** | Core service that orchestrates LLM interactions and MCP servers |

## Prerequisites

1. **OpenShift Cluster** - This chart is designed for OpenShift (uses service serving certificates)
2. **API Keys** - OpenAI (or compatible) API keys for LLM access
3. The genie web client is installed (steps for this listed below)

### Install the aladdin web client helm chart

To run aladdin you must have the aladdin web client installed, it comes from a separate
repo.  The following steps guide you through pulling down that repo and installing
its helm chart.

#### Clone the web client repo

```bash
$ git clone git@github.com:openshift/genie-web-client.git
$ cd genie-web-client
```
#### Build your own genie web client image (OPTIONAL)
If you don't want to build your own image you can use quay.io/bparees/genie-web-client:latest as your image.

```base
$ podman build -t quay.io/<your_quay_user>/genie-web-client:latest .
$ podman push quay.io/<your_quay_user>/genie-web-client:latest
```

Then go to quay.io and ensure the new image repository is public.

#### Run the web client helm chart installation

```bash
$ helm upgrade -i genie-web-client ./charts/openshift-console-plugin \
  -n genie-web-client \
  --create-namespace \
  --set plugin.name=genie-web-client \
  --set plugin.image=<YOUR_GENIE_IMAGE>
```

## Installation

Once you have the prereq steps completed, you can switch to the aladdin-installer repo to install the backend aladdin helm chart.

### Basic Installation

```bash
export LLM_API_KEY=<your llm api key>

helm upgrade -i aladdin-prereqs ./charts/aladdin-prereqs \
  -n openshift-aladdin \
  --create-namespace \
  --set llm.apiKey=$LLM_API_KEY \
  --set nguiMcp.apiKey=$LLM_API_KEY
```

When it finishes the chart will print out the URL need to access the aladdin console.

### Installation with Custom Values File

```bash
# Create a custom values file
cat > my-values.yaml <<EOF
llm:
  apiKey: "sk-..."
nguiMcp:
  apiKey: "sk-..."
EOF

helm upgrade -i aladdin-prereqs ./charts/aladdin-prereqs \
  -n openshift-aladdin \
  --create-namespace \
  -f my-values.yaml
```
### Installation with customized model + provider
By default this chart configures llamastack and Lightspeed Core to use the openai provider with the gpt-4o-mini model.  If you want to use a different provider or model you can override the parameter values by customizing the [charts/aladdin-prereqs/values.yaml](charts/aladdin-prereqs/values.yaml), or on the command line:

```bash
helm upgrade -i aladdin-prereqs ./charts/aladdin-prereqs \
  -n openshift-aladdin \
  --create-namespace \
  --set llm.apiKey=$LLM_API_KEY \
  --set nguiMcp.apiKey=$LLM_API_KEY \
  --set lightspeedCore.models.providerId=anthropic \
  --set lightspeedCore.models.providerType=remote::anthropic \
  --set lightspeedCore.models.modelId=claude-3-sonnet \
  --set lightspeedCore.models.providerModelId=claude-3-sonnet-20240229
```


## Uninstallation

```bash
helm uninstall aladdin-prereqs -n openshift-aladdin
```

**Note:** The ClusterRoleBinding is cluster-scoped and will be deleted. Secrets and ConfigMaps will also be removed.


## Advanced Options

### Building custom images
By default this chart uses a set of images that live under quay.io/bparees, but you want to use your own images you can clone the various repos and build/push the images and then reference them using the appropriate chart parameters.

#### Observability MCP Server

1. Clone https://github.com/rhobs/obs-mcp
1. `podman build -t quay.io/<your quay org>/obs-mcp:<some-tag>`
1. `podman push quay.io/<your quay org>/obs-mcp:<some-tag>`
1. Ensure the quay repository is public
1. Override the `obsMcp.image.repository` and `obsMcp.image.tag` chart parameters

#### Kubernetes MCP Server

1. Clone https://github.com/containers/kubernetes-mcp-server
1. `podman build -t quay.io/<your quay org>/k8s-mcp:<some-tag>`
1. `podman push quay.io/<your quay org>/k8s-mcp:<some-tag>`
1. Ensure the quay repository is public
1. Override the `k8sMcp.image.repository` and `k8sMcp.image.tag` chart parameters

#### NextGenUI MCP Server

1. Clone https://github.com/RedHat-UX/next-gen-ui-agent/
1. `cd libs/next_gen_ui_mcp/`
1. `podman build -t quay.io/<your quay org>/nextgenui-mcp:<some-tag>`
1. `podman push quay.io/<your quay org>/nextgenui-mcp:<some-tag>`
1. Ensure the quay repository is public
1. Override the `nguiMcp.image.repository` and `nguiMcp.image.tag` chart parameters

#### Lightspeed Core

1. Clone https://github.com/lightspeed-core/lightspeed-stack
1. `podman build -t quay.io/<your quay org>/lightspeed-core:<some-tag>`
1. `podman push quay.io/<your quay org>/lightspeed-core:<some-tag>`
1. Ensure the quay repository is public
1. Override the `lightspeedCore.image.repository` and `lightspeedCore.image.tag` chart parameters

### Configuring Parameters

The chart exposes a number of parameters that can be customized to alter the backend configuration.  Below is a comprehensive list of the available parameters and their default values.

#### LLM API Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `llm.apiKey` | LLM API key (required) | `""` |
| `llm.secretName` | Name of the API key secret | `llm-api-key` |

#### Obs MCP Server Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `obsMcp.enabled` | Enable Obs MCP server | `true` |
| `obsMcp.image.repository` | Container image repository | `quay.io/bparees/obs-mcp` |
| `obsMcp.image.tag` | Container image tag | `latest` |
| `obsMcp.image.pullPolicy` | Image pull policy | `Always` |
| `obsMcp.service.port` | Service port | `8080` |
| `obsMcp.replicas` | Number of replicas | `1` |
| `obsMcp.args` | Container arguments | `["-auth-mode", "header"]` |
| `obsMcp.prometheusUrl` | Prometheus URL for metrics queries | `https://prometheus-k8s.openshift-monitoring.svc:9091` |

#### Kubernetes MCP Server Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `k8sMcp.enabled` | Enable K8S MCP server | `true` |
| `k8sMcp.image.repository` | Container image repository | `quay.io/bparees/k8s-mcp` |
| `k8sMcp.image.tag` | Container image tag | `latest` |
| `k8sMcp.image.pullPolicy` | Image pull policy | `Always` |
| `k8sMcp.service.port` | Service port | `8080` |
| `k8sMcp.service.targetPort` | Container target port | `8080` |
| `k8sMcp.containerPort` | Container port | `8080` |
| `k8sMcp.replicas` | Number of replicas | `1` |
| `k8sMcp.args` | Container arguments | `["--read-only", "--toolsets", "core", "--log-level", "8"]` |

#### NextGenUI MCP Server Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `nguiMcp.enabled` | Enable NGUI MCP server | `true` |
| `nguiMcp.image.repository` | Container image repository | `quay.io/next-gen-ui/mcp` |
| `nguiMcp.image.tag` | Container image tag | `dev` |
| `nguiMcp.image.pullPolicy` | Image pull policy | `Always` |
| `nguiMcp.service.port` | Service port | `9200` |
| `nguiMcp.containerPort` | Container port | `9200` |
| `nguiMcp.replicas` | Number of replicas | `1` |
| `nguiMcp.apiKey` | NGUI provider API key (required if creating secret via Helm) | `""` |
| `nguiMcp.secretName` | Name of the API key secret | `ngui-llm-api-key` |
| `nguiMcp.configMapName` | Name of the config ConfigMap | `ngui-mcp-config` |
| `nguiMcp.env.model` | NGUI model name | `gpt-4.1-nano` |
| `nguiMcp.env.tools` | Enabled MCP tools | `generate_ui_component` |
| `nguiMcp.env.structuredOutputEnabled` | Enable structured output | `false` |

#### Lightspeed Core Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `lightspeedCore.enabled` | Enable Lightspeed Core | `true` |
| `lightspeedCore.image.repository` | Container image repository | `quay.io/bparees/lightspeed-core` |
| `lightspeedCore.image.tag` | Container image tag | `latest` |
| `lightspeedCore.image.pullPolicy` | Image pull policy | `Always` |
| `lightspeedCore.service.port` | Service port (HTTPS) | `8443` |
| `lightspeedCore.containerPort` | Container port | `8443` |
| `lightspeedCore.replicas` | Number of replicas | `1` |
| `lightspeedCore.tlsSecretName` | TLS secret name (auto-generated by OpenShift) | `lightspeed-core-tls` |
| `lightspeedCore.runConfigMapName` | LlamaStack run.yaml ConfigMap name | `llamastack-run` |
| `lightspeedCore.stackConfigMapName` | Lightspeed stack config ConfigMap name | `lightspeed-stack` |
| `lightspeedCore.mcpServers.obs.url` | Obs MCP server URL | `http://genie-obs-mcp-server:8080/mcp` |
| `lightspeedCore.mcpServers.kube.url` | K8S MCP server URL | `http://mcp-kubernetes-svc:8080/mcp` |
| `lightspeedCore.mcpServers.ngui.url` | NGUI MCP server URL | `http://ngui-mcp:9200/mcp` |
| `lightspeedCore.models.providerId` | LLM provider ID | `openai` |
| `lightspeedCore.models.providerType` | LLM provider type | `remote::openai` |
| `lightspeedCore.models.modelId` | Model ID | `gpt-4o-mini` |
| `lightspeedCore.models.modelType` | Model type | `llm` |
| `lightspeedCore.models.providerModelId` | Provider-specific model ID | `gpt-4o-mini` |

#### ConsolePlugin Patch Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `consolePluginPatch.enabled` | Enable ConsolePlugin patching | `true` |
| `consolePluginPatch.pluginName` | Name of ConsolePlugin to patch | `genie-web-client` |
| `consolePluginPatch.targetService.name` | Service name to point proxy to | `lightspeed-core` |
| `consolePluginPatch.targetService.namespace` | Service namespace | `openshift-aladdin` |
| `consolePluginPatch.targetService.port` | Service port | `8443` |

### Hardcoded Values

The following values are hardcoded in the templates and cannot be overridden:

| Value | Location | Description |
|-------|----------|-------------|
| Service names | Various templates | `genie-obs-mcp-server`, `mcp-kubernetes-svc`, `ngui-mcp`, `lightspeed-core` |
| TLS certificate paths | `lcore-configmap-stack.yaml` | `/opt/app-root/certs/tls.crt`, `/opt/app-root/certs/tls.key` |
| LlamaStack config path | `lcore-deployment.yaml` | `/opt/app-root/lightspeed-stack.yaml` |
| LlamaStack run.yaml path | `lcore-configmap-stack.yaml` | `/opt/app-root/run.yaml` |
| SQLite database paths | `lcore-configmap-run.yaml` | `/opt/app-root/.llama/distributions/ollama/*.db` |
| NGUI config mount path | `ngui-mcp-deployment.yaml` | `/opt/app-root/config/ngui_openshift_mcp_config.yaml` |
| NGUI data types config | `ngui-mcp-configmap.yaml` | Embedded configuration for UI component generation |
| OpenShift serving cert annotation | `lcore-service.yaml` | `service.beta.openshift.io/serving-cert-secret-name` |

## Resources Created

| Resource Type | Count | Names |
|---------------|-------|-------|
| Secret | 2 | `llm-api-key`, `ngui-llm-api-key` |
| ConfigMap | 3 | `ngui-mcp-config`, `llamastack-run`, `lightspeed-stack` |
| ServiceAccount | 5 | `genie-obs-mcp-server`, `mcp-kubernetes`, `ngui-mcp`, `lightspeed-core`, `consoleplugin-patcher` |
| Deployment | 4 | `genie-obs-mcp-server`, `mcp-kubernetes`, `ngui-mcp`, `lightspeed-core` |
| Service | 4 | `genie-obs-mcp-server`, `mcp-kubernetes-svc`, `ngui-mcp`, `lightspeed-core` |
| Job | 1 | `consoleplugin-patcher` (post-install hook) |
| ClusterRole | 1 | `<namespace>-consoleplugin-patcher` |
| ClusterRoleBinding | 1 | `<namespace>-consoleplugin-patcher` |



## Troubleshooting

### Check Pod Status
```bash
oc get pods -n openshift-aladdin
```

### View Logs
```bash
oc logs -l app=lightspeed-core -n openshift-aladdin
oc logs -l app=mcp-kubernetes -n openshift-aladdin
oc logs -l app=ngui-mcp -n openshift-aladdin
oc logs -l app=genie-obs-mcp-server -n openshift-aladdin
```

### Verify TLS Certificate
```bash
oc get secret lightspeed-core-tls -n openshift-aladdin
```



# TODO
- mcp servers not using TLS
