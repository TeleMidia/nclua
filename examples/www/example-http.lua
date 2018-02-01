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

-- Make HTTP requests using the HTTP API and print the responses.

local assert = assert
local coroutine = coroutine
local ipairs = ipairs
local math = math
local os = os
local pairs = pairs
local print = print
local tonumber = tonumber

local canvas = canvas
local event = event
local http = assert (require 'http')
_ENV = nil

-- List of URIs to be displayed.
local URIs = {
   'https://github.com/telemidia/nclua/raw/master/NEWS',
   'https://github.com/telemidia/nclua/raw/master/TODO',
   'https://github.com/telemidia/nclua/raw/master/AUTHORS',
   'http://laws.deinf.ufma.br/404', -- expect a 404
}

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

-- Colors.
local BG_COLOR = 'black'        -- background
local FG_COLOR = 'lime'         -- foreground
local FT_COLOR = 'yellow'       -- footer
local function clear ()
   canvas:attrColor (BG_COLOR)
   canvas:clear ()
   canvas:attrColor (FG_COLOR)
end
clear ()

-- Font.
canvas:attrFont ('monospace', 12)

-- Maximum line height.
local STRUT = canvas:measureText ('()')

local function clamp (x, min, max)
   if x < min then return min end
   if x > max then return max end
   return x
end

http.execute (
   function ()
      for _,uri in ipairs (URIs) do
         local text = ("Fetching %s..."):format (uri)
         local w,h = canvas:measureText (text)
         clear ()
         local family, size, style = canvas:attrFont ()
         canvas:attrColor (FT_COLOR)
         canvas:attrFont (family, size, 'bold')
         canvas:attrColor (FT_COLOR)
         canvas:drawText ((WIDTH - w)/2, (HEIGHT - h)/2, text)
         canvas:attrFont (family, size, style)
         canvas:flush ()

         -- Fetch URI.
         local headers = {
            ['Accept'] = 'plain/text',
            ['X-foo'] = 'bar',
         }
         local body = '...request body goes here...'
         local status, code, headers, body = http.get (uri, headers, body)
         if status == false then
            print (('error: %s'):format (code))
            os.exit (1)
         end

         -- Print the response.
         local header = ('HTTP Code: %d -- %s'):format (code, uri)
         local footer = "Press <UP>/<DOWN> to scroll or 'q' to quit"
         local text = ''
         for k,v in pairs (headers) do
            text = text..('%s: %s\n'):format (k,v)
         end
         text = text..'\n'..body
         local pages = {{text='', height=0}}
         for line in text:gmatch ('(.-\n)') do
            if pages[#pages].height + STRUT > HEIGHT - (STRUT * 2) then
               pages[#pages+1] = {text='', height=h}
            else
               local t = pages[#pages]
               t.text = t.text..line
               local _, h = canvas:measureText (t.text)
               t.height = h
            end
         end

         local CURRENT_PAGE = 1
         local redraw = function ()
            clear ()
            local family, size, style = canvas:attrFont ()
            canvas:attrColor (FT_COLOR)
            canvas:attrFont (family, size, 'bold')
            canvas:drawText (0, 0, header)
            local perc = (' -- %d%%')
               :format (math.floor (CURRENT_PAGE * 100 / #pages))
            canvas:drawText (0, HEIGHT - STRUT, footer..perc)
            canvas:attrFont (family, size, style)
            canvas:attrColor (FG_COLOR)
            canvas:drawText (0, STRUT, pages[CURRENT_PAGE].text)
            canvas:attrColor (FT_COLOR)
            canvas:flush ()
         end
         redraw ()

         local co = assert (coroutine.running ())
         local handler = function (e)
            if e.key == 'q' then -- done
               event.post {
                  class='ncl',
                  type='presentation',
                  action='stop',
                  label='',
               }
               return true
            end
            if e.key == 'PAGE_UP' or e.key == 'BACKSPACE'
               or e.key == 'CURSOR_UP' then
               CURRENT_PAGE = clamp (CURRENT_PAGE - 1, 1, #pages)
            elseif e.key == 'PAGE_DOWN' or e.key == 'SPACE'
               or e.key == 'CURSOR_DOWN' then
               if CURRENT_PAGE == #pages then
                  coroutine.resume (co)
                  return true
               else
                  CURRENT_PAGE = clamp (CURRENT_PAGE + 1, 1, #pages)
               end
            elseif e.key == 'HOME' then
               CURRENT_PAGE = 1
            elseif e.key == 'END' then
               CURRENT_PAGE = #pages
            end
            redraw ()
            return true
         end
         event.register (handler, {class='key', type='press'})
         coroutine.yield ()
         event.unregister (handler)
      end
      event.post {
         class='ncl',
         type='presentation',
         action='stop',
         label='',
      }
   end
)
