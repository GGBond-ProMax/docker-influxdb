#!/bin/bash

# 设置InfluxDB版本（要升级到的版本）
NEW_INFLUXDB_VERSION="2.7.1"  # 可以更改为要升级的版本

# 设置InfluxDB容器名称
INFLUXDB_CONTAINER_NAME="influxdb-server"

# 设置挂载目录
INFLUXDB_BASE_DIR="/influxdb"  # 基本目录
INFLUXDB_DATA_DIR="$INFLUXDB_BASE_DIR/data"     # 数据存储目录
INFLUXDB_CONFIG_DIR="$INFLUXDB_BASE_DIR/config" # 配置文件目录
INFLUXDB_BACKUP_DIR="$INFLUXDB_BASE_DIR/backup" # 挂载的备份目录

# 设置数据备份目录
INFLUXDB_DATA_BACKUP_DIR="$INFLUXDB_BASE_DIR/influxdb_data"

# 设置InfluxDB暴露端口
INFLUXDB_HTTP_PORT="8086"

# 获取当前时间戳，用于备份目录
BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$INFLUXDB_DATA_BACKUP_DIR/backup_$BACKUP_TIMESTAMP"

# 检查Docker是否安装
if ! [ -x "$(command -v docker)" ]; then
  echo "Error: Docker is not installed." >&2
  exit 1
fi

# 备份InfluxDB数据和配置文件
backup_influxdb() {
  echo "开始备份InfluxDB数据和配置文件..."

  # 创建数据备份目录
  echo "创建数据备份目录 $BACKUP_DIR..."
  sudo mkdir -p $BACKUP_DIR
  sudo chmod -R 777 $BACKUP_DIR

  # 检查是否有运行中的InfluxDB容器并停止
  if [ $(docker ps -q -f name=$INFLUXDB_CONTAINER_NAME) ]; then
    echo "停止运行中的InfluxDB容器..."
    docker stop $INFLUXDB_CONTAINER_NAME
  else
    echo "没有发现运行中的InfluxDB容器。"
  fi

  # 备份数据和配置文件到 /influxdb/influxdb_data
  echo "备份数据到 $BACKUP_DIR..."
  sudo cp -r $INFLUXDB_DATA_DIR $BACKUP_DIR/data
  sudo cp -r $INFLUXDB_CONFIG_DIR $BACKUP_DIR/config

  echo "InfluxDB数据和配置文件备份完成。"
}

# 升级InfluxDB
upgrade_influxdb() {
  echo "开始升级InfluxDB到版本 $NEW_INFLUXDB_VERSION..."

  # 删除旧的容器
  echo "删除旧的InfluxDB容器..."
  docker rm -f $INFLUXDB_CONTAINER_NAME

  # 拉取新的InfluxDB镜像
  echo "拉取InfluxDB版本 $NEW_INFLUXDB_VERSION 的镜像..."
  docker pull influxdb:$NEW_INFLUXDB_VERSION

  # 启动新的InfluxDB容器
  echo "启动新的InfluxDB容器..."
  docker run -d --name $INFLUXDB_CONTAINER_NAME \
    -p $INFLUXDB_HTTP_PORT:8086 \
    -v $INFLUXDB_DATA_DIR:/var/lib/influxdb2 \
    -v $INFLUXDB_CONFIG_DIR:/etc/influxdb2 \
    -v $INFLUXDB_BACKUP_DIR:/var/lib/influxdb2-backup \
    --restart=always \
    influxdb:$NEW_INFLUXDB_VERSION

  # 检查InfluxDB是否启动成功
  if [ $(docker ps -q -f name=$INFLUXDB_CONTAINER_NAME) ]; then
    echo "InfluxDB版本 $NEW_INFLUXDB_VERSION 已成功启动，访问地址为 http://localhost:$INFLUXDB_HTTP_PORT"
  else
    echo "InfluxDB启动失败，请检查日志。"
    exit 1
  fi
}

# 用户操作选择
echo "请选择要执行的操作："
echo "1) 备份InfluxDB"
echo "2) 升级InfluxDB"
read -p "输入选项 (1 或 2): " user_choice

if [ "$user_choice" == "1" ]; then
  backup_influxdb
elif [ "$user_choice" == "2" ]; then
  upgrade_influxdb
else
  echo "无效的选项，脚本退出。"
  exit 1
fi
