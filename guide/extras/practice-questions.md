# CKAD practice questions

> These questions come from an earlier CKAD practice app. They are a starting point for self-testing — verify every answer on your own cluster before relying on it.

---

## q001 — Create a Simple Pod with Labels

> Domain: Application Design & Build | Difficulty: Beginner | Est. time: 8 min

Create a pod named `webapp` running `nginx:1.27` with labels `app=frontend` and `version=v1`. Expose it on port 80.

<details>
<summary>Hints</summary>

- Use the `kubectl run` command with the `--labels` flag
- Remember to specify the port in the pod spec
- Labels should be `key=value` pairs

</details>

<details>
<summary>Solution</summary>

```bash
kubectl run webapp --image=nginx:1.27 --labels=app=frontend,version=v1 --port=80
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: webapp
  labels:
    app: frontend
    version: v1
spec:
  containers:
  - name: nginx
    image: nginx:1.27
    ports:
    - containerPort: 80
```

</details>

This creates a basic pod with custom labels. Labels are key-value pairs used for organizing and selecting objects.

## q002 — ConfigMap and Secret Integration

> Domain: Environment & Security | Difficulty: Intermediate | Est. time: 15 min

Create a ConfigMap for app configuration and a Secret for database credentials. Mount both in a pod running `mysql:8.0`.

<details>
<summary>Hints</summary>

- Create the ConfigMap using `kubectl create configmap`
- Create the Secret using `kubectl create secret`
- Mount as volumes or environment variables

</details>

<details>
<summary>Solution</summary>

```bash
kubectl create configmap app-config --from-literal=DB_HOST=mysql-service --from-literal=DB_PORT=3306
```

```bash
# ConfigMap creation
kubectl create configmap app-config \
  --from-literal=DB_HOST=mysql-service \
  --from-literal=DB_PORT=3306

# Secret creation
kubectl create secret generic db-secret \
  --from-literal=username=admin \
  --from-literal=password=secretpass
```

</details>

ConfigMaps store non-sensitive configuration data, while Secrets store sensitive data like passwords.

## q003 — Micro-segmentation with Network Policies

> Domain: Services & Networking | Difficulty: Advanced | Est. time: 25 min

Implement network policies to secure communication between frontend, backend, and database tiers in a namespace.

<details>
<summary>Hints</summary>

- Use `podSelector` to target specific pods
- Configure ingress and egress rules
- Test network connectivity after applying

</details>

<details>
<summary>Solution</summary>

Apply a NetworkPolicy with proper selectors and rules for each tier.

</details>

NetworkPolicies provide micro-segmentation by controlling traffic flow between pods based on labels.

## q004 — Rolling Updates and Rollbacks

> Domain: Application Deployment | Difficulty: Intermediate | Est. time: 12 min

Deploy an application with a rolling update strategy, perform an update, and demonstrate rollback capabilities.

<details>
<summary>Hints</summary>

- Use a Deployment resource for rolling updates
- Configure `maxUnavailable` and `maxSurge`
- Use `kubectl rollout` commands

</details>

<details>
<summary>Solution</summary>

```bash
kubectl create deployment app --image=nginx:1.27 --replicas=3
```

</details>

Rolling updates ensure zero downtime by gradually replacing old pods with new ones.

## q005 — Multi-container Pod Patterns

> Domain: Application Design & Build | Difficulty: Intermediate | Est. time: 18 min

Create a pod with the sidecar pattern: a main application container and a logging sidecar that processes logs.

<details>
<summary>Hints</summary>

- Use shared volumes between containers
- Configure an `emptyDir` volume for log sharing
- Both containers should mount the same volume

</details>

<details>
<summary>Solution</summary>

Create a multi-container pod YAML with a shared volume.

</details>

The sidecar pattern allows helper containers to augment the functionality of the main container.

## q006 — Persistent Volume Claims

> Domain: Application Design & Build | Difficulty: Intermediate | Est. time: 20 min

Create a PersistentVolumeClaim and use it in a database pod for data persistence.

<details>
<summary>Hints</summary>

- Create the PVC with an appropriate storage class
- Mount the PVC in the pod at the database data directory
- Verify data persists across pod restarts

</details>

<details>
<summary>Solution</summary>

```bash
kubectl apply -f pvc.yaml && kubectl apply -f db-pod.yaml
```

</details>

PVCs provide persistent storage that survives pod lifecycle events.

## q007 — Service Discovery and DNS

> Domain: Services & Networking | Difficulty: Intermediate | Est. time: 16 min

Create multiple services and demonstrate how pods can discover and communicate with each other using DNS.

<details>
<summary>Hints</summary>

- Create ClusterIP services for internal communication
- Use service names for DNS resolution
- Test connectivity from within pods

</details>

<details>
<summary>Solution</summary>

Create services and test DNS resolution between pods.

</details>

Kubernetes DNS enables service discovery using service names as hostnames.

## q008 — Resource Limits and Requests

> Domain: Application Design & Build | Difficulty: Beginner | Est. time: 14 min

Deploy pods with proper resource requests and limits. Observe behavior when limits are exceeded.

<details>
<summary>Hints</summary>

- Set both requests and limits for CPU and memory
- Use stress testing to exceed limits
- Monitor pod resource usage

</details>

<details>
<summary>Solution</summary>

Configure resources in the pod spec and test with a stress workload.

</details>

Resource requests ensure scheduling guarantees while limits prevent resource exhaustion.

## q009 — Health Checks and Probes

> Domain: Observability & Maintenance | Difficulty: Intermediate | Est. time: 22 min

Implement liveness and readiness probes for a web application. Test failure scenarios.

<details>
<summary>Hints</summary>

- Configure HTTP probes for web endpoints
- Set appropriate timeouts and intervals
- Test probe failures and recovery

</details>

<details>
<summary>Solution</summary>

Define probes in the deployment spec with proper configuration.

</details>

Probes ensure pods are healthy and ready to receive traffic.

## q010 — Ingress Controller Setup

> Domain: Services & Networking | Difficulty: Advanced | Est. time: 30 min

Configure an Ingress resource to route traffic to multiple services based on hostnames and paths.

<details>
<summary>Hints</summary>

- Install an ingress controller if needed
- Configure host-based and path-based routing
- Test external access to services

</details>

<details>
<summary>Solution</summary>

Apply an Ingress manifest with routing rules.

</details>

Ingress provides HTTP/HTTPS routing and load balancing for services.

---

## Quick reference

### Pod Management

| Task | Command | Example |
|------|---------|---------|
| Create a pod | `kubectl run nginx --image=nginx` | `kubectl run webapp --image=nginx:1.27 --port=80` |
| Get pods with details | `kubectl get pods -o wide` | `kubectl get pods -n kube-system -o wide` |
| Describe a pod | `kubectl describe pod <pod-name>` | `kubectl describe pod webapp` |
| Get pod logs | `kubectl logs <pod-name>` | `kubectl logs webapp -f --tail=100` |
| Execute command in pod | `kubectl exec -it <pod-name> -- /bin/bash` | `kubectl exec -it webapp -- /bin/sh` |
| Delete a pod | `kubectl delete pod <pod-name>` | `kubectl delete pod webapp` |

### Deployment Management

| Task | Command | Example |
|------|---------|---------|
| Create deployment | `kubectl create deployment nginx --image=nginx --replicas=3` | `kubectl create deployment webapp --image=nginx:1.27 --replicas=5` |
| Scale deployment | `kubectl scale deployment nginx --replicas=5` | `kubectl scale deployment webapp --replicas=10` |
| Update image | `kubectl set image deployment/nginx nginx=nginx:1.27` | `kubectl set image deployment/webapp nginx=nginx:1.28` |
| Check rollout status | `kubectl rollout status deployment/nginx` | `kubectl rollout status deployment/webapp` |
| Rollout history | `kubectl rollout history deployment/nginx` | `kubectl rollout history deployment/webapp --revision=2` |
| Rollback deployment | `kubectl rollout undo deployment/nginx` | `kubectl rollout undo deployment/webapp --to-revision=1` |

### Service Management

| Task | Command | Example |
|------|---------|---------|
| Expose deployment as ClusterIP | `kubectl expose deployment nginx --port=80 --type=ClusterIP` | `kubectl expose deployment webapp --port=80 --target-port=8080` |
| Create NodePort service | `kubectl create service nodeport nginx --tcp=80:80` | `kubectl create service nodeport webapp --tcp=80:8080 --node-port=30080` |
| Get services | `kubectl get services -o wide` | `kubectl get svc -A -o wide` |
| Describe service | `kubectl describe service <service-name>` | `kubectl describe svc webapp` |

### ConfigMap & Secrets

| Task | Command | Example |
|------|---------|---------|
| Create ConfigMap from literals | `kubectl create configmap app-config --from-literal=key=value` | `kubectl create configmap app-config --from-literal=DB_HOST=localhost --from-literal=DB_PORT=5432` |
| Create ConfigMap from file | `kubectl create configmap app-config --from-file=config.properties` | `kubectl create configmap nginx-config --from-file=/etc/nginx/nginx.conf` |
| Create Secret | `kubectl create secret generic db-secret --from-literal=username=admin` | `kubectl create secret generic db-secret --from-literal=username=admin --from-literal=password=secret123` |
| Get ConfigMaps | `kubectl get configmaps` | `kubectl get cm -o yaml` |

### Debugging & Troubleshooting

| Task | Command | Example |
|------|---------|---------|
| Get events | `kubectl get events --sort-by=.metadata.creationTimestamp` | `kubectl get events -n default --sort-by=.metadata.creationTimestamp` |
| Check node status | `kubectl get nodes -o wide` | `kubectl describe node worker-node-1` |
| Port forward | `kubectl port-forward pod/<pod-name> 8080:80` | `kubectl port-forward svc/webapp 8080:80` |
| Get resource usage | `kubectl top pods` | `kubectl top nodes --sort-by=cpu` |

### YAML templates

#### Basic Pod

Simple pod template with a single container.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: webapp
  labels:
    app: webapp
spec:
  containers:
  - name: nginx
    image: nginx:1.27
    ports:
    - containerPort: 80
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "128Mi"
        cpu: "500m"
```

#### Deployment

Basic deployment with rolling update strategy.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
  labels:
    app: webapp
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: nginx
        image: nginx:1.27
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
```

#### Service

ClusterIP service template.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: webapp-service
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
  selector:
    app: webapp
```

#### ConfigMap

ConfigMap with multiple data entries.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  database.host: "postgresql.default.svc.cluster.local"
  database.port: "5432"
  database.name: "myapp"
  config.properties: |
    debug=true
    log.level=info
    cache.enabled=true
```

#### Secret

Secret with base64 encoded values.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
type: Opaque
data:
  username: YWRtaW4=  # admin
  password: cGFzc3dvcmQ=  # password
```

#### Ingress

Ingress with host-based routing.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: webapp-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: webapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: webapp-service
            port:
              number: 80
```

#### PersistentVolumeClaim

PVC for persistent storage.

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: webapp-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: standard
```

#### NetworkPolicy

Network policy for pod-to-pod communication.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: webapp-netpol
spec:
  podSelector:
    matchLabels:
      app: webapp
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 80
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database
    ports:
    - protocol: TCP
      port: 5432
```

---

## Scenario projects

### project1 — Simple Web Application

> Difficulty: Beginner | Duration: 2-3 hours | Technologies: NGINX, ConfigMap, Service

Deploy a basic NGINX web server with custom content using ConfigMaps and expose it via a LoadBalancer service.

**Objectives**

- Create and configure ConfigMaps for web content
- Deploy an NGINX pod with custom configuration
- Expose the application using a LoadBalancer service
- Test external access and connectivity

<details>
<summary>Solution outline</summary>

**Phase: Setup Configuration**

- Create a namespace for the project
- Create a ConfigMap with custom HTML content
- Create a ConfigMap with the NGINX configuration

**Phase: Deploy Application**

- Create an NGINX deployment with ConfigMap mounts
- Configure a service to expose the application
- Test deployment and service connectivity

</details>

### project2 — WordPress + MySQL Stack

> Difficulty: Intermediate | Duration: 4-5 hours | Technologies: WordPress, MySQL, PVC, Secrets

Deploy a complete WordPress application with a MySQL database, persistent storage, and proper secret management.

**Objectives**

- Set up persistent storage for the database
- Configure secrets for database credentials
- Deploy MySQL with a persistent volume
- Deploy WordPress connected to MySQL
- Configure ingress for external access

<details>
<summary>Solution outline</summary>

**Phase: Database Setup**

- Create a PersistentVolumeClaim for MySQL
- Create a Secret for the database credentials
- Deploy MySQL with persistent storage

**Phase: WordPress Deployment**

- Deploy the WordPress application
- Configure WordPress to connect to MySQL
- Set up ingress for external access

</details>

### project3 — Full-Stack E-commerce Platform

> Difficulty: Advanced | Duration: 6-8 hours | Technologies: React, Node.js, PostgreSQL, Redis, Monitoring

Deploy a complete microservices e-commerce platform with a React frontend, Node.js APIs, PostgreSQL database, Redis cache, and a monitoring stack.

**Objectives**

- Deploy a microservices architecture
- Set up persistent database storage
- Configure Redis for caching
- Implement service mesh communication
- Set up monitoring and logging

<details>
<summary>Solution outline</summary>

**Phase: Infrastructure Setup**

- Create a namespace and RBAC
- Deploy PostgreSQL with persistent storage
- Deploy a Redis cluster for caching

**Phase: Application Services**

- Deploy backend API services
- Deploy the React frontend application
- Configure service discovery and communication

**Phase: Monitoring Stack**

- Deploy Prometheus for metrics
- Deploy Grafana for visualization
- Configure alerting rules

</details>

### project4 — Chat Application

> Difficulty: Beginner | Duration: 3-4 hours | Technologies: Node.js, Socket.io, Redis

Build a real-time chat application using Node.js and Socket.io with Redis for message persistence and scaling.

**Objectives**

- Deploy a real-time chat backend
- Configure Redis for message storage
- Set up load balancing for WebSocket connections
- Implement horizontal scaling

<details>
<summary>Solution outline</summary>

**Phase: Backend Setup**

- Deploy the Node.js chat application
- Configure Redis for session storage
- Set up WebSocket load balancing

</details>

### project5 — Monitoring Stack

> Difficulty: Intermediate | Duration: 5-6 hours | Technologies: Prometheus, Grafana, AlertManager

Deploy Prometheus, Grafana, and AlertManager to monitor your Kubernetes cluster and applications with custom dashboards.

**Objectives**

- Deploy Prometheus for metrics collection
- Set up Grafana for visualization
- Configure AlertManager for notifications
- Create custom monitoring dashboards

<details>
<summary>Solution outline</summary>

**Phase: Metrics Collection**

- Deploy the Prometheus server
- Configure service discovery
- Set up node exporters

**Phase: Visualization**

- Deploy Grafana
- Import Kubernetes dashboards
- Create custom application dashboards

</details>

### project6 — Logging & Analytics

> Difficulty: Intermediate | Duration: 6-7 hours | Technologies: Elasticsearch, Logstash, Kibana

Deploy an ELK stack (Elasticsearch, Logstash, Kibana) for centralized logging and log analytics across your applications.

**Objectives**

- Deploy an Elasticsearch cluster
- Configure Logstash for log processing
- Set up Kibana for log visualization
- Implement log forwarding from applications

<details>
<summary>Solution outline</summary>

**Phase: ELK Stack Setup**

- Deploy an Elasticsearch cluster
- Deploy Logstash for processing
- Deploy Kibana for visualization

</details>

### project7 — CI/CD Pipeline with GitOps

> Difficulty: Advanced | Duration: 8-10 hours | Technologies: GitHub Actions, ArgoCD, Helm, Kustomize

Implement a complete CI/CD pipeline using GitHub Actions, ArgoCD, and automated testing for a microservices application.

**Objectives**

- Set up GitHub Actions for CI
- Implement an automated testing pipeline
- Configure ArgoCD for GitOps deployment
- Set up automated rollbacks and monitoring

<details>
<summary>Solution outline</summary>

**Phase: CI Pipeline**

- Configure GitHub Actions workflows
- Set up automated testing
- Implement container image building

**Phase: GitOps Setup**

- Install and configure ArgoCD
- Set up a GitOps repository structure
- Configure automated deployments

</details>

### project8 — Multi-tenant SaaS Platform

> Difficulty: Advanced | Duration: 10-12 hours | Technologies: RBAC, NetworkPolicies, ResourceQuotas, Istio

Build a multi-tenant SaaS application with namespace isolation, RBAC, and resource quotas per tenant.

**Objectives**

- Implement namespace-based tenant isolation
- Configure RBAC for multi-tenancy
- Set up resource quotas per tenant
- Implement network policies for security

<details>
<summary>Solution outline</summary>

**Phase: Tenant Isolation**

- Create a namespace per tenant
- Configure RBAC policies
- Set up resource quotas

**Phase: Security Implementation**

- Configure network policies
- Implement pod security standards
- Set up a service mesh for traffic management

</details>
