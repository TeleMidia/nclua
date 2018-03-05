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

local function handler (e)
    print ('Event received:')
    for k,v in pairs (e) do
       print (('\t%s:=%s'):format (k,v))

    end
    
    if e["type"] == 'connect' then
        event.post {class='tcp', type='data', connection=e["connection"], value='nclua client message!' }
    end

 end
 
 event.register (handler, {class='tcp'})
 
 event.post {class='tcp', type='connect', host='127.0.0.1', port=47818}
 