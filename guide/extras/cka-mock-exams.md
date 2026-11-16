# CKA mock exams (three full 2-hour sets)

> The missing layer of this guide: **unseen-scenario practice under a clock**. The lessons teach topics one at a time; these exams mix all five CKA domains into one sitting, the way the real thing does. Every scenario is original — these are not real exam questions, and nothing here claims to predict the exam.
>
> **When to take these.** Only after you finish the Part 4 lessons — the vms tasks assume you already know the T4.04/T4.25/T4.26 runbooks (etcd, static Pods, node repair). Warm up first with the [CKA task bank](cka-task-bank.md): it is the untimed/short-task version of this material. A mock is a dress rehearsal, not a lesson.

## How to run a mock

- **Timer:** set 120 minutes, hard stop. Suggested minutes per task sum to ~105-110, leaving buffer for context switches and verification — the same margin the real exam needs (reported shape: ~17 tasks, ~66% to pass, see [exam intel](exam-intel.md)).
- **Contexts:** the real exam puts each task on its own SSH session and cluster context. These mocks simulate that with two environments — every task header names one. **Type the context line every time you start a task, even if you never switched:**
  - `kind` tasks: `kubectl config use-context kind-lab` (context `kind-lab`, cluster `lab`, nodes `lab-control-plane`, `lab-worker`, `lab-worker2`, Calico — from `env/kind-up.sh`, see [conventions](../00-conventions.md)).
  - `vms` tasks: the kubeadm cluster — `ssh cp1`, `sudo -i`, `export KUBECONFIG=/etc/kubernetes/admin.conf`. Node work happens on `w1`/`w2` via `ssh` + `sudo -i`; `exit` between nodes, no nested `ssh`.
- **Shell setup** (once per session, same as the lessons): `alias k=kubectl; export do="--dry-run=client -o yaml"; export now="--force --grace-period=0"; source <(kubectl completion bash); complete -o default -F __start_kubectl k`.
- **Allowed references:** keep a browser tab open on `kubernetes.io/docs`, `kubernetes.io/blog`, `helm.sh/docs` and `gateway-api.sigs.k8s.io` — the same set the real CKA allows. Nothing else.
- **No hints, no peeking.** Do not read the setup appendix or the grading appendix before or during the run. The setup is what a "proctor" (a peer, or you wearing a different hat) runs *before* your clock starts — the exam hands you broken things, never break instructions.
- **Answer files:** some tasks ask you to record output in `/opt/course/<task>/...`, the real exam's convention. Create the directories first if needed (`sudo mkdir -p /opt/course` on the host named in the task — on `vms` tasks that is `cp1`).
- **Flag and move.** Tasks are independent; the order is arbitrary. Skip anything that stalls you past its suggested time and come back.
- **Grading happens only after the timer.** Self-grade or have the peer grade with the per-exam grading appendix: each task has a collapsed block with the exact verification commands, the pass condition, and the partial-credit rule. Fill the score sheet, divide by 100. ~66% ≈ passing; below that, the score sheet tells you which domain to drill.
- **One exam per environment state.** Each exam's setup assumes a clean kind `lab` cluster (`kind delete cluster --name lab && env/kind-up.sh` or at least `env/kind-reset.sh` plus the extra deletes listed in that exam's cleanup) and a healthy kubeadm cluster at the version the exam states. Do not run two exams' setups on the same cluster without resetting.

---

# Exam 1 — "The quiet cluster"

## Environment plan

| Env | Tasks | Needs before the clock |
|---|---|---|
| `kind` (context `kind-lab`) | 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 16, 17 | Standard `lab` cluster. Add-ons for tasks 4 and 11: `helm`, `metallb` + address pool, `traefik` — installed by Appendix 1A. |
| `vms` (`cp1`, `w1`, `w2`; kubeadm 1.37.x, Calico, etcd 3.7.0) | 1, 2, 3, 14 | Healthy 1.37.x cluster, `etcdctl`/`etcdutl` on `cp1` (see [T4.04](../part4-cka/T4.04-manage-the-lifecycle-of-kubernetes-clusters.md) §7.0). Appendix 1A injects two faults on it. |

All `vms` faults are injected before the clock starts. On this cluster no injected fault kills `kubectl`, but one dependency is real: Task 1's restored `archive-web` Pods can only report ready once the node and scheduler faults are repaired — fix Tasks 2 and 3 before Task 1's final rollout check, or come back to it at the end.

## Tasks

### Task 1 — 10 min · 10 pts · Cluster Architecture · `vms`

> `ssh cp1`, `sudo -i`, `export KUBECONFIG=/etc/kubernetes/admin.conf`

Create a snapshot of the cluster's etcd to `/opt/course/01/etcd-snapshot.db` and verify the snapshot file is valid. Then delete the namespace `e1-archive`. Restore etcd from your snapshot so that `e1-archive` and all of its objects exist again, and Deployment `archive-web` has all replicas ready.

### Task 2 — 8 min · 8 pts · Troubleshooting · `vms`

> `ssh cp1`, `sudo -i`, `export KUBECONFIG=/etc/kubernetes/admin.conf`

Worker node `w1` of the kubeadm cluster reports `NotReady`. Find the cause and return the node to a healthy `Ready` state — the fix must survive a reboot. The workload Pods scheduled there must be `Running` again.

### Task 3 — 8 min · 7 pts · Troubleshooting · `vms`

> `ssh cp1`, `sudo -i`, `export KUBECONFIG=/etc/kubernetes/admin.conf`

On the kubeadm cluster, every newly created Pod stays `Pending` with no events — Pods that already run are unaffected. `kubectl` itself works. Restore the scheduler. When done, a test Pod you create must reach `Running` and `/etc/kubernetes/manifests` must be in its correct state.

### Task 4 — 7 min · 6 pts · Troubleshooting · `kind`

> `kubectl config use-context kind-lab`

Helm release `site` in namespace `e1-helm` was installed from the chart at `/opt/course/04/site-chart`, but its application never came up. Find what the release got wrong and fix it with `helm upgrade` — do not edit the Deployment or Service directly. Make `http://site.e1-helm.svc.cluster.local` answer, and write the release's current revision into `/opt/course/04/revision.txt`.

### Task 5 — 6 min · 6 pts · Cluster Architecture · `kind`

> `kubectl config use-context kind-lab`

The ServiceAccount `reader` in namespace `e1-rbac` must be able to **list and watch Pods in `e1-rbac` only** — nothing else, in no other namespace. Create the RBAC objects that grant exactly this. Record the result of a `can-i` check for `list pods` and one for `list secrets` (both `yes`/`no` lines) in `/opt/course/05/rbac.txt`.

### Task 6 — 5 min · 5 pts · Workloads & Scheduling · `kind`

> `kubectl config use-context kind-lab`

Deployment `web` in namespace `e1-web` was updated to a new image and the rollout is stuck — not all replicas serve. Roll it back to the previous working revision, confirm every Pod runs the older image, and write the Deployment's **current** revision number — the newest entry `kubectl rollout history` reports after the rollback — into `/opt/course/06/revision.txt`.

### Task 7 — 8 min · 8 pts · Services & Networking · `kind`

> `kubectl config use-context kind-lab`

Namespace `e1-sec` runs `frontend`, `api` (Service, port 80) and `db` (Service, port 5432). Create NetworkPolicies so that: `frontend` can reach `api` on TCP 80 and nothing else can; `api` can reach `db` on TCP 5432 and nothing else, yet can still resolve names; `db` accepts connections only from `api` on 5432; and no Pod outside `e1-sec` can initiate connections into `api` or `db`. Pods not mentioned keep unrestricted egress.

### Task 8 — 7 min · 8 pts · Storage · `kind`

> `kubectl config use-context kind-lab`

In namespace `e1-vol`: create a PersistentVolume `e1-pv` of type hostPath `/mnt/e1data`, capacity 1Gi, access mode ReadWriteOnce, reclaim policy `Retain`, storage class `manual`. Create a claim `e1-pvc` requesting 200Mi with the same access mode and class. Create a Pod `e1-volpod` (`busybox:1.36`, `sleep 3600`) that mounts the claim at `/data`, scheduled onto node `lab-worker`. Write the text `hello cka` into `/data/marker.txt` and record the PV's `STATUS` column in `/opt/course/08/pv-status.txt`.

### Task 9 — 6 min · 5 pts · Troubleshooting · `kind`

> `kubectl config use-context kind-lab`

Deployment `logger` in namespace `e1-app` has no running Pods — they fail before the container starts. Find the configuration error and make the Deployment healthy without changing the replica count.

### Task 10 — 6 min · 5 pts · Troubleshooting · `kind`

> `kubectl config use-context kind-lab`

Pod `pg-app` in namespace `e1-db` is stuck `Pending` because its PersistentVolumeClaim `pgdata` will not bind. The claim belongs to the database team — do not modify, delete or recreate it, and do not change its selector, class, mode or size. A PersistentVolume named `pg-vol` already exists in the cluster. Make `pgdata` `Bound` and `pg-app` `Running`.

### Task 11 — 6 min · 6 pts · Services & Networking · `kind`

> `kubectl config use-context kind-lab`

In namespace `e1-ing`, Services `web` (port 80) and `api` (port 8080) are running. Create an Ingress named `main` that serves host `shop.local` to `web:80` and host `api.local` to `api:8080`. Use the Ingress controller installed in the cluster. Verify both hostnames answer.

### Task 12 — 5 min · 4 pts · Services & Networking · `kind`

> `kubectl config use-context kind-lab`

The Pod `client` in namespace `e1-client` must reach the Service `records` — which lives in namespace `e1-net` — using only the bare name `http://records`. You may not move, rename or duplicate the existing `records` Service's backend Pods. Make the name resolve and the request succeed.

### Task 13 — 5 min · 4 pts · Services & Networking · `kind`

> `kubectl config use-context kind-lab`

Expose Deployment `edge` in namespace `e1-edge` as a NodePort Service named `edge` on port 80. Write the assigned node port number into `/opt/course/13/nodeport.txt` and verify the Service answers on that port.

### Task 14 — 5 min · 4 pts · Cluster Architecture · `vms`

> `ssh cp1`, `sudo -i`, `export KUBECONFIG=/etc/kubernetes/admin.conf`

Determine how many days remain until the kube-apiserver serving certificate on `cp1` expires. Write **only the number of days** (for example `364`) into `/opt/course/14/days.txt`.

### Task 15 — 6 min · 5 pts · Workloads & Scheduling · `kind`

> `kubectl config use-context kind-lab`

One node of the kind cluster has SSD storage — it is already labelled `disk=ssd`. Create a Deployment `cache` in namespace `e1-cache` (3 replicas, `nginx:1.27`) that runs **only** on SSD nodes, using `requiredDuringSchedulingIgnoredDuringExecution` node affinity. Confirm all replicas land on the labelled node.

### Task 16 — 6 min · 5 pts · Cluster Architecture · `kind`

> `kubectl config use-context kind-lab`

Node `lab-worker2` needs kernel maintenance. Evict its workload Pods safely and mark it unschedulable. Then imagine the maintenance is done: return the node to service. When you finish, `lab-worker2` must be `Ready` and schedulable, and all replicas of Deployment `web` in namespace `e1-drain` must be `Running`.

### Task 17 — 5 min · 4 pts · Workloads & Scheduling · `kind`

> `kubectl config use-context kind-lab`

In namespace `e1-pay`, create a Deployment `pay` with 3 replicas of `nginx:1.27`, and a PodDisruptionBudget `pay-pdb` that keeps at least 2 Pods available during voluntary disruptions.

## Appendix 1A — setup (run BEFORE the clock)

Run by the peer/proctor, not the candidate. Two parts: the kind part runs on the workstation; the vms part runs on the kubeadm nodes. Order does not matter between them.

**Part 1 — kind setup.** Installs the add-ons for tasks 4 and 11 (helm, metallb + pool, traefik), then creates every object the exam expects — including the injected faults. Takes ~10 minutes.

```bash
#!/usr/bin/env bash
# run from the repo root so env/kind-addons.sh resolves
set -euo pipefail
shopt -s expand_aliases; alias k=kubectl
k config use-context kind-lab
k get nodes
sudo mkdir -p /opt/course/{04,05,06,08,13,16} && sudo chown -R "$USER" /opt/course   # answer files live on this host

# --- add-ons for tasks 4 (helm release) and 11 (Ingress) — helm, metallb, traefik ---
env/kind-addons.sh helm
export PATH="$HOME/.local/bin:$PATH"
env/kind-addons.sh metallb
PREFIX=$(docker network inspect kind -f '{{range .IPAM.Config}}{{println .Subnet}}{{end}}' | grep -E '^[0-9]+\.[0-9]+\.' | head -1)
case "$PREFIX" in
  */16) BASE=$(echo "$PREFIX" | cut -d. -f1-2); RANGE="${BASE}.255.200-${BASE}.255.220" ;;
  *)    BASE=$(echo "$PREFIX" | cut -d. -f1-3); RANGE="${BASE}.200-${BASE}.220" ;;
esac
until kubectl apply -f - <<YAML
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata: {name: lab-pool, namespace: metallb-system}
spec:
  addresses: [$RANGE]
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata: {name: lab-l2, namespace: metallb-system}
spec:
  ipAddressPools: [lab-pool]
YAML
do echo "waiting for the MetalLB webhook"; sleep 5; done
env/kind-addons.sh traefik
k -n traefik rollout status deploy/traefik --timeout=300s
k -n traefik get svc traefik   # must show an EXTERNAL-IP

# --- task 4 objects ---
mkdir -p /opt/course/04/site-chart/templates
cat > /opt/course/04/site-chart/Chart.yaml <<'YAML'
apiVersion: v2
name: site
version: 0.1.0
YAML
cat > /opt/course/04/site-chart/values.yaml <<'YAML'
image:
  repository: nginx
  tag: "1.2x"          # no such tag — the release installs, the Pod never pulls
service:
  port: 80
page: "helm-ok"
YAML
cat > /opt/course/04/site-chart/templates/page.yaml <<'YAML'
apiVersion: v1
kind: ConfigMap
metadata:
  name: site-page
data:
  index.html: {{ .Values.page | quote }}
YAML
cat > /opt/course/04/site-chart/templates/deploy.yaml <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: site
spec:
  replicas: 1
  selector:
    matchLabels: {app: site}
  template:
    metadata:
      labels: {app: site}
    spec:
      containers:
      - name: web
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        volumeMounts: [{name: page, mountPath: /usr/share/nginx/html}]
      volumes:
      - name: page
        configMap: {name: site-page}
YAML
cat > /opt/course/04/site-chart/templates/svc.yaml <<'YAML'
apiVersion: v1
kind: Service
metadata:
  name: site
spec:
  selector: {app: site}
  ports: [{port: {{ .Values.service.port }}, targetPort: 80}]
YAML
helm install site /opt/course/04/site-chart -n e1-helm --create-namespace

# --- task 5 objects ---
k create ns e1-rbac
k -n e1-rbac create serviceaccount reader

# --- task 6 objects ---
k create ns e1-web
k -n e1-web create deploy web --image=nginx:1.25 --replicas=2
k -n e1-web rollout status deploy/web --timeout=180s
k -n e1-web set image deploy/web nginx=nginx:1.2x
sleep 5

# --- task 7 objects (pinned to lab-worker: bare Pods on lab-worker2 would block the task-16 drain) ---
k create ns e1-sec
k -n e1-sec run frontend --image=busybox:1.36 -l app=frontend --overrides='{"spec":{"nodeName":"lab-worker"}}' -- sleep 3600
k -n e1-sec run api --image=busybox:1.36 -l app=api --overrides='{"spec":{"nodeName":"lab-worker"}}' -- \
  sh -c 'mkdir -p /www && echo api-ok > /www/index.html && exec httpd -f -p 80 -h /www'
k -n e1-sec run db --image=busybox:1.36 -l app=db --overrides='{"spec":{"nodeName":"lab-worker"}}' -- \
  sh -c 'mkdir -p /www && echo db-ok > /www/index.html && exec httpd -f -p 5432 -h /www'
k -n e1-sec expose pod api --port=80
k -n e1-sec expose pod db --port=5432

# --- task 8 namespace ---
k create ns e1-vol

# --- task 9 objects ---
k create ns e1-app
cat <<'YAML' | k -n e1-app apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: logger-config
data:
  logdir: /var/log/app
  level: info
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: logger
spec:
  replicas: 1
  selector:
    matchLabels: {app: logger}
  template:
    metadata:
      labels: {app: logger}
    spec:
      containers:
      - name: logger
        image: busybox:1.36
        command: ["sh", "-c", "echo started >> $LOG_FILE; sleep 3600"]
        env:
        - name: LOG_FILE
          valueFrom:
            configMapKeyRef:
              name: logger-config
              key: logfile
YAML

# --- task 10 objects ---
k create ns e1-db
cat <<'YAML' | k apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pg-vol
  labels: {vol: postgres}
spec:
  capacity: {storage: 2Gi}
  accessModes: [ReadWriteOnce]
  persistentVolumeReclaimPolicy: Retain
  storageClassName: ""
  hostPath: {path: /mnt/pg-vol, type: DirectoryOrCreate}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pgdata
  namespace: e1-db
spec:
  storageClassName: ""
  selector: {matchLabels: {vol: pg}}
  accessModes: [ReadWriteOnce]
  resources: {requests: {storage: 2Gi}}
---
apiVersion: v1
kind: Pod
metadata:
  name: pg-app
  namespace: e1-db
spec:
  nodeName: lab-worker   # pinned: a controller-less Pod on lab-worker2 would block the task-16 drain
  containers:
  - name: c
    image: busybox:1.36
    command: ["sleep", "3600"]
    volumeMounts: [{name: d, mountPath: /data}]
  volumes:
  - name: d
    persistentVolumeClaim: {claimName: pgdata}
YAML

# --- task 11 objects ---
k create ns e1-ing
k -n e1-ing create deploy web --image=nginx:1.27
k -n e1-ing expose deploy web --port=80
k -n e1-ing run api --image=busybox:1.36 -l app=api --overrides='{"spec":{"nodeName":"lab-worker"}}' -- \
  sh -c 'mkdir -p /www && echo api-ok > /www/index.html && exec httpd -f -p 8080 -h /www'
k -n e1-ing expose pod api --port=8080

# --- task 12 objects ---
k create ns e1-net
k -n e1-net run records --image=busybox:1.36 -l app=records --overrides='{"spec":{"nodeName":"lab-worker"}}' -- \
  sh -c 'mkdir -p /www && echo records-ok > /www/index.html && exec httpd -f -p 80 -h /www'
k -n e1-net expose pod records --port=80
k create ns e1-client
k -n e1-client run client --image=busybox:1.36 --overrides='{"spec":{"nodeName":"lab-worker"}}' -- sleep 3600

# --- task 13 objects ---
k create ns e1-edge
k -n e1-edge create deploy edge --image=nginx:1.27 --replicas=2

# --- task 15 objects ---
k label node lab-worker disk=ssd --overwrite
k create ns e1-cache

# --- task 16 objects: all four replicas are pinned to lab-worker2 so the drain is real work ---
k create ns e1-drain
cat <<'YAML' | k -n e1-drain apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 4
  selector:
    matchLabels: {app: web}
  template:
    metadata:
      labels: {app: web}
    spec:
      nodeSelector: {kubernetes.io/hostname: lab-worker2}
      containers:
      - {name: nginx, image: nginx:1.27}
YAML
k -n e1-drain rollout status deploy/web --timeout=180s
k -n e1-drain get pods -o jsonpath='{range .items[*]}{.metadata.uid}{"\n"}{end}' | sort > /opt/course/16/.pre-drain-uids   # grader fixture: these UIDs must all be gone after the drain

# --- task 17 namespace ---
k create ns e1-pay

for ns in e1-sec e1-ing e1-net e1-client e1-edge e1-drain; do
  k -n "$ns" wait --for=condition=Ready pod --all --timeout=180s || true
done
echo "kind setup complete"
```

**Part 2 — vms setup.** Run each block where it says; each `ssh` is a separate connection (no nested ssh).

```bash
# --- on cp1 as root (ssh cp1; sudo -i) ---
export KUBECONFIG=/etc/kubernetes/admin.conf
alias k=kubectl
mkdir -p /opt/course/01 /opt/course/14   # the other /opt/course dirs belong on the kind workstation
k get nodes    # all Ready before you break things

# task 1 objects
k create ns e1-archive
k -n e1-archive create deploy archive-web --image=nginx:1.27 --replicas=2
k -n e1-archive create configmap marker --from-literal=day=monday
k -n e1-archive rollout status deploy/archive-web --timeout=180s
k get ns e1-archive -o jsonpath='{.metadata.uid}' > /opt/course/01/.ns-uid   # grader fixture: proves the namespace came back from the snapshot, not a hand-recreate

# task 3 setup
mv /etc/kubernetes/manifests/kube-scheduler.yaml /root/
for c in $(crictl ps --name kube-scheduler -q); do crictl stop "$c"; done
exit

# --- on w1 as root (ssh w1; sudo -i): task 2 setup ---
systemctl disable --now kubelet
exit

# done — wait about a minute, then hand the exam to the candidate
```

## Appendix 1B — grading

Score each task per its block, then fill the score sheet. Commands are grouped by where they run: `kind-lab` blocks on your workstation; `cp1`, `w1` and `w2` blocks on the named node as root — each over its own ssh session. Exit back to your workstation before switching nodes, and never `ssh` from inside another node.

<details>
<summary>Task 1 — etcd backup and restore (10 pts)</summary>

```bash
test -f /opt/course/01/etcd-snapshot.db && echo "snapshot file exists"
etcdutl snapshot status /opt/course/01/etcd-snapshot.db >/dev/null && echo "snapshot valid"
k get ns e1-archive -o name | grep -qx namespace/e1-archive && echo "namespace restored"
test "$(k get ns e1-archive -o jsonpath='{.metadata.uid}')" = "$(cat /opt/course/01/.ns-uid)" && echo "uid matches the snapshot"
test "$(k -n e1-archive get cm marker -o jsonpath='{.data.day}')" = "monday" && echo "cm back"
k -n e1-archive rollout status deploy/archive-web --timeout=180s && echo "deploy ready"   # pods may need a minute to be re-created by the kubelets
```

**Pass:** all six checks — the namespace UID comparison is what proves a real restore (a hand-recreated namespace gets a fresh UID and fails). **Partial credit:** yes — 4 pts for a valid snapshot alone; 7 pts if the restore was attempted but the namespace never came back (wrong data-dir, stale caches not restarted).
</details>

<details>
<summary>Task 2 — dead worker node (8 pts)</summary>

```bash
# --- on cp1 as root (ssh cp1; sudo -i) ---
test "$(k get node w1 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')" = "True" && echo "w1 Ready"
! k get node w1 -o jsonpath='{.spec.taints}' | grep -q 'unreachable' && echo "taint gone"
# --- on w1 as root (ssh w1; sudo -i — a separate session, exit cp1 first) ---
systemctl is-active kubelet | grep -q '^active$' && echo "kubelet active"
systemctl is-enabled kubelet | grep -q '^enabled$' && echo "kubelet enabled"
```

**Pass:** all four checks. **Partial credit:** yes — 5 pts if the node is `Ready` but the kubelet is not `enabled` (the fault returns at the next reboot).
</details>

<details>
<summary>Task 3 — missing scheduler (7 pts)</summary>

```bash
test "$(ls /etc/kubernetes/manifests | wc -l)" -eq 4 && echo "four manifests"
k -n kube-system get pod -l component=kube-scheduler -o jsonpath='{.items[0].status.phase}' | grep -q Running && echo "scheduler running"
k -n default run s-test --image=busybox:1.36 --restart=Never -- sleep 5
k -n default wait --for=condition=Ready pod/s-test --timeout=90s && echo "new pod scheduled" ; k -n default delete pod s-test --now --wait=false
```

**Pass:** scheduler Pod back, manifest present, a brand-new Pod schedules within ~90 s. **Partial credit:** yes — 4 pts if the manifest is back but the scheduler is still crash-looping on a second fault the candidate introduced.
</details>

<details>
<summary>Task 4 — broken helm release (6 pts)</summary>

```bash
R=$(helm -n e1-helm history site | awk 'NR>1{print $1}' | sort -n | tail -1)
helm -n e1-helm status site | grep -q 'STATUS: deployed' && echo "release deployed"
test "${R:-0}" -gt 1 && echo "upgraded via helm (rev $R)"   # kubectl edits leave this at 1
test "$(k -n e1-helm get deploy site -o jsonpath='{.spec.template.spec.containers[0].image}')" = "nginx:1.27" && echo "image fixed"
test "$(k -n e1-helm get deploy site -o jsonpath='{.status.readyReplicas}')" = "1" && echo "ready"
k -n e1-helm run t-$RANDOM --rm -i --restart=Never --image=busybox:1.36 -- sh -c 'sleep 2; wget -qO- -T3 http://site | grep -o helm-ok' | grep -q helm-ok && echo "svc answers"
grep -qx "$R" /opt/course/04/revision.txt && echo "file ok"
```

**Pass:** all five — the expected fix is `helm upgrade site /opt/course/04/site-chart --set image.tag=1.27 -n e1-helm` (or correcting `values.yaml` first). The `helm history` check proves the fix went through the release — a `kubectl set image` edit leaves revision at 1. **Partial credit:** yes — 4 pts for a working app fixed by hand (revision still 1) or a correct upgrade with the file missing/wrong.
</details>

<details>
<summary>Task 5 — RBAC (6 pts)</summary>

```bash
k -n e1-rbac auth can-i list pods --as=system:serviceaccount:e1-rbac:reader | grep -qx yes && echo "can list"
k -n e1-rbac auth can-i watch pods --as=system:serviceaccount:e1-rbac:reader | grep -qx yes && echo "can watch"
k -n e1-rbac auth can-i get pods --as=system:serviceaccount:e1-rbac:reader | grep -qx no && echo "get not granted"
k -n e1-rbac auth can-i delete pods --as=system:serviceaccount:e1-rbac:reader | grep -qx no && echo "delete not granted"
k -n e1-rbac auth can-i list deployments --as=system:serviceaccount:e1-rbac:reader | grep -qx no && echo "no other resources"
k -n e1-rbac auth can-i list secrets --as=system:serviceaccount:e1-rbac:reader | grep -qx no && echo "cannot list secrets"
k auth can-i list pods -n default --as=system:serviceaccount:e1-rbac:reader | grep -qx no && echo "namespace-scoped only"
grep -q '^yes$' /opt/course/05/rbac.txt && grep -q '^no$' /opt/course/05/rbac.txt && echo "file ok"
```

**Pass:** all eight checks — "list and watch, nothing else" means `get`, `delete` and other resources must all answer `no` (the file must hold one `yes` and one `no` line). **Partial credit:** yes — 4 pts for the correct grants with the file missing or wrong.
</details>

<details>
<summary>Task 6 — rollback (5 pts)</summary>

```bash
test "$(k -n e1-web get deploy web -o jsonpath='{.spec.template.spec.containers[0].image}')" = "nginx:1.25" && echo "old image back"
test "$(k -n e1-web get deploy web -o jsonpath='{.status.readyReplicas}')" = "2" && echo "all ready"
REV=$(k -n e1-web get deploy web -o jsonpath='{.metadata.annotations.deployment\.kubernetes\.io/revision}')
test "$(cat /opt/course/06/revision.txt)" = "$REV" && echo "file ok (current revision $REV)"
```

**Pass:** image is `nginx:1.25`, 2 ready replicas, file holds the Deployment's *current* revision — the new top entry in `rollout history` after the undo (revision `3` in the reference run: the rolled-back template is re-used as a *new* revision, so the pre-update revision `1` is the wrong answer). **Partial credit:** yes — 4 pts for a successful rollback with a missing/wrong file.
</details>

<details>
<summary>Task 7 — NetworkPolicy matrix (8 pts)</summary>

```bash
shopt -s expand_aliases; alias k=kubectl
S=e1-sec; bad=0
chk() { if k -n $S exec "$1" -- sh -c "nc -z -w2 $2 $3" >/dev/null 2>&1; then got=ALLOW; else got=DENY; fi
        [ "$got" = "$4" ] || { echo "WRONG: $1 -> $2:$3 want=$4 got=$got"; bad=$((bad+1)); }; }
sleep 4
chk frontend api.$S 80 ALLOW
chk frontend db.$S 5432 DENY
chk db api.$S 80 DENY
chk api db.$S 5432 ALLOW
k -n $S exec api -- nslookup db.$S.svc.cluster.local >/dev/null 2>&1 || { echo "WRONG: api lost DNS"; bad=$((bad+1)); }
CIP=$(k -n default get svc kubernetes -o jsonpath='{.spec.clusterIP}')   # a Service IP — outside the Pod network
k -n $S exec api -- nc -z -w2 "$CIP" 443 >/dev/null 2>&1 && { echo "WRONG: api egress not restricted"; bad=$((bad+1)); }
k -n default run outside-$RANDOM --rm -i --restart=Never --image=busybox:1.36 -- sh -c "nc -z -w2 api.$S 80" >/dev/null 2>&1 && { echo "WRONG: outside pod reached api"; bad=$((bad+1)); }
echo "mismatches: $bad"; test $bad -eq 0
```

**Pass:** `mismatches: 0`. **Partial credit:** yes — 6 pts for a single mismatch (usually the DNS row or the api-egress restriction row, both very common misses), 4 pts if only the "outside namespace" row fails.
</details>

<details>
<summary>Task 8 — PV/PVC/Pod (8 pts)</summary>

```bash
test "$(k get pv e1-pv -o jsonpath='{.spec.capacity.storage}')" = "1Gi" && \
test "$(k get pv e1-pv -o jsonpath='{.spec.accessModes[0]}')" = "ReadWriteOnce" && \
test "$(k get pv e1-pv -o jsonpath='{.spec.persistentVolumeReclaimPolicy}')" = "Retain" && \
test "$(k get pv e1-pv -o jsonpath='{.spec.storageClassName}')" = "manual" && \
test "$(k get pv e1-pv -o jsonpath='{.spec.hostPath.path}')" = "/mnt/e1data" && echo "pv correct"
test "$(k -n e1-vol get pvc e1-pvc -o jsonpath='{.status.phase}')" = "Bound" && echo "bound"
test "$(k -n e1-vol exec e1-volpod -- cat /data/marker.txt)" = "hello cka" && echo "data ok"
grep -qi bound /opt/course/08/pv-status.txt && echo "file ok"
```

**Pass:** all four checks. **Partial credit:** yes — 6 pts for a correct binding without the file or without the marker write.
</details>

<details>
<summary>Task 9 — broken ConfigMap reference (5 pts)</summary>

```bash
test "$(k -n e1-app get deploy logger -o jsonpath='{.status.readyReplicas}')" = "1" && echo "logger running"
k -n e1-app get pods | grep -v CreateContainerConfigError | grep -q Running && echo "no config error"
```

**Pass:** the Pod runs — either by adding the `logfile` key to `logger-config` or by pointing the env reference at `logdir`. **Partial credit:** no — it either runs or it does not.
</details>

<details>
<summary>Task 10 — binding without touching the claim (5 pts)</summary>

```bash
test "$(k -n e1-db get pvc pgdata -o jsonpath='{.status.phase}')" = "Bound" && echo "bound"
test "$(k -n e1-db get pvc pgdata -o jsonpath='{.spec.volumeName}')" = "pg-vol" && echo "bound to pg-vol"
test "$(k -n e1-db get pod pg-app -o jsonpath='{.status.phase}')" = "Running" && echo "pod running"
k -n e1-db get pvc pgdata -o jsonpath='{.spec.selector.matchLabels.vol}' | grep -qx pg && echo "claim untouched"
k get pv pg-vol -o jsonpath='{.metadata.labels.vol}' | grep -qx pg && echo "pv labelled"
```

**Pass:** claim `Bound` **to `pg-vol`** — `pg-vol` relabelled `vol=pg`, the claim's spec untouched, `pg-app` Running. A *new* PV the candidate created does not pass: the claim must bind the existing `pg-vol`. **Partial credit:** yes — 3 pts if the claim binds only to a new PV the candidate created while `pg-vol` stays untouched (the task pointed at `pg-vol`).
</details>

<details>
<summary>Task 11 — Ingress (6 pts)</summary>

```bash
test "$(k -n e1-ing get ingress main -o jsonpath='{.spec.rules[0].host}')" = "shop.local" && echo "ingress exists"
LB=$(k -n traefik get svc traefik -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
test -n "$LB" && echo "controller ip $LB"
docker run --rm --network kind curlimages/curl:8.12.1 -s -m5 --resolve "shop.local:80:$LB" http://shop.local/ | grep -qi nginx && echo "shop.local ok"
docker run --rm --network kind curlimages/curl:8.12.1 -s -m5 --resolve "api.local:80:$LB" http://api.local/ | grep -q api-ok && echo "api.local ok"
```

(On Linux, plain `curl --resolve` from the workstation works too.) **Pass:** both hosts return their backends. **Partial credit:** yes — 4 pts for one working host.
</details>

<details>
<summary>Task 12 — the bare name across namespaces (4 pts)</summary>

```bash
k -n e1-client exec client -- sh -c 'wget -qO- -T4 http://records' | grep -q records-ok && echo "resolves and answers"
```

**Pass:** the check — the expected fix is a Service `records` of type `ExternalName` in `e1-client` pointing at `records.e1-net.svc.cluster.local`; recreating `client` with a corrected FQDN/env also passes if the bare name still works (e.g. via `dnsConfig.searches`). **Partial credit:** no.
</details>

<details>
<summary>Task 13 — NodePort (4 pts)</summary>

```bash
test "$(k -n e1-edge get svc edge -o jsonpath='{.spec.type}')" = "NodePort" && echo "type ok"
NP=$(k -n e1-edge get svc edge -o jsonpath='{.spec.ports[0].nodePort}'); grep -qx "$NP" /opt/course/13/nodeport.txt && echo "file ok"
W=$(k get node lab-worker -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')
k -n e1-edge run t-$RANDOM --rm -i --restart=Never --image=busybox:1.36 -- sh -c "wget -qO- -T3 http://$W:$NP | grep -o nginx" | grep -q nginx && echo "nodeport answers"
```

**Pass:** all three. **Partial credit:** yes — 2 pts for the Service alone.
</details>

<details>
<summary>Task 14 — certificate expiry (4 pts)</summary>

```bash
EXP=$(kubeadm certs check-expiration 2>/dev/null | awk '$1=="apiserver"{for(i=2;i<=NF;i++) if($i ~ /^[0-9]+d$/) print $i}')
echo "expected: $EXP"
grep -oE '[0-9]+' /opt/course/14/days.txt | head -1
# PASS if the file's number equals the RESIDUAL TIME of the apiserver row (e.g. 364 for "364d")
```

**Pass:** the number in the file matches the `apiserver` row's residual time (±1 day to forgive timing). **Partial credit:** no.
</details>

<details>
<summary>Task 15 — node affinity (5 pts)</summary>

```bash
test "$(k -n e1-cache get pods -o jsonpath='{.items[*].spec.nodeName}' | tr ' ' '\n' | sort -u)" = "lab-worker" && echo "all on ssd node"
test "$(k -n e1-cache get deploy cache -o jsonpath='{.status.readyReplicas}')" = "3" && echo "3 ready"
k -n e1-cache get deploy cache -o yaml | grep -q requiredDuringScheduling && echo "affinity present"
```

**Pass:** all three. **Partial credit:** yes — 3 pts if `nodeSelector` was used instead of node affinity (functionally right, wrong mechanism per the task).
</details>

<details>
<summary>Task 16 — drain and return (5 pts)</summary>

```bash
test -s /opt/course/16/.pre-drain-uids && \
  ! k -n e1-drain get pods -o jsonpath='{.items[*].metadata.uid}' | tr ' ' '\n' | grep -qxFf /opt/course/16/.pre-drain-uids \
  && echo "pre-drain pods evicted"
test "$(k get node lab-worker2 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')" = "True" && echo "ready"
! k get node lab-worker2 -o jsonpath='{.spec.unschedulable}' | grep -q true && echo "schedulable"
test "$(k -n e1-drain get deploy web -o jsonpath='{.status.readyReplicas}')" = "4" && echo "web back"
```

**Pass:** the pre-drain Pod UIDs recorded by the setup are **all gone** (the drain really happened — an untouched node fails here even though `Ready` and `web back` would pass), the node is `Ready` and schedulable, and all 4 replicas are back. **Partial credit:** yes — 3 pts if the drain was correct but the node was left cordoned (half the task).
</details>

<details>
<summary>Task 17 — Deployment + PDB (4 pts)</summary>

```bash
test "$(k -n e1-pay get deploy pay -o jsonpath='{.status.readyReplicas}')" = "3" && echo "3 running"
test "$(k -n e1-pay get pdb pay-pdb -o jsonpath='{.spec.minAvailable}')" = "2" && echo "pdb ok"
```

**Pass:** both. **Partial credit:** yes — 2 pts for the Deployment alone.
</details>

### Score sheet — Exam 1

| # | Domain | Env | Pts | Pass criterion |
|---|---|---|---|---|
| 1 | Cluster Arch | vms | 10 | snapshot valid + `e1-archive` restored + `archive-web` ready |
| 2 | Troubleshooting | vms | 8 | `w1` Ready, kubelet active **and** enabled |
| 3 | Troubleshooting | vms | 7 | scheduler Pod back, new Pod schedules, 4 manifests |
| 4 | Troubleshooting | kind | 6 | helm release upgraded, `site` answers, file written |
| 5 | Cluster Arch | kind | 6 | SA can list/watch pods in `e1-rbac` only, file written |
| 6 | Workloads | kind | 5 | rolled back to `nginx:1.25`, file written |
| 7 | Svc & Net | kind | 8 | netpol matrix `mismatches: 0` |
| 8 | Storage | kind | 8 | PV/PVC/pod bound, file + marker written |
| 9 | Troubleshooting | kind | 5 | `logger` running |
| 10 | Troubleshooting | kind | 5 | `pgdata` Bound to `pg-vol`, claim untouched |
| 11 | Svc & Net | kind | 6 | `shop.local` and `api.local` answer |
| 12 | Svc & Net | kind | 4 | bare `http://records` works from `e1-client` |
| 13 | Svc & Net | kind | 4 | NodePort answers, file written |
| 14 | Cluster Arch | vms | 4 | days match `check-expiration` apiserver row |
| 15 | Workloads | kind | 5 | 3 replicas on the `disk=ssd` node |
| 16 | Cluster Arch | kind | 5 | `web` Pods evicted, `lab-worker2` uncordoned, `web` 4/4 |
| 17 | Workloads | kind | 4 | `pay` 3/3 + `pay-pdb` minAvailable 2 |
| | | | **100** | **pass ≈ 66 pts** |

**Interpretation.** 66/100 is a pass. You could leave one entire vms break-fix (Task 1 or 3) on the table and still pass — but only if the kind tasks are clean. If you score under 66, look at the domain column, not the total: a cluster of losses in Troubleshooting means more runbook reps ([T4.25](../part4-cka/T4.25-troubleshoot-cluster-components.md)–[T4.27](../part4-cka/T4.27-troubleshoot-services-and-networking.md)), not more YAML drills.

### Cleanup — Exam 1

```bash
# kind
k config use-context kind-lab
for n in $(k get ns -o name | grep 'namespace/e1-' | cut -d/ -f2); do k delete ns "$n" --wait=false; done
k delete pv e1-pv pg-vol --ignore-not-found
k label node lab-worker disk- 2>/dev/null || true
k uncordon lab-worker2 2>/dev/null || true
for n in lab-control-plane lab-worker lab-worker2; do docker exec $n rm -rf /mnt/e1data /mnt/pg-vol 2>/dev/null; done
sudo rm -rf /opt/course
# optional, if the cluster will not be reused soon:
helm uninstall traefik -n traefik 2>/dev/null; helm uninstall metallb -n metallb-system 2>/dev/null

# vms (on cp1, as root)
k delete ns e1-archive --ignore-not-found
# if etcd was left running from /var/lib/etcd-restore, move the data back to /var/lib/etcd
# (same procedure as T4.04 Lab A cleanup) so the next exam starts clean
rm -rf /opt/course /root/etcd.yaml.bak
# on w1: nothing to undo once kubelet is enabled+started
```

---

# Exam 2 — "Maintenance weekend"

## Environment plan

| Env | Tasks | Needs before the clock |
|---|---|---|
| `kind` (context `kind-lab`) | 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17 | Standard `lab` cluster. Add-ons for tasks 9, 11 and 12: `helm`, `metallb` + pool, `traefik`, `metrics-server` — installed by Appendix 2A. |
| `vms` (`cp1`, `w1`, `w2`; kubeadm, Calico, etcd 3.7.0) | 1, 2, 3, 4, 5 | **Cluster built at v1.36.5** (v1.36 apt repo, `env/vm-prereqs.sh`, `kubeadm init` per [T4.02](../part4-cka/T4.02-create-and-manage-kubernetes-clusters-using.md)). `etcdctl`/`etcdutl` on `cp1`. Appendix 2A brings the VMs to that state and injects the timed faults. |

This exam is the kubeadm-heavy one: 5 of 17 tasks are on the `vms` cluster. One injected fault blocks the other `vms` tasks until you find and repair it — work out the order yourself. That is intentional.

## Tasks

### Task 1 — 7 min · 7 pts · Troubleshooting · `vms`

> `ssh cp1`, `sudo -i`, `export KUBECONFIG=/etc/kubernetes/admin.conf`

Every `kubectl` command on `cp1` fails — not with a connection error, but with `Forbidden`, even for cluster-admin. The control-plane containers are running. Restore normal API access. Do not fix this by restoring files from backup; find the cause.

### Task 2 — 7 min · 7 pts · Troubleshooting · `vms`

> `ssh cp1`, `sudo -i`, `export KUBECONFIG=/etc/kubernetes/admin.conf`

Worker `w1` reports `NotReady` and `kubectl describe node w1` reports the container runtime as down. Restore the node to `Ready` — the fix must survive a reboot.

### Task 3 — 7 min · 6 pts · Cluster Architecture · `vms`

> `ssh cp1`, `sudo -i`, `export KUBECONFIG=/etc/kubernetes/admin.conf`

Worker `w2` was re-imaged with `kubeadm reset` and removed from the cluster. Generate a fresh join command on `cp1`, re-join `w2`, and bring it to `Ready`. Save the join command you used into `/opt/course/03/join.sh`.

### Task 4 — 11 min · 9 pts · Cluster Architecture · `vms`

> `ssh cp1`, `sudo -i`, `export KUBECONFIG=/etc/kubernetes/admin.conf`

Upgrade the control-plane node `cp1` of the kubeadm cluster from v1.36.5 to **v1.37.1** — kubeadm first, then the node, draining and uncordoning as needed. When done, `cp1` must report `Ready` at v1.37.1 and the cluster must still serve requests.

### Task 5 — 5 min · 4 pts · Cluster Architecture · `vms`

> `ssh cp1`, `sudo -i`, `export KUBECONFIG=/etc/kubernetes/admin.conf`

Create an etcd snapshot at `/opt/course/05/etcd-snapshot.db`. Then write the table-formatted output of a snapshot status check on that file into `/opt/course/05/snapshot-status.txt`.

### Task 6 — 6 min · 6 pts · Cluster Architecture · `kind`

> `kubectl config use-context kind-lab`

The CustomResourceDefinition `reports.lab.example.com` is installed and namespace `e2-crd` exists. Applying `/opt/course/06/report.yaml` is rejected by the API server. Read the CRD's schema, fix the manifest, and get a `Report` named `report-a` accepted in `e2-crd` — keep the manifest's `spec.note` value as written.

### Task 7 — 6 min · 7 pts · Services & Networking · `kind`

> `kubectl config use-context kind-lab`

In namespace `e2-net`, the NetworkPolicy `db-guard` should let Pods labelled `role=client` reach Pod `db` on TCP 5432 — and nothing else. Right now even `client` is refused. Fix the policy so the intended flow works and everything else stays denied. Do not delete the policy.

### Task 8 — 6 min · 6 pts · Troubleshooting · `kind`

> `kubectl config use-context kind-lab`

Service `api` in namespace `e2-api` refuses connections — `kubectl get endpoints api` shows no usable addresses even though both Pods of Deployment `api` are `Running`. Restore the Service's endpoints without deleting the Service.

### Task 9 — 6 min · 7 pts · Services & Networking · `kind`

> `kubectl config use-context kind-lab`

Requests to `http://shop.local/` through Ingress `shop` in namespace `e2-ing` return an error page instead of the shop site. The backend Service `shop` on port 80 is healthy. Fix the Ingress so the page is served.

### Task 10 — 6 min · 6 pts · Troubleshooting · `kind`

> `kubectl config use-context kind-lab`

Deployment `ingest` in namespace `e2-jobs` restarts over and over — `kubectl describe` shows the containers are being killed, not crashing on their own. Find the cause and make a stable, `Running` Deployment. Record the container's `lastState` reason word (e.g. `OOMKilled`) in `/opt/course/10/reason.txt`.

### Task 11 — 6 min · 4 pts · Troubleshooting · `kind`

> `kubectl config use-context kind-lab`

Something in namespace `e2-load` is burning CPU and starving its neighbours. Using `kubectl top`, identify the busiest Pod in `e2-load` and write its name to `/opt/course/11/noisy.txt`. Then use `kubectl logs` to copy that Pod's most recent log line into `/opt/course/11/last-log.txt`.

### Task 12 — 6 min · 6 pts · Workloads & Scheduling · `kind`

> `kubectl config use-context kind-lab`

Create a HorizontalPodAutoscaler `web` in namespace `e2-hpa` for the existing Deployment `web`: target CPU utilization 50%, minimum 2 replicas, maximum 6. Confirm it starts reporting metrics.

### Task 13 — 6 min · 6 pts · Workloads & Scheduling · `kind`

> `kubectl config use-context kind-lab`

The two Pods of Deployment `batch` in namespace `e2-batch` are `Pending`. They must keep running only on nodes in the `edge` zone — do not remove or loosen the existing node affinity, and do not remove the node's taint. Make the Pods schedule.

### Task 14 — 4 min · 3 pts · Workloads & Scheduling · `kind`

> `kubectl config use-context kind-lab`

Create a ResourceQuota `quota` in namespace `e2-shop` limiting the namespace to at most 10 Pods, 4 CPU of total requests, 8Gi of total memory requests, and 8 CPU of total limits.

### Task 15 — 6 min · 6 pts · Storage · `kind`

> `kubectl config use-context kind-lab`

Claim `cache` in namespace `e2-data` is `Pending` — it asks for StorageClass `fast`, which does not exist. Create a `fast` StorageClass using the cluster's existing provisioner so the claim binds and Pod `cache-pod` reaches `Running`.

### Task 16 — 6 min · 5 pts · Storage · `kind`

> `kubectl config use-context kind-lab`

Deployment `assets` in namespace `e2-assets` stores data on an `emptyDir` at `/data` — every restart loses it. Create a PersistentVolumeClaim `assets-pvc` (200Mi, ReadWriteOnce, default storage class) and reconfigure the Deployment to mount the claim at `/data` instead.

### Task 17 — 5 min · 5 pts · Services & Networking · `kind`

> `kubectl config use-context kind-lab`

Create a headless Service `db-hl` in namespace `e2-store` selecting `app=db` on port 80. Verify that resolving `db-hl.e2-store.svc.cluster.local` returns the backend Pod's IP, and write that IP into `/opt/course/17/db-ip.txt`.

## Appendix 2A — setup (run BEFORE the clock)

**Part 1 — vms build and faults.** The kubeadm cluster must be at **v1.36.5** when the timer starts. If your VMs are already at 1.37.x, rebuild them at 1.36.5 with `env/vm-prereqs.sh` (v1.36 repo) and `kubeadm init` per [T4.02](../part4-cka/T4.02-create-and-manage-kubernetes-clusters-using.md). Run the blocks in order — the last one kills `kubectl`.

```bash
# --- on w2 as root (ssh w2; sudo -i): task 3 setup ---
kubeadm reset -f
systemctl stop kubelet
rm -rf /etc/cni/net.d
iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X
exit

# --- on cp1 as root ---
export KUBECONFIG=/etc/kubernetes/admin.conf
alias k=kubectl
k delete node w2 --ignore-not-found
mkdir -p /opt/course/03 /opt/course/05   # task-answer dirs on this host; kind tasks write to the workstation
k get nodes   # cp1 and w1 Ready (w2 gone), all on v1.36.5
exit

# --- on w1 as root: task 2 setup ---
systemctl disable --now containerd
exit

# --- on cp1 as root: task 1 setup — must run LAST, after everything above ---
sed -i 's#--authorization-mode=Node,RBAC#--authorization-mode=AlwaysDeny#' /etc/kubernetes/manifests/kube-apiserver.yaml
echo "setup complete — hand over in ~60 s"
```

**Part 2 — kind setup.** Installs add-ons for task 9 (ingress) and tasks 11–12 (metrics-server), then seeds objects and faults.

```bash
#!/usr/bin/env bash
# run from the repo root so env/kind-addons.sh resolves
set -euo pipefail
shopt -s expand_aliases; alias k=kubectl
k config use-context kind-lab
sudo mkdir -p /opt/course/{06,10,11,17} && sudo chown -R "$USER" /opt/course   # answer files live on this host

# --- add-ons (tasks 9, 11, 12) ---
env/kind-addons.sh helm
export PATH="$HOME/.local/bin:$PATH"
env/kind-addons.sh metallb
PREFIX=$(docker network inspect kind -f '{{range .IPAM.Config}}{{println .Subnet}}{{end}}' | grep -E '^[0-9]+\.[0-9]+\.' | head -1)
case "$PREFIX" in
  */16) BASE=$(echo "$PREFIX" | cut -d. -f1-2); RANGE="${BASE}.255.200-${BASE}.255.220" ;;
  *)    BASE=$(echo "$PREFIX" | cut -d. -f1-3); RANGE="${BASE}.200-${BASE}.220" ;;
esac
until kubectl apply -f - <<YAML
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata: {name: lab-pool, namespace: metallb-system}
spec:
  addresses: [$RANGE]
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata: {name: lab-l2, namespace: metallb-system}
spec:
  ipAddressPools: [lab-pool]
YAML
do echo "waiting for the MetalLB webhook"; sleep 5; done
env/kind-addons.sh traefik
env/kind-addons.sh metrics-server
k -n traefik rollout status deploy/traefik --timeout=300s

# --- task 6 objects ---
mkdir -p /opt/course/06
k create ns e2-crd
cat <<'YAML' | k apply -f -
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: reports.lab.example.com
spec:
  group: lab.example.com
  names:
    kind: Report
    plural: reports
    singular: report
  scope: Namespaced
  versions:
  - name: v1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            required: [mode]
            properties:
              mode:
                type: string
                enum: [fast, slow]
              note:
                type: string
YAML
cat > /opt/course/06/report.yaml <<'YAML'
apiVersion: lab.example.com/v1
kind: Report
metadata:
  name: report-a
  namespace: e2-crd
spec:
  mode: turbo        # not in the schema's enum — the API rejects this manifest
  note: pilot
YAML

# --- task 7 objects ---
k create ns e2-net
k -n e2-net run db --image=busybox:1.36 -l app=db -- \
  sh -c 'mkdir -p /www && echo db-ok > /www/index.html && exec httpd -f -p 5432 -h /www'
k -n e2-net run client --image=busybox:1.36 -l role=client -- sleep 3600
k -n e2-net run other --image=busybox:1.36 -l role=other -- sleep 3600
cat <<'YAML' | k -n e2-net apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-guard
spec:
  podSelector:
    matchLabels: {app: db}
  policyTypes: [Ingress]
  ingress:
  - from:
    - podSelector:
        matchLabels: {role: clinet}
    ports:
    - {protocol: TCP, port: 5432}
YAML

# --- task 8 objects ---
k create ns e2-api
k -n e2-api create deploy api --image=nginx:1.27 --replicas=2
k -n e2-api patch deploy api -p '{"spec":{"template":{"spec":{"containers":[{"name":"nginx","readinessProbe":{"httpGet":{"path":"/healthz","port":80},"periodSeconds":2}}]}}}}'
k -n e2-api expose deploy api --port=80

# --- task 9 objects ---
k create ns e2-ing
k -n e2-ing create deploy shop --image=nginx:1.27
k -n e2-ing expose deploy shop --port=80
cat <<'YAML' | k -n e2-ing apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: shop
spec:
  ingressClassName: traefik
  rules:
  - host: shop.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: shpo
            port:
              number: 8080
YAML

# --- task 10 objects ---
k create ns e2-jobs
cat <<'YAML' | k -n e2-jobs apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ingest
spec:
  replicas: 1
  selector:
    matchLabels: {app: ingest}
  template:
    metadata:
      labels: {app: ingest}
    spec:
      containers:
      - name: c
        image: busybox:1.36
        command: ["sh", "-c", "head -c 200m /dev/zero | tail >/dev/null; sleep 3600"]
        resources:
          requests: {memory: 32Mi}
          limits: {memory: 64Mi}
YAML

# --- task 11 objects ---
mkdir -p /opt/course/11
k create ns e2-load
k -n e2-load run quiet-1 --image=busybox:1.36 -- sleep 3600
k -n e2-load run quiet-2 --image=busybox:1.36 -- sleep 3600
k -n e2-load run noisy --image=busybox:1.36 -- yes pressure-marker

# --- task 12 objects ---
k create ns e2-hpa
cat <<'YAML' | k -n e2-hpa apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 2
  selector:
    matchLabels: {app: web}
  template:
    metadata:
      labels: {app: web}
    spec:
      containers:
      - name: nginx
        image: nginx:1.27
        resources:
          requests: {cpu: 100m, memory: 64Mi}
          limits: {cpu: 200m, memory: 128Mi}
YAML

# --- task 13 objects ---
k create ns e2-batch
k label node lab-worker2 zone=edge --overwrite
k taint node lab-worker2 workload=batch:NoSchedule
cat <<'YAML' | k -n e2-batch apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: batch
spec:
  replicas: 2
  selector:
    matchLabels: {app: batch}
  template:
    metadata:
      labels: {app: batch}
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - {key: zone, operator: In, values: [edge]}
      containers:
      - {name: c, image: busybox:1.36, command: ["sleep", "3600"]}
YAML

# --- task 14 namespace ---
k create ns e2-shop

# --- task 15 objects ---
k create ns e2-data
cat <<'YAML' | k -n e2-data apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: cache
spec:
  storageClassName: fast
  accessModes: [ReadWriteOnce]
  resources: {requests: {storage: 500Mi}}
---
apiVersion: v1
kind: Pod
metadata:
  name: cache-pod
spec:
  containers:
  - {name: c, image: busybox:1.36, command: ["sleep", "3600"],
     volumeMounts: [{name: d, mountPath: /data}]}
  volumes:
  - {name: d, persistentVolumeClaim: {claimName: cache}}
YAML

# --- task 16 objects ---
k create ns e2-assets
cat <<'YAML' | k -n e2-assets apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: assets
spec:
  replicas: 1
  selector:
    matchLabels: {app: assets}
  template:
    metadata:
      labels: {app: assets}
    spec:
      containers:
      - name: c
        image: busybox:1.36
        command: ["sh", "-c", "echo seed > /data/seed.txt; sleep 3600"]
        volumeMounts: [{name: d, mountPath: /data}]
      volumes:
      - {name: d, emptyDir: {}}
YAML

# --- task 17 objects ---
k create ns e2-store
k -n e2-store run db --image=busybox:1.36 -l app=db -- sleep 3600

for ns in e2-net e2-ing e2-load e2-hpa e2-assets e2-store; do
  k -n "$ns" wait --for=condition=Ready pod --all --timeout=180s || true
done
echo "kind setup complete"   # e2-api/e2-batch/e2-jobs/e2-data pods intentionally do not go Ready
```

## Appendix 2B — grading

Score each task per its block, then fill the score sheet. Commands are grouped by where they run: `kind-lab` blocks on your workstation; `cp1`, `w1` and `w2` blocks on the named node as root — each over its own ssh session. Exit back to your workstation before switching nodes, and never `ssh` from inside another node.

<details>
<summary>Task 1 — API answers Forbidden (7 pts)</summary>

```bash
test "$(k get --raw=/readyz)" = ok && echo "readyz ok"
k get nodes >/dev/null 2>&1 && echo "kubectl works"
grep 'authorization-mode' /etc/kubernetes/manifests/kube-apiserver.yaml | grep -q 'Node,RBAC' && echo "flag restored"
k -n kube-system get pods | grep -E 'kube-apiserver.*Running' >/dev/null && echo "apiserver running"
```

**Pass:** all four. The fix is editing `--authorization-mode` back to `Node,RBAC` in the apiserver manifest and waiting for the kubelet to restart it. **Partial credit:** yes — 4 pts if the manifest is right but kubectl is still failing because the candidate left a second broken edit in the file.
</details>

<details>
<summary>Task 2 — runtime down on w1 (7 pts)</summary>

```bash
# --- on cp1 as root (ssh cp1; sudo -i) ---
test "$(k get node w1 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')" = "True" && echo "w1 Ready"
# --- on w1 as root (ssh w1; sudo -i — a separate session, exit cp1 first) ---
systemctl is-active containerd | grep -q '^active$' && echo "containerd active"
systemctl is-enabled containerd | grep -q '^enabled$' && echo "containerd enabled"
systemctl is-active kubelet | grep -q '^active$' && echo "kubelet active"
```

**Pass:** all four — `systemctl enable --now containerd` on `w1`. **Partial credit:** yes — 5 pts for `Ready` without `enabled`.
</details>

<details>
<summary>Task 3 — rejoin w2 (6 pts)</summary>

```bash
test "$(k get node w2 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')" = "True" && echo "w2 Ready"
test -s /opt/course/03/join.sh && grep -q 'kubeadm join' /opt/course/03/join.sh && echo "join.sh ok"
test "$(k get node w2 -o jsonpath='{.status.nodeInfo.kubeletVersion}')" = "v1.36.5" && echo "joined at 1.36.5"
```

**Pass:** `w2` `Ready` (version `v1.36.5` is expected — the control plane is still 1.36.5 until task 4). The join command comes from `kubeadm token create --print-join-command`. **Partial credit:** yes — 4 pts for a `Ready` node with a missing/unreadable `join.sh`. If `w2` stays `NotReady` because the CNI never lands, that is a failed join — no points beyond diagnosis.
</details>

<details>
<summary>Task 4 — upgrade cp1 to v1.37.1 (9 pts)</summary>

```bash
test "$(k get node cp1 -o jsonpath='{.status.nodeInfo.kubeletVersion}')" = "v1.37.1" && echo "kubelet 1.37.1"
test "$(k get node cp1 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')" = "True" && echo "Ready"
! k get node cp1 -o jsonpath='{.spec.unschedulable}' | grep -q true && echo "schedulable"
k -n kube-system get pod kube-apiserver-cp1 -o jsonpath='{.spec.containers[0].image}' | grep -q 1.37 && echo "apiserver 1.37"
```

**Pass:** all four — kubeadm, kubelet and kubectl on `cp1` at 1.37.1, node `Ready` and uncordoned. **Partial credit:** yes — 5 pts for `kubeadm upgrade apply` done but kubelet left at 1.36.5; 7 pts if only the uncordon was forgotten.
</details>

<details>
<summary>Task 5 — etcd snapshot + status file (4 pts)</summary>

```bash
etcdutl snapshot status /opt/course/05/etcd-snapshot.db >/dev/null && echo "snapshot valid"
grep -q '^+---' /opt/course/05/snapshot-status.txt && grep -qi 'total keys' /opt/course/05/snapshot-status.txt && echo "status table saved"
```

**Pass:** both — the file must show the `etcdutl snapshot status -w table` grid (the `+---+` border plus the `TOTAL KEYS` column). A `-w json` dump fails on purpose: its `revision`/`hash` keys are not the table the task asked for. **Partial credit:** yes — 3 pts for the snapshot alone.
</details>

<details>
<summary>Task 6 — rejected CustomResource (6 pts)</summary>

```bash
k get crd reports.lab.example.com >/dev/null 2>&1 && echo "crd intact"
k -n e2-crd get report report-a >/dev/null 2>&1 && echo "cr accepted"
M=$(k -n e2-crd get report report-a -o jsonpath='{.spec.mode}'); { [ "$M" = fast ] || [ "$M" = slow ]; } && echo "valid mode: $M"
test "$(k -n e2-crd get report report-a -o jsonpath='{.spec.note}')" = "pilot" && echo "note kept"
```

**Pass:** all four — the candidate read the schema, changed `spec.mode` to an enumerated value, and applied. **Partial credit:** yes — 4 pts if `report-a` exists but `spec.note` was changed or dropped (fixed the rejection, not the manifest faithfully).
</details>

<details>
<summary>Task 7 — NetworkPolicy selector fix (7 pts)</summary>

```bash
k -n e2-net exec client -- nc -z -w2 db.e2-net 5432 >/dev/null 2>&1 && echo "client allowed"
! k -n e2-net exec other -- nc -z -w2 db.e2-net 5432 >/dev/null 2>&1 && echo "other denied"
k -n e2-net get netpol db-guard >/dev/null && echo "policy intact"
k -n e2-net describe netpol db-guard | grep -q 'role=client' && echo "selector fixed"
```

**Pass:** all four. **Partial credit:** yes — 4 pts if `client` connects but `other` also can (over-broad `from:`).
</details>

<details>
<summary>Task 8 — empty EndpointSlice (6 pts)</summary>

```bash
test "$(k -n e2-api get endpointslices -l kubernetes.io/service-name=api -o jsonpath='{range .items[*].endpoints[?(@.conditions.ready==true)]}{.addresses[0]}{"\n"}{end}' | grep -c .)" = "2" && echo "ready endpoints"
test "$(k -n e2-api get deploy api -o jsonpath='{.status.readyReplicas}')" = "2" && echo "pods ready"
k -n e2-api run t-$RANDOM --rm -i --restart=Never --image=busybox:1.36 -- sh -c 'sleep 2; wget -qO- -T3 http://api | grep -o nginx' | grep -q nginx && echo "svc answers"
```

**Pass:** all three — probe path back to `/`. **Partial credit:** no — without ready endpoints there is nothing to grade.
</details>

<details>
<summary>Task 9 — broken Ingress backend (7 pts)</summary>

```bash
test "$(k -n e2-ing get ingress shop -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.name}')" = "shop" && echo "name fixed"
test "$(k -n e2-ing get ingress shop -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.port.number}')" = "80" && echo "port fixed"
LB=$(k -n traefik get svc traefik -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
docker run --rm --network kind curlimages/curl:8.12.1 -s -m5 --resolve "shop.local:80:$LB" http://shop.local/ | grep -qi nginx && echo "page served"
```

**Pass:** all three. **Partial credit:** yes — 4 pts for one of {name, port} fixed (page still fails, partial diagnosis).
</details>

<details>
<summary>Task 10 — OOMKilled (6 pts)</summary>

```bash
test "$(k -n e2-jobs get deploy ingest -o jsonpath='{.status.readyReplicas}')" = "1" && echo "running"
test "$(k -n e2-jobs get pods -l app=ingest -o jsonpath='{.items[0].status.containerStatuses[0].restartCount}')" = "0" && echo "no restarts"
grep -qi oom /opt/course/10/reason.txt && echo "file ok"
```

**Pass:** the Deployment runs without restarts — expected fix is raising the memory limit (e.g. `k -n e2-jobs set resources deploy/ingest --limits=memory=512Mi --requests=memory=64Mi`) — plus the file. **Partial credit:** yes — 4 pts for a correct limit raise with a missing/wrong file.
</details>

<details>
<summary>Task 11 — noisiest Pod (4 pts)</summary>

```bash
TOP=$(k -n e2-load top pod --no-headers | sort -k2 -nr | head -1 | awk '{print $1}')
test -n "$TOP" && echo "metrics available, top is $TOP"
test "$TOP" = "$(cat /opt/course/11/noisy.txt 2>/dev/null)" && echo "noisy identified"
test "$(cat /opt/course/11/last-log.txt 2>/dev/null)" = "$(k -n e2-load logs "$TOP" --tail=1)" && echo "log line ok"
```

**Pass:** all three — `noisy` tops the CPU column and its current last log line (`pressure-marker`) was captured. **Partial credit:** yes — 2 pts for the right Pod name with a wrong or missing log file.
</details>

<details>
<summary>Task 12 — HPA (6 pts)</summary>

```bash
test "$(k -n e2-hpa get hpa web -o jsonpath='{.spec.minReplicas}')" = "2" && \
test "$(k -n e2-hpa get hpa web -o jsonpath='{.spec.maxReplicas}')" = "6" && \
test "$(k -n e2-hpa get hpa web -o jsonpath='{.spec.metrics[0].resource.target.averageUtilization}')" = "50" && echo "hpa correct"
k -n e2-hpa get hpa web | grep -E 'cpu: [0-9]+%/' >/dev/null && echo "metrics flowing"
```

**Pass:** spec correct and `TARGETS` shows a live percentage (may take ~60 s). **Partial credit:** yes — 4 pts for a correct spec with metrics not yet reporting (`<unknown>` — note it as a timing issue, not a fault).
</details>

<details>
<summary>Task 13 — toleration for the tainted zone (6 pts)</summary>

```bash
test "$(k -n e2-batch get deploy batch -o jsonpath='{.status.readyReplicas}')" = "2" && echo "scheduled"
test "$(k -n e2-batch get pods -o jsonpath='{.items[*].spec.nodeName}' | tr ' ' '\n' | sort -u)" = "lab-worker2" && echo "on edge node"
k -n e2-batch get deploy batch -o yaml | grep -q 'workload' && echo "toleration added"
k get node lab-worker2 -o jsonpath='{.spec.taints}' | grep -q 'workload=batch' && echo "taint intact"
```

**Pass:** all four — add toleration `workload=batch:NoSchedule` to the Pod template. **Partial credit:** yes — 3 pts if Pods run but the affinity was deleted instead (violates the constraint).
</details>

<details>
<summary>Task 14 — ResourceQuota (3 pts)</summary>

```bash
test "$(k -n e2-shop get quota quota -o jsonpath='{.spec.hard.pods}' | tr -d '\"')" = "10" && \
test "$(k -n e2-shop get quota quota -o jsonpath='{.spec.hard.requests\.cpu}' | tr -d '\"')" = "4" && \
test "$(k -n e2-shop get quota quota -o jsonpath='{.spec.hard.requests\.memory}' | tr -d '\"')" = "8Gi" && \
test "$(k -n e2-shop get quota quota -o jsonpath='{.spec.hard.limits\.cpu}' | tr -d '\"')" = "8" && echo "quota correct"
```

**Pass:** all four hard limits present. **Partial credit:** no.
</details>

<details>
<summary>Task 15 — missing StorageClass (6 pts)</summary>

```bash
test "$(k get sc fast -o jsonpath='{.provisioner}')" = "rancher.io/local-path" && echo "sc created"
test "$(k -n e2-data get pvc cache -o jsonpath='{.status.phase}')" = "Bound" && echo "bound"
test "$(k -n e2-data get pod cache-pod -o jsonpath='{.status.phase}')" = "Running" && echo "pod running"
```

**Pass:** all three — copy the provisioner (and `volumeBindingMode`) from the existing `standard` class. **Partial credit:** yes — 4 pts if the SC exists but the claim only binds because the candidate changed the PVC's class (the task asked for a `fast` class).
</details>

<details>
<summary>Task 16 — swap emptyDir for a PVC (5 pts)</summary>

```bash
test "$(k -n e2-assets get pvc assets-pvc -o jsonpath='{.status.phase}')" = "Bound" && echo "bound"
test "$(k -n e2-assets get deploy assets -o jsonpath='{.spec.template.spec.volumes[0].persistentVolumeClaim.claimName}')" = "assets-pvc" && echo "deploy uses pvc"
test "$(k -n e2-assets get deploy assets -o jsonpath='{.status.readyReplicas}')" = "1" && echo "running"
```

**Pass:** all three. **Partial credit:** yes — 3 pts for the PVC existing but the Deployment still on `emptyDir`.
</details>

<details>
<summary>Task 17 — headless Service (5 pts)</summary>

```bash
test "$(k -n e2-store get svc db-hl -o jsonpath='{.spec.clusterIP}')" = "None" && echo "headless"
test "$(k -n e2-store get endpointslices -l kubernetes.io/service-name=db-hl -o jsonpath='{.items[0].endpoints[0].addresses[0]}')" != "" && echo "endpoints"
IP=$(k -n e2-store get pod db -o jsonpath='{.status.podIP}'); grep -qx "$IP" /opt/course/17/db-ip.txt && echo "file ok"
```

**Pass:** all three. **Partial credit:** yes — 3 pts for the Service alone.
</details>

### Score sheet — Exam 2

| # | Domain | Env | Pts | Pass criterion |
|---|---|---|---|---|
| 1 | Troubleshooting | vms | 7 | `kubectl` works again (`Node,RBAC` restored) |
| 2 | Troubleshooting | vms | 7 | `w1` Ready, containerd active + enabled |
| 3 | Cluster Arch | vms | 6 | `w2` rejoined and `Ready`, `join.sh` saved |
| 4 | Cluster Arch | vms | 9 | `cp1` v1.37.1, Ready, schedulable |
| 5 | Cluster Arch | vms | 4 | valid snapshot + status table file |
| 6 | Cluster Arch | kind | 6 | `report-a` CR accepted by the schema, `note` kept |
| 7 | Svc & Net | kind | 7 | client→db allowed, others denied, policy intact |
| 8 | Troubleshooting | kind | 6 | `api` has 2 ready endpoints |
| 9 | Svc & Net | kind | 7 | `shop.local` serves the nginx page |
| 10 | Troubleshooting | kind | 6 | `ingest` stable, reason file written |
| 11 | Troubleshooting | kind | 4 | noisiest Pod named, last log line saved |
| 12 | Workloads | kind | 6 | HPA 50%/2–6 reporting metrics |
| 13 | Workloads | kind | 6 | `batch` Pods Running on `lab-worker2`, taint kept |
| 14 | Workloads | kind | 3 | all four quota limits set |
| 15 | Storage | kind | 6 | `fast` SC created, claim Bound |
| 16 | Storage | kind | 5 | Deployment mounts `assets-pvc` |
| 17 | Svc & Net | kind | 5 | headless svc resolves to Pod IP, file written |
| | | | **100** | **pass ≈ 66 pts** |

**Interpretation.** The vms block is 33 points; you cannot pass this exam on kind tasks alone, which is honest — kubeadm lifecycle is the heart of the CKA. The upgrade (9) and the rejoin (6) are the long tasks: if they timed you out, re-run [T4.04](../part4-cka/T4.04-manage-the-lifecycle-of-kubernetes-clusters.md) Lab B until the node-upgrade block is muscle memory.

### Cleanup — Exam 2

```bash
# kind
k config use-context kind-lab
for n in $(k get ns -o name | grep 'namespace/e2-' | cut -d/ -f2); do k delete ns "$n" --wait=false; done
k delete crd reports.lab.example.com --ignore-not-found
k delete sc fast --ignore-not-found
# only PVs whose claim lived in an e2- namespace — never `delete pv --all`, another exam's PVs may exist
for p in $(k get pv -o jsonpath='{range .items[*]}{.spec.claimRef.namespace}{" "}{.metadata.name}{"\n"}{end}' | awk '$1 ~ /^e2-/ {print $2}'); do k delete pv "$p" --ignore-not-found; done
k label node lab-worker2 zone- 2>/dev/null || true
k taint node lab-worker2 workload=batch:NoSchedule- 2>/dev/null || true
sudo rm -rf /opt/course
helm uninstall traefik -n traefik 2>/dev/null; helm uninstall metallb -n metallb-system 2>/dev/null

# vms — the cluster is left upgraded to 1.37.1 with w2 rejoined; nothing else to undo.
# For the next exam, rebuild VMs per that exam's stated version.
```

---

# Exam 3 — "Audit day"

## Environment plan

| Env | Tasks | Needs before the clock |
|---|---|---|
| `kind` (context `kind-lab`) | 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17 | Standard `lab` cluster. Add-ons for task 10: `helm`, `metallb`, `gateway-api-crds`, `traefik` — installed by Appendix 3A. |
| `vms` (`cp1`, `w1`, `w2`; kubeadm 1.37.x, Calico, etcd 3.7.0) | 1, 2, 3, 4 | Healthy 1.37.x cluster, `etcdctl`/`etcdutl` on `cp1`. Appendix 3A stages the objects and injects the timed faults. |

One injected fault blocks the other `vms` tasks until you find and repair it. That is deliberate — real incident work is ordered by dependencies, not by task number.

## Tasks

### Task 1 — 10 min · 10 pts · Cluster Architecture · `vms`

> `ssh cp1`, `sudo -i`, `export KUBECONFIG=/etc/kubernetes/admin.conf`

Namespace `e3-critical` — containing Deployment `crit-app` and ConfigMap `crit-cfg` — has disappeared from the kubeadm cluster. A colleague left an etcd snapshot at `/opt/course/01/pre-loss.db`. Verify the snapshot and restore the lost namespace and its objects; etcd must keep running afterwards.

### Task 2 — 8 min · 7 pts · Troubleshooting · `vms`

> `ssh cp1`, `sudo -i`, `export KUBECONFIG=/etc/kubernetes/admin.conf`

`kubectl` on `cp1` fails with a connection error and the control plane looks broken. Find the fault and restore API access. When done, `kubectl get nodes` must work and all kube-system Pods must be `Running`.

### Task 3 — 7 min · 8 pts · Troubleshooting · `vms`

> `ssh cp1`, `sudo -i`, `export KUBECONFIG=/etc/kubernetes/admin.conf`

Node `w1` went `NotReady` after an OS maintenance reboot. Restore it — and make sure the same fault does not come back at the *next* reboot.

### Task 4 — 5 min · 4 pts · Cluster Architecture · `vms`

> `ssh cp1`, `sudo -i`, `export KUBECONFIG=/etc/kubernetes/admin.conf`

On node `w1`, create a static Pod running `nginx:1.27` named `e3-static` in namespace `e3-sys`. Confirm the API shows the Pod as `Running`.

### Task 5 — 6 min · 6 pts · Cluster Architecture · `kind`

> `kubectl config use-context kind-lab`

In namespace `e3-sec`, grant ServiceAccount `node-reader` the ability to `get` and `list` **Nodes** — cluster-wide, and nothing else. Verify with `kubectl auth can-i`, and record the answers for `list nodes` and for `delete nodes` in `/opt/course/05/rbac-check.txt`.

### Task 6 — 7 min · 5 pts · Services & Networking · `kind`

> `kubectl config use-context kind-lab`

Pods cluster-wide resolve in-cluster names but nothing outside: `nslookup kubernetes.default.svc.cluster.local` answers, `nslookup www.kubernetes.io` times out. The cause is a recent change to CoreDNS itself. Restore external name resolution for the whole cluster without breaking in-cluster names.

### Task 7 — 5 min · 5 pts · Troubleshooting · `kind`

> `kubectl config use-context kind-lab`

Pod `client` in namespace `e3-dns` cannot resolve `data.e3-dns.svc.cluster.local` — the Service exists with ready endpoints, and other Pods resolve it normally. Fix `client` without touching the Service.

### Task 8 — 5 min · 5 pts · Troubleshooting · `kind`

> `kubectl config use-context kind-lab`

Namespace `e3-quota` needs 6 replicas of Deployment `web` — `kubectl scale` accepts the change, yet only 4 Pods ever run and the ReplicaSet events show `FailedCreate` errors (`forbidden: exceeded quota`). Make all 6 run. The ResourceQuota `compute` exists for a reason: change only that object and the Deployment's replica count — nothing else.

### Task 9 — 7 min · 8 pts · Services & Networking · `kind`

> `kubectl config use-context kind-lab`

In namespace `e3-net`, NetworkPolicies already exist and **must not be modified or deleted**. Pod `monitor` must be able to reach `web` on TCP 80, and Pod `web` must be able to reach `api` on TCP 8080 — currently both fail. Inspect the policies' selectors and label the **Pods** so the intended flows work. Pod `rogue` must not gain access to anything.

### Task 10 — 7 min · 7 pts · Services & Networking · `kind`

> `kubectl config use-context kind-lab`

In namespace `e3-gw`, create a Gateway `main` (use the installed GatewayClass) listening on HTTP port 80, and an HTTPRoute `web` that routes host `gw.local` to Service `web` port 80. Verify `curl` to the Gateway's address with `Host: gw.local` returns the web page.

### Task 11 — 6 min · 5 pts · Workloads & Scheduling · `kind`

> `kubectl config use-context kind-lab`

Create a DaemonSet `node-agent` in namespace `e3-agents` running `nginx:1.27` on **every** node of the cluster — including the control-plane node. Record the number of running agent Pods in `/opt/course/11/agents.txt`.

### Task 12 — 6 min · 5 pts · Workloads & Scheduling · `kind`

> `kubectl config use-context kind-lab`

The two replicas of Deployment `ha-web` in namespace `e3-ha` must never share a node. Add a required pod anti-affinity (topology key `kubernetes.io/hostname`) and roll it out so the Pods sit on different nodes.

### Task 13 — 5 min · 4 pts · Workloads & Scheduling · `kind`

> `kubectl config use-context kind-lab`

In namespace `e3-jobs`, create a Job `etl` running `busybox:1.36` with the command `sh -c 'echo done'`: `completions: 3`, `parallelism: 2`, `backoffLimit: 4`. Wait for it to finish and write the number of succeeded Pods into `/opt/course/13/etl-count.txt`.

### Task 14 — 6 min · 6 pts · Troubleshooting · `kind`

> `kubectl config use-context kind-lab`

Deployment `writer` in namespace `e3-ws` cannot write to its mounted volume — the logs show `Permission denied` even though the Pod keeps running. Fix the security context so the write succeeds; do not change the volume type, the mount path, or the init container.

### Task 15 — 6 min · 5 pts · Storage · `kind`

> `kubectl config use-context kind-lab`

PersistentVolume `keep` holds data that must not be deleted, but its reclaim policy is `Delete`. Change it to `Retain` — the claim `keep-claim` in `e3-vault` must stay `Bound` throughout.

### Task 16 — 6 min · 5 pts · Cluster Architecture · `kind`

> `kubectl config use-context kind-lab`

A Kustomize overlay at `/opt/course/16/app/overlays/prod` fails to build (`kubectl apply -k` errors). Fix the error and apply it so its Deployment runs in the `prod` namespace.

### Task 17 — 6 min · 5 pts · Storage · `kind`

> `kubectl config use-context kind-lab`

In namespace `e3-docs`: create a PersistentVolume `shared` (hostPath `/mnt/shared`, 2Gi, `ReadWriteMany`, `Retain`, class `manual`), a claim `shared` requesting 1Gi RWX, and a Deployment `docs` (2 replicas, `nginx:1.27`) mounting the claim at `/usr/share/nginx/html`.

## Appendix 3A — setup (run BEFORE the clock)

**Part 1 — vms setup.** Order matters: run the blocks in the order shown.

```bash
# --- on cp1 as root ---
export KUBECONFIG=/etc/kubernetes/admin.conf
alias k=kubectl
mkdir -p /opt/course/01   # the only /opt/course dir needed on cp1; kind tasks write to the workstation
k get nodes   # all Ready, healthy 1.37.x

# task 1 setup — e3-sys is created BEFORE the snapshot so the restore does not erase it (task 4 needs it)
k create ns e3-critical
k -n e3-critical create deploy crit-app --image=nginx:1.27 --replicas=2
k -n e3-critical create configmap crit-cfg --from-literal=env=prod
k -n e3-critical rollout status deploy/crit-app --timeout=180s
k create ns e3-sys
k get ns e3-critical -o jsonpath='{.metadata.uid}' > /opt/course/01/.ns-uid   # grader fixture: proves the namespace came back from the snapshot, not a hand-recreate
ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save /opt/course/01/pre-loss.db
etcdutl snapshot status /opt/course/01/pre-loss.db -w table   # must print a valid status
k delete ns e3-critical

# task 2 setup
sed -i 's#path: /etc/kubernetes/pki/etcd$#path: /etc/kubernetes/pki/etcd-miss#' /etc/kubernetes/manifests/etcd.yaml
exit

# --- on w1 as root: task 3 setup ---
fallocate -l 512M /swap-mock
chmod 600 /swap-mock
mkswap /swap-mock >/dev/null
swapon /swap-mock
echo '/swap-mock none swap sw 0 0' >> /etc/fstab
systemctl restart kubelet
exit

# done — wait ~90 s, then hand over
```

**Part 2 — kind setup.**

```bash
#!/usr/bin/env bash
# run from the repo root so env/kind-addons.sh resolves
set -euo pipefail
shopt -s expand_aliases; alias k=kubectl
k config use-context kind-lab
sudo mkdir -p /opt/course/{05,11,13,16} && sudo chown -R "$USER" /opt/course   # answer files live on this host

# --- add-ons (tasks 6, 10) ---
env/kind-addons.sh helm
export PATH="$HOME/.local/bin:$PATH"
env/kind-addons.sh metallb
env/kind-addons.sh gateway-api-crds
# address pool for the cluster's LoadBalancer services
PREFIX=$(docker network inspect kind -f '{{range .IPAM.Config}}{{println .Subnet}}{{end}}' | grep -E '^[0-9]+\.[0-9]+\.' | head -1)
case "$PREFIX" in
  */16) BASE=$(echo "$PREFIX" | cut -d. -f1-2); ONE="${BASE}.255.200" ;;
  *)    BASE=$(echo "$PREFIX" | cut -d. -f1-3); ONE="${BASE}.200" ;;
esac
until kubectl apply -f - <<YAML
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata: {name: lab-pool, namespace: metallb-system}
spec:
  addresses: [$ONE-$ONE]
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata: {name: lab-l2, namespace: metallb-system}
spec:
  ipAddressPools: [lab-pool]
YAML
do echo "waiting for the MetalLB webhook"; sleep 5; done
env/kind-addons.sh traefik
k -n traefik rollout status deploy/traefik --timeout=300s
k -n traefik get svc traefik   # EXTERNAL-IP must equal the single pool address

# --- task 5 objects ---
k create ns e3-sec
k -n e3-sec create serviceaccount node-reader

# --- task 6 objects ---
# poison CoreDNS's forward block — in-cluster names keep resolving, external names time out
k -n kube-system get cm coredns -o yaml | \
  sed 's#forward \. /etc/resolv.conf#forward . 10.96.0.99#' | k apply -f -
k -n kube-system get cm coredns -o jsonpath='{.data.Corefile}' | grep -q '10.96.0.99' \
  || { echo "Corefile has no 'forward . /etc/resolv.conf' line — adjust the fault first"; exit 1; }
k -n kube-system rollout restart deploy/coredns
k -n kube-system rollout status deploy/coredns --timeout=120s

# --- task 7 objects ---
k create ns e3-dns
k -n e3-dns run data --image=busybox:1.36 -l app=data -- \
  sh -c 'mkdir -p /www && echo data-ok > /www/index.html && exec httpd -f -p 80 -h /www'
k -n e3-dns expose pod data --port=80
cat <<'YAML' | k -n e3-dns apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: client
spec:
  dnsPolicy: None
  dnsConfig:
    nameservers: ["8.8.8.8"]
  containers:
  - {name: c, image: busybox:1.36, command: ["sleep", "3600"]}
YAML

# --- task 8 objects ---
k create ns e3-quota
k -n e3-quota create deploy web --image=nginx:1.27 --replicas=3
cat <<'YAML' | k -n e3-quota apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute
spec:
  hard:
    pods: "4"
YAML
k -n e3-quota rollout status deploy/web --timeout=180s

# --- task 9 objects ---
k create ns e3-net
k -n e3-net run web --image=busybox:1.36 -l app=web -- \
  sh -c 'mkdir -p /www && echo web-ok > /www/index.html && exec httpd -f -p 80 -h /www'
k -n e3-net run api --image=busybox:1.36 -l app=api -- \
  sh -c 'mkdir -p /www && echo api-ok > /www/index.html && exec httpd -f -p 8080 -h /www'
k -n e3-net run monitor --image=busybox:1.36 -l app=monitor -- sleep 3600
k -n e3-net run rogue --image=busybox:1.36 -l app=rogue -- sleep 3600
k -n e3-net expose pod web --port=80
k -n e3-net expose pod api --port=8080
cat <<'YAML' | k -n e3-net apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: web-in
spec:
  podSelector:
    matchLabels: {app: web}
  policyTypes: [Ingress]
  ingress:
  - from:
    - podSelector:
        matchLabels: {netpol-access: web}
    ports:
    - {protocol: TCP, port: 80}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-in
spec:
  podSelector:
    matchLabels: {app: api}
  policyTypes: [Ingress]
  ingress:
  - from:
    - podSelector:
        matchLabels: {netpol-access: api}
    ports:
    - {protocol: TCP, port: 8080}
YAML

# --- task 10 objects ---
k create ns e3-gw
k -n e3-gw run web --image=busybox:1.36 -l app=web -- \
  sh -c 'mkdir -p /www && echo gw-web-ok > /www/index.html && exec httpd -f -p 80 -h /www'
k -n e3-gw expose pod web --port=80

# --- tasks 11, 13, 17: namespaces ---
k create ns e3-agents
k create ns e3-jobs
k create ns e3-docs

# --- task 12 objects ---
k create ns e3-ha
k -n e3-ha create deploy ha-web --image=nginx:1.27 --replicas=2

# --- task 14 objects ---
k create ns e3-ws
cat <<'YAML' | k -n e3-ws apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: writer
spec:
  replicas: 1
  selector:
    matchLabels: {app: writer}
  template:
    metadata:
      labels: {app: writer}
    spec:
      securityContext:
        runAsUser: 1000
      initContainers:
      - name: prep
        image: busybox:1.36
        securityContext:
          runAsUser: 0   # needs root to set the ownership the task is about
        command: ["sh", "-c", "chown 0:2000 /data && chmod 2770 /data"]
        volumeMounts: [{name: d, mountPath: /data}]
      containers:
      - name: c
        image: busybox:1.36
        command: ["sh", "-c", "echo report > /data/out.txt; sleep 3600"]
        volumeMounts: [{name: d, mountPath: /data}]
      volumes:
      - {name: d, emptyDir: {}}
YAML

# --- task 15 objects ---
k create ns e3-vault
cat <<'YAML' | k apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: keep
spec:
  capacity: {storage: 1Gi}
  accessModes: [ReadWriteOnce]
  persistentVolumeReclaimPolicy: Delete
  storageClassName: manual
  hostPath: {path: /mnt/keep, type: DirectoryOrCreate}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: keep-claim
  namespace: e3-vault
spec:
  storageClassName: manual
  accessModes: [ReadWriteOnce]
  resources: {requests: {storage: 1Gi}}
---
apiVersion: v1
kind: Pod
metadata:
  name: vault-pod
  namespace: e3-vault
spec:
  containers:
  - {name: c, image: busybox:1.36, command: ["sleep", "3600"],
     volumeMounts: [{name: d, mountPath: /data}]}
  volumes:
  - {name: d, persistentVolumeClaim: {claimName: keep-claim}}
YAML

# --- task 16 files ---
mkdir -p /opt/course/16/app/base /opt/course/16/app/overlays/prod
cat > /opt/course/16/app/base/kustomization.yaml <<'EOF'
resources:
- deploy.yaml
- svc.yaml
EOF
cat > /opt/course/16/app/base/deploy.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop
spec:
  replicas: 1
  selector:
    matchLabels: {app: shop}
  template:
    metadata:
      labels: {app: shop}
    spec:
      containers:
      - {name: nginx, image: nginx:1.27}
EOF
cat > /opt/course/16/app/base/svc.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: shop
spec:
  selector: {app: shop}
  ports: [{port: 80}]
EOF
cat > /opt/course/16/app/overlays/prod/kustomization.yaml <<'EOF'
namespace: prod
namePrefix: prod-
resources:
- ../../basee
- ns.yaml
EOF
cat > /opt/course/16/app/overlays/prod/ns.yaml <<'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: prod
EOF

for ns in e3-dns e3-net e3-gw e3-ha e3-vault; do
  k -n "$ns" wait --for=condition=Ready pod --all --timeout=180s || true
done
echo "kind setup complete"   # the e3-ws pod runs but logs 'Permission denied' on its /data write
```

## Appendix 3B — grading

Score each task per its block, then fill the score sheet. Commands are grouped by where they run: `kind-lab` blocks on your workstation; `cp1`, `w1` and `w2` blocks on the named node as root — each over its own ssh session. Exit back to your workstation before switching nodes, and never `ssh` from inside another node.

<details>
<summary>Task 1 — restore the lost namespace (10 pts)</summary>

```bash
etcdutl snapshot status /opt/course/01/pre-loss.db >/dev/null && echo "snapshot was usable"
k get ns e3-critical -o name | grep -qx namespace/e3-critical && echo "ns back"
test "$(k get ns e3-critical -o jsonpath='{.metadata.uid}')" = "$(cat /opt/course/01/.ns-uid)" && echo "uid matches the snapshot"
test "$(k -n e3-critical get cm crit-cfg -o jsonpath='{.data.env}')" = "prod" && echo "cm back"
test "$(k -n e3-critical get deploy crit-app -o jsonpath='{.status.readyReplicas}')" = "2" && echo "deploy ready"
ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key endpoint health | grep -q 'is healthy' && echo "etcd healthy"
```

**Pass:** all six — the namespace UID comparison is what proves a real restore (a hand-recreated namespace gets a fresh UID and fails). **Partial credit:** yes — 6 pts if the restore was attempted and the snapshot verified but the namespace never reappeared (data-dir not switched, or caches not restarted); 3 pts for a verified snapshot with no restore.
</details>

<details>
<summary>Task 2 — etcd down (7 pts)</summary>

```bash
k get nodes >/dev/null 2>&1 && echo "kubectl works"
test "$(k get --raw=/readyz)" = ok && echo "readyz ok"
test "$(k -n kube-system get pods --no-headers | grep -cv Running)" = "0" && echo "system pods running"
grep 'path: /etc/kubernetes/pki/etcd$' /etc/kubernetes/manifests/etcd.yaml >/dev/null && echo "mount restored"
```

**Pass:** all four — the `etcd-certs` hostPath points back at `/etc/kubernetes/pki/etcd`. **Partial credit:** yes — 4 pts if the manifest is right but a system Pod still fails (stale container, or a second fault the candidate introduced).
</details>

<details>
<summary>Task 3 — swap after reboot (8 pts)</summary>

```bash
# --- on cp1 as root (ssh cp1; sudo -i) ---
test "$(k get node w1 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')" = "True" && echo "w1 Ready"
# --- on w1 as root (ssh w1; sudo -i — a separate session, exit cp1 first) ---
systemctl is-active kubelet | grep -q '^active$' && echo "kubelet active"
test "$(swapon --show --noheadings | wc -l)" = "0" && echo "no swap"
test "$(grep -c '^[^#].*swap' /etc/fstab)" = "0" && echo "fstab clean"
```

**Pass:** node `Ready`, swap off, **and** no *active* swap line left in `fstab` — deleting or commenting the entry both count (commented lines do not match `^[^#]`), and the `/swap-mock` file itself may stay. **Partial credit:** yes — 5 pts for `Ready` with the fstab line still active (the fault returns at the next reboot).
</details>

<details>
<summary>Task 4 — static Pod (4 pts)</summary>

```bash
# --- on cp1 as root (ssh cp1; sudo -i) ---
k -n e3-sys get pod -o jsonpath='{.items[0].metadata.name}' | grep -q '^e3-static-w1$' && echo "mirror pod"
test "$(k -n e3-sys get pod e3-static-w1 -o jsonpath='{.status.phase}')" = "Running" && echo "running"
# --- on w1 as root (ssh w1; sudo -i — a separate session, exit cp1 first) ---
test "$(ls /etc/kubernetes/manifests | wc -l)" -ge 1 && echo "manifest on node"   # any filename works
```

**Pass:** all three — the manifest lives in `w1:/etc/kubernetes/manifests`, the mirror Pod `e3-static-w1` runs in `e3-sys`. **Partial credit:** no.
</details>

<details>
<summary>Task 5 — cluster-wide read on Nodes (6 pts)</summary>

```bash
k auth can-i list nodes --as=system:serviceaccount:e3-sec:node-reader | grep -qx yes && echo "list yes"
k auth can-i get nodes --as=system:serviceaccount:e3-sec:node-reader | grep -qx yes && echo "get yes"
k auth can-i delete nodes --as=system:serviceaccount:e3-sec:node-reader | grep -qx no && echo "delete no"
k auth can-i list pods --as=system:serviceaccount:e3-sec:node-reader | grep -qx no && echo "pods no"
grep -q yes /opt/course/05/rbac-check.txt && grep -q no /opt/course/05/rbac-check.txt && echo "file ok"
```

**Pass:** nodes get/list `yes`, delete `no`, pods `no`, file written — needs a `ClusterRole` + `ClusterRoleBinding` (a `Role` cannot grant cluster-scoped `nodes`). **Partial credit:** yes — 4 pts for correct grants with a missing file.
</details>

<details>
<summary>Task 6 — dead forwarder (5 pts)</summary>

```bash
! k -n kube-system get cm coredns -o jsonpath='{.data.Corefile}' | grep -q '10.96.0.99' && echo "poison forward gone"
k -n kube-system rollout status deploy/coredns --timeout=60s >/dev/null && echo "coredns rolled out"
k run dns-ext-$RANDOM --rm -i --restart=Never --image=busybox:1.36 -- nslookup -timeout=5 www.kubernetes.io >/dev/null 2>&1 && echo "external resolves"
k run dns-int-$RANDOM --rm -i --restart=Never --image=busybox:1.36 -- nslookup -timeout=5 kubernetes.default.svc.cluster.local >/dev/null 2>&1 && echo "internal still works"
```

**Pass:** all four — the expected fix is editing the `coredns` ConfigMap's `forward .` line back to `/etc/resolv.conf` (or another reachable resolver) and `k -n kube-system rollout restart deploy/coredns`. A per-Pod `dnsConfig` workaround fails the probes on purpose — the task says restore resolution *for the whole cluster*. **Partial credit:** yes — 3 pts for a corrected Corefile never rolled out (the running coredns Pods still serve the old config, so resolution still times out).
</details>

<details>
<summary>Task 7 — poisoned resolver (5 pts)</summary>

```bash
k -n e3-dns exec client -- nslookup data.e3-dns.svc.cluster.local >/dev/null 2>&1 && echo "resolves"
k -n e3-dns exec client -- sh -c 'wget -qO- -T4 http://data' | grep -q data-ok && echo "answers"
```

**Pass:** both — `dnsPolicy` is immutable, so `client` must be recreated with `ClusterFirst` (the default search list makes the bare `http://data` name work), or with `dnsPolicy: None` plus a `dnsConfig` giving the kube-dns ClusterIP **and** `searches: [e3-dns.svc.cluster.local]` — nameservers alone leave the bare name unresolvable. **Partial credit:** no.
</details>

<details>
<summary>Task 8 — quota blocks the scale-up (5 pts)</summary>

```bash
test "$(k -n e3-quota get deploy web -o jsonpath='{.status.readyReplicas}')" = "6" && echo "6 running"
k -n e3-quota get quota compute >/dev/null && echo "quota still there"
test "$(k -n e3-quota get quota compute -o jsonpath='{.spec.hard.pods}' | tr -d '\"')" -ge 6 && echo "headroom"
```

**Pass:** all three — raise `hard.pods` (≥6) on `compute` and scale `web` to 6. **Partial credit:** yes — 3 pts if 6 run because the quota was deleted (constraint violated).
</details>

<details>
<summary>Task 9 — label the Pods, not the policies (8 pts)</summary>

```bash
k -n e3-net exec monitor -- nc -z -w2 web.e3-net 80 >/dev/null 2>&1 && echo "monitor->web ok"
k -n e3-net exec web -- nc -z -w2 api.e3-net 8080 >/dev/null 2>&1 && echo "web->api ok"
! k -n e3-net exec rogue -- nc -z -w2 web.e3-net 80 >/dev/null 2>&1 && echo "rogue->web denied"
! k -n e3-net exec rogue -- nc -z -w2 api.e3-net 8080 >/dev/null 2>&1 && echo "rogue->api denied"
k -n e3-net get netpol web-in api-in >/dev/null && echo "policies intact"
```

**Pass:** all five — the intended labels are `netpol-access=web` on `monitor` and `netpol-access=api` on `web`. **Partial credit:** yes — 5 pts for the two ALLOW flows with `rogue` also gaining access (over-labelling).
</details>

<details>
<summary>Task 10 — Gateway + HTTPRoute (7 pts)</summary>

```bash
test "$(k -n e3-gw get gateway main -o jsonpath='{.spec.gatewayClassName}')" = "traefik" && echo "gateway exists"
test "$(k -n e3-gw get gateway main -o jsonpath='{.status.conditions[?(@.type=="Programmed")].status}')" = "True" && echo "programmed"
test "$(k -n e3-gw get httproute web -o jsonpath='{.spec.hostnames[0]}')" = "gw.local" && echo "route exists"
IP=$(k -n e3-gw get gateway main -o jsonpath='{.status.addresses[0].value}')
docker run --rm --network kind curlimages/curl:8.12.1 -s -m5 -H 'Host: gw.local' "http://$IP/" | grep -q gw-web-ok && echo "route answers"
```

**Pass:** all four. **Partial credit:** yes — 4 pts for a Programmed Gateway with a route that never serves (wrong backendRef name/port).
</details>

<details>
<summary>Task 11 — DaemonSet everywhere (5 pts)</summary>

```bash
test "$(k -n e3-agents get ds node-agent -o jsonpath='{.status.desiredNumberScheduled}')" = "3" && echo "3 desired"
test "$(k -n e3-agents get ds node-agent -o jsonpath='{.status.numberReady}')" = "3" && echo "3 ready"
k -n e3-agents get pods -o wide | grep -q lab-control-plane && echo "on control plane"
grep -qx 3 /opt/course/11/agents.txt && echo "file ok"
```

**Pass:** all four — the control-plane toleration (`node-role.kubernetes.io/control-plane`) is the point of the task. **Partial credit:** yes — 3 pts for 2/2 on workers only (no toleration).
</details>

<details>
<summary>Task 12 — anti-affinity (5 pts)</summary>

```bash
test "$(k -n e3-ha get deploy ha-web -o jsonpath='{.status.readyReplicas}')" = "2" && echo "2 ready"
test "$(k -n e3-ha get pods -o jsonpath='{.items[*].spec.nodeName}' | tr ' ' '\n' | sort -u | wc -l)" = "2" && echo "different nodes"
k -n e3-ha get deploy ha-web -o yaml | grep -q podAntiAffinity && echo "anti-affinity present"
```

**Pass:** all three — `requiredDuringSchedulingIgnoredDuringExecution` podAntiAffinity on `kubernetes.io/hostname`. **Partial credit:** yes — 3 pts for a soft (`preferred`) rule that happens to spread them today.
</details>

<details>
<summary>Task 13 — parallel Job (4 pts)</summary>

```bash
test "$(k -n e3-jobs get job etl -o jsonpath='{.status.succeeded}')" = "3" && echo "3 succeeded"
test "$(k -n e3-jobs get job etl -o jsonpath='{.spec.parallelism}')" = "2" && echo "parallelism ok"
grep -qx 3 /opt/course/13/etl-count.txt && echo "file ok"
```

**Pass:** all three. **Partial credit:** yes — 2 pts for the Job alone without the file.
</details>

<details>
<summary>Task 14 — permission on the volume (6 pts)</summary>

```bash
test "$(k -n e3-ws get deploy writer -o jsonpath='{.status.readyReplicas}')" = "1" && echo "running"
P=$(k -n e3-ws get pod -l app=writer -o jsonpath='{.items[0].metadata.name}')
test "$(k -n e3-ws exec "$P" -- cat /data/out.txt 2>/dev/null)" = "report" && echo "file written"
k -n e3-ws get deploy writer -o yaml | grep -qE 'fsGroup|supplementalGroups|runAsGroup' && echo "group access set"
```

**Pass:** all three — the init container left `/data` as `2770 root:2000`, so the fix is giving the app container group 2000: `fsGroup: 2000`, `supplementalGroups: [2000]` or `runAsGroup: 2000` at Pod level. **Partial credit:** yes — 4 pts for a working write achieved by `runAsUser: 0` instead (works, but loses the least-privilege point — flag it).
</details>

<details>
<summary>Task 15 — Retain (5 pts)</summary>

```bash
test "$(k get pv keep -o jsonpath='{.spec.persistentVolumeReclaimPolicy}')" = "Retain" && echo "retain"
test "$(k -n e3-vault get pvc keep-claim -o jsonpath='{.status.phase}')" = "Bound" && echo "still bound"
test "$(k -n e3-vault get pod vault-pod -o jsonpath='{.status.phase}')" = "Running" && echo "pod running"
```

**Pass:** all three — a one-line `k patch pv keep`. **Partial credit:** no.
</details>

<details>
<summary>Task 16 — kustomize overlay (5 pts)</summary>

```bash
test "$(k -n prod get deploy prod-shop -o jsonpath='{.status.readyReplicas}')" = "1" && echo "deployed"
k -n prod get svc prod-shop >/dev/null && echo "svc deployed"
kubectl kustomize /opt/course/16/app/overlays/prod >/dev/null 2>&1 && echo "builds clean"
```

**Pass:** all three — the `resources` path must point at `../../base`; the overlay's `ns.yaml` creates the `prod` namespace, so `kubectl apply -k` does the whole job. Grading checks the `prod-` prefix so applying the base directly does not count. **Partial credit:** yes — 3 pts if it deploys but the prefix/namespace was removed (bypassed the overlay).
</details>

<details>
<summary>Task 17 — RWX storage (5 pts)</summary>

```bash
test "$(k get pv shared -o jsonpath='{.spec.accessModes[0]}')" = "ReadWriteMany" && \
test "$(k get pv shared -o jsonpath='{.spec.persistentVolumeReclaimPolicy}')" = "Retain" && \
test "$(k get pv shared -o jsonpath='{.spec.capacity.storage}')" = "2Gi" && echo "pv ok"
test "$(k -n e3-docs get pvc shared -o jsonpath='{.status.phase}')" = "Bound" && echo "bound"
test "$(k -n e3-docs get deploy docs -o jsonpath='{.status.readyReplicas}')" = "2" && echo "2 running"
```

**Pass:** all three. **Partial credit:** yes — 3 pts for a bound claim with the Deployment missing or on the wrong mountPath.
</details>

### Score sheet — Exam 3

| # | Domain | Env | Pts | Pass criterion |
|---|---|---|---|---|
| 1 | Cluster Arch | vms | 10 | `e3-critical` restored from `pre-loss.db`, etcd healthy |
| 2 | Troubleshooting | vms | 7 | etcd cert mount fixed, `kubectl` works |
| 3 | Troubleshooting | vms | 8 | `w1` Ready, swap off, fstab clean |
| 4 | Cluster Arch | vms | 4 | `e3-static-w1` Running |
| 5 | Cluster Arch | kind | 6 | SA gets/lists nodes cluster-wide only |
| 6 | Svc & Net | kind | 5 | external DNS resolves, in-cluster names intact |
| 7 | Troubleshooting | kind | 5 | `client` resolves + answers |
| 8 | Troubleshooting | kind | 5 | 6 `web` replicas running, quota kept |
| 9 | Svc & Net | kind | 8 | monitor→web, web→api flow; rogue denied |
| 10 | Svc & Net | kind | 7 | Gateway Programmed, `gw.local` serves |
| 11 | Workloads | kind | 5 | agent on all 3 nodes, file written |
| 12 | Workloads | kind | 5 | replicas on different nodes |
| 13 | Workloads | kind | 4 | Job `etl` 3 succeeded, file written |
| 14 | Troubleshooting | kind | 6 | `writer` writes with `fsGroup` |
| 15 | Storage | kind | 5 | `keep` Retain, claim Bound |
| 16 | Cluster Arch | kind | 5 | overlay builds, `prod-shop` runs |
| 17 | Storage | kind | 5 | `shared` Bound, `docs` 2/2 |
| | | | **100** | **pass ≈ 66 pts** |

**Interpretation.** The two heaviest items are the etcd pair (Tasks 1–2): together they are worth 17 points and they gate each other — you cannot check Task 1 until Task 2 is fixed. If you burned more than 20 minutes there, your control-plane runbook is the gap; redo [T4.25](../part4-cka/T4.25-troubleshoot-cluster-components.md) Lab 3 under a timer.

### Cleanup — Exam 3

```bash
# kind
k config use-context kind-lab
for n in $(k get ns -o name | grep 'namespace/e3-' | cut -d/ -f2); do k delete ns "$n" --wait=false; done
k delete ns prod --ignore-not-found
k delete pv shared keep --ignore-not-found
helm uninstall traefik -n traefik 2>/dev/null; helm uninstall metallb -n metallb-system 2>/dev/null
kubectl delete -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.6.3/standard-install.yaml 2>/dev/null || true
rm -rf /opt/course
for n in lab-control-plane lab-worker lab-worker2; do docker exec $n rm -rf /mnt/shared /mnt/keep 2>/dev/null; done
# if task 6 was never solved, CoreDNS still points at the dead forwarder — restore it:
k -n kube-system get cm coredns -o yaml | sed 's#forward \. 10\.96\.0\.99#forward . /etc/resolv.conf#' | k apply -f -
k -n kube-system rollout restart deploy/coredns

# vms — on w1 as root, if swap is still on from an unfinished task:
swapoff /swap-mock 2>/dev/null; rm -f /swap-mock; sed -i '/swap-mock/d' /etc/fstab
# on w1, task 4's static Pod manifest also stays behind — remove it (the mirror Pod dies on its own):
rm -f /etc/kubernetes/manifests/e3-static*.yaml
# on cp1: k delete ns e3-sys --ignore-not-found
# if etcd was left running from /var/lib/etcd-restore, move data back to /var/lib/etcd (T4.04 Lab A cleanup)
```
