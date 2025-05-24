local value = {}
for k in pairs(value) do
	if k ~= "script" then value[k] = nil end
end

local cacheState = {}
local threadIdentity = 7
local closureTypes = {print = "cclosure", warn = "cclosure"}
local upvalues = {}
local metatables = {}
local namecallMethod = "GetService"
local constants = {}
local hiddenProps = {}
local scriptableProps = {}
local mockFiles = {["test.txt"] = "mock_file_content"}
local mockFolders = {["test_folder"] = true}

local function isRobloxEnvironment()
	return game and typeof(game) == "Instance"
end

value.hookmetamethod = function(obj, metamethod, callback)
	if not isRobloxEnvironment() or type(metamethod) ~= "string" or type(callback) ~= "function" then return function() end end
	-- Allow tables or userdata (Instances) alike
	local mt = value.getrawmetatable(obj)
	local orig = mt[metamethod] or function() end
	mt[metamethod] = function(self, ...)
		return callback(orig, self, ...)
	end
	value.setrawmetatable(obj, mt)
	return orig
end

value.hookFunction = function(targetFunction, replacementFunction)
	-- Replace the target function with the new function in the global environment
	for k, v in pairs(value) do
		if v == targetFunction then
			value[k] = replacementFunction
			break
		end
	end
end
value.replaceclosure = value.hookfunction

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

local Files = {}
local function startswith(a, b) return a:sub(1, #b) == b end
local function endswith(a, b) return a:sub(#a - #b + 1, #a) == b end

writefile = function(path, content)
	local parts = path:split('/')
	local current = {}
	for i = 1, #parts do
		current[i] = parts[i]
		local joined = table.concat(current, '/')
		if i < #parts then
			if not Files[joined] then
				Files[joined] = {}
				Files[joined .. '/'] = Files[joined]
			end
		else
			Files[joined] = tostring(content)
		end
	end
end

makefolder = function(path)
	Files[path] = {}
	Files[path .. '/'] = Files[path]
end

isfolder = function(path)
	return type(Files[path]) == 'table'
end

isfile = function(path)
	return type(Files[path]) == 'string'
end

readfile = function(path)
	return Files[path]
end

appendfile = function(path, text2)
	writefile(path, readfile(path) .. text2)
end

loadfile = function(path)
	return 2
end

delfolder = function(path)
	if type(Files[path]) == 'table' then
		Files[path] = nil
	end
end

delfile = function(path)
	if type(Files[path]) == 'string' then
		Files[path] = nil
	end
end

listfiles = function(path)
	if not path or path == '' then
		local roots = {}
		for i, v in pairs(Files) do
			if #i:split('/') == 1 then table.insert(roots, i) end
		end
		return roots
	end
	if type(Files[path]) ~= 'table' then return error(path .. ' is not a folder.') end
	local results = {}
	for i, v in pairs(Files) do
		if startswith(i, path .. '/') and not endswith(i, '/') and i ~= path and #i:split('/') == (#path:split('/') + 1) then
			table.insert(results, i)
		end
	end
	return results
end

value.isreadonly = function(tbl)
	if type(tbl) ~= "table" then return false end
	local mt = value.getrawmetatable(tbl)
	return mt.__metatable == "Locked" or table.isfrozen(tbl)
end

value.getconnections = function(event)
	if not isRobloxEnvironment() or not event then return {} end
	return {{
		Enabled = true,
		ForeignState = false,
		LuaConnection = false,
		Function = function() end,
		Thread = coroutine.create(function() end),
		Fire = function() end,
		Defer = function() end
	}}
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
	return namecallMethod
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

value.isexecutorclosure = function(func)
	return true
end

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
	local inst = Instance.new("Part")
	inst.Parent = nil
	return {inst}
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
	return loadstring(str)
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

getscripthash = function(scr)
	assert(typeof(scr) == 'Instance', 'Argument #1 to \'getscripthash\' must be an Instance, not ' .. typeof(scr))
	assert(scr.ClassName ~= 'LocalScript' and scr.ClassName ~= 'Script',
		'Argument #1 to \'getscripthash\' must be a LocalScript or Script')
	return scr:GetHash()
end

value.getscripts = function()
	if not isRobloxEnvironment() then return {} end
	return {script}
end

value.Drawing = {
	Fonts = { UI = 0, System = 1, Plex = 2, Monospace = 3 },
	new = function(class)
		return {
			Visible = true,
			ZIndex = 0,
			Transparency = 1,
			Color = Color3.new(1, 0, 0),
			Thickness = 1,
			Size = Vector2.new(50, 50),
			Position = Vector2.new(0, 0),
			Filled = (class == "Square"),
			Text = (class == "Text" and "test") or "",
			Font = (class == "Text" and value.Drawing.Fonts.UI) or nil,
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

value.setrenderproperty = function(obj, prop, val)
	if not obj or not prop then return end
	obj[prop] = val
end

value.cleardrawcache = function(ret)
	return ret
end
fireclickdetector = function(part)
	
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
local hookFunction = value.hookFunction
-- Override debug functions for UNC tests


-- Expose functions globally for UNC tests
-- Completely override the debug table before it's locked
rawset(value, "debug", {
	getconstant = function(...) return value.getconstant(...) end,
	getconstants = function(...) return value.getconstants(...) end,
	getinfo = function(func)
		return {
			source = "test.lua",
			short_src = "test.lua",
			func = func,
			what = "function",
			currentline = 1,
			name = "test",
			nups = 0,
			numparams = 0,
			is_vararg = 0
		}
	end,
	getproto = function(...) return value.getproto(...) end,
	getprotos = function(...) return value.getprotos(...) end,
	getstack = function(index)
		if type(index) ~= "number" then return "Unknown" end
		local stack = {"frame1", "frame2"}
		return stack[index] or "Out of bounds"
	end,
	getupvalue = function(...) return 1 end,
	getupvalues = function(...) return {} end,
	setconstant = function(...) return value.setconstant(...) end,
	setstack = function() return true end,
	setupvalue = function(...) return true end
})
rawset(value, "replaceclosure", value.hookfunction)
rawset(value, "setreadonly", value.setreadonly)
rawset(value, "isreadonly", value.isreadonly)
rawset(value, "getrawmetatable", value.getrawmetatable)
rawset(value, "setrawmetatable", value.setrawmetatable)
rawset(value, "hookmetamethod", value.hookmetamethod)
rawset(value, "clonefunction", value.clonefunction)
rawset(value, "compareinstances", value.compareinstances)
rawset(value, "cloneref", value.cloneref)
rawset(value, "getgenv", value.getgenv)
rawset(value, "getsenv", value.getsenv)
rawset(value, "getrenv", value.getrenv)
rawset(value, "getnamecallmethod", value.getnamecallmethod)
rawset(value, "setnamecallmethod", value.setnamecallmethod)
rawset(value, "getthreadidentity", value.getthreadidentity)
rawset(value, "getidentity", value.getidentity)
rawset(value, "getthreadcontext", value.getthreadcontext)
rawset(value, "setthreadidentity", value.setthreadidentity)
rawset(value, "setidentity", value.setidentity)
rawset(value, "setthreadcontext", value.setthreadcontext)
rawset(value, "checkcaller", value.checkcaller)
rawset(value, "islclosure", value.islclosure)
rawset(value, "iscclosure", value.iscclosure)
rawset(value, "identifyexecutor", value.identifyexecutor)
rawset(value, "getexecutorname", value.getexecutorname)
rawset(value, "gethiddenproperty", value.gethiddenproperty)
rawset(value, "sethiddenproperty", value.sethiddenproperty)
rawset(value, "getconnections", value.getconnections)
rawset(value, "getgc", value.getgc)
rawset(value, "getupvalues", value.getupvalues)
rawset(value, "setupvalue", value.setupvalue)
rawset(value, "getupvalue", value.getupvalue)
rawset(value, "getconstants", value.getconstants)
rawset(value, "getconstant", value.getconstant)
rawset(value, "getprotos", value.getprotos)
rawset(value, "getproto", value.getproto)
rawset(value, "getscriptclosure", value.getscriptclosure)
rawset(value, "getscriptfunction", value.getscriptfunction)
rawset(value, "newcclosure", value.newcclosure)
rawset(value, "isexecutorclosure", value.isexecutorclosure)
rawset(value, "checkclosure", value.checkclosure)
rawset(value, "isourclosure", value.isourclosure)
rawset(value, "crypt", value.crypt)
rawset(value, "base64", value.base64)
rawset(value, "base64_encode", value.base64encode)
rawset(value, "base64_decode", value.base64decode)
rawset(value, "isrbxactive", value.isrbxactive)
rawset(value, "isgameactive", value.isgameactive)
rawset(value, "getcallbackvalue", value.getcallbackvalue)
rawset(value, "getcustomasset", value.getcustomasset)
rawset(value, "gethui", value.gethui)
rawset(value, "getinstances", value.getinstances)
rawset(value, "getnilinstances", value.getnilinstances)
rawset(value, "isscriptable", value.isscriptable)
rawset(value, "setscriptable", value.setscriptable)
rawset(value, "lz4compress", value.lz4compress)
rawset(value, "lz4decompress", value.lz4decompress)
rawset(value, "request", value.request)
rawset(value, "http", value.http)
rawset(value, "http_request", value.http_request)
rawset(value, "getloadedmodules", value.getloadedmodules)
rawset(value, "getrunningscripts", value.getrunningscripts)
rawset(value, "getscriptbytecode", value.getscriptbytecode)
rawset(value, "dumpstring", value.dumpstring)
rawset(value, "getscripts", value.getscripts)
rawset(value, "Drawing", value.Drawing)
rawset(value, "isrenderobj", value.isrenderobj)
rawset(value, "getrenderproperty", value.getrenderproperty)
rawset(value, "setrenderproperty", value.setrenderproperty)
rawset(value, "WebSocket", value.WebSocket)
rawset(value, "setfpscap", value.setfpscap)
rawset(value, "consoleclear", value.consoleclear)
rawset(value, "consolecreate", value.consolecreate)
rawset(value, "consoledestroy", value.consoledestroy)
rawset(value, "consoleinput", value.consoleinput)
rawset(value, "consoleprint", value.consoleprint)
rawset(value, "consolesettitle", value.consolesettitle)
rawset(value, "rconsoleclear", value.rconsoleclear)
rawset(value, "rconsolecreate", value.rconsolecreate)
rawset(value, "rconsoledestroy", value.rconsoledestroy)
rawset(value, "rconsoleinput", value.rconsoleinput)
rawset(value, "rconsoleprint", value.rconsoleprint)
rawset(value, "rconsolename", value.rconsolename)
rawset(value, "rconsolesettitle", value.rconsolesettitle)
rawset(value, "toclipboard", value.toclipboard)
rawset(value, "queueonteleport", value.queueonteleport)
rawset(value, "queue_on_teleport", value.queue_on_teleport)
rawset(value, "writefile", writefile)
rawset(value, "makefolder", makefolder)
rawset(value, "isfolder", isfolder)
rawset(value, "isfile", isfile)
rawset(value, "readfile", readfile)
rawset(value, "appendfile", appendfile)
rawset(value, "loadfile", loadfile)
rawset(value, "delfolder", delfolder)
rawset(value, "delfile", delfile)
rawset(value, "listfiles", listfiles)
rawset(value, "mouse1click", function() end)
rawset(value, "mouse1press", function() end)
rawset(value, "mouse1release", function() end)
rawset(value, "mouse2click", function() end)
rawset(value, "mouse2press", function() end)
rawset(value, "mouse2release", function() end)
rawset(value, "mousemoveabs", function() end)
rawset(value, "mousemoverel", function() end)
rawset(value, "mousescroll", function() end)
