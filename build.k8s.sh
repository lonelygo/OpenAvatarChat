#!/usr/bin/env bash

# This script builds the application image for Kubernetes deployment.
# It uses Dockerfile.k8s and tags the image to be available for a local K8s cluster
# that uses containerd (like k3s, etc.), leveraging the k8s.io namespace.

# --- Configuration ---
# The name and tag for the final image.
# This MUST match the image name used in the oac-k8s-musetalk-deployment.yaml file.
IMAGE_NAME="open-avatar-chat-musetalk:v1"

# The K8s namespace for containerd images. This is standard for many local K8s distributions.
K8S_NAMESPACE="k8s.io"

# The configuration file to use for installing Python dependencies inside the Docker build.
# This should match the handlers you intend to run.
CONFIG_PATH="config/chat_with_mubing_cosyvoice_musetalk.yaml"

# --- Build Command ---

echo "Building K8s image: ${IMAGE_NAME} using ${CONFIG_PATH}"
echo "This command requires sudo for nerdctl."

# 【修改点】在nerdctl命令前添加sudo
sudo nerdctl --namespace ${K8S_NAMESPACE} build \
    --build-arg CONFIG_FILE=${CONFIG_PATH}  \
    -t ${IMAGE_NAME} \
    -f Dockerfile.k8s \
    .

EXIT_CODE=$?

if [ ${EXIT_CODE} -eq 0 ]; then
    echo ""
    echo "Build successful!"
    echo "Image '${IMAGE_NAME}' is now available in the '${K8S_NAMESPACE}' namespace."
    echo "You can now proceed with deploying the application to Kubernetes."
else
    echo ""
    echo "Build failed with exit code ${EXIT_CODE}."
fi