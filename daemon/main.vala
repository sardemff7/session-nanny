/*
 * session-nanny - Keep an eye on your sessions
 *
 * Copyright © 2015-2016 Quentin "Sardem FF7" Glidic
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

namespace SessionNanny
{
    public static const string bus_name = "net.sardemff7.SessionNanny";
    public static const string object_path = "/net/sardemff7/SessionNanny";

    class Session : Object
    {
        private Nanny nanny;
        private Logind.Session session;
        class Session current = null;
        private string session_path;

        private GLib.HashTable<string, string> _environment;
        public GLib.HashTable<string, string> environment
        {
            get
            {
                return this._environment;
            }
            set
            {
                this._environment = value;
                this._environment.insert("XDG_SESSION_ID", this.session.id);
            }
        }
        public bool active { get { return this.session.active; } }

        public
        Session(string session_path, Nanny nanny) throws GLib.IOError
        {
            this.session_path = session_path;
            this.nanny = nanny;

            this.session = GLib.Bus.get_proxy_sync(BusType.SYSTEM, Logind.bus_name, session_path);
            this.session.g_properties_changed.connect(this.session_properties_change);

            GLib.debug("[Session %s] Added%s", this.session.id, this.session.active ? " (active)" : "");
        }

        private void
        session_properties_change(GLib.DBusProxy session_, GLib.Variant properties, string[] invalidated)
        {
            var dict = new GLib.VariantDict(properties);
            if ( ! ( "Active" in dict ) )
                return;

            GLib.debug("[Session %s] %s", this.session.id, this.session.active ? "Active" : "Inactive");
            if ( this.session.active || ( this.current == this ) )
                this.push(this.session.active);
        }

        public void
        remove()
        {
            if ( this.current == this )
                this.push(false);
        }

        private void
        exec(string[] args)
        {
            try
            {
                GLib.Process.spawn_async(null, args, null, GLib.SpawnFlags.SEARCH_PATH, null, null);
            }
            catch ( GLib.SpawnError e ) {}
        }

        public void
        push(bool active)
        {
            if ( active && ( this.current != null ) )
                this.current.push(false);
            this.current = active ? this : null;

            GLib.HashTable<string, string> dbus_env;
            string[] set_env = {};
            string[] unset_env = {};

            var i = GLib.HashTableIter<string, string>(environment);
            unowned string name;
            unowned string val;
            if ( ! this.session.active )
            {
                dbus_env = new GLib.HashTable<string, string>(GLib.str_hash, GLib.str_equal);
                while ( i.next(out name, null) )
                {
                    unset_env += name;
                    dbus_env.insert(name, "");
                }
            }
            else
            {
                dbus_env = environment;
                while ( i.next(out name, out val) )
                {
                    GLib.debug("    %-20s = %s", name, val);
                    set_env += name + "=" + val;
                }
            }

            this.nanny.push(dbus_env, unset_env, set_env);

            if ( this.nanny.eventd )
            {
                string args[] = { "eventdctl", "nd", "switch", null, null };
                if ( ! active )
                    args[2] = "stop";
                else if ( "WAYLAND_DISPLAY" in environment )
                {
                    args[3] = "wayland";
                    args[4] = environment["WAYLAND_DISPLAY"];
                }
                else if ( "DISPLAY" in environment )
                {
                    args[3] = "xcb";
                    args[4] = environment["DISPLAY"];
                }
                else if ( "TTY" in environment )
                {
                    args[3] = "fbdev";
                    args[4] = "/dev/fb0";
                }
                else
                    args[2] = "stop";


                GLib.debug("eventdctl nd %s %s %s", args[2], ( args[3] != null ) ? args[3] : "", ( args[4] != null ) ? args[4] : "");
                this.exec(args);
            }

            if ( this.nanny.tmux )
            {
                string args[] = {
                    "tmux", "set-environment", null, "-u", ""
                };
                i = GLib.HashTableIter<string, string>(environment);
                while ( i.next(out name, out val) )
                {
                    if ( ! active )
                        args[4] = name;
                    else
                    {
                        args[3] = name;
                        args[4] = val;
                    }
                    GLib.debug("tmux set-environment %s %s", args[3], args[4]);
                    args[2] = "-t0";
                    this.exec(args);
                    args[2] = "-g";
                    this.exec(args);
                }
            }
        }

        public GLib.VariantBuilder
        get_environment_as_variant()
        {
            var env = new GLib.VariantBuilder((GLib.VariantType) "a{ss}");
            var v = GLib.HashTableIter<string, string>(this.environment);
            unowned string @var;
            unowned string val;
            while ( v.next(out @var, out val) )
                env.add("{ss}", @var, val);
            return env;
        }
    }

    [DBus (name = "net.sardemff7.SessionNanny")]
    class Nanny : Object
    {
        private DBus.DBus dbus;
        private Systemd.Manager systemd;
        private Logind.Manager logind;
        [DBus (visible = false)]
        public bool eventd { get; private set; default = false; }
        [DBus (visible = false)]
        public bool tmux { get; private set; default = false; }
        private GLib.HashTable<string, Session> sessions;

        [DBus (visible = false)]
        public
        Nanny() throws GLib.IOError
        {
            this.dbus = GLib.Bus.get_proxy_sync(BusType.SESSION, DBus.bus_name, DBus.object_path);
            this.systemd = GLib.Bus.get_proxy_sync(BusType.SESSION, Systemd.bus_name, Systemd.object_path);
            this.logind = GLib.Bus.get_proxy_sync(BusType.SYSTEM, Logind.bus_name, Logind.object_path);

            string path;
            path = GLib.Path.build_filename(GLib.Environment.get_user_runtime_dir(), "eventd", "private");
            this.eventd = GLib.FileUtils.test(path, GLib.FileTest.EXISTS) && ( ! GLib.FileUtils.test(path, GLib.FileTest.IS_DIR|GLib.FileTest.IS_REGULAR) );

            unowned string base_path;
            base_path = GLib.Environment.get_variable("TMUX_TMPDIR");
            if ( base_path == null )
                base_path = GLib.Environment.get_variable("TMPDIR");
            if ( base_path == null )
                base_path = "/tmp";
            path = GLib.Path.build_filename(base_path, "tmux-%u".printf((uint)Posix.getuid()), "default");
            this.tmux = GLib.FileUtils.test(path, GLib.FileTest.EXISTS) && ( ! GLib.FileUtils.test(path, GLib.FileTest.IS_DIR|GLib.FileTest.IS_REGULAR) );

            this.sessions = new GLib.HashTable<string, Session>(GLib.str_hash, GLib.str_equal);

            this.logind.session_removed.connect(this.session_removed);
        }

        private void
        session_removed(string session_id, GLib.ObjectPath session_path)
        {
            var session = this.sessions[session_path];
            this.sessions.remove(session_path);
            session.remove();
            GLib.debug("[Session %s] Removed", session_id);
        }

        public void
        update_environment(GLib.ObjectPath session_path, GLib.HashTable<string, string> environment)
        {
            var session = this.sessions.lookup(session_path);
            if ( session == null )
            {
                try
                {
                    session = new Session(session_path, this);
                    this.sessions.insert(session_path, session);
                }
                catch ( GLib.IOError e )
                {
                    GLib.warning("Could not register service");
                    return;
                }
            }

            session.environment = environment;
            if ( session.active )
                session.push(true);
        }

        [DBus (visible = false)]
        public void
        push(GLib.HashTable<string, string> dbus_env, string[] unset_env, string[] set_env)
        {
            try
            {
                this.dbus.update_activation_environment(dbus_env);
            }
            catch ( GLib.IOError e ) {}
            try
            {
                this.systemd.unset_and_set_environment(unset_env, set_env);
            }
            catch ( GLib.IOError e ) {}
        }

        public string
        get_version()
        {
            return Config.PACKAGE_VERSION;
        }

        [DBus (signature = "a{o(ba{ss})}")]
        public GLib.Variant
        get_sessions()
        {
            var r = new GLib.VariantBuilder((GLib.VariantType) "a{o(ba{ss})}");
            var i = GLib.HashTableIter<string, Session>(this.sessions);
            unowned string path;
            Session session;
            while ( i.next(out path, out session) )
                r.add("{o(ba{ss})}", path, session.active, session.get_environment_as_variant());
            return r.end();
        }
    }
}

static GLib.MainLoop loop;
void
on_bus_acquired(GLib.DBusConnection connection)
{
    try
    {
        connection.register_object(SessionNanny.object_path, new SessionNanny.Nanny());
    }
    catch ( GLib.IOError e )
    {
        GLib.warning("Could not register service");
        loop.quit();
    }
}

void
on_name_acquired()
{
    GLib.debug("D-Bus name acquired");
}

void
on_name_lost()
{
    GLib.debug("D-Bus name lost");
    loop.quit();
}

int
main()
{
    loop = new GLib.MainLoop();

    GLib.Bus.own_name(GLib.BusType.SESSION, SessionNanny.bus_name, BusNameOwnerFlags.NONE, on_bus_acquired, on_name_acquired, on_name_lost);

    loop.run();

    return 0;
}
