--[[ nclua.event.check -- Auxiliary functions for Event plugins.
     Copyright (C) 2013-2018 PUC-Rio/Laboratorio TeleMidia

This file is part of NCLua.

NCLua is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 of the License, or
(at your option) any later version.

NCLua is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
License for more details.

You should have received a copy of the GNU General Public License
along with NCLua.  If not, see <https://www.gnu.org/licenses/>.  ]]--

local check = {}

local error = error
local ipairs = ipairs
local tonumber = tonumber
local tostring = tostring
local type = type
_ENV = nil

-- Error message templates.
local ERR_BAD             = "bad %s '%s' (%s)"
local ERR_BAD_TYPE        = "%s expected, got %s"
local ERR_BAD_OPTION      = "invalid option '%s'"
local ERR_ARG_PREFIX      = 'argument'
local ERR_EVENT_PREFIX    = 'event field'
do
   check.ERR_ARG_PREFIX   = ERR_ARG_PREFIX
   check.ERR_EVENT_PREFIX = ERR_EVENT_PREFIX
end

---
-- Throws an error.
--
function check.throw_bad (prefix, name, fmt, ...)
   error (((ERR_BAD):format (prefix, name, fmt)):format (...), 0)
end

---
-- Throws a "bad type" error.
--
function check.throw_bad_type (prefix, name, exp, got)
   return check.throw_bad (prefix, name, ERR_BAD_TYPE, exp, got)
end

---
-- Throws a "bad option" error.
--
function check.throw_bad_option (prefix, name, got)
   return check.throw_bad (prefix, name, ERR_BAD_OPTION, got)
end

---
-- Checks if VALUE is a boolean.  If DEF is given, then assumes that VALUE
-- is optional and that its default value is DEF.  Returns boolean VALUE if
-- successful, otherwise throws an error.
--
function check.boolean (prefix, name, value, def)
   local value = value or def
   local t = type (value)
   if t == 'boolean' then
      return value
   else
      return check.throw_bad_type (prefix, name, 'boolean', t)
   end
end

---
-- Checks if VALUE is a function.  If DEF is given, then assumes that VALUE
-- is optional and that its default value is DEF.  Returns function VALUE if
-- successful,  otherwise throws an error.
--
function check.func (prefix, name, value, def)
   local value = value or def
   local t = type (value)
   if t == 'function' then
      return value
   else
      return check.throw_bad_type (prefix, name, 'function', t)
   end
end

---
-- Checks if VALUE is a number.  If DEF is given, then assumes that VALUE is
-- optional and that its default value is DEF.  Returns number VALUE if
-- successful, otherwise throws an error.
--
function check.number (prefix, name, value, def)
   local value = value or def
   local t = type (value)
   if t == 'number' or (t == 'string' and tonumber (value) ~= nil) then
      return tonumber (value)
   else
      return check.throw_bad_type (prefix, name, 'number', t)
   end
end

---
-- Checks if VALUE is a supported string option (the supported options must
-- be listed in array LIST).  If DEF is given, then assumes that VALUE is
-- optional and that its default value is DEF.  Returns string VALUE if
-- successful, otherwise throws an error.
--
function check.option (prefix, name, value, list, def)
   local value = check.string (prefix, name, value, def)
   for _,str in ipairs (list) do
      if value == str then
         return value
      end
   end
   return check.throw_bad_option (prefix, name, value)
end

---
-- Checks if VALUE a string.  If DEF is given, then assumes that VALUE is
-- optional and that its default value is DEF.  Returns string VALUE if
-- successful, otherwise throws an error.
--
function check.string (prefix, name, value, def)
   local value = value or def
   local t = type (value)
   if t == 'string' or t == 'number' then
      return tostring (value)
   else
      check.throw_bad_type (prefix, name, 'string', t)
   end
end

---
-- Checks if VALUE is a table.  If DEF is given, then assumes that VALUE is
-- optional and that its default value is DEF.  Returns table VALUE if
-- successful, otherwise throws an error.
--
function check.table (prefix, name, value, def)
   local value = value or def
   local t = type (value)
   if t == 'table' then
      return value
   else
      check.throw_bad_type (prefix, name, 'table', t)
   end
end

-- Build specific check functions.

local function build_check_functions (prefix)
   local wrap = function (f)
      return function (...) return f (prefix, ...) end
   end
   local t = {}
   t.boolean          = wrap (check.boolean)
   t.func             = wrap (check.func)
   t.number           = wrap (check.number)
   t.option           = wrap (check.option)
   t.string           = wrap (check.string)
   t.table            = wrap (check.table)
   t.throw_bad        = wrap (check.throw_bad)
   t.throw_bad_option = wrap (check.throw_bad_option)
   t.throw_bad_type   = wrap (check.throw_bad_type)
   return t
end

do
   check.arg = build_check_functions (ERR_ARG_PREFIX)
   check.event = build_check_functions (ERR_EVENT_PREFIX)
end

return check
