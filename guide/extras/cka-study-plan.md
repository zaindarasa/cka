# 7-week CKA study plan

> A week-by-week plan weighted by the official CKA v1.37 domain weights (research summary §1.2): **Troubleshooting 30%, Cluster Architecture, Installation & Configuration 25%, Services & Networking 20%, Workloads & Scheduling 15%, Storage 10%.** It doubles as the CKA-only reading order for this guide: Part 4 is the spine, and earlier parts are pulled in only where a Part 4 lesson needs them. Plan on 19–26.5 lesson-hours per week (summed from [ROADMAP](../ROADMAP.md)) plus timed practice — about 27 h/week all-in. Tick `[x]` as you clear each block.

The exam: 15–20 hands-on tasks in 2 h, pass mark 66%, one SSH host per task (`ssh <node>`, `sudo -i`, exit back to `base`, no nested ssh). Allowed docs: kubernetes.io/docs + /blog, helm.sh/docs and — CKA only — gateway-api.sigs.k8s.io (summary E2, E3, E4, E7, E8, E13). For what pass reports say actually shows up, see [CKA exam intel](cka-exam-intel.md).

**How to use:**

1. Within a week the Part 4 lessons are the deliverable. Read the supporting rows first wherever the concept is new — they are the lessons the Part 4 pages link back to — then do every lab, timed.
2. Lab environments per week come from [conventions §2](../00-conventions.md): `kind` = `env/kind-up.sh`, `vms` = three kubeadm VMs from `env/vm-prereqs.sh`. Weeks 2, 3 and 7 run mostly or entirely on VMs — cluster lifecycle and node troubleshooting need real kubeadm nodes. Weeks 5 and 6 are kind-based but each contains VM-only labs; the week headers name them.
3. Keep the shell setup (`alias k=kubectl`, `export do=...`) from conventions on from week one.
4. Every lab ends with VERIFY — `get`, `describe`, `curl`, `systemctl`, `journalctl`, `crictl`. Done is not scored until verified.
5. Pace target: about 6 min per task on average, no docs for the common shapes (conventions §7).
6. Troubleshooting is 30% of the exam, so it is drilled every week, not only in week 7. From week 2 on, each week has a **Break-fix** row naming tasks from [cka-task-bank](cka-task-bank.md) whose domain matches the week. For each one: run the Setup block, start the timer, fix it, grade it. Have a partner run the break block where the bank offers a fault choice.

## CKA-only reading order

The minimal path through the guide for a CKA-only candidate:

1. **All of Part 4** — T4.01–T4.27. Every lesson maps to a CKA competency; nothing here is optional. T4.02, T4.04 and T4.05 (cluster lifecycle) and T4.25–T4.27 (troubleshooting) carry the most exam weight — see the schedule.
2. **All of Part 2** — T2.01–T2.10. API model, kubectl fluency, Pods, labels, controllers, Services, events, exam environment.
3. **Part 1 subset** — the Linux a CKA candidate actually needs: [T1.01](../part1-linux/T1.01-bash-shell-essentials-for-exam-speed.md) shell speed, [T1.03](../part1-linux/T1.03-vim-and-tmux-for-yaml-editing.md) vim/YAML editing, [T1.06](../part1-linux/T1.06-systemd-and-journalctl.md) systemd + journalctl (kubelet debugging), [T1.07](../part1-linux/T1.07-linux-networking-i-interfaces-ips-routes.md) + [T1.08](../part1-linux/T1.08-linux-networking-ii-dns-ports-sockets.md) Linux networking (CNI/DNS debugging), [T1.12](../part1-linux/T1.12-tls-pki-and-openssl-for-kubernetes.md) TLS/PKI/openssl (cluster certificates), [T1.14](../part1-linux/T1.14-ssh-and-remote-work-across-nodes.md) SSH (the exam is `ssh <node>` + `sudo -i`), [T1.15](../part1-linux/T1.15-packages-kernel-modules-sysctl-swap-and.md) packages/kernel/sysctl/swap (node prep).
4. **Part 3, only where Part 4 links to it** — these 18 lessons and no others: T3.02, T3.03, T3.04, T3.05, T3.06, T3.07, T3.09, T3.10, T3.12, T3.13, T3.14, T3.15, T3.16, T3.18, T3.19, T3.20, T3.22, T3.23. Read each for the prerequisite concept; the admin depth is in the Part 4 lesson that links it.

## What to skip for CKA

- **Part 3 lessons no Part 4 page links to**: T3.01 (image builds), T3.08 (multi-container patterns), T3.11 (blue/green and canary primitives), T3.17 (securityContexts), T3.21 (API deprecations), T3.24 (application debugging — CKA troubleshooting is cluster-, node- and network-level, covered in T4.25–T4.27).
- **The rest of Part 1**: T1.02, T1.04, T1.05, T1.09, T1.10, T1.11, T1.13 — useful background, but no Part 4 lesson requires them.
- **The CKAD extras**: [exam intel](exam-intel.md), the [15-day CKAD plan](study-plan.md) and [practice questions](practice-questions.md) are scoped to the application-developer exam. The CKA equivalents are [cka-exam-intel](cka-exam-intel.md), this file, [cka-task-bank](cka-task-bank.md) and [cka-mock-exams](cka-mock-exams.md).
- Come back to a skipped lesson only if a Part 4 page sends you there.

## Schedule at a glance

| Week | Focus | Exam domain (weight) | Lessons | Timed practice |
|---|---|---|---|---|
| 1 | Exam mechanics + Kubernetes foundations | foundation (all domains) | 20 h | +2 h |
| 2 | Node prep + kubeadm cluster bring-up | Cluster Architecture (25%) | 26 h | +3 h |
| 3 | Cluster lifecycle: upgrades, etcd, certs, HA, RBAC | Cluster Architecture (25%) | 19.5 h | +4 h |
| 4 | Extensions + workloads I | Cluster Arch. + Workloads (15%) | 25 h | +3 h |
| 5 | Config, scheduling + storage | Workloads 15% + Storage 10% | 26.5 h | +3 h |
| 6 | Services & networking | Services & Networking (20%) | 26.5 h | +3 h |
| 7 | Troubleshooting + 3 mocks | Troubleshooting (30%) | 19 h | +9 h |

About 162.5 lesson-hours + 27 practice-hours over 7 weeks — a weekly load of about 27 h including drills.

## Compressed variant (5–6 weeks)

Less time does not mean dropping domains — it means spending less of the week on support reading. Two rules decide what to protect:

- **Protected (do not compress): weeks 2, 3 and 7.** They hold the highest-weight and highest-fail-rate material — kubeadm bring-up, cluster lifecycle, and the troubleshooting/mocks week (Troubleshooting alone is 30%). Skimping here is how people fail at 60%.
- **Compressible: weeks 1, 4, 5 and 6.** The Part 4 lesson rows stay — every one maps to exam competencies — but the Part 1/2/3 support rows become on-demand references: read a support lesson only when the Part 4 page that links it is not already clear, and cut its row's hours to the time you actually needed.

A concrete 6-week cut:

1. **Week 1 → half a week.** Keep T2.02, T2.09, T2.10 and the kubectl-speed timed row. Skim T2.01/T2.03/T2.04 only for gaps; drop the T1.* refreshers you already have (shell, vim).
2. **Weeks 2 and 3: unchanged.** Full hours, full timed rows.
3. **Weeks 4 + 5 → one heavy week.** Do all Part 4 rows (T4.07–T4.16) and both break-fix rows; support rows on demand only. Keep the timed rows.
4. **Week 6: keep, trimmed.** Part 4 rows and the break-fix/timed rows stay; T2.06/T3.12–T3.14 become reference-only.
5. **Week 7: unchanged.** All three mocks.

That lands at about 5.5 weeks of calendar time — extend week 7 by a few days rather than touching weeks 2 or 3 if anything slips.

## Week 1 — Exam mechanics + Kubernetes foundations (`kind`, 20 h + 2 h drills)

| Done | Lessons | h |
|---|---|---|
| [ ] | **Part 4:** none this week — these are the foundations the admin lessons assume | — |
| [ ] | [T2.01](../part2-basics/T2.01-kubernetes-architecture-and-the-api-model.md) architecture + API model · [T2.02](../part2-basics/T2.02-kubectl-fluency-and-productivity.md) kubectl fluency | 7 |
| [ ] | [T2.03](../part2-basics/T2.03-pods-in-depth.md) Pods in depth · [T2.04](../part2-basics/T2.04-labels-selectors-annotations-and-namespaces.md) labels/selectors/namespaces | 5 |
| [ ] | [T1.01](../part1-linux/T1.01-bash-shell-essentials-for-exam-speed.md) shell speed · [T1.03](../part1-linux/T1.03-vim-and-tmux-for-yaml-editing.md) vim for YAML editing | 5 |
| [ ] | [T2.09](../part2-basics/T2.09-local-practice-clusters-kind-and-minikube.md) kind/minikube · [T2.10](../part2-basics/T2.10-exam-environment-docs-navigation-and-time.md) exam environment + docs strategy | 3 |
| [ ] | Timed: [task bank](cka-task-bank.md) — kubectl-speed set: imperative Pod/Deployment/Service generation, `$do` YAML to files, context switching, docs lookups under a timer | 2 |

## Week 2 — Node prep + kubeadm cluster bring-up (`vms`, 26 h + 3 h drills)

| Done | Lessons | h |
|---|---|---|
| [ ] | [T4.01](../part4-cka/T4.01-prepare-underlying-infrastructure-for-a-kubernetes.md) prepare the underlying infrastructure | 3 |
| [ ] | [T4.02](../part4-cka/T4.02-create-and-manage-kubernetes-clusters-using.md) create and manage clusters with kubeadm — highest-fail-rate territory, drill it | 4 |
| [ ] | [T4.03](../part4-cka/T4.03-understand-extension-interfaces-cni-csi-cri.md) extension interfaces: CNI, CSI, CRI | 2.5 |
| [ ] | Support: [T1.15](../part1-linux/T1.15-packages-kernel-modules-sysctl-swap-and.md) packages/kernel/sysctl/swap · [T1.06](../part1-linux/T1.06-systemd-and-journalctl.md) systemd + journalctl | 5 |
| [ ] | Support: [T1.07](../part1-linux/T1.07-linux-networking-i-interfaces-ips-routes.md) + [T1.08](../part1-linux/T1.08-linux-networking-ii-dns-ports-sockets.md) Linux networking I + II · [T1.14](../part1-linux/T1.14-ssh-and-remote-work-across-nodes.md) SSH across nodes | 7.5 |
| [ ] | Support: [T2.05](../part2-basics/T2.05-controllers-replicasets-deployments-basics-and-garbage.md) controllers · [T2.07](../part2-basics/T2.07-declarative-object-management-apply-diff-patch.md) apply/diff/patch | 4 |
| [ ] | Timed: [task bank](cka-task-bank.md) — rebuild the kubeadm cluster from bare VMs (prep → `kubeadm init` → CNI → join `w1`/`w2`) against the clock; repeat until under an hour end to end | 3 |
| [ ] | Break-fix: task bank task 18 — node `w1` `NotReady` (`vms`, 8 min): kubelet disabled, bad kubelet.conf port or containerd stopped. Fix the nodes you just learned to build | (in timed) |

## Week 3 — Cluster lifecycle: upgrades, etcd, certs, HA, RBAC (`vms`, 19.5 h + 4 h drills)

| Done | Lessons | h |
|---|---|---|
| [ ] | [T4.04](../part4-cka/T4.04-manage-the-lifecycle-of-kubernetes-clusters.md) upgrades, etcd backup/restore, certificates, node maintenance — the heaviest single lesson; give it two sessions | 5 |
| [ ] | [T4.05](../part4-cka/T4.05-implement-and-configure-a-highly-available.md) highly-available control plane | 3.5 |
| [ ] | [T4.06](../part4-cka/T4.06-manage-role-based-access-control-rbac.md) RBAC | 3 |
| [ ] | Support: [T1.12](../part1-linux/T1.12-tls-pki-and-openssl-for-kubernetes.md) TLS/PKI/openssl — before the certificate sections of T4.04 | 3 |
| [ ] | Support: [T3.15](../part3-ckad/T3.15-understand-serviceaccounts.md) ServiceAccounts · [T3.16](../part3-ckad/T3.16-understand-authentication-authorization-and-admission-control.md) authn/authz/admission — before T4.06 | 5 |
| [ ] | Timed: [task bank](cka-task-bank.md) — etcd snapshot + restore drill, `kubeadm upgrade` run on `cp1` then a worker, certificate-expiry inspection, drain/uncordon cycle; RBAC create-and-bind set | 4 |
| [ ] | Break-fix: task bank tasks 19 + 20 — broken `kube-scheduler` manifest (Pods `Pending`, no events) and crashed `kube-apiserver` (`vms`, 8 min each): static-pod repair on the control plane this week is about | (in timed) |

## Week 4 — Extensions + workloads I (`kind`, 25 h + 3 h drills)

| Done | Lessons | h |
|---|---|---|
| [ ] | [T4.07](../part4-cka/T4.07-use-helm-and-kustomize-to-install.md) Helm + Kustomize to install cluster components | 2.5 |
| [ ] | [T4.08](../part4-cka/T4.08-understand-crds-install-and-configure-operators.md) CRDs, install and configure operators | 2.5 |
| [ ] | [T4.09](../part4-cka/T4.09-application-deployments-rolling-updates-and-rollbacks.md) rolling updates/rollbacks, admin view · [T4.12](../part4-cka/T4.12-primitives-for-robust-self-healing-application.md) self-healing primitives | 3.5 |
| [ ] | Support: [T3.18](../part3-ckad/T3.18-discover-and-use-resources-that-extend.md) CRDs/operators · [T3.19](../part3-ckad/T3.19-use-helm-to-deploy-existing-packages.md) Helm · [T3.20](../part3-ckad/T3.20-kustomize.md) Kustomize | 7.5 |
| [ ] | Support: [T3.02](../part3-ckad/T3.02-choose-and-use-the-right-workload.md) right workload · [T3.09](../part3-ckad/T3.09-implement-probes-and-health-checks.md) probes · [T3.10](../part3-ckad/T3.10-deployments-and-rolling-updates.md) deployments | 9 |
| [ ] | Timed: [task bank](cka-task-bank.md) — `helm install/upgrade/rollback` a chart + apply a kustomize overlay; workload set: rollout + `rollout undo`, probe fix, self-healing check | 3 |
| [ ] | Break-fix: task bank task 21 — Service `web-svc` refuses connections while all Pods are `Running` (`kind`, 5 min): the self-contained fault is a selector that matches nothing | (in timed) |

## Week 5 — Config, scheduling + storage (`kind`; `vms` for the VM-only parts — encryption at rest in T4.10, static Pods/admission plugins in T4.13, the provisioner install in T4.16 — 26.5 h + 3 h drills)

| Done | Lessons | h |
|---|---|---|
| [ ] | [T4.10](../part4-cka/T4.10-use-configmaps-and-secrets-to-configure.md) ConfigMaps/Secrets admin view incl. encryption at rest · [T4.11](../part4-cka/T4.11-configure-workload-autoscaling.md) autoscaling | 4.5 |
| [ ] | [T4.13](../part4-cka/T4.13-configure-pod-admission-and-scheduling-limits.md) Pod admission and scheduling | 4 |
| [ ] | [T4.14](../part4-cka/T4.14-configure-volume-types-access-modes-and.md) volume types/access modes/reclaim · [T4.15](../part4-cka/T4.15-manage-persistent-volumes-and-persistent-volume.md) PV/PVC · [T4.16](../part4-cka/T4.16-implement-storage-classes-and-dynamic-volume.md) storage classes + dynamic provisioning | 6 |
| [ ] | Support: [T3.03](../part3-ckad/T3.03-configmaps.md) ConfigMaps · [T3.04](../part3-ckad/T3.04-create-consume-secrets.md) Secrets | 4 |
| [ ] | Support: [T3.05](../part3-ckad/T3.05-define-resource-requirements.md) resource requirements · [T3.06](../part3-ckad/T3.06-requests-limits-and-quotas-resourcequota-and.md) requests/limits/quotas | 4.5 |
| [ ] | Support: [T3.07](../part3-ckad/T3.07-utilize-persistent-and-ephemeral-volumes.md) persistent + ephemeral volumes | 3.5 |
| [ ] | Timed: [task bank](cka-task-bank.md) — PV → PVC → Pod chain drill, StorageClass provisioning, ResourceQuota + node-affinity scheduling set | 3 |
| [ ] | Break-fix: task bank task 24 — Deployment `data-app` stuck at 0/2, Pods never scheduled (`kind`, 7 min): the block is an unbound claim on a StorageClass that does not exist — this week's storage + scheduling ground | (in timed) |

## Week 6 — Services & networking (`kind`; `vms` for T4.17/T4.18 — Pod connectivity and Service types need real nodes — 26.5 h + 3 h drills)

| Done | Lessons | h |
|---|---|---|
| [ ] | [T4.17](../part4-cka/T4.17-understand-connectivity-between-pods.md) Pod connectivity · [T4.18](../part4-cka/T4.18-use-clusterip-nodeport-loadbalancer-service-types.md) Service types + endpoints | 5 |
| [ ] | [T4.19](../part4-cka/T4.19-understand-and-use-coredns.md) CoreDNS | 2.5 |
| [ ] | [T4.20](../part4-cka/T4.20-define-and-enforce-network-policies.md) NetworkPolicies · [T4.21](../part4-cka/T4.21-know-how-to-use-ingress-controllers.md) Ingress · [T4.22](../part4-cka/T4.22-use-the-gateway-api-to-manage.md) Gateway API | 8.5 |
| [ ] | Support: [T2.06](../part2-basics/T2.06-services-and-endpointslices-fundamentals.md) Services/EndpointSlices · [T3.12](../part3-ckad/T3.12-provide-and-troubleshoot-access-to-applications.md) access via Services | 5 |
| [ ] | Support: [T3.13](../part3-ckad/T3.13-use-ingress-rules-to-expose-applications.md) Ingress rules · [T3.14](../part3-ckad/T3.14-demonstrate-basic-understanding-of-networkpolicies.md) NetworkPolicies | 5.5 |
| [ ] | Timed: [task bank](cka-task-bank.md) — fix-the-Service set (selector/port/DNS), temp-pod `curl` chains through svc → netpol → ingress, a Gateway API route | 3 |
| [ ] | Break-fix: task bank task 22 — cluster-wide DNS failure (`kind`, 7 min): scaled-to-zero CoreDNS or a mangled Corefile; re-run task 21 afterwards in under 5 min | (in timed) |

## Week 7 — Troubleshooting + mock cadence (`vms` + `kind`, 19 h + 9 h drills/mocks)

| Done | Lessons | h |
|---|---|---|
| [ ] | [T4.25](../part4-cka/T4.25-troubleshoot-cluster-components.md) cluster components · [T4.26](../part4-cka/T4.26-troubleshoot-clusters-and-nodes.md) clusters and nodes · [T4.27](../part4-cka/T4.27-troubleshoot-services-and-networking.md) services and networking — 30% of the exam lives here | 11.5 |
| [ ] | [T4.23](../part4-cka/T4.23-manage-and-evaluate-container-output-streams.md) container output streams · [T4.24](../part4-cka/T4.24-monitor-cluster-and-application-resource-usage.md) resource-usage monitoring | 3 |
| [ ] | Support: [T2.08](../part2-basics/T2.08-events-describe-and-reading-object-status.md) events/describe/status · [T3.22](../part3-ckad/T3.22-utilize-container-logs.md) container logs · [T3.23](../part3-ckad/T3.23-use-built-in-cli-tools-to.md) CLI monitoring | 4.5 |
| [ ] | Timed: [task bank](cka-task-bank.md) mixed break-fix set — re-run the `break.sh` labs from T4.02, T4.04, T4.25, T4.26 and bank tasks 18–20, 23 until each diagnosis takes under 6 min | 3 |
| [ ] | Mock 1 — mid-week, 2 h, one sitting, from [cka-mock-exams](cka-mock-exams.md); same-day review of every miss | 2 |
| [ ] | Mocks 2 + 3 — final two days, 2 h each, docs allowed, no pausing; see the cadence below | 4 |

## Final week — mock-exam cadence (3 mocks)

- **Mock 1 (mid-week):** full 2 h simulator set — the diagnostic. Note every task that ran over ~6 min.
- **Mock 2:** a fresh set, 2 h, exam rules — allowed docs only, no pause, verify every answer.
- **Mock 3:** weakest-domain set, or the second Killer.sh session if your registration includes it (2 attempts, 36 h access each — summary E20). Set lists and scoring sheets: [cka-mock-exams](cka-mock-exams.md).
- Between mocks, re-drill only what the last mock exposed — use the [task bank](cka-task-bank.md) by domain. Book the real exam when two consecutive mocks finish comfortably above the 66% pass mark with time spare.

## VERIFY-LIST — re-run expected outputs during practice

Many lessons still carry blocks labelled `EXPECTED OUTPUT (not captured)` — written and reviewed, but never run on a live cluster. [VERIFY-LIST](../VERIFY-LIST.md) collects every one by environment (linux-vm / kind / vms). Whenever a lab hits one, re-run it on your own cluster or VMs and compare with the printed expectation. Treat it as free extra break-fix practice, not a defect — and if real output differs, the lesson text is what to re-check.
