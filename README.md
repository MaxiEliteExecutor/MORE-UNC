# MORE-UNC
UNC Environment Check

✅ - Pass, ⛔ - Fail, ⏺️ - No test, ⚠️ - Missing aliases

✅ cache.invalidate

✅ cache.iscached

✅ cache.replace

⛔ cloneref failed: Players.Player.PlayerGui.LocalScript:803: Clone should have updated the original

✅ compareinstances

✅ checkcaller

✅ clonefunction

⏺️ getcallingscript

⛔ getscriptclosure failed: The current thread cannot access 'CoreGui' (lacking capability Plugin)

⛔ hookfunction failed: Players.Player.PlayerGui.LocalScript:880: Function should return false

⚠️ replaceclosure

✅ iscclosure

✅ islclosure
⛔ isexecutorclosure failed: Players.Player.PlayerGui.LocalScript:896: Did not return true for an executor global

⛔ loadstring failed: Players.Player.PlayerGui.LocalScript:907: Luau bytecode not supported

✅ newcclosure

⏺️ rconsoleclear

⏺️ rconsolecreate

⏺️ rconsoledestroy

⏺️ rconsoleinput

⏺️ rconsoleprint

⏺️ rconsolesettitle

✅ crypt.base64encode

✅ crypt.base64decode

✅ crypt.encrypt

✅ crypt.decrypt

✅ crypt.generatebytes

✅ crypt.generatekey

✅ crypt.hash

⛔ debug.getconstant

⛔ debug.getconstants

⛔ debug.getinfo

⛔ debug.getproto

⛔ debug.getprotos

⛔ debug.getstack

⛔ debug.getupvalue

⛔ debug.getupvalues

⛔ debug.setconstant

⛔ debug.setstack

⛔ debug.setupvalue

✅ readfile

✅ listfiles

✅ writefile

✅ makefolder

✅ appendfile

✅ isfile

✅ isfolder

✅ delfolder

✅ delfile

⛔ loadfile failed: Players.Player.PlayerGui.LocalScript:1193: assertion failed!

⏺️ dofile

✅ isrbxactive

⏺️ mouse1click

⏺️ mouse1press

⏺️ mouse1release

⏺️ mouse2click

⏺️ mouse2press

⏺️ mouse2release

⏺️ mousemoveabs

⏺️ mousemoverel

⏺️ mousescroll

✅ fireclickdetector

⛔ getcallbackvalue failed: Players.Player.PlayerGui.LocalScript:1237: Did not return the correct value

⛔ getconnections failed: Players.Player.PlayerGui.LocalScript:1257: Did not return a table with a 'Function' field

✅ getcustomasset

✅ gethiddenproperty

✅ sethiddenproperty

✅ gethui

✅ getinstances

✅ getnilinstances

✅ isscriptable

⛔ setscriptable failed: Players.Player.PlayerGui.LocalScript:1307: Did not set the scriptable property

⏺️ setrbxclipboard

⛔ getrawmetatable failed: Players.Player.PlayerGui.LocalScript:1319: Did not return the metatable

⛔ hookmetamethod failed: Players.Player.PlayerGui.LocalScript:29: attempt to index string with '__index'

⛔ getnamecallmethod failed: Players.Player.PlayerGui.LocalScript:1339: Did not get the correct method (GetService)

✅ isreadonly

⛔ setrawmetatable failed: Players.Player.PlayerGui.LocalScript:296: cannot change a protected metatable

⛔ setreadonly failed: attempt to modify a readonly table

✅ identifyexecutor • Returns version as a string

✅ lz4compress

✅ lz4decompress

⏺️ messagebox

⏺️ queue_on_teleport

✅ request • User-Agent: TestExecutor/1.0

⏺️ setclipboard

✅ getgc

✅ getgenv

✅ getloadedmodules

✅ getrenv

✅ getrunningscripts

✅ getscriptbytecode

⛔ getscripthash failed: The current thread cannot call 'GetHash' (lacking capability LocalUser)

✅ getscripts

✅ getsenv

✅ getthreadidentity

✅ setthreadidentity

⏺️ Drawing

✅ Drawing.new

✅ Drawing.Fonts

✅ isrenderobj

✅ getrenderproperty

✅ setrenderproperty

✅ cleardrawcache

⏺️ WebSocket

✅ WebSocket.connect

✅ setfpscap • 38fps @60 • 46fps @0

UNC Summary

✅ Tested with a 69% success rate (57 out of 83)

⛔ 26 tests failed

⚠️ 1 globals are missing aliases
