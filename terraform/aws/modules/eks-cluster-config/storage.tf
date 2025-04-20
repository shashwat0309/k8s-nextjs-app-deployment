################################################################################
# Storage Classes
################################################################################

resource "kubectl_manifest" "storage_default" {
  yaml_body = <<-YAML
    apiVersion: storage.k8s.io/v1
    kind: StorageClass
    metadata:
      annotations:
        storageclass.kubernetes.io/is-default-class: "true"
      name: default
    parameters:
      fsType: ext4
      type: gp3
    provisioner: ebs.csi.aws.com
    allowVolumeExpansion: true
    volumeBindingMode: Immediate
    reclaimPolicy: Delete
  YAML
}

resource "kubectl_manifest" "storage_del_ext4" {
  yaml_body = <<-YAML
    apiVersion: storage.k8s.io/v1
    kind: StorageClass
    metadata:
      annotations:
        storageclass.kubernetes.io/is-default-class: "false"
      name: resizable-delete-ext4
    parameters:
      fsType: ext4
      type: gp3
    provisioner: kubernetes.io/aws-ebs
    allowVolumeExpansion: true
    volumeBindingMode: Immediate
    reclaimPolicy: Delete
  YAML
}

resource "kubectl_manifest" "storage_ret_ext4" {
  yaml_body = <<-YAML
    apiVersion: storage.k8s.io/v1
    kind: StorageClass
    metadata:
      annotations:
        storageclass.kubernetes.io/is-default-class: "false"
      name: resizable-retain-ext4
    parameters:
      fsType: ext4
      type: gp3
    provisioner: kubernetes.io/aws-ebs
    allowVolumeExpansion: true
    volumeBindingMode: Immediate
    reclaimPolicy: Retain
  YAML
}
