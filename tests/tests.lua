--[[ Copyright (C) 2013-2018 PUC-Rio/Laboratorio TeleMidia

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

local tests = {}

local assert = assert
local debug = debug
local error = error
local getmetatable = getmetatable
local io = io
local ipairs = ipairs
local math = math
local os = os
local pairs = pairs
local pcall = pcall
local print = print
local setmetatable = setmetatable
local string = string
local table = table
local tostring = tostring
local type = type

---
-- Fail-safe require.
--
local function optrequire (name)
   local t = {pcall (require, name)}
   if t[1] == false then
      return nil, t[2]
   else
      return table.unpack (t, 2)
   end
end
tests.optrequire = optrequire

local tests0 = require ('tests0')
local canvas = require ('nclua.canvas')
local socket = optrequire ('nclua.event.tcp_socket')
local soup = optrequire ('nclua.event.http_soup')
local stopwatch = require ('nclua.event.stopwatch')
_ENV = nil

-- Export some Makefile variables.
do
   local match = {
      '_VALGRIND',
      'abs_builddir',
      'abs_srcdir',
      'abs_top_builddir',
      'abs_top_srcdir',
      'build_os',
      'builddir',
      'srcdir',
      'top_builddir',
      'top_srcdir',
   }
   for i,s in ipairs (match) do
      match[i] = nil
      match[s] = true
   end
   tests.mk = {}
   local file = assert (io.open ('Makefile'))
   for s in file:lines () do
      local k,v = s:match ('^([%w_]+)%s*=%s-(%S.-)%s-$')
      if k ~= nil and match[k] then
         tests.mk[k] = v
      end
   end
end

---
-- Returns true if we're on FreeBSD.
--
function tests.is_freebsd ()
   return tests.mk.build_os:match ('^freebsd.*$') ~= nil
end

---
-- Returns true if we're on Linux.
--
function tests.is_linux ()
   return tests.mk.build_os:match ('^linux.*$') ~= nil
end

---
-- Returns true if we're on Windows.
--
function tests.is_windows ()
   return tests.mk.build_os:match ('^mingw.*$') ~= nil
end

---
-- Checks if each of its arguments evaluates to true.
-- Returns its arguments if successful, otherwise throws an error.
--
function tests.ASSERT (...)
   local args = {...}
   local n = tests.maxi (args)
   for i=1,n do
      if not args[i] then
         local no = ''
         if n > 1 then
            no = ' #'..i
         end
         error (('assertion%s failed!'):format (no), 2)
      end
   end
   return table.unpack (args, 1, n)
end

---
-- Checks if the call FUNC(...) throws an error.
-- Returns true if successful, otherwise throws an error.
--
function tests.ASSERT_ERROR (func, ...)
   if type (func) ~= 'function' then
      error (("bad argument 'func' (function expected got %s)")
                :format (type (func)), 2)
   end
   if pcall (func, ...) then
      error ("error expected!", 2)
   end
   return true
end

---
-- Checks if table MOD contains the data specified in SIG.
-- Returns true if successful, otherwise throws an error.
--
function tests.ASSERT_CHECK_API (args)
   local mod = args[1]
   table.remove (args, 1)
   local sig = args
   if mod.__name ~= nil then
      sig.__name = type (mod.__name)
   end
   for k,v in pairs (mod) do
      if sig[k] == nil then
         error (("extra %s '%s'"):format (type (v), k), 2)
      end
      if type (v) ~= sig[k] then
         error (("bad type for '%s' (%s expected, got %s)")
                   :format (k, sig[k], type (v), 2))
      end
   end
   for k,v in pairs (sig) do
      if mod[k] == nil then
         error (("missing %s '%s'"):format (sig[k], k), 2)
      end
   end
   return true
end

---
-- Checks if userdata object OBJ is of type TNAME.
-- Returns true if successful, otherwise throws an error.
--
function tests.ASSERT_CHECK_OBJECT(obj, tname)
   if (type (obj) == 'table' and tname ~= 'table')
   or type (obj) == 'userdata' and  not tests0.testudata (obj, tname) then
      error (("object %s is not of type %s!")
                :format (tostring (obj), tname), 2)
   end
   if not getmetatable (obj) == 'not your business' then
      error (("object's %s metatable is accessible via getmetatable()")
                :format (tostring (obj)), 2)
   end
   return true
end

---
-- Fail with error message ERRMSG.
--
function tests.FAIL (errmsg)
   error (errmsg or "should not get here", 2)
end

---
-- Dumps the given object to stdout.
--
local function cat (s)
   io.stdout:write (s)
end

local function dump (x, tab)
   if type (x) ~= 'table' then
      cat (tostring (x))
   else
      local tab = tab or 1
      cat ('{\n')
      for k,v in pairs (x) do
         cat (('   '):rep (tab))
         dump (k, tab + 1)
         cat ('=')
         dump (v, tab + 1)
         cat (',\n')
      end
      cat (('   '):rep (tab - 1)..'}')
   end
end

function tests.dump (...)
   local args = {...}
   local n = tests.maxi (args) or 0
   for i=1,n do
      dump (args[i])
      cat ('\n')
   end
end

---
-- Returns the maximum integer index in the given table T.
-- If no index is found, returns nil.
--
function tests.maxi (t)
   local max = nil
   for k,_ in pairs (t) do
      if type (k) == 'number' and (max == nil or k > max) then
         max = k
      end
   end
   return max
end

---
-- Returns true if numbers x and y are equal up to the given threshold.
--
function tests.numeq (x, y, epsilon)
   return math.abs (x - y) <= (epsilon or .0000001)
end

---
-- Returns true if objects X and Y have the same structure.
--
function tests.objeq (x, y)
   if type (x) ~= type (y) then
      return false
   end
   if type (x) ~= 'table' then
      return x == y
   else
      for k,v in pairs (x) do
         if not tests.objeq (v, y[k]) then
            return false
         end
      end
      for k,v in pairs (y) do
         if not tests.objeq (v, x[k]) then
            return false
         end
      end
   end
   return true
end

---
-- Calls the given function N times.
--
function tests.iter (f, n)
   for i=1, (n or 100) do
      f ()
   end
end

---
-- Returns its (i+1)-th argument.
--
function tests.proj (i, ...)
   local args = {...}
   return args[i]
end

---
-- Returns N if N is in the interval [LOWER,UPPER].
-- If LOWER is given and N < LOWER, returns LOWER.
-- If UPPER is given and N > UPPER, returns UPPER.
--
function tests.range (lower, n, upper)
   if lower and n < lower then
      return lower
   elseif upper and n > upper then
      return upper
   else
      return n
   end
end

---
-- Delay for a specified amount of time.
--
do
   tests.sleep = function (s) tests.usleep (s * 10^6) end
   tests.usleep = tests0.usleep
end

---
-- Outputs arguments to stdout prefixed with a time-stamp.
--
function tests.trace (...)
   if tests._stopwatch == nil then
      tests._stopwatch = stopwatch.new ()
      tests._stopwatch:start ()
   end
   print (('[%.2gms]'):format (tests._stopwatch:get_time ('ms')), ...)
end

---
-- Outputs a numbered entry separator.
--
function tests.trace_sep ()
   if tests._trace_sep_number == nil then
      tests._trace_sep_number = 1
   end
   print ('#'..tests._trace_sep_number..'\t'..('-'):rep (70))
   tests._trace_sep_number = tests._trace_sep_number + 1
end


---------------------------- File manipulation  ----------------------------

---
-- Returns the filename part of PATH.
--
function tests.basename (path)
   return path:match ('^.*/([^/]*)$') or path
end

---
-- Returns the directory part of PATH.
--
function tests.dirname (path)
   return path:match ('^(.*)/[^/]*$') or '.'
end

---
-- Concatenate the given arguments to make a path.
--
function tests.mkpath (...)
   return table.concat ({...}, '/')
end

---
-- Wrapper to os.tmpname; it workarounds bogus names returned by
-- os.tmpname() on MinGW.
--
function tests.tmpname ()
   local name = os.tmpname ()
   if tests.is_windows () then
      return name:gsub ('\\', 'xslashx')
   else
      return name
   end
end

---
-- Returns true if PATH points to a directory.
--
do
   tests.dir_exists = tests0.dir_exists
end

---
-- Returns true if PATH points to a regular file.
--
do
   tests.file_exists = tests0.file_exists
end

---
-- Reads FILE and returns its contents as a string.
--
function tests.read_file (file)
   local file = assert (io.open (file, 'rb'))
   local result = ''
   while true do
      local s = file:read ('*a')
      if s == '' then
         break
      end
      result = result..s
   end
   file:close ()
   return result
end

---
-- Writes string STR to file FILE.
--
function tests.write_file (s, file)
   local file = assert (io.open (file, 'wb'))
   assert (file:write (str))
   file:close ()
end


-------------------------- Random data generators --------------------------

-- Initialize Lua PRNG.
do
   math.randomseed (tests0.get_monotonic_time ())
end

local function rand (lower, upper)
   return math.random (lower or -tests0.XRAND0_LIMIT,
                       upper or tests0.XRAND0_LIMIT)
end

local function rand_iterate (n, f, ...)
   local t = {}
   for i=1,(n or 1) do
      table.insert (t, f (...))
   end
   return table.unpack (t)
end

---
-- Return N random boolean values.
--
local function rand_boolean (f_rand)
   return f_rand (0, 1) == 1
end

function tests.rand_boolean (n)
   return rand_iterate (n, rand_boolean, rand)
end

function tests.xrand_boolean (n)
   return rand_iterate (n, rand_boolean, tests0.xrand)
end

---
-- Returns N random color values.
--
local function rand_color (f_rand)
   return f_rand (0, 255)
end

function tests.rand_color (n)
   return rand_iterate (n, rand_color, rand)
end

function tests.xrand_color (n)
   return rand_iterate (n, rand_color, tests0.xrand)
end

---
-- Creates N temporary files with SIZE bytes of random data and returns
-- their names.  Each file must be explicitly removed with os.remove when no
-- longer needed.
--
local function rand_file (f_rand_string, size)
   local tmp = tests.tmpname ()
   local file = assert (io.open (tmp, 'wb'))
   assert (file:write (f_rand_string (size)))
   file:close ()
   return tmp
end

function tests.rand_file (size, n)
   return rand_iterate (n, rand_file, tests.rand_string, size)
end

function tests.xrand_file (size, n)
   return rand_iterate (n, rand_file, tests.xrand_string, size)
end

---
-- Returns N random integers between [UPPER,LOWER].
--
local function rand_integer (f_rand, lower, upper)
   return f_rand (math.floor (lower or 0), math.floor (upper or 1))
end

function tests.rand_integer (lower, upper, n)
   return rand_iterate (n, rand_integer, rand, lower, upper)
end

function tests.xrand_integer (lower, upper, n)
   return rand_iterate (n, rand_integer, tests0.xrand, lower, upper)
end

---
-- Returns N random numbers between [UPPER,LOWER].
--
local function rand_number (f_rand, lower, upper)
   local x = f_rand (math.floor (lower or 0), math.floor (upper or 1))
   if f_rand (0, 1) == 1 then   -- put fraction?
      local frac = math.abs (f_rand ())
      local y = math.floor (math.log (frac, 10) + 1)
      frac = frac / 10^y
      if x > (lower or 0) then
         x = x - frac
      else
         x = x + frac
      end
   end
   return x
end

function tests.rand_number (lower, upper, n)
   return rand_iterate (n, rand_number, rand, lower, upper)
end

function tests.xrand_number (lower, upper, n)
   return rand_iterate (n, rand_number, tests0.xrand, lower, upper)
end

---
-- Returns N random elements from list LIST.
--
local function rand_option (f_rand, list)
   return list[f_rand (1, #list)]
end

function tests.rand_option (list, n)
   return rand_iterate (n, rand_option, rand, list)
end

function tests.xrand_option (list, n)
   return rand_iterate (n, rand_option, tests0.xrand, list)
end

---
-- Returns N random scalar objects; each returned object is either a
-- boolean, integer, number, or string.
--
local function rand_scalar (arg)
   local tname = {'boolean', 'integer', 'number', 'string'}
   local t = tname[arg.integer (1, #tname)]
   return arg[t] ()
end

function tests.rand_scalar (n)
   local arg = {
      boolean=tests.rand_boolean,
      integer=tests.rand_integer,
      number=tests.rand_number,
      ['string']=tests.rand_string,
   }
   return rand_iterate (n, rand_scalar, arg)
end

function tests.xrand_scalar (n)
   local arg = {
      boolean=tests.xrand_boolean,
      integer=tests.xrand_integer,
      number=tests.xrand_number,
      ['string']=tests.xrand_string,
   }
   return rand_iterate (n, rand_scalar, arg)
end

---
-- Returns N random strings, each SIZE bytes long.
--
local function rand_string (f_rand, size)
   local s = ''
   for i=1,(size or 32) do
      s = s..string.char (f_rand (0, 255))
   end
   return s
end

function tests.rand_string (size, n)
   return rand_iterate (n, rand_string, rand, size)
end

function tests.xrand_string (size, n)
   return rand_iterate (n, rand_string, tests0.xrand, size)
end

---
-- Returns N random tables with NELEM pairs of random data and DEPTH level
-- of nested tables.
--
local function _rand_table_get_scalar (f_rand_scalar)
   local x
   repeat
      x = f_rand_scalar ()
   until type (x) ~= 'number' or x == x
   return x
end

local function rand_table (f_rand, f_rand_scalar, nelem, depth)
   local nelem = nelem or 8
   local depth = depth or 4
   local t = {}
   for i=1,nelem do
      local k, v
      if depth >= 1 and f_rand (0, 1) == 1 then
         k = rand_table (f_rand, f_rand_scalar, nelem / 2, depth / 2)
      else
         k = _rand_table_get_scalar (f_rand_scalar)
      end
      if depth >= 1 and f_rand (0, 1) == 1 then
         v = rand_table (f_rand, f_rand_scalar, nelem / 2, depth / 2)
      else
         v = _rand_table_get_scalar (f_rand_scalar)
      end
      t[k] = v
   end
   return t
end

function tests.rand_table (nelem, depth, n)
   return rand_iterate (n, rand_table, rand, tests.rand_scalar, nelem, depth)
end


---------------------------------- CAIRO -----------------------------------

do
   tests.cairo_check_version = tests0.cairo_check_version
   tests.cairo_get_version = tests0.cairo_get_version
   tests.CAIRO_MAJOR, tests.CAIRO_MINOR, tests.CAIRO_MICRO
      = tests.cairo_get_version ()
end


---------------------------------- CANVAS ----------------------------------

do
   tests.canvas = {}
   tests.canvas.intersect = tests0.canvas_intersect
   tests.canvas.surface_equals = tests0.canvas_surface_equals

   -- List containing all possible styles for canvas.drawText.
   local t = {}
   for _, weight in ipairs { 'thin', 'ultralight', 'light', 'book',
                             'normal', 'medium', 'semibold', 'bold',
                             'ultrabold', 'heavy', 'ultraheavy'}
   do
      for _, slant in ipairs {'normal', 'oblique', 'italic'} do
         table.insert (t, weight..'-'..slant)
      end
      tests.canvas.text_style_list = t
   end
end

---
-- Returns a canvas with the default size.
--
function tests.canvas.new ()
   local w, h = 50, 50
   return assert (canvas.new (w, h)), w, h
end

---
-- Clears the given canvas with a transparent color.
--
function tests.canvas.clear (c)
   local r, g, b, a = c:attrColor ()
   c:attrColor (0, 0, 0, 0)
   c:clear ()
   c:attrColor (r, g, b, a)
end

---
-- Returns true if the contents of CANVAS is equal to that of the reference
-- picture with serial SERIAL, otherwise returns false.
--
-- If EPSILON is given, admit difference in EPSILON * 100% of the pixels.
--
local REF_CAIRO_DIRS = {
   ('ref-cairo-%d-%d'):format (tests.CAIRO_MAJOR, tests.CAIRO_MINOR),
   'ref-cairo-any',
}
function tests.canvas.check_ref (canvas, serial, epsilon)
   local s = debug.getinfo (2).short_src
   local root = tests.dirname (s)
   local base = tests.basename (s):gsub ('%.lua', '-'..serial..'-ref.png')
   local path = nil
   for _, dir in ipairs (REF_CAIRO_DIRS) do
      path = tests.mkpath (root, dir, base)
      if tests.file_exists (path) then
         break
      end
   end
   assert (path, path)
   local ref = assert (canvas:new (path), path)
   return tests.canvas.surface_equals (canvas:_surface (),
                                       ref:_surface (),
                                       epsilon or 0)
end

---
-- Dumps a new reference picture with the given serial.
--
function tests.canvas.dump_ref (canvas, serial)
   local s = debug.getinfo (2).short_src
   local root = tests.dirname (s)
   local base = tests.basename (s):gsub ('%.lua', '-'..serial..'-ref.png')
   local path = nil
   for _, dir in ipairs (REF_CAIRO_DIRS) do
      if tests.dir_exists (dir) then
         path = tests.mkpath (root, dir, base)
         break
      end
   end
   assert (path, path)
   tests.trace (('*** DUMPING REF: %s ***'):format (path))
   return assert (canvas:_dump_to_file (path))
end

---
-- Returns the sample PNG image denoted by string S.
--
function tests.canvas.get_sample (s)
   return tests.mk.top_srcdir..'/tests/sample/'..s..'.png'
end


---------------------------------- SERVER ----------------------------------

do
   tests.server = {}
   tests.server.__index = tests.server
   tests.server.__metatable = 'not your business'
end

---
-- Creates a new network server.
--
function tests.server.new (port, args)
   port = port or tests.rand_integer (1986, 9999)
   return setmetatable ({port=port, args=args}, tests.server),
   'localhost', port
end

---
-- Creates a new echo server.
--
function tests.server.new_echo (port, ...)
   return tests.server.new (port, ...)
end

---
-- Creates a new sink server.
--
function tests.server.new_sink (port, ...)
   local args = table.concat ({...}, ' ')
   return tests.server.new (port, '--mode=sink '..args)
end

---
-- Creates a new source server.
--
function tests.server.new_source (port, ...)
   local args = table.concat ({...}, ' ')
   return tests.server.new (port, '--mode=source '..args)
end

---
-- Starts the given network server.
--
function tests.server.start (server)
   -- TODO: Kill server if it's running.
   server.pid = nil
   server.pidfile = tests.tmpname ()
   local str = ('sh %s/server.sh %s --verbose --pid="%s" --port=%d %s')
      :format (tests.mk.srcdir,
               tests.mk.srcdir,
               server.pidfile,
               server.port,
               server.args or '')
   assert (os.execute (str))
   tests.sleep (.5)
   local file = assert (io.open (server.pidfile, 'r'))
   server.pid = assert (file:read ('*n'), 'cannot start server')
   file:close ()
end

---
-- Stops the given network server.
--
function tests.server.stop (server)
   assert (server.pid ~= nil)
   os.execute (("perl -e 'kill \"KILL\", %s;'"):format (server.pid))
   assert (os.remove (server.pidfile))
end


---------------------------------- SOCKET ----------------------------------

do
   tests.socket = {}
end

---
-- Calls socket.cycle () until function FUNC returns true.
--
function tests.socket.cycle_until (func)
   repeat
      socket.cycle ()
      tests.usleep (10^4)       -- 10ms
   until func ()
end


----------------------------------  SOUP  ----------------------------------

do
   tests.soup = {}
end

---
-- Calls soup.cycle () until function FUNC returns true.
--
function tests.soup.cycle_until (func)
   repeat
      soup.cycle ()
      tests.usleep (10^4)       -- 10ms
   until func ()
end

return tests
