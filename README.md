# Secure Enclave Charts

This repository contains Kubernetes charts for deploying two main components: 
- Setup App
- Trusted Output App

## Introduction

This repository provides Kubernetes manifests and Helm charts for deploying two key components:
1. **Setup App**: The setup app is the part of the enclave that polls the Management App for new avalaible research studies to run in the enclave. Once some studies become available, The setup app pull the container image, and start the research container with the variable environments needed to communicate with the Trusted Output App.  
There is some documentation on the Setup App architecture and how it runs in different enclave environments (AWS. KUBERNETES, DOCKER) available [here](https://github.com/safeinsights/setup-app#enclave-environments)

1. **Trusted Output Application**: The Trusted Output App is used to validate the results sent by the research container before they are sent to the Management App.****

## Installation

### Prerequisites
- Kubernetes cluster with proper authentication/authorization configured.
- `Helm` installed on your system.

### Install Chart
To install the chart, run:
```bash
helm repo add secure-enclave https://safeinsights.github.io/helm-charts
helm repo update
helm install secure-enclave secure-enclave/secure-enclave --values custom-values.yaml
```

## Pre Requirements
Before deploying the helm chart, we first need to have a private/public key pair as well as credentials for the [image repository](https://harbor.safeinsights.org/)

### Key Pair generation
To generate the key pair, we can run: 
```
openssl genrsa -out privatekey.pem 4096 # This will generate the private key
openssl rsa -in privatekey.pem -pubout > publickey.pub # This will generate the public key. 

```
The content of the public key need to be added in the [Management app](https://app.safeinsights.org/). 
We then need to create a secret in the namespace we  will deploy the helm. 
`kubectl create secret generic management-app-secret --from-file=private-key=./privatekey.pem -n $namespace`


Once we create the robot-account credentials in the [image repository](https://harbor.safeinsights.org/), we will need to login from the environment and create a secret with the docker authentication. 

The credentials should be a json similar to this (eg: credentials.json). 
``` json
{
    "username": "username",
    "password": "password",
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
| affinity | object | `{"nodeAffinity":{"requiredDuringSchedulingIgnoredDuringExecution":{"nodeSelectorTerms":[{"matchExpressions":[{"key":"karpenter.sh/nodepool","operator":"DoesNotExist"}]}]}},"podAntiAffinity":{"requiredDuringSchedulingIgnoredDuringExecution":[{"topologyKey":"kubernetes.io/hostname"}]}}` | Affinity rules for scheduling the pod. If an explicit label selector is not provided for pod affinity or pod anti-affinity one will be created from the pod selector labels. |
| autoscaling.enabled | bool | `false` |  |
| autoscaling.maxReplicas | int | `100` |  |
| autoscaling.minReplicas | int | `1` |  |
| autoscaling.targetCPUUtilizationPercentage | int | `80` |  |
| aws.enabled | bool | `false` |  |
| aws.storageClass.allowedTopologies[0].matchLabelExpressions[0].key | string | `"topology.ebs.csi.aws.com/zone"` |  |
| aws.storageClass.allowedTopologies[0].matchLabelExpressions[0].values[0] | string | `"us-east-1"` |  |
| aws.storageClass.name | string | `"aws-ebs-sc"` |  |
| aws.storageClass.parameters."csi.storage.k8s.io/fstype" | string | `"xfs"` |  |
| aws.storageClass.parameters.encrypted | string | `"true"` |  |
| aws.storageClass.parameters.iopsPerGB | string | `"50"` |  |
| aws.storageClass.parameters.type | string | `"io1"` |  |
| aws.storageClass.provisioner | string | `"ebs.csi.aws.com"` |  |
| aws.storageClass.volumeBindingMode | string | `"WaitForFirstConsumer"` |  |
| fullnameOverride | string | `""` |  |
| ingress.annotations | object | `{}` |  |
| ingress.className | string | `""` |  |
| ingress.enabled | bool | `false` |  |
| ingress.hosts[0].host | string | `"chart-example.local"` |  |
| ingress.hosts[0].paths[0].path | string | `"/"` |  |
| ingress.hosts[0].paths[0].pathType | string | `"ImplementationSpecific"` |  |
| ingress.tls | list | `[]` |  |
| livenessProbe.httpGet.path | string | `"/"` |  |
| livenessProbe.httpGet.port | string | `"http"` |  |
| managementApp.endpoint.host | string | `"app.safeinsights.org"` |  |
| managementApp.endpoint.port | int | `443` |  |
| managementApp.endpoint.protocol | string | `"https"` |  |
| managementApp.memberId | string | `nil` |  |
| managementApp.privateKey.key | string | `"private-key"` |  |
| managementApp.privateKey.secretName | string | `"management-app-secret"` |  |
| nameOverride | string | `""` |  |
| networkPolicy.enabled | bool | `false` |  |
| nodeSelector | object | `{}` |  |
| podAnnotations | object | `{}` |  |
| podLabels | object | `{}` |  |
| podSecurityContext | object | `{}` |  |
| readinessProbe.httpGet.path | string | `"/"` |  |
| readinessProbe.httpGet.port | string | `"http"` |  |
| researchContainer.name | string | `"research"` |  |
| resources.limits.cpu | string | `"100m"` |  |
| resources.limits.memory | string | `"128Mi"` |  |
| resources.requests.cpu | string | `"100m"` |  |
| resources.requests.memory | string | `"128Mi"` |  |
| securityContext | object | `{}` |  |
| setupApp.command[0] | string | `"npx"` |  |
| setupApp.command[1] | string | `"tsx"` |  |
| setupApp.command[2] | string | `"src/scripts/poll.ts"` |  |
| setupApp.enabled | bool | `true` |  |
| setupApp.environmentVariables.harborPullSecret | string | `"si-docker-config"` |  |
| setupApp.environmentVariables.k8sApiServer | string | `"https://kubernetes.default.svc.cluster.local"` |  |
| setupApp.environmentVariables.k8sServiceAccountPath | string | `"/var/run/secrets/kubernetes.io/serviceaccount"` |  |
| setupApp.environmentVariables.pollIntervall | string | `"60000"` |  |
| setupApp.environmentVariables.toaApiIUrl | string | `"http://toa-svc:5050"` |  |
| setupApp.image.pullPolicy | string | `"Always"` |  |
| setupApp.image.registry | string | `"harbor.safeinsights.org/safeinsights-public"` |  |
| setupApp.image.repository | string | `"setup-app"` |  |
| setupApp.image.tag | string | `"20250828-5a509a54"` |  |
| setupApp.name | string | `"setup-app"` |  |
| setupApp.persistence.accessModes[0] | string | `"ReadWriteOnce"` |  |
| setupApp.persistence.enabled | bool | `false` |  |
| setupApp.persistence.pvcSize | string | `"1Gi"` |  |
| setupApp.persistence.storageClassName | string | `"aws-ebs-sc"` |  |
| setupApp.service.port | int | `5051` |  |
| setupApp.service.protocol | string | `"TCP"` |  |
| setupApp.service.targetPort | int | `5051` |  |
| setupApp.service.type | string | `"ClusterIP"` |  |
| setupApp.serviceAccount.annotations."kubernetes.io/enforce-mountable-secrets" | string | `"true"` |  |
| setupApp.workingDir | string | `"/home/node/code"` |  |
| tolerations | list | `[{"key":"CriticalAddonsOnly","operator":"Exists"}]` | Tolerations to allow the pod to be scheduled to nodes with taints. |
| topologySpreadConstraints | list | `[{"maxSkew":1,"topologyKey":"topology.kubernetes.io/zone","whenUnsatisfiable":"DoNotSchedule"}]` | Topology spread constraints to increase the controller resilience by distributing pods across the cluster zones. If an explicit label selector is not provided one will be created from the pod selector labels. |
| trustedOutputApp.command[0] | string | `"npm"` |  |
| trustedOutputApp.command[1] | string | `"run"` |  |
| trustedOutputApp.command[2] | string | `"start"` |  |
| trustedOutputApp.enabled | bool | `true` |  |
| trustedOutputApp.environmentVariables.httpBasicAuth | string | `"admin:admin"` |  |
| trustedOutputApp.image.pullPolicy | string | `"Always"` |  |
| trustedOutputApp.image.registry | string | `"harbor.safeinsights.org/safeinsights-public"` |  |
| trustedOutputApp.image.repository | string | `"trusted-output-app"` |  |
| trustedOutputApp.image.tag | string | `"20250728-a5d087fc"` |  |
| trustedOutputApp.name | string | `"toa"` |  |
| trustedOutputApp.persistence.accessModes[0] | string | `"ReadWriteOnce"` |  |
| trustedOutputApp.persistence.enabled | bool | `false` |  |
| trustedOutputApp.persistence.pvcSize | string | `"1Gi"` |  |
| trustedOutputApp.persistence.storageClassName | string | `"aws-ebs"` |  |
| trustedOutputApp.service.port | int | `5050` |  |
| trustedOutputApp.service.protocol | string | `"TCP"` |  |
| trustedOutputApp.service.targetPort | int | `3002` |  |
| trustedOutputApp.service.type | string | `"ClusterIP"` |  |
| trustedOutputApp.workingDir | string | `"/home/node/app"` |  |
| volumeMounts | list | `[]` |  |
| volumes | list | `[]` |  |

----------------------------------------------

### General Parameters
- **`resources.limits.cpu/memory`**: CPU and memory limits (defaults: 100m/128Mi)
- **`resources.requests.cpu/memory`**: CPU and memory requests (defaults: 100m/128Mi)

### Deployment Configuration
All the deployment configurations are available in [values.yaml](secure-enclave/values.yaml) and each property is documented. 

## Uninstallation

To uninstall the chart, please run:
```bash
helm uninstall secure-enclave
```

## Notes

1. Ensure your Kubernetes cluster has sufficient resources.
2. All sensitive values should be stored in Kubernetes secrets.
3. Proper networking and security policies should be implemented.
4. For production use, please consider enabling TLS for ingress.
