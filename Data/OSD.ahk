#SingleInstance Force

RegRead,ZoomIncText,HKCU,Software\WanderSick\AeroZoom,ZoomIncTextOSD
RegRead,ZoomitColor,HKCU,Software\WanderSick\AeroZoom,ZoomitColorOSD
RegRead,SnipMode,HKCU,Software\WanderSick\AeroZoom,SnipModeOSD
RegRead,CaptureDisk,HKCU,Software\WanderSick\AeroZoom,CaptureDiskOSD

if ZoomitColor 
	goto, color
if ZoomIncText 
	goto, zoominc
if SnipMode 
	goto, SnipMode
if CaptureDisk 
	goto, CaptureDisk
	
Exitapp
	
zoominc:
Gui, +LastFound -Caption +ToolWindow +AlwaysOnTop
Gui, Color, EEAA99 ; any color
WinSet, TransColor, EEAA99 165
Gui, Font, s50, Verdana
Gui, Add, Text, cLime, %ZoomIncText%
Gui, Show, w320 h200 x15 y60 AutoSize NoActivate, AeroZoom OSD
Sleep, 700
Exitapp

color:
If (ZoomitColor=1) {
	colorCode=FF0000
	color=Red
} else if (ZoomitColor=2) {
	colorCode=00FF00
	color=Green
} else if (ZoomitColor=3) {
	colorCode=0000FF
	color=Blue
} else if (ZoomitColor=4) {
	colorCode=FFFF00
	color=Yellow
} else if (ZoomitColor=5) {
	colorCode=FF00FF
	color=Pink
} else if (ZoomitColor=6) {
	colorCode=FFCC00
	color=Orange
}
Gui, Color, %colorCode%
Gui, +LastFound -Caption +ToolWindow +AlwaysOnTop
Gui, Font, s40, Verdana
Gui, Add, Text, cWhite, %color%
Gui, Show, Center x25 y25 AutoSize NoActivate, AeroZoom OSD
WinSet, Transparent, 165
Sleep, 700
Exitapp

SnipMode:
If (SnipMode=1) {
	SnipModeText=Free-form
} else if (SnipMode=3) {
	SnipModeText=Window
} else if (SnipMode=4) {
	SnipModeText=Screen
} else {
	SnipModeText=Rectangular
}
Gui, +LastFound -Caption +ToolWindow +AlwaysOnTop
Gui, Color, EEAA99 ; any color
WinSet, TransColor, EEAA99 165
Gui, Font, s45, Verdana
Gui, Add, Text, cLime, %SnipModeText%
Gui, Show, w430 h150 x15 y60 AutoSize NoActivate, AeroZoom OSD
Sleep, 700
Exitapp

CaptureDisk:
If (CaptureDisk=1) {
	CaptureDiskText=Cap2Disk On
} else if (CaptureDisk=2) {
	CaptureDiskText=Cap2Disk Off
}
Gui, +LastFound -Caption +ToolWindow +AlwaysOnTop
Gui, Color, EEAA99 ; any color
WinSet, TransColor, EEAA99 165
Gui, Font, s45, Verdana
Gui, Add, Text, cLime, %CaptureDiskText%
Gui, Show, w430 h150 x15 y60 AutoSize NoActivate, AeroZoom OSD
Sleep, 700
Exitapp