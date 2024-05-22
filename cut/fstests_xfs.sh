#!/bin/bash
# SPDX-License-Identifier: (LGPL-2.1 OR LGPL-3.0)
# Copyright (C) SUSE LLC 2016-2022, all rights reserved.

RAPIDO_DIR="$(realpath -e ${0%/*})/.."
. "${RAPIDO_DIR}/runtime.vars"

_rt_require_dracut_args "$RAPIDO_DIR/autorun/lib/fstests.sh" \
			"$RAPIDO_DIR/autorun/fstests_xfs.sh" "$@"
_rt_require_fstests
req_inst=()
_rt_require_pam_mods req_inst "pam_rootok.so" "pam_limits.so"
_rt_human_size_in_b "${FSTESTS_ZRAM_SIZE:-1G}" zram_bytes \
	|| _fail "failed to calculate memory resources"
# 2x multiplier for one test and one scratch zram. +2G as buffer
_rt_mem_resources_set "$((2048 + (zram_bytes * 2 / 1048576)))M"

man_deps=(man /etc/manpath.config \
	  $(man --path xfs_io xfs_spaceman xfs_db xfs_quota))
[[ ${man_deps[@]} == ${man_deps[@]%.gz} ]] || man_deps+=(zcat gzip)
[[ ${man_deps[@]} == ${man_deps[@]%.bz2} ]] || man_deps+=(bzcat)
[[ ${man_deps[@]} == ${man_deps[@]%.xz} ]] || man_deps+=(xzcat)

# xfs/122: pull in compiler and xfs headers
_rt_require_gcc req_inst stdio.h xfs/xfs.h xfs/xfs_types.h xfs/xfs_fs.h \
	xfs/xfs_arch.h xfs/xfs_format.h xfs/linux.h
# xfs/122: catch any headers which might be new
req_inst+=("/usr/include/xfs/*.h")

"$DRACUT" --install "tail blockdev ps rmdir resize dd vim grep find df sha256sum \
		   strace mkfs mkfs.xfs free ip su uuidgen losetup ipcmk \
		   which perl awk bc touch cut chmod true false unlink \
		   mktemp getfattr setfattr chacl attr killall hexdump sync \
		   id sort uniq date expr tac diff head dirname seq \
		   basename tee egrep yes mkswap timeout blkdiscard \
		   fstrim fio logger dmsetup chattr lsattr cmp stat \
		   dbench /usr/share/dbench/client.txt hostname getconf md5sum \
		   od wc getfacl setfacl tr xargs sysctl link truncate quota \
		   repquota setquota quotacheck quotaon pvremove vgremove \
		   xfs_mkfile xfs_db xfs_io xfs_spaceman fsck comm indent \
		   xfs_mdrestore xfs_bmap xfs_fsr xfsdump xfs_freeze xfs_info \
		   xfs_logprint xfs_repair xfs_growfs xfs_quota xfs_metadump \
		   chgrp du fgrep pgrep tar rev kill duperemove ${man_deps[*]} \
		   ${req_inst[*]} ${FSTESTS_SRC}/ltp/* ${FSTESTS_SRC}/src/* \
		   ${FSTESTS_SRC}/src/log-writes/* \
		   ${FSTESTS_SRC}/src/aio-dio-regress/*" \
	--include "$FSTESTS_SRC" "$FSTESTS_SRC" \
	--add-drivers "zram nvme lzo lzo-rle dm-snapshot dm-flakey xfs \
		       loop scsi_debug dm-log-writes virtio_blk" \
	--modules "base" \
	"${DRACUT_RAPIDO_ARGS[@]}" \
	"$DRACUT_OUT" || _fail "dracut failed"
