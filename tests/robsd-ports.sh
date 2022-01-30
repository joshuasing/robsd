robsd_mock >"$TMP1"; read -r _ BINDIR ROBSDDIR <"$TMP1"

cat <<'EOF' >"${BINDIR}/dpb"
#!/bin/sh

mkdir -p "${TSHDIR}/ports/logs/$(machine)/paths/devel"
touch "${TSHDIR}/ports/logs/$(machine)/paths/devel/outdated.log"

case "$@" in
*devel/broken*)
	cat <<-ENGINE >"${TSHDIR}/ports/logs/$(machine)/engine.log"
	!: devel/broken is marked as broken
	ENGINE
	;;
*)
	;;
esac

EOF
chmod u+x "${BINDIR}/dpb"

# robsd_ports [robsd-ports-argument ...]
robsd_ports() (
	setmode "robsd-ports"
	PATH="${BINDIR}:${PATH}"
	export PATH PORTS TSHDIR
	sh "${EXECDIR}/robsd-ports" "$@"
)

if testcase "basic"; then
	robsd_config -P - <<-EOF
	robsddir "${ROBSDDIR}"
	execdir "${EXECDIR}"
	ports { "devel/updated" "devel/outdated" }
	EOF
	mkdir "$ROBSDDIR"

	if ! robsd_ports -d -s cvs -s proot >"$TMP1" 2>&1; then
		fail - "expected exit zero" <"$TMP1"
	fi
	_builddir="$(find "${ROBSDDIR}" -type d -mindepth 1 -maxdepth 1)"

	if step_eval -n devel/updated "${_builddir}/steps" 2>/dev/null; then
		fail - "unexpected step devel/updated" <"${_builddir}/steps"
	fi
	if ! step_eval -n devel/outdated "${_builddir}/steps" 2>/dev/null; then
		fail - "expected step devel/outdated" <"${_builddir}/steps"
	fi

	# Remove unstable output.
	sed -e '/running as pid/d' "${_builddir}/robsd.log" >"$TMP1"
	assert_file - "$TMP1" <<-EOF
	robsd-ports: using directory ${_builddir} at step 1
	robsd-ports: skipping steps: cvs proot
	robsd-ports: step env
	robsd-ports: step cvs skipped
	robsd-ports: step proot skipped
	robsd-ports: step patch
	robsd-ports: step dpb
	robsd-ports: step distrib
	robsd-ports: step revert
	robsd-ports: step end
	robsd-ports: trap exit 0
	EOF
fi

if testcase "skip"; then
	robsd_config -P - <<-EOF
	robsddir "${ROBSDDIR}"
	execdir "${EXECDIR}"
	ports { "devel/updated" "devel/outdated" }
	EOF
	mkdir "$ROBSDDIR"

	if ! robsd_ports -d -s cvs -s proot -s distrib >"$TMP1" 2>&1; then
		fail - "expected exit zero" <"$TMP1"
	fi
	_builddir="$(find "${ROBSDDIR}" -type d -mindepth 1 -maxdepth 1)"

	# Remove unstable output.
	sed -e '/running as pid/d' "${_builddir}/robsd.log" >"$TMP1"
	assert_file - "$TMP1" <<-EOF
	robsd-ports: using directory ${_builddir} at step 1
	robsd-ports: skipping steps: cvs proot distrib
	robsd-ports: step env
	robsd-ports: step cvs skipped
	robsd-ports: step proot skipped
	robsd-ports: step patch
	robsd-ports: step dpb
	robsd-ports: step distrib skipped
	robsd-ports: step revert
	robsd-ports: step end
	robsd-ports: trap exit 0
	EOF
fi

if testcase "port flagged as broken"; then
	robsd_config -P - <<-EOF
	robsddir "${ROBSDDIR}"
	execdir "${EXECDIR}"
	ports { "devel/broken" }
	EOF
	mkdir "$ROBSDDIR"

	if robsd_ports -d -s cvs -s proot >"$TMP1" 2>&1; then
		fail - "expected exit non-zero" <"$TMP1"
	fi
	_builddir="$(find "${ROBSDDIR}" -type d -mindepth 1 -maxdepth 1)"

	if ! step_eval -n devel/broken "${_builddir}/steps" 2>/dev/null; then
		fail - "expected step devel/broken" <"${_builddir}/steps"
	fi
	assert_file - "$(step_value log)" <<-EOF
	!: devel/broken is marked as broken
	EOF
fi
