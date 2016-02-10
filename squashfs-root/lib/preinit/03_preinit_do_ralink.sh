#!/bin/sh

do_ralink() {
	. /lib/ralink.sh
}

boot_hook_add preinit_main do_ralink
