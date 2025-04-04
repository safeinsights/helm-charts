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

## Configuration

The following parameters can be configured using a `values.yaml` file or via command line:

### General Parameters
- **`resources.limits.cpu/memory`**: CPU and memory limits (defaults: 100m/128Mi)
- **`resources.requests.cpu/memory`**: CPU and memory requests (defaults: 100m/128Mi)

### Setup Application Configuration
```yaml
setupApp:
  enabled: true
  name: "setup-app"
  image:
    repository: "setup-image"
    registry: "docker.io"
    tag: "latest"
  service:
    ports:
      - port: 5051
        targetPort: 5051
```

### Trusted Output Application Configuration
```yaml
trustedOutputApp:
  enabled: true
  name: "trusted-output"
  image:
    repository: "output-image"
    registry: "docker.io"
    tag: "latest"
  service:
    ports:
      - port: 5050
        targetPort: 3002
```

### Environment Variables
- **Setup App**:
  ```yaml
  setupApp.environmentVariables:
    k8sApiServer: The Kubernetes API endpoint.
    k8sServiceAccountPath: The service account path in the container.
    mgmtAppMemberId: The id of the member deploying this enclave
    mgmtAppApiUrl: The URL where the Management App is deployed
    toaApiIUrl: The URL where the Trusted Output App is deployed
    toaBasicAuth: The Basic authentication that will be used to authenticate with the Trusted Output App.
    pollIntervall: The poll intervall to pull jobs from the basic management app. 
    mgmtPrivateKey: The private key of the member that is use to sign REST calls made to the management app.
  ```
  
- **Trusted Output App**:
  ```yaml
  trustedOutputApp.environmentVariables:
    httpBasicAuth: The Basic authentication that will be used to authenticate with the Trusted Output App.
    mgmtAppMemberId: The id of the member deploying this enclave
    mgmtAppApiUrl: The URL where the Management App is deployed
    mgmtPrivateKey: The private key of the member that is use to sign REST calls made to the management app.

## Security Context

Pod security context can be configured using:
```yaml
securityContext:
  runAsUser: 1000
  fsGroup: 1000
```

## Resources

Resource limits and requests can be customized as follows:
```yaml
resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi
```

## Liveness and Readiness Probes

Probes are configured by default to check HTTP endpoints on port `http`:
```yaml
livenessProbe:
  httpGet:
    path: /
    port: http

readinessProbe:
  httpGet:
    path: /
    port: http
```

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
