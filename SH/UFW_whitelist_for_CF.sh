#!/bin/bash

#例如每天凌晨 2 点更新一次
#crontab -e && 0 2 * * * /bin/bash UFW_whitelist_for_CF.sh

# Cloudflare 的 IP 地址列表
CLOUDFLARE_IPV4_URL="https://www.cloudflare.com/ips-v4"
CLOUDFLARE_IPV6_URL="https://www.cloudflare.com/ips-v6"

# 清除现有 ufw 规则，只针对 80 和 443 端口
ufw --force reset

# 允许 SSH 连接（确保自己不会被锁在外面，假设 SSH 端口是 22）
ufw allow 22/tcp

# 获取并应用 Cloudflare 的 IPv4 规则
for cf_ip in $(curl -s $CLOUDFLARE_IPV4_URL); do
    ufw allow from $cf_ip to any port 80,443 proto tcp
done

# 获取并应用 Cloudflare 的 IPv6 规则
for cf_ip in $(curl -s $CLOUDFLARE_IPV6_URL); do
    ufw allow from $cf_ip to any port 80,443 proto tcp
done

# 阻止所有其他来源访问 80 和 443 端口
ufw deny 80/tcp
ufw deny 443/tcp

# 启用 ufw 防火墙
ufw --force enable
