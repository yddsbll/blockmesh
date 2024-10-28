#!/bin/bash


function main_start() {

   while true; do
    # 菜单
     echo "脚本由yddsbll编写，推特 @yddsbll"
     echo "选择操作:"
     echo "1)安装节点"
     echo "2)查看日志"
     echo "3)删除节点"
     echo "4)退出"
     read -rp "请输入操作选项：" choice
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
    done
}


function install_before() {

    # 检查bc
    echo "正在检查您的操作系统版本..."
    if ! command -v bc &> /dev/null; then
        sudo apt update
        sudo apt install bc -y
    fi
    sleep 1

    # 检查linux Ubuntu系统版本
    UBUNTU_VERSION=$(lsb_release -rs)
    REQUIRED_VERSION=22.04

    if (( $(echo "$UBUNTU_VERSION < $REQUIRED_VERSION" | bc -l) )); then
        echo "此节点需要最低版本的 Ubuntu 22.04"
        exit 1
    fi

    
}

# 安装节点函数
function install_node() {
    #安装之前检查
     install_before
     echo "安装 BlockMesh 节点"
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
        read -rp "请输入邮箱号:  " USER_EMAIL
        read -rp "请输入密码:  " USER_PASSWORD

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
        sleep 1
        sudo systemctl enable blockmesh.service
        sudo systemctl start blockmesh.service
        echo "安装完成并且节点正在运行中！"
        read -rp "按 Enter 返回菜单。"
}

function remove_node() {
     echo "正在删除节点"
        # 删除服务文件并更新服务
        sudo systemctl stop blockmesh.service
        sudo systemctl disable blockmesh.service
        sudo rm /etc/systemd/system/blockmesh.service
        sudo systemctl daemon-reload
        sleep 1
        # 删除二进制文件
        rm -rf target
        echo "删除成功!"
        read -rp "按 Enter 返回菜单。"
}

function cat_logs() {
    sudo journalctl -u blockmesh.service -f
    echo "按 Ctrl+C 退出日志查看。"
}

# 主程序开始
main_start