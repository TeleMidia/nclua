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

-- Make a simple HTTP request using the TCP API and print the response.

local assert = assert
local coroutine = coroutine
local os = os
local print = print
local tonumber = tonumber

local canvas = canvas
local event = event
local tcp = assert (require 'tcp')

_ENV = nil

-- Screen size.
local WIDTH, HEIGHT = canvas:attrSize ()
assert (
   event.register (
      function (e)
         if e.name == 'width' then
            WIDTH = tonumber (e.value)
         elseif e.name == 'height' then
            HEIGHT = tonumber (e.value)
         end
      end,
      {class='ncl', type='attribution', action='start'}
   )
)

-- Colors (background, foreground, and footer).
local BG_COLOR, FG_COLOR, FT_COLOR = 'black', 'lime', 'blue'
canvas:attrColor (BG_COLOR)
canvas:clear ()

-- Font.
canvas:attrFont ('monospace', 12)

local function normalize (s)
   return s:gsub ('\r', '')
end

local function clamp (x, min, max)
   if x < min then return min end
   if x > max then return max end
   return x
end

-- Main.
tcp.execute (
   function ()
      local text = 'Connecting to server...'
      local w, h = canvas:measureText (text)
      canvas:attrColor (FG_COLOR)
      canvas:drawText ((WIDTH - w)/2, (HEIGHT - h)/2, text)
      canvas:flush ()

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
      local body = assert (normalize (buf:sub (j + 1)))

      -- Collect body.
      local length = tonumber (buf:match ('Content%-Length:%s*(%d+)'))
      assert (length > 0)
      repeat
         body = body .. normalize (assert (tcp.receive ()))
      until #body >= length
      body = body:sub (1, length) -- trim
      tcp.disconnect ()

      -- Print body.
      local pages = {{text='', height=0}}
      local i = 1
      for line in body:gmatch ('(.-\n)') do
         local w, h = canvas:measureText (line)
         if pages[i].height + h > HEIGHT then
            i = i + 1
            pages[i] = {text=line, height=h}
         else
            pages[i].text = pages[i].text..line
            local _, height = canvas:measureText (pages[i].text)
            pages[i].height = height
         end
      end
      local co = assert (coroutine.running ())
      local CURRENT_PAGE = 1
      event.register (
         function (e)
            if e.key == 'q' then -- done
               event.post {
                  class='ncl',
                  type='presentation',
                  action='stop',
                  label='',
               }
               return true      -- consume
            end
            if e.key == 'PAGE_UP' or e.key == 'BACKSPACE'
               or e.key == 'CURSOR_UP' then
               CURRENT_PAGE = clamp (CURRENT_PAGE - 1, 1, #pages)
            elseif e.key == 'PAGE_DOWN' or e.key == 'SPACE'
               or e.key == 'CURSOR_DOWN' then
               CURRENT_PAGE = clamp (CURRENT_PAGE + 1, 1, #pages)
            elseif e.key == 'HOME' then
               CURRENT_PAGE = 1
            elseif e.key == 'END' then
               CURRENT_PAGE = #pages
            end
            canvas:attrColor (BG_COLOR)
            canvas:clear ()
            canvas:attrColor (FG_COLOR)
            canvas:drawText (0, 0, pages[CURRENT_PAGE].text)

            -- Print footer.
            local text = ("Press <UP>/<DOWN> to scroll or 'q' to quit -- %d%%")
               :format (CURRENT_PAGE * 100 / #pages)
            local w, h = canvas:measureText (text)
            canvas:attrColor (FT_COLOR)
            canvas:drawText (0, HEIGHT - h, text)
            canvas:flush ()

            coroutine.resume (co)
         end,
         {class='key', type='press'}
      )
      event.post ('in', {class='key', type='press', key='ENTER'})
      while true do
         coroutine.yield ()
      end
   end
)
