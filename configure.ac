AC_PREREQ([2.65])
AC_INIT([session-nanny],[1],[],[])

AC_CONFIG_HEADERS([src/config.h])
AC_CONFIG_SRCDIR([daemon/])
AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_AUX_DIR([.aux])

AM_INIT_AUTOMAKE([1.11 foreign subdir-objects parallel-tests dist-xz no-dist-gzip tar-ustar])

AM_SILENT_RULES([yes])

AM_CFLAGS="-Wall -Wextra"
AM_VALA_CFLAGS="-Wno-all -Wno-extra -Wno-discarded-qualifiers"
AM_VALAFLAGS=""
AM_LDFLAGS=""

AC_PROG_CC
AM_PROG_VALAC([0.14])
AC_PROG_SED

GETTEXT_PACKAGE=$PACKAGE_NAME
AC_DEFINE_UNQUOTED([GETTEXT_PACKAGE], ["${GETTEXT_PACKAGE}"], [Gettext Package])
AC_SUBST([GETTEXT_PACKAGE])

AC_PROG_INSTALL

AC_ARG_WITH(systemduserunitdir, AS_HELP_STRING([--with-systemduserunitdir=DIR], [Directory for systemd user unit files]), [], with_systemduserunitdir=yes)
case "${with_systemduserunitdir}" in
    no|"") AC_MSG_ERROR([*** You must define systemduserunitdir when compiling systemd support]) ;;
    yes) systemduserunitdir="`${PKG_CONFIG} --variable=systemduserunitdir systemd`" ;;
    *) systemduserunitdir="${with_systemduserunitdir}" ;;
esac
AC_SUBST([systemduserunitdir])

AC_ARG_WITH(dbussessionservicedir, AS_HELP_STRING([--with-dbussessionservicedir=DIR], [Directory for D-Bus session service files]), [], with_dbussessionservicedir=yes)
case "${with_dbussessionservicedir}" in
    no|"") AC_MSG_ERROR([*** You must define dbussessionservicedir when compiling D-Bus support]) ;;
    yes) dbussessionservicedir="`${PKG_CONFIG} --variable=session_bus_services_dir dbus-1`" ;;
    *) dbussessionservicedir="${with_dbussessionservicedir}" ;;
esac
AC_SUBST([dbussessionservicedir])

PKG_CHECK_MODULES([GLIB], [glib-2.0 >= 2.32])
GLIB_VALAFLAGS="--pkg glib-2.0"
AC_SUBST([GLIB_VALAFLAGS])

PKG_CHECK_MODULES([GIO], [gio-2.0 >= 2.28])
GIO_VALAFLAGS="--pkg gio-2.0"
AC_SUBST([GIO_VALAFLAGS])


AC_SUBST([AM_CFLAGS])
AC_SUBST([AM_VALA_CFLAGS])
AC_SUBST([AM_VALAFLAGS])
AC_SUBST([AM_LDFLAGS])

AC_CONFIG_FILES([
  Makefile
])
AC_OUTPUT
