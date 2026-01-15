# Create cluster

# Install OLS
Needed, but not sure why……

## Install operator
From console UI, operator hub, install OLS

## Create LLM api creds secret
$ oc create -f /home/bparees/git/gocode/src/github.com/openshift/lightspeed-service/scratch/openai.secret.yaml

apiVersion: v1
kind: Secret
metadata:
  name: "openai-api-keys"
  namespace: openshift-lightspeed
type: Opaque
stringData:
  apitoken: <YOUR API TOKEN STRING>


## Create OLS config
Note: this config assumes the api creds are for openai.  Modify as needed.

$ oc create -f /home/bparees/git/gocode/src/github.com/openshift/lightspeed-service/scratch/olsconfig.crd.openai.yaml

apiVersion: ols.openshift.io/v1alpha1
kind: OLSConfig
metadata:
  name: cluster
  labels:
    app.kubernetes.io/created-by: lightspeed-operator
    app.kubernetes.io/instance: olsconfig-sample
    app.kubernetes.io/managed-by: kustomize
    app.kubernetes.io/name: olsconfig
    app.kubernetes.io/part-of: lightspeed-operator
spec:
  llm:
    providers:
      - credentialsSecretRef:
          name: openai-api-keys
        models:
          - name: gpt-4o-mini
        name: OpenAI
        type: openai
        url: 'https://api.openai.com/v1'
  ols:
    defaultModel: gpt-4o-mini
    defaultProvider: OpenAI

# Install Obs MCP

## Starting from clone of https://github.com/rhobs/obs-mcp

## Build binary
$ go build .

## Build image
$ podman build -t quay.io/bparees/obs-mcp:latest .
$ podman push quay.io/bparees/obs-mcp:latest

## Create OCP resources
$ oc create -f /home/bparees/git/gocode/src/github.com/openshift/rhobs/obs-mcp/manifests/01_service_account.yaml 

edit manifests/02_deployment.yaml to point to quay.io/bparees/obs-mcp:latest or other obs-mcp image
$ oc create -f /home/bparees/git/gocode/src/github.com/openshift/rhobs/obs-mcp/manifests/02_deployment.yaml 

$ oc create -f /home/bparees/git/gocode/src/github.com/openshift/rhobs/obs-mcp/manifests/03_mcp_service.yaml 


## Install K8S MCP
Note: should be openshift mcp in the future?

## Build/publish a K8S MCP image

Clone repo:
git clone https://github.com/containers/kubernetes-mcp-server

build the image
$ podman build -t quay.io/bparees/k8s-mcp:latest .
$ podman push quay.io/bparees/k8s-mcp:latest

## Deploy K8S-MCP

### Create deployment
$ oc create -f /home/bparees/git/gocode/src/github.com/bparees/aladdin-install/resources/k8s-mcp/k8s-mcp-deployment.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
 name: mcp-kubernetes
 labels:
   app: mcp-kubernetes
spec:
 replicas: 1
 selector:
   matchLabels:
     app: mcp-kubernetes
 template:
   metadata:
     labels:
       app: mcp-kubernetes
   spec:
     containers:
       - name: mcp-kubernetes
         image: quay.io/bparees/k8s-mcp:latest
         imagePullPolicy: IfNotPresent
         ports:
           - containerPort: 8080
         args:
           - "--read-only"
           - "--toolsets"
           - "core"



### Create service
$ oc create -f /home/bparees/git/gocode/src/github.com/bparees/aladdin-install/resources/k8s-mcp/k8s-mcp-service.yaml

apiVersion: v1
kind: Service
metadata:
 name: mcp-kubernetes-svc
 labels:
   app: mcp-kubernetes
spec:
 selector:
   app: mcp-kubernetes
 ports:
   - protocol: TCP
     port: 80             # service port
     targetPort: 8080     # same as containerPort
 type: ClusterIP    


### Grant Permissions
Ensure the k8s mcp server can read OLS data
Note: SHOULD NOT BE NECESSARY, Aladdin should be performing actions w/ the User’s permissions.

$ oc adm policy add-cluster-role-to-user cluster-admin -z default



# NextGenUI MCP Install

## Create configmap for ngui config

$ oc project openshift-lightspeed
$ oc create configmap ngui-mcp-config  --from-file=ngui_openshift_mcp_config.yaml=/home/bparees/git/gocode/src/github.com/bparees/aladdin-install/resources/ngui/ngui_openshift_mcp_config.yaml

## Create secret for api key
# note, update this to reuse api key secret from OLS?
$ oc create secret generic ngui-openai-secret   --from-literal=NGUI_PROVIDER_API_KEY="<YOUR_API_KEY>"


## Create deployment
$ oc create -f /home/bparees/git/gocode/src/github.com/bparees/aladdin-install/resources/ngui/ngui-mcp-deployment.yaml


## Create service
$ oc create -f /home/bparees/git/gocode/src/github.com/bparees/aladdin-install/resources/ngui/ngui-mcp-service.yaml


# Lightspeed Core

Starting from clone of https://github.com/lightspeed-core/lightspeed-stack

## Build the image
$ podman build -t quay.io/bparees/lightspeed-core:latest
$ podman push quay.io/bparees/lightspeed-core:latest

## Create configuration

Note: 
modify lcore config yaml
point to /opt/app-root/run.yaml
mount path for llamastack’s config file
include all MCP servers (obs, kcp, ngui)
Use tls configuration (service signing certs)
modify llamastack run.yaml config
 use /opt/app-root/.llama for storage (multiple spots)
reuses/shares openai secret that was created for OLS


$ oc create configmap llamastack-run --from-file=run.yaml=/home/bparees/git/gocode/src/github.com/bparees/aladdin-install/resources/lcore/run.yaml
$ oc create configmap lightspeed-stack --from-file=lightspeed-stack.yaml=/home/bparees/git/gocode/src/github.com/bparees/aladdin-install/resources/lcore/lightspeed-stack.yaml

## Create deployment

$ oc create -f /home/bparees/git/gocode/src/github.com/bparees/aladdin-install/resources/lcore/lcore-deployment.yaml
$ oc create -f /home/bparees/git/gocode/src/github.com/bparees/aladdin-install/resources/lcore/lcore-service.yaml


# Genie Plugin

https://github.com/openshift/genie-web-client/blob/main/DEPLOY-GUIDE.md

Run ./deploy.sh ?

Starting from https://github.com/openshift/genie-web-client

## Build the image
Note: had to bump based image to node-20 instead of node-18

Edit code to use on-cluster OLS api:
https://github.com/openshift/genie-web-client/blob/fd618b5afaa3c5d3cf8f93fec569adae18684018/src/components/utils/aiStateManager.ts#L50-L56

$ podman build -t quay.io/bparees/genie-web-client:latest .
$ podman push quay.io/bparees/genie-web-client:latest

## Deploy the image
Note: creates console resources in genie-web-client namespace

$ helm upgrade -i genie-web-client ./charts/openshift-console-plugin \
  -n genie-web-client \
  --create-namespace \
  --set plugin.name=genie-web-client \
  --set plugin.image=quay.io/bparees/genie-web-client:latest

edit ols proxy config to point to lightspeed-core server name, not ols-app
$ oc edit consoleplugin

Note: deployment uses PullIfNotPresent, should probably change to PullAlways for dev purposes

Note: modify ConsolePlugin to point the “ols” proxy to the “lightspeed-core” service instead of the OLS app service

## Access the console
https://console-openshift-console.apps.bparees.devcluster.openshift.com/genie/chat
