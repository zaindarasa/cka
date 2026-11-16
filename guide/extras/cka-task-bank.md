# CKA timed task bank

> 24 timed, graded practice tasks that simulate exam conditions: no hints inside the task text, a hard time target, and an objective pass/fail check inside each collapsed **Grade** block. The domain mix mirrors the published CKA weighting (Cluster 25% / Workloads 15% / Networking 20% / Storage 10% / Troubleshooting 30%). These are original practice tasks, not exam questions.

---

## How to use this bank

1. **Pick a task, start a timer.** Read only the **Task** line. The time target is in the header; stop when it fires, grade anyway, and log the overtime.
2. **Docs are allowed, nothing else is.** Only `kubernetes.io/docs`, `kubernetes.io/blog`, `helm.sh/docs` and `gateway-api.sigs.k8s.io` — the same sites the exam browser may open. No notes, no AI, no lesson files during the attempt. The **Ref** link is for review *after* you finish.
3. **Run the Setup block first, then start the timer.** Setup creates the namespace, workloads, and — for troubleshooting tasks — injects the fault. For break-fix tasks, have a study partner run the break block (or run it yourself and do not look at which branch fired). Do not read the Grade block until you think you are done.
4. **Grade yourself.** Every check inside the collapsed block must pass. The checks read object state and observable behaviour — the same thing a real grader scores — not the commands you typed.
5. **Log your times.** Keep the table at the bottom. Re-run a failed task after a review session, not in the same sitting.
6. **Clean up.** Each task ends with a Cleanup line inside the grade block. On `kind`, `env/kind-reset.sh` deletes every `lab-*` namespace in one shot; it does **not** remove taints, StorageClasses, Ingress/Gateway objects' cluster-scoped pieces, or CoreDNS changes — undo those by hand (each task says how).

**Answer files.** Tasks that produce a written artifact ask you to write it to `/opt/course/<NN>/answer` — the same convention as the real tasks. Create the dirs once: `sudo mkdir -p /opt/course && sudo chown -R "$USER" /opt/course`. Answer files live on the machine you are working on: your workstation for `kind` tasks, `cp1` for `vms` tasks.

## Environment key

| Env | What it is | How you reach it |
|---|---|---|
| `kind` | The standard lab cluster `lab`: kind v0.33.0, `kindest/node:v1.37.0` pinned by digest, 1 control plane + 2 workers (`lab-control-plane`, `lab-worker`, `lab-worker2`), Calico v3.33.0, context `kind-lab`. Created by `env/kind-up.sh`; add-ons by `env/kind-addons.sh <name>`. | `kubectl` on your workstation. Node shell if ever needed: `docker exec -it lab-worker bash`. |
| `vms` | Three Ubuntu LTS VMs built by `env/vm-prereqs.sh`: `cp1` (control plane, kubeadm from `pkgs.k8s.io/core:/stable:/v1.37`), `w1`, `w2`; containerd 2.x, Calico v3.33.0, etcd 3.7.0. | `ssh cp1`, then `sudo -i`, then `export KUBECONFIG=/etc/kubernetes/admin.conf`. Reach workers with a **second** terminal + `ssh w1` — no nested ssh. |

## One-time shell setup

Same block as every lesson — run it in each new shell:

```bash
alias k=kubectl
export do="--dry-run=client -o yaml"
export now="--force --grace-period=0"
source <(kubectl completion bash); complete -o default -F __start_kubectl k
```

**Safety.** Every `vms` task and every break-fix task mutates a running cluster. Only run them on disposable lab machines. Never on a cluster you care about.

---

## Domain A — Cluster architecture, installation, configuration and RBAC (~25%)

Six tasks. The `vms` ones (02–05) are the heavyweights; do them in one VM session.

### Task 01 — Context discipline

**Env:** kind · **Time:** 5 min · **Ref:** [T2.02](../part2-basics/T2.02-kubectl-fluency-and-productivity.md)

**Task.** Two clusters exist, contexts `kind-lab` and `kind-lab2`. Using `k config use-context` to switch between them — work done on the wrong cluster scores zero — do the following: on `kind-lab2` create namespace `lab-ctx-b` and Deployment `web` (`nginx:1.27`, 2 replicas). On `kind-lab` create namespace `lab-ctx-a` and ConfigMap `marker` with `team=blue`. Write the name of the context that holds the Deployment to `/opt/course/01/answer`. Finish with your current context set back to `kind-lab`.

**Setup** (run before the timer starts):

```bash
kind create cluster --name lab2          # default CNI is fine for this drill
mkdir -p /opt/course/01
k config get-contexts                    # confirm kind-lab and kind-lab2 exist
```

<details><summary><b>Grade</b></summary>

```bash
k --context kind-lab2 -n lab-ctx-b rollout status deploy/web --timeout=60s && echo ok-1
test "$(k --context kind-lab -n lab-ctx-a get cm marker -o jsonpath='{.data.team}')" = "blue" && echo ok-2
! k --context kind-lab -n lab-ctx-b get deploy web 2>/dev/null && echo ok-3
test "$(k config current-context)" = "kind-lab" && echo ok-4
grep -qx 'kind-lab2' /opt/course/01/answer && echo ok-5
```

**Pass:** all five lines print their `ok` marker.

**Cleanup.** `kind delete cluster --name lab2`; `k delete ns lab-ctx-a`.
</details>

### Task 02 — etcd snapshot backup and restore

**Env:** vms · **Time:** 12 min · **Ref:** [T4.04](../part4-cka/T4.04-manage-the-lifecycle-of-kubernetes-clusters.md)

**Task.** Back up the cluster's etcd datastore to `/opt/course/02/etcd-snap.db` and prove the backup is valid. Then delete namespace `lab-etcd`. Now assume disaster: restore the snapshot into a **new** data directory `/var/lib/etcd-task02` (do not overwrite `/var/lib/etcd`), point etcd at the new directory, and bring the API server back to the snapshot's state. Write the `TOTAL KEYS` value your snapshot reports to `/opt/course/02/answer`.

**Setup** (on `cp1` as root, before the timer):

```bash
ssh cp1 && sudo -i
export KUBECONFIG=/etc/kubernetes/admin.conf
k create ns lab-etcd
k -n lab-etcd create cm marker --from-literal=state=before-restore
mkdir -p /opt/course/02
# etcdctl/etcdutl must exist on cp1 — the kubeadm cluster runs etcd in a
# container, so install matching client binaries (v3.7.0) if they are missing:
command -v etcdctl etcdutl || {
  curl -fsSL https://github.com/etcd-io/etcd/releases/download/v3.7.0/etcd-v3.7.0-linux-$(dpkg --print-architecture).tar.gz | tar xz
  install -m755 etcd-v3.7.0-linux-*/etcdctl etcd-v3.7.0-linux-*/etcdutl /usr/local/bin/
}
```

<details><summary><b>Grade</b></summary>

```bash
test -s /opt/course/02/etcd-snap.db && echo ok-1
test "$(etcdutl snapshot status /opt/course/02/etcd-snap.db -w json | grep -oE '"totalKey":[0-9]+' | cut -d: -f2)" -gt 400 && echo ok-2
grep -q '/var/lib/etcd-task02' /etc/kubernetes/manifests/etcd.yaml && echo ok-3
test "$(k get ns lab-etcd -o jsonpath='{.status.phase}')" = "Active" && echo ok-4
test "$(k -n lab-etcd get cm marker -o jsonpath='{.data.state}')" = "before-restore" && echo ok-5
test "$(k get nodes --no-headers | grep -c ' Ready ')" = "3" && echo ok-6
grep -qE '[0-9]{3,}' /opt/course/02/answer && echo ok-7
```

**Pass:** all seven `ok` markers. Note: after repointing the manifest, the kubelet needs ~1 min to start the new etcd container; if the API server or the controllers serve stale state afterwards, move `kube-apiserver.yaml`, `kube-controller-manager.yaml` and `kube-scheduler.yaml` out of `/etc/kubernetes/manifests` and back in, or restart the kubelet.

**Cleanup.** `k delete ns lab-etcd`; to put etcd back on its original dir repeat the restore into `/var/lib/etcd` and repoint the manifest, or keep the new dir — either is a valid baseline. `rm -rf /root/etcd-v3.7.0-linux-*` if you installed the binaries.
</details>

### Task 03 — kubeadm upgrade, one minor

**Env:** vms · **Time:** 12 min · **Ref:** [T4.04](../part4-cka/T4.04-manage-the-lifecycle-of-kubernetes-clusters.md)

**Task.** The control-plane node `cp1` runs v1.36.5; the workers stay as they are. Upgrade **only** `cp1` — kubeadm, the control plane components, kubelet and kubectl — to v1.37.1, keeping workloads schedulable elsewhere while you work. Write the kubelet version `cp1` reports after the upgrade to `/opt/course/03/answer`.

**Setup** (on `cp1` as root — this task needs a cluster installed at 1.36.5; if your VMs are already on 1.37, rebuild them from the v1.36 repo first):

```bash
ssh cp1 && sudo -i
export KUBECONFIG=/etc/kubernetes/admin.conf
# expected starting state — verify all three before timing yourself:
kubeadm version -o short                                   # v1.36.5
k get nodes                                                # all Ready, VERSION v1.36.5
grep -o 'v1\.3[0-9]' /etc/apt/sources.list.d/kubernetes.list # v1.36 repo enabled
k create ns lab-upg 2>/dev/null; k -n lab-upg create deploy web --image=nginx:1.27 --replicas=3 --port=80
k -n lab-upg rollout status deploy/web --timeout=90s
mkdir -p /opt/course/03
```

<details><summary><b>Grade</b></summary>

```bash
test "$(kubeadm version -o short)" = "v1.37.1" && echo ok-1
test "$(k get node cp1 -o jsonpath='{.status.nodeInfo.kubeletVersion}')" = "v1.37.1" && echo ok-2
k -n kube-system get cm kubeadm-config -o jsonpath='{.data.ClusterConfiguration}' | grep -q 'kubernetesVersion: v1.37.1' && echo ok-3
test "$(k get nodes --no-headers | grep -c ' Ready ')" = "3" && echo ok-4
test -z "$(k get node cp1 -o jsonpath='{.spec.unschedulable}')" && echo ok-5
k -n lab-upg rollout status deploy/web --timeout=60s && echo ok-6
test "$(cat /opt/course/03/answer)" = "v1.37.1" && echo ok-7
```

**Pass:** all seven `ok` markers. A stuck step is usually a forgotten `apt-mark unhold`, the repo still pointing at v1.36, or a skipped `daemon-reload`.

**Cleanup.** `k delete ns lab-upg`. The upgraded cluster is the new baseline — to redo the task, rebuild the VMs at 1.36.5.
</details>

### Task 04 — Certificate expiry check and renewal

**Env:** vms · **Time:** 6 min · **Ref:** [T4.04](../part4-cka/T4.04-manage-the-lifecycle-of-kubernetes-clusters.md)

**Task.** Audit the cluster's certificates: find which certificate expires first and write the apiserver certificate's expiry line (the date shown) to `/opt/course/04/answer`. Then renew **only** the apiserver serving certificate and make sure the API server actually starts using the new certificate.

**Setup** (on `cp1` as root, before the timer):

```bash
ssh cp1 && sudo -i
export KUBECONFIG=/etc/kubernetes/admin.conf
mkdir -p /opt/course/04
k get nodes    # all Ready
```

<details><summary><b>Grade</b></summary>

```bash
test -s /opt/course/04/answer && grep -qE '[0-9]{4}|UTC' /opt/course/04/answer && echo ok-1
d=$(kubeadm certs check-expiration 2>/dev/null | grep -E '^apiserver[[:space:]]' | grep -oE '[0-9]+d' | head -1 | tr -dc '0-9')
test "${d:-0}" -ge 360 && echo "ok-2 apiserver residual ${d}d"
test "$(k get --raw=/readyz 2>/dev/null)" = "ok" && echo ok-3
crictl ps --name kube-apiserver -q | grep -q . && echo ok-4
```

**Pass:** all four `ok` markers. Renewing writes the cert file; the running apiserver does not pick it up until its container restarts (`crictl stop` on it — the kubelet recreates it).

**Cleanup.** Nothing to undo — renewed certs are the baseline.
</details>

### Task 05 — Drain a node, reboot it, bring it back

**Env:** vms · **Time:** 6 min · **Ref:** [T4.04](../part4-cka/T4.04-manage-the-lifecycle-of-kubernetes-clusters.md)

**Task.** Node `w1` needs a reboot for kernel maintenance. Evict its workloads so they keep running elsewhere — the Pod named `scratch` is disposable and its `emptyDir` must not block you — then reboot `w1` (`sudo reboot`; wait for it to come back), and finally return it to service. Write the `STATUS` column `k get node w1` shows at the end to `/opt/course/05/answer`.

**Setup** (on `cp1` as root, before the timer):

```bash
ssh cp1 && sudo -i
export KUBECONFIG=/etc/kubernetes/admin.conf
k create ns lab-maint
k -n lab-maint create deploy web --image=nginx:1.27 --replicas=4 --port=80
cat <<'EOF' | k apply -f -
apiVersion: v1
kind: Pod
metadata: {name: scratch, namespace: lab-maint}
spec:
  nodeName: w1
  containers:
  - name: c
    image: busybox:1.36
    command: ["sleep","3600"]
    volumeMounts: [{name: d, mountPath: /data}]
  volumes: [{name: d, emptyDir: {}}]
EOF
k -n lab-maint rollout status deploy/web --timeout=90s
k -n lab-maint get pods -o wide
mkdir -p /opt/course/05
```

<details><summary><b>Grade</b></summary>

```bash
test "$(k get node w1 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')" = "True" && echo ok-1
test -z "$(k get node w1 -o jsonpath='{.spec.unschedulable}')" && echo ok-2
test "$(k -n lab-maint get pods -l app=web --field-selector=status.phase=Running --no-headers | wc -l)" = "4" && echo ok-3
grep -q 'Ready' /opt/course/05/answer && ! grep -q 'SchedulingDisabled' /opt/course/05/answer && echo ok-4
```

**Pass:** all four `ok` markers. `scratch` is expected to be gone — it was a bare Pod; the Deployment's Pods must all be `Running` somewhere.

**Cleanup.** `k delete ns lab-maint`.
</details>

### Task 06 — RBAC: least-privilege ServiceAccount

**Env:** kind · **Time:** 7 min · **Ref:** [T4.06](../part4-cka/T4.06-manage-role-based-access-control-rbac.md)

**Task.** In namespace `lab-rbac`: create ServiceAccount `deploy-reader`; create Role `pod-read` that permits exactly `get`, `list` and `watch` on `pods` (nothing else); bind the Role to the ServiceAccount with RoleBinding `deploy-reader-binding`. Prove the account can list Pods in `lab-rbac`, **cannot** list Secrets there, and **cannot** list Pods in `default`. Write the three `k auth can-i` verdicts — `yes`/`no`, one per line, in that order — to `/opt/course/06/answer`.

**Setup** (before the timer):

```bash
k create ns lab-rbac
k -n lab-rbac run web --image=nginx:1.27
k -n lab-rbac create secret generic s1 --from-literal=k=v
mkdir -p /opt/course/06
```

<details><summary><b>Grade</b></summary>

```bash
SA=system:serviceaccount:lab-rbac:deploy-reader
test "$(k auth can-i list pods --as=$SA -n lab-rbac)" = "yes" && echo ok-1
test "$(k auth can-i watch pods --as=$SA -n lab-rbac)" = "yes" && echo ok-2
test "$(k auth can-i list secrets --as=$SA -n lab-rbac)" = "no" && echo ok-3
test "$(k auth can-i list pods --as=$SA -n default)" = "no" && echo ok-4
test "$(k auth can-i delete pods --as=$SA -n lab-rbac)" = "no" && echo ok-5
diff <(printf 'yes\nno\nno\n') <(head -3 /opt/course/06/answer) && echo ok-6
test "$(k -n lab-rbac get rolebinding deploy-reader-binding -o jsonpath='{.roleRef.name}/{.subjects[0].kind}/{.subjects[0].name}')" = "pod-read/ServiceAccount/deploy-reader" && echo ok-7
```

**Pass:** all seven `ok` markers.

**Cleanup.** `k delete ns lab-rbac`.
</details>

---

## Domain B — Workloads and scheduling (~15%)

Four tasks, all `kind`.

### Task 07 — Roll out, then roll back

**Env:** kind · **Time:** 6 min · **Ref:** [T4.09](../part4-cka/T4.09-application-deployments-rolling-updates-and-rollbacks.md)

**Task.** Deployment `web` in `lab-roll` is on `nginx:1.25`. Upgrade it to `nginx:1.27`, confirm the rollout completes cleanly, then roll it back to the previous version. Write the container image running after the rollback to `/opt/course/07/answer`.

**Setup** (before the timer):

```bash
k create ns lab-roll
k -n lab-roll create deploy web --image=nginx:1.25 --replicas=4 --port=80
k -n lab-roll rollout status deploy/web --timeout=90s
mkdir -p /opt/course/07
```

<details><summary><b>Grade</b></summary>

```bash
test "$(k -n lab-roll get deploy web -o jsonpath='{.spec.template.spec.containers[0].image}')" = "nginx:1.25" && echo ok-1
test "$(k -n lab-roll get deploy web -o jsonpath='{.status.readyReplicas}')" = "4" && echo ok-2
test "$(k -n lab-roll rollout history deploy/web --no-headers | wc -l | tr -d ' ')" -ge 2 && echo ok-3
grep -q 'nginx:1.25' /opt/course/07/answer && echo ok-4
```

**Pass:** all four `ok` markers.

**Cleanup.** `k delete ns lab-roll`.
</details>

### Task 08 — HPA on metrics-server

**Env:** kind · **Time:** 10 min · **Ref:** [T4.11](../part4-cka/T4.11-configure-workload-autoscaling.md)

**Task.** In `lab-hpa`: give the `web` container a CPU **request** of `100m`, then create HPA `web` targeting Deployment `web` — minimum 1, maximum 4, CPU utilization 50%. Scale the `load` Deployment to 2 replicas and let it run until `web` scales out past 1 replica. Write the highest replica count the HPA reaches to `/opt/course/08/answer`.

**Setup** (before the timer; metrics-server must already be installed):

```bash
env/kind-addons.sh metrics-server        # once per cluster; needs no helm
k create ns lab-hpa
k -n lab-hpa create deploy web --image=nginx:1.27 --replicas=1 --port=80
k -n lab-hpa expose deploy web --port=80
cat <<'EOF' | k apply -f -
apiVersion: apps/v1
kind: Deployment
metadata: {name: load, namespace: lab-hpa}
spec:
  replicas: 0                            # you scale this up during the task
  selector: {matchLabels: {app: load}}
  template:
    metadata: {labels: {app: load}}
    spec:
      containers:
      - name: load
        image: busybox:1.36
        command: ["/bin/sh","-c","while true; do wget -q -O- -T 1 http://web.lab-hpa >/dev/null 2>&1; done"]
EOF
k -n lab-hpa rollout status deploy/web --timeout=90s
sleep 60                                  # let metrics-server scrape the new pods
mkdir -p /opt/course/08
```

<details><summary><b>Grade</b></summary>

```bash
test "$(k -n lab-hpa get deploy web -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}')" = "100m" && echo ok-1
test "$(k -n lab-hpa get hpa web -o jsonpath='{.spec.minReplicas}/{.spec.maxReplicas}')" = "1/4" && echo ok-2
test "$(k -n lab-hpa get hpa web -o jsonpath='{.spec.metrics[0].resource.target.averageUtilization}')" = "50" && echo ok-3
! k -n lab-hpa get hpa web | grep -q '<unknown>' && echo ok-4
for i in $(seq 1 30); do n=$(k -n lab-hpa get hpa web -o jsonpath='{.status.currentReplicas}'); [ "${n:-1}" -gt 1 ] && echo "ok-5 scaled to $n" && break; sleep 10; done
grep -qE '^[2-4]$' /opt/course/08/answer && echo ok-6
```

**Pass:** all six `ok` markers. `<unknown>` in TARGETS means metrics-server or the CPU request is missing — the request must land **before** the HPA is expected to compute.

**Cleanup.** `k delete ns lab-hpa`.
</details>

### Task 09 — Taint a node, tolerate the taint

**Env:** kind · **Time:** 5 min · **Ref:** [T4.13](../part4-cka/T4.13-configure-pod-admission-and-scheduling-limits.md)

**Task.** Reserve `lab-worker` for database workloads: taint it `dedicated=db:NoSchedule`. In namespace `lab-sched` create Pod `app` (`nginx:1.27`) — it must run but must **not** land on `lab-worker` — and Pod `db` (`nginx:1.27`) — it must tolerate the taint **and** be placed on `lab-worker`. Write the node name `db` runs on to `/opt/course/09/answer`.

**Setup** (before the timer):

```bash
k create ns lab-sched
k get nodes
mkdir -p /opt/course/09
```

<details><summary><b>Grade</b></summary>

```bash
test "$(k get node lab-worker -o jsonpath='{.spec.taints[?(@.key=="dedicated")].effect}')" = "NoSchedule" && echo ok-1
test "$(k get node lab-worker -o jsonpath='{.spec.taints[?(@.key=="dedicated")].value}')" = "db" && echo ok-2
test "$(k -n lab-sched get pod db -o jsonpath='{.spec.nodeName}')" = "lab-worker" && echo ok-3
test "$(k -n lab-sched get pod db -o jsonpath='{.status.phase}')" = "Running" && echo ok-4
test "$(k -n lab-sched get pod app -o jsonpath='{.status.phase}')" = "Running" && echo ok-5
test "$(k -n lab-sched get pod app -o jsonpath='{.spec.nodeName}')" != "lab-worker" && echo ok-6
test "$(cat /opt/course/09/answer)" = "lab-worker" && echo ok-7
```

**Pass:** all seven `ok` markers. Pinning `db` to the node takes two cooperating pieces: a toleration for the taint and a `nodeSelector` (or node affinity) on the hostname — a toleration alone only *permits* the node.

**Cleanup.** `k taint node lab-worker dedicated=db:NoSchedule-`; `k delete ns lab-sched`.
</details>

### Task 10 — Sidecar reading a shared log volume

**Env:** kind · **Time:** 6 min · **Ref:** [T4.23](../part4-cka/T4.23-manage-and-evaluate-container-output-streams.md)

**Task.** In `lab-logs` create Pod `applog` with two containers sharing an `emptyDir` volume `logvol`: container `app` (`nginx:1.27`) mounts it read-write at `/var/log/nginx`; container `reader` (`busybox:1.36`) mounts it read-only at `/var/log/nginx` and runs `tail -f /var/log/nginx/access.log`. Send one HTTP request to `app`, then write the last line `k logs applog -c reader` shows to `/opt/course/10/answer`.

**Setup** (before the timer):

```bash
k create ns lab-logs
mkdir -p /opt/course/10
```

<details><summary><b>Grade</b></summary>

```bash
test "$(k -n lab-logs get pod applog -o jsonpath='{.spec.containers[*].name}' | wc -w | tr -d ' ')" = "2" && echo ok-1
test "$(k -n lab-logs get pod applog -o jsonpath='{range .spec.containers[*]}{.volumeMounts[*].mountPath}{"\n"}{end}' | grep -c '/var/log/nginx')" = "2" && echo ok-2
test "$(k -n lab-logs get pod applog -o jsonpath='{.status.phase}')" = "Running" && echo ok-3
k -n lab-logs exec applog -c app -- wget -q -O- -T 3 http://127.0.0.1 >/dev/null 2>&1; sleep 2
k -n lab-logs logs applog -c reader --tail=5 | grep -q 'GET / ' && echo ok-4
grep -q 'GET / ' /opt/course/10/answer && echo ok-5
```

**Pass:** all five `ok` markers. Mounting the volume over `/var/log/nginx` hides the image's stdout symlinks, so nginx writes a real `access.log` file into the shared dir.

**Cleanup.** `k delete ns lab-logs`.
</details>

---

## Domain C — Services and networking (~20%)

Five tasks, all `kind`.

### Task 11 — ClusterIP, NodePort, Ingress: the full path

**Env:** kind · **Time:** 10 min · **Ref:** [T4.18](../part4-cka/T4.18-use-clusterip-nodeport-loadbalancer-service-types.md), [T4.21](../part4-cka/T4.21-know-how-to-use-ingress-controllers.md)

**Task.** In `lab-expose`, for the existing `web` Deployment: (1) Service `web-ip`, type ClusterIP, port 80 → targetPort 80. (2) Service `web-np`, type NodePort, port 80, nodePort **30080**. (3) Ingress `web-ing` using class `traefik` (the controller is already installed) routing host `web.lab`, path `/`, to `web-ip:80`. Verify each layer. Write the HTTP status code of a request carrying `Host: web.lab` to `/opt/course/11/answer`.

**Setup** (before the timer; Traefik install needs helm on PATH):

```bash
env/kind-addons.sh helm                  # once per machine; installs to ~/.local/bin
env/kind-addons.sh traefik               # chart 42.1.3, Traefik v3.7.x
k create ns lab-expose
k -n lab-expose create deploy web --image=nginx:1.27 --replicas=2 --port=80
k -n lab-expose rollout status deploy/web --timeout=90s
mkdir -p /opt/course/11
```

<details><summary><b>Grade</b></summary>

```bash
test "$(k -n lab-expose get svc web-ip -o jsonpath='{.spec.type}')" = "ClusterIP" && echo ok-1
test "$(k -n lab-expose get endpointslice -l kubernetes.io/service-name=web-ip -o jsonpath='{.items[*].endpoints[*].addresses[*]}' | wc -w | tr -d ' ')" = "2" && echo ok-2
test "$(k -n lab-expose get svc web-np -o jsonpath='{.spec.ports[0].nodePort}')" = "30080" && echo ok-3
test "$(curl -s -o /dev/null -w '%{http_code}' -m 5 http://localhost:30080/)" = "200" && echo ok-4
test "$(k -n lab-expose get ingress web-ing -o jsonpath='{.spec.rules[0].host}{" "}{.spec.rules[0].http.paths[0].backend.service.name}{":"}{.spec.rules[0].http.paths[0].backend.service.port.number}')" = "web.lab web-ip:80" && echo ok-5
k -n traefik port-forward svc/traefik 18080:80 >/tmp/pf-11.log 2>&1 & PF=$!; sleep 3
test "$(curl -s -o /dev/null -w '%{http_code}' -m 5 -H 'Host: web.lab' http://localhost:18080/)" = "200" && echo ok-6
kill $PF 2>/dev/null
grep -qx '200' /opt/course/11/answer && echo ok-7
```

**Pass:** all seven `ok` markers. `localhost:30080` works because `kind.yaml` maps host port 30080 into the control-plane node; the Ingress check goes through Traefik's own Service via port-forward — on a cluster with MetalLB you would curl its external address with `Host:` set instead.

**Cleanup.** `k delete ns lab-expose` (Traefik stays installed as baseline).
</details>

### Task 12 — NetworkPolicy: default-deny plus allow

**Env:** kind · **Time:** 10 min · **Ref:** [T4.20](../part4-cka/T4.20-define-and-enforce-network-policies.md)

**Task.** Lock down namespace `lab-netpol` without breaking the app: (a) a NetworkPolicy `default-deny` that isolates **every** Pod in the namespace for ingress **and** egress; (b) a policy that allows ingress to `app=db` Pods from `app=client` Pods on TCP 80; (c) a policy that allows `app=client` Pods egress to `app=db` Pods on TCP 80; (d) a policy that lets all Pods in the namespace resolve names via kube-dns (UDP and TCP 53). Prove `client` reaches `db` over HTTP by name and `stranger` cannot.

**Setup** (before the timer — NetworkPolicy enforcement needs Calico, which `kind-up.sh` already installed):

```bash
k create ns lab-netpol
k -n lab-netpol create deploy db --image=nginx:1.27 --replicas=1 --port=80
k -n lab-netpol expose deploy db --port=80
k -n lab-netpol run client --image=busybox:1.36 --labels=app=client -- sleep 3600
k -n lab-netpol run stranger --image=busybox:1.36 --labels=app=stranger -- sleep 3600
k -n lab-netpol rollout status deploy/db --timeout=90s
```

<details><summary><b>Grade</b></summary>

```bash
test "$(k -n lab-netpol get netpol --no-headers | wc -l | tr -d ' ')" -ge 3 && echo ok-1
k -n lab-netpol exec client -- sh -c 'wget -q -O- -T 3 http://db.lab-netpol | head -1' | grep -q 'DOCTYPE' && echo ok-2
IP=$(k -n lab-netpol get svc db -o jsonpath='{.spec.clusterIP}')
! k -n lab-netpol exec stranger -- wget -q -O- -T 3 "http://$IP" >/dev/null 2>&1 && echo ok-3
k -n lab-netpol exec client -- nslookup kubernetes.default >/dev/null 2>&1 && echo ok-4
```

**Pass:** all four `ok` markers. Remember the union rule: traffic needs an allow at **both** ends when both directions are isolated — an ingress allow on `db` does nothing while `client`'s egress is denied. And a full egress deny also kills DNS unless you open 53 to `kube-system`.

**Cleanup.** `k delete ns lab-netpol`.
</details>

### Task 13 — CoreDNS: fixed record and name alias

**Env:** kind · **Time:** 5 min · **Ref:** [T4.19](../part4-cka/T4.19-understand-and-use-coredns.md)

**Task.** Extend cluster DNS so Pods additionally resolve `cache.corp.test` to the fixed address `10.99.99.99`, and `old-svc.corp.test` to the ClusterIP of Service `web-svc` in `lab-dnsrec`. Every other name must keep resolving. Write the address CoreDNS answers for `cache.corp.test` to `/opt/course/13/answer`.

**Setup** (before the timer):

```bash
k create ns lab-dnsrec
k -n lab-dnsrec create deploy web --image=nginx:1.27 --replicas=1 --port=80
k -n lab-dnsrec expose deploy web --name web-svc --port=80
k -n lab-dnsrec run chk --image=busybox:1.36 -- sleep 3600
mkdir -p /opt/course/13
```

<details><summary><b>Grade</b></summary>

```bash
k -n lab-dnsrec exec chk -- nslookup cache.corp.test | tail -1 | grep -q '10.99.99.99' && echo ok-1
IP=$(k -n lab-dnsrec get svc web-svc -o jsonpath='{.spec.clusterIP}')
k -n lab-dnsrec exec chk -- nslookup old-svc.corp.test | tail -1 | grep -q "$IP" && echo ok-2
k -n lab-dnsrec exec chk -- nslookup kubernetes.default | grep -q '10.96.0.10' && echo ok-3
grep -q '10.99.99.99' /opt/course/13/answer && echo ok-4
```

**Pass:** all four `ok` markers. The `hosts` plugin needs `fallthrough` or it swallows every name it does not know; a `rewrite name exact` rule is the clean way to make an alias. The `reload` plugin picks the new Corefile up by itself — a rollout restart is just faster.

**Cleanup.** Restore the `coredns` ConfigMap to its original Corefile (`k -n kube-system rollout restart deploy coredns` after editing); `k delete ns lab-dnsrec`.
</details>

### Task 14 — Gateway API: Gateway plus HTTPRoute

**Env:** kind · **Time:** 8 min · **Ref:** [T4.22](../part4-cka/T4.22-use-the-gateway-api-to-manage.md)

**Task.** The Gateway API CRDs and a Gateway-capable Traefik install are already in the cluster. In `lab-gw`: create Gateway `main` (GatewayClass `traefik`, one `HTTP` listener on port 80 for hostname `api.lab`) and HTTPRoute `api` that attaches to `main` and routes hostname `api.lab`, path `/`, to Service `api:80`. Write the HTTP status of a request carrying `Host: api.lab` to `/opt/course/14/answer`.

**Setup** (before the timer):

```bash
env/kind-addons.sh gateway-api-crds      # v1.6.3 standard channel
env/kind-addons.sh traefik               # already enables the Gateway provider
k create ns lab-gw
k -n lab-gw create deploy api --image=nginx:1.27 --replicas=1 --port=80
k -n lab-gw expose deploy api --port=80
k -n lab-gw rollout status deploy/api --timeout=90s
mkdir -p /opt/course/14
```

<details><summary><b>Grade</b></summary>

```bash
test "$(k get gatewayclass traefik -o jsonpath='{.spec.controllerName}')" = "traefik.io/gateway-controller" && echo ok-1
test "$(k -n lab-gw get gtw main -o jsonpath='{.spec.gatewayClassName}')" = "traefik" && echo ok-2
k -n lab-gw get gtw main -o jsonpath='{.status.conditions[?(@.type=="Programmed")].status}' | grep -qw 'True' && echo ok-3
k -n lab-gw get httproute api -o jsonpath='{.status.parents[*].conditions[?(@.type=="Accepted")].status}' | grep -qw 'True' && echo ok-4
k -n traefik port-forward svc/traefik 18081:80 >/tmp/pf-14.log 2>&1 & PF=$!; sleep 3
test "$(curl -s -o /dev/null -w '%{http_code}' -m 5 -H 'Host: api.lab' http://localhost:18081/)" = "200" && echo ok-5
kill $PF 2>/dev/null
grep -qx '200' /opt/course/14/answer && echo ok-6
```

**Pass:** all six `ok` markers. The status conditions are where a silent failure lives: `Accepted`/`ResolvedRefs` on the route, `Programmed` on the Gateway — read them before touching the object again.

**Cleanup.** `k delete ns lab-gw`; leave the CRDs and Traefik installed.
</details>

### Task 15 — Selector-less Service with a hand-written EndpointSlice

**Env:** kind · **Time:** 6 min · **Ref:** [T4.18](../part4-cka/T4.18-use-clusterip-nodeport-loadbalancer-service-types.md)

**Task.** An external database lives at `10.9.9.9:5432` (the address only — no real server needed). In `lab-ext`, create Service `ext-db` on port 5432 that sends traffic to that address **without** selecting any Pods, and write the EndpointSlice that populates it yourself. Write the value of the `kubernetes.io/service-name` label on your EndpointSlice to `/opt/course/15/answer`.

**Setup** (before the timer):

```bash
k create ns lab-ext
mkdir -p /opt/course/15
```

<details><summary><b>Grade</b></summary>

```bash
test "$(k -n lab-ext get svc ext-db -o jsonpath='{.spec.ports[0].port}')" = "5432" && echo ok-1
test -z "$(k -n lab-ext get svc ext-db -o jsonpath='{.spec.selector}')" && echo ok-2
k -n lab-ext get endpointslice -l kubernetes.io/service-name=ext-db -o jsonpath='{.items[*].endpoints[*].addresses[*]}' | grep -qw '10.9.9.9' && echo ok-3
k -n lab-ext get endpointslice -l kubernetes.io/service-name=ext-db -o jsonpath='{.items[*].ports[*].port}' | grep -qw '5432' && echo ok-4
test "$(cat /opt/course/15/answer)" = "ext-db" && echo ok-5
```

**Pass:** all five `ok` markers. A Service with no `spec.selector` gets no controller-written EndpointSlices — the label `kubernetes.io/service-name` is the string that ties a hand-written slice to the Service (a mirrored `Endpoints` view will then also show the address).

**Cleanup.** `k delete ns lab-ext`.
</details>

---

## Domain D — Storage (~10%)

Two tasks, both `kind`. Both hinge on the three states of `storageClassName` — `""`, omitted, and a name.

### Task 16 — Static PV, PVC, mounted Pod

**Env:** kind · **Time:** 7 min · **Ref:** [T4.15](../part4-cka/T4.15-manage-persistent-volumes-and-persistent-volume.md)

**Task.** Create PersistentVolume `pv-static`: `hostPath` `/mnt/static-data` (DirectoryOrCreate), capacity 1Gi, access mode `ReadWriteOnce`, reclaim policy `Retain`, `storageClassName: ""`, label `tier=gold`. Create PersistentVolumeClaim `pvc-static` in `lab-pv`: 500Mi, RWO, `storageClassName: ""`, and a label selector `tier=gold`. Create Pod `pv-app` (`busybox:1.36`, `sleep 3600`) mounting the claim at `/data`, then put a file `/data/hello.txt` containing `cka` inside it. Write the bound claim's `<namespace>/<name>` to `/opt/course/16/answer`.

**Setup** (before the timer):

```bash
k create ns lab-pv
mkdir -p /opt/course/16
k get sc        # note the cluster's default class for step review
```

<details><summary><b>Grade</b></summary>

```bash
test "$(k get pv pv-static -o jsonpath='{.status.phase}')" = "Bound" && echo ok-1
test "$(k get pv pv-static -o jsonpath='{.spec.claimRef.namespace}/{.spec.claimRef.name}')" = "lab-pv/pvc-static" && echo ok-2
test "$(k -n lab-pv get pvc pvc-static -o jsonpath='{.spec.volumeName}')" = "pv-static" && echo ok-3
test "$(k -n lab-pv get pvc pvc-static -o jsonpath='{.spec.storageClassName}')" = "" && echo ok-4
test "$(k -n lab-pv exec pv-app -- cat /data/hello.txt)" = "cka" && echo ok-5
test "$(cat /opt/course/16/answer)" = "lab-pv/pvc-static" && echo ok-6
```

**Pass:** all six `ok` markers. The classic failure: omit `storageClassName` on the claim and the admission plugin injects the default class — your claim dynamically provisions a different PV while `pv-static` sits `Available` forever.

**Cleanup.** `k delete ns lab-pv`; `k delete pv pv-static`; `docker exec lab-worker rm -rf /mnt/static-data` on each node where the Pod ran.
</details>

### Task 17 — StorageClass, dynamic provisioning, new default

**Env:** kind · **Time:** 8 min · **Ref:** [T4.16](../part4-cka/T4.16-implement-storage-classes-and-dynamic-volume.md)

**Task.** Create StorageClass `fast-local` on provisioner `rancher.io/local-path` with `volumeBindingMode: WaitForFirstConsumer` and `reclaimPolicy: Delete`, and make it the cluster's **only** default class. Then in `lab-dyn` create claim `data-fast` (1Gi, RWO) with **no** `storageClassName` field at all, and Pod `fast-app` (`busybox:1.36`, `sleep 3600`) that mounts it at `/data`. Write the `storageClassName` the claim ended up with to `/opt/course/17/answer`.

**Setup** (before the timer):

```bash
k create ns lab-dyn
k get sc        # standard (default) on kind — your job is to replace it
mkdir -p /opt/course/17
```

<details><summary><b>Grade</b></summary>

```bash
test "$(k get sc fast-local -o jsonpath='{.metadata.annotations["storageclass.kubernetes.io/is-default-class"]}')" = "true" && echo ok-1
test "$(k get sc standard -o jsonpath='{.metadata.annotations["storageclass.kubernetes.io/is-default-class"]}')" != "true" && echo ok-2
test "$(k get sc fast-local -o jsonpath='{.provisioner}/{.volumeBindingMode}/{.reclaimPolicy}')" = "rancher.io/local-path/WaitForFirstConsumer/Delete" && echo ok-3
test "$(k -n lab-dyn get pvc data-fast -o jsonpath='{.spec.storageClassName}')" = "fast-local" && echo ok-4
test "$(k -n lab-dyn get pvc data-fast -o jsonpath='{.status.phase}')" = "Bound" && echo ok-5
test "$(k -n lab-dyn get pod fast-app -o jsonpath='{.status.phase}')" = "Running" && echo ok-6
test "$(cat /opt/course/17/answer)" = "fast-local" && echo ok-7
```

**Pass:** all seven `ok` markers. `WaitForFirstConsumer` means the claim deliberately sits `Pending` until the Pod exists — that is a feature, not a bug; watch the ordering. Switching the default is two patches: annotation off the old class, on the new one — `k get sc` must show exactly one `(default)`.

**Cleanup.** `k delete ns lab-dyn`; `k patch sc standard --type=merge -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'`; `k delete sc fast-local`; delete the leftover PV (`reclaimPolicy: Delete` handles the backing dir once the claim is gone).
</details>

---

## Domain E — Troubleshooting (~30%)

Seven break-fix tasks. The setup injects the fault; the task text gives only the symptom. Have a partner run the break block, or run it yourself and look away from the branch that fires.

### Task 18 — Node NotReady: the silent or sick kubelet

**Env:** vms · **Time:** 8 min · **Ref:** [T4.26](../part4-cka/T4.26-troubleshoot-clusters-and-nodes.md)

**Task.** Node `w1` reports `NotReady`. Find the cause and restore the node so it reports `Ready` — permanently: the fix must survive a reboot of `w1`. Write a one-line root cause to `/opt/course/18/answer` on `cp1`.

**Setup** — on `w1` as root (`ssh w1`, `sudo -i`), before the timer:

```bash
n=$(( RANDOM % 3 + 1 ))
case $n in
  1) systemctl disable --now kubelet ;;
  2) sed -i 's#:6443#:6444#' /etc/kubernetes/kubelet.conf && systemctl restart kubelet ;;
  3) systemctl stop containerd ;;
esac
echo "injected"
exit        # back out; work the task from cp1
```

Also on `cp1`: `mkdir -p /opt/course/18`.

<details><summary><b>Grade</b></summary>

`k` lines run on `cp1` as root (`export KUBECONFIG=/etc/kubernetes/admin.conf`); the `ssh w1` lines run from your workstation or a second terminal — no nested ssh:

```bash
test "$(k get node w1 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')" = "True" && echo ok-1
ssh w1 'systemctl is-active kubelet' | grep -qx 'active' && echo ok-2
ssh w1 'systemctl is-enabled kubelet' | grep -qx 'enabled' && echo ok-3
ssh w1 'systemctl is-active containerd' | grep -qx 'active' && echo ok-4
ssh w1 'grep -q ":6443" /etc/kubernetes/kubelet.conf' && echo ok-5
test -s /opt/course/18/answer && echo ok-6
```

**Pass:** all six `ok` markers. `is-enabled` is part of the pass: a stopped **and** disabled kubelet comes back broken after every reboot. Diagnostic path: `k describe node w1` → `ssh w1` → `systemctl status kubelet containerd` → `journalctl -u kubelet -n 50 --no-pager` → `crictl info`.

**Cleanup.** Nothing extra once the node is healthy — the fault is the fix. Remove any half-restored files (`/etc/cni/net.d` was not touched by this break set).
</details>

### Task 19 — Pods never schedule: the broken static Pod

**Env:** vms · **Time:** 8 min · **Ref:** [T4.25](../part4-cka/T4.25-troubleshoot-cluster-components.md)

**Task.** Deployment `smoke` in `lab-fix` has been stuck at 0/2 for ten minutes — its Pods exist but are `Pending` with **no** events. All nodes report `Ready`. Find the cause, restore scheduling so `smoke` reaches 2/2, and write the path of the file that was wrong to `/opt/course/19/answer`.

**Setup** — on `cp1` as root, before the timer:

```bash
ssh cp1 && sudo -i
export KUBECONFIG=/etc/kubernetes/admin.conf
cp -a /etc/kubernetes/manifests/kube-scheduler.yaml /root/kube-scheduler.yaml.orig
sed -i 's#--kubeconfig=/etc/kubernetes/scheduler.conf#--kubeconfig=/etc/kubernetes/scheduler-missing.conf#' /etc/kubernetes/manifests/kube-scheduler.yaml
sleep 20
k create ns lab-fix
k -n lab-fix create deploy smoke --image=nginx:1.27 --replicas=2 --port=80
mkdir -p /opt/course/19
```

<details><summary><b>Grade</b></summary>

```bash
test "$(k -n lab-fix get deploy smoke -o jsonpath='{.status.readyReplicas}')" = "2" && echo ok-1
grep -q 'scheduler\.conf' /etc/kubernetes/manifests/kube-scheduler.yaml && ! grep -q 'scheduler-missing' /etc/kubernetes/manifests/kube-scheduler.yaml && echo ok-2
test "$(ls /etc/kubernetes/manifests | wc -l | tr -d ' ')" = "4" && echo ok-3
crictl ps --name kube-scheduler -q | grep -q . && echo ok-4
test "$(cat /opt/course/19/answer)" = "/etc/kubernetes/manifests/kube-scheduler.yaml" && echo ok-5
```

**Pass:** all five `ok` markers. `Pending` with no events and healthy nodes means nothing is trying to schedule: the scheduler's mirror Pod in `kube-system` is `CrashLoopBackOff` and `crictl logs` on it names the bad path.

**Cleanup.** `k delete ns lab-fix`; `cp -a /root/kube-scheduler.yaml.orig /etc/kubernetes/manifests/kube-scheduler.yaml` only if your repair drifted; `rm /root/kube-scheduler.yaml.orig`.
</details>

### Task 20 — kubectl dead: the crashed apiserver

**Env:** vms · **Time:** 8 min · **Ref:** [T4.25](../part4-cka/T4.25-troubleshoot-cluster-components.md)

**Task.** Every `kubectl` command on `cp1` fails with `connect: connection refused`. SSH to the node still works and containerd is running. Restore the API server and write the path of the file you repaired to `/opt/course/20/answer`.

**Setup** — on `cp1` as root, before the timer:

```bash
ssh cp1 && sudo -i
export KUBECONFIG=/etc/kubernetes/admin.conf
cp -a /etc/kubernetes/manifests/kube-apiserver.yaml /root/kube-apiserver.yaml.orig
sed -i 's#--authorization-mode=#--authorization-mod=#' /etc/kubernetes/manifests/kube-apiserver.yaml
sleep 30
mkdir -p /opt/course/20
```

<details><summary><b>Grade</b></summary>

```bash
test "$(k get --raw=/readyz 2>/dev/null)" = "ok" && echo ok-1
k get nodes --no-headers | grep -q ' Ready ' && echo ok-2
! grep -q 'authorization-mod=' /etc/kubernetes/manifests/kube-apiserver.yaml && echo ok-3
crictl ps --name kube-apiserver -q | grep -q . && echo ok-4
test "$(ls /etc/kubernetes/manifests | wc -l | tr -d ' ')" = "4" && echo ok-5
test "$(cat /opt/course/20/answer)" = "/etc/kubernetes/manifests/kube-apiserver.yaml" && echo ok-6
```

**Pass:** all six `ok` markers. When `kubectl` is dead your eyes are `crictl ps -a` and `crictl logs`: an `Exited` apiserver container plus `unknown flag` in its log is a manifest typo — the kubelet keeps retrying, so recovery is automatic within a restart cycle once the manifest is fixed.

**Cleanup.** `cp -a /root/kube-apiserver.yaml.orig /etc/kubernetes/manifests/kube-apiserver.yaml` only if needed; `rm /root/kube-apiserver.yaml.orig`.
</details>

### Task 21 — Service with no endpoints

**Env:** kind · **Time:** 5 min · **Ref:** [T4.27](../part4-cka/T4.27-troubleshoot-services-and-networking.md)

**Task.** Callers report `web-svc` in `lab-netfix` refuses connections. The Pods are all `Running` and the Service object "looks right". Restore connectivity and write the number of ready backend addresses the Service has after your fix to `/opt/course/21/answer`.

**Setup** — before the timer:

```bash
k create ns lab-netfix
k -n lab-netfix create deploy web --image=nginx:1.27 --replicas=3 --port=80
k -n lab-netfix expose deploy web --name web-svc --port=80 --target-port=80
k -n lab-netfix run chk --image=busybox:1.36 -- sleep 3600
k -n lab-netfix rollout status deploy/web --timeout=90s
mkdir -p /opt/course/21
# the break:
k -n lab-netfix patch svc web-svc --type=merge -p '{"spec":{"selector":{"app":"web-typo"}}}'
```

<details><summary><b>Grade</b></summary>

```bash
test "$(k -n lab-netfix get endpointslice -l kubernetes.io/service-name=web-svc -o jsonpath='{.items[*].endpoints[*].addresses[*]}' | wc -w | tr -d ' ')" = "3" && echo ok-1
k -n lab-netfix exec chk -- sh -c 'wget -q -O- -T 3 http://web-svc.lab-netfix | head -1' | grep -q 'DOCTYPE' && echo ok-2
test "$(cat /opt/course/21/answer)" = "3" && echo ok-3
```

**Pass:** all three `ok` markers. Empty endpoints + healthy Pods is a selector problem nine times out of ten — compare `k get svc -o jsonpath='{.spec.selector}'` with `k get pods --show-labels` before touching anything else.

**Cleanup.** `k delete ns lab-netfix`.
</details>

### Task 22 — Cluster-wide DNS failure

**Env:** kind · **Time:** 7 min · **Ref:** [T4.19](../part4-cka/T4.19-understand-and-use-coredns.md), [T4.27](../part4-cka/T4.27-troubleshoot-services-and-networking.md)

**Task.** Applications across the cluster report "could not resolve host" for every Service name. Requests to Service ClusterIPs still work. Restore name resolution cluster-wide and write the name of the object you repaired to `/opt/course/22/answer`.

**Setup** — before the timer (pick a fault; a partner should choose):

```bash
k create ns lab-dnsfix
k -n lab-dnsfix create deploy web --image=nginx:1.27 --replicas=1 --port=80
k -n lab-dnsfix expose deploy web --port=80
k -n lab-dnsfix run client --image=busybox:1.36 -- sleep 3600
k -n lab-dnsfix rollout status deploy/web --timeout=90s
mkdir -p /opt/course/22
# the break — FAULT=1 or FAULT=2:
if [ "${FAULT:-1}" = "2" ]; then
  k -n kube-system get cm coredns -o yaml > /tmp/coredns-orig.yaml
  sed 's/cluster\.local/clusterX.local/g' /tmp/coredns-orig.yaml | k apply -f -
  k -n kube-system rollout restart deploy coredns
else
  k -n kube-system scale deploy coredns --replicas=0
fi
```

<details><summary><b>Grade</b></summary>

```bash
test "$(k -n kube-system get deploy coredns -o jsonpath='{.status.readyReplicas}')" = "2" && echo ok-1
k -n kube-system get cm coredns -o jsonpath='{.data.Corefile}' | grep -q 'cluster\.local' && echo ok-2
! k -n kube-system get cm coredns -o jsonpath='{.data.Corefile}' | grep -q 'clusterX' && echo ok-3
k -n lab-dnsfix exec client -- nslookup web.lab-dnsfix >/dev/null 2>&1 && echo ok-4
k -n lab-dnsfix exec client -- nslookup kubernetes.default.svc.cluster.local >/dev/null 2>&1 && echo ok-5
test -s /opt/course/22/answer && echo ok-6
```

**Pass:** all six `ok` markers. The names to check first: Deployment `coredns`, Service `kube-dns`, ConfigMap `coredns` in `kube-system` — and the Pods with label `k8s-app=kube-dns`. A Corefile fix needs a rollout restart (or ~30 s for the `reload` plugin) to take effect.

**Cleanup.** If fault 2 fired: `k apply -f /tmp/coredns-orig.yaml` is acceptable alongside a manual fix, then `k -n kube-system rollout restart deploy coredns`. If fault 1: the scale-up to 2 is the fix itself. `k delete ns lab-dnsfix`.
</details>

### Task 23 — crictl inspection on a worker

**Env:** vms · **Time:** 6 min · **Ref:** [T4.26](../part4-cka/T4.26-troubleshoot-clusters-and-nodes.md), [T4.23](../part4-cka/T4.23-manage-and-evaluate-container-output-streams.md)

**Task.** Pod `stuck` in `lab-inspe` keeps restarting. Work on the node it runs on — `kubectl logs` is off-limits for this task: use the container runtime. Write the failure message the container prints before exiting to line 1 of `/opt/course/23/answer` (on `cp1`), and the number of **running** containers on that node (`crictl ps`) to line 2.

**Setup** — on `cp1` as root, before the timer:

```bash
ssh cp1 && sudo -i
export KUBECONFIG=/etc/kubernetes/admin.conf
k create ns lab-inspe
k -n lab-inspe run stuck --image=busybox:1.36 \
  --overrides='{"spec":{"nodeName":"w1"}}' \
  -- /bin/sh -c 'echo "FATAL: missing DB_URL env"; exit 1'
k -n lab-inspe run ok-app --image=nginx:1.27 \
  --overrides='{"spec":{"nodeName":"w1"}}'
mkdir -p /opt/course/23
sleep 60     # let a few restarts accumulate
```

<details><summary><b>Grade</b></summary>

`k` and file lines run on `cp1` as root; the `ssh w1` line runs from your workstation or a second terminal:

```bash
sed -n '1p' /opt/course/23/answer | grep -q 'DB_URL' && echo ok-1
n=$(ssh w1 'crictl ps -q | wc -l'); test "$(sed -n '2p' /opt/course/23/answer | tr -d ' ')" = "$n" && echo "ok-2 running containers: $n"
test "$(k -n lab-inspe get pod stuck -o jsonpath='{.status.containerStatuses[0].restartCount}')" -ge 1 && echo ok-3
```

**Pass:** all three `ok` markers. The exam-style path: `k get pod -o wide` for the node name → `ssh` → `crictl ps -a --name stuck` → `crictl logs <container-id>` (or `--tail`). `crictl` talks to the runtime socket directly and needs no API server.

**Cleanup.** `k delete ns lab-inspe`.
</details>

### Task 24 — Deployment stuck Pending on a claim

**Env:** kind · **Time:** 7 min · **Ref:** [T4.27](../part4-cka/T4.27-troubleshoot-services-and-networking.md), [T4.15](../part4-cka/T4.15-manage-persistent-volumes-and-persistent-volume.md)

**Task.** Deployment `data-app` in `lab-pend` has shown 0/2 ready Pods for 15 minutes. The Pods are not scheduled at all and the nodes have capacity. Get both replicas `Running` and write the object kind that was blocking scheduling to `/opt/course/24/answer`.

**Setup** — before the timer:

```bash
k create ns lab-pend
cat <<'EOF' | k apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata: {name: data, namespace: lab-pend}
spec:
  accessModes: [ReadWriteOnce]
  storageClassName: gold-fast          # no such class exists in the cluster
  resources: {requests: {storage: 200Mi}}
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: data-app, namespace: lab-pend}
spec:
  replicas: 2
  selector: {matchLabels: {app: data-app}}
  template:
    metadata: {labels: {app: data-app}}
    spec:
      containers:
      - name: app
        image: busybox:1.36
        command: ["sleep","3600"]
        volumeMounts: [{name: d, mountPath: /data}]
      volumes:
      - name: d
        persistentVolumeClaim: {claimName: data}
EOF
sleep 30
k -n lab-pend get pods    # both Pending
mkdir -p /opt/course/24
```

<details><summary><b>Grade</b></summary>

```bash
test "$(k -n lab-pend get deploy data-app -o jsonpath='{.status.readyReplicas}')" = "2" && echo ok-1
test "$(k -n lab-pend get pvc data -o jsonpath='{.status.phase}')" = "Bound" && echo ok-2
grep -qiE 'storageclass|persistentvolumeclaim' /opt/course/24/answer && echo ok-3
```

**Pass:** all three `ok` markers. `FailedScheduling` + "unbound immediate PersistentVolumeClaims" points at the claim; `k describe pvc` shows it waits for a provisioner that does not exist. Both valid fixes pass: create the missing `gold-fast` StorageClass (any working provisioner — kind's is `rancher.io/local-path`), or delete and recreate the claim on a class that exists (the field is immutable — patching it is not an option).

**Cleanup.** `k delete ns lab-pend`; `k delete sc gold-fast` if you created it.
</details>

---

## Suggested 10-task sprints

Pick one row per session. Times are the sums of the targets — finishing under budget at 100% grade is the goal; the real exam averages ~6 min per task.

| Sprint | Tasks (in order) | Target | Envs | Focus |
|---|---|---|---|---|
| A — kind warm-up | 01, 06, 07, 09, 12, 13, 16, 21, 22, 24 | 64 min | kind | RBAC, scheduling, netpol, DNS, storage, three break-fixes |
| B — kind deep | 08, 10, 11, 14, 15, 17, 09, 13, 21, 22 | 70 min | kind | HPA, sidecars, Ingress+Gateway, EndpointSlice, dynamic PV |
| C — VM day | 02, 03, 04, 05, 18, 19, 20, 23, 01, 06 | 78 min | vms ×8 + kind ×2 | All cluster-admin tasks back to back |
| D — exam mix | 02, 05, 18, 07, 11, 12, 16, 21, 10, 15 | 76 min | vms ×3 + kind ×7 | Nearest to a real mix: admin, workloads, networking, storage, break-fix |

Tips for running a sprint:

- Do the `vms` block first when a sprint mixes environments — context switching between `ssh` nodes and `kind-lab` is exactly the kind of thing the exam's per-task contexts punish. Task 01 is the drill for that muscle.
- Run all eight `vms` tasks in one VM session, in numeric order: 02 (etcd) and 03 (upgrade) mutate the cluster most, so they go early; the break-fixes (18–20, 23) each restore to baseline.
- Re-run a sprint after a week. The target is not "can finish" but "same grade in half the time".

## Time log

| Date | Sprint/Task | Target | Actual | Passed first try | What slowed me |
|---|---|---|---|---|---|
| | | | | | |

## Next step

This bank trains single-task speed. For a full 2-hour, mixed-domain run under real exam pacing — sequential tasks, no breaks, one flat pass mark — use the sibling file [cka-mock-exams.md](cka-mock-exams.md), which strings these tasks into complete mock exams.
