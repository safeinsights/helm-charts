# Secure Enclave Helm Chart - Values Documentation

## Table of Contents
1. [Chart Metadata](#chart-metadata)
2. [AWS Configuration](#aws-configuration)
3. [Network Policy Configuration](#network-policy-configuration)
4. [Calico Network Policy](#calico-network-policy)
5. [Harbor Configuration](#harbor-configuration)
6. [Monitoring](#monitoring)
7. [Management App Configuration](#management-app-configuration)
8. [Setup App Configuration](#setup-app-configuration)
9. [Trusted Output App Configuration](#trusted-output-app-configuration)
10. [Research Container Configuration](#research-container-configuration)
11. [Global Defaults](#global-defaults)
12. [Horizontal Pod Autoscaler (HPA)](#horizontal-pod-autoscaler-hpa)
13. [Namespace Configuration](#namespace-configuration)
14. [Research Network Egress](#research-network-egress)
15. [External Secrets Configuration](#external-secrets-configuration)
16. [Internal Auth Configuration](#internal-auth-configuration)
17. [Audit Configuration](#audit-configuration)
18. [Kubernetes Core Services](#kubernetes-core-services)
19. [CNI Configuration](#cni-configuration)
20. [Infrastructure Components](#infrastructure-components)
21. [Node Ports](#node-ports)
22. [AWS Special Addresses](#aws-special-addresses)
23. [NAT Gateway](#nat-gateway)

---

## Chart Metadata

### `nameOverride`
- **Type:** String
- **Default:** `''`
- **Purpose:** Override the default chart name in resource names

### `fullnameOverride`
- **Type:** String
- **Default:** `''`
- **Purpose:** Override the full resource name completely

---

## AWS Configuration

### `aws.enabled`
- **Type:** Boolean
- **Default:** `true`
- **Purpose:** Enable AWS EBS StorageClass creation

### `aws.storageClass`
Storage class configuration for AWS EBS volumes

#### `aws.storageClass.name`
- **Type:** String
- **Default:** `aws-ebs-sc`
- **Purpose:** Name of the StorageClass

#### `aws.storageClass.provisioner`
- **Type:** String
- **Default:** `ebs.csi.aws.com`
- **Purpose:** CSI driver for EBS volume provisioning

#### `aws.storageClass.volumeBindingMode`
- **Type:** String
- **Default:** `WaitForFirstConsumer`
- **Purpose:** Delay volume binding until pod is scheduled

#### `aws.storageClass.allowVolumeExpansion`
- **Type:** Boolean
- **Default:** `true`
- **Purpose:** Allow PVC size increases after creation

#### `aws.storageClass.reclaimPolicy`
- **Type:** String
- **Default:** `Retain`
- **Purpose:** Keep volumes after PVC deletion

#### `aws.storageClass.storageclass.kubernetes.io/is-default-class`
- **Type:** String
- **Default:** `"true"`
- **Purpose:** Mark as cluster default StorageClass

#### `aws.storageClass.parameters`
EBS volume parameters

- **`type`**: `gp3` - General Purpose SSD v3
- **`encrypted`**: `"true"` - Enable encryption at rest
- **`csi.storage.k8s.io/fstype`**: `xfs` - Filesystem type

#### `aws.storageClass.allowedTopologies`
- **Type:** Array (commented)
- **Purpose:** Restrict volumes to specific AZs

---

## Network Policy Configuration

### `networkPolicy.enabled`
- **Type:** Boolean
- **Default:** `true`
- **Purpose:** Enable Kubernetes NetworkPolicy enforcement

---

## Calico Network Policy

### `calicoNetworkPolicy.useEnhanced`
- **Type:** Boolean
- **Default:** `true`
- **Purpose:** Enable enhanced Calico policy features

### `calicoNetworkPolicy.logging`
Compliance and audit trail configuration

#### `calicoNetworkPolicy.logging.enableDnsLogging`
- **Type:** Boolean
- **Default:** `false`
- **Purpose:** Log DNS queries (high volume)

#### `calicoNetworkPolicy.logging.enableResearchEgress`
- **Type:** Boolean
- **Default:** `true`
- **Purpose:** Audit research pod data access

#### `calicoNetworkPolicy.logging.enableManagementApiCalls`
- **Type:** Boolean
- **Default:** `true`
- **Purpose:** Compliance logging for management API calls

#### `calicoNetworkPolicy.logging.enableToaTraffic`
- **Type:** Boolean
- **Default:** `true`
- **Purpose:** Audit result submission traffic

#### `calicoNetworkPolicy.logging.logLevel`
- **Type:** String
- **Default:** `"info"`
- **Options:** `debug`, `info`, `warn`, `error`
- **Purpose:** Global log verbosity level

#### `calicoNetworkPolicy.logging.logRetentionDays`
- **Type:** Integer
- **Default:** `90`
- **Purpose:** Days to retain logs (handled by Calico/Fluentd)

#### `calicoNetworkPolicy.logging.logFormat`
- **Type:** String
- **Default:** `"json"`
- **Options:** `json`, `text`
- **Purpose:** Log output format

#### `calicoNetworkPolicy.logging.logDestination`
- **Type:** String
- **Default:** `"syslog"`
- **Options:** `syslog`, `file`, `stdout`
- **Purpose:** Where logs are sent

### `calicoNetworkPolicy.policyOrder`
Explicit evaluation order for policies

- **`globalDns`**: `1` - Global DNS (highest priority)
- **`defaultDeny`**: `10` - Default deny all
- **`research`**: `20` - Research pod egress
- **`setupApp`**: `25` - Setup app ingress/egress
- **`trustedOutputApp`**: `30` - TOA ingress/egress
- **`testConnection`**: `40` - Test pods (lowest priority)

---

## Harbor Configuration

### `harbor.externalSecret`
Harbor container registry credentials

#### `harbor.externalSecret.enabled`
- **Type:** Boolean
- **Default:** `true`
- **Purpose:** Pull Harbor credentials from AWS Secrets Manager

#### `harbor.externalSecret.awsSecretName`
- **Type:** String
- **Default:** `prod/harbor/research-robot-credentials`
- **Purpose:** AWS Secrets Manager path for Harbor credentials

#### `harbor.externalSecret.refreshInterval`
- **Type:** String
- **Default:** `1h`
- **Purpose:** How often to sync credentials from AWS

---

## Monitoring

### `monitoring.applicationNamespaces`
- **Type:** Array
- **Default:** `["enclave-admin-ns", "enclave-research-ns"]`
- **Purpose:** Namespaces to monitor for metrics collection

---

## Management App Configuration

External service (app.safeinsights.org) configuration

### `managementApp.endpoint`
External management service endpoint

#### `managementApp.endpoint.protocol`
- **Type:** String
- **Default:** `https`
- **Purpose:** Connection protocol

#### `managementApp.endpoint.host`
- **Type:** String
- **Default:** `app.safeinsights.org`
- **Purpose:** Management service hostname

#### `managementApp.endpoint.port`
- **Type:** Integer
- **Default:** `443`
- **Purpose:** Management service port

### `managementApp.externalSecret`
Credentials from AWS Secrets Manager

#### `managementApp.externalSecret.enabled`
- **Type:** Boolean
- **Default:** `true`
- **Purpose:** Enable external secret sync

#### `managementApp.externalSecret.secretName`
- **Type:** String
- **Default:** `management-app-secret`
- **Purpose:** Kubernetes secret name

#### `managementApp.externalSecret.awsSecretName`
- **Type:** String
- **Default:** `prod/management/app/creds`
- **Purpose:** AWS Secrets Manager path

#### `managementApp.externalSecret.refreshInterval`
- **Type:** String
- **Default:** `1h`
- **Purpose:** Secret refresh frequency

#### `managementApp.externalSecret.secretStoreRef`
Reference to ClusterSecretStore

- **`kind`**: `ClusterSecretStore`
- **`name`**: `aws-sm`

### `managementApp.privateKey`
Private key configuration

#### `managementApp.privateKey.enabled`
- **Type:** Boolean
- **Default:** `true`
- **Purpose:** Enable private key management

#### `managementApp.privateKey.awsSecretName`
- **Type:** String
- **Default:** `prod/management/app/creds`
- **Purpose:** AWS path for private key

#### `managementApp.privateKey.secretName`
- **Type:** String
- **Default:** `management-app-secret`
- **Purpose:** Kubernetes secret containing key

#### `managementApp.privateKey.refreshInterval`
- **Type:** String
- **Default:** `1h`
- **Purpose:** Key refresh frequency

### `managementApp.networkPolicy.egressCidrs`
Allowed egress IP ranges

- **Type:** Array
- **Purpose:** IP allowlist for management app and Harbor registry
- **Example:**
  - `3.160.22.0/24` - app.safeinsights.org
  - `44.207.122.80/32` - Harbor registry

---

## Setup App Configuration

### `setupApp.enabled`
- **Type:** Boolean
- **Default:** `true`
- **Purpose:** Deploy setup-app component

### `setupApp.name`
- **Type:** String
- **Default:** `setup-app`
- **Purpose:** Application name

### `setupApp.replicas`
- **Type:** Integer
- **Default:** `2`
- **Purpose:** Pod count when HPA disabled

### `setupApp.priorityClassName`
- **Type:** String
- **Default:** `enclave-high-priority`
- **Purpose:** Pod scheduling priority

### `setupApp.terminationGracePeriodSeconds`
- **Type:** Integer
- **Default:** `60`
- **Purpose:** Graceful shutdown time

### `setupApp.rbac`
RBAC permissions configuration

#### `setupApp.rbac.allowedSecretNames`
- **Type:** Array
- **Default:** `[]`
- **Purpose:** Specific secrets the app can read

#### `setupApp.rbac.allowJobCreate`
- **Type:** Boolean
- **Default:** `true`
- **Purpose:** Allow creating Job resources

#### `setupApp.rbac.allowJobDelete`
- **Type:** Boolean
- **Default:** `true`
- **Purpose:** Allow deleting Job resources

#### `setupApp.rbac.research`
Research namespace permissions

- **`allowPodExec`**: `false` - Execute commands in pods
- **`readLogs`**: `true` - Read pod logs
- **`watchEvents`**: `true` - Watch namespace events
- **`jobs`**: `true` - Manage research Jobs

### `setupApp.serviceAccount`
ServiceAccount configuration

#### `setupApp.serviceAccount.create`
- **Type:** Boolean
- **Default:** `true`
- **Purpose:** Create new ServiceAccount

#### `setupApp.serviceAccount.name`
- **Type:** String
- **Default:** `""`
- **Purpose:** SA name (defaults to `setup-app-sa`)

#### `setupApp.serviceAccount.secrets`
- **Type:** Array
- **Default:** `["management-app-secret", "internal-auth-credentials"]`
- **Purpose:** Secrets attached to ServiceAccount

#### `setupApp.serviceAccount.automountServiceAccountToken`
- **Type:** Boolean
- **Default:** `true`
- **Purpose:** Auto-mount SA token to pods

#### `setupApp.serviceAccount.annotations`
- **Type:** Object
- **Default:** `{}`
- **Purpose:** SA annotations (e.g., IRSA role ARN)

### `setupApp.persistence`
Persistent volume configuration

#### `setupApp.persistence.enabled`
- **Type:** Boolean
- **Default:** `false`
- **Purpose:** Enable persistent storage

#### `setupApp.persistence.create`
- **Type:** Boolean
- **Default:** `true`
- **Purpose:** Create new PVC

#### `setupApp.persistence.storageClassName`
- **Type:** String
- **Default:** `aws-ebs-sc`
- **Purpose:** StorageClass for PVC

#### `setupApp.persistence.accessModes`
- **Type:** Array
- **Default:** `["ReadWriteOnce"]`
- **Purpose:** Volume access mode (RWO for EBS)

#### `setupApp.persistence.pvcSize`
- **Type:** String
- **Default:** `20Gi`
- **Purpose:** Requested storage capacity

#### `setupApp.persistence.mountPath`
- **Type:** String
- **Default:** `/var/lib/setup-app`
- **Purpose:** Container mount path

#### `setupApp.persistence.volumeName`
- **Type:** String
- **Default:** `data`
- **Purpose:** Volume name in pod spec

#### `setupApp.persistence.annotations`
- **Type:** Object
- **Default:** `{}`
- **Purpose:** PVC annotations

### `setupApp.resources`
CPU, memory, and storage limits

#### `setupApp.resources.requests`
- **`cpu`**: `100m` - Minimum CPU
- **`memory`**: `256Mi` - Minimum memory
- **`ephemeral-storage`**: `512Mi` - Minimum ephemeral storage

#### `setupApp.resources.limits`
- **`cpu`**: `1000m` - Maximum CPU
- **`memory`**: `1Gi` - Maximum memory
- **`ephemeral-storage`**: `2Gi` - Maximum ephemeral storage

### `setupApp.service`
Kubernetes Service configuration

#### `setupApp.service.enabled`
- **Type:** Boolean
- **Default:** `true`
- **Purpose:** Create Service resource

#### `setupApp.service.type`
- **Type:** String
- **Default:** `ClusterIP`
- **Purpose:** Service type

#### `setupApp.service.protocol`
- **Type:** String
- **Default:** `TCP`
- **Purpose:** Network protocol

#### `setupApp.service.portName`
- **Type:** String
- **Default:** `http`
- **Purpose:** Named port

#### `setupApp.service.port`
- **Type:** Integer
- **Default:** `5051`
- **Purpose:** External service port

#### `setupApp.service.targetPort`
- **Type:** Integer
- **Default:** `5051`
- **Purpose:** Container port

#### `setupApp.service.annotations`
- **Type:** Object
- **Default:** `{}`
- **Purpose:** Service annotations

### `setupApp.pod.nodeSelector`
- **Type:** Object
- **Default:** `{"role": "workloads"}`
- **Purpose:** Schedule pods on specific nodes

### `setupApp.image`
Container image configuration

#### `setupApp.image.registry`
- **Type:** String
- **Default:** `harbor.safeinsights.org/safeinsights-public`
- **Purpose:** Container registry

#### `setupApp.image.repository`
- **Type:** String
- **Default:** `setup-app`
- **Purpose:** Image repository name

#### `setupApp.image.digest`
- **Type:** String
- **Default:** `sha256:2e3e5c74...`
- **Purpose:** Image digest for immutable deploys

#### `setupApp.image.tag`
- **Type:** String
- **Default:** `""`
- **Purpose:** Image tag (use digest instead)

#### `setupApp.image.pullPolicy`
- **Type:** String
- **Default:** `Always`
- **Purpose:** When to pull image

### `setupApp.imagePullSecrets`
- **Type:** Array
- **Default:** `["si-docker-config"]`
- **Purpose:** Secrets for private registry authentication

### `setupApp.secret`
App-specific secrets

#### `setupApp.secret.enabled`
- **Type:** Boolean
- **Default:** `false`
- **Purpose:** Enable secret creation

#### `setupApp.secret.name`
- **Type:** String
- **Default:** `internal-auth-credentials`
- **Purpose:** Secret name

### `setupApp.externalSecret`
AWS Secrets Manager integration

#### `setupApp.externalSecret.enabled`
- **Type:** Boolean
- **Default:** `false`
- **Purpose:** Sync from AWS Secrets Manager

#### `setupApp.externalSecret.secretStoreRef`
- **`kind`**: `ClusterSecretStore`
- **`name`**: `aws-sm`

#### `setupApp.externalSecret.awsSecretName`
- **Type:** String
- **Default:** `prod/enclave/internal-auth`
- **Purpose:** AWS path

#### `setupApp.externalSecret.targetSecretName`
- **Type:** String
- **Default:** `internal-auth-credentials`
- **Purpose:** K8s secret name

#### `setupApp.externalSecret.refreshInterval`
- **Type:** String
- **Default:** `1h`
- **Purpose:** Sync frequency

### `setupApp.config`
ConfigMap configuration

#### `setupApp.config.enabled`
- **Type:** Boolean
- **Default:** `true`
- **Purpose:** Create ConfigMap

#### `setupApp.config.name`
- **Type:** String
- **Default:** `setup-app-config`
- **Purpose:** ConfigMap name

#### `setupApp.config.data`
Environment variables

- **`DEPLOYMENT_ENVIRONMENT`**: `KUBERNETES` - Runtime environment
- **`K8S_APISERVER`**: K8s API endpoint
- **`K8S_SERVICEACCOUNT_PATH`**: SA token path
- **`TOA_BASE_URL`**: `http://toa-svc:5050` - TOA service URL
- **`POLL_STUDIES_INTERVAL_SECONDS`**: `"30"` - Study polling frequency
- **`POLL_ERRORED_JOBS_INTERVAL_SECONDS`**: `"60"` - Error check frequency
- **`HARBOR_PULL_SECRET`**: `si-docker-config` - Image pull secret

### `setupApp.pdb`
PodDisruptionBudget configuration

#### `setupApp.pdb.enabled`
- **Type:** Boolean
- **Default:** `true`
- **Purpose:** Create PDB

#### `setupApp.pdb.maxUnavailable`
- **Type:** Integer
- **Default:** `1`
- **Purpose:** Max pods down during disruptions

### `setupApp.toaAccessLabel`
TOA access label (DISABLED)

#### `setupApp.toaAccessLabel.enabled`
- **Type:** Boolean
- **Default:** `false`
- **Purpose:** Disabled to prevent duplicate role labels

#### `setupApp.toaAccessLabel.key`
- **Type:** String
- **Default:** `role`

#### `setupApp.toaAccessLabel.value`
- **Type:** String
- **Default:** `setup-app`

### `setupApp.podLabels`
Pod labels

- **`app.kubernetes.io/component`**: `setup-app` - Component identifier
- **`role`**: `setup-app` - Role label for network policies

### `setupApp.workingDir`
- **Type:** String
- **Default:** `/home/node/code`
- **Purpose:** Container working directory

### `setupApp.command`
- **Type:** Array
- **Default:** `["npx", "tsx", "src/scripts/poll.ts"]`
- **Purpose:** Container entrypoint command

### `setupApp.networkPolicy`
Network policy egress configuration

#### `setupApp.networkPolicy.allowK8sApiEgress`
- **Type:** Boolean
- **Default:** `true`
- **Purpose:** Allow access to K8s API server

#### `setupApp.networkPolicy.k8sApiCidr`
- **Type:** String
- **Default:** `10.52.0.0/16`
- **Purpose:** K8s API CIDR range

---

## Trusted Output App Configuration

### `trustedOutputApp.enabled`
- **Type:** Boolean
- **Default:** `true`
- **Purpose:** Deploy TOA component

### `trustedOutputApp.name`
- **Type:** String
- **Default:** `toa`
- **Purpose:** Application name

### `trustedOutputApp.replicas`
- **Type:** Integer
- **Default:** `1`
- **Purpose:** Pod count when HPA disabled

### `trustedOutputApp.hpa.enabled`
- **Type:** Boolean
- **Default:** `false`
- **Purpose:** Disable HPA for TOA (single replica)

### `trustedOutputApp.priorityClassName`
- **Type:** String
- **Default:** `system-cluster-critical`
- **Purpose:** Critical system priority

### `trustedOutputApp.terminationGracePeriodSeconds`
- **Type:** Integer
- **Default:** `60`
- **Purpose:** Graceful shutdown time

### `trustedOutputApp.serviceAccount`
ServiceAccount configuration

#### `trustedOutputApp.serviceAccount.create`
- **Type:** Boolean
- **Default:** `true`
- **Purpose:** Create ServiceAccount

#### `trustedOutputApp.serviceAccount.name`
- **Type:** String
- **Default:** `""`
- **Purpose:** SA name (defaults to `toa-sa`)

#### `trustedOutputApp.serviceAccount.secrets`
- **Type:** Array
- **Default:** `["management-app-secret", "internal-auth-credentials"]`
- **Purpose:** Attached secrets

#### `trustedOutputApp.serviceAccount.automountServiceAccountToken`
- **Type:** Boolean
- **Default:** `false`
- **Purpose:** Disable token auto-mount

#### `trustedOutputApp.serviceAccount.annotations`
- **Type:** Object
- **Default:** `{}`
- **Purpose:** SA annotations

### `trustedOutputApp.persistence`
Persistent volume configuration

#### `trustedOutputApp.persistence.enabled`
- **Type:** Boolean
- **Default:** `true`
- **Purpose:** Enable persistent storage

#### `trustedOutputApp.persistence.create`
- **Type:** Boolean
- **Default:** `true`
- **Purpose:** Create new PVC

#### `trustedOutputApp.persistence.storageClassName`
- **Type:** String
- **Default:** `aws-ebs-sc`
- **Purpose:** StorageClass

#### `trustedOutputApp.persistence.accessModes`
- **Type:** Array
- **Default:** `["ReadWriteOnce"]`
- **Purpose:** EBS access mode

#### `trustedOutputApp.persistence.pvcSize`
- **Type:** String
- **Default:** `10Gi`
- **Purpose:** Storage capacity

#### `trustedOutputApp.persistence.mountPath`
- **Type:** String
- **Default:** `/var/lib/trusted-output-app`
- **Purpose:** Mount path

#### `trustedOutputApp.persistence.volumeName`
- **Type:** String
- **Default:** `data`
- **Purpose:** Volume name

#### `trustedOutputApp.persistence.annotations`
- **Type:** Object
- **Default:** `{}`
- **Purpose:** PVC annotations

### `trustedOutputApp.resources`
Resource limits

#### `trustedOutputApp.resources.requests`
- **`cpu`**: `100m`
- **`memory`**: `256Mi`
- **`ephemeral-storage`**: `512Mi`

#### `trustedOutputApp.resources.limits`
- **`cpu`**: `1000m`
- **`memory`**: `1Gi`
- **`ephemeral-storage`**: `2Gi`

### `trustedOutputApp.service`
Service configuration

#### `trustedOutputApp.service.enabled`
- **Type:** Boolean
- **Default:** `true`
- **Purpose:** Create Service

#### `trustedOutputApp.service.type`
- **Type:** String
- **Default:** `ClusterIP`
- **Purpose:** Service type

#### `trustedOutputApp.service.protocol`
- **Type:** String
- **Default:** `TCP`
- **Purpose:** Network protocol

#### `trustedOutputApp.service.portName`
- **Type:** String
- **Default:** `http`
- **Purpose:** Named port

#### `trustedOutputApp.service.port`
- **Type:** Integer
- **Default:** `5050`
- **Purpose:** External port

#### `trustedOutputApp.service.targetPort`
- **Type:** Integer
- **Default:** `3002`
- **Purpose:** Container port

#### `trustedOutputApp.service.annotations`
- **Type:** Object
- **Default:** `{}`
- **Purpose:** Service annotations

### `trustedOutputApp.pod.nodeSelector`
- **Type:** Object
- **Default:** `{"role": "workloads"}`
- **Purpose:** Node selection

### `trustedOutputApp.image`
Container image

#### `trustedOutputApp.image.registry`
- **Type:** String
- **Default:** `harbor.safeinsights.org/safeinsights-public`
- **Purpose:** Registry

#### `trustedOutputApp.image.repository`
- **Type:** String
- **Default:** `trusted-output-app`
- **Purpose:** Repository

#### `trustedOutputApp.image.digest`
- **Type:** String
- **Default:** `sha256:59c4b637...`
- **Purpose:** Image digest

#### `trustedOutputApp.image.tag`
- **Type:** String
- **Default:** `""`
- **Purpose:** Image tag (use digest)

#### `trustedOutputApp.image.pullPolicy`
- **Type:** String
- **Default:** `Always`
- **Purpose:** Pull policy

### `trustedOutputApp.imagePullSecrets`
- **Type:** Array
- **Default:** `["si-docker-config"]`
- **Purpose:** Registry auth

### `trustedOutputApp.secret`
App secrets

#### `trustedOutputApp.secret.enabled`
- **Type:** Boolean
- **Default:** `true`
- **Purpose:** Enable secret

#### `trustedOutputApp.secret.name`
- **Type:** String
- **Default:** `trusted-output-app-secret`
- **Purpose:** Secret name

#### `trustedOutputApp.secret.data`
Secret keys mapping

- **`TOA_SIGNING_KEY`**: `signingKey` - Signing key for outputs
- **`TOA_BASIC_AUTH`**: `httpBasicAuth` - Basic auth credentials

### `trustedOutputApp.externalSecret`
AWS integration

#### `trustedOutputApp.externalSecret.enabled`
- **Type:** Boolean
- **Default:** `true`
- **Purpose:** Sync from AWS

#### `trustedOutputApp.externalSecret.awsSecretName`
- **Type:** String
- **Default:** `prod/trusted-output/keys`
- **Purpose:** AWS path

#### `trustedOutputApp.externalSecret.refreshInterval`
- **Type:** String
- **Default:** `1h`
- **Purpose:** Refresh frequency

#### `trustedOutputApp.externalSecret.secretStoreRef`
- **`kind`**: `ClusterSecretStore`
- **`name`**: `aws-sm`

### `trustedOutputApp.config`
ConfigMap

#### `trustedOutputApp.config.enabled`
- **Type:** Boolean
- **Default:** `true`
- **Purpose:** Create ConfigMap

#### `trustedOutputApp.config.name`
- **Type:** String
- **Default:** `trusted-output-app-config`
- **Purpose:** ConfigMap name

#### `trustedOutputApp.config.data`
Configuration data

- **`LOG_LEVEL`**: `"info"` - Logging verbosity
- **`ENABLE_AUDIT`**: `"true"` - Enable audit logging

### `trustedOutputApp.pdb`
PodDisruptionBudget

#### `trustedOutputApp.pdb.enabled`
- **Type:** Boolean
- **Default:** `true`
- **Purpose:** Create PDB

### `trustedOutputApp.toaAccessLabel`
Access label configuration

#### `trustedOutputApp.toaAccessLabel.enabled`
- **Type:** Boolean
- **Default:** `true`
- **Purpose:** Enable TOA access label

#### `trustedOutputApp.toaAccessLabel.key`
- **Type:** String
- **Default:** `role`
- **Purpose:** Label key

#### `trustedOutputApp.toaAccessLabel.value`
- **Type:** String
- **Default:** `toa-access`
- **Purpose:** Label value for network policies

### `trustedOutputApp.podLabels`
Pod labels

- **`app.kubernetes.io/component`**: `toa`
- **`role`**: `toa`

### `trustedOutputApp.workingDir`
- **Type:** String
- **Default:** `/home/node/app`
- **Purpose:** Working directory

### `trustedOutputApp.command`
- **Type:** Array
- **Default:** `["npm", "run", "start"]`
- **Purpose:** Entrypoint command

### `trustedOutputApp.networkPolicy`
Network policy

#### `trustedOutputApp.networkPolicy.allowK8sApiEgress`
- **Type:** Boolean
- **Default:** `false`
- **Purpose:** K8s API access

#### `trustedOutputApp.networkPolicy.k8sApiCidr`
- **Type:** String
- **Default:** `10.100.0.0/16`
- **Purpose:** API CIDR range

### `trustedOutputApp.environmentVariables`
Environment variables

- **`httpBasicAuth`**: `admin:admin` - Basic auth (example)

---

## Research Container Configuration

### `researchContainer.name`
- **Type:** String
- **Default:** `research`
- **Purpose:** Name for research container pods

---

## Global Defaults

### `replicaCount`
- **Type:** Integer
- **Default:** `2`
- **Purpose:** Default replica count

### `podAnnotations`
- **Type:** Object
- **Default:** `{}`
- **Purpose:** Default pod annotations

### `podLabels`
Default pod labels

- **`environment`**: `prod` - Environment label
- **`team`**: `data` - Team ownership

### `podSecurityContext`
Pod-level security context

- **`runAsUser`**: `10001` - Run as non-root UID
- **`runAsGroup`**: `10001` - Run as non-root GID
- **`fsGroup`**: `10001` - Filesystem group
- **`runAsNonRoot`**: `true` - Enforce non-root
- **`seccompProfile.type`**: `RuntimeDefault` - Seccomp profile

### `securityContext`
Container-level security context

- **`allowPrivilegeEscalation`**: `false` - No privilege escalation
- **`readOnlyRootFilesystem`**: `true` - Immutable root filesystem
- **`runAsNonRoot`**: `true` - Non-root enforcement
- **`runAsUser`**: `10001`
- **`runAsGroup`**: `10001`
- **`seccompProfile.type`**: `RuntimeDefault`
- **`capabilities.drop`**: `["ALL"]` - Drop all capabilities

### `ingress`
Ingress configuration (disabled)

#### `ingress.enabled`
- **Type:** Boolean
- **Default:** `false`
- **Purpose:** Create Ingress resource

### `resources`
Default resource limits

#### `resources.requests`
- **`cpu`**: `100m`
- **`memory`**: `128Mi`
- **`ephemeral-storage`**: `512Mi`

#### `resources.limits`
- **`cpu`**: `500m`
- **`memory`**: `512Mi`
- **`ephemeral-storage`**: `2Gi`

### `emptyDir`
Temporary storage

#### `emptyDir.enabled`
- **Type:** Boolean
- **Default:** `true`
- **Purpose:** Mount emptyDir volume

#### `emptyDir.sizeLimit`
- **Type:** String
- **Default:** `2Gi`
- **Purpose:** Max size

#### `emptyDir.mountPath`
- **Type:** String
- **Default:** `/tmp`
- **Purpose:** Mount path

### `livenessProbe`
Liveness probe configuration

- **`httpGet.path`**: `/`
- **`httpGet.port`**: `http`
- **`initialDelaySeconds`**: `30`
- **`periodSeconds`**: `15`
- **`timeoutSeconds`**: `5`
- **`failureThreshold`**: `3`

### `readinessProbe`
Readiness probe configuration

- **`httpGet.path`**: `/`
- **`httpGet.port`**: `http`
- **`initialDelaySeconds`**: `5`
- **`periodSeconds`**: `5`
- **`timeoutSeconds`**: `2`
- **`failureThreshold`**: `2`
- **`successThreshold`**: `1`

### `startupProbe`
Startup probe configuration

- **`httpGet.path`**: `/`
- **`httpGet.port`**: `http`
- **`periodSeconds`**: `5`
- **`timeoutSeconds`**: `3`
- **`failureThreshold`**: `30`
- **`initialDelaySeconds`**: `0`

### `volumes`
- **Type:** Array
- **Default:** `[]`
- **Purpose:** Additional volumes

### `volumeMounts`
- **Type:** Array
- **Default:** `[]`
- **Purpose:** Additional volume mounts

### `nodeSelector`
- **Type:** Object
- **Default:** `{"role": "workloads"}`
- **Purpose:** Node selection

### `tolerations`
Node taints toleration

- **`key`**: `dedicated`
- **`operator`**: `Equal`
- **`value`**: `workloads`
- **`effect`**: `NoSchedule`

### `affinity`
Pod affinity configuration

#### `affinity.nodeAffinity`
Prefer non-Karpenter nodes

#### `affinity.podAntiAffinity`
Avoid co-locating pods on same node

### `topologySpreadConstraints`
Spread pods across zones

#### `topologySpreadConstraints.enabled`
- **Type:** Boolean
- **Default:** `true`
- **Purpose:** Enable topology spread

#### `topologySpreadConstraints.rules`
- **`maxSkew`**: `1`
- **`topologyKey`**: `topology.kubernetes.io/zone`
- **`whenUnsatisfiable`**: `DoNotSchedule`

### `pdb`
Global PDB defaults

#### `pdb.enabled`
- **Type:** Boolean
- **Default:** `true`
- **Purpose:** Create PDB

#### `pdb.maxUnavailable`
- **Type:** Integer
- **Default:** `1`
- **Purpose:** Max unavailable pods

### `antiAffinity`
Pod anti-affinity

#### `antiAffinity.enabled`
- **Type:** Boolean
- **Default:** `true`

#### `antiAffinity.required`
- **Type:** Boolean
- **Default:** `false`

### `topologySpread`
Topology spread defaults

#### `topologySpread.enabled`
- **Type:** Boolean
- **Default:** `true`

#### `topologySpread.topologyKey`
- **Type:** String
- **Default:** `topology.kubernetes.io/zone`

---

## Horizontal Pod Autoscaler (HPA)

### `hpa.enabled`
- **Type:** Boolean
- **Default:** `true`
- **Purpose:** Enable auto-scaling

### `hpa.minReplicas`
- **Type:** Integer
- **Default:** `2`
- **Purpose:** Minimum pod count

### `hpa.maxReplicas`
- **Type:** Integer
- **Default:** `10`
- **Purpose:** Maximum pod count

### `hpa.targetCPUUtilizationPercentage`
- **Type:** Integer
- **Default:** `70`
- **Purpose:** CPU threshold for scaling

### `hpa.targetMemoryUtilizationPercentage`
- **Type:** Integer
- **Default:** `80`
- **Purpose:** Memory threshold for scaling

---

## Service Configuration

### `service.enabled`
- **Type:** Boolean
- **Default:** `true`
- **Purpose:** Create Service

### `service.type`
- **Type:** String
- **Default:** `ClusterIP`
- **Purpose:** Service type

### `service.port`
- **Type:** Integer
- **Default:** `80`
- **Purpose:** Service port

---

## Image Configuration

### `image.pullPolicy`
- **Type:** String
- **Default:** `Always`
- **Purpose:** Image pull policy

---

## Service Account

### `automountServiceAccountToken`
- **Type:** Boolean
- **Default:** `false`
- **Purpose:** Global default for token mounting

---

## Namespace Configuration

### `bootstrapNamespaces`
- **Type:** Boolean
- **Default:** `false`
- **Purpose:** Create namespaces via Helm

### `adminNamespace`
- **Type:** String
- **Default:** `enclave-admin-ns`
- **Purpose:** Admin namespace name

### `researchNamespace`
- **Type:** String
- **Default:** `enclave-research-ns`
- **Purpose:** Research namespace name

### `environment`
- **Type:** String
- **Default:** `prod`
- **Purpose:** Environment label

### `team`
- **Type:** String
- **Default:** `data`
- **Purpose:** Team label

---

## Research Network Egress

### `researchEgressCidrs`
- **Type:** Array
- **Purpose:** Allowed egress destinations for research pods
- **Entries:**
  - `{ cidr: "10.2.0.0/16", port: 5432 }` - RDS database
  - `{ cidr: "10.2.0.0/16", port: 5439 }` - Redshift
  - `{ cidr: "192.168.0.0/16", port: 443 }` - S3 via Gateway Endpoint

---

## External Secrets Configuration

### `externalSecretsEnabled`
- **Type:** Boolean
- **Default:** `true`
- **Purpose:** Enable External Secrets Operator

### `externalSecret.secretStoreRef`
Reference to secret store

#### `externalSecret.secretStoreRef.kind`
- **Type:** String
- **Default:** `ClusterSecretStore`
- **Purpose:** Store type

#### `externalSecret.secretStoreRef.name`
- **Type:** String
- **Default:** `aws-sm`
- **Purpose:** Store name

---

## Internal Auth Configuration

### `internalAuth.enabled`
- **Type:** Boolean
- **Default:** `true`
- **Purpose:** Enable internal authentication

### `internalAuth.awsSecretName`
- **Type:** String
- **Default:** `prod/enclave/internal-auth`
- **Purpose:** AWS Secrets Manager path

### `internalAuth.refreshInterval`
- **Type:** String
- **Default:** `1h`
- **Purpose:** Refresh frequency

### `internalAuth.isJson`
- **Type:** Boolean
- **Default:** `true`
- **Purpose:** Secret is JSON format

### `internalAuth.k8sSecretName`
- **Type:** String
- **Default:** `internal-auth-credentials`
- **Purpose:** Kubernetes secret name

### `internalAuth.taoBasicAuth`
- **Type:** String
- **Default:** `TOA_BASIC_AUTH`
- **Purpose:** TOA auth key name

### `internalAuth.signingKey`
- **Type:** String
- **Default:** `SIGNING_KEY`
- **Purpose:** Signing key name

### `internalAuth.volumeName`
- **Type:** String
- **Default:** `internal-auth`
- **Purpose:** Volume name

### `internalAuth.mountPath`
- **Type:** String
- **Default:** `/etc/secrets/internal-auth`
- **Purpose:** Mount path

### `internalAuth.pathEnvVar`
- **Type:** String
- **Default:** `INTERNAL_AUTH_PATH`
- **Purpose:** Environment variable name

### `internalAuth.defaultMode`
- **Type:** String/Integer
- **Default:** `0400`
- **Purpose:** File permissions (read-only owner)

---

## Audit Configuration

### `audit.placeholders.research`
- **Type:** Boolean
- **Default:** `true`
- **Purpose:** Create research placeholder deployment

---

## Kubernetes Core Services

### `kubeSystem.serviceCidr`
- **Type:** String
- **Default:** `172.20.0.0/16`
- **Purpose:** K8s service CIDR range

### `kubeSystem.vpcCidr`
- **Type:** String
- **Default:** `10.52.0.0/16`
- **Purpose:** AWS VPC CIDR

### `kubeSystem.controlPlaneCidr`
- **Type:** String
- **Default:** `10.52.0.0/16`
- **Purpose:** Control plane CIDR

### `kubeSystem.apiServer`
Kubernetes API server

#### `kubeSystem.apiServer.ip`
- **Type:** String
- **Default:** `172.20.0.1`
- **Purpose:** API server IP

#### `kubeSystem.apiServer.port`
- **Type:** Integer
- **Default:** `443`
- **Purpose:** API server port

### `kubeSystem.coreDns`
CoreDNS configuration

#### `kubeSystem.coreDns.ip`
- **Type:** String
- **Default:** `172.20.0.10`
- **Purpose:** CoreDNS service IP

#### `kubeSystem.coreDns.dnsPort`
- **Type:** Integer
- **Default:** `53`
- **Purpose:** DNS UDP port

#### `kubeSystem.coreDns.dnsTcpPort`
- **Type:** Integer
- **Default:** `53`
- **Purpose:** DNS TCP port

#### `kubeSystem.coreDns.metricsPort`
- **Type:** Integer
- **Default:** `9153`
- **Purpose:** Metrics port

---

## CNI Configuration

### `cni.type`
- **Type:** String
- **Default:** `"calico"`
- **Purpose:** CNI plugin type

### `cni.calico`
Calico-specific configuration

#### `cni.calico.typhaPort`
- **Type:** Integer
- **Default:** `5473`
- **Purpose:** Typha service port

#### `cni.calico.nodeMetricsPort`
- **Type:** Integer
- **Default:** `9091`
- **Purpose:** Node metrics port

#### `cni.calico.bgpPort`
- **Type:** Integer
- **Default:** `179`
- **Purpose:** BGP port

---

## Infrastructure Components

### `infrastructure.metricsServer`
Metrics server configuration

#### `infrastructure.metricsServer.enabled`
- **Type:** Boolean
- **Default:** `true`
- **Purpose:** Enable metrics server

#### `infrastructure.metricsServer.ip`
- **Type:** String
- **Default:** `172.20.167.223`
- **Purpose:** Metrics server IP

#### `infrastructure.metricsServer.port`
- **Type:** Integer
- **Default:** `443`
- **Purpose:** Metrics server port

### `infrastructure.externalSecrets`
External Secrets Operator

#### `infrastructure.externalSecrets.enabled`
- **Type:** Boolean
- **Default:** `true`
- **Purpose:** Enable ESO

#### `infrastructure.externalSecrets.webhookIp`
- **Type:** String
- **Default:** `172.20.246.71`
- **Purpose:** Webhook service IP

#### `infrastructure.externalSecrets.webhookPort`
- **Type:** Integer
- **Default:** `443`
- **Purpose:** Webhook port

---

## Node Ports

### `nodePorts.kubelet`
- **Type:** Integer
- **Default:** `10250`
- **Purpose:** Kubelet API port

### `nodePorts.kubeletReadOnly`
- **Type:** Integer
- **Default:** `10255`
- **Purpose:** Kubelet read-only (deprecated)

### `nodePorts.nodePortRange`
- **Type:** String
- **Default:** `"30000-32767"`
- **Purpose:** NodePort service range

---

## AWS Special Addresses

### `awsAddresses.imds`
Instance Metadata Service

#### `awsAddresses.imds.ip`
- **Type:** String
- **Default:** `169.254.169.254`
- **Purpose:** IMDS link-local IP

#### `awsAddresses.imds.port`
- **Type:** Integer
- **Default:** `80`
- **Purpose:** IMDS port

### `awsAddresses.timeSync`
AWS Time Sync

#### `awsAddresses.timeSync.ip`
- **Type:** String
- **Default:** `169.254.169.123`
- **Purpose:** Time sync IP

#### `awsAddresses.timeSync.port`
- **Type:** Integer
- **Default:** `123`
- **Purpose:** NTP port

### `awsAddresses.podIdentity`
EKS Pod Identity

#### `awsAddresses.podIdentity.ip`
- **Type:** String
- **Default:** `169.254.170.23`
- **Purpose:** Pod Identity endpoint

#### `awsAddresses.podIdentity.port`
- **Type:** Integer
- **Default:** `80`
- **Purpose:** Pod Identity port

### `awsAddresses.instanceConnect`
EC2 Instance Connect

#### `awsAddresses.instanceConnect.ip`
- **Type:** String
- **Default:** `169.254.169.254`
- **Purpose:** Instance Connect IP

#### `awsAddresses.instanceConnect.port`
- **Type:** Integer
- **Default:** `80`
- **Purpose:** Instance Connect port

---

## NAT Gateway

### `natGateway.egressCidrs`
- **Type:** Array
- **Purpose:** NAT Gateway egress IPs
- **Example:**
  - `{ cidr: "3.18.49.59/32", description: "NAT Gateway Elastic IP" }`
