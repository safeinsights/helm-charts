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
helm repo add secure-enclave https://github.com/safeinsights/helm-charts
helm repo update
helm install secure-enclave secure-enclave/secure-enclave
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

The following parameters can be configured using a `values.yaml` file or via command line:

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
