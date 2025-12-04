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

The following parameters can be configured using a `values.yaml` file.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| aws | object | `{"enabled":false,"storageClass":{"allowedTopologies":[{"matchLabelExpressions":[{"key":"topology.ebs.csi.aws.com/zone","values":["us-east-1"]}]}],"name":"aws-ebs-sc","parameters":{"csi.storage.k8s.io/fstype":"xfs","encrypted":"true","iopsPerGB":"50","type":"io1"},"provisioner":"ebs.csi.aws.com","volumeBindingMode":"WaitForFirstConsumer"}}` | This defines the values configured when deployed on AWS. |
| aws.enabled | bool | `false` | Sets if AWS configurations are enabled. |
| aws.storageClass | object | `{"allowedTopologies":[{"matchLabelExpressions":[{"key":"topology.ebs.csi.aws.com/zone","values":["us-east-1"]}]}],"name":"aws-ebs-sc","parameters":{"csi.storage.k8s.io/fstype":"xfs","encrypted":"true","iopsPerGB":"50","type":"io1"},"provisioner":"ebs.csi.aws.com","volumeBindingMode":"WaitForFirstConsumer"}` | Sets the storage class used for the deployment |
| aws.storageClass.name | string | `"aws-ebs-sc"` | Sets the name of the storage class |
| aws.storageClass.parameters | object | `{"csi.storage.k8s.io/fstype":"xfs","encrypted":"true","iopsPerGB":"50","type":"io1"}` | Sets the storage class parameters |
| aws.storageClass.parameters."csi.storage.k8s.io/fstype" | string | `"xfs"` | Sets the filesystem type for the storage class |
| aws.storageClass.parameters.encrypted | string | `"true"` | Sets if the storage is encrypted |
| aws.storageClass.parameters.iopsPerGB | string | `"50"` | Sets the IOPS per GB for the storage |
| aws.storageClass.parameters.type | string | `"io1"` | Sets the type of the storage class |
| aws.storageClass.provisioner | string | `"ebs.csi.aws.com"` | Sets the storage class provisioner |
| aws.storageClass.volumeBindingMode | string | `"WaitForFirstConsumer"` | Sets the storage class volume binding mode |
| fullnameOverride | string | `""` |  |
| managementApp | object | `{"endpoint":"https://app.safeinsights.org","memberId":null}` | Sets all the configurations related to the management app |
| managementApp.endpoint | string | `"https://app.safeinsights.org"` | Sets the endpoint where the management app is available. |
| managementApp.memberId | string | `nil` | Sets the id of the member deploying the enclave |
| nameOverride | string | `""` |  |
| networkPolicy | object | `{"enabled":true,"installCalico":false,"logging":true}` | Sets if the network policy restrictions are enforced. |
| networkPolicy.enabled | bool | `true` | networkPolicy.enabled this enables or  disables the network policy |
| networkPolicy.installCalico | bool | `false` | networkPolicy.installCalico this enables or disables automatic installation of Calico |
| nodeSelector | object | `{}` |  |
| podAffinity | object | `{}` |  |
| podAnnotations | object | `{}` | This is for setting Kubernetes Annotations to a Pod. For more information checkout: https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/ |
| podLabels | object | `{}` | This is for setting Kubernetes Labels to a Pod. For more information checkout: https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/ |
| podSecurityContext | object | `{}` |  |
| researchContainer | object | `{"name":"research"}` | Sets the research container app configuration # |
| researchContainer.name | string | `"research"` | Sets the name of the jobs and containers for the research |
| resources.limits.cpu | string | `"100m"` |  |
| resources.limits.memory | string | `"128Mi"` |  |
| resources.requests.cpu | string | `"100m"` |  |
| resources.requests.memory | string | `"128Mi"` |  |
| setupApp | object | `{"command":["npx","tsx","src/scripts/poll.ts"],"enabled":true,"environmentVariables":{"harborPullSecret":"si-docker-config","pollIntervall":"60000"},"image":{"pullPolicy":"Always","registry":"harbor.safeinsights.org/safeinsights-public","repository":"setup-app","tag":"20251006-e1ccae88"},"name":"setup-app","persistence":{"accessModes":["ReadWriteOnce"],"enabled":false,"pvcSize":"1Gi","storageClassName":"aws-ebs-sc"},"service":{"port":5051,"protocol":"TCP","targetPort":5051,"type":"ClusterIP"},"serviceAccount":{"annotations":{"kubernetes.io/enforce-mountable-secrets":"true"}},"workingDir":"/home/node/code"}` | Sets the setup app configuration |
| setupApp.command | list | `["npx","tsx","src/scripts/poll.ts"]` | Sets the command to start the setup app container |
| setupApp.enabled | bool | `true` | Sets if the setup app should be deployed |
| setupApp.environmentVariables | object | `{"harborPullSecret":"si-docker-config","pollIntervall":"60000"}` | Sets the setup app environment variables |
| setupApp.environmentVariables.harborPullSecret | string | `"si-docker-config"` | setupApp.environmentVariables.harborPullSecret this configures the pull secret from harbor |
| setupApp.environmentVariables.pollIntervall | string | `"60000"` | setupApp.environmentVariables.pollIntervall this overrides the setup app polling interval |
| setupApp.image | object | `{"pullPolicy":"Always","registry":"harbor.safeinsights.org/safeinsights-public","repository":"setup-app","tag":"20251006-e1ccae88"}` | Sets the image configuration for the setup app |
| setupApp.image.pullPolicy | string | `"Always"` | Sets the image pull policy |
| setupApp.image.registry | string | `"harbor.safeinsights.org/safeinsights-public"` | Sets the image registry |
| setupApp.image.repository | string | `"setup-app"` | Sets the image repository |
| setupApp.image.tag | string | `"20251006-e1ccae88"` | Sets the image tag |
| setupApp.name | string | `"setup-app"` | Sets the name of the deployment and containers for the setup app |
| setupApp.persistence | object | `{"accessModes":["ReadWriteOnce"],"enabled":false,"pvcSize":"1Gi","storageClassName":"aws-ebs-sc"}` | Sets the persistence configuration for the setup app. |
| setupApp.persistence.accessModes | list | `["ReadWriteOnce"]` | Sets the access modes used for the persitence |
| setupApp.persistence.enabled | bool | `false` | Sets if the persistence should be enabled during the deployment |
| setupApp.persistence.pvcSize | string | `"1Gi"` | Sets the size set for the the persitence |
| setupApp.persistence.storageClassName | string | `"aws-ebs-sc"` | Sets the storageClassName used for the persitence |
| setupApp.service | object | `{"port":5051,"protocol":"TCP","targetPort":5051,"type":"ClusterIP"}` | Sets the service on which the setup App will be accessible |
| setupApp.service.port | int | `5051` | Sets the service external port |
| setupApp.service.protocol | string | `"TCP"` | Sets the service protocol |
| setupApp.service.targetPort | int | `5051` | Sets the container internal port that the service redirects to. |
| setupApp.service.type | string | `"ClusterIP"` | Sets the service type |
| setupApp.serviceAccount | object | `{"annotations":{"kubernetes.io/enforce-mountable-secrets":"true"}}` | Sets the service account used by setup account to manage the research container and also access the Kubernetes API |
| setupApp.workingDir | string | `"/home/node/code"` | Sets the working directory inside the setup app container |
| trustedOutputApp | object | `{"command":["npm","run","start"],"enabled":true,"image":{"pullPolicy":"Always","registry":"harbor.safeinsights.org/safeinsights-public","repository":"trusted-output-app","tag":"20250728-a5d087fc"},"name":"toa","persistence":{"accessModes":["ReadWriteOnce"],"enabled":false,"pvcSize":"1Gi","storageClassName":"aws-ebs"},"service":{"port":5050,"protocol":"TCP","targetPort":3002,"type":"ClusterIP"},"workingDir":"/home/node/app"}` | Sets the trusted output app configuration |
| trustedOutputApp.command | list | `["npm","run","start"]` | Sets the command to start the trusted output app container |
| trustedOutputApp.enabled | bool | `true` | Sets if the trusted output app should be deployed |
| trustedOutputApp.image | object | `{"pullPolicy":"Always","registry":"harbor.safeinsights.org/safeinsights-public","repository":"trusted-output-app","tag":"20250728-a5d087fc"}` | Sets the image configuration for the trusted output app |
| trustedOutputApp.image.pullPolicy | string | `"Always"` | Sets the image pull policy |
| trustedOutputApp.image.registry | string | `"harbor.safeinsights.org/safeinsights-public"` | Sets the image registry |
| trustedOutputApp.image.repository | string | `"trusted-output-app"` | Sets the image repository |
| trustedOutputApp.image.tag | string | `"20250728-a5d087fc"` | Sets the image tag |
| trustedOutputApp.name | string | `"toa"` | Sets the name of the deployment and containers for the trusted output app |
| trustedOutputApp.persistence | object | `{"accessModes":["ReadWriteOnce"],"enabled":false,"pvcSize":"1Gi","storageClassName":"aws-ebs"}` | Sets the persistence configuration for the trusted output app. |
| trustedOutputApp.persistence.accessModes | list | `["ReadWriteOnce"]` | Sets the access modes used for the persitence |
| trustedOutputApp.persistence.enabled | bool | `false` | Sets if the persistence should be enabled during the deployment |
| trustedOutputApp.persistence.pvcSize | string | `"1Gi"` | Sets the size set for the the persitence |
| trustedOutputApp.persistence.storageClassName | string | `"aws-ebs"` | Sets the storageClassName used for the persitence |
| trustedOutputApp.service | object | `{"port":5050,"protocol":"TCP","targetPort":3002,"type":"ClusterIP"}` | Sets the service on which the trusted output App will be accessible |
| trustedOutputApp.service.port | int | `5050` | Sets the service external port |
| trustedOutputApp.service.protocol | string | `"TCP"` | Sets the service protocol |
| trustedOutputApp.service.targetPort | int | `3002` | Sets the container internal port that the service redirects to. |
| trustedOutputApp.service.type | string | `"ClusterIP"` | Sets the service type |
| trustedOutputApp.workingDir | string | `"/home/node/app"` | Sets the working directory inside the setup app container |

----------------------------------------------

### General Parameters
- **`resources.limits.cpu/memory`**: CPU and memory limits (defaults: 100m/128Mi)
- **`resources.requests.cpu/memory`**: CPU and memory requests (defaults: 100m/128Mi)

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
