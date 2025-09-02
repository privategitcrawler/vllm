# =================================================================================
# Dockerfile for a generic, production-ready vLLM OpenAI-compatible server
# =================================================================================

# --- 阶段 1: 基础环境 ---
# 使用NVIDIA官方的CUDA镜像，确保环境纯净且驱动兼容。
# 我们选择基于Ubuntu 22.04的CUDA 12.1.1开发版，它包含了编译工具。
FROM nvidia/cuda:12.1.1-devel-ubuntu22.04

# --- 阶段 2: 安装系统依赖 ---
# 设置环境变量，防止安装过程中出现交互式弹窗，并设置时区。
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# 更新包列表，并安装Python 3.10、pip及git。
# --no-install-recommends可以减少不必要的软件包，保持镜像小巧。
# 最后清理apt缓存，减小镜像体积。
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python3.10 \
    python3-pip \
    git \
    && rm -rf /var/lib/apt/lists/*

# --- 阶段 3: 安装Python依赖 ---
# 为vLLM创建一个专用的工作目录。
WORKDIR /vllm-workspace

# 升级pip并安装vLLM。我们固定版本号以确保部署的一致性和可复现性。
# transformers是vLLM的常用依赖，建议显式安装。
RUN pip3 install --no-cache-dir --upgrade pip && \
    pip3 install --no-cache-dir \
    vllm==0.5.1 \
    transformers==4.41.2

# --- 阶段 4: 配置容器 ---
# 声明服务将监听8000端口。这主要用于文档和自动化工具。
EXPOSE 8000

# 设置默认启动命令。
# 这个命令将在容器启动时执行，除非被Kubernetes的args覆盖。
# --host 0.0.0.0 是必须的，以允许从容器外部访问服务。
CMD [ \
    "python3", \
    "-m", \
    "vllm.entrypoints.openai.api_server", \
    "--host", "0.0.0.0", \
    "--port", "8000" \
]
