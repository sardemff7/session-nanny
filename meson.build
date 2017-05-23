project('session-nanny', 'c', 'vala',
    version: '1',
    meson_version: '>=0.39.1',
    license: [ 'GPL3+', 'LGPL3+', 'MIT' ],
    default_options: [
        'c_std=gnu11',
        'warning_level=2',
    ],
)

vala = meson.get_compiler('vala')

glib_min_major='2'
glib_min_minor='32'
glib_min_version='.'.join([glib_min_major, glib_min_minor])
glib = dependency('glib-2.0', version: '>= @0@'.format(glib_min_version))
gio = dependency('gio-2.0')
posix = vala.find_library('posix')
config_vapi = vala.find_library('config', dirs: join_paths(meson.current_source_dir(), 'src'))

systemduserunit_install_dir = get_option('systemduserunitdir')
if systemduserunit_install_dir == ''
    systemd = dependency('systemd')
    systemduserunit_install_dir = systemd.get_pkgconfig_variable('systemduserunitdir')
endif
dbussessionservice_install_dir = get_option('dbussessionservicedir')
if dbussessionservice_install_dir == ''
    dbus = dependency('dbus-1')
    dbussessionservice_install_dir = dbus.get_pkgconfig_variable('session_bus_services_dir')
endif


header_conf = configuration_data()
other_conf = configuration_data()
header_conf.set_quoted('PACKAGE_NAME', meson.project_name())
header_conf.set_quoted('PACKAGE_VERSION', meson.project_version())
header_conf.set_quoted('GETTEXT_PACKAGE', meson.project_name())

header_conf.set('GLIB_VERSION_MIN_REQUIRED', '(G_ENCODE_VERSION(@0@,@1@))'.format(glib_min_major, glib_min_minor))
header_conf.set('G_LOG_USE_STRUCTURED', true)

other_conf.set('libexecdir', join_paths(get_option('prefix'), get_option('libexecdir')))

config_h = configure_file(output: 'config.h', configuration: header_conf)

executable('session-nanny', [
        'daemon/main.vala',
        'daemon/interfaces.vala',
        config_h,
    ],
    dependencies: [ config_vapi, gio, glib, posix ],
    install: true,
    install_dir: get_option('libexecdir'),
)

executable('session-baby', [
        'client/main.vala',
        config_h,
    ],
    dependencies: [ config_vapi, gio, glib ],
    install: true,
)

configure_file(
    input: 'daemon/session-nanny.service.in',
    output: 'session-nanny.service',
    configuration: other_conf,
    install_dir: systemduserunit_install_dir,
)

configure_file(
    input: 'daemon/net.sardemff7.session-nanny.service.in',
    output: 'net.sardemff7.session-nanny.service',
    configuration: other_conf,
    install_dir: dbussessionservice_install_dir,
)
