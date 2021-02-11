export WRKDIR
utility_setup >"$TMP1"; read -r WRKDIR BUILDDIR <"$TMP1"

ROBSDRESCUE="${EXECDIR}/robsd-rescue"

setup() {
	config_stub - <<-EOF
	BSDDIFF=/var/empty
	EOF

	mkdir -p "${BUILDDIR}/2020-09-01.1" "${BUILDDIR}/2020-09-02.1"
	cat <<-EOF >"${BUILDDIR}/2020-09-02.1/steps"
	step="1" name="patch" exit="0"
	EOF

	diff_create >"${BUILDDIR}/2020-09-02.1/src.diff.1"
	cat <<-EOF >"${TSHDIR}/foo"
	int main(void) {
		int x = 0;
		return x;
	}
	EOF
}

if testcase "basic"; then
	setup
	(cd "$TSHDIR" && patch -s <"${BUILDDIR}/2020-09-02.1/src.diff.1")

	sh "$ROBSDRESCUE" >"$TMP1" 2>&1
	assert_file - "$TMP1" <<-EOF
	robsd-rescue: using release directory ${TSHDIR}/build/2020-09-02.1
	robsd-rescue: reverting diff ${BUILDDIR}/2020-09-02.1/src.diff.1
	EOF
fi

if testcase "patch already reverted"; then
	setup
	sh "$ROBSDRESCUE" >"$TMP1" 2>&1
	assert_file - "$TMP1" <<-EOF
	robsd-rescue: using release directory ${TSHDIR}/build/2020-09-02.1
	robsd-rescue: diff already reverted ${BUILDDIR}/2020-09-02.1/src.diff.1
	EOF
fi

if testcase "patch step absent"; then
	setup
	: >"${BUILDDIR}/2020-09-02.1/steps"
	if sh "$ROBSDRESCUE" >"$TMP1" 2>&1; then
		fail "want exit 1, got 0"
	fi
	assert_file - "$TMP1" <<-EOF
	robsd-rescue: using release directory ${TSHDIR}/build/2020-09-02.1
	robsd-rescue: step patch not found
	EOF
fi
