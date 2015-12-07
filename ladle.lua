-----------------------------------------------------
-- Ladle web server
-- Version 0.1.1
-- Original work Copyright (c) 2008 Samuel Saint-Pettersen (original author)
-- Modified work Copyright (c) 2015 Daniel Rempel
-- Released under the MIT License
-----------------------------------------------------

-- load required modules
socket = require('socket')
mime = require('mimetypes')

-- load server components
ladleutil = require('ladleutil')

-- load configuration file
if ladleutil.fileExists('config.lua') then
	config = require('config')
else
	config = nil
end

function serve(request, client)
	if request["query_string"] then
		print("request: query: \"" .. request["query_string"] .. "\"")
	end

	local file = request["uri"]
	-- if no file mentioned in request, assume root file is index.html.
	if file == nil or file == "" then
		file = "index.html"
	end

	-- retrieve mime type for file based on extension
	local ext = string.match(file, "%.%l%l%l%l?") or ""
	local mimetype = mime.getMime(ext)
	if nil == mimetype then
		mimetype = "text/html" -- fallback. didn't think out something
								-- better
	end

	local binary = mime.isBinary(ext)

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

	local served = io.open("www/" .. file, flags)
	if served ~= nil then
		client:send("HTTP/1.1 200/OK\r\nServer: Ladle\r\n")
		client:send("Content-Type:" .. mimetype .. "\r\n\r\n")

		local content = served:read("*all")
		client:send(content)
	else
		client:send("HTTP/1.1 404 Not Found\r\nServer: Ladle\r\n")
		client:send("Content-Type: text/plain\r\n\r\n")

		-- display not found error
		ladleutil.err("Not found!", client)
	end

	-- done with client, close request
	client:close()
end

function clientHandler(client)
	-- set timeout - 1 minute.
	client:settimeout(60)
	-- receive request from client
	local request_text, err = ladleutil.receiveHTTPRequest(client)

	-- if there's no error, begin serving content or kill server
	if not err then
		-- parse request
		local request = ladleutil.parseRequest(request_text)
		-- run a prep [e.g. for POST with files - download files]
		ladleutil.prepMain(request, client)
		-- begin serving content
		serve(request, client)
	end
end

-- TODO: maybe implement keepalive?
function waitReceive(server)
	-- loop while waiting for a client request
	while 1 do
		-- accept a client request
		local client = server:accept()
		clientHandler(client)
	end
end

-- start web server
function main(arg1)
	-- command line argument overrides config file entry:
	local port = arg1
	-- if no port specified on command line, use config entry:
	if port == nil then port = config['port'] end
	-- if still no port, fall back to default port, 80:
	if port == nil then port = 80 end

	-- load hostname from config file:
	local hostname = config['hostname']
	if hostname == nil then hostname = '*' end -- fall back to default

	-- display initial program information
	print("Ladle web server v0.1.1")
	print("Copyright (c) 2008 Samuel Saint-Pettersen")

	-- create tcp socket on localhost:$port
	local server = socket.bind(hostname, port)
	if not server
	then
		print("Failed to bind to given hostname:port")
		os.exit(1)
	end

	-- display message to web server is running
	print(("Serving on %s:%d"):format(hostname,port))
	waitReceive(server) -- begin waiting for client requests
end

-- invoke program starting point:
-- parameter is command-line argument for port number
main(arg[1])
