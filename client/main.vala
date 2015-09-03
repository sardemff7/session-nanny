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

namespace Logind
{
    public static const string bus_name = "org.freedesktop.login1";
    public static const string object_path = "/org/freedesktop/login1";

    [DBus (name = "org.freedesktop.login1.Manager")]
    interface Manager : GLib.DBusProxy
    {
        public abstract void get_session(string id, out GLib.ObjectPath path) throws GLib.IOError;
    }
}

namespace SessionNanny
{
    public static const string bus_name = "net.sardemff7.SessionNanny";
    public static const string object_path = "/net/sardemff7/SessionNanny";

    [DBus (name = "net.sardemff7.SessionNanny")]
    interface Nanny : GLib.Object
    {
        public abstract void update_environment(GLib.ObjectPath session_path, GLib.HashTable<string, string> environment) throws GLib.IOError;
        public abstract string get_version() throws GLib.IOError;
        [DBus (signature = "a{o(ba{ss})}")]
        public abstract GLib.Variant get_sessions() throws GLib.IOError;
    }

    class Baby
    {
        public static inline void
        add_var(GLib.HashTable<string, string> env, string @var)
        {
            var val = GLib.Environment.get_variable(@var);
            if ( val != null )
                env.insert(@var, val);
        }
        private static bool display = false;
        private static bool show_version = false;
        private static const GLib.OptionEntry[] options = {
                { "display", 'd', 0, GLib.OptionArg.NONE, ref display, "Display sessions", null },
                { "version", 'V', 0, GLib.OptionArg.NONE, ref show_version, "Print version", null },
                { null }
            };

        public static int
        main(string[] args)
        {
            var option_context = new GLib.OptionContext(" [VARIABLE...] - Get session-nanny something to take care of");
            option_context.add_main_entries(options, SessionNanny.Config.GETTEXT_PACKAGE);
            try
            {
                option_context.parse(ref args);
            }
            catch ( GLib.OptionError e )
            {
                GLib.warning("Couldn't parse command line options: %s", e.message);
                return 1;
            }

            SessionNanny.Nanny nanny;
            try
            {
                nanny = GLib.Bus.get_proxy_sync(BusType.SESSION, SessionNanny.bus_name, SessionNanny.object_path);
            }
            catch ( GLib.IOError e )
            {
                GLib.warning("Couldn't connect to session-nanny: %s", e.message);
                return 10;
            }


            if ( show_version )
            {
                string nanny_version = "[unavailable]";
                try
                {
                    nanny_version = nanny.get_version();
                }
                catch ( GLib.IOError e )
                {
                    GLib.warning("Couldn't get session-nanny version: %s", e.message);
                }
                GLib.print("session-baby %s (session-nanny %s)\n", SessionNanny.Config.PACKAGE_VERSION, nanny_version);
                return 0;
            }

            if ( display )
            {
                try
                {
                    var sessions = nanny.get_sessions();
                    foreach ( var session in sessions )
                    {
                        unowned string path;
                        bool active;
                        GLib.VariantIter env;
                        session.get("{&o(ba{ss})}", out path, out active, out env);

                        GLib.print("Session %s%s", path, active ? " (active)" : "");

                        unowned string @var;
                        unowned string val;
                        while ( env.next("{&s&s}", out @var, out val) )
                            GLib.print("\n    %-20s = %s", @var, val);
                        GLib.print("\n--\n");
                    }
                }
                catch ( GLib.IOError e )
                {
                    GLib.warning("Couldn't get session-nanny version: %s", e.message);
                }
                return 0;
            }

            var env = new GLib.HashTable<string, string>(GLib.str_hash, GLib.str_equal);
            try
            {
                Logind.Manager logind = GLib.Bus.get_proxy_sync(BusType.SYSTEM, Logind.bus_name, Logind.object_path);

                var id = GLib.Environment.get_variable("XDG_SESSION_ID");
                GLib.ObjectPath session_path;
                logind.get_session(id, out session_path);

                var config_file = GLib.Path.build_filename(GLib.Environment.get_user_config_dir(), Config.PACKAGE_NAME, "environment", null);
                if ( GLib.FileUtils.test(config_file, GLib.FileTest.EXISTS|GLib.FileTest.IS_REGULAR) )
                {
                    try
                    {
                        string contents;
                        GLib.FileUtils.get_contents(config_file, out contents);
                        foreach ( var @var in contents.split_set(" \n") )
                        {
                            if ( @var != "" )
                                add_var(env, @var);
                        }
                    }
                    catch ( GLib.FileError e )
                    {

                    }
                }
                foreach ( var @var in args[1:args.length] )
                    add_var(env, @var);
                nanny.update_environment(session_path, env);
            }
            catch ( GLib.IOError e )
            {

            }

            return 0;
        }
    }
}
