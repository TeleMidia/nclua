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

-- Written by Guilherme F. Lima.

-- TODO: Add support to re-entrant http.get() calls.

local http = {}

local assert = assert
local pairs = pairs
local tonumber = tonumber

local tcp = require ('tcp')
_ENV = nil

local function normalize (s)
   return s:gsub ('\r', '')
end

local function clamp (x, min, max)
   if x < min then return min end
   if x > max then return max end
   return x
end

local function http_get_request_string (server, path, headers, body)
   local s = ('GET %s HTTP/1.1\nHost: %s'):format (path, server)
   for k,v in pairs (headers or {}) do
      k = k:gsub ('[\r\n]', '')
      v = v:gsub ('[\r\n', '')
      s = s .. ('%s: %s\n'):format (k, v)
   end
   return s .. '\n\n' .. (body or '')
end

function http.get (uri, headers, body, callback)
   local schema, server, path = uri:match ('^(%w+://)(.-)(/.*)$')
   tcp.execute (
      function ()
         local status
         local errmsg

         assert (schema == 'http://',
                 ("unsupported schema '%s'"):format (schema))

         -- Connect to server.
         status, errmsg = tcp.connect (server, 80, 5)
         if status == false then
            return callback (status, errmsg)
         end

         -- Send request.
         local req = http_get_request_string (server, path)
         status, errmsg = tcp.send (req)
         if status == false then
            return callback (status, errmsg)
         end

         -- Collect response header.
         local buf = ''
         local init, i, j, tries = 1, nil, nil, 50
         repeat
            local s, errmsg = tcp.receive ()
            if status == false then
               return callback (s, errmsg)
            end
            buf = buf .. s
            i, j = buf:find ('\r\n\r\n', init, true)
            tries = tries - 1
            init = init - 2
            if init < 1 then
               init = 1
            end
         until (i ~= nil and j ~= nil) or tries == 0
         if tries == 0 then
            return callback (false, 'cannot find end of HTTP header')
         end

         local header = assert (normalize (buf:sub (1, i - 1)))
         local body = assert (normalize (buf:sub (j + 1)))

         -- Collect body
         local length = tonumber (buf:match ('Content%-Length:%s*(%d+)'))
         if length <= 0 then
            return callback (true, uri, header, '')
         end
         while #body < length do
            local s, errmsg = tcp.receive ()
            if s == false then
               return callback (s, errmsg)
            end
            body = body .. normalize (s)
         end
         body = body:sub (1, length) -- trim
         tcp.disconnect ()

         return callback (true, uri, header, body)
      end
   )
end

return http
