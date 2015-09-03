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

namespace DBus
{
    public static const string bus_name = "org.freedesktop.DBus";
    public static const string object_path = "/org/freedesktop/DBus";

    [DBus (name = "org.freedesktop.DBus")]
    interface DBus : GLib.DBusProxy
    {
        public abstract void update_activation_environment([DBus (signature = "a{ss}")] GLib.Variant environment) throws GLib.IOError;
    }
}

namespace Systemd
{
    public static const string bus_name = "org.freedesktop.systemd1";
    public static const string object_path = "/org/freedesktop/systemd1";

    [DBus (name = "org.freedesktop.systemd1.Manager")]
    interface Manager : GLib.DBusProxy
    {
        public abstract void unset_and_set_environment(string[] unset, string[] @set) throws GLib.IOError;
    }
}

namespace Logind
{
    public static const string bus_name = "org.freedesktop.login1";
    public static const string object_path = "/org/freedesktop/login1";

    [DBus (name = "org.freedesktop.login1.Manager")]
    interface Manager : GLib.DBusProxy
    {
        public signal void session_new(string session_id, GLib.ObjectPath session_path);
        public signal void session_removed(string session_id, GLib.ObjectPath session_path);
    }

    [DBus (name = "org.freedesktop.login1.Session")]
    public interface Session : GLib.DBusProxy
    {
        public abstract string id { owned get; private set; }
        [DBus (signature = "(uo)")]
        public abstract GLib.Variant user { owned get; private set; }
        [DBus (name = "Name")]
        public abstract string name { owned get; private set; }
        [DBus (name = "Active")]
        public abstract bool active { get; private set; }
    }
}
