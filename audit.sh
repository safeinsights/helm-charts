#!/usr/bin/env bash
set -euo pipefail

# -------- Settings --------
CHART_DIR="${1:-./chart}"       # path to Helm chart (arg1)
RELEASE_NAME="${2:-audit}"      # synthetic release name
NAMESPACE="${3:-audit}"         # synthetic namespace
VALUES_FILE="${4:-}"            # optional values.yaml path
K8S_VERSION="${K8S_VERSION:-1.29.0}"  # for kubeconform schemas

#To run this script, install Helm,yq,kubeconform,kube-score,Polaris,Trivy,Conftest
# -------- Helpers --------
need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing '$1'"; exit 127; }; }

render() {
  echo "==> helm lint"
  if [[ -n "$VALUES_FILE" ]]; then
    helm lint "$CHART_DIR" -f "$VALUES_FILE"
  else
    helm lint "$CHART_DIR"
  fi

  echo "==> helm template"
  if [[ -n "$VALUES_FILE" ]]; then
    helm template "$RELEASE_NAME" "$CHART_DIR" -n "$NAMESPACE" -f "$VALUES_FILE" > rendered.yaml
  else
    helm template "$RELEASE_NAME" "$CHART_DIR" -n "$NAMESPACE" > rendered.yaml
  fi
  echo "Rendered manifests -> rendered.yaml"
}

scan() {
  echo "==> kubeconform (OpenAPI validation)"
  kubeconform -strict -kubernetes-version "$K8S_VERSION" -ignore-missing-schemas rendered.yaml

  echo "==> kube-score (best practices)"
  # Fail on warnings for CI; locally you can drop --exit-one-on-warning
  kube-score score --exit-one-on-warning rendered.yaml || {
    echo "kube-score found issues"; exit 1; }

  echo "==> Polaris (policy & configs)"
  polaris audit --file rendered.yaml --only-show-failed-tests=false --output-format pretty --set-exit-code-on-danger --set-exit-code-below-score 90

  echo "==> Trivy (misconfig scan)"
  # HIGH+ only; add CRITICAL for stricter
  trivy config --severity HIGH,CRITICAL --exit-code 1 --timeout 10m rendered.yaml

  if [[ -d "policy" ]]; then
    echo "==> Conftest (OPA policies in ./policy)"
    conftest test rendered.yaml || { echo "Conftest policy failures"; exit 1; }
  else
    echo "Conftest skipped (no ./policy directory)"
  fi
}

main() {
  render
  scan
  echo "✅ Audit passed for $CHART_DIR"
}

main "$@"

