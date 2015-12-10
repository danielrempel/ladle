do

--[[

	TODO: improve site and server separation
		example: same page, once loads a module (lsqlite3)
				the second time the module is available even
				if the require cmd was removed from the source.
				I think the environment gets dirty. I need a way
				to keep track of environmental pollution;)

]]--

local ladleutil = require('ladleutil')
local lfs = require('lfs')

--[[

	API = {
		Env
		__tmp_output_buffer
		write(text)
		trace(text)
		onerror(text)
		request = {}
		config = {}
		handleIt(filename, env)
		include(filename)
		
	
	}

--]]

local function executeLua(code, Env)
	local func, message = load(code, "code","bt", Env)
	if not func
	then
		return nil, message
	end
	return xpcall(func, debug.traceback)
end

local function parseLuaPage(page, Env)
	local a,b,c
	while page:len() > 0 do
		a,b = page:find("%<%?")

		if a
		then
			a= a-1
		
			Env.write(page:sub(0,a))
			page = page:sub(b+1)
					
			a,c = page:find("%?%>")
			if not a
			then
				return nil, "matching '?>' not found!"
			else
				a=a-1
				local code = page:sub(1,a)
								
				local retval, err = executeLua(code, Env)
				if err
				then
					return nil, err
				end
				page = page:sub(c+1)
			end
		else
			Env.write(page)
			page = ""
		end
	end
end

local function handleIt(filename, Env)
	local uri = filename:match("[^/]+$")
	ladleutil.trace(("luascript: handleIt(%s)" ):format(uri, filename))
	local file_l = io.open(filename, "r")
	if not file_l
	then
		ladleutil.trace(("luascript: failed to open %s"):format(filename))
		return nil, "HTTP/1.1 500 Internal Server Error\r\nServer: Ladle\r\n" ..
					"Content-Type: text/plain\r\n\r\n" ..
					"500 Internal Server Error\r\n"
	end

	local fileContents = file_l:read("*all")
	
	-- either lua script
	-- or anything else
	if filename:match(".+%.lua$") ~= nil
	then
		local retval, err = executeLua(fileContents, Env)
		if err
		then
			Env.onerror("luascript: " .. uri .. ": " .. err)
		end
	else
		local retval, err = parseLuaPage(fileContents, Env)
		if err
		then
			Env.onerror("luascript: " .. uri .. ": " .. err)
		end
	end
end

local function genEnv(_Env, request, config)
	local Env = _Env
	Env.__tmp_output_buffer = ""
	Env.write	= function (text)
					Env.__tmp_output_buffer = Env.__tmp_output_buffer .. text
				end
	Env.trace	= ladleutil.trace
	Env.onerror	= function (text)
						trace(text)
						if not text:match("\n$")
						then
							text = text .. "\n"
						end
						write(text)
						
				end
	Env.request = request
	Env.config = config
	Env.handleIt = handleIt
	Env.include	= function (filename)
					handleIt(Env.config.webroot .. "/" .. filename, _ENV)
				end
	return Env
end

local function handler(request, client, config)
	local Env = genEnv(_ENV, request, config)
	
	if not ladleutil.fileExists(config.webroot .. request.uri)
	then
		-- TODO : link to ladle's generic err
		ladleutil.trace(("luascript: %s not found"):format(config.webroot .. request.uri))
		client:send("HTTP/1.1 404 Not Found\r\nServer: Ladle\r\n")
		client:send("Content-Type: text/plain\r\n\r\n")
		client:send("404 Not Found\r\n")
		return
	end
	
	local cdir = lfs.currentdir()
	lfs.chdir(config.webroot)
	handleIt(config.webroot .. request.uri, Env)
	client:send(Env.__tmp_output_buffer)
	lfs.chdir(cdir)
end

local function match(filename)
	return (filename:match(".+%.lp$") ~= nil) or (filename:match(".+%.lua$") ~= nil)
end

return {
	["match"] = match,
	["handler"] = handler,
	["id"] = "luascript",
	["name"] = "Lua script and page handler"
}
end
