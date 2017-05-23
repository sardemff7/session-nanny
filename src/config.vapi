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
    [CCode (cprefix = "", lower_case_cprefix = "", cheader_filename = "config.h")]
    namespace Config
    {
        public const string GETTEXT_PACKAGE;
        public const string PACKAGE_NAME;
        public const string PACKAGE_VERSION;
}
}
