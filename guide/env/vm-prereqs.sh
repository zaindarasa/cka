#!/usr/bin/env bash
# Run as root on each of cp1, w1, w2 (Ubuntu LTS). Unverified until step 5.
#
# Optional version pinning (for the 1.36.x -> 1.37.1 upgrade lab, T4.04):
#   K8S_MINOR=1.36 K8S_PATCH='1.36.5-*' bash vm-prereqs.sh   # held at v1.36.5
#   bash vm-prereqs.sh                                       # latest v1.37 (default)
# K8S_MINOR picks the pkgs.k8s.io repo (stable:/v<minor>/deb). K8S_PATCH is an apt
# version glob; '1.36.5-*' matches the revision suffix (e.g. 1.36.5-1.1, see
# `apt-cache madison kubeadm`). If K8S_PATCH is set, K8S_MINOR must match it.
#
# This script only prepares a node. It does NOT run `kubeadm init`/`kubeadm join`
# and does NOT install a CNI - those steps are lesson T4.02.
set -euo pipefail
K8S_MINOR=${K8S_MINOR:-1.37}
K8S_PATCH=${K8S_PATCH:-}
swapoff -a && sed -i '/ swap / s/^/#/' /etc/fstab
printf 'overlay\nbr_netfilter\n' > /etc/modules-load.d/k8s.conf && modprobe overlay br_netfilter
cat > /etc/sysctl.d/k8s.conf <<EOT
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
EOT
sysctl --system >/dev/null
apt-get update && apt-get install -y apt-transport-https ca-certificates curl gpg containerd
mkdir -p /etc/containerd && containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl enable --now containerd && systemctl restart containerd
mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL "https://pkgs.k8s.io/core:/stable:/v${K8S_MINOR}/deb/Release.key" | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${K8S_MINOR}/deb/ /" > /etc/apt/sources.list.d/kubernetes.list
if [[ -n $K8S_PATCH ]]; then
  apt-get update && apt-get install -y kubelet="$K8S_PATCH" kubeadm="$K8S_PATCH" kubectl="$K8S_PATCH"
else
  apt-get update && apt-get install -y kubelet kubeadm kubectl
fi
apt-mark hold kubelet kubeadm kubectl
systemctl enable --now kubelet
