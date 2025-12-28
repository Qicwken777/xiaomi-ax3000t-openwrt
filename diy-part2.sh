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
