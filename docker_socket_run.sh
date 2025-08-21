#!/usr/bin/env bash
CONFIG_PATH=""
SOCKET_DIR="/tmp/sockets"

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -config | --config )
            CONFIG_PATH="$2"
            shift 2
            ;;
    esac
done

echo "${CONFIG_PATH}"

sudo docker run --rm --runtime=nvidia --gpus '"device=0"' -it --name open-avatar-chat \
    -v `pwd`/build:/root/open-avatar-chat/build \
    -v `pwd`/models:/root/open-avatar-chat/models \
    -v `pwd`/ssl_certs:/root/open-avatar-chat/ssl_certs \
    -v `pwd`/config:/root/open-avatar-chat/config \
    -v `pwd`/models/musetalk/s3fd-619a316812/:/root/.cache/torch/hub/checkpoints/ \
    -v ${SOCKET_DIR}:${SOCKET_DIR} \
    -p 8282:8282 \
    open-avatar-chat:0.0.1 \
    --config "config/chat_with_socket_cosyvoice_musetalk.yaml"