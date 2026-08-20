/*
 *     Copyright (C) 2026 Gab Nikumura (Nanoid modifications)
 *     Copyright (C) 2026 Valeri Gokadze (original work)
 *
 *     Nanoid is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     Nanoid is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *
 *     For more information about Nanoid, including how to contribute,
 *     please visit: https://github.com/gabcodingapp-dev/Nanoid
 */

Map<String, dynamic> cloneMap(Map source) {
  return Map<String, dynamic>.from(source);
}

List<Map<String, dynamic>> cloneMaps(Iterable<Map> sources) {
  return sources.map(cloneMap).toList();
}
