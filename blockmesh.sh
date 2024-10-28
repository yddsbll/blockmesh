#!/bin/bash

# 文字颜色
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NONEC='\033[0m'

# 检查是否有curl，如果没有安装则安装
#if ! command -v curl &> /dev/null; then
#    sudo apt update
#    sudo apt install curl -y
#fi
#sleep 2


# 检查bc
#echo -e "${BLUE}正在检查您的操作系统版本...${NONEC}"
#if ! command -v bc &> /dev/null; then
#    sudo apt update
#    sudo apt install bc -y
#fi
#sleep 1
#
## 检查linux Ubuntu系统版本
#UBUNTU_VERSION=$(lsb_release -rs)
#REQUIRED_VERSION=22.04
#
#
#if (( $(echo "UBUNTU_VERSION < $REQUIRED_VERSION" | bc -l) )); then
#    echo -e "${RED}此节点需要最低版本的 Ubuntu 22.04 ${NONEC}"
#    exit 1
#fi


function main_start() {
    # 菜单
     echo -e "${YELLOW}选择操作:${NONEC}"
     echo -e "${BLUE}1)安装节点${NONEC}"
     echo -e "${BLUE}2)查看日志${NONEC}"
     echo -e "${RED}3)删除节点${NONEC}"
     echo -e "${BLUE}4)退出${NONEC}"

     read choice
    
      case $choice in
          1)
              install_node
              ;;
          2)
              # 查看日志
              cat_logs
              ;;
          3)
              remove_node
              ;;
          4)
              exit 0
              ;;
      esac
}


function install_before() {
      # 检查是否有curl，如果没有安装则安装
      if ! command -v curl &> /dev/null; then
          sudo apt update
          sudo apt install curl -y
      fi
      sleep 1
      # 检查bc
      echo -e "${BLUE}正在检查您的操作系统版本...${NONEC}"
      if ! command -v bc &> /dev/null; then
          sudo apt update
          sudo apt install bc -y
      fi
      sleep 1

      # 检查linux Ubuntu系统版本
      UBUNTU_VERSION=$(lsb_release -rs)
      REQUIRED_VERSION=22.04


      if (( $(echo "UBUNTU_VERSION < $REQUIRED_VERSION" | bc -l) )); then
          echo -e "${RED}此节点需要最低版本的 Ubuntu 22.04 ${NONEC}"
          exit 1
      fi

    
}

# 安装节点函数
function install_node() {
    #安装之前检查
     install_before
     echo -e "${BLUE}安装 BlockMesh 节点${NONEC}"
        # 检查是否有tar命令
        if ! command -v tar &> /dev/null; then
            sudo apt install tar -y
        fi
        sleep 1

        # 下载 BlockMesh 二进制文件
        wget https://github.com/block-mesh/block-mesh-monorepo/releases/download/v0.0.316/blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz
        # 解压文件
        tar -xzvf blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz
        sleep 1

        # 删除压缩文件
        rm blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz

        # 进入目录
        cd target/release

        # 输入登陆数据数据
        echo -e "${BLUE}输入邮箱号:${NONEC}"
        read USER_EMAIL

        echo -e "${BLUE}输入密码(密码不明文显示):${NONEC}"
        read -s USER_PASSWORD

        # 获取用户名称及其主目录
        USERNAME=$(whoami)

        if [ "$USERNAME" == "root" ]; then
            HOME_DIR="/root"
        else
            HOME_DIR="/home/$USERNAME"
        fi
        # 使用当前用户的用户名和主目录创建或更新服务文件
        sudo bash -c "cat <<EOT > /etc/systemd/system/blockmesh.service
[Unit]
Description=BlockMesh CLI Service
After=network.target

[Service]
User=$USERNAME
ExecStart=$HOME_DIR/target/release/blockmesh-cli login --email $USER_EMAIL --password $USER_PASSWORD
WorkingDirectory=$HOME_DIR/target/release
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOT"
        # 更新服务并启用
        sudo systemctl daemon-reload
        sleep 2
        sudo systemctl enable blockmesh.service
        sudo systemctl start blockmesh.service
        echo -e "${BLUE}安装完成并且节点正在运行中！${NONEC}"
        read -rp "按 Enter 返回菜单。"
}

function remove_node() {
     echo -e "${RED}正在删除节点${NONEC}"
        # 删除服务文件并更新服务
        sudo systemctl stop blockmesh.service
        sudo systemctl disable blockmesh.service
        sudo rm /etc/systemd/system/blockmesh.service
        sudo systemctl daemon-reload
        sleep 2
        # 删除二进制文件
        rm -rf target
        echo -e "${RED}删除成功!${NONEC}"
        read -rp "按 Enter 返回菜单。"
}

function cat_logs() {
    sudo journalctl -u blockmesh.service -f
    echo "按 Ctrl+C 退出日志查看。"
}

# 主程序开始
main_start