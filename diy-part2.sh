#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# Modify default IP
# sed -i 's/192.168.1.1/192.168.11.1/g' package/base-files/luci2/bin/config_generate

sed -i '/config_get channel "$device" channel/a \	[ -z "$channel" ] && channel="auto"' package/kernel/mac80211/files/lib/wifi/mac80211.sh

# 修改默认 IP
sed -i 's/192.168.1.1/192.168.12.1/g' package/base-files/files/bin/config_generate

# 处理 DHCP 配置注入
DHCP_CONF="package/base-files/files/etc/config/dhcp"
mkdir -p $(dirname $DHCP_CONF)

# 如果文件不存在，先创建一个基础模板
if [ ! -f "$DHCP_CONF" ]; then
cat << 'EOF' > "$DHCP_CONF"
config dnsmasq
	option domainneeded	1
	option boguspriv	1
	option filterwin2k	0  # enable for dial on demand
	option localise_queries	1
	option rebind_protection 1  # disable if upstream must serve RFC1918 addresses
	option rebind_localhost 1  # enable for RBL checking and similar services
	#list rebind_domain example.lan  # whitelist RFC1918 responses for domains
	option local	'/lan/'
	option domain	'lan'
	option expandhosts	1
	option nonegcache	0
	option cachesize	8192
	option authoritative	1
	option readethers	1
	option leasefile	'/tmp/dhcp.leases'
	option resolvfile	'/tmp/resolv.conf.d/resolv.conf.auto'
	#list server		'/mycompany.local/1.2.3.4'
	option nonwildcard	1 # bind to & keep track of interfaces
	#list interface		br-lan
	#list notinterface	lo
	#list bogusnxdomain     '64.94.110.11'
	option localservice	1  # disable to allow DNS requests from non-local subnets
	option ednspacket_max	1232
	option filter_aaaa	0
	option filter_a		0
	#list addnmount		/some/path # read-only mount path to expose it to dnsmasq

config dhcp lan
	option interface	lan
	option start 	100
	option limit	150
	option leasetime	12h

config dhcp wan
	option interface	wan
	option ignore	1
EOF
fi

# 确保注入你的 list ipset 行 (防止重复添加)
sed -i "/miwifi.com/d" "$DHCP_CONF"
sed -i "/option ednspacket_max/a \ \ \ \ \ \ \ \ list ipset '/miwifi.com/192.168.12.1'" "$DHCP_CONF"

# 清除后台密码
sed -i '/\/etc\/shadow/d' package/lean/default-settings/files/zzz-default-settings
sed -i '/chpasswd/d' package/lean/default-settings/files/zzz-default-settings
sed -i '/root:\$/d' package/lean/default-settings/files/zzz-default-settings

sed -i '/passwall/d' package/base-files/files/etc/opkg/distfeeds.conf 2>/dev/null
sed -i '/helloworld/d' package/base-files/files/etc/opkg/distfeeds.conf 2>/dev/null

# 读取版本信息
if [ -f /etc/openwrt_release ]; then
    source /etc/openwrt_release
elif [ -f /etc/release ]; then
    source /etc/release
fi

# 默认值防止为空
orig_version=$(cat "package/lean/default-settings/files/zzz-default-settings" | grep DISTRIB_REVISION= | awk -F "'" '{print $2}')

# 修改banner
cat << EOF > package/base-files/files/etc/banner
     _________
    /        /\     __   __          _
   /  YU    /  \    \ \ / /   _ _ __(_)
  /    RI  /    \    \ V / | | | '__| |
 /________/  YU  \    | || |_| | |  | |
 \        \   RI /    |_| \__,_|_|  |_|
  \    YU  \    /  -------------------------------------------
   \  RI    \  /    LEDE, ${orig_version}
    \________\/    -------------------------------------------

EOF

# 写入 /etc/config/wireless
mkdir -p package/base-files/files/etc/config

cat << 'EOF' > package/base-files/files/etc/config/wireless
config wifi-device 'radio0'
	option type 'mac80211'
	option path 'platform/soc/18000000.wifi'
	option channel '1'
	option band '2g'
	option htmode 'HE20'
	option disabled '0'
	option country 'CN'
	option cell_density '3'
	option mu_beamformer '1'
	option vendor_vht '1'

config wifi-iface 'default_radio0'
	option device 'radio0'
	option network 'lan'
	option mode 'ap'
	option ssid 'rd03_minet_12ac'
	option encryption 'none'
	option multicast_to_unicast '1'
	option ieee80211k '1'
	option ieee80211v '1'
	option wnm_sleep_mode '0'
	option time_advertisement '0'
	option wpa_disable_eapol_key_retries '1'

config wifi-device 'radio1'
	option type 'mac80211'
	option path 'platform/soc/18000000.wifi+1'
	option channel '36'
	option band '5g'
	option htmode 'HE160'
	option disabled '0'
	option country 'CN'
	option cell_density '3'
	option mu_beamformer '1'

config wifi-iface 'default_radio1'
	option device 'radio1'
	option network 'lan'
	option mode 'ap'
	option ssid 'rd03_minet_12ac'
	option encryption 'none'
	option multicast_to_unicast '1'
	option ieee80211k '1'
	option ieee80211v '1'
	option wnm_sleep_mode '0'
	option time_advertisement '0'
	option wpa_disable_eapol_key_retries '1'
EOF

mkdir -p package/base-files/files/etc

# 设置 LuCI 设备描述（model）
mkdir -p package/base-files/files/etc/config
cat << 'EOF' > package/base-files/files/etc/config/system
config system
	option hostname 'AX3000T'
	option description 'Xiaomi-AX3000T'
EOF

# Move UPnP from Services to Network
sed -i 's#admin/services/upnp#admin/network/upnp#g' \
feeds/luci/applications/luci-app-upnp/root/usr/share/luci/menu.d/luci-app-upnp.json
