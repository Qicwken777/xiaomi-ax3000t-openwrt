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

# 修改默认 IP
sed -i 's/192.168.1.1/192.168.12.1/g' package/base-files/files/bin/config_generate

# 清除后台密码
sed -i 's/^root:.*/root::0:0:99999:7:::/' package/base-files/files/etc/shadow

# 劫持miwifi.com
mkdir -p package/base-files/files/etc/dnsmasq.d

cat << 'EOF' > package/base-files/files/etc/dnsmasq.d/miwifi.conf
address=/miwifi.com/192.168.12.1
address=/www.miwifi.com/192.168.12.1
EOF

# 修改banner
cat << 'EOF' > package/base-files/files/etc/banner
     _________
    /        /\     __   __          _
   /  YU    /  \    \ \ / /   _ _ __(_)
  /    RI  /    \    \ V / | | | '__| |
 /________/  YU  \    | || |_| | |  | |
 \        \   RI /    |_| \__,_|_|  |_|
  \    YU  \    /  -------------------------------------------
   \  RI    \  /    \s \r
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
	option ssid 'rd03_minet_12ac_5G'
	option encryption 'none'
	option multicast_to_unicast '1'
	option ieee80211k '1'
	option ieee80211v '1'
	option wnm_sleep_mode '0'
	option time_advertisement '0'
	option wpa_disable_eapol_key_retries '1'
EOF
