#!/bin/bash
# SPDX-License-Identifier: (LGPL-2.1 OR LGPL-3.0)
# Copyright (C) SUSE LLC 2021-2022, all rights reserved.

RAPIDO_DIR="$(realpath -e ${0%/*})/.."
. "${RAPIDO_DIR}/runtime.vars"

_rt_require_dracut_args "$RAPIDO_DIR/autorun/lib/fstests.sh" \
			"$RAPIDO_DIR/autorun/fstests_ext4.sh" "$@"
_rt_require_fstests

"$DRACUT" --install "tail blockdev ps rmdir resize dd vim grep find df sha256sum \
		   strace mkfs shuf free ip \
		   which perl awk bc touch cut chmod true false unlink \
		   mktemp getfattr setfattr chacl attr killall hexdump sync \
		   id sort uniq date expr tac diff head dirname seq \
		   basename tee egrep yes mkswap timeout \
		   fstrim fio logger dmsetup chattr lsattr cmp stat \
		   dbench /usr/share/dbench/client.txt hostname getconf md5sum \
		   od wc getfacl setfacl tr xargs sysctl link truncate quota \
		   repquota setquota quotacheck quotaon pvremove vgremove \
		   xfs_mkfile xfs_db xfs_io wipefs filefrag losetup \
		   chgrp du fgrep pgrep tar rev kill duperemove \
		   swapon swapoff xfs_freeze fsck dump restore \
		   debugfs dumpe2fs e2fsck e2image e4defrag fsck.ext4 \
		   mke2fs mkfs.ext4 resize2fs tune2fs \
		   ${FSTESTS_SRC}/ltp/* ${FSTESTS_SRC}/src/* \
		   ${FSTESTS_SRC}/src/log-writes/* \
		   ${FSTESTS_SRC}/src/aio-dio-regress/*" \
	--include "$FSTESTS_SRC" "$FSTESTS_SRC" \
	--add-drivers "zram lzo lzo-rle dm-flakey ext4 \
		       loop scsi_debug dm-log-writes" \
	--modules "base" \
	"${DRACUT_RAPIDO_ARGS[@]}" \
	"$DRACUT_OUT" || _fail "dracut failed"

_rt_xattr_vm_resources_set "$DRACUT_OUT" "2" "4096M"
