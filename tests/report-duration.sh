if testcase "with previous"; then
	LOGDIR="${BUILDDIR}/2019-02-23"
	mkdir -p ${BUILDDIR}/2019-02-{22,23}
	cat <<-EOF >${BUILDDIR}/2019-02-22/stages
	name="end" stage="1" duration="1800"
	EOF

	assert_eq "01:00:00 (+00:30:00)" "$(report_duration -d 3600)"
fi

if testcase "with previous negative"; then
	LOGDIR="${BUILDDIR}/2019-02-23"
	mkdir -p ${BUILDDIR}/2019-02-{22,23}
	cat <<-EOF >${BUILDDIR}/2019-02-22/stages
	name="end" stage="1" duration="3600"
	EOF

	assert_eq "00:30:00 (-00:30:00)" "$(report_duration -d 1800)"
fi

if testcase "with previous failed"; then
	LOGDIR="${BUILDDIR}/2019-02-23"
	mkdir -p ${BUILDDIR}/2019-02-{22,23}
	cat <<-EOF >${BUILDDIR}/2019-02-22/stages
	name="kernel" stage="1" exit="1" duration="3600"
	EOF

	assert_eq "00:30:00" "$(report_duration -d 1800)"
fi

if testcase "with previous absent"; then
	assert_eq "00:30:00" "$(report_duration -d 1800)"
fi

if testcase "without previous"; then
	assert_eq "01:00:00" "$(report_duration 3600)"
fi
