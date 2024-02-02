## Intro

This is a practical work on the following course https://practicum.yandex.ru/profile/ycloud-deploy/

## Infrastructure

### ya.cloud environment creation

Yandex.Cloud is deployed using terraform. So the following prerequisites are required

- terraform and ya.cloud provider
- jq
- yc


```
./install.sh apply dev
```

## Kubernetes preparations

### kubeconfig generating

```
yc managed-kubernetes cluster get-credentials --name=main --external
```

### ya.alb deployment

This operator manages yandex cloud ALB from Kubernetes

```
yc iam key create --service-account-name ingress-controller --output sa-key.json

export HELM_EXPERIMENTAL_OCI=1
cat sa-key.json | helm registry login cr.yandex --username 'json_key' --password-stdin

export FOLDER_ID=$(yc config get folder-id)
export CLUSTER_ID=$(yc managed-kubernetes cluster get main | head -n 1 | awk -F ': ' '{print $2}')

helm install \
--create-namespace \
--namespace yc-alb \
--set folderId=$FOLDER_ID \
--set clusterId=$CLUSTER_ID \
--set-file saKeySecretKey=sa-key.json \
yc-alb \
oci://cr.yandex/yc-marketplace/yandex-cloud/yc-alb-ingress/yc-alb-ingress-controller-chart \
--version v0.1.17

rm -rf sa-key.json
```

## gitlab

Gitlab is installed inside of the same kubernetes cluster. Such installation requires a little bit more resources.

```
helm repo add gitlab https://charts.gitlab.io/
helm install gitlab gitlab/gitlab \
  -n gitlab \
  --create-namespace \
  --set global.edition=ce \
  --set global.hosts.domain=gitlab.qamo.ru \
  --set certmanager-issuer.email=qamo@example.com \
  --set prometheus.install=false \
  --set global.ingress.enabled=true \
  --set certmanager.install.enabled=false \
  --set gitlab-runner.gitlabUrl=http://gitlab-webservice-default.gitlab:8080 
```

Pay your attention the installation creates NLB and disks for PV/PVCs.


## demo httpbin deployment

Deploy the following manifests and check that ALB has created. Then add DNS or /etc/hosts entry to check the application deployed.

<details> 
  <summary>Namespace, Service and Deployment </summary>

```yaml
apiVersion: v1    
kind: Namespace                
metadata:
  name: httpbin 
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpbin
  labels:
    app: httpbin
spec:
  replicas: 1
  selector:
    matchLabels:
      app: httpbin
  template:
    metadata:
      labels:
        app: httpbin
    spec:
      containers:
        - name: httpbin
          image: kong/httpbin:latest
          ports:
            - name: http
              containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: httpbin
spec:
  type: NodePort
  selector:
    app: httpbin
  ports:
    - name: http
      port: 80
      targetPort: 80
      protocol: TCP
      nodePort: 30081
```
</details>

<details> 
  <summary>ingress </summary>

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: httpbin
  annotations:
    ingress.alb.yc.io/subnets: <id подсети>
    ingress.alb.yc.io/external-ipv4-address: <ip адрес балансировщика>
    ingress.alb.yc.io/group-name: infra-ingress
    ingress.alb.yc.io/security-groups: <id группы безопасности>
spec:
  rules:
    - host: httpbin.infra.<домен>
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: httpbin
                port:
                  number: 80

```
</details>

## ArgoCD

```
export HELM_EXPERIMENTAL_OCI=1 && \
cat <<EOF >values.yaml
configs:
  repositories:
    infra:
      password: glpat-GyP-RZgFRhQEY_DLWmyN
      project: default
      type: git
      url: http://gitlab-webservice-default.gitlab:8080/yc-courses/infra.git
      username: gitlab-ci-token 
EOF

helm upgrade -n argocd \
  --install \
  --create-namespace \
  argocd \
  oci://cr.yandex/yc-marketplace/yandex-cloud/argo/chart/argo-cd \
  --version=5.46.8-6 \
  --values values.yaml
```