FROM docker.1ms.run/nvidia/cuda:12.2.2-cudnn8-devel-ubuntu22.04
LABEL authors="HumanAIGC-Engineering"

ARG CONFIG_FILE=config/chat_with_minicpm.yaml

ENV DEBIAN_FRONTEND=noninteractive
ENV http_proxy="http://172.16.40.42:7890"
ENV https_proxy="http://172.16.40.42:7890"
ENV HTTP_PROXY="http://172.16.40.42:7890"
ENV HTTPS_PROXY="http://172.16.40.42:7890"

# Use Tsinghua University APT mirrors
RUN sed -i 's/archive.ubuntu.com/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list && \
    sed -i 's/security.ubuntu.com/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list

# Update package list and install required dependencies
RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
    apt-get install -y python3.11 python3.11-dev python3.11-venv python3.11-distutils python3-pip git libgl1 libglib2.0-0

RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1 && \
    python3.11 -m ensurepip --upgrade && \
    python3.11 -m pip install --upgrade pip

ARG WORK_DIR=/root/open-avatar-chat
WORKDIR $WORK_DIR

# Install core dependencies
COPY ./install.py $WORK_DIR/install.py
COPY ./pyproject.toml $WORK_DIR/pyproject.toml
COPY ./src/third_party $WORK_DIR/src/third_party
RUN pip install uv && \
    uv venv --python 3.11.11 && \
    uv sync --no-install-workspace

# 装ffpeg
RUN apt-get update && \
    apt-get install -y ffmpeg

ADD ./src $WORK_DIR/src

# Copy script files (must be copied before installing config dependencies)
ADD ./scripts $WORK_DIR/scripts

# Execute pre-config installation script
RUN echo "Using config file: ${CONFIG_FILE}"
COPY $CONFIG_FILE /tmp/build_config.yaml
RUN chmod +x $WORK_DIR/scripts/pre_config_install.sh && \
    $WORK_DIR/scripts/pre_config_install.sh --config /tmp/build_config.yaml

# Install config dependencies
RUN uv run install.py \
    --config /tmp/build_config.yaml \
    --uv \
    --skip-core

# uv默认安装的mmcv在实际运行时可能会报错“No module named ‘mmcv._ext’”参考MMCV-FAQ，解决方法是
# https://github.com/HumanAIGC-Engineering/OpenAvatarChat/blob/main/README.md#musetalk%E6%95%B0%E5%AD%97%E4%BA%BAhandler
RUN uv pip uninstall mmcv
RUN uv pip install mmcv==2.2.0 -f https://download.openmmlab.com/mmcv/dist/cu121/torch2.4/index.html --trusted-host download.openmmlab.com

# Execute post-config installation script
RUN chmod +x $WORK_DIR/scripts/post_config_install.sh && \
    $WORK_DIR/scripts/post_config_install.sh --config /tmp/build_config.yaml && \
    rm /tmp/build_config.yaml

ADD ./resource $WORK_DIR/resource
ADD ./.env* $WORK_DIR/

ENV http_proxy=""
ENV https_proxy=""
ENV HTTP_PROXY=""
ENV HTTPS_PROXY=""

WORKDIR $WORK_DIR
ENTRYPOINT ["uv", "run", "src/demo.py"]
