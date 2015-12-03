-----------------------------------------------------
-- Ladle web server
-- Version 0.1.1
-- Original work Copyright (c) 2008 Samuel Saint-Pettersen (original author)
-- Modified work Copyright (c) 2015 Daniel Rempel
-- Released under the MIT License
-----------------------------------------------------

-- load required modules
socket = require("socket")
xmlp = require("xml.parser")

-- load mime configuration file
mconf = io.open("config/mime.xml", "r")
if mconf ~= nil then mconf = mconf:read("*all") end

-- start web server
function main(arg1) 
	port = arg1 -- set first argument as port

	-- display initial program information
	print [[Ladle web server v0.1.1
Copyright (c) 2008 Samuel Saint-Pettersen]]

	-- if no port is specified, use port 80
	if port == nil then port = 80 end

	-- display warning message if configuration missing
	if mconf == nil then
		print("\nWarning: MIME config file missing")
	end 

	-- create tcp socket on localhost:$port
	server = assert(socket.bind("*", port))

	-- display message to web server is running
	print("\nRunning on localhost:" .. port)
	waitReceive() -- begin waiting for client requests
end
-- wait for and receive client requests
function waitReceive()
	-- loop while waiting for a client request
	while 1 do
		-- accept a client request
		client = server:accept()
		-- set timeout - 1 minute.
		client:settimeout(60)
		-- receive request from client
		local request, err = client:receive()
		-- if there's no error, begin serving content or kill server
		if not err then
			-- if request is kill (via telnet), stop the server
			if request == "kill" then
				client:send("Ladle has stopped\n")
				print("Stopped")
				break
			else
				-- begin serving content
				serve(request)
			end
		end
	end
end

-- serve requested ordinary file
function serveFile(file, flags, mime)
	served = io.open("www/" .. file, flags)
	if served ~= nil then
		client:send("HTTP/1.1 200/OK\r\nServer: Ladle\r\n")
		client:send("Content-Type:" .. mime .. "\r\n\r\n")
	
		local content = served:read("*all")
		client:send(content)
	else
		client:send("HTTP/1.1 404 Not Found\r\nServer: Ladle\r\n")
		client:send("Content-Type:" .. mime .. "\r\n\r\n")
	
		-- display not found error
		err("Not found!")
	end
end

function serveLua(file)
	tmp_lua_script_output_buffer = ""
	local newEnv = _ENV
		newEnv["write"] = function(text) tmp_lua_script_output_buffer = tmp_lua_script_output_buffer .. text end
	
	local file_l = io.open("www/" .. file, "r")
	if file_l
	then
		local code = file_l:read("*all")
		local func, message = load(code, file,"bt", newEnv)
		if not func
		then
			client:send("HTTP/1.1 500 Internal server error\r\nServer: Ladle\r\n")
			client:send("Content-Type: text/plain\r\n\r\n")
			client:send(message)
			return
		end
		local retval = pcall(func, function(err) tmp_lua_script_output_buffer = tmp_lua_script_output_buffer .. "\nError: " .. err end)
		client:send(tmp_lua_script_output_buffer)
		return
	else
		client:send("HTTP/1.1 404 Not Found\r\nServer: Ladle\r\n")
		client:send("Content-Type: text/plain\r\n\r\n")
	end
end

-- serve requested content
function serve(request)
	-- resolve requested file from client request
	local file = string.match(request, "%w+%/?.?%l+")
	-- if no file mentioned in request, assume root file is index.html.
	if file == nil then
		file = "index.html"
	end
		
	-- retrieve mime type for file based on extension
	local ext = string.match(file, "%.%l%l%l%l?")
	local islua = file:match("%.lua$")
	local mime = getMime(ext)

	-- reply with a response, which includes relevant mime type
	if nil == mime then
		mime = "text/html; encoding: utf8"
	end

	-- determine if file is in binary or ASCII format
	local binary = isBinary(mime)

	-- load requested file in browser
	local served, flags
	if binary == false then
		-- if file is ASCII, use just read flag
		flags = "r"     
	else
		-- otherwise file is binary, so also use binary flag (b)
		-- note: this is for operating systems which read binary
		-- files differently to plain text such as Windows
		flags = "rb"
	end
	
	if islua
	then
		serveLua(file)
	else
		serveFile(file, flags, mime)
	end

	-- done with client, close request
	client:close()
end
-- determine mime type based on file extension
function getMime(ext)
	local i = 1
	local exts = xmlp.ctag(mconf, "file")
	while i < exts do
		local v = xmlp.vatt(mconf, "file", "ext", i)
		if v == ext then
			return xmlp.vtag(mconf, "mime", i)
		end
		i = i + 1
	end
end
-- determine if file is binary - true or false
function isBinary(mime)
	local i = 1
	local types = xmlp.ctag(mconf, "mime")
	while i < types do
		local v = xmlp.vtag(mconf, "mime", i)
		if v == mime then
			return xmlp.vtag(mconf, "bin", i)
		end
		i = i + 1
	end
end     
-- display error message and server information
function err(message)
	client:send(message)
	-- ...
end
-- invoke program starting point:
-- parameter is command-line argument for port number
main(arg[1])
