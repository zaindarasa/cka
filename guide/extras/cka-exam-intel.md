# Exam intel and strategy (CKA)

> **Read this first.** This is the CKA companion to the [CKAD exam intel](exam-intel.md) page — read that one too; the PSI environment, docs rules and time strategy are shared. This page is community-sourced exam intel, mined from pass/fail reports covering exam attempts from Feb 2025 (the big curriculum refresh) to mid-2026. It is **not** verified exam fact. The exam's contents are confidential (candidates sign an NDA) and change over time. Treat everything here as directional advice: where to spend practice time, not a promise of what you will see. For authoritative facts — rules, logistics, curriculum — use the official sources linked at the bottom, not this page. Exam facts that could not be confirmed are marked **UNVERIFIED**, per [conventions](../00-conventions.md) §5.

## 1. The exam shape — confirmed vs reported

Confirmed by official Linux Foundation pages (collected in [research summary](../inputs/00-research-summary.md) §2 — the row number is given so you can check it):

| Fact | Status |
|---|---|
| 2 hours, online, remotely proctored (PSI Secure Browser), performance-based tasks on a Linux command line | confirmed — summary E1, E3, E25 |
| "The exams consist of 15-20 performance-based tasks" | confirmed — summary E2 |
| Pass mark 66%; scored automatically; results emailed within 24 hours | confirmed — summary E4, E5 |
| Each task is done on a **designated host**: an infobox gives `ssh <nodename>`, `sudo -i` gives root, `exit` returns to host `base`, nested ssh is not supported | confirmed — summary E7, E8 |
| Exam hosts provide kubectl with an alias and bash completion, `yq`, `curl`, `wget`, `man`. `jq` is **not** guaranteed — use `-o jsonpath` | confirmed — summary E9 (exact alias name UNVERIFIED) |
| Allowed in the browser tab: `kubernetes.io/docs`, `kubernetes.io/blog`, `helm.sh/docs`, task-linked "Quick Reference" docs, and — **CKA only** — `gateway-api.sigs.k8s.io` | confirmed — summary E13 |
| Timer alerts at 30, 15 and 5 minutes; "Pause Exam" does not stop the timer; lost time after a disconnect is not added back | confirmed — summary E12 |
| One retake included; Killer.sh simulator: 2 sessions × 36 h, 17 questions per session (not included with CKA-SINGLE registrations) | confirmed — summary E18, E20 |

Reported by candidates, not confirmed by any official page:

- **Task count per sitting:** reports say 16–17 tasks, inside the official 15–20 range. Your exact number is UNVERIFIED until you sit it.
- **Kubeconfig context per task:** reports describe each task pinning both a host *and* a kubectl context (`k config use-context <name>` in the task header or already switched). The official pages confirm the host part only; the number of clusters/contexts is UNVERIFIED (summary E21). Wrong-host or wrong-context work cannot be graded — the checker only looks at the designated target, and nothing warns you. Re-read the context line twice, every task.
- **No answer checker.** There is no submit-and-verify button; scoring happens after the exam ends (E5). `k get`, `k describe`, `systemctl status`, `curl` from a temp pod and `k get nodes` showing `Ready` at the right version are your only graders.
- **Partial credit:** one 92% report says creating the required resources earns partial points even when the task is not fully working. UNVERIFIED — but it means: always leave *something* correct behind, never leave a task blank.
- **Click-to-copy:** the PSI question panel lets you click resource names to copy them. Reports recommend this over typing odd names (`spline-reticulator`-style) — a typo'd name or namespace scores zero.
- **Breaks:** one report's proctor allowed short breaks; another's UI makes leaving mid-task awkward. Treat the exam as a 2-hour sprint; do not plan on a break.
- **Per-task weighting:** older reports describe a percentage shown per task. Whether tasks are weighted differently in the current version is UNVERIFIED — flag-and-skip either way.

## 2. Where the points are

Official domain weights, v1.37 curriculum ([summary](../inputs/00-research-summary.md) §1.2, from `CKA_Curriculum_v1.37.pdf` on github.com/cncf/curriculum):

| Domain | Weight | Guide lessons | What the weight means |
|---|---|---|---|
| Troubleshooting | **30%** | T4.23–T4.27 | The single biggest lever. Roughly a third of your score is "something is broken — find it and fix it": dead kubelet, broken static pod, bad kubeconfig, service with no endpoints, DNS that doesn't resolve. Speed at *diagnosis* (not just fixing) is the skill. |
| Cluster Architecture, Installation & Configuration | **25%** | T4.01–T4.08 | kubeadm cluster lifecycle, RBAC, Helm/Kustomize installs, CRDs/operators, CNI/CRI/CSI awareness, HA concepts. Heavy on node-level work: ssh, sudo, systemd, packages. |
| Servicing and Networking *(the PDF's spelling)* | **20%** | T4.17–T4.22 | Pod connectivity, Service types/EndpointSlices, CoreDNS, NetworkPolicy, Ingress **and** Gateway API (CKA-only curriculum item — and its docs site is CKA-only in the exam too). |
| Workloads and Scheduling | **15%** | T4.09–T4.13 | Rollouts/rollbacks, ConfigMaps/Secrets consumption, autoscaling (HPA), self-healing primitives, Pod admission and scheduling (requests/limits, affinity, PriorityClass, taints/tolerations). |
| Storage | **10%** | T4.14–T4.16 | PV/PVC, access modes, reclaim policies, StorageClasses and dynamic provisioning. Smallest slice — but PVs can't be created imperatively, so drill the YAML shape. |

**Strategy math:** Troubleshooting + Cluster Architecture = **55%** of the paper. Weak node-level skills are the most expensive weakness you can have. At a 66% pass mark you can afford to completely skip about a third of the tasks — so bank the fast ones first (RBAC, NetworkPolicy, PV/PVC, drain/uncordon, rollout ops) and flag the slow ones (upgrade, etcd restore, multi-layer break-fix).

## 3. What shows up (task types, as reported)

Frequency is what candidates reported across sittings — not an official syllabus, and one person's sitting is a small sample. Absent from one report means nothing; several reports include "topics I did *not* get" lists that contradict each other.

### 3.1 Classic task types (reported for years, still worth muscle memory)

| Task type | How reports describe it | Guide lesson | Reported frequency |
|---|---|---|---|
| Node NotReady / broken kubelet | A node is `NotReady`; ssh in, `systemctl`/`journalctl` the kubelet, fix config/cert/CNI, `enable --now` | [T4.26](../part4-cka/T4.26-troubleshoot-clusters-and-nodes.md) | Nearly every sitting in older reports; still reported |
| Broken control plane / static pods | `kubectl` dead → `crictl ps -a`, fix a manifest or kubeconfig under `/etc/kubernetes`, wait for the static pod to come back | [T4.25](../part4-cka/T4.25-troubleshoot-cluster-components.md) | Very common — the core of the 30% domain |
| Service/networking troubleshooting | App can't reach app: selector/endpoint/DNS/NetworkPolicy/kube-proxy hunt | [T4.27](../part4-cka/T4.27-troubleshoot-services-and-networking.md) | Common |
| etcd snapshot save + restore | `etcdctl snapshot save` with TLS flags read from `etcd.yaml`; restore via `etcdutl` + repoint the etcd `hostPath` | [T4.04](../part4-cka/T4.04-manage-the-lifecycle-of-kubernetes-clusters.md) | The classic CKA task for years — **but see the caveat below** |
| kubeadm cluster upgrade | `kubeadm upgrade plan/apply` on cp, `upgrade node` + kubelet/kubectl packages + drain/uncordon on workers | [T4.04](../part4-cka/T4.04-manage-the-lifecycle-of-kubernetes-clusters.md) | Same caveat below |
| Drain / cordon / uncordon | Drain a node for maintenance, uncordon after | [T4.04](../part4-cka/T4.04-manage-the-lifecycle-of-kubernetes-clusters.md), [T4.26](../part4-cka/T4.26-troubleshoot-clusters-and-nodes.md) | Common, usually embedded in the upgrade task |
| RBAC | Create ServiceAccount + Role/ClusterRole + binding; often "give X permission to do Y in namespace Z" | [T4.06](../part4-cka/T4.06-manage-role-based-access-control-rbac.md) | Common |
| PV/PVC + StorageClass | Create a PV with given capacity/access mode/reclaim policy, a PVC that binds it, mount in a Pod; set a default StorageClass | [T4.14](../part4-cka/T4.14-configure-volume-types-access-modes-and.md), [T4.15](../part4-cka/T4.15-manage-persistent-volumes-and-persistent-volume.md), [T4.16](../part4-cka/T4.16-implement-storage-classes-and-dynamic-volume.md) | Common — storage is only 10% but usually quick points |
| NetworkPolicy | Allow/deny traffic between specific pods/namespaces via podSelector + ingress/egress rules | [T4.20](../part4-cka/T4.20-define-and-enforce-network-policies.md) | Common |
| Ingress | Create an Ingress for a host/path → existing Service | [T4.21](../part4-cka/T4.21-know-how-to-use-ingress-controllers.md) | Common |
| CoreDNS | Fix or customize CoreDNS (Corefile via the `coredns` ConfigMap — restart needed), debug cluster DNS | [T4.19](../part4-cka/T4.19-understand-and-use-coredns.md) | Occasional reports |
| Sidecar / multi-container | Add a second container (e.g. logging) to an existing deployment via `k edit` | [T3.08](../part3-ckad/T3.08-multi-container-pod-patterns-init-sidecar.md), [T4.12](../part4-cka/T4.12-primitives-for-robust-self-healing-application.md) | Reported; YAML-editing speed is the risk, not the concept |
| Certificates / TLS context | `kubeadm certs check-expiration`, inspect a cert with `openssl`, fix a kubeconfig's server/user | [T4.04](../part4-cka/T4.04-manage-the-lifecycle-of-kubernetes-clusters.md), [T1.12](../part1-linux/T1.12-tls-pki-and-openssl-for-kubernetes.md) | Embedded in troubleshooting tasks |

### 3.2 Post-refresh task types (Feb 2025+ curriculum — the newer reports)

The Feb 18, 2025 refresh (summary §4.1, [program changes](https://training.linuxfoundation.org/certified-kubernetes-administrator-cka-program-changes/)) added Gateway API, Helm, Kustomize, CRDs/operators, autoscaling and extension interfaces, and stopped *naming* "etcd backup/restore" and "kubeadm upgrade" (the guide still teaches both under "Manage the lifecycle", [T4.04](../part4-cka/T4.04-manage-the-lifecycle-of-kubernetes-clusters.md) — that's the guide's inference, not official wording). A June 2026 report notes etcd maintenance was dropped from the syllabus; an Aug 2025 92%-scorer reports encountering **none** of etcd, kubeadm upgrade, RBAC, CoreDNS, Kustomize or affinity — while other reports describe RBAC-style tasks. Treat the classic tasks as "still possible, still taught, no longer named".

| Task type | How reports describe it | Guide lesson | Reported frequency |
|---|---|---|---|
| Helm: repo add, template, install, troubleshoot | Add a repo, render with `helm template` (+ specific `--version`/`--set`), `k apply -f` the output or `helm install`; one report needed a broken install debugged — plain `helm install` errors were part of the task | [T4.07](../part4-cka/T4.07-use-helm-and-kustomize-to-install.md) | Multiple independent reports — treat as likely |
| CNI install on a kubeadm cluster | Install a CNI that supports NetworkPolicy (Calico over Flannel in the reported case), with the cluster's pod CIDR; verify pods schedule | [T4.02](../part4-cka/T4.02-create-and-manage-kubernetes-clusters-using.md), [T4.03](../part4-cka/T4.03-understand-extension-interfaces-cni-csi-cri.md) | Multiple reports |
| Container runtime install | Install/configure containerd (or another CRI) on a node — *not* kubeadm itself | [T4.01](../part4-cka/T4.01-prepare-underlying-infrastructure-for-a-kubernetes.md) | Multiple reports |
| Gateway API | Gateway + HTTPRoute to expose a Service; one report needed a TLS cert reference variant not in kubernetes.io examples — solvable via `gateway-api.sigs.k8s.io` (CKA-allowed docs); another report described migrating an Ingress to Gateway keeping TLS | [T4.22](../part4-cka/T4.22-use-the-gateway-api-to-manage.md) | Multiple reports — a signature post-refresh ask |
| CRDs / operators | List/filter CRDs with kubectl pipelines (`get crd \| grep \| awk \| xargs` was one reported shape); install an operator | [T4.08](../part4-cka/T4.08-understand-crds-install-and-configure-operators.md), [T4.23](../part4-cka/T4.23-manage-and-evaluate-container-output-streams.md) | Several reports |
| HPA / PriorityClass / scheduling | `k autoscale` an HPA on a deployment; PriorityClass for scheduling/eviction order; requests/limits that let a pending pod schedule | [T4.11](../part4-cka/T4.11-configure-workload-autoscaling.md), [T4.13](../part4-cka/T4.13-configure-pod-admission-and-scheduling-limits.md) | Several reports |
| Cluster install with custom settings | kubeadm init/join with required modifications (e.g. specific pod CIDR or config), reported from the 2025 beta | [T4.02](../part4-cka/T4.02-create-and-manage-kubernetes-clusters-using.md) | Reported |
| Taints on a small cluster | Pods won't schedule because every node is tainted — a single-node control-plane cluster in one report blocked quick "test it works" pod runs | [T4.13](../part4-cka/T4.13-configure-pod-admission-and-scheduling-limits.md), [T4.26](../part4-cka/T4.26-troubleshoot-clusters-and-nodes.md) | Single report — 30-second `describe node` check |
| Output formatting | `jsonpath`, `--sort-by`, `-o wide` to extract and record specific fields to a file | [T4.23](../part4-cka/T4.23-manage-and-evaluate-container-output-streams.md), [T2.02](../part2-basics/T2.02-kubectl-fluency-and-productivity.md) | Embedded in other tasks |

**Priority if short on time**, synthesized from the reports:

1. Node/cluster break-fix reflexes (T4.25–T4.27) — it's 30% and it's the domain where slow diagnosis burns the most clock.
2. The kubeadm lifecycle bundle: drain → upgrade → etcd → certs (T4.04). Slow tasks; start them early.
3. Helm install/template/troubleshoot + CNI/runtime install (T4.01, T4.02, T4.07) — the post-refresh topics the reports keep naming.
4. Gateway API + Ingress + NetworkPolicy (T4.20–T4.22).
5. The quick banks: RBAC, PV/PVC, drain/uncordon, HPA, output formatting.

## 4. Clusters, contexts and hosts — what is actually known

- **Confirmed (summary E7):** every task names a designated host; you `ssh <node>` to it, `sudo -i` for root, and `exit` back to `base` when done. No nested ssh.
- **UNVERIFIED (summary E21):** how many clusters or kubeconfig contexts the environment has. Official pages do not publish it.
- **Reported:** tasks pin a kubectl context as well as a host; candidates describe `k config use-context <name>` lines in task headers and context switches between tasks. One candidate reports losing an attempt's momentum partly to not changing context between tasks.

**Discipline regardless of the exact setup** — costs seconds, protects whole tasks:

```bash
k config get-contexts          # what exists
k config current-context       # where am I now
k config use-context <name>    # go where the task header says
k get nodes                    # do the node names match this task's cluster?
```

Then, per task: `ssh` to exactly the host the infobox names → `sudo -i` when you need root → do the work → `exit` to `base`. If a task's header names both a context and a node, set the context **first**, then ssh — and assume every `kubectl` you run afterwards is aimed at whatever that context points at.

## 5. Speed tactics for admin tasks

- **The alias is already there.** Exam hosts ship kubectl with an alias and bash completion (summary E9 — the page says "kalias"; the exact name is UNVERIFIED, reports say `k` works). Per-report advice: don't burn time hand-crafting aliases that evaporate on the next `ssh`. Do still set the two exports that carry over in one line: `export do="--dry-run=client -o yaml"` and `export now="--force --grace-period=0"` — and re-export them after each `sudo -i`, because root gets a fresh shell.
- **Imperative first, YAML by exception.** Same rule as CKAD, but the admin generators differ:

```bash
k drain w1 --ignore-daemonsets --delete-emptydir-data
k cordon w1 / k uncordon w1
k create rolebinding rb --role=r --serviceaccount=ns:sa -n ns
k create clusterrolebinding crb --clusterrole=cr --serviceaccount=ns:sa
k autoscale deploy web --min=2 --max=8 --cpu-percent=70
k create ingress in --rule="h.com/app*=svc:80" --class=traefik
k create quota q --hard=pods=10 $do > q.yaml
kubeadm token create --print-join-command      # join a worker
kubeadm certs check-expiration                 # cert audit in one shot
```

  There is no generator for `PersistentVolume`, `StorageClass`, `NetworkPolicy`, `Gateway`/`HTTPRoute` or `PriorityClass` — those you copy from the allowed docs and edit. Have the doc page per kind already bookmarked.
- **`etcdctl` vs `etcdutl` — know which tool touches what.** On etcd ≥3.6 (the exam runs Kubernetes v1.37, whose kubeadm bundles etcd 3.7): `etcdctl snapshot save` talks to a *running* etcd and needs endpoint + `--cacert/--cert/--key` — read all four values out of `/etc/kubernetes/manifests/etcd.yaml`, don't type them from memory. `snapshot status` and `snapshot restore` were removed from `etcdctl` in etcd 3.6 — they live in **`etcdutl`**, which works on the file/data-dir offline with no TLS flags. Whether either binary is on an exam host's PATH is UNVERIFIED (exam host details aren't published, summary E22): run `which etcdctl etcdutl` first; the fallback is `k exec -n kube-system etcd-<node> -- etcdctl …` writing into a host-mounted dir. Full walk-through: [T4.04](../part4-cka/T4.04-manage-the-lifecycle-of-kubernetes-clusters.md).
- **systemd is a scoring surface, not plumbing.** `systemctl status kubelet`, `journalctl -u kubelet -n 50 --no-pager`, `systemctl restart kubelet`, and — the classic half-fix — `systemctl enable --now kubelet` so the fix survives a reboot. Practice these until they're one gesture each; they're guaranteed-useful on any node task and they exist on every systemd host regardless of what else is installed (unlike `crictl`, `etcdctl`, `jq` — presence UNVERIFIED, check with `which`).
- **Static-pod editing protocol.** Back up to `/root` (`cp … /root/x.bak`), never leave `.bak` files inside `/etc/kubernetes/manifests` — the kubelet reads *every* file there. After editing a manifest, wait for the kubelet's rescan; after editing a kubeconfig a component uses, `crictl stop` the container — no manifest change means no restart.
- **`crictl` is your dead-apiserver flashlight.** `kubectl` dead → `systemctl is-active kubelet` → `crictl ps -a | grep -E 'apiserver|etcd|scheduler|controller'` → `crictl logs <id>`. Then `curl -sk https://localhost:6443/readyz?verbose | tail -1` for a kubeconfig-free health check.
- **Pre-bookmark these allowed-doc pages** (all inside the E13 allow-list):

```
kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/
kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-certs/
kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/
kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/
kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
kubernetes.io/docs/setup/production-environment/tools/kubeadm/troubleshooting-kubeadm/
kubernetes.io/docs/tasks/debug/debug-cluster/
kubernetes.io/docs/tasks/debug/debug-application/debug-service/
kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/
kubernetes.io/docs/concepts/services-networking/network-policies/
kubernetes.io/docs/concepts/storage/persistent-volumes/
kubernetes.io/docs/tasks/configure-pod-container/static-pod/
kubernetes.io/docs/reference/kubectl/quick-reference/
gateway-api.sigs.k8s.io/guides/            (CKA only)
helm.sh/docs/                              (chart install/template/troubleshooting)
```

- **Start the slow tasks early.** Node work is slow work: package downloads, image pulls, static-pod restarts. If a task has a waiting phase (an upgrade, an etcd pod coming back), kick it off, flag it, bank a fast task, come back and verify. Reports describe exactly this "don't watch the pot" play.
- **`k explain` beats doc-diving for fields.** `k explain networkpolicy.spec.ingress`, `k explain pv.spec`, `k explain httproute.spec.rules` — the shape without leaving the terminal.
- **Verify like the checker would.** `k get nodes` shows the right version and `Ready`, not `SchedulingDisabled`. `k get endpoints <svc>` non-empty. `curl` the thing from a pod. Then, and only then, move on — a compound outage hides the second fault behind the first.
- **Time:** ~6 min/task average over 15–20 tasks (E2/E3); per-report pacing is ~7.5 min with a flag-and-return pass. A node fix that has produced no error line after ~8 min is pointing at the wrong layer — go back to the symptom.

## 6. Why people fail (reported failure modes)

| Reported result | Root cause | Defense |
|---|---|---|
| 41 → 47 → 65 → 81 over four sittings | Wrote YAML from scratch out of the docs — "too declarative"; burned clock on syntax errors | Go imperative wherever a generator exists; YAML only where none does. His imperative switch was worth +18 points in 6 days |
| Same candidate, exam 2 | Verification panic: Ingress returned no 200, he deleted and rebuilt the Service, still broken, −15 min | Verify first, fix the *found* cause, never rebuild blindly. A working-looking fix for the wrong layer scores nothing |
| "Sidecar hell" | `k edit deployment` + sidecar YAML kept failing on save under pressure — the *edit*, not the concept | Drill `k edit` + multi-container YAML until it's boring; `k set`/`k patch` where they reach |
| 50% fail | Post-refresh topics the mocks hadn't covered: Helm template-then-install, CNI install on a tainted single-node cluster, a Gateway TLS variant missing from kubernetes.io examples, a CRD listing needing a `grep/awk/xargs` pipeline | The Feb-2025 refresh is real and mocks lag it. Cover Helm/Kustomize/Gateway/CNI/CRD install paths yourself; know `gateway-api.sigs.k8s.io` is allowed |
| Failed first try | ~40% of tasks outside what course + mocks covered (Helm troubleshoot, ArgoCD-style install, runtime install) | Same as above — and the follow-up post in that thread: 57% → 90% after two passes through free Killercoda practice exams |
| Time expired with questions left (2025 beta tester) | Dwelt on single questions; didn't know per-task "Quick Reference" doc links existed | Flag-and-skip discipline; check each task's own doc links — they're allowed on top of the base list (E13) |
| Lost minutes at check-in | PSI environment surprises: terminal hidden behind the browser window, laggy input, a macOS `SideCarRelay`/Bluetooth block | Check in 30–45 min early; kill non-essential apps; wired peripherals; expect the remote desktop to feel worse than your machine |
| Killer.sh panic | Scored ~30% on the simulator and nearly gave up | Reports consistently put Killer.sh *harder* than the real thing (it's designed to over-prepare). Use it for UI rehearsal and solution review, not as a pass/fail oracle |
| Breadth surprises | CKA spans the whole cluster, not just workloads — one report lists jumping between deployments, PriorityClasses, storage, Ingress, ConfigMaps, Helm, CRDs, HPA and Gateway in a single sitting | Depth in two domains won't carry 66%. Get "can do it slowly" coverage of all 27 competencies, then speed in the heavy three |

## 7. Resources passers credited (community-reported, none official)

| Resource | Cost | Signal from reports |
|---|---|---|
| KodeKloud "Certified Kubernetes Administrator" (Mumshad, Udemy) + its mock exams | ~$12 on sale | Used by nearly every fetched report. Caveat, reported: the course/mocks initially lagged the Feb-2025 refresh; reported updated for it since ~Apr 2025 — verify your copy covers Helm, Kustomize, Gateway API |
| Killer.sh (2 sessions bundled with the exam registration — not with CKA-SINGLE) | included | Official simulator (summary E20): same-style PSI-like UI, 17 questions/session, 36 h each. Most reports: harder than the real exam. Book it late as a dress rehearsal; review solutions, don't just score it |
| Killercoda free CKA scenarios | free | The 57%→90% turnaround report credits two passes through the free practice exams; other reports name the community scenario sets for drilling |
| kubernetes.io docs navigation practice | free | Reports repeatedly credit "knowing where things live in the docs" over memorizing YAML — build the bookmark set in §5 while practicing |
| Kubernetes the Hard Way | free | Optional depth: one 95% report used it to internalize PKI/etcd/control-plane wiring; called it valuable but not mandatory |
| Real kubeadm VMs for practice | your lab | Node tasks need real systemd/ssh/`sudo -i`. The guide's 3-VM `cp1/w1/w2` setup ([conventions](../00-conventions.md) §2.3, `env/vm-prereqs.sh`) mirrors the exam's shape far better than kind for Part 4 topics |

## 8. Exam-day checklist

- [ ] Check in 30–45 min early — PSI issues are the most-cited day-of problem (ID, room scan, blocked processes, chat-only support)
- [ ] One monitor only (dual not supported, summary E25), clean desk, covered glass, stable power + internet, backup hotspot, wired keyboard/mouse handy
- [ ] Kill everything non-essential before launch — one report lost ~30 min to a macOS background process the PSI browser refused
- [ ] First thing per task: read the host + context line twice → `ssh <node>` → `k config current-context` sanity check → `sudo -i` if root needed
- [ ] Re-export `do`/`now` after every `sudo -i`; Ctrl+Shift+C/V for paste; INSERT key is prohibited (summary E10)
- [ ] Copy names by clicking them in the task panel, never by typing
- [ ] Bank fast tasks first (RBAC, NetPol, PV/PVC, drain, formatting); flag upgrades/etcd/deep break-fix for a second pass — and kick their slow phases off before you leave them
- [ ] ~7.5 min/task pacing; if nothing actionable after ~8–10 min, flag and move — a skipped task still beats three unattempted ones
- [ ] `which crictl etcdctl etcdutl` before assuming tools exist; `jsonpath` not `jq`
- [ ] Verify each fix on the designated host/context (`get`/`describe`/`curl`/`Ready`), then `exit` back to `base`
- [ ] Leave 15–20 min for flagged tasks; the 30/15/5-min alerts are real (E12) and "Pause Exam" does not pause anything
- [ ] Don't leave litter: no cordon left behind, no stray files in `/etc/kubernetes/manifests`, no debug pods
- [ ] Last Killer.sh session the day before for UI muscle memory; then sleep

## 9. If attempt 1 fails

One retake is included with the registration (summary E18). The result email arrives within ~24 h (E5) and — as reported — breaks your score down by domain: that breakdown is your drill list, and Troubleshooting+Cluster-Architecture misses cost the most. Fetched second-attempt reports: 57%→90% after two passes of Killercoda practice exams; 41→47→65→81 by switching to imperative workflows and fixing exactly one failure mode per attempt. Whether questions overlap between attempts is UNVERIFIED — but the *types* in §3 recur constantly across reports, so re-drilling the types you fumbled is a good bet either way. Rebook while the misses are still fresh; the 12-month voucher window (E18) is not the constraint, your memory of what went wrong is.

## 10. The daily loop (TL;DR)

```
1. Pick a task type from §3 (start with the 30% troubleshooting domain)
2. Do it on a real kubeadm VM or cluster: ssh → sudo -i → fix/create → verify
3. Time it. Target <6-8 min, no docs for the common shapes
4. Redo the ones that broke until the path is reflex, not recall
5. Weekly: one timed mixed set (upgrade + break-fix + create-type + network)
6. Consistently finishing sets inside 2h with verification → book the exam
```

## Sources

**Official (authoritative — use these for rules and logistics; verified in [inputs/00-research-summary.md](../inputs/00-research-summary.md) §1–2):**

- LF certification tips for CKA/CKAD (hosts, ssh, tools, shortcuts): https://docs.linuxfoundation.org/tc-docs/certification/tips-cka-and-ckad
- LF CKA/CKAD/CKS FAQ (duration, pass mark, scoring, version, retake, simulator): https://docs.linuxfoundation.org/tc-docs/certification/faq-cka-ckad-cks
- LF allowed resources during the exam: https://docs.linuxfoundation.org/tc-docs/certification/certification-resources-allowed
- LF candidate handbook — exam UI (terminal, Firefox, VSCodium, timer alerts): https://docs.linuxfoundation.org/tc-docs/certification/lf-handbook2/exam-user-interface/examui-performance-based-exams.md
- CNCF curriculum repo (`CKA_Curriculum_v1.37.pdf` — domains and weights): https://github.com/cncf/curriculum
- LF CKA product page (price, attempts, validity): https://training.linuxfoundation.org/certification/certified-kubernetes-administrator-cka/
- LF CKA program-changes page (Feb 2025 refresh): https://training.linuxfoundation.org/certified-kubernetes-administrator-cka-program-changes/

**Community reports actually consulted for this page** (fetched 2026-10; all personal accounts, NDA-bound so they describe types and strategy, not real questions):

- "I passed the CKA (February 2025 Changes)" — 17 tasks, 78%, post-refresh difficulty + ~100 h prep (Jun 2025): https://nattapol.com/i-passed-the-cka-february-2025-changes/
- "Certified Kubernetes Administrator (CKA)" — 92%, 16 questions, detailed topic in/out lists incl. no etcd/upgrade/RBAC/CoreDNS in his sitting (Aug 2025): https://shevtsod.com/blog/250830-certified-kubernetes-administrator
- "I passed the CKA! My Exam Experience (2026)" — ~16 questions, 95%, whole-syllabus breadth incl. Helm/CRDs/Gateway; notes etcd maintenance removed from the syllabus; "aliases are already set, don't bother" (Jun 2026): https://dcassisi.com/2026/06/09/i-passed-the-cka-my-exam-experience-2026/
- KodeKloud community: "Just took the latest version of the CKA exam, failed miserably, need some advice" — post-refresh coverage gaps (Helm template/troubleshoot, runtime install); reply reports 57%→90% via Killercoda free exams (Mar 2025): https://kodekloud.com/community/t/just-took-the-latest-version-of-the-cka-exam-failed-miserably-need-some-advice/474751
- KodeKloud community: "CKA exam 2025 — few thoughts after taking killer.sh exams" — 50% fail with named weak spots (Helm install pipeline, CNI on a tainted single node, Gateway TLS variant, CRD listing pipeline); Killer.sh-much-harder-than-exam consensus (Aug–Nov 2025): https://kodekloud.com/community/t/cka-exam-2025-few-thoughts-after-taking-killer-sh-exams/482003
- "I Didn't Pass the CKA by Studying Harder. I Passed by Debugging Smarter." — 41→47→65→81 over four sittings; imperative-over-declarative breakthrough; PSI navigation pitfalls (Feb 2026): https://cromyhector.medium.com/i-didnt-pass-the-cka-by-studying-harder-i-passed-by-debugging-smarter-a945c27d0c09
- "Thoughts on taking the Kubernetes CKS and beta CKA exams in 2025" — beta-tested the refreshed CKA: tighter time crunch than CKS, per-task doc links, cluster-install-with-modifications task shape, PSI/macOS pitfalls (Feb 2025): https://bargenqua.st/posts/cks-cka-2025/

**Where to mine more reports yourself:** the communities candidates keep pointing at are Reddit's r/CKA, r/CKAExam (recommended by name in the shevtsod report) and r/KubernetesCerts, plus the KodeKloud community forum. Reddit threads could not be fetched from the machine this page was written on, so no individual thread is linked — read recent pass/fail reports there yourself, newest first, and weight post-Feb-2025 reports over older ones.

*Everything on this page is community-sourced and directional. The exam changes; the NDA means no report can tell you the real questions. When this page disagrees with an official LF/CNCF page, the official page wins.*
