# Secure Enclave Helm Chart - Templates Documentation

## Table of Contents
1. [Deployments](#deployments)
2. [Storage](#storage)
3. [Secrets](#secrets)
4. [Services](#services)
5. [PersistentVolumeClaims (PVC)](#persistentvolumeclaims-pvc)
6. [PodDisruptionBudgets (PDB)](#poddisruptionbudgets-pdb)
7. [HorizontalPodAutoscaler (HPA)](#horizontalpodautoscaler-hpa)
8. [ServiceAccounts](#serviceaccounts)
9. [Network Policies](#network-policies)
10. [Roles and RoleBindings](#roles-and-rolebindings)
11. [ConfigMaps](#configmaps)
12. [PriorityClass](#priorityclass)
13. [Helpers (_helpers.tpl)](#helpers-_helperstpl)
14. [Tests](#tests)

---

## Deployments

### `setup-app-deployment.yaml`
**Purpose:** Deploy the Setup App that manages research job lifecycle

**What it does:**
- Creates a Deployment for the Setup App with configurable replicas (or HPA-managed)
- Mounts ConfigMap, Secrets (management-app, internal-auth)
- Configures pod security context (non-root, read-only filesystem)
- Implements pod anti-affinity for high availability
- Uses EBS persistent volume when enabled
- Configures readiness, liveness, and startup probes
- Sets resource requests/limits
- Uses Harbor registry with image pull secrets
- Exposes port 5051 for HTTP traffic
- Runs polling script to check for new studies and manage research pods

**Key Features:**
- RollingUpdate strategy (maxSurge: 0, maxUnavailable: 1)
- Pod priority class: `enclave-high-priority`
- Topology spread across availability zones
- Working directory: `/home/node/code`
- Command: `npx tsx src/scripts/poll.ts`

### `trusted-output-app-deployment.yaml`
**Purpose:** Deploy the Trusted Output App (TOA) for secure result validation

**What it does:**
- Creates a Deployment for TOA (typically single replica)
- Mounts ConfigMap, Secrets (signing keys, auth credentials)
- Implements strict pod security context
- Uses EBS persistent volume for result storage
- Configures health probes
- Sets resource requests/limits
- Exposes port 3002 (targetPort) as service port 5050
- Validates and signs research output before submission

**Key Features:**
- RollingUpdate strategy (maxSurge: 0, maxUnavailable: 1)
- Pod priority class: `system-cluster-critical`
- Required pod anti-affinity (no co-location)
- Working directory: `/home/node/app`
- Command: `npm run start`
- HPA typically disabled (single replica for security)

### `research-placeholder.yaml`
**Purpose:** Create a placeholder deployment for network policy validation

**What it does:**
- Creates a zero-replica Deployment with research pod labels
- Used by Calico to validate network policies apply correctly
- Ensures NetworkPolicies compile before actual research pods exist
- Helps with policy auditing and troubleshooting
- Uses minimal busybox image for efficiency

**Key Features:**
- Replicas: 0 (never actually runs)
- Label: `role: research` (matches network policy selectors)
- Minimal resources (10m CPU, 16Mi memory)
- Priority class: `system-cluster-critical`
- Non-root security context
- Topology spread for zone distribution

---

## Storage

### `aws-ebs-sc.yaml`
**Purpose:** Define AWS EBS StorageClass for persistent volumes

**What it does:**
- Creates a StorageClass using AWS EBS CSI driver
- Configures gp3 volume type (latest general-purpose SSD)
- Enables encryption at rest
- Sets XFS filesystem type
- Allows volume expansion after creation
- Uses `WaitForFirstConsumer` binding mode (volume created only when pod is scheduled)
- Reclaim policy: Retain (keeps volumes after PVC deletion)

**Configuration:**
- Provisioner: `ebs.csi.aws.com`
- Volume type: `gp3`
- Encryption: Enabled
- Filesystem: `xfs`
- Binding mode: `WaitForFirstConsumer` (optimal for multi-AZ clusters)

---

## Secrets

### `management-app-externalsecret.yaml`
**Purpose:** Sync Management App credentials from AWS Secrets Manager

**What it does:**
- Creates ExternalSecret resource for External Secrets Operator
- Fetches credentials from AWS Secrets Manager path: `prod/management/app/creds`
- Creates Kubernetes secret: `management-app-secret`
- Syncs: HTTP Basic Auth credentials, Member ID
- Refreshes every 1 hour
- Uses ClusterSecretStore: `aws-sm`

**Keys:**
- `HTTP_BASIC_AUTH` ← `httpBasicAuth`
- `MGMT_APP_MEMBER_ID` ← `memberId`

### `internal-auth-externalsecret.yaml`
**Purpose:** Sync internal authentication credentials (Setup ↔ TOA ↔ Research)

**What it does:**
- Fetches internal auth secrets from AWS Secrets Manager
- Creates Kubernetes secret: `internal-auth-credentials`
- Used for communication between Setup App, TOA, and Research pods
- Supports JSON secret format
- Refreshes every 1 hour

**Keys:**
- Signing keys
- TOA basic auth
- Internal service credentials

### `admin-harbor-pull-externalsecret.yaml`
**Purpose:** Sync Harbor registry credentials for image pulling

**What it does:**
- Fetches Harbor robot account credentials from AWS Secrets Manager
- Creates Kubernetes Docker config secret: `si-docker-config`
- Used by Setup App and TOA to pull images from Harbor registry
- Enables private registry access
- Refreshes every 1 hour

**Secret Type:** `kubernetes.io/dockerconfigjson`

### `research-image-pull-externalsecret.yaml`
**Purpose:** Sync Harbor credentials for research namespace

**What it does:**
- Fetches Harbor robot credentials for research namespace
- Creates Docker config secret in research namespace
- Used by research pods to pull container images
- Separate credentials for isolation
- Refreshes every 1 hour

---

## Services

### `setup-app-svc.yaml`
**Purpose:** Expose Setup App within the cluster

**What it does:**
- Creates ClusterIP Service for Setup App
- Exposes port 5051 (both service and target port)
- Selects pods with label: `app: setup-app`
- Enables internal communication from other components
- Used by TOA and test pods to reach Setup App

**Service Type:** ClusterIP (internal only)
**Selector:** `app: setup-app`
**Port:** 5051 (HTTP)

### `trusted-output-app-svc.yaml`
**Purpose:** Expose Trusted Output App within the cluster

**What it does:**
- Creates ClusterIP Service for TOA
- Exposes port 5050 (service) → 3002 (container)
- Selects pods with label: `app: toa`
- Enables Setup App and research pods to submit results
- Provides secure result validation endpoint

**Service Type:** ClusterIP (internal only)
**Selector:** `app: toa`
**Ports:** 5050 → 3002 (HTTP)

---

## PersistentVolumeClaims (PVC)

### `setup-app-pvc.yaml`
**Purpose:** Request persistent storage for Setup App

**What it does:**
- Creates PVC for Setup App data persistence
- Requests EBS volume via StorageClass: `aws-ebs-sc`
- Size: 20Gi (default)
- Access mode: ReadWriteOnce (single node attachment)
- Mounts at: `/var/lib/setup-app`
- Used for: Job state, logs, temporary data

**Key Details:**
- StorageClass: `aws-ebs-sc`
- Access Mode: `ReadWriteOnce` (EBS constraint)
- Default Size: 20Gi
- Volume Mode: Filesystem

### `trusted-output-app-pvc.yaml`
**Purpose:** Request persistent storage for TOA

**What it does:**
- Creates PVC for TOA result storage
- Requests EBS volume via StorageClass: `aws-ebs-sc`
- Size: 10Gi (default)
- Access mode: ReadWriteOnce
- Mounts at: `/var/lib/trusted-output-app`
- Used for: Signed results, verification logs

**Key Details:**
- StorageClass: `aws-ebs-sc`
- Access Mode: `ReadWriteOnce`
- Default Size: 10Gi
- Volume Mode: Filesystem

---

## PodDisruptionBudgets (PDB)

### `setup-app-pdb.yaml`
**Purpose:** Ensure Setup App availability during disruptions

**What it does:**
- Creates PodDisruptionBudget for Setup App
- Ensures minimum pod availability during voluntary disruptions
- Protects against too many pods being evicted simultaneously
- Default: `maxUnavailable: 1` (at least N-1 pods must remain)
- Selector: `app: setup-app`

**Use Case:**
- Prevents complete downtime during node drains
- Allows rolling updates to proceed safely
- Protects against cluster upgrades disrupting service

### `trusted-output-app-pdb.yaml`
**Purpose:** Ensure TOA availability during disruptions

**What it does:**
- Creates PodDisruptionBudget for TOA
- Maintains minimum availability during voluntary disruptions
- Critical for result submission reliability
- Default: `maxUnavailable: 1`
- Selector: `app: toa`

### `research-placeholder-pdb.yaml`
**Purpose:** PDB for research placeholder deployment

**What it does:**
- Creates PDB for research placeholder (though replicas=0)
- Maintains consistency in resource definitions
- Used for policy validation
- Selector: `role: research`

---

## HorizontalPodAutoscaler (HPA)

### `setup-app-hpa.yaml`
**Purpose:** Auto-scale Setup App based on CPU/memory

**What it does:**
- Creates HPA for Setup App deployment
- Scales between min (2) and max (10) replicas
- Triggers scaling based on CPU (70%) and memory (80%) utilization
- Automatically adjusts pod count based on load
- Overrides static replica count when enabled

**Metrics:**
- CPU target: 70% utilization
- Memory target: 80% utilization

**Scaling:**
- Min replicas: 2
- Max replicas: 10

### `trusted-output-app-hpa.yaml`
**Purpose:** Auto-scale TOA (typically disabled)

**What it does:**
- Creates HPA for TOA deployment
- Usually disabled (`hpa.enabled: false`) for security/consistency
- TOA typically runs single replica for signed result integrity
- Can be enabled if horizontal scaling is needed

**Note:** HPA is typically disabled for TOA to maintain single-instance result signing

---

## ServiceAccounts

### `setup-app-serviceaccount.yaml`
**Purpose:** Define ServiceAccount for Setup App with IRSA

**What it does:**
- Creates ServiceAccount for Setup App
- Annotated with IAM Role ARN for IRSA (IAM Roles for Service Accounts)
- Grants AWS API access via IAM role assumption
- Mounts token to pods (enabled by default)
- Attached secrets: management-app-secret, internal-auth-credentials

**IRSA Integration:**
- Annotation: `eks.amazonaws.com/role-arn` (set via values)
- Enables AWS API calls without static credentials
- Used for: S3 access, Secrets Manager, EC2 API

**Security:**
- `automountServiceAccountToken: true` (needed for K8s API access)
- Enforces mountable secrets (optional annotation)

### `trusted-output-app-serviceaccount.yaml`
**Purpose:** Define ServiceAccount for TOA

**What it does:**
- Creates ServiceAccount for TOA
- Annotated with IAM Role ARN for IRSA
- Token auto-mount disabled by default (enhanced security)
- Attached secrets: management-app-secret, internal-auth-credentials

**IRSA Integration:**
- Annotation: `eks.amazonaws.com/role-arn`
- Enables AWS API access for result storage
- Used for: S3 output storage, Secrets Manager

**Security:**
- `automountServiceAccountToken: false` (disabled by default)
- Minimal AWS permissions via IRSA

---

## Network Policies

### `global-deny-all-network-policy.yaml`
**Purpose:** Default-deny all traffic in admin namespace

**What it does:**
- Creates default-deny NetworkPolicy in admin namespace
- Blocks all ingress and egress by default
- Allows only CoreDNS egress (UDP/TCP 53 to kube-system)
- Forces explicit allow rules for all other traffic
- Fail-closed security model

**Scope:** Admin namespace (enclave-admin-ns)

**Allowed:**
- Egress to CoreDNS in kube-system (UDP/TCP port 53)

### `global-allow-network-policy.yaml`
**Purpose:** Global allow-all policy (typically disabled in production)

**What it does:**
- Creates allow-all NetworkPolicy when enabled
- Useful for testing/debugging
- Should be disabled in production
- Overrides default-deny rules

**Use Case:** Temporary debugging, initial setup validation

### `global-infrastructure-network-policy.yaml`
**Purpose:** Allow traffic to infrastructure components

**What it does:**
- Permits egress to Kubernetes infrastructure services
- Allows access to: Metrics Server, External Secrets Operator webhook
- Enables infrastructure components to function
- Applies to all pods in namespace

**Allowed Destinations:**
- Metrics Server (443)
- External Secrets Operator webhook (443)
- AWS IMDS (169.254.169.254:80)

### `global-monitoring-network-policy.yaml`
**Purpose:** Allow metrics collection for monitoring

**What it does:**
- Permits monitoring systems to scrape metrics
- Allows ingress from monitoring namespace
- Enables Prometheus to collect pod metrics
- Applies to pods with monitoring labels

**Allowed:**
- Ingress from monitoring namespace to metrics ports

### `setup-app-network-policy.yaml`
**Purpose:** Define egress rules for Setup App

**What it does:**
- Allows egress to CoreDNS for name resolution
- Permits connections to TOA service (port 5050)
- Allows connections to Management App (external IPs)
- Optionally allows K8s API access (if enabled)
- Blocks all other egress

**Allowed Egress:**
- CoreDNS (kube-system, UDP/TCP 53)
- TOA service (admin namespace, TCP 5050)
- Management App (external IPs, TCP 443)
- K8s API (optional, TCP 443)

**Ingress:**
- From admin namespace (TCP 5051)

### `trusted-output-app-network-policy.yaml`
**Purpose:** Define ingress/egress rules for TOA

**What it does:**
- Allows ingress from research pods (label: `role: toa-access`)
- Allows ingress from Setup App
- Permits egress to Management App for result submission
- Blocks all other traffic

**Allowed Ingress:**
- From research namespace pods with `role: toa-access` (TCP 5050)
- From Setup App in admin namespace (TCP 5050)

**Allowed Egress:**
- To Management App IPs (TCP 443)

### `research-network-policy.yaml`
**Purpose:** Define egress rules for research pods

**What it does:**
- Allows egress to CoreDNS for name resolution
- Permits connections to data sources (RDS, Redshift, S3)
- Restricts egress to specified CIDRs and ports
- Blocks all other egress

**Allowed Egress:**
- CoreDNS (kube-system, UDP/TCP 53)
- RDS databases (10.2.0.0/16, TCP 5432)
- Redshift (10.2.0.0/16, TCP 5439)
- S3 via Gateway Endpoint (192.168.0.0/16, TCP 443)

**Selector:** `role: research`

### `research-container-admin-network-policy.yaml`
**Purpose:** Allow research pods to communicate with Setup App

**What it does:**
- Permits research pods to reach Setup App for job coordination
- Enables status reporting
- Allows job lifecycle management

**Allowed:**
- Research pods → Setup App (TCP 5051)

---

## Roles and RoleBindings

### `setup-app-role.yaml`
**Purpose:** Define RBAC permissions for Setup App in admin namespace

**What it does:**
- Grants read-only access to pods, services, endpoints, configmaps, events
- Allows reading specific secrets (name-scoped)
- Permits Job management (get, list, watch, create, delete)
- Enables Setup App to manage research jobs

**Permissions:**
- Read: pods, services, endpoints, configmaps, events
- Read (name-scoped): specified secrets
- Manage: Jobs (create, delete, get, list, watch)

**Namespace:** Admin namespace (enclave-admin-ns)

### `setup-app-research-role.yaml`
**Purpose:** Define RBAC permissions for Setup App in research namespace

**What it does:**
- Grants pod lifecycle management in research namespace
- Allows creating, deleting, watching research pods
- Optionally allows pod exec (disabled by default)
- Optionally allows log reading (enabled by default)
- Enables research Job management

**Permissions:**
- Pods: create, get, list, watch, delete
- Pods/exec: create (optional, disabled)
- Pods/log: get, list, watch (optional, enabled)
- Events: get, list, watch (optional, enabled)
- Jobs: create, get, list, watch, delete (optional, enabled)

**Namespace:** Research namespace (enclave-research-ns)

### `setup-app-research-rolebinding.yaml`
**Purpose:** Bind research Role to Setup App ServiceAccount

**What it does:**
- Binds `setup-app-research-pod-admin` Role to Setup App SA
- Grants cross-namespace permissions
- ServiceAccount in admin namespace gets permissions in research namespace
- Enables Setup App to manage research pods

**Binding:**
- Role: `setup-app-research-pod-admin` (research namespace)
- Subject: `setup-app-sa` (admin namespace)

---

## ConfigMaps

ConfigMaps store non-sensitive configuration data for applications.

### `setup-app-configmap.yaml`
**Purpose:** Store Setup App environment configuration

**What it does:**
- Creates ConfigMap with application settings
- Stores environment variables for Setup App
- Contains K8s API endpoint, TOA URL, polling intervals
- Loaded via `envFrom` in deployment

**Configuration Data:**
- `DEPLOYMENT_ENVIRONMENT`: `KUBERNETES`
- `K8S_APISERVER`: K8s API endpoint URL
- `K8S_SERVICEACCOUNT_PATH`: ServiceAccount token path
- `TOA_BASE_URL`: TOA service URL
- `POLL_STUDIES_INTERVAL_SECONDS`: Study polling frequency
- `POLL_ERRORED_JOBS_INTERVAL_SECONDS`: Error check frequency
- `HARBOR_PULL_SECRET`: Image pull secret name

**Usage:**
- Mounted via `envFrom.configMapRef` in Setup App deployment
- Values accessible as environment variables in containers

### `trusted-output-app-configmap.yaml`
**Purpose:** Store TOA environment configuration

**What it does:**
- Creates ConfigMap with TOA application settings
- Stores logging level, audit settings
- Loaded via `envFrom` in deployment

**Configuration Data:**
- `LOG_LEVEL`: Logging verbosity (`info`, `debug`, etc.)
- `ENABLE_AUDIT`: Enable audit logging

**Usage:**
- Mounted via `envFrom.configMapRef` in TOA deployment
- Provides runtime configuration without rebuilding images

**Note:** ConfigMaps are used for non-sensitive configuration. Secrets (via ExternalSecret) are used for sensitive data like credentials.

---

## PriorityClass

### `priorityclass.yaml`
**Purpose:** Define pod scheduling priorities

**What it does:**
- Creates PriorityClass resources for workload prioritization
- Ensures critical pods are scheduled first
- Prevents lower-priority pods from evicting critical ones
- Used during resource contention

**Priority Classes:**

#### `system-cluster-critical`
- **Priority Value:** 2000000000
- **Global Default:** false
- **Description:** Critical system components (TOA)
- **Preemption Policy:** PreemptLowerPriority

#### `enclave-high-priority`
- **Priority Value:** 1000000
- **Global Default:** false
- **Description:** High-priority application pods (Setup App)
- **Preemption Policy:** PreemptLowerPriority

#### `enclave-normal-priority`
- **Priority Value:** 100000
- **Global Default:** true
- **Description:** Normal workload priority
- **Preemption Policy:** PreemptLowerPriority

**Usage:**
- TOA: `system-cluster-critical` (highest priority)
- Setup App: `enclave-high-priority`
- Research pods: `enclave-normal-priority` (default)

---

## Helpers (_helpers.tpl)

The `_helpers.tpl` file contains reusable template functions used across all other templates.

### Template Functions

#### `secure-enclave.name`
**Purpose:** Get the chart name
**Returns:** Chart name from `.Chart.Name` or `nameOverride`

#### `secure-enclave.fullname`
**Purpose:** Generate fully qualified app name
**Returns:** Release name + chart name (or `fullnameOverride`)

#### `secure-enclave.chart`
**Purpose:** Generate chart label value
**Returns:** Chart name + version (e.g., `secure-enclave-1.0.1`)

#### `secure-enclave.labels`
**Purpose:** Generate common labels for all resources
**Returns:** Standard Kubernetes labels
- `helm.sh/chart`
- `app.kubernetes.io/name`
- `app.kubernetes.io/instance`
- `app.kubernetes.io/version`
- `app.kubernetes.io/managed-by`

#### `secure-enclave.selectorLabels`
**Purpose:** Generate selector labels for pod matching
**Returns:**
- `app.kubernetes.io/name`
- `app.kubernetes.io/instance`

#### `secure-enclave.serviceAccountName`
**Purpose:** Get ServiceAccount name
**Returns:** ServiceAccount name or "default"

#### `secure-enclave.labelsFor`
**Purpose:** Generate labels for specific component
**Parameters:** `root` (context), `name` (component name)
**Returns:** Component-specific labels

#### `secure-enclave.selectorLabelsFor`
**Purpose:** Generate selector labels for specific component
**Parameters:** `root` (context), `name` (component name)
**Returns:** Component-specific selector labels

#### `secure-enclave.adminNamespace`
**Purpose:** Get admin namespace name
**Returns:** `.Values.adminNamespace` or default `enclave-admin-ns`

#### `secure-enclave.researchNamespace`
**Purpose:** Get research namespace name
**Returns:** `.Values.researchNamespace` (required value)

#### `secure-enclave.defaultDenyNetworkPolicy`
**Purpose:** Generate default-deny NetworkPolicy template
**Returns:** Complete NetworkPolicy YAML
**Features:**
- Denies all ingress/egress
- Allows CoreDNS egress only

#### `secure-enclave.setupAppServiceAccountName`
**Purpose:** Get Setup App ServiceAccount name
**Returns:** `.Values.setupApp.serviceAccount.name` or `setup-app-sa`

#### `secure-enclave.trustedOutputAppServiceAccountName`
**Purpose:** Get TOA ServiceAccount name
**Returns:** `.Values.trustedOutputApp.serviceAccount.name` or `toa-sa`

---

## Tests

### Test Templates

#### `tests/test-connection.yaml`
**Purpose:** Helm test to verify Setup App is reachable

**What it does:**
- Creates a test Pod with curl image
- Attempts to connect to Setup App service
- Checks `/healthz/ready` endpoint
- Runs as Helm test hook
- Auto-deleted before each test run and after success

**Test Command:**
```bash
curl -fsS --connect-timeout 5 --max-time 10 \
  http://setup-app-svc:5051/healthz/ready
```

**Annotations:**
- `helm.sh/hook: test` - Runs on `helm test`
- `helm.sh/hook-delete-policy: before-hook-creation,hook-succeeded` - Cleanup policy

**Security:**
- Non-root user (10000)
- Read-only root filesystem
- Drops all capabilities
- Resource limits enforced

#### `tests/test-connection-np.yaml`
**Purpose:** NetworkPolicy for test connection pod

**What it does:**
- Creates NetworkPolicy for test pods
- Allows egress to Setup App service only
- Allows CoreDNS egress for name resolution
- Denies all ingress to test pod
- Ensures test runs in isolated environment

**Allowed Egress:**
- Setup App service (TCP 5051)
- CoreDNS (kube-system, UDP/TCP 53)

**Selector:** `test-connection: "true"`

---

## Summary

This Helm chart deploys a secure enclave architecture with:

- **Setup App**: Orchestrates research job lifecycle
- **Trusted Output App**: Validates and signs research results
- **Research Pods**: Execute data analysis in isolated environment
- **Network Policies**: Zero-trust network segmentation (Calico)
- **External Secrets**: AWS Secrets Manager integration
- **Storage**: EBS persistent volumes for stateful data
- **RBAC**: Least-privilege access control
- **Monitoring**: Metrics collection and health probes
- **High Availability**: PDBs, HPAs, anti-affinity rules

All components follow security best practices:
- Non-root containers
- Read-only root filesystems
- No privilege escalation
- Minimal capabilities
- Network segmentation
- Secret management via AWS Secrets Manager
- IRSA for AWS API access
- Resource limits enforced
