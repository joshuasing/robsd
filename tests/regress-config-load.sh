# Must be defined, usually done by config_load.
NOTPARALLEL=""
SKIPIGNORE=""

if testcase "basic"; then
(
	TESTS="bin/cat:SP bin/cp:S bin/dd"
	if ! regress_config_load; then
		fail - "expected exit zero" <"$TMP1"
	fi
	{
		echo "TESTS: ${TESTS}"
		echo "NOTPARALLEL: ${NOTPARALLEL}"
		echo "SKIPIGNORE: ${SKIPIGNORE}"
	} >"$TMP1"
	assert_file - "$TMP1" <<-EOF
	TESTS: bin/cat bin/cp bin/dd
	NOTPARALLEL: bin/cat
	SKIPIGNORE: bin/cat bin/cp
	EOF
)
fi

if testcase "unknown flag"; then
(
	TESTS="bin/cat:X"
	# Must end up calling fatal(), hence the subshell.
	if (regress_config_load >"$TMP1" 2>&1); then
		fail - "expected exit non-zero" <"$TMP1"
	fi
)
fi
