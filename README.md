
# Pandorabox 纯洁版 for MiWiFi mini

基于 Pandorabox for MiWiFi mini 的 r1696 版。并使用 [@rssnsj](https://github.com/rssnsj) 的 [firmware-tools](https://github.com/rssnsj/firmware-tools) 工具进行解包，若需要打包，则需要这里的版本：[firmware-tools](https://github.com/pexcn/firmware-tools).

```bash
# 由于 git 不能索引空目录，所以必须还原空目录
mkdir \
	squashfs-root/dev/ \
	squashfs-root/lib/uci/ \
	squashfs-root/mnt/ \
	squashfs-root/overlay/ \
	squashfs-root/proc/ \
	squashfs-root/root/ \
	squashfs-root/sys/ \
	squashfs-root/tmp/ \
	squashfs-root/usr/lib/lua/luci/model/cbi/admin_services/ \
	squashfs-root/usr/lib/opkg/lists/

# 打包
openwrt-repack.sh -R pandorabox.bin
```

