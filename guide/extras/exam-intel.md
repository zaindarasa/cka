# Exam intel and strategy (CKAD)

> **Read this first.** This page is community-sourced exam intel, mined from 60+ Reddit pass/fail reports (r/ckad, r/KubernetesCerts, r/devops, r/platformengineering) covering exam attempts from Dec 2025 to Feb 2026. It is **not** verified exam fact. The exam's contents are confidential and change over time. Treat everything here as directional advice: where to spend practice time, not a promise of what you will see.

## 1. The exam shape, as reported

- Pass mark reported at **66%**, about 17 tasks in 2 hours, one free retake.
- Remote proctored via PSI. `docs.kubernetes.io` (docs + blog) is allowed in the browser tab.
- Each task is its own SSH session with its own kubeconfig context. Wrong-context work scores zero and nobody tells you.
- There is no answer-checker. `get`, `describe`, `rollout status` and `curl` from a temp pod are the only grader.

## 2. What shows up (consensus across pass reports)

Frequency is what passers reported seeing, not an official syllabus.

| Topic | How it's asked | Reported frequency |
|---|---|---|
| Secrets / env vars | Replace hardcoded env values with `secretKeyRef`; move pod env vars into a Secret | Nearly every exam |
| Ingress | Fix a broken Ingress (wrong svc name / port / `pathType`) AND create one with a hostname + `/` or `/app` route | ~2 questions |
| NetworkPolicy | 4 policies pre-exist and may NOT be edited; label pods to match selectors, connect 3 pods | 1–2 |
| Resources | Fix requests/limits (limits often = 2× requests); fix or create a ResourceQuota; `k describe ns` shows quota | 1–2 |
| RBAC / ServiceAccount | Read pod logs → find the missing permission → create SA, bind the right role, assign to the pod | 1 (newer exams) |
| Canary deployment | Split traffic between a stable and a canary deployment via labels + one Service | 1 (newer exams) |
| Probes | Add readiness (and sometimes liveness) to a deployment | 1 |
| Docker | `docker build -t`, tag, `docker save` to tar/OCI — the save path is given | 1 |
| Services | Fix a broken selector; create a NodePort | 1–2 |
| CronJob | Create with a schedule + history limits | 1 |
| securityContext | Add `runAsUser` / `fsGroup` / `capabilities` to a deployment | 1 |
| Rollouts | Edit a deployment, `rollout undo`; scale + label pods | 1 |
| Temp-pod debugging | `k run tmp --rm -it --image=curlimages/curl` to test svc / ingress / netpol | Embedded everywhere |

**Reported absent** (multiple independent reports — reallocate this time): CRDs, Helm, Kustomize, PV/PVC provisioning, StatefulSet, DaemonSet, LimitRange, custom controllers, cluster admin (etcd/kubeadm — that is CKA territory).

**Priority if short on time**, per the reports:

1. Secrets/env refactor → Ingress fix+create → NetPol labeling → Resources/Quota → probes. The "guaranteed five".
2. Canary, RBAC-from-logs, `docker save`. Newer common asks.
3. Everything else.

## 3. Resources that correlate with passing

Ranked by how often passers credited them. No resource here is official.

| Priority | Resource | Cost | Signal |
|---|---|---|---|
| 1 | **KodeKloud CKAD** (Mumshad, Udemy) | ~$12 on sale | Used by virtually every passer. The labs matter more than the videos. Then their Ultimate Mock Exam Series + Lightning Labs on repeat. |
| 2 | **github.com/aravind4799/CKAD-Practice-Questions** | free | Multiple passers: "most of my questions were the same as this repo", "incredibly close to the real exam". Closest to real exam phrasing. Drill until reflex. |
| 3 | **Killercoda** scenarios | free | Browser k8s playground, no setup. The omkar-shelke25 CKAD Mock Challenge got praised by a 91% retake passer. |
| 4 | **github.com/dgkanatsios/CKAD-exercises** | free | The classic drill set, by domain. Muscle memory. |
| 5 | **Killer.sh** (2 sessions bundled with the exam) | included | Harder than the real exam for most — one candidate scored 105/113 there and still failed at 33%. Use one session near the end as a dress rehearsal for the PSI-like UI, not as a readiness benchmark. |
| 6 | **prepium.sh** | free attempts | Real clusters, auto-scored like the real exam. Giveaway rounds run on r/KubernetesCerts; free "Task of the Week". |
| 7 | **sailor.sh** CKAD mocks | paid | Recommended in the fail-recovery threads ("grind killercoda + sailor.sh for a week"). |
| — | **github.com/TiPunchLabs/ckad-dojo** | free | Extra scenario practice, recommended by a retake passer. |
| — | **github.com/bmuschko/ckad-crash-course**, **ibrahimatay/CKAD-Exercises**, **tariqm/CKAD-2026**, **ManikSinghal777/CKAD-2025**, **GuillermoW93/CKAD-prep** | free | Extra question banks if you want more volume. |
| — | **O'Reilly CKAD Study Guide** (bmuschko) | ~$40 | Used by a 99% scorer as theory base. Not required. |
| — | **notes.kodekloud.com** | free | Written notes for the whole KodeKloud CKAD course, sectioned by topic. Faster than re-watching a video for one concept. For studying only — not exam-allowed. |

**Practice cluster:** minikube or kind is enough — almost all reported tasks are namespace-level YAML work. The guide's own kind setup is in [conventions](../00-conventions.md) and [T2.09](../part2-basics/T2.09-local-practice-clusters-kind-and-minikube.md).

## 4. Why people fail (the reported failure modes)

| Reported result | Root cause | Defense |
|---|---|---|
| 33% despite 105/113 on Killer.sh | Memorized isolated tasks; froze on differently-worded chained questions (svc → netpol → test pod) | Drill *scenarios*, not just commands. Verification-first habit. |
| 56% (a CKA+CKS holder) | Underestimated it — CKAD tests app-dev domains CKA/CKS don't | Treat it as its own exam even with k8s experience. |
| 57% then 60% | Same weak domains both times (Env/Config/Security, Services & Networking, Design & Build) | The result email gives per-domain scores. Drill those, not everything. |
| 59% → 91% on retake | Time management — stuck 20 min on one question, tilted | Flag and move. At 66% you can skip roughly a third. |
| 65%, 1% short | No prior k8s experience, mocks averaging ~70% | The sub's rule: **80%+ consistently on KodeKloud mocks before booking**. |
| Panic | Even a 100% scorer flagged 4 questions and felt panic at the start | Flag, move on, come back. |
| Lost attempt | Power outage mid-exam — the timer never pauses | Stable power and network, backup hotspot, laptop charged. |
| Check-in hell | Blurry webcam ID → 2 hours of support chat. Glass walls got a room rejected | Check in 30–45 min early, clean desk, closed blinds. |

The meta-lesson across all threads: passers did reps until the patterns were hard-coded (each mock 2–4× until it was fast). Failers knew the material but lacked speed or crumbled on unfamiliar phrasing. Train for the clock, not just the content.

## 5. Speed tactics (from reported 90%+ scorers)

- **Flag and skip.** Tasks are not sequential-dependent. Bank easy points first.
- **Imperative-first workflow:** generate with `--dry-run`, edit in vi, apply, verify:

```bash
alias k=kubectl
export do='--dry-run=client -o yaml'
export now='--force --grace-period=0'
source <(kubectl completion bash) 2>/dev/null; complete -F __start_kubectl k
```

- **Generators, never YAML from scratch:**

```bash
k run pod --image=nginx $do > pod.yaml                 # pod
k create deploy web --image=nginx $do > d.yaml         # deployment
k create svc clusterip web --tcp=80:8080 $do > s.yaml  # service
k create job j --image=busybox $do > j.yaml
k create cronjob cj --image=busybox --schedule="*/5 * * * *" -- echo hi
k create cm cfg --from-literal=A=1 --from-file=app.conf
k create secret generic s --from-literal=pw=hunter2 --from-file=f
k create sa mysa
k create rolebinding rb --role=r --serviceaccount=ns:mysa
k expose deploy web --port=80 --target-port=8080 --type=NodePort
k create ingress in --rule="h.com/app*=svc:80" $do > i.yaml
k create quota q --hard=pods=10,cpu=4 $do > q.yaml
```

- **Mutate in place** when a task forbids recreating: `k edit`, `k set image`, `k set resources`, `k set env`, `k scale`, `k label --overwrite`, `k patch`.
- **vi fluency is required:** `shift+v` select, `dd`, `yy`, `p`, `:set nu`, `:tabedit` / `:tabnext` for two files, `:term` for a shell inside vi. See [T1.03](../part1-linux/T1.03-vim-and-tmux-for-yaml-editing.md).
- **`k explain <resource>.spec.<field>`** for nested fields (resources, securityContext, pod template) — faster than hunting docs.
- **Verify after every task.** `get` → `describe` → `curl`/logs → then move on. `k get endpoints <svc>` empty = broken selector. Creating the object is not scoring.
- **Temp pods are the killer skill:** `k run tmp --rm -it --image=curlimages/curl -- sh`, or busybox + `wget -O- svc:80`.
- **jsonpath for precise checks:** `k get pod x -o jsonpath='{.spec.containers[0].resources}'`.
- **Context switching, every question:** `k config get-contexts`, `k config use-context <name>`. Re-read the context line in each question header — twice.
- **External monitor** if you have one (PSI shrinks the usable screen); external mic is allowed.
- Run your **last full simulator the day before** so the environment is muscle memory.

## 6. How objects connect (the wiring that chained questions test)

Reported exam questions chain resources instead of asking for one object. Connections are always label or name references, never nesting:

```
Ingress ──host/path──> Service ──selector──> Pod labels
        │                  │
        └──> NetworkPolicy (podSelector matches pod labels;
             reports say policies exist and YOU label pods)

Deployment ──creates──> ReplicaSet ──creates──> Pods   (edit only the Deployment)
CronJob ──spawns──> Job ──spawns──> Pod
Secret/ConfigMap ──consumed via──> pod env[] / envFrom / volumes
ServiceAccount ──bound by──> RoleBinding ──grants──> Role/ClusterRole
```

- Service `selector.app: web` → pod label `app: web`.
- Ingress `backend.service.name: web` → Service `metadata.name`.
- Pod `serviceAccountName: mysa` → SA name.
- RoleBinding `subjects.name` → SA name; `roleRef.name` → Role name.
- env `valueFrom.secretKeyRef.name/key` → Secret name + key.

**Debug reflex:** a broken connection is a mismatched name or label. `k describe`, `k get endpoints <svc>` (empty endpoints = wrong selector). Where the fields go inside a deployment: workload settings at `spec.`, pod settings at `spec.template.spec`, per-container settings inside `containers[]`. `k explain` drills the tree.

## 7. Sites reported allowed inside the exam (open book)

- `kubernetes.io/docs` — the main one; every task's YAML shape is here.
- `kubernetes.io/blog` — also allowed.
- `github.com/kubernetes` — allowed, rarely needed.
- `kubectl explain` — built-in docs, fastest of all.

Bookmark `kubernetes.io/docs/reference/generated/kubectl/kubectl-commands` (every kubectl flag, searchable). Learn the docs search box before exam day — question headers link to relevant pages.

## 8. Prep timeline that worked for passers

| Background | Timeline reported |
|---|---|
| No k8s experience | KodeKloud course 2–4 weeks → mocks on repeat (2–4× each) → 60–90 days total |
| Some k8s/dev experience | 2–4 weeks of daily mocks + GitHub question repos |
| Post-CKA | 1–2 weeks — several people say take CKAD right after CKA |

The three phases in practice:

1. **Learn (weeks 1–2).** Course once through, every lab hands-on — never watch-and-nod. Build the `alias k` / `$do` / vi habits from day one. The [15-day study plan](study-plan.md) maps this phase onto the guide's lessons.
2. **Drill (weeks 2–4).** dgkanatsios exercises by domain, then aravind4799's exam sets, Killercoda scenarios on repeat. Target under 8 minutes per task, verified.
3. **Exam-fit (final week).** One Killer.sh session as dress rehearsal. Re-run only the weakest domains — the svc → netpol → ingress chains are the reported killer. Practice verification, not just creation. Sleep; stress and rushing were named in fail reports.

## 9. Exam-day checklist

- [ ] Check in 30–45 min early — PSI proctor issues are common (blurry ID, chat-only support)
- [ ] Clean desk, closed blinds / covered glass, stable power + internet, backup hotspot ready, phone away
- [ ] External monitor + external mic if available
- [ ] `alias k=kubectl`, `export do='--dry-run=client -o yaml'` first thing
- [ ] Read each question's ssh/context line — twice
- [ ] Easy questions first; flag hard ones; don't burn more than ~8 min on any single one
- [ ] If a question forbids deleting/recreating objects it says so — read twice before `k delete`
- [ ] Verify each answer with get/describe/curl before moving on
- [ ] Leave 15–30 min at the end to re-verify flagged questions
- [ ] Run the last full simulator the day before; sleep

## 10. If attempt 1 fails — the retake is a gift

Reports put question overlap between attempts at roughly 80% (from the 59→91 retaker). The result email breaks the score down **by domain**: drill exactly those for a week (Killercoda + sailor.sh + the aravind4799 repo), reschedule while the pattern still overlaps. Reported second-attempt jumps: 50→89, 53→98, 59→91.

## 11. The daily loop (TL;DR)

```
1. Pick a domain task (e.g. "fix broken ingress")
2. Do it imperatively: k create/expose --dry-run -o yaml > f.yaml; vi f.yaml
3. Verify with get/describe/curl — don't move on until it WORKS
4. Repeat until <8 min per task, no docs for the common shapes
5. Once mocks hit 80%+ consistently → book the exam
```
