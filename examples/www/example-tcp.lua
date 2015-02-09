--[[ Copyright (C) 2013-2015 PUC-Rio/Laboratorio TeleMidia

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
along with NCLua.  If not, see <http://www.gnu.org/licenses/>.  ]]--

-- Makes a simple HTTP request using the basic TCP API and
-- outputs the received header and content on stdout.

local assert = assert
local print = print
local tonumber = tonumber

local event = event
local tcp = assert (require 'tcp')

_ENV = nil

local function normalize (s)
   return s:gsub ('\r', '')
end

local function separator (text)
   local maxcol = 76
   if #text >= maxcol then return text end
   local pad = ('-'):rep ((maxcol - #text)/2)
   return pad..text..pad
end

tcp.execute (
   function ()

      -- Connect to server.
      assert (tcp.connect ('www.telemidia.puc-rio.br', 80))

      -- Send request.
      assert (tcp.send ([[
GET /~gflima/ HTTP/1.1
Host: www.telemidia.puc-rio.br
Accept: text/html
Accept-Language: en-US,en
Accept-Encoding: identity

]]))

      -- Collect header.
      local buf = ''
      local init, i, j, tries = 1, nil, nil, 50
      repeat
         buf = buf .. assert (tcp.receive ())
         i, j = buf:find ('\r\n\r\n', init, true)
         tries = tries - 1
         init = init - 2
         if init < 1 then
            init = 1
         end
      until (i ~= nil and j ~= nil) or tries == 0
      if tries == 0 then
         print ('error: cannot find HTTP header, giving up')
         os.exit (1)
      end

      local header = assert (normalize (buf:sub (1, i - 1)))
      local content = assert (normalize (buf:sub (j + 1)))

      -- Collect content.
      local length = tonumber (buf:match ('Content%-Length:%s*(%d+)'))
      repeat
         content = content .. normalize (assert (tcp.receive ()))
      until #content >= length
      content = content:sub (1, length) -- trim

      -- Print content.
      print (separator ('Begin Header'))
      print (header)
      print (separator ('End Header'))
      print (separator ('Begin Content'))
      print (content)
      print (separator ('End Content'))
      tcp.disconnect ()

      -- Done.
      event.post {class='ncl', type='presentation', action='stop', label=''}
   end
)
