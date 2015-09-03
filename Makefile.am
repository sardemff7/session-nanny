AM_DISTCHECK_CONFIGURE_FLAGS = \
	--with-systemduserunitdir="$$dc_install_base/$(systemduserunitdir)" \
	--with-dbussessionservicedir="$$dc_install_base/$(dbussessionservicedir)" \
	$(null)

ACLOCAL_AMFLAGS = -I m4 ${ACLOCAL_FLAGS}
AM_MAKEFLAGS = --no-print-directory


bin_PROGRAMS =
libexec_PROGRAMS =

systemduserunit_DATA =
dbussessionservice_DATA =


EXTRA_DIST = \
	src/config.vapi \
	$(null)

CLEANFILES =


AM_CFLAGS += \
	-I $(srcdir)/src \
	$(null)

AM_VALA_CFLAGS += \
	--include config.h \
	$(null)

AM_VALAFLAGS += \
	--vapidir $(srcdir)/src \
	--pkg config \
	$(null)

#
# Daemon
#
libexec_PROGRAMS += session-nanny
systemduserunit_DATA += daemon/session-nanny.service
dbussessionservice_DATA += daemon/net.sardemff7.session-nanny.service

session_nanny_SOURCES = \
	daemon/interfaces.vala \
	daemon/main.vala

EXTRA_session_nanny_DEPENDENCIES = \
	src/config.vapi

session_nanny_VALAFLAGS = \
	$(AM_VALAFLAGS) \
	$(GIO_VALAFLAGS) \
	$(GLIB_VALAFLAGS) \
	--pkg posix

session_nanny_CFLAGS = \
	$(AM_CFLAGS) \
	$(AM_VALA_CFLAGS) \
	-D G_LOG_DOMAIN=\"session-nanny\" \
	$(GIO_CFLAGS) \
	$(GLIB_CFLAGS)

session_nanny_LDADD = \
	$(GIO_LIBS) \
	$(GLIB_LIBS)


#
# Client
#
bin_PROGRAMS += session-baby

session_baby_SOURCES = \
	client/main.vala

EXTRA_session_baby_DEPENDENCIES = \
	src/config.vapi

session_baby_VALAFLAGS = \
	$(AM_VALAFLAGS) \
	$(GIO_VALAFLAGS) \
	$(GLIB_VALAFLAGS)

session_baby_CFLAGS = \
	$(AM_CFLAGS) \
	$(AM_VALA_CFLAGS) \
	-D G_LOG_DOMAIN=\"session-baby\" \
	$(GIO_CFLAGS) \
	$(GLIB_CFLAGS)

session_baby_LDADD = \
	$(GIO_LIBS) \
	$(GLIB_LIBS)



#
# systemd units and D-Bus service file
#

EXTRA_DIST += $(systemduserunit_DATA:.service=.service.in) $(dbussessionservice_DATA:.service=.service.in)
CLEANFILES += $(systemduserunit_DATA) $(dbussessionservice_DATA)

%.service: %.service.in Makefile
	$(AM_V_GEN)$(SED) \
		-e 's:[@]libexecdir[@]:$(libexecdir):g' \
		$< > $@
