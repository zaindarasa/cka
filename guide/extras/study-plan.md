# 15-day CKAD study plan

> A day-by-day plan built from mined exam-report data (see [exam intel](exam-intel.md) — community-sourced, directional). About 1–2 h per day. Each day maps to this guide's lessons where one exists. Labs run on the kind `lab` cluster from [conventions](../00-conventions.md) (`env/kind-up.sh`); a couple of days note add-ons. Tick `[x]` as you clear each day.

**How to use:**

1. Read the linked lesson, then do the lab idea timed.
2. Every lab ends with VERIFY — `get`, `describe`, `curl`. Done is not scored until verified.
3. Keep the shell setup (`alias k=kubectl`, `export do=...`) from conventions on from day one.
4. Pace target: under 8 min per task, no docs for the common shapes.

| Done | Day | Topic | Guide lessons | Lab idea | Exam weight |
|---|---|---|---|---|---|
| [ ] | 01 | Pods, namespaces, kubectl workflow | [T2.03](../part2-basics/T2.03-pods-in-depth.md), [T2.04](../part2-basics/T2.04-labels-selectors-annotations-and-namespaces.md) | `k run` a pod imperatively; same pod via `$do > f.yaml` + label + env; a two-container pod; fix a bad image without deleting; recreate in a new ns | foundation |
| [ ] | 02 | Deployments, scaling, rollouts | [T3.10](../part3-ckad/T3.10-deployments-and-rolling-updates.md) | Create a deployment, scale it, `k set image`, then `rollout status` / `history` / `undo` | Deployment 20% |
| [ ] | 03 | ConfigMaps + Secrets | [T3.03](../part3-ckad/T3.03-configmaps.md), [T3.04](../part3-ckad/T3.04-create-consume-secrets.md) | Create both from literal and from file; consume via `env`, `envFrom`, `secretKeyRef`; refactor a pod's hardcoded env vars into a Secret — the reported guaranteed question | Config/Sec 25% |
| [ ] | 04 | securityContext, ServiceAccounts, RBAC | [T3.15](../part3-ckad/T3.15-understand-serviceaccounts.md), [T3.16](../part3-ckad/T3.16-understand-authentication-authorization-and-admission-control.md), [T3.17](../part3-ckad/T3.17-understand-application-security-securitycontexts-and-capabilities.md) | Add `runAsUser`/`fsGroup` to a deployment; create an SA, bind a Role, assign the SA to a pod | Config/Sec 25% |
| [ ] | 05 | requests/limits, ResourceQuota | [T3.05](../part3-ckad/T3.05-define-resource-requirements.md), [T3.06](../part3-ckad/T3.06-requests-limits-and-quotas-resourcequota-and.md) | Set requests/limits (limits often = 2× requests); create a ResourceQuota; check usage with `k describe ns` | Config/Sec 25% |
| [ ] | 06 | readiness/liveness probes | [T3.09](../part3-ckad/T3.09-implement-probes-and-health-checks.md) | Add readiness + liveness to a deployment; break a probe, watch the restarts, fix it | Observability 15% |
| [ ] | 07 | Timed review — days 1–6 | — | Redo the day 1–6 labs untimed, from memory; then once more against the clock | — |
| [ ] | 08 | Services: ClusterIP/NodePort, selectors | [T3.12](../part3-ckad/T3.12-provide-and-troubleshoot-access-to-applications.md), [T2.06](../part2-basics/T2.06-services-and-endpointslices-fundamentals.md) | `k expose` ClusterIP and NodePort; fix a service with a wrong selector; confirm with `k get endpoints` | Networking 20% |
| [ ] | 09 | Ingress create + fix | [T3.13](../part3-ckad/T3.13-use-ingress-rules-to-expose-applications.md) | Create an ingress with a hostname + `/` route; then fix a broken one (wrong svc name / port / `pathType`). Needs the traefik add-on (`env/kind-addons.sh traefik`) | Networking 20% |
| [ ] | 10 | NetworkPolicy label-matching | [T3.14](../part3-ckad/T3.14-demonstrate-basic-understanding-of-networkpolicies.md) | With pre-existing policies you cannot edit, label pods to match their selectors; get 3 pods talking | Networking 20% |
| [ ] | 11 | Temp-pod debugging chains | [T3.24](../part3-ckad/T3.24-debugging-in-kubernetes.md), [T3.22](../part3-ckad/T3.22-utilize-container-logs.md), [T3.23](../part3-ckad/T3.23-use-built-in-cli-tools-to.md), [T2.08](../part2-basics/T2.08-events-describe-and-reading-object-status.md) | `k run tmp --rm -it --image=curlimages/curl` to walk svc → netpol → pod chains until "why can't A curl B" is boring. The reported killer skill | cross-cutting |
| [ ] | 12 | Jobs + CronJobs | [T3.02](../part3-ckad/T3.02-choose-and-use-the-right-workload.md) (closest — covers the Job/CronJob decision table and fields) | Create a Job (`completions`, `backoffLimit`) and a CronJob with a schedule + history limits | Design/Build 20% |
| [ ] | 13 | Volumes, sidecar, init | [T3.07](../part3-ckad/T3.07-utilize-persistent-and-ephemeral-volumes.md), [T3.08](../part3-ckad/T3.08-multi-container-pod-patterns-init-sidecar.md) | Two containers sharing an `emptyDir`; an init container gating the main one | Design/Build 20% |
| [ ] | 14 | docker build/save, canary, rollback | [T3.01](../part3-ckad/T3.01-define-build-and-modify-container-images.md), [T3.11](../part3-ckad/T3.11-deployment-strategies-with-primitives-blue-green.md), [T3.10](../part3-ckad/T3.10-deployments-and-rolling-updates.md) | `docker build -t`, tag, `docker save` to tar; split traffic stable/canary via labels + one Service; `rollout undo` | both domains |
| [ ] | 15 | Full timed mock | [exam-intel.md — resources](exam-intel.md) | Run a ~17-question set under a 2 h timer, vi + imperative only, verify everything (Killer.sh session, Killercoda mock, or aravind4799 sets — see the resources section) | everything |

## Companion text — notes.kodekloud.com

Free written notes for the KodeKloud CKAD course (132 lessons), faster than re-watching a video for one concept:
`notes.kodekloud.com/docs/Certified-Kubernetes-Application-Developer-CKAD`

| Day | Read along |
|---|---|
| 01 | Core Concepts → Recap Pods, Pods with YAML, Namespaces |
| 02 | Core Concepts → ReplicaSets, Deployments · POD Design → Rolling Updates/Rollbacks |
| 03 | Configuration → Env Vars, ConfigMaps, Secrets |
| 04 | Configuration → Security Contexts, Service Account · Security section |
| 05 | Configuration → Resource Requirements |
| 06 | Observability → Readiness/Liveness Probes, Logging, Monitoring |
| 08 | Core Concepts → Services, Services ClusterIP · Services & Networking |
| 09 | Services & Networking → Ingress |
| 10 | Services & Networking → Network Policies (+ the "Learn-By-Doing Network Policies" notes) |
| 12 | POD Design → Jobs/CronJobs |
| 13 | Multi-Container Pods · State Persistence |
| 14 | Configuration → Container Images · POD Design → Rollout strategies |

The notes site also covers Helm and Kustomize sections — reports say these are absent from recent exams (see [exam intel](exam-intel.md)), so skip them unless you want the knowledge anyway.

## After day 15

Move to the drill phase from [exam intel](exam-intel.md): mocks on repeat, weakest domains hardest, book when KodeKloud mocks sit at 80%+ consistently.
