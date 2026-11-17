# kubectl cheat sheet (practice reference)

> One dense page per area, filtered to what actually saves time in the exam. Not a lesson — a memorization target. Deeper explanations live in [T2.02](../part2-basics/T2.02-kubectl-fluency-and-productivity.md); the official page (allowed in the exam browser) is https://kubernetes.io/docs/reference/kubectl/cheatsheet/. Flags verified against kubectl v1.37.2.

Run this in every new shell first (bash; in scripts aliases need `shopt -s expand_aliases`):

```bash
alias k=kubectl
export do="--dry-run=client -o yaml"    # generate YAML, change nothing
export now="--force --grace-period=0"   # kill a pod right now
source <(kubectl completion bash); complete -o default -F __start_kubectl k
```

Exam ground rules:

- **Always type `k`, never `kubectl`.** Tab-complete resource names, not just flags.
- On control-plane nodes: `export KUBECONFIG=/etc/kubernetes/admin.conf` (or `sudo -i` where it's already root's config).
- Available tools on exam hosts: kubectl, yq, curl, wget, man. **No jq, no k9s, no kubectx/kubens/stern/tmux guaranteed** — learn the `k config`/`k get -o jsonpath` equivalents.
- `k <cmd> --help` is always there. `k options` prints every global flag.

---

## 1. Contexts and kubeconfig (do these FIRST on every task)

| Command | What it does |
|---|---|
| `k config current-context` | Where you are right now — run before any write |
| `k config get-contexts` | Table of contexts; `-o name` for names only |
| `k config use-context <ctx>` | Switch (the task usually says which) |
| `k --context <ctx> get po` | One-off command on another context — safest for multi-cluster tasks, nothing to switch back |
| `k config set-context --current --namespace=<ns>` | Set default ns for current context — then drop `-n` everywhere |
| `k config unset contexts.<ctx>.namespace` | Back to `default` |
| `k config rename-context long-name c1` | Shorten annoying names |
| `k config view` | Whole kubeconfig; `--minify` current context only; `--raw` shows cert data inline |
| `k config get-clusters` / `get-users` | List cluster / user entries |
| `k config delete-context <ctx>` | Remove a context entry |
| `k config set-cluster c --server=https://x:6443 --certificate-authority=ca.crt --embed-certs=true` | Define a cluster entry |
| `k config set-credentials u --client-certificate=u.crt --client-key=u.key --embed-certs=true` | Define a user entry |
| `k config set-context ctx --cluster=c --user=u --namespace=n` | Wire cluster+user+ns into a context |
| `KUBECONFIG=a:b k config view --flatten > merged` | Merge several kubeconfig files into one |
| `k --kubeconfig=/path/to/file get ns` | Explicit config file for one command |

Precedence: `--kubeconfig` flag > `KUBECONFIG` env (colon-separated list, merged) > `~/.kube/config`.

**Habit:** task says "set context to X" → `k config use-context X`, then `k config current-context` to prove it, then work. Wrong cluster = zero points.

## 2. Global flags that work on almost every command

| Flag | Meaning |
|---|---|
| `-n <ns>` / `--namespace` | This namespace only |
| `-A` / `--all-namespaces` | Every namespace (list commands) |
| `-l k=v` / `--selector` | Label selector (grammar in §4.2) |
| `--field-selector k=v` | Field selector (limited fields, §4.2) |
| `-o yaml\|json\|wide\|name\|kyaml` | Output format (`kyaml` keeps comments) |
| `-o jsonpath='{...}'` | Extract fields (§13) |
| `-o jsonpath-as-json='{...}'` | Same but valid JSON output |
| `-o custom-columns=N:.path,...` | Own table columns |
| `-o go-template='{{...}}'` | Go templates (has `base64decode`) |
| `--sort-by='{.path}'` | Sort a list (field must be string/int) |
| `--show-labels` / `-L l1,l2` | Labels as last column / as own columns |
| `--no-headers` | Strip table header (for pipes) |
| `-w` / `--watch` | Keep printing on change |
| `--dry-run=client` | Build object locally, don't send |
| `--dry-run=server` | Full admission+webhooks run, persist nothing — catches quota/policy errors early |
| `-f file` / `-f dir/` / `-f -` / `-f URL` | Input: file, directory, stdin, or remote manifest |
| `-R` | With `-f dir/`: recurse into subdirs |
| `-k dir/` | Treat dir as kustomization |
| `--context`, `--cluster`, `--user` | Override kubeconfig entries per command |
| `--kubeconfig=`, `--server=`, `--token=` | Point at a cluster without a context |
| `--as=user` / `--as-group=g` / `--as-uid=u` | Impersonate (RBAC testing) |
| `--request-timeout=5s` | Bail out of a hanging call |
| `--insecure-skip-tls-verify` | Skip cert validation (lab only) |
| `-v=6` / `-v=8` | Show HTTP requests / +response bodies — when kubectl behaves weirdly |
| `--force`, `--grace-period=0`, `--cascade=`, `--wait`, `--timeout=` | Delete tuning (§8) |
| `--subresource=status` | On get/patch/replace — touch subresources |
| `--chunk-size=500` | List pagination (0 disables) |
| `--ignore-not-found` | Don't error on missing objects |
| `--field-manager=name` | Who owns applied fields |
| `--show-managed-fields` | Include `managedFields` in yaml output |

## 3. Resource names and short names

Type the short name. `k api-resources` prints this table live.

| Short | Resource | | Short | Resource |
|---|---|---|---|---|
| `po` | pods | | `pvc` | persistentvolumeclaims |
| `svc` | services | | `pv` | persistentvolumes (cluster) |
| `deploy` | deployments | | `sc` | storageclasses (cluster) |
| `rs` | replicasets | | `cm` | configmaps |
| `sts` | statefulsets | | `secret` | secrets |
| `ds` | daemonsets | | `sa` | serviceaccounts |
| `job` | jobs | | `ns` | namespaces (cluster) |
| `cj` | cronjobs | | `no` | nodes (cluster) |
| `ev` | events | | `hpa` | horizontalpodautoscalers |
| `ep` | endpoints (deprecated — use endpointslice) | | `pdb` | poddisruptionbudgets |
| `endpointslice` | endpointslices | | `ing` | ingresses |
| `netpol` | networkpolicies | | `limits` | limitranges |
| `quota` | resourcequotas | | `crd` | customresourcedefinitions (cluster) |
| `csr` | certificatesigningrequests (cluster) | | `pc` | priorityclasses (cluster) |
| `role`, `rolebinding` | namespaced RBAC | | `clusterrole`, `clusterrolebinding` | cluster RBAC (cluster) |
| `rc` | replicationcontrollers (legacy) | | `cs` | componentstatuses (deprecated) |
| `apiservice` | apiservices (aggregated APIs) | | `leases` | leases (kubelet heartbeats live in `kube-node-lease`) |

Discovery commands:

```bash
k api-resources                      # everything the cluster knows
k api-resources --namespaced=false   # cluster-scoped only
k api-resources --verbs=list,create  # filter by verb
k api-resources --api-group=apps     # one API group
k api-resources -o wide              # adds VERBS + CATEGORIES columns
k api-resources --categories=all     # what `k get all` actually covers
k api-resources --cached=false       # refresh discovery (new CRD "not found" fix)
k api-versions                       # flat list of served versions
```

- Fully-qualified names disambiguate: `k get deploy.apps`, `k get hpa.autoscaling`, `k get gateways.gateway.networking.k8s.io`.
- **`k get all` is NOT everything.** `all` is a category: pods, services, workload controllers, jobs, HPAs. It misses cm/secret/pvc/netpol/quota/limits/roles — check `--categories=all` and get them explicitly.
- To list literally everything namespaced: `k api-resources --verbs=list --namespaced=true -o name | xargs -n1 k get -n <ns> --ignore-not-found` (slow, complete).

## 4. Reading objects

### 4.1 get — the workhorse

```bash
k get po                          # current namespace
k get po -A                       # all namespaces
k get po -o wide                  # +IP, NODE, nominated node, readiness gates
k get po web -o yaml              # full object
k get po web -o name              # pod/web — for scripting
k get po,svc,deploy               # several types, current ns
k get po/x svc/y deploy/z         # several named objects, mixed types
k get po -w                       # watch changes (Ctrl-C to stop)
k get po --watch-only             # watch without initial list
k get po -l app=web -L env,tier   # label columns
k get po --show-labels            # all labels last
k get po --no-headers | wc -l     # count
k get po --sort-by='{.metadata.creationTimestamp}'   # oldest first
k get po --sort-by='{.status.containerStatuses[0].restartCount}'  # crashlooplest last
k get ev --sort-by='{.lastTimestamp}' | tail        # newest events
k get po --field-selector=status.phase=Pending      # unscheduled/failed pods
k get po -A --field-selector=spec.nodeName=w1       # everything on node w1
k get ev --field-selector=type!=Normal -A           # all warnings
k get ev --field-selector=involvedObject.name=web   # events for one object
k get svc --field-selector=metadata.name!=kubernetes  # hide the default svc
k get deploy/web --subresource=scale                # scale subresource view
k get -f app.yaml                                   # what the file created, server-side
```

### 4.2 Selectors

**Label selectors** (`-l`, repeatable = AND):

| Selector | Matches |
|---|---|
| `-l app=web` | label app == web |
| `-l app!=web` | exists and != web |
| `-l 'app in (a,b)'` | set membership |
| `-l 'app notin (a,b)'` | not in set (or missing) |
| `-l 'app'` | label exists |
| `-l '!app'` | label does not exist (single quotes — `!` is history expansion) |
| `-l app=web,tier=fe` | both (comma = AND) |

Annotations are NOT selectable — only labels.

**Field selectors** (`--field-selector`, `=`/`==`/`!=`, comma = AND) — server only supports specific fields:

| Resource | Useful fields |
|---|---|
| pods | `status.phase`, `status.podIP`, `status.hostIP`, `status.nominatedNodeName`, `spec.nodeName`, `spec.restartPolicy`, `spec.schedulerName`, `spec.serviceAccountName`, `spec.hostNetwork` |
| events | `type`, `reason`, `involvedObject.name/kind/namespace/uid`, `source.component`, `metadata.name` |
| everything | `metadata.name`, `metadata.namespace` |

Nodes: only `metadata.name`. To find cordoned nodes use jsonpath: `k get no -o jsonpath='{.items[?(@.spec.unschedulable==true)].metadata.name}'`.

Unsupported field → `Error from server (BadRequest): Unable to find ... field label`. Fall back to `-l`, grep, or jsonpath.

### 4.3 custom-columns and -o name

```bash
k get po -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName,IP:.status.podIP
k get rolebindings -A -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,ROLE:.roleRef.name
k get po -o custom-columns-file=cols.txt    # file: "NAME  .metadata.name" one per line
k get po -o name                            # pod/web — pipe into xargs/loops
```

`--allow-missing-template-keys=false` makes missing fields an error instead of blank.

### 4.4 describe — first stop when something's wrong

```bash
k describe po web
k describe node w1
k describe deploy web
```

Read these sections:

- **pod**: `Status`, each container's `State`/`Last State`/`Reason`/`Exit Code`/`Restart Count`, `Conditions` (PodScheduled/Initialized/ContainersReady/Ready), `Events` at the bottom.
- **node**: `Conditions` (Ready/MemoryPressure/DiskPressure/PIDPressure/NetworkUnavailable), `Addresses`, `Taints`, `Capacity`/`Allocatable`, `Allocated resources` (sum of pod requests — "does this pod fit?"), `Non-terminated Pods`, `Events`.
- **deploy**: `Replicas` (desired vs updated/available), `StrategyType` + `RollingUpdate` params, `NewReplicaSet`, `Conditions` (Available/Progressing), `Events`.
- **svc**: `Endpoints:` line — `<none>` = selector matches nothing.
- **pvc**: `Status`, `Bound`, `Volume`, `Events` (provisioner errors).
- **netpol**: `PodSelector` + `Allowing ingress/egress traffic` summary — verifies who it applies to.

### 4.5 explain — the schema without opening docs

```bash
k explain pod.spec.containers          # field docs, required/optional
k explain pod.spec --recursive         # whole tree
k explain deployment.spec.template.spec.containers.resources
k explain httproute.spec.rules         # works for installed CRDs
k explain deploy --api-version=apps/v1 # pick a version
```

### 4.6 events

```bash
k events                          # sorted view of events (better than get ev)
k events -A --types=Warning       # all warnings cluster-wide
k events --for=pod/web            # events for one object
k events --for=pod/web -w         # live tail while it fails
k get ev --sort-by='{.lastTimestamp}' --field-selector=reason=FailedScheduling
```

Events aggregate: `.count` grows, `.lastTimestamp` is the freshest. `type!=Normal` ≈ warnings.

## 5. Creating objects — the `$do` factory

The pattern: **generate → edit → apply**. Never hand-write YAML from scratch for standard objects.

```bash
k run web --image=nginx:1.27 $do > pod.yaml     # print YAML, touch nothing
vim pod.yaml                                   # add what the generator can't
k apply -f pod.yaml                            # create or update idempotently
```

`--dry-run=server` runs real validation (admission, webhooks, quota) without persisting — use it to check a manifest first.

### 5.1 What `k create` can make (v1.37)

| Command | Key flags |
|---|---|
| `k create ns lab-x` | — |
| `k create deploy web --image=nginx:1.27 --replicas=3 --port=80 -- cmd args` | `--image` repeatable (multi-container), `--replicas`, `--port`, args after `--` |
| `k create job j --image=busybox:1.36 -- echo hi` | `--from=cronjob/<cj>` clones a CronJob into a Job |
| `k create cronjob cj --image=busybox:1.36 --schedule="*/5 * * * *" --restart=OnFailure -- cmd` | `--restart`: OnFailure\|Never only |
| `k create svc clusterip s --tcp=80:8080 --tcp=443:8443` | `--tcp=<svcPort>:<targetPort>` repeatable; `--clusterip=None` = headless |
| `k create svc nodeport s --tcp=80:8080 --node-port=30080` | + `--node-port` |
| `k create svc loadbalancer s --tcp=80:80` | external IP from cloud/MetalLB |
| `k create svc externalname s --external-name=db.example.com` | DNS CNAME record |
| `k create cm cfg --from-literal=k=v --from-literal=k2=v2` | `--from-literal`, `--from-file=path` or `--from-file=key=path`, `--from-env-file=file`, `--append-hash` |
| `k create secret generic s --from-literal=pass=s3cr3t --type=Opaque` | same as cm + `--type` |
| `k create secret tls tls-s --cert=cert.pem --key=key.pem` | `kubernetes.io/tls` |
| `k create secret docker-registry reg --docker-server=s --docker-username=u --docker-password=p --docker-email=e` | `--from-file=.dockerconfigjson` alternative |
| `k create sa app` | token: `k create token app` (§11) |
| `k create role r --verb=get,list,watch --resource=pods --resource=pods/log --resource-name=web` | flags repeatable → multiple rules/subjects |
| `k create clusterrole cr --verb='*' --resource='*'` | + `--non-resource-url=/healthz`, `--aggregation-rule='k=v'` |
| `k create rolebinding rb --role=r --user=u --group=g --serviceaccount=ns:sa` | `--clusterrole=` works here too (binds cluster perms to one ns); subject flags repeatable |
| `k create clusterrolebinding crb --clusterrole=cr --serviceaccount=ns:sa` | cluster-wide |
| `k create quota q --hard=cpu=2,memory=1Gi,pods=10` | `--scopes=` |
| `k create pdb p --selector=app=web --min-available=1` | or `--max-unavailable=20%` |
| `k create priorityclass p --value=10000 --global-default=false --description="hi"` | `--preemption-policy=Never` |
| `k create ingress ing --class=traefik --rule="app.local/*=web:80" --rule="api.local/v1=api:8080,tls=api-tls"` | `--rule="host/path=svc:port[,tls=secret]"` repeatable; `*` in path = pathType Prefix; `--default-backend="svc:port"`, `--annotation=` |
| `k create token sa --duration=1h` | `--audience=`, `--bound-object-kind=Pod --bound-object-name=p` |

### 5.2 What has NO generator — go get YAML elsewhere

`pv`, `pvc`, `netpol`, `limits` (LimitRange), `sc`, `ds`, `sts`, `csr`, `lease`, webhook configs, `vap`, Gateway API (`gateway`, `httproute`), custom resources.

Fastest sources: copy from the exam docs (allowed), or clone an existing object (§6.6).

### 5.3 `k run` — the pod factory (all flags)

```bash
k run web --image=nginx:1.27                    # a bare pod (run ONLY makes pods)
k run web --image=nginx:1.27 --port=80          # declares containerPort (does NOT expose!)
k run web --image=nginx:1.27 -l app=web,tier=fe # labels
k run web --image=nginx:1.27 --env=A=1 --env=B=2
k run web --image=nginx:1.27 --annotations='k=v'
k run web --image=nginx:1.27 --restart=Never    # Never|OnFailure|Always — sets restartPolicy
k run web --image=nginx:1.27 --privileged       # privileged container
k run web --image=nginx:1.27 --image-pull-policy=Always
k run web --image=busybox:1.36 -- sleep 3600    # args after -- become command ARGS
k run web --image=busybox:1.36 --command -- sh -c 'sleep 3600'  # --command → entrypoint
k run web --image=nginx:1.27 --expose --port=80 # +ClusterIP svc (deprecated, prefer create svc)
k run -it tmp --rm --image=busybox:1.36 -- sh   # THE throwaway shell: exits = pod gone
k run dns --rm -it --image=busybox:1.36 --restart=Never -- nslookup web
k run curl --rm -it --image=curlimages/curl:8.16.0 -- http://web/
k run web --image=nginx:1.27 --overrides='{"spec":{"nodeName":"w1"}}'           # pin to node
k run web --image=nginx:1.27 --overrides='{"spec":{"serviceAccountName":"app"}}' # run has NO --serviceaccount flag
k run web --image=nginx:1.27 --overrides='{"spec":{"hostNetwork":true}}'
```

`--overrides` merges JSON into the object (`--override-type=strategic|merge|json`). `-i`+`-t` attach; `--rm` deletes on exit; `--attach` waits for Running; `--pod-running-timeout=1m`; `--leave-stdin-open`; `-q` quiet. There is also `--edit` on `k create`/`k run` — opens the generated object in vim before submitting.

**Trick to remember:** `--port` only writes `containerPort` metadata — it exposes nothing. To actually serve traffic you need a Service (§5.1, `k expose`).

### 5.4 expose — wrap an existing object in a Service

```bash
k expose deploy web --port=80 --target-port=8080 --type=ClusterIP --name=web-svc
k expose pod web --port=80                      # single-pod service
k expose deploy web --port=80 --type=NodePort --name=web-np
k expose deploy web --port=80 --cluster-ip=None # headless
k expose deploy web --port=80 --session-affinity=ClientIP
```

Defaults: `--type=ClusterIP`, port copied from the workload's `containerPort` if `--port` omitted. Selector is taken from the workload. `$do` works here too.

## 6. Changing objects

### 6.1 Which mutation tool when

| Situation | Use |
|---|---|
| Field the generator got wrong / quick live change | `k edit` |
| One scalar field, scriptable | `k patch` |
| Well-known field (image, env, replicas, sa, resources) | `k set` / `k scale` |
| The file is the truth (your YAML) | `k apply -f` |
| Immutable field must change | `k replace --force -f` (delete+recreate) |
| Metadata only | `k label` / `k annotate` |
| Preview before applying | `k diff -f` or `--dry-run=server` |

```bash
k edit deploy web                     # KUBE_EDITOR=nano to pick editor; bad edit → retry prompt
k edit --output-patch                 # show the patch your edit produced
k diff -f app.yaml                    # what apply WOULD change
k apply -f app.yaml                   # create-or-update
k apply -f dir/ -R                    # whole tree
k apply -k kustomize-dir/             # kustomize
k apply --server-side --force-conflicts -f app.yaml   # server-side apply, take field ownership
k replace -f app.yaml                 # full PUT — object must exist
k replace --force -f app.yaml         # delete + recreate (immutable fields)
k patch --patch-file=fix.patch deploy web             # patch from file
KUBECTL_EXTERNAL_DIFF="diff -u -N" k diff -f app.yaml # custom differ
```

### 6.2 `k set` — the common fields

```bash
k set image deploy/web nginx=nginx:1.28 other=img2   # per-container; --all = every matching workload
k set image --local -f pod.yaml nginx=nginx:1.28 -o yaml > new.yaml   # offline edit, no cluster
k set env deploy/web A=1 B=2          # add/replace env
k set env deploy/web A-               # remove env
k set env deploy/web --list           # show env
k set env deploy/web -c sidecar X=1   # one container only
k set env deploy/web --from=configmap/cfg      # envFrom
k set env deploy/web --from=secret/s --prefix=APP_   # envFrom + prefix
k set env deploy/web --from=secret/s --keys=pass     # one key only
k set resources deploy/web -c=web --requests=cpu=100m,memory=128Mi --limits=cpu=200m
k set serviceaccount deploy/web app   # serviceAccountName
k set subject rolebinding rb --user=u --group=g --serviceaccount=ns:sa
```

### 6.3 `k patch` — surgical edits

`--type`: `strategic` (default — merges lists by `name`), `merge` (replaces whole lists/maps), `json` (RFC 6902 ops — only way to touch list items by index, add/remove).

```bash
k patch deploy web -p '{"spec":{"replicas":5}}'                                   # strategic (default)
k patch deploy web -p '{"spec":{"template":{"spec":{"nodeSelector":{"disk":"ssd"}}}}}'
k patch deploy web -p '{"spec":{"template":{"spec":{"containers":[{"name":"web","image":"nginx:1.28"}]}}}}'  # merges by container name
k patch svc web --type=merge -p '{"spec":{"ports":[{"port":80,"targetPort":8080}]}}'  # replace whole ports list
k patch node w1 -p '{"spec":{"unschedulable":true}}'                              # = cordon
k patch pv vol -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'           # classic task
k patch pvc data -p '{"spec":{"resources":{"requests":{"storage":"2Gi"}}}}'       # expand (SC must allow it)
k patch pvc data --type=json -p='[{"op":"replace","path":"/spec/volumeName","value":"vol-9"}]'  # bind to specific PV
k patch cronjob cj -p '{"spec":{"suspend":true}}'                                 # pause without deleting
k patch po web --type=json -p='[{"op":"add","path":"/spec/containers/0/env/-","value":{"name":"A","value":"1"}}]'  # append to list
k patch po web --type=json -p='[{"op":"remove","path":"/metadata/finalizers/0"}]' # remove a finalizer
k patch deploy web --subresource=status -p '{"status":{}}'                        # status subresource
```

### 6.4 label / annotate

```bash
k label po web env=prod                 # add (fails if exists)
k label po web env=prod2 --overwrite    # change existing
k label po web env-                     # remove (trailing -)
k label po web --list                   # show labels
k label po --all tier=fe                # every pod in ns
k label po -l env=dev tier=fe           # label a selected set
k label ns x pod-security.kubernetes.io/enforce=restricted
k label no w1 disk=ssd
k annotate deploy web kubernetes.io/change-cause="image bump to 1.28" --overwrite
k annotate po web key-                  # remove annotation
```

### 6.5 scale / autoscale

```bash
k scale deploy web --replicas=5         # deploy, sts, rs, rc all work
k scale deploy web --replicas=0         # park an app
k scale deploy web --replicas=5 --current-replicas=3   # only if currently 3
k autoscale deploy web --min=2 --max=10 --cpu=80%      # makes an HPA v2
k autoscale deploy web --min=2 --max=10 --cpu=500m     # quantity form also valid
k autoscale deploy web --min=1 --max=5 --memory=60%
```

`k autoscale ... $do > hpa.yaml` — generate the HPA skeleton, then edit in extra metrics. `k describe hpa` shows live % + events; `k get hpa -w` watches scaling decisions.

### 6.6 Clone / copy / move objects

```bash
# same ns, rename:
k get cm cfg -o yaml | yq 'del(.metadata.resourceVersion,.metadata.uid,.metadata.creationTimestamp,.status) | .metadata.name = "cfg2"' | k create -f -
# to another namespace:
k get secret s -n a -o yaml | yq 'del(.metadata.resourceVersion,.metadata.uid,.metadata.creationTimestamp,.status,.metadata.namespace)' | k -n b create -f -
```

Fields that must go before recreating: `status`, `metadata.resourceVersion`, `metadata.uid`, `metadata.creationTimestamp`, `metadata.namespace` (if retargeting), `metadata.selfLink`, `metadata.ownerReferences` (if parentless copy desired), `metadata.managedFields` (hidden by default anyway).

## 7. rollout — deployments, daemonsets, statefulsets

| Command | Purpose |
|---|---|
| `k rollout status deploy/web` | Block until done; `--timeout=30s`, `--watch=false` for one-shot check |
| `k rollout history deploy/web` | Revisions table (CHANGE-CAUSE = `kubernetes.io/change-cause` annotation — `--record` is gone, annotate it yourself) |
| `k rollout history deploy/web --revision=3` | That revision's pod template |
| `k rollout undo deploy/web` | Back one revision |
| `k rollout undo deploy/web --to-revision=2` | Back to a specific revision |
| `k rollout restart deploy/web` | Bounce all pods (bumps `restartedAt` annotation → new RS) |
| `k rollout pause deploy/web` | Freeze — batch several `set`/`patch` edits… |
| `k rollout resume deploy/web` | …then one rollout for all of them |

Watch the machinery: `k get rs -l app=web -o wide` (old RS scales down, new scales up), `k get po -l app=web -w`.

## 8. Deleting things

```bash
k delete po web                     # graceful (30s default grace)
k delete po web $now                # force delete, don't wait — "stuck pod" fix
k delete po --all                   # every pod in ns (they may respawn via controllers!)
k delete po -l app=web              # by label
k delete po --field-selector=status.phase=Succeeded   # completed pods cleanup
k delete deploy,svc -l app=web      # mixed types by label
k delete all -l app=web             # "all" category by label (see §3 caveat)
k delete all --all -n lab-x         # nuke ns workloads — still leaves cm/secret/pvc!
k delete -f app.yaml                # what's in the file
k delete po x --cascade=orphan      # kill parent, leave pods running
k delete po x --cascade=foreground  # wait for dependents first
k delete po x --wait=false          # return immediately
k delete job old --ignore-not-found # idempotent for scripts
k delete ns lab-x                   # everything inside goes with it
```

`--now` = `--wait=false --grace-period=1`. `$now` is harsher (force + 0). Deleting a controller's pod just reschedules it — delete the controller.

**Stuck namespace (`Terminating` forever):** `force` won't help — it's a finalizer.

```bash
NS=lab-x
k get ns $NS -o json | sed 's/"kubernetes"//' | k replace --raw "/api/v1/namespaces/$NS/finalize" -f -
```

**Other stuck things:** PVC won't die while a pod mounts it (`kubernetes.io/pvc-protection`); PV in `Released` keeps its `claimRef` — `k patch pv vol --type=json -p='[{"op":"remove","path":"/spec/claimRef"}]'`.

## 9. Inside the pod

### 9.1 exec / attach / cp

```bash
k exec -it web -- sh                # sh before bash (busybox has no bash)
k exec web -- env                   # one-shot command, no shell needed
k exec -it web -c sidecar -- sh     # pick container (required when >1)
k exec -it deploy/web -- sh         # controllers work — picks ONE pod
k attach web -it                    # attach to running process (rare)
k cp web:/var/log/app.log ./app.log # pod → local (needs `tar` in image)
k cp ./cfg web:/etc/app/ -c sidecar # local → pod
```

### 9.2 logs

```bash
k logs web                          # single-container pod
k logs web -c sidecar               # REQUIRED when >1 container (or --all-containers)
k logs web --previous               # the crashed container's last words — CrashLoopBackOff #1 move
k logs web -f                       # follow
k logs web --tail=50                # last N lines
k logs web --since=10m / --since-time=2026-11-17T09:00:00Z
k logs web --timestamps             # prefix each line (ordering across replicas)
k logs -l app=web --all-containers --prefix --tail=20  # fan-in from many pods
k logs -l app=web --max-log-requests=20 --ignore-errors
k logs deploy/web                   # one pod's logs, not all — use -l for all
k logs job/pi                       # job's pod
k -n kube-system logs etcd-cp1      # control plane via mirror pods
```

### 9.3 port-forward — bypass the Service, or test it

```bash
k port-forward pod/web 8080:80      # local 8080 → pod 80 (pod-level test)
k port-forward svc/web 8080:80      # through the Service (svc-level test)
k port-forward deploy/web 8080:80   # resolves to a pod too
k port-forward pod/web 8080         # same port both sides
k port-forward pod/web :80          # random local port
k port-forward --address 0.0.0.0 pod/web 8080:80   # share outside localhost
```

It holds the terminal — second terminal or `&` + `kill %1`. Use it to isolate layers: does the POD answer (pf→pod)? does the SERVICE answer (pf→svc)? does the INGRESS answer (curl the LB IP)? First broken layer is where the bug is.

### 9.4 debug — ephemeral containers, pod copies, node shells

```bash
k debug -it web --image=busybox:1.36 --target=app          # ephemeral container INTO running pod; --target shares app container's processes
k debug -it web --image=nicolaka/netshoot:v0.16 --target=app  # tcpdump/nsenter toolchain
k debug web -it --image=busybox:1.36 --profile=sysadmin    # privileged profile (general|baseline|restricted|netadmin|sysadmin)
k debug web --copy-to=web-v2 --set-image=app=nginx:1.28    # clone pod with different image
k debug web --copy-to=web-sh -it --share-processes --image=busybox:1.36 -- sh   # clone + process sharing
k debug web --copy-to=web-v2 --replace --set-image=app=fixed:tag   # swap the pod entirely
k debug node/w1 -it --image=busybox:1.36                   # pod ON the node, host FS at /host
#   inside it:  chroot /host    → journalctl -u kubelet, crictl ps, systemctl status kubelet
```

`--copy-to` modifiers: `--same-node`, `--keep-labels`, `--keep-annotations`, `--keep-init-containers` (default true), `--keep-liveness/--keep-readiness/--keep-startup`, `--replace`, `--share-processes` (default true on copy), `--set-image=` repeatable.

### 9.5 proxy and raw API — when objects aren't enough

```bash
k proxy --port=8001 &               # full API on localhost:8001
curl localhost:8001/version
curl localhost:8001/api/v1/namespaces/default/services/web:80/proxy/   # reach a Service THROUGH the apiserver
k get --raw '/readyz?verbose'       # apiserver health checks
k get --raw '/metrics' | head       # apiserver metrics
k get --raw '/apis/metrics.k8s.io/v1beta1/nodes'   # is metrics-server serving?
k get --raw '/api' ; k get --raw '/apis'           # discovery: versions/groups
k create --raw '/api/v1/namespaces/x/secrets' -f s.yaml   # POST
k replace --raw '/api/v1/namespaces/x/finalize' -f -      # PUT (the ns-unstick trick)
k delete --raw '/api/v1/namespaces/x/pods/y'              # DELETE
```

## 10. Watching and waiting

```bash
k get po -w                        # watch list
k get po --watch-only              # watch only (skip initial list)
k get po -w --output-watch-events  # raw ADDED/MODIFIED/DELETED events
k logs web -f                      # follow logs (Ctrl-C just detaches)
k events --for=pod/web -w          # watch events for one object
k rollout status deploy/web        # block on rollout progress
k wait --for=condition=ready pod/web --timeout=60s         # block on condition (default 30s!)
k wait --for=condition=complete job/pi --timeout=120s
k wait --for=delete pod/web --timeout=30s                  # block until gone
k wait --for=create -l app=web pod --timeout=60s           # block until it exists (needs -l or -f)
k wait --for=jsonpath='{.status.phase}'=Succeeded pod/job-pod --timeout=60s
k wait --for=condition=ready pod -l app=web --timeout=60s  # all matching pods
```

`--for` repeatable = AND. Condition names are case-folded (`ready`≈`Ready`). `wait` on Jobs: use `condition=complete` — "complete" appears only when done.

## 11. auth — RBAC from the command line

```bash
k auth can-i create deployments                    # me, current ns
k auth can-i get pods -n kube-system               # me, other ns
k auth can-i '*' '*'                               # cluster-admin?
k auth can-i --list -n x                           # everything I'm allowed to do
k auth can-i create deploy --as=system:serviceaccount:x:app -n x   # AS that SA
k auth can-i list secrets --as=alice --as-group=devs -A            # as user+group
k auth whoami                                      # who kubectl thinks I am
k create token app --duration=10m                  # short-lived SA token (no more auto secret!)
k auth reconcile -f rbac.yaml                      # create/update roles+bindings from file
```

Fast RBAC verify loop: create SA → role → rolebinding → `k auth can-i ... --as=system:serviceaccount:ns:sa` → check yes/no.

CSR flow (client cert for a user):

```bash
openssl req -new -newkey rsa:2048 -nodes -keyout u.key -subj "/CN=u/O=devs" -out u.csr   # user side
# CSR object via YAML (no imperative generator): base64 the csr into spec.request
cat u.csr | base64 | tr -d '\n'    # → spec.request, signerName: kubernetes.io/kube-apiserver-client
k apply -f csr.yaml
k get csr                          # CONDITION column
k certificate approve u-csr        # or deny
k get csr u-csr -o jsonpath='{.status.certificate}' | base64 -d > u.crt
k get csr u-csr -o jsonpath='{.spec.request}' | base64 -d | openssl req -text -noout   # inspect CSR
k config set-credentials u --client-key=u.key --client-certificate=u.crt --embed-certs=true
k config set-context u --cluster=kind-lab --user=u
```

## 12. Node and cluster admin

### 12.1 cordon / drain / taint

```bash
k cordon w1                        # unschedulable (STATUS: Ready,SchedulingDisabled)
k uncordon w1                      # back
k drain w1 --ignore-daemonsets --delete-emptydir-data   # evict + cordon
k drain w1 --pod-selector=app=web --ignore-daemonsets   # drain only these pods
k drain w1 --dry-run=client        # what would be evicted
k drain w1 --ignore-daemonsets --delete-emptydir-data --disable-eviction  # skip Eviction API/PDB
k taint node w1 dedicated=ci:NoSchedule                # add taint
k taint node w1 dedicated=ci:NoSchedule-               # remove that taint
k taint node w1 dedicated-                             # remove all taints with this key
k describe node w1 | grep -A3 Taints
```

Taint effects: `NoSchedule` (never schedule), `PreferNoSchedule` (soft), `NoExecute` (evict existing too). Drain fails on: DaemonSet pods (→ `--ignore-daemonsets`), emptyDir data (→ `--delete-emptydir-data`), bare pods (→ `--force`), PDB blocks (`k get pdb` → check `ALLOWED DISRUPTIONS`).

### 12.2 Cluster view via kubectl

```bash
k get no -o wide                    # STATUS/VERSION/INTERNAL-IP/OS/KERNEL/RUNTIME
k get no -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.conditions[?(@.type=="Ready")].status}{"\t"}{.status.nodeInfo.kubeletVersion}{"\n"}{end}'
k get no -l node-role.kubernetes.io/control-plane       # cp nodes
k get no -l '!node-role.kubernetes.io/control-plane'    # workers
k get po -A -o wide --field-selector=spec.nodeName=w1   # what's on w1
k describe no w1 | grep -A20 'Allocated resources'      # request sums
k top node ; k top pod -A --sort-by=memory              # needs metrics-server
k -n kube-system get po -o wide                         # control plane health (static pods!)
k -n kube-system get po kube-apiserver-cp1 -o jsonpath='{.spec.containers[0].command}'  # apiserver flags (admission plugins, encryption config, etcd endpoints)
k -n kube-system get cm kubeadm-config -o yaml          # cluster config (podSubnet, certsDir)
k -n kube-system logs kube-scheduler-cp1 --tail=50      # cp logs via mirror pods (exec FAILS — distroless images)
k get leases -n kube-node-lease                         # kubelet heartbeats — stale renewTime = dead kubelet
k get apiservices                                       # aggregated APIs (metrics-server etc.) + False = backend down
k get --raw '/readyz?verbose'                           # apiserver self-checks
k get --raw '/healthz'  # "ok"
k cluster-info                                          # apiserver + DNS endpoints
k version                                               # client + server versions
k get csr ; k certificate approve <csr>                 # pending CSRs
```

`k get cs` (componentstatuses) is deprecated and empty on modern clusters — use `--raw /readyz?verbose` + the mirror pods.

### 12.3 Companion CLIs (not kubectl, but exam kit)

```bash
# kubeadm (on cp nodes, as root)
kubeadm token create --print-join-command     # join command for new nodes
kubeadm certs check-expiration                # cert expiry table
kubeadm certs renew all                       # renew pki certs
kubeadm upgrade plan                          # what upgrade would do
kubeadm upgrade apply v1.37.1                 # upgrade cp
kubeadm upgrade node                          # worker/cp-local step
kubeadm config images pull                    # prefetch images
kubeadm reset -f                              # nuke the node

# etcdctl (CKA: snapshot save/restore)
ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key snapshot save /opt/snap.db
ETCDCTL_API=3 etcdctl ... snapshot status /opt/snap.db -w table
ETCDCTL_API=3 etcdctl ... snapshot restore /opt/snap.db --data-dir /var/lib/etcd-new
ETCDCTL_API=3 etcdctl ... member list ; endpoint health

# crictl (node-level container runtime, containerd)
crictl ps ; crictl ps -a ; crictl pods ; crictl images
crictl logs <cid> ; crictl inspect <cid> ; crictl inspectp <podid>
crictl stats ; crictl info ; crictl rm <cid> ; crictl rmi <img>
ctr -n k8s.io containers ls                   # raw containerd (k8s.io namespace!)

# node systemd
systemctl status kubelet ; systemctl restart kubelet
journalctl -u kubelet -f ; journalctl -u kubelet -n 100 --no-pager
journalctl -u containerd --since '10 min ago'

# certs
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -dates -subject -issuer
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -text | grep -A1 'Subject Alternative Name'
```

## 13. JSONPath + templates — the recipe bank

Syntax: `{.field}`, `{.items[*]}`, `{range .items[*]}...{end}`, `{.items[?(@.field=="v")].name}` filters, `{.list[?(@.type=="Ready")].status}` nested conditions.

```bash
# the workhorse table
k get po -A -o jsonpath='{range .items[*]}{.metadata.namespace}{"/"}{.metadata.name}{"\t"}{.status.phase}{"\t"}{.spec.nodeName}{"\n"}{end}'
# pod conditions
k get po web -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}'     # → True
k get no -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}'
# single fields (the "write X to /opt/course/NN/answer" tasks)
k get po web -o jsonpath='{.spec.containers[0].image}' > /opt/course/05/answer
k get po web -o jsonpath='{.status.podIP}'
k get deploy web -o jsonpath='{.spec.template.spec.containers[0].image}'
k get po web -o jsonpath='{.status.containerStatuses[*].restartCount}'
k get po web -o jsonpath='{.status.containerStatuses[*].lastState.terminated.exitCode}'   # why it died
k get po web -o jsonpath='{.status.containerStatuses[*].lastState.terminated.reason}'     # OOMKilled?
# secrets (decode!)
k get secret s -o jsonpath='{.data.password}' | base64 -d
k get secret s -o go-template='{{range $k,$v := .data}}{{printf "%s: %s\n" $k ($v | base64decode)}}{{end}}'
# reports
k get no -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.status.addresses[?(@.type=="InternalIP")].address}{"\n"}{end}'
k get po -A -o jsonpath='{range .items[*]}{.spec.containers[*].image}{"\n"}{end}' | sort | uniq -c   # image census
k get po -o jsonpath='{range .items[*]}{.spec.nodeName}{"\n"}{end}' | sort | uniq -c               # pods per node
k get po -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}'
k get po -o jsonpath='{range .items[?(@.status.phase!="Running")]}{.metadata.name}{" "}{.status.phase}{"\n"}{end}'
k get svc web -o jsonpath='{.spec.selector}'     # vs pod labels — the svc debug pair
k get svc web -o jsonpath='{.spec.ports[0].nodePort}'
k get svc web -o jsonpath='{.status.loadBalancer.ingress[0]}'
k get pvc data -o jsonpath='{.spec.volumeName}' ; k get pv vol -o jsonpath='{.spec.claimRef}'
k get po web -o jsonpath='{.spec.volumes}'  ;  '{.spec.containers[0].volumeMounts}'
k get hpa -o jsonpath='{.items[*].status.currentMetrics}'
k get endpointslices -l kubernetes.io/service-name=web -o jsonpath='{.items[*].endpoints[*].addresses[0]}'
```

`custom-columns` = same paths, nicer columns. `go-template` = when you need funcs (`base64decode`, `printf`, range over maps). `jsonpath` can't sum restart counts — use `--sort-by` or `sort -n` after.

## 14. Exam-style one-liner recipes

| Task | Command |
|---|---|
| Answer file | `k get po web -o jsonpath='{.status.podIP}' > /opt/course/05/answer` |
| Pod using most CPU | `k top pod -A --sort-by=cpu --no-headers \| head -1` |
| Write all pod IPs on node w1 | `k get po -A --field-selector=spec.nodeName=w1 -o jsonpath='{.items[*].status.podIP}'` |
| Fix svc pointing nowhere | `k get svc s -o jsonpath='{.spec.selector}'` then `k get po -l <that>` and `k get endpointslices -l kubernetes.io/service-name=s` |
| Headless svc | `k create svc clusterip s --clusterip=None --tcp=80:80 $do` |
| Pod on a specific node, fast | `k run x --image=nginx:1.27 --overrides='{"spec":{"nodeName":"w1"}}'` |
| Find cordoned nodes | `k get no -o jsonpath='{.items[?(@.spec.unschedulable==true)].metadata.name}'` |
| Suspend a cronjob | `k patch cronjob cj -p '{"spec":{"suspend":true}}'` |
| Run a cronjob NOW | `k create job manual --from=cronjob/cj` |
| Record why you changed it | `k annotate deploy web kubernetes.io/change-cause="bumped to 1.28" --overwrite` |
| Free a Released PV | `k patch pv vol --type=json -p='[{"op":"remove","path":"/spec/claimRef"}]'` |
| Decode every key in a secret | `k get secret s -o go-template='{{range $k,$v := .data}}{{printf "%s=%s\n" $k ($v \| base64decode)}}{{end}}'` |
| Everything not Running | `k get po -A \| grep -vE 'Running\|Completed\|NAMESPACE'` (or the jsonpath above) |
| Copy cm to another ns | `k get cm c -n a -o yaml \| yq 'del(.metadata.resourceVersion,.metadata.uid,.metadata.creationTimestamp,.metadata.namespace)' \| k -n b apply -f -` |
| Service reachable? skip port-forward | `k get --raw '/api/v1/namespaces/x/services/s:80/proxy/'` |
| Quick DNS check | `k run d --rm -it --image=busybox:1.36 --restart=Never -- nslookup s.x` |
| Quick HTTP check | `k run c --rm -it --image=curlimages/curl:8.16.0 -- curl -sv http://s.x/` |
| Pending pods and why | `k get po -A --field-selector=status.phase=Pending` → `k describe` → read `FailedScheduling` event node lines (`0/3 nodes are available: 2 Insufficient cpu, 1 untolerated taint`) |
| Who can do X | `k auth can-i create deploy --as=system:serviceaccount:ns:sa -n ns` |
| Node heartbeats | `k get leases -n kube-node-lease` — stale `renewTime` = dead kubelet |
| All images in use | `k get po -A -o jsonpath='{.items[*].spec.containers[*].image}' \| tr ' ' '\n' \| sort -u` |

## 15. Troubleshooting ladders

**Pod STATUS → next move:**

| STATUS | Means | First command |
|---|---|---|
| `Pending` | not scheduled yet | `k describe po` → `FailedScheduling` event lists which nodes failed and why |
| `ContainerCreating` | pulling/mounting | `k describe po` events (image pull? volume attach?) |
| `ImagePullBackOff`/`ErrImagePull` | bad image name/registry/creds | `k get po -o jsonpath='{.spec.containers[*].image}'`, check imagePullSecrets |
| `CrashLoopBackOff` | runs then dies | `k logs p --previous`, then `lastState.terminated` (exitCode/reason) |
| `CreateContainerConfigError` | missing cm/secret | `k describe po` → names the missing object |
| `Init:N/M` / `Init:Error` | init container running/failed | `k logs p -c <init-name>` |
| `Running` 0/1 ready | alive but failing readiness | probe config, `k describe po` → `Readiness probe failed` events |
| `Evicted` | node pressure killed it | `k describe no` → DiskPressure/MemoryPressure; delete the corpse |
| `Terminating` | finalizer or grace hang | `k get po p -o jsonpath='{.metadata.finalizers}'`; `$now` as last resort |
| `OOMKilled` (in lastState) | exceeded memory limit | bump limits / fix the leak |
| `Unknown` | node unreachable | `k get no`, `k get leases -n kube-node-lease` |

**Service unreachable, in order:** 1) `k get svc s` ports vs `k get po -o wide` pod ports 2) `k get endpointslices -l kubernetes.io/service-name=s` — empty? 3) `k get svc s -o jsonpath='{.spec.selector}'` vs `k get po -l <sel> --show-labels` 4) `k port-forward pod/x` (pod ok?) then `k port-forward svc/s` (svc ok?) 5) DNS: `nslookup s.ns` from a pod 6) netpol silently dropping: `k get netpol -A`, `k describe netpol`.

**DNS names:** `svc`, `svc.ns`, `svc.ns.svc.cluster.local`; pods get `1-2-3-4.ns.pod.cluster.local` (dashed IP) when a headless svc or hostname exists. `k exec p -- cat /etc/resolv.conf`.

**Node NotReady:** `k get no` → `k describe no` Conditions + Events → `k get leases -n kube-node-lease` (stale renewTime = dead kubelet) → on the node: `systemctl status kubelet`, `journalctl -u kubelet -n 100 --no-pager`, `crictl ps`, or `k debug node/w1 -it --image=busybox:1.36` → `chroot /host`.

**"Mystery" mutations/denials at create time:** `k get limits -o yaml` (injected defaults), `k describe quota` (`exceeded quota` errors), `k get mutatingwebhookconfigurations,validatingwebhookconfigurations` (field changes, `failed calling webhook`), `k get validatingadmissionpolicies` (CEL denies), `k get ns -o yaml` → `pod-security.kubernetes.io/*` labels (PSA rejects `privileged`, hostPath, etc.). `--dry-run=server` surfaces all of these before you commit.

**Control plane:** `k -n kube-system get po` (mirror pods = apiserver/etcd/scheduler/cm health), `k get --raw /readyz?verbose`, `k -n kube-system logs <cp-pod>`, mirror pod's `.spec.containers[0].command` to read component flags; on the node: files in `/etc/kubernetes/manifests/` are the source of truth — edit → kubelet restarts the component.

## 16. Speed drills + habits

Run these against your kind cluster until each is under ~2 min:

1. Contexts: create a second kind cluster, switch to it, deploy `web` (nginx:1.27, 3 replicas), switch back — verify both clusters with `--context` only.
2. `$do` factory: generate deploy+svc+yaml in one line, apply, verify endpoints.
3. CrashLoop fix: `k run bad --image=busybox:1.36 -- false` → find exit code + reason via jsonpath, fix.
4. Secret → env: create secret, `k set env --from=secret/`, verify with `k exec -- env`.
5. JSONPath: pods→file answer, node version/IP table, decode a secret.
6. Drain + uncordon a kind worker, watch pods migrate (`-w` in a second terminal).
7. RBAC loop: SA + role(get/list pods) + rolebinding + `auth can-i` proof.
8. Patch: add env via `--type=json` add-op; change svc ports via `--type=merge`.
9. Fix broken svc selector + empty endpoints (label a pod to match).
10. etcd snapshot save → `snapshot status -w table` (on a kubeadm lab).

Habits: `k config current-context` before writes · `-n` on everything (or `set-context --current --namespace`) · `$do > f.yaml` → vim → `k apply -f` · verify every change with `get`/`describe`/`endpointslices` · `--dry-run=server` to pre-check · write answer files with `> /opt/course/NN/answer` exactly as the task says · `k explain`/`api-resources` instead of docs when the field name is the question · `k <cmd> --help` before guessing a flag.
