# 基于官方镜像
FROM yandex/clickhouse-server:latest

# 安装中文语言包（解决日志/数据中文乱码）
RUN apt-get update && apt-get install -y locales && \
    locale-gen zh_CN.UTF-8 && \
    echo "LANG=zh_CN.UTF-8" > /etc/default/locale

# 复制自定义配置（如需）
COPY ./config/custom.xml /etc/clickhouse-server/config.d/

# 暴露端口（和compose一致）
EXPOSE 8123 9000 9009

# 启动ClickHouse
CMD ["clickhouse-server", "--config-file=/etc/clickhouse-server/config.xml"]