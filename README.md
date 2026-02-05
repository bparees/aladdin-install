# Aladdin Backend Helm Chart

This Helm chart installs the backend components required for the Aladdin AI assistant on OpenShift.  The frontend is installed via a separate chart, see instructions below.

## Overview

The chart supports two backend options for orchestrating LLM interactions:

1. **OLS (OpenShift Lightspeed)** - The default backend. Installs the Red Hat Lightspeed operator from OperatorHub.
2. **Lightspeed Core** - An alternative backend that deploys lightspeed-core as the inference/mcp api provider

### Common Components (deployed with both backends)

| Component | Description |
|-----------|-------------|
| **Obs MCP Server** | Observability MCP server for cluster metrics and monitoring data |
| **K8S MCP Server** | Kubernetes MCP server for cluster resource access |
| **NextGenUI MCP Server** | UI component generation MCP server |

### OLS Backend Components (default)

| Component | Description |
|-----------|-------------|
| **OLS Namespace** | Creates the `openshift-lightspeed` namespace |
| **OLS OperatorGroup** | OperatorGroup for the Lightspeed operator |
| **OLS Subscription** | Subscription to install the Lightspeed operator from OperatorHub |
| **OLS API Key Secret** | Secret containing the LLM API key |
| **OLSConfig** | Custom resource that configures the Lightspeed operator |

### Lightspeed Core Backend Components (alternative)

| Component | Description |
|-----------|-------------|
| **Lightspeed Core** | Core service that orchestrates LLM interactions and MCP servers |
| **LLM API Secret** | API key secret for LLM provider access |
| **ConsolePlugin Patch** | Job that patches the web client to point to lightspeed-core |

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

Choose one of the two backend options below:

### Option 1: Install with OLS Backend (Default)

The OLS (OpenShift Lightspeed) backend installs the Red Hat Lightspeed operator from OperatorHub and configures it via an OLSConfig custom resource. This is the default option.

```bash
export LLM_API_KEY=<your llm api key>

helm upgrade -i aladdin-backend ./charts/aladdin-backend \
  -n openshift-aladdin \
  --create-namespace \
  --set olsConfig.llm.apiKey=$LLM_API_KEY \
  --set nguiMcp.apiKey=$LLM_API_KEY
```

When it finishes the chart will print out the URL needed to access the aladdin console.

#### OLS with Custom Model/Provider

By default OLS is configured to use the OpenAI provider with the gpt-5-mini model. To use a different provider or model:

```bash
helm upgrade -i aladdin-backend ./charts/aladdin-backend \
  -n openshift-aladdin \
  --create-namespace \
  --set olsConfig.llm.apiKey=$LLM_API_KEY \
  --set nguiMcp.apiKey=$LLM_API_KEY \
  --set olsConfig.llm.providers[0].name=Anthropic \
  --set olsConfig.llm.providers[0].type=anthropic \
  --set olsConfig.llm.providers[0].models[0]=claude-3-sonnet \
  --set olsConfig.ols.defaultModel=claude-3-sonnet \
  --set olsConfig.ols.defaultProvider=Anthropic
```

### Option 2: Install with Lightspeed Core Backend

The Lightspeed Core backend deploys+configures the lightspeed-core service for llm inference and mcp server interaction.

```bash
export LLM_API_KEY=<your llm api key>

helm upgrade -i aladdin-backend ./charts/aladdin-backend \
  -n openshift-aladdin \
  --create-namespace \
  --set olsConfig.enabled=false \
  --set lightspeedCore.enabled=true \
  --set lightspeedCore.llm.apiKey=$LLM_API_KEY \
  --set nguiMcp.apiKey=$LLM_API_KEY
```

#### Lightspeed Core with Custom Model/Provider

By default Lightspeed Core is configured to use the OpenAI provider with the gpt-5-mini model. To use a different provider or model:

```bash
helm upgrade -i aladdin-backend ./charts/aladdin-backend \
  -n openshift-aladdin \
  --create-namespace \
  --set olsConfig.enabled=false \
  --set lightspeedCore.enabled=true \
  --set lightspeedCore.llm.apiKey=$LLM_API_KEY \
  --set nguiMcp.apiKey=$LLM_API_KEY \
  --set lightspeedCore.models.providerId=anthropic \
  --set lightspeedCore.models.providerType=remote::anthropic \
  --set lightspeedCore.models.modelId=claude-3-sonnet \
  --set lightspeedCore.models.providerModelId=claude-3-sonnet-20240229
```

### Installation with Custom Values File

You can also use a values file instead of command line parameters:

#### OLS Backend Values File

```bash
cat > my-values.yaml <<EOF
olsConfig:
  llm:
    apiKey: "sk-..."
nguiMcp:
  apiKey: "sk-..."
EOF

helm upgrade -i aladdin-backend ./charts/aladdin-backend \
  -n openshift-aladdin \
  --create-namespace \
  -f my-values.yaml
```

#### Lightspeed Core Backend Values File

```bash
cat > my-values.yaml <<EOF
olsConfig:
  enabled: false
lightspeedCore:
  enabled: true
  llm:
    apiKey: "sk-..."
nguiMcp:
  apiKey: "sk-..."
EOF

helm upgrade -i aladdin-backend ./charts/aladdin-backend \
  -n openshift-aladdin \
  --create-namespace \
  -f my-values.yaml
```


## Uninstallation

```bash
helm uninstall aladdin-backend -n openshift-aladdin
oc delete ns openshift-aladdin
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
1. `./get-pants.sh` - only need to run this once to install `pants`
1. `pants package --filter-target-type=docker_image ::` - this builds the images
1. `podman tag quay.io/next-gen-ui/mcp:dev quay.io/<your quay org>/nextgenui-mcp:<some-tag>`
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

Note: The K8S MCP server is only deployed when `lightspeedCore.enabled` is `true`.

| Parameter | Description | Default |
|-----------|-------------|---------|
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
| `nguiMcp.image.repository` | Container image repository | `quay.io/bparees/ngui-mcp` |
| `nguiMcp.image.tag` | Container image tag | `latest` |
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

#### OLS Subscription Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `olsSubscription.name` | Subscription name | `lightspeed-operator` |
| `olsSubscription.namespace` | Namespace for the operator | `openshift-lightspeed` |
| `olsSubscription.channel` | Subscription channel | `stable` |
| `olsSubscription.installPlanApproval` | Install plan approval mode | `Automatic` |
| `olsSubscription.source` | Catalog source | `redhat-operators` |
| `olsSubscription.sourceNamespace` | Catalog source namespace | `openshift-marketplace` |
| `olsSubscription.operatorGroupName` | OperatorGroup name | `openshift-lightspeed` |
| `olsSubscription.targetNamespaces` | Target namespaces for the operator | `["openshift-lightspeed"]` |

#### OLS Config Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `olsConfig.enabled` | Enable OLS backend (controls all OLS resources) | `true` |
| `olsConfig.llm.apiKey` | LLM API key (required) | `""` |
| `olsConfig.llm.apiKeySecretName` | Name of the API key secret | `ols-llm-api-key` |
| `olsConfig.llm.providers` | Array of LLM provider configurations | See values.yaml |
| `olsConfig.ols.defaultModel` | Default model to use | `gpt-5-mini` |
| `olsConfig.ols.defaultProvider` | Default provider to use | `OpenAI` |
| `olsConfig.mcpServers` | MCP server configuration for OLS | See values.yaml |

#### Lightspeed Core Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `lightspeedCore.enabled` | Enable Lightspeed Core | `false` |
| `lightspeedCore.llm.apiKey` | LLM API key (required) | `""` |
| `lightspeedCore.llm.apiKeySecretName` | Name of the API key secret | `lcore-llm-api-key` |
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

Note: ConsolePlugin patching is automatically enabled when `lightspeedCore.enabled` is `true`.

| Parameter | Description | Default |
|-----------|-------------|---------|
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

### Common Resources (both backends)

| Resource Type | Count | Names |
|---------------|-------|-------|
| Secret | 1 | `ngui-llm-api-key` |
| ConfigMap | 1 | `ngui-mcp-config` |
| ServiceAccount | 3 | `genie-obs-mcp-server`, `mcp-kubernetes`, `ngui-mcp` |
| Deployment | 3 | `genie-obs-mcp-server`, `mcp-kubernetes`, `ngui-mcp` |
| Service | 3 | `genie-obs-mcp-server`, `mcp-kubernetes-svc`, `ngui-mcp` |

### OLS Backend Resources (default)

| Resource Type | Count | Names | Notes |
|---------------|-------|-------|-------|
| Namespace | 1 | `openshift-lightspeed` | Created via pre-install hook |
| OperatorGroup | 1 | `openshift-lightspeed` | Created via pre-install hook |
| Subscription | 1 | `lightspeed-operator` | Installs the Lightspeed operator |
| Secret | 1 | `ols-llm-api-key` | In `openshift-lightspeed` namespace |
| OLSConfig | 1 | `cluster` | Created via post-install hook after CRD is available |
| ServiceAccount | 1 | `ols-crd-wait-sa` | Helm hook, deleted after success |
| ClusterRole | 1 | `ols-crd-wait-role` | Helm hook, deleted after success |
| ClusterRoleBinding | 1 | `ols-crd-wait-rolebinding` | Helm hook, deleted after success |
| Job | 1 | `ols-wait-for-crd` | Waits for OLS CRD, deleted after success |

### Lightspeed Core Backend Resources (alternative)

| Resource Type | Count | Names |
|---------------|-------|-------|
| Secret | 1 | `lcore-llm-api-key` |
| ConfigMap | 2 | `llamastack-run`, `lightspeed-stack` |
| ServiceAccount | 2 | `lightspeed-core`, `consoleplugin-patcher` |
| Deployment | 1 | `lightspeed-core` |
| Service | 1 | `lightspeed-core` |
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
