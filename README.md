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
| networkPolicy.installCalico | bool | `false` | networkPolicy.installCalico this enables or disables automatic installation of Calico |
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
