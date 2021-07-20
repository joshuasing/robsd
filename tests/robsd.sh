utility_setup >"$TMP1"; read -r WRKDIR BUILDDIR <"$TMP1"

ROBSD="${EXECDIR}/robsd"

# Create exec directory including all stages.
mkdir -p "${WRKDIR}/exec"
cp "${EXECDIR}/util.sh" "${WRKDIR}/exec"
for _stage in \
	env \
        cvs \
        patch \
        kernel \
        reboot \
        base \
        release \
        checkflist \
        xbase \
        xrelease \
        image \
	hash \
        revert \
        distrib
do
	: >"${WRKDIR}/exec/robsd-${_stage}.sh"
done

if testcase "basic"; then
	# Ensure hook output is prefixed and exit status ignored.
	_hook="${TSHDIR}/hook.sh"
	cat <<-EOF >"$_hook"
	if [ "\$2" = "end" ]; then
		echo stdout
		echo stderr 1>&2
		exit 1
	fi
	EOF
	chmod u+x "$_hook"

	config_stub - <<-EOF
	HOOK=${_hook}
	EOF
	mkdir -p "$BUILDDIR"
	echo "Index: dir/file.c" >"${TSHDIR}/src.diff"
	echo "Index: dir/file.c" >"${TSHDIR}/xenocara.diff"
	EXECDIR="${WRKDIR}/exec" sh "$ROBSD" \
		-S "${TSHDIR}/src.diff" -X "${TSHDIR}/xenocara.diff" \
		-s reboot \
		>"$TMP1" 2>&1
	if [ -e "${BUILDDIR}/.running" ]; then
		fail - "lock not removed" <"$TMP1"
	fi

	# Remove non stable output.
	sed -i -e '/running as pid/d' -e '/robsd-exec:/d' "$TMP1"
	_logdir="${BUILDDIR}/$(date '+%Y-%m-%d').1"
	assert_file - "$TMP1" <<-EOF
	robsd: using directory ${_logdir} at step 1
	robsd: using diff ${TSHDIR}/src.diff rooted at ${TSHDIR}
	robsd: using diff ${TSHDIR}/xenocara.diff rooted at ${TSHDIR}
	robsd: skipping steps: reboot
	robsd: step env
	robsd: step cvs
	robsd: invoking hook: ${_hook} ${_logdir} cvs 0
	robsd: step patch
	robsd: invoking hook: ${_hook} ${_logdir} patch 0
	robsd: step kernel
	robsd: invoking hook: ${_hook} ${_logdir} kernel 0
	robsd: step reboot skipped
	robsd: step env
	robsd: step base
	robsd: invoking hook: ${_hook} ${_logdir} base 0
	robsd: step release
	robsd: invoking hook: ${_hook} ${_logdir} release 0
	robsd: step checkflist
	robsd: invoking hook: ${_hook} ${_logdir} checkflist 0
	robsd: step xbase
	robsd: invoking hook: ${_hook} ${_logdir} xbase 0
	robsd: step xrelease
	robsd: invoking hook: ${_hook} ${_logdir} xrelease 0
	robsd: step image
	robsd: invoking hook: ${_hook} ${_logdir} image 0
	robsd: step hash
	robsd: invoking hook: ${_hook} ${_logdir} hash 0
	robsd: step revert
	robsd: invoking hook: ${_hook} ${_logdir} revert 0
	robsd: step distrib
	robsd: invoking hook: ${_hook} ${_logdir} distrib 0
	robsd: step end
	robsd: invoking hook: ${_hook} ${_logdir} end 0
	hook: stdout
	hook: stderr
	EOF
fi

if testcase "already running"; then
	config_stub
	mkdir -p "$BUILDDIR"
	echo /var/empty >"${BUILDDIR}/.running"
	EXECDIR="${WRKDIR}/exec" sh "$ROBSD" 2>&1 | grep -v 'using ' >"$TMP1"
	if ! [ -e "${BUILDDIR}/.running" ]; then
		fail - "lock not preserved" <"$TMP1"
	fi
	assert_file - "$TMP1" <<-EOF
	robsd: /var/empty: lock already acquired
	robsd: already running
	robsd: failed in step unknown, exit 1
	EOF
fi

if testcase "already running detached"; then
	config_stub
	mkdir -p "$BUILDDIR"
	echo /var/empty >"${BUILDDIR}/.running"
	EXECDIR="${WRKDIR}/exec" sh "$ROBSD" -D 2>&1 | grep -v 'using ' >"$TMP1"
	if ! [ -e "${BUILDDIR}/.running" ]; then
		fail - "lock not preserved" <"$TMP1"
	fi
	assert_file - "$TMP1" <<-EOF
	robsd: /var/empty: lock already acquired
	robsd: already running
	robsd: failed in step unknown, exit 1
	EOF
fi

if testcase "early failure"; then
	config_stub
	echo 'exit 0' >"${WRKDIR}/bin/sysctl"
	mkdir -p "$BUILDDIR"
	if EXECDIR="${WRKDIR}/exec" sh "$ROBSD" >"$TMP1" 2>&1; then
		fail - "expected exit non-zero" <"$TMP1"
	fi
	assert_file - "$TMP1" <<-EOF
	robsd: non-optimal performance detected, check hw.perfpolicy and hw.setperf
	robsd: failed in step unknown, exit 1
	EOF
fi

if testcase "missing build directory"; then
	config_stub
	if EXECDIR="${WRKDIR}/exec" sh "$ROBSD" >"$TMP1" 2>&1; then
		fail - "expected exit non-zero" <"$TMP1"
	fi
	assert_file - "$TMP1" <<-EOF
	ls: ${BUILDDIR}: No such file or directory
	EOF
fi
