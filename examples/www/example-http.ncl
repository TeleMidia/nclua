<?xml version="1.0" encoding="utf-8"?>
<!-- Copyright (C) 2013-2018 PUC-Rio/Laboratorio TeleMidia

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
along with NCLua.  If not, see <https://www.gnu.org/licenses/>.  -->

<ncl id="example-http">
  <head>
    <regionBase>
      <region id="luaRegion" width="100%" height="100%"/>
    </regionBase>
    <descriptorBase>
      <descriptor id="luaDesc" region="luaRegion" focusIndex="luaIdx"/>
    </descriptorBase>
  </head>
  <body>
    <port id="init" component="lua"/>
    <media type="application/x-ginga-settings" id="programSettings">
      <property name="currentKeyMaster" value="luaIdx"/>
    </media>
    <media id="lua" descriptor="luaDesc" src="example-http.lua"/>
  </body>
</ncl>
