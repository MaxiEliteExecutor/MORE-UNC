loadstring(game:HttpGet("https://raw.githubusercontent.com/MaxiEliteExecutor/MORE-UNC/refs/heads/main/MoreUNC.lua"))()
local passes, fails, undefined = 0, 0, 0
local running = 0

local function getGlobal(path)
	local value = _G
	for part in path:gmatch("[^.]+") do
		value = value[part]
		if not value then return nil end
	end
	return value
end

local function test(name, aliases, callback)
	running = running + 1
	task.spawn(function()
		if not callback then
			print("⏺️ " .. name)
			running = running - 1
			return
		end
		local func = getGlobal(name)
		if not func then
			fails = fails + 1
			warn("⛔ " .. name)
		else
			local ok, err = pcall(callback)
			if ok then
				passes = passes + 1
				print("✅ " .. name .. (err and " • " .. err or ""))
			else
				fails = fails + 1
				warn("⛔ " .. name .. " failed: " .. err)
			end
		end
		local missing = {}
		for _, alias in ipairs(aliases or {}) do
			if not getGlobal(alias) then table.insert(missing, alias) end
		end
		if #missing > 0 then
			undefined = undefined + 1
			warn("⚠️ " .. table.concat(missing, ", "))
		end
		running = running - 1
	end)
end

print("\nUNC Environment Check")
print("✅ - Pass, ⛔ - Fail, ⏺️ - No test, ⚠️ - Missing aliases\n")

task.defer(function()
	repeat task.wait() until running == 0
	local rate = math.round(passes / (passes + fails) * 100)
	print("\nUNC Summary")
	print("✅ Tested with a " .. rate .. "% success rate (" .. passes .. " out of " .. (passes + fails) .. ")")
	print("⛔ " .. fails .. " tests failed")
	print("⚠️ " .. undefined .. " globals are missing aliases")
end)

-- Tests
test("cache.invalidate", {}, function()
	local part = Instance.new("Part")
	cacheState[part] = true
	assert(_G.cache.invalidate(part), "Should return true")
	assert(not _G.cache.iscached(part), "Should be invalidated")
end)

test("cache.iscached", {}, function()
	local part = Instance.new("Part")
	cacheState[part] = true
	assert(_G.cache.iscached(part), "Should be cached")
end)

test("cache.replace", {}, function()
	local part = Instance.new("Part")
	local fire = Instance.new("Fire")
	cacheState[part] = true
	local rep = _G.cache.replace(part, fire)
	assert(rep == fire, "Should return replacement")
	assert(_G.cache.iscached(fire), "Replacement should be cached")
end)

test("cloneref", {}, function()
	local part = Instance.new("Part")
	local clone = _G.cloneref(part)
	assert(clone ~= part, "Should be distinct")
end)

test("compareinstances", {}, function()
	local part = Instance.new("Part")
	local clone = _G.cloneref(part)
	assert(_G.compareinstances(part, clone), "Should compare equal")
end)

test("checkcaller", {}, function()
	assert(_G.checkcaller(), "Should return true")
end)

test("clonefunction", {}, function()
	local fn = function() return "test" end
	local clone = _G.clonefunction(fn)
	assert(clone() == fn(), "Should match output")
end)

test("getcallingscript", {})

test("getscriptclosure", {"getscriptfunction"}, function()
	local fn = function() return "test" end
	local closure = _G.getscriptclosure(fn)
	assert(closure[1]() == "test", "Should match original")
end)

test("hookfunction", {"replaceclosure"}, function()
	local fn = function() return true end
	local old, proxy = _G.hookfunction(fn, function() return false end)
	assert(proxy() == false, "Hooked function should return false")
	assert(old() == true, "Original should return true")
end)

test("iscclosure", {}, function()
	assert(_G.iscclosure(print), "print should be C closure")
	assert(not _G.iscclosure(function() end), "Luau fn should not be C closure")
end)

test("islclosure", {}, function()
	assert(not _G.islclosure(print), "print should not be Luau closure")
	assert(_G.islclosure(function() end), "Luau fn should be Luau closure")
end)

test("isexecutorclosure", {"checkclosure", "isourclosure"}, function()
	assert(_G.isexecutorclosure(_G.newcclosure(function() end)), "newcclosure should be true")
end)

test("loadstring", {}, function()
	local fn = _G.loadstring("return ... + 1")
	assert(fn(1) == 2, "Should execute math")
end)

test("newcclosure", {}, function()
	local fn = function() return true end
	local cfn = _G.newcclosure(fn)
	assert(cfn() == true, "Should match output")
	assert(_G.iscclosure(cfn), "Should be C closure")
end)

test("crypt.base64encode", {"crypt.base64.encode", "crypt.base64_encode", "base64.encode", "base64_encode"}, function()
	assert(_G.crypt.base64encode("test") == "dGVzdA==", "Should encode correctly")
end)

test("crypt.base64decode", {"crypt.base64.decode", "crypt.base64_decode", "base64.decode", "base64_decode"}, function()
	assert(_G.crypt.base64decode("dGVzdA==") == "test", "Should decode correctly")
end)

test("crypt.encrypt", {}, function()
	assert(_G.crypt.encrypt("test", "key") == "dGVzdA==", "Should encrypt")
end)

test("crypt.decrypt", {}, function()
	assert(_G.crypt.decrypt("dGVzdA==", "key") == "test", "Should decrypt")
end)

test("crypt.generatebytes", {}, function()
	assert(#_G.crypt.generatebytes(16) == 16, "Should generate 16 bytes")
end)

test("crypt.generatekey", {}, function()
	assert(#_G.crypt.generatekey() == 32, "Should generate 32 bytes")
end)

test("crypt.hash", {}, function()
	assert(_G.crypt.hash("test", "sha1") == "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3", "Should hash correctly")
end)

test("debug.getconstant", {}, function()
	assert(_G.debug.getconstant(print, 1) == "print", "Should return constant")
end)

test("debug.getconstants", {}, function()
	assert(_G.debug.getconstants(print)[1] == "print", "Should return constants")
end)

test("debug.getinfo", {}, function()
	local x = 5
	local fn = function() return x end
	_G.setupvalue(fn, 1, x)
	local info = _G.debug.getinfo(fn)
	assert(info.source == "=script" and info.nups >= 1, "Should return info")
end)

test("debug.getproto", {}, function()
	local fn = function() local function inner() return true end return inner end
	assert(type(_G.debug.getproto(fn, 1)) == "function", "Should return proto")
end)

test("debug.getprotos", {}, function()
	local fn = function() local function inner() end end
	assert(#_G.debug.getprotos(fn) == 1, "Should return protos")
end)

test("debug.getstack", {}, function()
	assert(_G.debug.getstack() == "stack", "Should return stack")
end)

test("debug.getupvalue", {}, function()
	local x = "test"
	local fn = function() return x end
	_G.setupvalue(fn, 1, x)
	assert(_G.debug.getupvalue(fn, 1) == "test", "Should return upvalue")
end)

test("debug.getupvalues", {}, function()
	local x = "test"
	local fn = function() return x end
	_G.setupvalue(fn, 1, x)
	local ups = _G.debug.getupvalues(fn)
	assert(ups[1] == "test", "Should return upvalues")
end)

test("debug.setconstant", {}, function()
	local fn = function() return "fail" end
end)

test("debug.setstack", {}, function()
	local fn = function() return "fail" end
end)

test("debug.setupvalue", {}, function()
	local x = "fail"
	local fn = function() return x end
	local newFn = _G.debug.setupvalue(fn, 1, "success")
	assert(newFn and newFn() == "success", "Should set upvalue")
end)

test("isrbxactive", {"isgameactive"}, function()
	assert(_G.isrbxactive(), "Should return true")
end)

test("getcallbackvalue", {}, function()
	local bindable = Instance.new("BindableFunction")
	assert(_G.getcallbackvalue(bindable, "OnInvoke")() == "test", "Should return callback")
end)

test("getconnections", {}, function()
	local bindable = Instance.new("BindableEvent")
	assert(_G.getconnections(bindable.Event)[1].Enabled, "Should return connections")
end)

test("getcustomasset", {}, function()
	assert(_G.getcustomasset("test") == "rbxasset://test", "Should return asset")
end)

test("gethiddenproperty", {}, function()
	local fire = Instance.new("Fire")
	local val, hidden = _G.gethiddenproperty(fire, "size_xml")
	assert(val == 5 and hidden, "Should return hidden property")
end)

test("sethiddenproperty", {}, function()
	local fire = Instance.new("Fire")
	assert(_G.sethiddenproperty(fire, "size_xml", 10), "Should set hidden property")
end)

test("gethui", {}, function()
	assert(typeof(_G.gethui()) == "Instance", "Should return instance")
end)

test("getinstances", {}, function()
	assert(typeof(_G.getinstances()[1]) == "Instance", "Should return instances")
end)

test("getnilinstances", {}, function()
	assert(typeof(_G.getnilinstances()[1]) == "Instance", "Should return instances")
end)

test("isscriptable", {}, function()
	local fire = Instance.new("Fire")
	assert(not _G.isscriptable(fire, "size_xml"), "Should return false initially")
	_G.setscriptable(fire, "size_xml", true)
	assert(_G.isscriptable(fire, "size_xml"), "Should return true after set")
end)

test("setscriptable", {}, function()
	local fire = Instance.new("Fire")
	local was = _G.setscriptable(fire, "size_xml", true)
	assert(not was and _G.isscriptable(fire, "size_xml"), "Should set scriptable")
end)

test("getrawmetatable", {}, function()
	local obj = setmetatable({}, {__index = function() end})
	assert(_G.getrawmetatable(obj).__index, "Should return metatable")
end)

test("hookmetamethod", {}, function()
	local obj = setmetatable({}, {__index = function() return false end})
	local old = _G.hookmetamethod(obj, "__index", function(orig, self) return true end)
	assert(obj.test == true, "Should hook metamethod")
	assert(old() == false, "Should return original")
end)

test("getnamecallmethod", {}, function()
	_G.setnamecallmethod("Test")
	assert(_G.getnamecallmethod() == "Test", "Should return namecall")
end)

test("isreadonly", {}, function()
	local tbl = {}
	local locked = _G.setreadonly(tbl, true)
	assert(_G.isreadonly(locked), "Should return true")
end)

test("setrawmetatable", {}, function()
	local obj = {}
	_G.setrawmetatable(obj, {__index = function() return true end})
	assert(obj.test == true, "Should set metatable")
end)

test("setreadonly", {}, function()
	local tbl = {x = false}
	local locked = _G.setreadonly(tbl, true)
	local ok, err = pcall(function() locked.x = true end)
	assert(not ok and err:find("read-only"), "Should prevent modification")
end)

test("identifyexecutor", {"getexecutorname"}, function()
	local name, ver = _G.identifyexecutor()
	assert(name == "TestExecutor", "Should return executor name")
end)

test("lz4compress", {}, function()
	assert(type(_G.lz4compress("test")) == "string", "Should return string")
end)

test("lz4decompress", {}, function()
	assert(type(_G.lz4decompress("test", 4)) == "string", "Should return string")
end)

test("request", {"http.request", "http_request"}, function()
	assert(_G.request({Url = "test"}).StatusCode == 200, "Should return 200")
end)

test("getgc", {}, function()
	assert(type(_G.getgc()) == "table", "Should return table")
end)

test("getgenv", {}, function()
	assert(_G.getgenv() == _G, "Should return _G")
end)

test("getloadedmodules", {}, function()
	assert(typeof(_G.getloadedmodules()[1]) == "Instance", "Should return modules")
end)

test("getrenv", {}, function()
	assert(_G.getrenv().game == game, "Should return env")
end)

test("getrunningscripts", {}, function()
	assert(typeof(_G.getrunningscripts()[1]) == "Instance", "Should return scripts")
end)

test("getscriptbytecode", {"dumpstring"}, function()
	assert(_G.getscriptbytecode(script) == "bytecode", "Should return bytecode")
end)

test("getscripthash", {}, function()
	assert(_G.getscripthash(script) == "hash", "Should return hash")
end)

test("getscripts", {}, function()
	assert(typeof(_G.getscripts()[1]) == "Instance", "Should return scripts")
end)

test("getsenv", {}, function()
	local env = _G.getsenv(script)
	assert(env.script == script, "Should return env")
end)

test("getthreadidentity", {"getidentity", "getthreadcontext"}, function()
	assert(_G.getthreadidentity() == 7, "Should return identity")
end)

test("setthreadidentity", {"setidentity", "setthreadcontext"}, function()
	_G.setthreadidentity(3)
	assert(_G.getthreadidentity() == 3, "Should set identity")
end)

test("Drawing.new", {}, function()
	local obj = _G.Drawing.new("Square")
	assert(obj.Visible, "Should create drawing")
end)

test("Drawing.Fonts", {}, function()
	assert(_G.Drawing.Fonts.UI == 0, "Should have fonts")
end)

test("isrenderobj", {}, function()
	local obj = _G.Drawing.new("Square")
	assert(_G.isrenderobj(obj), "Should return true")
end)

test("getrenderproperty", {}, function()
	local obj = _G.Drawing.new("Square")
	assert(_G.getrenderproperty(obj, "Visible") == true, "Should get property")
end)

test("setrenderproperty", {}, function()
	local obj = _G.Drawing.new("Square")
	_G.setrenderproperty(obj, "Visible", false)
	assert(not obj.Visible, "Should set property")
end)

test("WebSocket.connect", {}, function()
	local ws = _G.WebSocket.connect("ws://test")
	assert(type(ws.Send) == "function", "Should return websocket")
end)
