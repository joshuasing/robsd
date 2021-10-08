utility_setup >"$TMP1"; read -r _ BINDIR ROBSDDIR <"$TMP1"

ROBSDREGRESS="${EXECDIR}/robsd-regress"
ROBSDKILL="${EXECDIR}/robsd-kill"

if testcase "basic"; then
	config_stub - "robsd-regress" <<-EOF
	ROBSDDIR=${ROBSDDIR}
	EXECDIR=${EXECDIR}
	REGRESSUSER=nobody
	SUDO=doas
	TESTS="test/fail test/hello:P test/root:R"
	EOF
	mkdir "$ROBSDDIR"
	mkdir -p "${TSHDIR}/regress/test/fail"
	cat <<EOF >"${TSHDIR}/regress/test/fail/Makefile"
all:
	exit 1
EOF
	mkdir -p "${TSHDIR}/regress/test/hello"
	cat <<EOF >"${TSHDIR}/regress/test/hello/Makefile"
all:
	echo hello >${TSHDIR}/hello
EOF
	mkdir -p "${TSHDIR}/regress/test/root"
	cat <<EOF >"${TSHDIR}/regress/test/root/Makefile"
all:
	echo SUDO=\${SUDO} >${TSHDIR}/root
EOF

	if ! PATH="${BINDIR}:${PATH}" sh "$ROBSDREGRESS" >"$TMP1" 2>&1; then
		fail - "expected exit zero" <"$TMP1"
	fi
	assert_file - "${TSHDIR}/hello" <<-EOF
	hello
	EOF
	assert_file - "${TSHDIR}/root" <<-EOF
	SUDO=
	EOF
fi

if testcase "failure in non-test step"; then
	config_stub - "robsd-regress" <<-EOF
	ROBSDDIR=${ROBSDDIR}
	EXECDIR=${EXECDIR}
	REGRESSUSER=nobody
	TESTS="test/nothing"
	EOF
	mkdir "$ROBSDDIR"
	# Make the env step fail.
	cat <<-EOF >"${BINDIR}/df"
	#!/bin/sh
	exit 1
	EOF
	chmod u+x "${BINDIR}/df"

	if PATH="${BINDIR}:${PATH}" sh "$ROBSDREGRESS" >"$TMP1" 2>&1; then
		fail - "expected exit non-zero" <"$TMP1"
	fi

	rm "${BINDIR}/df"
fi

if testcase "kill"; then
	config_stub - "robsd-regress" <<-EOF
	ROBSDDIR=${ROBSDDIR}
	EXECDIR=${EXECDIR}
	REGRESSUSER=nobody
	TESTS="test/sleep test/nein"
	EOF
	mkdir "$ROBSDDIR"
	mkdir -p "${TSHDIR}/regress/test/sleep"
	cat <<EOF >"${TSHDIR}/regress/test/sleep/Makefile"
all:
	echo sleep >${TSHDIR}/sleep
	sleep 3600
EOF
	mkdir -p "${TSHDIR}/regress/test/nein"
	cat <<EOF >"${TSHDIR}/regress/test/nein/Makefile"
all:
	echo nein >${TSHDIR}/nein
EOF

	if ! PATH="${BINDIR}:${PATH}" sh "$ROBSDREGRESS" -D \
	   >"$TMP1" 2>&1; then
		fail - "expected exit zero" <"$TMP1"
	fi
	until [ -e "${TSHDIR}/sleep" ]; do
		sleep .1
	done
	PATH="${BINDIR}:${PATH}" sh "$ROBSDKILL"
	while pgrep -q -f "$ROBSDREGRESS"; do
		sleep .1
	done
	echo sleep | assert_file - "${TSHDIR}/sleep"
	if [ -e "${TSHDIR}/nein" ]; then
		fail - "expected nein to not be present" <"${TSHDIR}/nein"
	fi
	if [ -e "${ROBSDDIR}/.running" ]; then
		fail "expected lock to not be present"
	fi
fi
