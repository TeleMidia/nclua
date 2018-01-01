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

assert (event.register (function (e) assert (event.post ('out', e)) end))

function echo (...)
   io.stdout:write (...)
end

function dump (evt)
   if type (evt) ~= 'table' then
      echo (evt)
      return
   end
   local keys = {}
   for k,v in pairs (evt) do
      keys[#keys+1] = k
   end
   local n = #keys
   table.sort (keys)
   echo ('{')
   for i=1,n-1 do
      echo (keys[i]..'=\"'..evt[keys[i]]..'\", ')
   end
   if n > 0 then
      echo (keys[n]..'=\"'..evt[keys[n]]..'\"')
   end
   echo ('}')
end
