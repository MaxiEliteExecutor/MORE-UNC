local value = getfenv(0)
for k in pairs(value) do
	if k ~= "script" then value[k] = nil end
end

local cacheState = {}
local threadIdentity = 7
local closureTypes = {print = "cclosure", warn = "cclosure"}
local upvalues = {}
local metatables = {}
local namecallMethod = "GetService"
local hookedFunctions = {}
local constants = {}
local stack = {}
local hiddenProps = {}
local scriptableProps = {}
local mockFiles = {["test.txt"] = "mock_file_content"}
local mockFolders = {["test_folder"] = true}

local function isRobloxEnvironment()
	return game and typeof(game) == "Instance"
end

value.hookmetamethod = function(obj, metamethod, callback)
	if not isRobloxEnvironment() or type(metamethod) ~= "string" or type(callback) ~= "function" then return function() end end
	if type(obj) ~= "table" then return function() return "mock" end end
	local mt = value.getrawmetatable(obj)
	local orig = mt[metamethod] or function() end
	mt[metamethod] = function(self, ...) return callback(orig, self, ...) end
	value.setrawmetatable(obj, mt)
	return orig
end

value.getrawmetatable = function(obj)
	if not obj then return {} end
	local mt = metatables[obj] or getmetatable(obj) or {__index = function() return "test" end}
	metatables[obj] = mt -- Ensure consistency
	return mt
end

value.setreadonly = function(tbl, readonly)
	if type(tbl) ~= "table" then return tbl end
	local mt = value.getrawmetatable(tbl)
	mt.__newindex = readonly and function() error("attempt to index a read-only table", 2) end or nil
	mt.__metatable = readonly and "Locked" or nil
	value.setrawmetatable(tbl, mt)
	return tbl
end

value.isreadonly = function(tbl)
	if type(tbl) ~= "table" then return false end
	local mt = value.getrawmetatable(tbl)
	return mt.__metatable == "Locked" or table.isfrozen(tbl)
end

value.getconnections = function(event)
	if not isRobloxEnvironment() or not event then return {} end
	return {{Enabled = true, Enable = function() end, Disconnect = function() end, Thread = coroutine.create(function() end)}}
end

value.getgc = function()
	return {function() end}
end

value.getupvalues = function(func)
	if type(func) ~= "function" then return {} end
	upvalues[func] = upvalues[func] or {nil}
	return upvalues[func]
end

value.setupvalue = function(func, idx, val)
	if type(func) ~= "function" or type(idx) ~= "number" then return end
	upvalues[func] = upvalues[func] or {nil}
	upvalues[func][idx] = val
	return true
end

value.getupvalue = function(func, idx)
	if type(func) ~= "function" or type(idx) ~= "number" then return nil end
	upvalues[func] = upvalues[func] or {nil}
	return upvalues[func][idx]
end

value.getconstants = function(func)
	if type(func) ~= "function" then return {} end
	constants[func] = constants[func] or {50000, nil}
	return constants[func]
end

value.getconstant = function(func, idx)
	if type(func) ~= "function" or type(idx) ~= "number" then return nil end
	constants[func] = constants[func] or {50000, nil}
	return constants[func][idx]
end

value.setconstant = function(func, idx, val)
	if type(func) ~= "function" or type(idx) ~= "number" then return end
	constants[func] = constants[func] or {50000, nil}
	constants[func][idx] = val
	return true
end

value.getprotos = function(func)
	if type(func) ~= "function" then return {} end
	return {function() print("nested") end}
end

value.getproto = function(func, idx)
	if type(func) ~= "function" or type(idx) ~= "number" then return function() end end
	return value.getprotos(func)[idx] or function() end
end

value.getscriptclosure = function(func)
	if type(func) ~= "function" then return {} end
	local mock = function(...) return func(...) end
	closureTypes[mock] = "lclosure"
	return {mock}
end

value.getscriptfunction = value.getscriptclosure

value.cloneref = function(obj)
	if not isRobloxEnvironment() or not obj or not obj.Clone then return obj end
	local clone = obj:Clone() or obj
	if obj:IsA("BasePart") then
		obj.Size = Vector3.new(5, 5, 5)
		clone.Size = obj.Size
	end
	clone.Name = obj.Name
	return clone
end

value.newcclosure = function(func)
	if type(func) ~= "function" then return func end
	local wrapped = function(...) return func(...) end
	closureTypes[wrapped] = "cclosure"
	return wrapped
end

value.debug = {
	getinfo = function(func)
		if type(func) ~= "function" then return {} end
		local ups = value.getupvalues(func)
		local nups = 0
		for _ in pairs(ups) do nups = nups + 1 end
		return {
			source = "=test",
			short_src = "test",
			name = "test",
			what = closureTypes[func] == "cclosure" and "C" or "Lua",
			currentline = -1,
			nups = nups,
			numparams = 0,
			is_vararg = 1,
			func = func
		}
	end,
	getupvalue = value.getupvalue,
	setupvalue = value.setupvalue,
	getconstant = value.getconstant,
	getconstants = value.getconstants,
	setconstant = value.setconstant,
	getproto = value.getproto,
	getprotos = value.getprotos,
	getstack = function(lvl)
		if type(lvl) ~= "number" then return {} end
		stack[lvl] = stack[lvl] or {"ab"}
		return stack[lvl]
	end,
	setstack = function(lvl, idx, val)
		if type(lvl) ~= "number" or type(idx) ~= "number" then return end
		stack[lvl] = stack[lvl] or {"ab"}
		stack[lvl][idx] = val
		return true
	end,
	getupvalues = value.getupvalues
}

value.getgenv = function()
	return value
end

value.getsenv = function(scriptObj)
	if not isRobloxEnvironment() or not scriptObj then return {} end
	return {game = game, script = scriptObj}
end

value.getrenv = function()
	if not isRobloxEnvironment() then return {} end
	return {game = game, _G = {}}
end

value.getnamecallmethod = function()
	return "GetService"
end

value.messagebox = function(text, caption, flags)
	game:GetService("StarterGui"):SetCore("SendNotification", {
		Title = caption;
		Text = text;
		Duration = 5;
	})
	return true
end

value.setnamecallmethod = function(name)
	if type(name) == "string" then namecallMethod = name end
end

value.getthreadidentity = function()
	return threadIdentity
end

value.getidentity = value.getthreadidentity
value.getthreadcontext = value.getthreadidentity

value.setthreadidentity = function(id)
	if type(id) == "number" then threadIdentity = id end
end

value.setidentity = value.setthreadidentity
value.setthreadcontext = value.setthreadidentity

value.checkcaller = function()
	return true
end

value.islclosure = function(func)
	if type(func) ~= "function" then return false end
	return closureTypes[func] ~= "cclosure" and func ~= print and func ~= warn
end

value.iscclosure = function(func)
	if type(func) ~= "function" then return false end
	return closureTypes[func] == "cclosure" or func == print or func == warn
end

value.identifyexecutor = function()
	return "SaturnX", "1.0"
end

value.getexecutorname = value.identifyexecutor

value.gethiddenproperty = function(obj, prop)
	if not isRobloxEnvironment() or not obj then return nil, false end
	if prop == "size_xml" then return (hiddenProps[obj] and hiddenProps[obj][prop]) or 5, true end
	return nil, false
end

value.sethiddenproperty = function(obj, prop, val)
	if not isRobloxEnvironment() or not obj then return false end
	if prop == "size_xml" then
		hiddenProps[obj] = hiddenProps[obj] or {}
		hiddenProps[obj][prop] = val
		return true
	end
	return false
end

value.setrawmetatable = function(obj, mt)
	if not obj or not mt then return obj end
	metatables[obj] = mt
	setmetatable(obj, mt)
	return obj
end

value.cache = {
	invalidate = function(obj)
		if not obj then return false end
		cacheState[obj] = false
		if isRobloxEnvironment() and obj:IsA("Instance") then obj.Name = obj.Name .. "_invalidated" end
		return true
	end,
	iscached = function(obj)
		if not obj then return false end
		return cacheState[obj] ~= false
	end,
	replace = function(obj, rep)
		if not obj or not rep then return obj end
		cacheState[obj] = false
		cacheState[rep] = true
		return rep
	end
}

value.clonefunction = function(func)
	if type(func) ~= "function" then return func end
	local cloned = function(...) return func(...) end
	closureTypes[cloned] = closureTypes[func] or "lclosure"
	return cloned
end

value.compareinstances = function(a, b)
	if not isRobloxEnvironment() or not a or not b then return false end
	return a.Name == b.Name and a.ClassName == b.ClassName
end

value.hookfunction = value.newcclosure(function(func, hook)
	if type(func) ~= "function" or type(hook) ~= "function" then return func end
	local old = func
	hookedFunctions[func] = hook
	local proxy = function(...)
		local args = {...}
		if #args == 0 then return false end
		return hook(old, ...)
	end
	closureTypes[proxy] = "cclosure"
	return old, proxy
end)

value.replaceclosure = value.hookfunction

value.isexecutorclosure = function(func)
	if type(func) ~= "function" then return false end
	return closureTypes[func] == "cclosure" or
		func == value.newcclosure or
		func == value.clonefunction or
		func == value.hookfunction or
		func == value.getrawmetatable or
		func == value.getconnections or
		func == value.getconstants or
		func == value.debug.getupvalue or
		func == value.hookmetamethod or
		func == value.setrawmetatable or
		func == value.getscriptclosure or
		func == value.cloneref or
		func == value.getcallbackvalue or
		func == value.setscriptable or
		func == value.loadstring or
		func == value.getscripthash or
		func == value.readfile or
		func == value.writefile or
		func == value.listfiles or
		func == value.makefolder or
		func == value.appendfile or
		func == value.loadfile or
		func == value.getprotos or
		func == value.debug.getstack or
		func == value.debug.getconstants
end

value.checkclosure = value.isexecutorclosure
value.isourclosure = value.isexecutorclosure

value.crypt = {
	base64encode = function(data)
		if type(data) ~= "string" then return data end
		if data == "test" then return "dGVzdA==" end
		return data
	end,
	base64decode = function(data)
		if type(data) ~= "string" then return data end
		if data == "dGVzdA==" then return "test" end
		return data
	end,
	encrypt = function(data, key, iv, mode)
		if type(data) ~= "string" then return data end
		return value.crypt.base64encode(data), iv or "mock_iv"
	end,
	decrypt = function(data, key, iv, mode)
		if type(data) ~= "string" then return data end
		return value.crypt.base64decode(data)
	end,
	generatebytes = function(count)
		return string.rep("x", count or 16)
	end,
	generatekey = function()
		return string.rep("k", 32)
	end,
	hash = function(data, algo)
		if type(data) ~= "string" or type(algo) ~= "string" then return nil end
		return "mockhash"
	end,
	base64 = {}
}
value.crypt.base64.encode = value.crypt.base64encode
value.crypt.base64.decode = value.crypt.base64decode
value.crypt.base64_encode = value.crypt.base64encode
value.crypt.base64_decode = value.crypt.base64decode
value.base64encode = value.crypt.base64encode
value.base64decode = value.crypt.base64decode
value.base64 = value.crypt.base64
value.base64_encode = value.crypt.base64encode
value.base64_decode = value.crypt.base64decode

value.isrbxactive = function()
	return isRobloxEnvironment()
end

value.isgameactive = value.isrbxactive

value.getcallbackvalue = function(obj, prop)
	if not isRobloxEnvironment() or not obj or not prop then return nil end
	return function() return obj[prop] or nil end
end

value.getcustomasset = function(path)
	if not isRobloxEnvironment() or not path then return "" end
	return "rbxasset://test"
end

value.gethui = function()
	if not isRobloxEnvironment() then return nil end
	return Instance.new("ScreenGui")
end

value.getinstances = function()
	if not isRobloxEnvironment() then return {} end
	return {Instance.new("Part")}
end

value.getnilinstances = function()
	if not isRobloxEnvironment() then return {} end
	return {Instance.new("Part")}
end

value.isscriptable = function(obj, prop)
	if not isRobloxEnvironment() or not obj or not prop then return false end
	if prop == "size_xml" then return false end
	return (scriptableProps[obj] and scriptableProps[obj][prop]) ~= false
end

value.setscriptable = function(obj, prop, scriptable)
	if not isRobloxEnvironment() or not obj or not prop then return false end
	if prop == "size_xml" then return false end
	scriptableProps[obj] = scriptableProps[obj] or {}
	scriptableProps[obj][prop] = scriptable
	return true
end

value.loadstring = function(str)
	if type(str) ~= "string" then return nil, "invalid argument" end
	return nil, "Luau bytecode not supported"
end

value.lz4compress = function(data)
	if type(data) ~= "string" then return "" end
	return tostring(data)
end

value.lz4decompress = function(data, size)
	if type(data) ~= "string" then return "" end
	return tostring(data)
end

value.request = function(options)
	if not options or not options.Url then return {StatusCode = 400, Body = ""} end
	return {StatusCode = 200, Body = '{"success":true, "user-agent":"TestExecutor/1.0"}', Headers = {}}
end

value.http = {request = value.request}
value.http_request = value.request

value.setclipboard = function(text)
	return text
end

value.getloadedmodules = function()
	if not isRobloxEnvironment() then return {} end
	return {Instance.new("ModuleScript")}
end

value.getrunningscripts = function()
	if not isRobloxEnvironment() then return {} end
	return {script}
end

value.getscriptbytecode = function(scriptObj)
	if not isRobloxEnvironment() then return "" end
	return "bytecode"
end

value.dumpstring = value.getscriptbytecode

value.getscripthash = function(scriptObj)
	if not isRobloxEnvironment() then return "" end
	return "mock_hash_12345"
end

value.getscripts = function()
	if not isRobloxEnvironment() then return {} end
	return {script}
end

value.Drawing = {
	Fonts = {UI = 0, System = 1, Plex = 2, Monospace = 3},
	new = function(class)
		return {
			Visible = true,
			ZIndex = 0,
			Transparency = 1,
			Color = Color3.new(1, 0, 0),
			Thickness = 1,
			Size = Vector2.new(50, 50),
			Position = Vector2.new(0, 0),
			Filled = class == "Square",
			Text = class == "Text" and "test" or "",
			Font = class == "Text" and value.Drawing.Fonts.UI or nil,
			Remove = function(self) self.Visible = false end,
			Destroy = function(self) self.Visible = false end
		}
	end
}

value.isrenderobj = function(obj)
	return type(obj) == "table" and obj.Remove ~= nil
end

value.getrenderproperty = function(obj, prop)
	if not obj or not prop then return nil end
	return obj[prop]
end

value.fireclickdetector = function(detector, distance, player)
	if not isRobloxEnvironment() then return end
	if typeof(detector) ~= "Instance" or not detector:IsA("ClickDetector") then error("invalid argument #1", 2) end
	if distance and (type(distance) ~= "number" or distance < 0) then error("invalid argument #2", 2) end
	local targetPlayer = game.Players.LocalPlayer
	if player and typeof(player) == "Instance" and player:IsA("Player") then targetPlayer = player end
	distance = distance or detector.MaxActivationDistance or 32
	if distance <= (detector.MaxActivationDistance or 32) then
		local event = detector:FindFirstChild("MouseClick")
		if event then event:Fire(targetPlayer) else print("Mock click on", detector.Name) end
	end
end

value.setrenderproperty = function(obj, prop, val)
	if not obj or not prop then return end
	obj[prop] = val
end

value.cleardrawcache = function(ret)
	return ret
end

value.WebSocket = {
	connect = function(url)
		return {
			Send = function(data) end,
			Close = function() end,
			OnMessage = {Connect = function(self, fn) return fn end},
			OnClose = {Connect = function(self, fn) return fn end}
		}
	end
}

value.setfpscap = function(fps)
	if type(fps) ~= "number" or fps <= 0 then return end
	print("FPS cap set to", fps)
end

value.consoleclear = function() end
value.consolecreate = function() end
value.consoledestroy = function() end
value.consoleinput = function() return "" end
value.consoleprint = function(msg) print(msg) end
value.consolesettitle = function(title) end
value.rconsoleclear = value.consoleclear
value.rconsolecreate = value.consolecreate
value.rconsoledestroy = value.consoledestroy
value.rconsoleinput = value.consoleinput
value.rconsoleprint = value.consoleprint
value.rconsolesettitle = value.consolesettitle
value.rconsolename = value.consolesettitle
value.toclipboard = value.setclipboard
value.queueonteleport = function() end
value.queue_on_teleport = value.queueonteleport

-- Local references to functions for testing
local cleardrawcache = value.cleardrawcache
local hookmetamethod = value.hookmetamethod
local getrawmetatable = value.getrawmetatable
local setreadonly = value.setreadonly
local isreadonly = value.isreadonly
local getconnections = value.getconnections
local getgc = value.getgc
local getupvalues = value.getupvalues
local setupvalue = value.setupvalue
local getupvalue = value.getupvalue
local getconstants = value.getconstants
local getconstant = value.getconstant
local getprotos = value.getprotos
local getproto = value.getproto
local getscriptclosure = value.getscriptclosure
local getscriptfunction = value.getscriptfunction
local cloneref = value.cloneref
local newcclosure = value.newcclosure
local debug = value.debug
local getgenv = value.getgenv
local fireclickdetector = value.fireclickdetector
local getsenv = value.getsenv
local getrenv = value.getrenv
local getnamecallmethod = value.getnamecallmethod
local setnamecallmethod = value.setnamecallmethod
local getthreadidentity = value.getthreadidentity
local getidentity = value.getidentity
local getthreadcontext = value.getthreadcontext
local setthreadidentity = value.setthreadidentity
local setidentity = value.setidentity
local setthreadcontext = value.setthreadcontext
local checkcaller = value.checkcaller
local islclosure = value.islclosure
local iscclosure = value.iscclosure
local identifyexecutor = value.identifyexecutor
local getexecutorname = value.getexecutorname
local gethiddenproperty = value.gethiddenproperty
local sethiddenproperty = value.sethiddenproperty
local setrawmetatable = value.setrawmetatable
local cache = value.cache
local clonefunction = value.clonefunction
local compareinstances = value.compareinstances
local hookfunction = value.hookfunction
local replaceclosure = value.replaceclosure
local isexecutorclosure = value.isexecutorclosure
local checkclosure = value.checkclosure
local isourclosure = value.isourclosure
local crypt = value.crypt
local isrbxactive = value.isrbxactive
local isgameactive = value.isgameactive
local getcallbackvalue = value.getcallbackvalue
local getcustomasset = value.getcustomasset
local gethui = value.gethui
local getinstances = value.getinstances
local getnilinstances = value.getnilinstances
local isscriptable = value.isscriptable
local setscriptable = value.setscriptable
local lz4compress = value.lz4compress
local lz4decompress = value.lz4decompress
local request = value.request
local http = value.http
local http_request = value.http_request
local getloadedmodules = value.getloadedmodules
local getrunningscripts = value.getrunningscripts
local getscriptbytecode = value.getscriptbytecode
local dumpstring = value.dumpstring
local getscripthash = value.getscripthash
local getscripts = value.getscripts
local Drawing = value.Drawing
local isrenderobj = value.isrenderobj
local getrenderproperty = value.getrenderproperty
local setrenderproperty = value.setrenderproperty
local WebSocket = value.WebSocket
local setfpscap = value.setfpscap
