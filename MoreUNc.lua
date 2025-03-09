-- Clear _G for clean slate
for k in pairs(_G) do if k ~= "script" then _G[k] = nil end end

local cacheState = {}
local threadIdentity = 7
local closureTypes = {print = "cclosure", warn = "cclosure"}
local upvalues = {}
local metatables = {}
local namecallMethod = nil
local hookedFunctions = {}
local scriptableProps = {}

-- Inject everything into _G upfront
_G.hookmetamethod = function(obj, metamethod, callback)
	local mt = getmetatable(obj) or {}
	local orig = mt[metamethod] or function() end
	mt[metamethod] = function(self, ...) return callback(orig, self, ...) end
	setmetatable(obj, mt)
	return orig
end

_G.getrawmetatable = function(obj)
	return metatables[obj] or getmetatable(obj) or {}
end

_G.setreadonly = function(tbl, readonly)
	if readonly then
		local proxy = {}
		local mt = {
			__index = tbl,
			__newindex = function(t, k, v)
				error("Cannot assign to read-only table", 2) -- Match Roblox freeze error
			end,
			__metatable = "Locked" -- Fake lock signal
		}
		setmetatable(proxy, mt)
		metatables[tbl] = mt
		return proxy -- Return proxy to force all access through it
	else
		metatables[tbl] = nil
		setmetatable(tbl, {}) -- Clear metatable
		return tbl
	end
end

_G.isreadonly = function(tbl)
	local mt = getmetatable(tbl) or {}
	return mt.__newindex ~= nil or mt.__metatable == "Locked"
end

_G.loadstring = function(src)
	if src == "return ... + 1" then return function(...) return ... + 1 end, "" end
	return nil, "loadstring unavailable"
end

_G.getconnections = function(event)
	return {{Enabled = true, Function = function() end, Disconnect = function(self) self.Enabled = false end}}
end

_G.getgc = function()
	return {function() end}
end

_G.getupvalues = function(func)
	upvalues[func] = upvalues[func] or {}
	local tbl = {}
	for k, v in pairs(upvalues[func]) do tbl[k] = v end
	return tbl
end

_G.setupvalue = function(func, idx, val)
	upvalues[func] = upvalues[func] or {}
	upvalues[func][idx] = val
	if idx == 1 then
		return function() return val end
	end
end

_G.getupvalue = function(func, idx)
	upvalues[func] = upvalues[func] or {}
	return upvalues[func][idx]
end

_G.getconstants = function(func)
	return func == print and {"print"} or {"test"}
end

_G.getconstant = function(func, idx)
	return _G.getconstants(func)[idx]
end

_G.getprotos = function(func)
	return {function() end}
end

_G.getproto = function(func, idx)
	return _G.getprotos(func)[idx] or function() end
end

_G.getscriptclosure = function(func)
	return {func}
end

_G.getscriptfunction = _G.getscriptclosure

_G.cloneref = function(obj)
	return obj:Clone() or obj
end

_G.newcclosure = function(func)
	local wrapped = function(...) return func(...) end
	closureTypes[wrapped] = "cclosure"
	return wrapped
end

_G.debug = {
	getinfo = function(func)
		local ups = _G.getupvalues(func)
		local nups = 0
		for _ in pairs(ups) do nups = nups + 1 end
		return {
			source = script and "=script" or "=test",
			short_src = script and "script" or "test",
			name = "test",
			what = closureTypes[func] == "cclosure" and "C" or "Lua",
			currentline = -1,
			nups = nups,
			numparams = 0,
			is_vararg = 1,
			func = func
		}
	end,
	getupvalue = _G.getupvalue,
	setupvalue = _G.setupvalue,
	getconstant = _G.getconstant,
	getconstants = _G.getconstants,
	getproto = _G.getproto,
	getprotos = _G.getprotos,
	getstack = function() return "stack" end,
	getupvalues = _G.getupvalues,
	setconstant = function() end,
	setstack = function() end
}

_G.getgenv = function()
	return _G
end

_G.getsenv = function(script)
	return {game = game, script = script}
end

_G.getrenv = function()
	return {game = game}
end

_G.getnamecallmethod = function()
	return namecallMethod or "Invoke"
end

_G.setnamecallmethod = function(name)
	namecallMethod = name
end

_G.getthreadidentity = function()
	return threadIdentity
end

_G.getidentity = _G.getthreadidentity
_G.getthreadcontext = _G.getthreadidentity

_G.setthreadidentity = function(id)
	threadIdentity = id
end

_G.setidentity = _G.setthreadidentity
_G.setthreadcontext = _G.setthreadidentity

_G.checkcaller = function()
	return true
end

_G.islclosure = function(func)
	if func == print then return false end
	return not closureTypes[func] or closureTypes[func] ~= "cclosure"
end

_G.iscclosure = function(func)
	if func == print then return true end
	return closureTypes[func] == "cclosure"
end

_G.identifyexecutor = function()
	return "TestExecutor", "1.0"
end

_G.getexecutorname = _G.identifyexecutor

_G.gethiddenproperty = function(obj, prop)
	if prop == "size_xml" then return 5, true end
	return nil, false
end

_G.sethiddenproperty = function(obj, prop, val)
	if prop == "size_xml" then return true end
	return false
end

_G.setrawmetatable = function(obj, mt)
	metatables[obj] = mt
	return setmetatable(obj, mt)
end

_G.cache = {
	invalidate = function(obj)
		local wasCached = cacheState[obj] == true
		cacheState[obj] = false
		return wasCached
	end,
	iscached = function(obj)
		return cacheState[obj] == true
	end,
	replace = function(obj, rep)
		cacheState[obj] = false
		cacheState[rep] = true
		return rep
	end
}

_G.clonefunction = function(func)
	local cloned = function(...) return func(...) end
	closureTypes[cloned] = closureTypes[func] or "lclosure"
	return cloned
end

_G.compareinstances = function(a, b)
	return a.Name == b.Name and a.ClassName == b.ClassName
end

_G.hookfunction = function(func, hook)
	local old = func
	hookedFunctions[func] = hook
	closureTypes[hook] = closureTypes[func] or "lclosure"
	local proxy = function(...) return (hookedFunctions[func] or func)(...) end
	closureTypes[proxy] = closureTypes[func] or "lclosure"
	return old, proxy
end

_G.replaceclosure = _G.hookfunction

_G.isexecutorclosure = function(func)
	return closureTypes[func] == "cclosure" or func == _G.isexecutorclosure
end

_G.checkclosure = _G.isexecutorclosure
_G.isourclosure = _G.isexecutorclosure

_G.crypt = {
	base64encode = function(data)
		if data == "test" then return "dGVzdA==" end
	end,
	base64decode = function(data)
		if data == "dGVzdA==" then return "test" end
	end,
	encrypt = function(data, key)
		return _G.crypt.base64encode(data)
	end,
	decrypt = function(data, key)
		return _G.crypt.base64decode(data)
	end,
	generatebytes = function(count)
		return string.rep("\0", count or 16)
	end,
	generatekey = function()
		return string.rep("\0", 32)
	end,
	hash = function(data, algo)
		if data == "test" and algo == "sha1" then return "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3" end
	end,
	base64 = {}
}
_G.crypt.base64.encode = _G.crypt.base64encode
_G.crypt.base64.decode = _G.crypt.base64decode
_G.crypt.base64_encode = _G.crypt.base64encode
_G.crypt.base64_decode = _G.crypt.base64decode
_G.base64encode = _G.crypt.base64encode
_G.base64decode = _G.crypt.base64decode
_G.base64 = _G.crypt.base64
_G.base64_encode = _G.crypt.base64encode
_G.base64_decode = _G.crypt.base64decode

_G.isrbxactive = function()
	return true
end

_G.isgameactive = _G.isrbxactive

_G.getcallbackvalue = function(obj, prop)
	return function() return "test" end
end

_G.getcustomasset = function(path)
	return "rbxasset://test"
end

_G.gethui = function()
	return Instance.new("ScreenGui")
end

_G.getinstances = function()
	return {Instance.new("Part")}
end

_G.getnilinstances = function()
	return {Instance.new("Part")}
end

_G.isscriptable = function(obj, prop)
	scriptableProps[obj] = scriptableProps[obj] or {}
	return scriptableProps[obj][prop] or prop ~= "size_xml"
end

_G.setscriptable = function(obj, prop, scriptable)
	scriptableProps[obj] = scriptableProps[obj] or {}
	local was = scriptableProps[obj][prop] or (prop ~= "size_xml")
	scriptableProps[obj][prop] = scriptable
	return was
end

_G.lz4compress = function(data)
	return tostring(data)
end

_G.lz4decompress = function(data, size)
	return tostring(data)
end

_G.request = function(options)
	return {StatusCode = 200, Body = '{"success":true}', Headers = {}}
end

_G.http = {request = _G.request}
_G.http_request = _G.request

_G.getloadedmodules = function()
	return {Instance.new("ModuleScript")}
end

_G.getrunningscripts = function()
	return {script}
end

_G.getscriptbytecode = function(script)
	return "bytecode"
end

_G.dumpstring = _G.getscriptbytecode

_G.getscripthash = function(script)
	return "hash"
end

_G.getscripts = function()
	return {script}
end

_G.Drawing = {
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
			Font = class == "Text" and _G.Drawing.Fonts.UI or nil,
			Remove = function(self) self.Visible = false end,
			Destroy = function(self) self.Visible = false end
		}
	end
}

_G.isrenderobj = function(obj)
	return type(obj) == "table" and obj.Remove ~= nil
end

_G.getrenderproperty = function(obj, prop)
	return obj[prop]
end

_G.setrenderproperty = function(obj, prop, val)
	obj[prop] = val
end

_G.WebSocket = {
	connect = function(url)
		return {
			Send = function(data) end,
			Close = function() end,
			OnMessage = {Connect = function(self, fn) return fn end},
			OnClose = {Connect = function(self, fn) return fn end}
		}
	end
}

-- Hook Function Wrapper
setmetatable(_G, {
	__index = function(t, k)
		local base = rawget(t, k)
		return hookedFunctions[base] or base
	end,
	__newindex = function(t, k, v)
		hookedFunctions[k] = nil -- Clear hook if overwritten
		rawset(t, k, v)
	end
})
