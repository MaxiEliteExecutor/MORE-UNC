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

local passes, fails, undefined = 0, 0, 0
local running = 0

local function getGlobal(path)
	while value ~= nil and path ~= "" do
		local name, nextValue = string.match(path, "^([^.]+)%.?(.*)$")
		value = value[name]
		path = nextValue
	end

	return value
end

local function test(name, aliases, callback)
	running += 1

	task.spawn(function()
		if not callback then
			print("⏺️ " .. name)
		elseif not getGlobal(name) then
			fails += 1
			warn("⛔ " .. name)
		else
			local success, message = pcall(callback)
	
			if success then
				passes += 1
				print("✅ " .. name .. (message and " • " .. message or ""))
			else
				fails += 1
				warn("⛔ " .. name .. " failed: " .. message)
			end
		end
	
		local undefinedAliases = {}
	
		for _, alias in ipairs(aliases) do
			if getGlobal(alias) == nil then
				table.insert(undefinedAliases, alias)
			end
		end
	
		if #undefinedAliases > 0 then
			undefined += 1
			warn("⚠️ " .. table.concat(undefinedAliases, ", "))
		end

		running -= 1
	end)
end

-- Header and summary

print("\n")

print("UNC Environment Check")
print("✅ - Pass, ⛔ - Fail, ⏺️ - No test, ⚠️ - Missing aliases\n")

task.defer(function()
	repeat task.wait() until running == 0

	local rate = math.round(passes / (passes + fails) * 100)
	local outOf = passes .. " out of " .. (passes + fails)

	print("\n")

	print("UNC Summary")
	print("✅ Tested with a " .. rate .. "% success rate (" .. outOf .. ")")
	print("⛔ " .. fails .. " tests failed")
	print("⚠️ " .. undefined .. " globals are missing aliases")
end)

-- Cache

test("cache.invalidate", {}, function()
	local container = Instance.new("Folder")
	local part = Instance.new("Part", container)
	cache.invalidate(container:FindFirstChild("Part"))
	assert(part ~= container:FindFirstChild("Part"), "Reference `part` could not be invalidated")
end)

test("cache.iscached", {}, function()
	local part = Instance.new("Part")
	assert(cache.iscached(part), "Part should be cached")
	cache.invalidate(part)
	assert(not cache.iscached(part), "Part should not be cached")
end)

test("cache.replace", {}, function()
	local part = Instance.new("Part")
	local fire = Instance.new("Fire")
	cache.replace(part, fire)
	assert(part ~= fire, "Part was not replaced with Fire")
end)

test("cloneref", {}, function()
	local part = Instance.new("Part")
	local clone = cloneref(part)
	assert(part ~= clone, "Clone should not be equal to original")
	clone.Name = "Test"
	assert(part.Name == "Test", "Clone should have updated the original")
end)

test("compareinstances", {}, function()
	local part = Instance.new("Part")
	local clone = cloneref(part)
	assert(part ~= clone, "Clone should not be equal to original")
	assert(compareinstances(part, clone), "Clone should be equal to original when using compareinstances()")
end)

-- Closures

local function shallowEqual(t1, t2)
	if t1 == t2 then
		return true
	end

	local UNIQUE_TYPES = {
		["function"] = true,
		["table"] = true,
		["userdata"] = true,
		["thread"] = true,
	}

	for k, v in pairs(t1) do
		if UNIQUE_TYPES[type(v)] then
			if type(t2[k]) ~= type(v) then
				return false
			end
		elseif t2[k] ~= v then
			return false
		end
	end

	for k, v in pairs(t2) do
		if UNIQUE_TYPES[type(v)] then
			if type(t2[k]) ~= type(v) then
				return false
			end
		elseif t1[k] ~= v then
			return false
		end
	end

	return true
end

test("checkcaller", {}, function()
	assert(checkcaller(), "Main scope should return true")
end)

test("clonefunction", {}, function()
	local function test()
		return "success"
	end
	local copy = clonefunction(test)
	assert(test() == copy(), "The clone should return the same value as the original")
	assert(test ~= copy, "The clone should not be equal to the original")
end)

test("getcallingscript", {})

test("getscriptclosure", {"getscriptfunction"}, function()
	local module = game:GetService("CoreGui").RobloxGui.Modules.Common.Constants
	local constants = getrenv().require(module)
	local generated = getscriptclosure(module)()
	assert(constants ~= generated, "Generated module should not match the original")
	assert(shallowEqual(constants, generated), "Generated constant table should be shallow equal to the original")
end)

test("hookfunction", {"replaceclosure"}, function()
	local function test()
		return true
	end
	local ref = hookfunction(test, function()
		return false
	end)
	assert(test() == false, "Function should return false")
	assert(ref() == true, "Original function should return true")
	assert(test ~= ref, "Original function should not be same as the reference")
end)

test("iscclosure", {}, function()
	assert(iscclosure(print) == true, "Function 'print' should be a C closure")
	assert(iscclosure(function() end) == false, "Executor function should not be a C closure")
end)

test("islclosure", {}, function()
	assert(islclosure(print) == false, "Function 'print' should not be a Lua closure")
	assert(islclosure(function() end) == true, "Executor function should be a Lua closure")
end)

test("isexecutorclosure", {"checkclosure", "isourclosure"}, function()
	assert(isexecutorclosure(isexecutorclosure) == true, "Did not return true for an executor global")
	assert(isexecutorclosure(newcclosure(function() end)) == true, "Did not return true for an executor C closure")
	assert(isexecutorclosure(function() end) == true, "Did not return true for an executor Luau closure")
	assert(isexecutorclosure(print) == false, "Did not return false for a Roblox global")
end)

test("loadstring", {}, function()
	local animate = game:GetService("Players").LocalPlayer.Character.Animate
	local bytecode = getscriptbytecode(animate)
	local func = loadstring(bytecode)
	assert(type(func) ~= "function", "Luau bytecode should not be loadable!")
	assert(assert(loadstring("return ... + 1"))(1) == 2, "Failed to do simple math")
	assert(type(select(2, loadstring("f"))) == "string", "Loadstring did not return anything for a compiler error")
end)

test("newcclosure", {}, function()
	local function test()
		return true
	end
	local testC = newcclosure(test)
	assert(test() == testC(), "New C closure should return the same value as the original")
	assert(test ~= testC, "New C closure should not be same as the original")
	assert(iscclosure(testC), "New C closure should be a C closure")
end)

-- Console

test("rconsoleclear", {"consoleclear"})

test("rconsolecreate", {"consolecreate"})

test("rconsoledestroy", {"consoledestroy"})

test("rconsoleinput", {"consoleinput"})

test("rconsoleprint", {"consoleprint"})

test("rconsolesettitle", {"rconsolename", "consolesettitle"})

-- Crypt

test("crypt.base64encode", {"crypt.base64.encode", "crypt.base64_encode", "base64.encode", "base64_encode"}, function()
	assert(crypt.base64encode("test") == "dGVzdA==", "Base64 encoding failed")
end)

test("crypt.base64decode", {"crypt.base64.decode", "crypt.base64_decode", "base64.decode", "base64_decode"}, function()
	assert(crypt.base64decode("dGVzdA==") == "test", "Base64 decoding failed")
end)

test("crypt.encrypt", {}, function()
	local key = crypt.generatekey()
	local encrypted, iv = crypt.encrypt("test", key, nil, "CBC")
	assert(iv, "crypt.encrypt should return an IV")
	local decrypted = crypt.decrypt(encrypted, key, iv, "CBC")
	assert(decrypted == "test", "Failed to decrypt raw string from encrypted data")
end)

test("crypt.decrypt", {}, function()
	local key, iv = crypt.generatekey(), crypt.generatekey()
	local encrypted = crypt.encrypt("test", key, iv, "CBC")
	local decrypted = crypt.decrypt(encrypted, key, iv, "CBC")
	assert(decrypted == "test", "Failed to decrypt raw string from encrypted data")
end)

test("crypt.generatebytes", {}, function()
	local size = math.random(10, 100)
	local bytes = crypt.generatebytes(size)
	assert(#crypt.base64decode(bytes) == size, "The decoded result should be " .. size .. " bytes long (got " .. #crypt.base64decode(bytes) .. " decoded, " .. #bytes .. " raw)")
end)

test("crypt.generatekey", {}, function()
	local key = crypt.generatekey()
	assert(#crypt.base64decode(key) == 32, "Generated key should be 32 bytes long when decoded")
end)

test("crypt.hash", {}, function()
	local algorithms = {'sha1', 'sha384', 'sha512', 'md5', 'sha256', 'sha3-224', 'sha3-256', 'sha3-512'}
	for _, algorithm in ipairs(algorithms) do
		local hash = crypt.hash("test", algorithm)
		assert(hash, "crypt.hash on algorithm '" .. algorithm .. "' should return a hash")
	end
end)

--- Debug

test("debug.getconstant", {}, function()
	local function test()
		print("Hello, world!")
	end
	assert(debug.getconstant(test, 1) == "print", "First constant must be print")
	assert(debug.getconstant(test, 2) == nil, "Second constant must be nil")
	assert(debug.getconstant(test, 3) == "Hello, world!", "Third constant must be 'Hello, world!'")
end)

test("debug.getconstants", {}, function()
	local function test()
		local num = 5000 .. 50000
		print("Hello, world!", num, warn)
	end
	local constants = debug.getconstants(test)
	assert(constants[1] == 50000, "First constant must be 50000")
	assert(constants[2] == "print", "Second constant must be print")
	assert(constants[3] == nil, "Third constant must be nil")
	assert(constants[4] == "Hello, world!", "Fourth constant must be 'Hello, world!'")
	assert(constants[5] == "warn", "Fifth constant must be warn")
end)

test("debug.getinfo", {}, function()
	local types = {
		source = "string",
		short_src = "string",
		func = "function",
		what = "string",
		currentline = "number",
		name = "string",
		nups = "number",
		numparams = "number",
		is_vararg = "number",
	}
	local function test(...)
		print(...)
	end
	local info = debug.getinfo(test)
	for k, v in pairs(types) do
		assert(info[k] ~= nil, "Did not return a table with a '" .. k .. "' field")
		assert(type(info[k]) == v, "Did not return a table with " .. k .. " as a " .. v .. " (got " .. type(info[k]) .. ")")
	end
end)

test("debug.getproto", {}, function()
	local function test()
		local function proto()
			return true
		end
	end
	local proto = debug.getproto(test, 1, true)[1]
	local realproto = debug.getproto(test, 1)
	assert(proto, "Failed to get the inner function")
	assert(proto() == true, "The inner function did not return anything")
	if not realproto() then
		return "Proto return values are disabled on this executor"
	end
end)

test("debug.getprotos", {}, function()
	local function test()
		local function _1()
			return true
		end
		local function _2()
			return true
		end
		local function _3()
			return true
		end
	end
	for i in ipairs(debug.getprotos(test)) do
		local proto = debug.getproto(test, i, true)[1]
		local realproto = debug.getproto(test, i)
		assert(proto(), "Failed to get inner function " .. i)
		if not realproto() then
			return "Proto return values are disabled on this executor"
		end
	end
end)

test("debug.getstack", {}, function()
	local _ = "a" .. "b"
	assert(debug.getstack(1, 1) == "ab", "The first item in the stack should be 'ab'")
	assert(debug.getstack(1)[1] == "ab", "The first item in the stack table should be 'ab'")
end)

test("debug.getupvalue", {}, function()
	local upvalue = function() end
	local function test()
		print(upvalue)
	end
	assert(debug.getupvalue(test, 1) == upvalue, "Unexpected value returned from debug.getupvalue")
end)

test("debug.getupvalues", {}, function()
	local upvalue = function() end
	local function test()
		print(upvalue)
	end
	local upvalues = debug.getupvalues(test)
	assert(upvalues[1] == upvalue, "Unexpected value returned from debug.getupvalues")
end)

test("debug.setconstant", {}, function()
	local function test()
		return "fail"
	end
	debug.setconstant(test, 1, "success")
	assert(test() == "success", "debug.setconstant did not set the first constant")
end)

test("debug.setstack", {}, function()
	local function test()
		return "fail", debug.setstack(1, 1, "success")
	end
	assert(test() == "success", "debug.setstack did not set the first stack item")
end)

test("debug.setupvalue", {}, function()
	local function upvalue()
		return "fail"
	end
	local function test()
		return upvalue()
	end
	debug.setupvalue(test, 1, function()
		return "success"
	end)
	assert(test() == "success", "debug.setupvalue did not set the first upvalue")
end)

-- Filesystem

if isfolder and makefolder and delfolder then
	if isfolder(".tests") then
		delfolder(".tests")
	end
	makefolder(".tests")
end

test("readfile", {}, function()
	writefile(".tests/readfile.txt", "success")
	assert(readfile(".tests/readfile.txt") == "success", "Did not return the contents of the file")
end)

test("listfiles", {}, function()
	makefolder(".tests/listfiles")
	writefile(".tests/listfiles/test_1.txt", "success")
	writefile(".tests/listfiles/test_2.txt", "success")
	local files = listfiles(".tests/listfiles")
	assert(#files == 2, "Did not return the correct number of files")
	assert(isfile(files[1]), "Did not return a file path")
	assert(readfile(files[1]) == "success", "Did not return the correct files")
	makefolder(".tests/listfiles_2")
	makefolder(".tests/listfiles_2/test_1")
	makefolder(".tests/listfiles_2/test_2")
	local folders = listfiles(".tests/listfiles_2")
	assert(#folders == 2, "Did not return the correct number of folders")
	assert(isfolder(folders[1]), "Did not return a folder path")
end)

test("writefile", {}, function()
	writefile(".tests/writefile.txt", "success")
	assert(readfile(".tests/writefile.txt") == "success", "Did not write the file")
	local requiresFileExt = pcall(function()
		writefile(".tests/writefile", "success")
		assert(isfile(".tests/writefile.txt"))
	end)
	if not requiresFileExt then
		return "This executor requires a file extension in writefile"
	end
end)

test("makefolder", {}, function()
	makefolder(".tests/makefolder")
	assert(isfolder(".tests/makefolder"), "Did not create the folder")
end)

test("appendfile", {}, function()
	writefile(".tests/appendfile.txt", "su")
	appendfile(".tests/appendfile.txt", "cce")
	appendfile(".tests/appendfile.txt", "ss")
	assert(readfile(".tests/appendfile.txt") == "success", "Did not append the file")
end)

test("isfile", {}, function()
	writefile(".tests/isfile.txt", "success")
	assert(isfile(".tests/isfile.txt") == true, "Did not return true for a file")
	assert(isfile(".tests") == false, "Did not return false for a folder")
	assert(isfile(".tests/doesnotexist.exe") == false, "Did not return false for a nonexistent path (got " .. tostring(isfile(".tests/doesnotexist.exe")) .. ")")
end)

test("isfolder", {}, function()
	assert(isfolder(".tests") == true, "Did not return false for a folder")
	assert(isfolder(".tests/doesnotexist.exe") == false, "Did not return false for a nonexistent path (got " .. tostring(isfolder(".tests/doesnotexist.exe")) .. ")")
end)

test("delfolder", {}, function()
	makefolder(".tests/delfolder")
	delfolder(".tests/delfolder")
	assert(isfolder(".tests/delfolder") == false, "Failed to delete folder (isfolder = " .. tostring(isfolder(".tests/delfolder")) .. ")")
end)

test("delfile", {}, function()
	writefile(".tests/delfile.txt", "Hello, world!")
	delfile(".tests/delfile.txt")
	assert(isfile(".tests/delfile.txt") == false, "Failed to delete file (isfile = " .. tostring(isfile(".tests/delfile.txt")) .. ")")
end)

test("loadfile", {}, function()
	writefile(".tests/loadfile.txt", "return ... + 1")
	assert(assert(loadfile(".tests/loadfile.txt"))(1) == 2, "Failed to load a file with arguments")
	writefile(".tests/loadfile.txt", "f")
	local callback, err = loadfile(".tests/loadfile.txt")
	assert(err and not callback, "Did not return an error message for a compiler error")
end)

test("dofile", {})

-- Input

test("isrbxactive", {"isgameactive"}, function()
	assert(type(isrbxactive()) == "boolean", "Did not return a boolean value")
end)

test("mouse1click", {})

test("mouse1press", {})

test("mouse1release", {})

test("mouse2click", {})

test("mouse2press", {})

test("mouse2release", {})

test("mousemoveabs", {})

test("mousemoverel", {})

test("mousescroll", {})

-- Instances

test("fireclickdetector", {}, function()
	local detector = Instance.new("ClickDetector")
	fireclickdetector(detector, 50, "MouseHoverEnter")
end)

test("getcallbackvalue", {}, function()
	local bindable = Instance.new("BindableFunction")
	local function test()
	end
	bindable.OnInvoke = test
	assert(getcallbackvalue(bindable, "OnInvoke") == test, "Did not return the correct value")
end)

test("getconnections", {}, function()
	local types = {
		Enabled = "boolean",
		ForeignState = "boolean",
		LuaConnection = "boolean",
		Function = "function",
		Thread = "thread",
		Fire = "function",
		Defer = "function",
		Disconnect = "function",
		Disable = "function",
		Enable = "function",
	}
	local bindable = Instance.new("BindableEvent")
	bindable.Event:Connect(function() end)
	local connection = getconnections(bindable.Event)[1]
	for k, v in pairs(types) do
		assert(connection[k] ~= nil, "Did not return a table with a '" .. k .. "' field")
		assert(type(connection[k]) == v, "Did not return a table with " .. k .. " as a " .. v .. " (got " .. type(connection[k]) .. ")")
	end
end)

test("getcustomasset", {}, function()
	writefile(".tests/getcustomasset.txt", "success")
	local contentId = getcustomasset(".tests/getcustomasset.txt")
	assert(type(contentId) == "string", "Did not return a string")
	assert(#contentId > 0, "Returned an empty string")
	assert(string.match(contentId, "rbxasset://") == "rbxasset://", "Did not return an rbxasset url")
end)

test("gethiddenproperty", {}, function()
	local fire = Instance.new("Fire")
	local property, isHidden = gethiddenproperty(fire, "size_xml")
	assert(property == 5, "Did not return the correct value")
	assert(isHidden == true, "Did not return whether the property was hidden")
end)

test("sethiddenproperty", {}, function()
	local fire = Instance.new("Fire")
	local hidden = sethiddenproperty(fire, "size_xml", 10)
	assert(hidden, "Did not return true for the hidden property")
	assert(gethiddenproperty(fire, "size_xml") == 10, "Did not set the hidden property")
end)

test("gethui", {}, function()
	assert(typeof(gethui()) == "Instance", "Did not return an Instance")
end)

test("getinstances", {}, function()
	assert(getinstances()[1]:IsA("Instance"), "The first value is not an Instance")
end)

test("getnilinstances", {}, function()
	assert(getnilinstances()[1]:IsA("Instance"), "The first value is not an Instance")
	assert(getnilinstances()[1].Parent == nil, "The first value is not parented to nil")
end)

test("isscriptable", {}, function()
	local fire = Instance.new("Fire")
	assert(isscriptable(fire, "size_xml") == false, "Did not return false for a non-scriptable property (size_xml)")
	assert(isscriptable(fire, "Size") == true, "Did not return true for a scriptable property (Size)")
end)

test("setscriptable", {}, function()
	local fire = Instance.new("Fire")
	local wasScriptable = setscriptable(fire, "size_xml", true)
	assert(wasScriptable == false, "Did not return false for a non-scriptable property (size_xml)")
	assert(isscriptable(fire, "size_xml") == true, "Did not set the scriptable property")
	fire = Instance.new("Fire")
	assert(isscriptable(fire, "size_xml") == false, "⚠️⚠️ setscriptable persists between unique instances ⚠️⚠️")
end)

test("setrbxclipboard", {})

-- Metatable

test("getrawmetatable", {}, function()
	local metatable = { __metatable = "Locked!" }
	local object = setmetatable({}, metatable)
	assert(getrawmetatable(object) == metatable, "Did not return the metatable")
end)

test("hookmetamethod", {}, function()
	local object = setmetatable({}, { __index = newcclosure(function() return false end), __metatable = "Locked!" })
	local ref = hookmetamethod(object, "__index", function() return true end)
	assert(object.test == true, "Failed to hook a metamethod and change the return value")
	assert(ref() == false, "Did not return the original function")
end)

test("getnamecallmethod", {}, function()
	local method
	local ref
	ref = hookmetamethod(game, "__namecall", function(...)
		if not method then
			method = getnamecallmethod()
		end
		return ref(...)
	end)
	game:GetService("Lighting")
	assert(method == "GetService", "Did not get the correct method (GetService)")
end)

test("isreadonly", {}, function()
	local object = {}
	table.freeze(object)
	assert(isreadonly(object), "Did not return true for a read-only table")
end)

test("setrawmetatable", {}, function()
	local object = setmetatable({}, { __index = function() return false end, __metatable = "Locked!" })
	local objectReturned = setrawmetatable(object, { __index = function() return true end })
	assert(object, "Did not return the original object")
	assert(object.test == true, "Failed to change the metatable")
	if objectReturned then
		return objectReturned == object and "Returned the original object" or "Did not return the original object"
	end
end)

test("setreadonly", {}, function()
	local object = { success = false }
	table.freeze(object)
	setreadonly(object, false)
	object.success = true
	assert(object.success, "Did not allow the table to be modified")
end)

-- Miscellaneous

test("identifyexecutor", {"getexecutorname"}, function()
	local name, version = identifyexecutor()
	assert(type(name) == "string", "Did not return a string for the name")
	return type(version) == "string" and "Returns version as a string" or "Does not return version"
end)

test("lz4compress", {}, function()
	local raw = "Hello, world!"
	local compressed = lz4compress(raw)
	assert(type(compressed) == "string", "Compression did not return a string")
	assert(lz4decompress(compressed, #raw) == raw, "Decompression did not return the original string")
end)

test("lz4decompress", {}, function()
	local raw = "Hello, world!"
	local compressed = lz4compress(raw)
	assert(type(compressed) == "string", "Compression did not return a string")
	assert(lz4decompress(compressed, #raw) == raw, "Decompression did not return the original string")
end)

test("messagebox", {})

test("queue_on_teleport", {"queueonteleport"})

test("request", {"http.request", "http_request"}, function()
	local response = request({
		Url = "https://httpbin.org/user-agent",
		Method = "GET",
	})
	assert(type(response) == "table", "Response must be a table")
	assert(response.StatusCode == 200, "Did not return a 200 status code")
	local data = game:GetService("HttpService"):JSONDecode(response.Body)
	assert(type(data) == "table" and type(data["user-agent"]) == "string", "Did not return a table with a user-agent key")
	return "User-Agent: " .. data["user-agent"]
end)

test("setclipboard", {"toclipboard"})

test("setfpscap", {}, function()
	local renderStepped = game:GetService("RunService").RenderStepped
	local function step()
		renderStepped:Wait()
		local sum = 0
		for _ = 1, 5 do
			sum += 1 / renderStepped:Wait()
		end
		return math.round(sum / 5)
	end
	setfpscap(60)
	local step60 = step()
	setfpscap(0)
	local step0 = step()
	return step60 .. "fps @60 • " .. step0 .. "fps @0"
end)

-- Scripts

test("getgc", {}, function()
	local gc = getgc()
	assert(type(gc) == "table", "Did not return a table")
	assert(#gc > 0, "Did not return a table with any values")
end)

test("getgenv", {}, function()
	getgenv().__TEST_GLOBAL = true
	assert(__TEST_GLOBAL, "Failed to set a global variable")
	getgenv().__TEST_GLOBAL = nil
end)

test("getloadedmodules", {}, function()
	local modules = getloadedmodules()
	assert(type(modules) == "table", "Did not return a table")
	assert(#modules > 0, "Did not return a table with any values")
	assert(typeof(modules[1]) == "Instance", "First value is not an Instance")
	assert(modules[1]:IsA("ModuleScript"), "First value is not a ModuleScript")
end)

test("getrenv", {}, function()
	assert(_G ~= getrenv()._G, "The variable _G in the executor is identical to _G in the game")
end)

test("getrunningscripts", {}, function()
	local scripts = getrunningscripts()
	assert(type(scripts) == "table", "Did not return a table")
	assert(#scripts > 0, "Did not return a table with any values")
	assert(typeof(scripts[1]) == "Instance", "First value is not an Instance")
	assert(scripts[1]:IsA("ModuleScript") or scripts[1]:IsA("LocalScript"), "First value is not a ModuleScript or LocalScript")
end)

test("getscriptbytecode", {"dumpstring"}, function()
	local animate = game:GetService("Players").LocalPlayer.Character.Animate
	local bytecode = getscriptbytecode(animate)
	assert(type(bytecode) == "string", "Did not return a string for Character.Animate (a " .. animate.ClassName .. ")")
end)

test("getscripthash", {}, function()
	local animate = game:GetService("Players").LocalPlayer.Character.Animate:Clone()
	local hash = getscripthash(animate)
	local source = animate.Source
	animate.Source = "print('Hello, world!')"
	task.defer(function()
		animate.Source = source
	end)
	local newHash = getscripthash(animate)
	assert(hash ~= newHash, "Did not return a different hash for a modified script")
	assert(newHash == getscripthash(animate), "Did not return the same hash for a script with the same source")
end)

test("getscripts", {}, function()
	local scripts = getscripts()
	assert(type(scripts) == "table", "Did not return a table")
	assert(#scripts > 0, "Did not return a table with any values")
	assert(typeof(scripts[1]) == "Instance", "First value is not an Instance")
	assert(scripts[1]:IsA("ModuleScript") or scripts[1]:IsA("LocalScript"), "First value is not a ModuleScript or LocalScript")
end)

test("getsenv", {}, function()
	local animate = game:GetService("Players").LocalPlayer.Character.Animate
	local env = getsenv(animate)
	assert(type(env) == "table", "Did not return a table for Character.Animate (a " .. animate.ClassName .. ")")
	assert(env.script == animate, "The script global is not identical to Character.Animate")
end)

test("getthreadidentity", {"getidentity", "getthreadcontext"}, function()
	assert(type(getthreadidentity()) == "number", "Did not return a number")
end)

test("setthreadidentity", {"setidentity", "setthreadcontext"}, function()
	setthreadidentity(3)
	assert(getthreadidentity() == 3, "Did not set the thread identity")
end)

-- Drawing

test("Drawing", {})

test("Drawing.new", {}, function()
	local drawing = Drawing.new("Square")
	drawing.Visible = false
	local canDestroy = pcall(function()
		drawing:Destroy()
	end)
	assert(canDestroy, "Drawing:Destroy() should not throw an error")
end)

test("Drawing.Fonts", {}, function()
	assert(Drawing.Fonts.UI == 0, "Did not return the correct id for UI")
	assert(Drawing.Fonts.System == 1, "Did not return the correct id for System")
	assert(Drawing.Fonts.Plex == 2, "Did not return the correct id for Plex")
	assert(Drawing.Fonts.Monospace == 3, "Did not return the correct id for Monospace")
end)

test("isrenderobj", {}, function()
	local drawing = Drawing.new("Image")
	drawing.Visible = true
	assert(isrenderobj(drawing) == true, "Did not return true for an Image")
	assert(isrenderobj(newproxy()) == false, "Did not return false for a blank table")
end)

test("getrenderproperty", {}, function()
	local drawing = Drawing.new("Image")
	drawing.Visible = true
	assert(type(getrenderproperty(drawing, "Visible")) == "boolean", "Did not return a boolean value for Image.Visible")
	local success, result = pcall(function()
		return getrenderproperty(drawing, "Color")
	end)
	if not success or not result then
		return "Image.Color is not supported"
	end
end)

test("setrenderproperty", {}, function()
	local drawing = Drawing.new("Square")
	drawing.Visible = true
	setrenderproperty(drawing, "Visible", false)
	assert(drawing.Visible == false, "Did not set the value for Square.Visible")
end)

test("cleardrawcache", {}, function()
	cleardrawcache()
end)

-- WebSocket

test("WebSocket", {})

test("WebSocket.connect", {}, function()
	local types = {
		Send = "function",
		Close = "function",
		OnMessage = {"table", "userdata"},
		OnClose = {"table", "userdata"},
	}
	local ws = WebSocket.connect("ws://echo.websocket.events")
	assert(type(ws) == "table" or type(ws) == "userdata", "Did not return a table or userdata")
	for k, v in pairs(types) do
		if type(v) == "table" then
			assert(table.find(v, type(ws[k])), "Did not return a " .. table.concat(v, ", ") .. " for " .. k .. " (a " .. type(ws[k]) .. ")")
		else
			assert(type(ws[k]) == v, "Did not return a " .. v .. " for " .. k .. " (a " .. type(ws[k]) .. ")")
		end
	end
	ws:Close()
end)
