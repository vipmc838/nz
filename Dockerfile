# ==========================
# 构建阶段：拉取哪吒面板
# ==========================
FROM ghcr.io/nezhahq/nezha AS app

# ==========================
# 运行阶段：Nginx + 工具环境
# ==========================
FROM nginx:alpine

# 安装依赖
RUN apk add --no-cache \
    wget \
    unzip \
    bash \
    curl \
    git \
    tar \
    openssl \
    jq \
    procps \
    tzdata \
    zip \
    sqlite \
    sqlite-libs

# 复制 cloudflared
COPY --from=cloudflare/cloudflared:latest /usr/local/bin/cloudflared /usr/local/bin/cloudflared

# 复制 SSL 证书（避免证书问题）
COPY --from=app /etc/ssl/certs /etc/ssl/certs

# Nginx 配置
COPY main.conf /etc/nginx/conf.d/main.conf
RUN rm -f /etc/nginx/conf.d/default.conf
COPY ssl.conf.template /etc/nginx/ssl.conf.template

# 时区
ENV TZ=Asia/Shanghai

# 工作目录
WORKDIR /dashboard

# 复制哪吒面板 app
COPY --from=app /dashboard/app /dashboard/app

# 数据目录并设置权限
RUN mkdir -p /dashboard/data && chmod -R 777 /dashboard

# 暴露端口
EXPOSE 8008

# 环境变量
ENV ARGO_DOMAIN="" \
    ARGO_AUTH="" \
    GITHUB_TOKEN="" \
    GITHUB_REPO_OWNER="" \
    GITHUB_REPO_NAME="" \
    GITHUB_BRANCH="" \
    ZIP_PASSWORD="" \
    NZ_CLIENT_SECRET="" \
    NZ_UUID="" \
    NZ_TLS="" \
    DASHBOARD_VERSION="" 

# 复制脚本和静态文件
COPY restore.sh /restore.sh
COPY backup.sh /backup.sh
COPY entrypoint.sh /entrypoint.sh
COPY index.html /usr/share/nginx/html/index.html

# 设置可执行权限
RUN chmod +x /restore.sh /backup.sh /entrypoint.sh

# 启动脚本
CMD ["/entrypoint.sh"]
