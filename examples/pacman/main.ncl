<?xml version="1.0" encoding="utf-8"?>
<!-- $Id: main.ncl,v 1.1 2009/03/11 12:41:42 root Exp $ -->
<!--
    main.ncl
    11mar2009, gflima@telemidia.puc-rio.br

    Pacman for Ginga-NCL!
  -->

<ncl id="pacman">
  <head>
    <regionBase>
      <region id="rgLua" top="0" left="0" width="100%"  height="100%"
              zIndex="1" />
    </regionBase>

    <descriptorBase>
      <descriptor id="dLua" region="rgLua" focusIndex="0" />
    </descriptorBase>
  </head>

  <body>
    <port id="start" component="lua" />
    <media type="application/x-ginga-settings" id="settings">
      <property name="service.currentKeyMaster" value="lua"/>
    </media>
    <media id="lua" src="game.lua" descriptor="dLua" />
  </body>
</ncl>
