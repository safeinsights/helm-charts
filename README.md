# Secure Enclave Charts

This repository contains Kubernetes charts for deploying two main components: 
- Setup App
- Trusted Output App

## Introduction

This repository provides Kubernetes manifests and Helm charts for deploying two key components:
1. **Setup App**: The setup app is the part of the enclave that polls the Management App for new avalaible research studies to run in the enclave. Once some studies become available, The setup app pull the container image, and start the research container with the variable environments needed to communicate with the Trusted Output App.  
There is some documentation on the Setup App architecture and how it runs in different enclave environments (AWS. KUBERNETES, DOCKER) available [here](https://github.com/safeinsights/setup-app#enclave-environments)

1. **Trusted Output Application**: The Trusted Output App is used to validate the results sent by the research container before they are sent to the Management App.

## Installation

### Prerequisites
- Kubernetes cluster with proper authentication/authorization configured.
- `Helm` installed on your system.
- **Calico** network plugin installed on the cluster (see [Calico Installation](#calico-installation) below).

### Calico Installation

This chart uses [Calico](https://www.tigera.io/project-calico/) network policies (`crd.projectcalico.org/v1`) for zero-trust network enforcement. Calico must be installed on the cluster before deploying the secure-enclave chart.

#### GKE Cluster Setup

When using Google Kubernetes Engine (GKE), you must configure Calico to run as the full CNI (not just policy-only mode). This ensures the `calico-node` DaemonSet is deployed, which is required by this chart.

**Step 1: Create GKE cluster without Dataplane V2**

```bash
gcloud container clusters create my-cluster \
  --zone $ZONE \
  --num-nodes $NUMBER_OF_NODES \
  --no-enable-dataplane-v2

# Get cluster credentials
gcloud container clusters get-credentials my-cluster --zone $ZONE
```

**Step 2: Install Calico using the Tigera Operator**

```bash
helm repo add projectcalico https://docs.tigera.io/calico/charts
helm repo update
helm install calico projectcalico/tigera-operator \
  --version $VERSION \
  --namespace tigera-operator \
  --create-namespace
```

**Step 3: Configure Calico for full CNI mode**

By default, the Tigera Operator auto-detects GKE and configures Calico in policy-only mode (`cni.type: GKE`), which does not create the `calico-node` DaemonSet. You must patch the Installation to use Calico as the full CNI:

```bash
# Patch Installation to use Calico CNI instead of GKE policy-only mode
kubectl patch installation default --type=merge -p '{
  "spec": {
    "kubernetesProvider": "",
    "cni": {
      "type": "Calico",
      "ipam": {
        "type": "Calico"
      }
    },
    "calicoNetwork": {
      "bgp": "Disabled",
      "ipPools": [
        {
          "cidr": "192.168.0.0/16",
          "encapsulation": "VXLAN"
        }
      ]
    }
  }
}'
```

**Step 4: Fix Tigera Operator RBAC permissions**

On GKE, the Tigera Operator may lack permissions to create resourcequotas. Apply the following RBAC fix:

```bash
# Create ClusterRole for resourcequotas
kubectl create clusterrole tigera-resourcequota \
  --verb=create,get,list,update,delete,watch \
  --resource=resourcequotas

# Bind to tigera-operator service account
kubectl create clusterrolebinding tigera-resourcequota-binding \
  --clusterrole=tigera-resourcequota \
  --serviceaccount=tigera-operator:tigera-operator

# Restart the operator to trigger reconciliation
kubectl rollout restart deployment tigera-operator -n tigera-operator
```

**Step 5: Verify Installation**

Wait for `calico-node` DaemonSet to be running on all nodes:

```bash
kubectl get daemonset calico-node -n calico-system
```

All nodes should show as `READY` before proceeding with the secure-enclave chart installation. You can also verify the Installation status:

```bash
kubectl get installation default -o jsonpath='{.status.conditions}' | jq
```

The `Degraded` condition should be `False` and `Ready` should be `True`.

For more details, refer to the [official Calico documentation](https://docs.tigera.io/calico/latest/getting-started/kubernetes/helm).

### Install Chart
To install the chart, run:
``` bash
helm repo add secure-enclave https://safeinsights.github.io/helm-charts
helm repo update
helm install secure-enclave secure-enclave/secure-enclave --values custom-values.yaml
```

The basic configuration for the custom-values.yaml is:
``` yaml
managementApp:
  memberId: Your member Id. This value is required.
```

## Pre Deployment Requirements
Before deploying the helm chart, we first need to have credentials from the [image repository](https://harbor.safeinsights.org/)

### Key Pair generation
The key pair generation is done during the deployment. To once the deployment is finished you can retrieve the public key by running the following command. 
```
kubectl get secret enclave-secret -n $namespace -o json | jq -r '.data."management-app-public-key"' | base64 -d
```
The key/pair is only generated during the first installation and needs to be updated in the Management APP. If the namespace has been deleted or the chart has been deployed to a new namespace, then the public key needs to be retrieved and updated in the Management App. 

Once we create the robot-account credentials in the [image repository](https://harbor.safeinsights.org/), we will need to login from the environment and create a secret with the docker authentication. 

The credentials should be a json similar to this (eg: credentials.json). 
``` json
{
    "name": "username",
    "secret": "password",
    "serveraddress": "https://harbor.safeinsights.org"
}
```
We then run the following [script](./tools/harbor-login). 
`NAMESPACE=$namespace ./tools/harbor-login credentials.json` 
This will create a secret with the `si-docker-config` secret in the specified namespace. 

## Configuration

The following parameters can be configured using a `values.yaml` file. For more details on the configuration, refers to the comments [here](./secure-enclave/values.yaml)

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| managementApp.endpoint | string | `"https://app.safeinsights.org"` | Sets the endpoint where the management app is available. |
| managementApp.memberId | string | `nil` | Sets the id of the member deploying the enclave |
| networkPolicy.enabled | bool | `true` | networkPolicy.enabled this enables or  disables the network policy |
| setupApp.command | list | `["npx","tsx","src/scripts/poll.ts"]` | Sets the command to start the setup app container |
| setupApp.enabled | bool | `true` | Sets if the setup app should be deployed |
| setupApp.environmentVariables.harborPullSecret | string | `"si-docker-config"` | setupApp.environmentVariables.harborPullSecret this configures the pull secret from harbor |
| setupApp.environmentVariables.pollIntervall | string | `"60000"` | setupApp.environmentVariables.pollIntervall this overrides the setup app polling interval |
| setupApp.image.pullPolicy | string | `"Always"` | Sets the image pull policy |
| setupApp.image.registry | string | `"harbor.safeinsights.org/safeinsights-public"` | Sets the image registry |
| setupApp.image.repository | string | `"setup-app"` | Sets the image repository |
| setupApp.image.tag | string | `"20251006-e1ccae88"` | Sets the image tag |
| setupApp.name | string | `"setup-app"` | Sets the name of the deployment and containers for the setup app |
| setupApp.persistence.accessModes | list | `["ReadWriteOnce"]` | Sets the access modes used for the persitence |
| setupApp.persistence.enabled | bool | `false` | Sets if the persistence should be enabled during the deployment |
| setupApp.persistence.pvcSize | string | `"1Gi"` | Sets the size set for the the persitence |
| setupApp.persistence.storageClassName | string | `"aws-ebs-sc"` | Sets the storageClassName used for the persitence |
| setupApp.service.port | int | `5051` | Sets the service external port |
| setupApp.service.protocol | string | `"TCP"` | Sets the service protocol |
| setupApp.service.targetPort | int | `5051` | Sets the container internal port that the service redirects to. |
| setupApp.service.type | string | `"ClusterIP"` | Sets the service type |
| setupApp.workingDir | string | `"/home/node/code"` | Sets the working directory inside the setup app container |
| trustedOutputApp.command | list | `["npm","run","start"]` | Sets the command to start the trusted output app container |
| trustedOutputApp.enabled | bool | `true` | Sets if the trusted output app should be deployed |
| trustedOutputApp.image.pullPolicy | string | `"Always"` | Sets the image pull policy |
| trustedOutputApp.image.registry | string | `"harbor.safeinsights.org/safeinsights-public"` | Sets the image registry |
| trustedOutputApp.image.repository | string | `"trusted-output-app"` | Sets the image repository |
| trustedOutputApp.image.tag | string | `"20250728-a5d087fc"` | Sets the image tag |
| trustedOutputApp.name | string | `"toa"` | Sets the name of the deployment and containers for the trusted output app |
| trustedOutputApp.persistence.accessModes | list | `["ReadWriteOnce"]` | Sets the access modes used for the persitence |
| trustedOutputApp.persistence.enabled | bool | `false` | Sets if the persistence should be enabled during the deployment |
| trustedOutputApp.persistence.pvcSize | string | `"1Gi"` | Sets the size set for the the persitence |
| trustedOutputApp.persistence.storageClassName | string | `"aws-ebs"` | Sets the storageClassName used for the persitence |
| trustedOutputApp.service.port | int | `5050` | Sets the service external port |
| trustedOutputApp.service.protocol | string | `"TCP"` | Sets the service protocol |
| trustedOutputApp.service.targetPort | int | `3002` | Sets the container internal port that the service redirects to. |
| trustedOutputApp.service.type | string | `"ClusterIP"` | Sets the service type |
| trustedOutputApp.workingDir | string | `"/home/node/app"` | Sets the working directory inside the setup app container |

----------------------------------------------

### Deployment Configuration
All the deployment configurations are available in [values.yaml](secure-enclave/values.yaml) and each property is documented. 

## Uninstallation

To uninstall the chart, please run:
```bash
helm uninstall secure-enclave -n $namespace
```

The uninstallation will keep the secret that was generated during the deployment.

### Development
First we need to build the helm dependencies by running `helm dependency build ./secure-enclave` 
