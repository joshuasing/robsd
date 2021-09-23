VERSION=	3.0.0

PROG_robsd-exec=	robsd-exec
SRCS_robsd-exec=	robsd-exec.c
OBJS_robsd-exec=	${SRCS_robsd-exec:.c=.o}
DEPS_robsd-exec=	${SRCS_robsd-exec:.c=.d}

CFLAGS+=	-Wall -Wextra -MD -MP

KNFMT+=	robsd-exec.c

SCRIPTS+=	robsd-base.sh
SCRIPTS+=	robsd-checkflist.sh
SCRIPTS+=	robsd-cvs.sh
SCRIPTS+=	robsd-distrib.sh
SCRIPTS+=	robsd-env.sh
SCRIPTS+=	robsd-hash.sh
SCRIPTS+=	robsd-image.sh
SCRIPTS+=	robsd-kernel.sh
SCRIPTS+=	robsd-patch.sh
SCRIPTS+=	robsd-reboot.sh
SCRIPTS+=	robsd-regress-env.sh
SCRIPTS+=	robsd-regress-exec.sh
SCRIPTS+=	robsd-release.sh
SCRIPTS+=	robsd-revert.sh
SCRIPTS+=	robsd-xbase.sh
SCRIPTS+=	robsd-xrelease.sh
SCRIPTS+=	util.sh

DISTFILES+=	CHANGELOG.md
DISTFILES+=	LICENSE
DISTFILES+=	Makefile
DISTFILES+=	Makefile.inc
DISTFILES+=	README.md
DISTFILES+=	robsd
DISTFILES+=	robsd-base.sh
DISTFILES+=	robsd-checkflist.sh
DISTFILES+=	robsd-clean
DISTFILES+=	robsd-clean.8
DISTFILES+=	robsd-cvs.sh
DISTFILES+=	robsd-distrib.sh
DISTFILES+=	robsd-env.sh
DISTFILES+=	robsd-exec.c
DISTFILES+=	robsd-hash.sh
DISTFILES+=	robsd-image.sh
DISTFILES+=	robsd-kernel.sh
DISTFILES+=	robsd-patch.sh
DISTFILES+=	robsd-reboot.sh
DISTFILES+=	robsd-regress
DISTFILES+=	robsd-regress-env.sh
DISTFILES+=	robsd-regress-exec.sh
DISTFILES+=	robsd-regress.8
DISTFILES+=	robsd-release.sh
DISTFILES+=	robsd-rescue
DISTFILES+=	robsd-rescue.8
DISTFILES+=	robsd-revert.sh
DISTFILES+=	robsd-steps
DISTFILES+=	robsd-steps.8
DISTFILES+=	robsd-xbase.sh
DISTFILES+=	robsd-xrelease.sh
DISTFILES+=	robsd.8
DISTFILES+=	robsd.conf.5
DISTFILES+=	tests/Makefile
DISTFILES+=	tests/cleandir.sh
DISTFILES+=	tests/config-load.sh
DISTFILES+=	tests/cvs-log.sh
DISTFILES+=	tests/diff-apply.sh
DISTFILES+=	tests/diff-clean.sh
DISTFILES+=	tests/diff-copy.sh
DISTFILES+=	tests/diff-list.sh
DISTFILES+=	tests/diff-root.sh
DISTFILES+=	tests/duration-total.sh
DISTFILES+=	tests/format-duration.sh
DISTFILES+=	tests/lock-acquire.sh
DISTFILES+=	tests/log-id.sh
DISTFILES+=	tests/prev-release.sh
DISTFILES+=	tests/purge.sh
DISTFILES+=	tests/regress-config-load.sh
DISTFILES+=	tests/regress-failed.sh
DISTFILES+=	tests/regress-tests.sh
DISTFILES+=	tests/report-duration.sh
DISTFILES+=	tests/report-size.sh
DISTFILES+=	tests/report-skip.sh
DISTFILES+=	tests/report.sh
DISTFILES+=	tests/robsd-regress.sh
DISTFILES+=	tests/robsd-rescue.sh
DISTFILES+=	tests/robsd-steps.sh
DISTFILES+=	tests/robsd.sh
DISTFILES+=	tests/step-end.sh
DISTFILES+=	tests/step-eval.sh
DISTFILES+=	tests/step-id.sh
DISTFILES+=	tests/step-next.sh
DISTFILES+=	tests/step-value.sh
DISTFILES+=	tests/t.sh
DISTFILES+=	tests/util.sh
DISTFILES+=	util.sh

PREFIX=		/usr/local
BINDIR=		${PREFIX}/sbin
LIBEXECDIR=	${PREFIX}/libexec
MANDIR=		${PREFIX}/man
INSTALL?=	install
INSTALL_MAN?=	${INSTALL}

MANLINT+=	robsd-clean.8
MANLINT+=	robsd-regress.8
MANLINT+=	robsd-rescue.8
MANLINT+=	robsd-steps.8
MANLINT+=	robsd.8
MANLINT+=	robsd.conf.5

SHLINT+=	${SCRIPTS}
SHLINT+=	robsd
SHLINT+=	robsd-clean
SHLINT+=	robsd-regress
SHLINT+=	robsd-rescue
SHLINT+=	robsd-steps

SUBDIR+=	tests

all: ${PROG_robsd-exec}

${PROG_robsd-exec}: ${OBJS_robsd-exec}
	${CC} ${DEBUG} -o ${PROG_robsd-exec} ${OBJS_robsd-exec} ${LDFLAGS}

clean:
	rm -f ${DEPS_robsd-exec} ${OBJS_robsd-exec} ${PROG_robsd-exec}
.PHONY: clean

dist:
	set -e; \
	d=robsd-${VERSION}; \
	mkdir $$d; \
	for f in ${DISTFILES}; do \
		mkdir -p $$d/`dirname $$f`; \
		cp -p ${.CURDIR}/$$f $$d/$$f; \
	done; \
	find $$d -type d -exec touch -r ${.CURDIR}/Makefile {} \;; \
	tar czvf ${.CURDIR}/$$d.tar.gz $$d; \
	(cd ${.CURDIR}; sha256 $$d.tar.gz >$$d.sha256); \
	rm -r $$d
.PHONY: dist

install: all
	mkdir -p ${DESTDIR}${BINDIR}
	${INSTALL} -m 0755 ${.CURDIR}/robsd ${DESTDIR}${BINDIR}
	${INSTALL} -m 0755 ${.CURDIR}/robsd-clean ${DESTDIR}${BINDIR}
	ln -f ${DESTDIR}${BINDIR}/robsd-clean ${DESTDIR}${BINDIR}/robsd-regress-clean
	${INSTALL} -m 0755 ${.CURDIR}/robsd-regress ${DESTDIR}${BINDIR}
	${INSTALL} -m 0755 ${.CURDIR}/robsd-rescue ${DESTDIR}${BINDIR}
	${INSTALL} -m 0755 ${.CURDIR}/robsd-steps ${DESTDIR}${BINDIR}
	mkdir -p ${DESTDIR}${LIBEXECDIR}/robsd
	${INSTALL} ${PROG_robsd-exec} ${DESTDIR}${LIBEXECDIR}/robsd
.for s in ${SCRIPTS}
	${INSTALL} -m 0644 ${.CURDIR}/$s ${DESTDIR}${LIBEXECDIR}/robsd/$s
.endfor
	@mkdir -p ${DESTDIR}${MANDIR}/man5
	${INSTALL_MAN} ${.CURDIR}/robsd.conf.5 ${DESTDIR}${MANDIR}/man5
	@mkdir -p ${DESTDIR}${MANDIR}/man8
	${INSTALL_MAN} ${.CURDIR}/robsd.8 ${DESTDIR}${MANDIR}/man8
	${INSTALL_MAN} ${.CURDIR}/robsd-clean.8 ${DESTDIR}${MANDIR}/man8
	${INSTALL_MAN} ${.CURDIR}/robsd-regress.8 ${DESTDIR}${MANDIR}/man8
	${INSTALL_MAN} ${.CURDIR}/robsd-rescue.8 ${DESTDIR}${MANDIR}/man8
	${INSTALL_MAN} ${.CURDIR}/robsd-steps.8 ${DESTDIR}${MANDIR}/man8
.PHONY: install

test: all
	${MAKE} -C ${.CURDIR}/tests \
		"EXECDIR=${.CURDIR}" \
		"ROBSDEXEC=${.OBJDIR}/${PROG_robsd-exec}" \
		"TESTFLAGS=${TESTFLAGS}"
.PHONY: test

.include "${.CURDIR}/Makefile.inc"
-include ${DEPS_robsd-exec}
