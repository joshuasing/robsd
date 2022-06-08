. "${EXECDIR}/util.sh"

config_load <<'EOF'
ROBSDDIR="${robsddir}"
CVSROOT="${cvs-root}"
CVSUSER="${cvs-user}"
EOF

if [ -z "$CVSROOT" ] || [ -z "$CVSUSER" ]; then
	exit 0
fi

case "$_MODE" in
robsd)
	config_load <<-'EOF'
	BSDSRCDIR="${bsd-srcdir}"
	XSRCDIR="${x11-srcdir}"
	EOF
	;;
robsd-ports)
	config_load <<-'EOF'
	CHROOT="${chroot}"
	PORTSDIR="${ports-dir}"
	EOF
	;;
*)
	exit 1
	;;
esac

_tmpdir="${BUILDDIR}/tmp"

{
[ "$_MODE" = "robsd" ] && echo src "$BSDSRCDIR"
[ "$_MODE" = "robsd" ] && echo xenocara "$XSRCDIR"
[ "$_MODE" = "robsd-ports" ] && echo ports "${CHROOT}${PORTSDIR}"
} | while read -r _n _d; do
	_ci="${_tmpdir}/cvs-${_n}-ci.log"
	_up="${_tmpdir}/cvs-${_n}-up.log"

	if ! [ -d "${_d}/CVS" ]; then
		unpriv "$CVSUSER" "cd ${_d}/.. && exec cvs -qd ${CVSROOT} checkout ${_n}" 2>&1 |
		tee "$_up"
	else
		unpriv "$CVSUSER" "cd ${_d} && exec cvs -qd ${CVSROOT} update -Pd" 2>&1 |
		tee "$_up" |
		cvs_log -r "$ROBSDDIR" -t "$_tmpdir" -c "$_d" -h "$CVSROOT" -u "$CVSUSER" |
		tee "$_ci"
	fi

	find "$_d" -type f -name Root -delete
done
