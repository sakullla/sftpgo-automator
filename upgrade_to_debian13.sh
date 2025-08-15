#!/bin/bash

# ==============================================================================
# Debian 12 "Bookworm" to Debian 13 "Trixie" 自动升级脚本
#
# 免责声明：请在执行此脚本前务必备份您的重要数据。
# 作者不对因使用此脚本可能导致的任何数据丢失或系统损坏负责。
# ==============================================================================

# --- 设置颜色变量，用于输出提示信息 ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# --- 脚本在遇到任何错误时立即退出 ---
set -e

# --- 检查 Root 权限 ---
if [ "$(id -u)" -ne 0 ]; then
   echo -e "${RED}错误：此脚本需要以 root 权限运行。${NC}"
   echo "请尝试使用 'sudo ./upgrade_to_debian13.sh' 来执行。"
   exit 1
fi

# --- 用户确认 ---
clear
echo -e "${YELLOW}=================================================${NC}"
echo -e "${YELLOW}  Debian 12 'Bookworm' to 13 'Trixie' 升级脚本 ${NC}"
echo -e "${YELLOW}=================================================${NC}"
echo
echo -e "${RED}警告：此脚本将对您的系统进行重大更改。${NC}"
echo "在继续之前，请确保您已完成以下操作："
echo "1. 对所有重要数据进行了【完整备份】。"
echo "2. 当前的 Debian 12 系统已通过 'apt upgrade' 更新到最新。"
echo

read -p "您是否已备份数据并准备好开始升级？(y/N): " confirm
if [[ ! "$confirm" =~ ^[yY](es)?$ ]]; then
    echo "操作已取消。"
    exit 0
fi

echo
echo -e "${GREEN}--- [步骤 1/6] 正在备份当前的软件源文件... ---${NC}"
# 检查目录是否存在
if [ -d "/etc/apt/sources.list.d" ]; then
    cp -R /etc/apt/sources.list.d /etc/apt/sources.list.d.bak
fi
cp /etc/apt/sources.list /etc/apt/sources.list.bak
echo "备份完成，已保存到 .bak 文件。"
sleep 2

echo
echo -e "${GREEN}--- [步骤 2/6] 正在将软件源从 'bookworm' 替换为 'trixie'... ---${NC}"
sed -i 's/bookworm/trixie/g' /etc/apt/sources.list
if [ -d "/etc/apt/sources.list.d" ]; then
    find /etc/apt/sources.list.d/ -type f -name "*.list" -exec sed -i 's/bookworm/trixie/g' {} +
fi
echo "软件源更新完成。"
sleep 2

echo
echo -e "${GREEN}--- [步骤 3/6] 正在更新软件包列表并执行升级... ---${NC}"
echo "这可能需要很长时间，请确保网络和电源稳定。"
echo
echo "--> 正在更新软件包索引 (apt update)..."
apt update

echo
echo "--> 正在执行最小化系统升级 (apt upgrade)..."
apt upgrade --without-new-pkgs -y

echo
echo "--> 正在执行完整系统升级 (apt full-upgrade)..."
apt full-upgrade -y
echo "核心升级过程完成。"
sleep 2

echo
echo -e "${GREEN}--- [步骤 4/6] 正在恢复并重新加载系统配置... ---${NC}"
if [ -f "/etc/sysctl.conf.dpkg-bak" ]; then
    echo "检测到 sysctl.conf 的备份文件，正在恢复..."
    mv /etc/sysctl.conf.dpkg-bak /etc/sysctl.conf
    echo "恢复完成。正在重新加载系统配置 (sysctl -p)..."
    sysctl -p
    echo "系统配置已重新加载。"
else
    echo "未找到 sysctl.conf 的备份文件，跳过此步骤。"
fi
sleep 2

echo
echo -e "${GREEN}--- [步骤 5/6] 正在清理不再需要的软件包... ---${NC}"
apt --purge autoremove -y
apt clean
echo "系统清理完成。"
sleep 2

echo
echo -e "${GREEN}--- [步骤 6/6] 检查升级结果... ---${NC}"
if command -v lsb_release &> /dev/null; then
    VERSION_INFO=$(lsb_release -a)
    echo "当前系统版本信息："
    echo "$VERSION_INFO"
    if echo "$VERSION_INFO" | grep -q "trixie"; then
        echo -e "${GREEN}恭喜！您的系统已成功升级到 Debian 13 'Trixie'。${NC}"
    else
        echo -e "${YELLOW}警告：系统版本似乎未正确更新，请手动检查。${NC}"
    fi
else
    echo "lsb_release 命令不可用，请手动检查 /etc/debian_version 文件。"
    cat /etc/debian_version
fi


echo
echo -e "${YELLOW}=================================================${NC}"
echo -e "${YELLOW}  所有步骤已完成！                       ${NC}"
echo -e "${YELLOW}=================================================${NC}"
echo
echo "为了应用新的内核和所有系统更新，强烈建议您现在重启计算机。"
echo "请手动运行以下命令来重启："
echo -e "${GREEN}sudo reboot${NC}"

exit 0
