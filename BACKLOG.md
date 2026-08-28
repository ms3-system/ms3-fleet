# Infra Backlog

Deferred hardening work for the k8s manifests, tracked incrementally as each
service's base gets built out. Items are opt-in improvements on top of a
working base — not blockers for getting a service running.

Status: `[ ]` open · `[x]` done. Update in place as items are picked up;
add new items under the relevant service/section rather than a new file.

## api-service

### Security
- [ ] Move `api-service-secret` values out of plaintext manifests. Use
      SOPS, Sealed Secrets, or External Secrets Operator so `base/` never
      carries real secret material — only a placeholder/generator shape.
      Rotate `API_SERVICE_INTERNAL_TOKEN` once this lands.
- [ ] Add pod-level `securityContext`: `runAsNonRoot: true`,
      `seccompProfile: { type: RuntimeDefault }`.
- [ ] Add container-level `securityContext`: `allowPrivilegeEscalation: false`,
      `readOnlyRootFilesystem: true`, `capabilities: { drop: ["ALL"] }`.
- [ ] Create a dedicated `ServiceAccount` for api-service instead of using
      `default`; set `automountServiceAccountToken: false` unless the pod
      needs k8s API access.
- [ ] Add a `NetworkPolicy`: default-deny plus explicit allow for the other
      ms3 services it calls (metadata, data, auth) and for ingress traffic.

### Scaling / availability
- [ ] Add a `PodDisruptionBudget` (e.g. `minAvailable: 2` at 3 replicas) so
      node drains/upgrades can't take out all replicas at once.
- [ ] Add `topologySpreadConstraints` or pod anti-affinity to spread
      replicas across nodes/zones.
- [ ] Consider `HorizontalPodAutoscaler` once real traffic/load data exists.
- [ ] Make the `RollingUpdate` strategy (`maxSurge`/`maxUnavailable`)
      explicit rather than relying on defaults.

### Scheduling / lifecycle
- [ ] Add `terminationGracePeriodSeconds` + a `preStop` hook (short sleep)
      so in-flight requests aren't dropped during rolling updates/scale-down.
- [ ] Name the container port (`name: http`) and reference it by name from
      `service.yaml`'s `targetPort` instead of the numeric port.

### Maintainability
- [x] Resolve label duplication: removed hardcoded `app.kubernetes.io/name`/
      `part-of` labels and `matchLabels`/`selector` values from
      `deployment.yaml` and `service.yaml`. `kustomization.yaml`'s `labels`
      transformer (`includeSelectors: true`) is now the single source of
      truth for `metadata.labels`, `Deployment.spec.selector.matchLabels`,
      `Service.spec.selector`, and pod template labels. `selector: {}` is
      kept as a placeholder since kustomize patches into an existing field
      rather than creating one. Verified with `kubectl kustomize` that
      rendered output is unchanged.
- [ ] Pin the image by digest (not just `:v0.1.0` tag) in prod overlays for
      immutability.
