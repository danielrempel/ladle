-----------------------------------------------------
-- Ladle web server
-- Version 0.1.1
-- Original work Copyright (c) 2008 Samuel Saint-Pettersen (original author)
-- Modified work Copyright (c) 2015 Daniel Rempel
-- Released under the MIT License
-----------------------------------------------------

-- load required modules
socket = require("socket")

-- load mime configuration file
mconf = require('mimetypes')

-- load configuration file
local f = io.open('config.lua', 'r')
if f then
	config = require('config')
	f:close()
else config = nil
end

-- start web server
function main(arg1)

	-- command line argument overrides config file entry:
	port = arg1
	-- if no port specified on command line, use config entry:
	if port == nil then port = config['port'] end
	-- if still no port, fall back to default port, 80:
	if port == nil then port = 80 end
	
	-- load hostname from config file:
	hostname = config['hostname']
	if hostname == nil then hostname = '*' end -- fall back to default

	-- display initial program information
	print("Ladle web server v0.1.1")
	print("Copyright (c) 2008 Samuel Saint-Pettersen")

	-- create tcp socket on localhost:$port
	server = socket.bind(hostname, port)
	if not server
	then
		print("Failed to bind to given hostname:port")
		os.exit(1)
	end

	-- display message to web server is running
	print(("Serving on %s:%d"):format(hostname,port))
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
	local mime = getMime(ext)

	-- reply with a response, which includes relevant mime type
	if nil == mime then
		mime = "text/html; encoding: utf8"
	end

	-- determine if file is in binary or ASCII format
	local binary = isBinary(ext)

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

	-- done with client, close request
	client:close()
end
-- determine mime type based on file extension
function getMime(ext)
	return mconf[ext]['mime']
end
-- determine if file is binary - true or false
function isBinary(ext)
	return mconf[ext]['bin']
end     
-- display error message and server information
function err(message)
	client:send(message)
	-- ...
end
-- invoke program starting point:
-- parameter is command-line argument for port number
main(arg[1])
