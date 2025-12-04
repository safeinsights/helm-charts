# Secure Enclave Helm Chart

## Dependencies

This chart depends on the Calico chart for network policy functionality. The Calico chart will be automatically installed if:
1. `networkPolicy.installCalico` is set to `true` in values.yaml, AND
2. The calico-node daemonset does not already exist in the cluster

**Note**: Helm dependencies cannot check for existing resources at install time. The installation is controlled by the `networkPolicy.installCalico` flag. To check if calico is already installed, use the helper function:
```helm
{{- if eq (include "secure-enclave.hasCalicoNodeDaemonset" .) "true" }}
# Calico is installed and running
{{- else }}
# Calico is not installed or not running
{{- end }}
```

## Lookup Functions

### hasCalicoNodeDaemonset

Check if the calico-node daemonset exists in the calico-system namespace.

**Usage:**
```helm
{{- if eq (include "secure-enclave.hasCalicoNodeDaemonset" .) "true" }}
# Calico daemonset exists
{{- else }}
# Calico daemonset does not exist
{{- end }}
```

**Returns:**
- `true` if calico-node daemonset exists in calico-system namespace
- `false` if calico-node daemonset does not exist in calico-system namespace
