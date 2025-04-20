resource "kubectl_manifest" "role_developers" {
  yaml_body = <<-YAML
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRole
    metadata:
      name: read-only
      annotations:
        rbac.authorization.kubernetes.io/autoupdate: "true"
    rules:
    - apiGroups: [""]
      resources: ["pods/exec", "pods/portforward", "pods/attach"]
      verbs: ["get", "create"]
    - apiGroups: [""]
      resources: ["pods/log"]
      verbs: ["get"]
    - apiGroups: [""]
      resources: ["pods"]
      verbs: ["get", "list", "watch", "patch", "delete"]
    - apiGroups: ["batch"]
      resources: ["jobs"]
      verbs: ["get", "list", "watch", "patch", "delete"]
    - apiGroups: ["apps"]
      resources: ["deployments", "replicasets"]
      verbs: ["get", "list", "watch", "patch"]
    - apiGroups: ["*"]
      resources: ["*"]
      verbs: ["get", "watch", "list"]
    - nonResourceURLs: ["*"]
      verbs: ["get", "watch", "list"]
  YAML
}

resource "kubectl_manifest" "role_binding_developers" {
  yaml_body = <<-YAML
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      annotations:
        rbac.authorization.kubernetes.io/autoupdate: "true"
      name: aws-developers-access
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: read-only
    subjects:
      - apiGroup: rbac.authorization.k8s.io
        kind: Group
        name: nextapp-dev
  YAML
}

resource "kubectl_manifest" "role_binding_devops" {
  yaml_body = <<-YAML
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      annotations:
        rbac.authorization.kubernetes.io/autoupdate: "true"
      name: aws-devops-access
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: cluster-admin
    subjects:
      - apiGroup: rbac.authorization.k8s.io
        kind: Group
        name: nextapp-devops
  YAML
}
