#!/bin/bash

#例如每天凌晨 2 点更新一次
#crontab -e && 0 2 * * * /bin/bash UFW_whitelist_for_CF.sh

# Cloudflare 的 IP 地址列表
CLOUDFLARE_IPV4_URL="https://www.cloudflare.com/ips-v4"
CLOUDFLARE_IPV6_URL="https://www.cloudflare.com/ips-v6"

# 定义一个错误退出函数
function error_exit {
    echo "Error: $1"
    exit 1
}

# 获取 Cloudflare IPv4 地址，检测是否成功
ipv4_list=$(curl -s $CLOUDFLARE_IPV4_URL)
if [ $? -ne 0 ] || [ -z "$ipv4_list" ]; then
    error_exit "Failed to fetch Cloudflare IPv4 list."
fi

# 获取 Cloudflare IPv6 地址，检测是否成功
ipv6_list=$(curl -s $CLOUDFLARE_IPV6_URL)
if [ $? -ne 0 ] || [ -z "$ipv6_list" ]; then
    error_exit "Failed to fetch Cloudflare IPv6 list."
fi

# 清除现有的 ufw 规则，只针对 80 和 443 端口
ufw --force reset

# 允许 SSH 连接，确保自己不会被锁住
ufw allow 22/tcp

# 应用 Cloudflare 的 IPv4 规则
for cf_ip in $ipv4_list; do
    ufw allow from $cf_ip to any port 80,443 proto tcp
done

# 应用 Cloudflare 的 IPv6 规则
for cf_ip in $ipv6_list; do
    ufw allow from $cf_ip to any port 80,443 proto tcp
done

# 阻止其他任何来源访问 80 和 443 端口
ufw deny 80/tcp
ufw deny 443/tcp

# 启用 ufw 防火墙
ufw --force enable

echo "Cloudflare IP 白名单已更新并应用成功。"
