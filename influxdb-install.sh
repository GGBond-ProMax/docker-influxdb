#!/bin/bash

# 设置InfluxDB版本
INFLUXDB_VERSION="2.7.1"  # 你可以更改为想要的版本

# 设置InfluxDB容器名称
INFLUXDB_CONTAINER_NAME="influxdb-server"

# 设置挂载目录
INFLUXDB_BASE_DIR="/influxdb"  # 基本目录
INFLUXDB_DATA_DIR="$INFLUXDB_BASE_DIR/data"     # 数据存储目录
INFLUXDB_CONFIG_DIR="$INFLUXDB_BASE_DIR/config" # 配置文件目录
INFLUXDB_BACKUP_DIR="$INFLUXDB_BASE_DIR/backup" # 备份目录

# 设置InfluxDB暴露端口
INFLUXDB_HTTP_PORT="8086"

# 检查Docker是否安装
if ! [ -x "$(command -v docker)" ]; then
  echo "Error: Docker is not installed." >&2
  exit 1
fi

# 创建InfluxDB本地挂载目录
echo "创建InfluxDB数据、配置和备份目录..."
sudo mkdir -p $INFLUXDB_DATA_DIR $INFLUXDB_CONFIG_DIR $INFLUXDB_BACKUP_DIR

# 设置目录权限
sudo chmod -R 777 $INFLUXDB_BASE_DIR

# 拉取InfluxDB镜像
echo "拉取InfluxDB版本 $INFLUXDB_VERSION 的镜像..."
docker pull influxdb:$INFLUXDB_VERSION

# 检查是否有运行中的同名容器
if [ $(docker ps -q -f name=$INFLUXDB_CONTAINER_NAME) ]; then
    echo "旧的InfluxDB容器正在运行，停止并删除..."
    docker stop $INFLUXDB_CONTAINER_NAME
    docker rm $INFLUXDB_CONTAINER_NAME
fi

# 启动InfluxDB容器
echo "启动InfluxDB容器..."
docker run -d --name $INFLUXDB_CONTAINER_NAME \
  -p $INFLUXDB_HTTP_PORT:8086 \
  -v $INFLUXDB_DATA_DIR:/var/lib/influxdb2 \
  -v $INFLUXDB_CONFIG_DIR:/etc/influxdb2 \
  -v $INFLUXDB_BACKUP_DIR:/var/lib/influxdb2-backup \
  --restart=always \
  influxdb:$INFLUXDB_VERSION

# 检查InfluxDB是否启动成功
if [ $(docker ps -q -f name=$INFLUXDB_CONTAINER_NAME) ]; then
    echo "InfluxDB已成功启动，访问地址为 http://localhost:$INFLUXDB_HTTP_PORT"
else
    echo "InfluxDB启动失败，请检查日志。"
    exit 1
fi
