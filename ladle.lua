-----------------------------------------------------
-- Ladle web server
-- Version 0.1.2
-- Original work Copyright (c) 2008 Samuel Saint-Pettersen (original author)
-- Modified work Copyright (c) 2015 Daniel Rempel
-- Released under the MIT License
-----------------------------------------------------

Server = "Ladle"
ServerVersion = "0.1.2"

-- load required modules
socket = require('socket')

-- load server components
ladleutil = require('ladleutil')

-- load configuration file
-- TODO: have a default array with config and merge with the loaded one
if ladleutil.fileExists('config.lua') then
	config = require('config')
else
	config = nil
end

-- load extensions
extensions = {}

function getHandler(request)
	local handler = nil
	for k,ext in pairs(extensions) do
		if ext["id"] ~= "generic" and ext.match(request["uri"])
		then
			handler = ext.handler
			break
		end
	end
	-- no specific match, use generic handler
	if not handler
	then
		handler = extensions["generic"].handler
	end
	return handler
end

-- checks whether the root index file is requested and finds an appropriate
-- one if needed
function checkURI(uri)
	-- if index file was requested
	-- loop til' the first index.* file found
	if(uri == "")
	then
		if ladleutil.fileExists(config["webroot"] .. "index.html")
		then
			uri = "index.html"
		else
			local wrootIndex = ladleutil.scandir(config["webroot"])
			local chosenIndex = ""

			for k,v in pairs(wrootIndex) do
			if v:match("index.*")
			then
				chosenIndex = "" .. v
				break
			end
			end
			uri = chosenIndex
		end
	end
	return uri
end

function serve(request, client)

	request["uri"] = checkURI(request["uri"])

	-- find an appropriate handler in extensions
	local handler = getHandler(request)

	-- Got a handler, run it
	handler(request, client, config)

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

function loadExtensions()
	local extdir = "extensions/"
	local files = ladleutil.scandir(extdir)
	for i,v in pairs(files) do
		if v:match("^.+%.lua$")
		then
			local extfile = io.open(extdir .. v, "r")
			local extcode
			if extfile
			then
				extcode = extfile:read("*all")
			end

			if extcode
			then
				local extf, message = load(extcode)
				if not message
				then
					local ext = extf()
					extensions[ext['id']] = ext
					print(("Extension %q loaded successfully"):format(ext['name']))
				else
					print(("Failed to load extension %s: %q"):format(v, message))
				end
			end
		end
	end
end

-- start web server
function main(arg1)
	loadExtensions()

	-- command line argument overrides config file entry:
	local port = arg1
	-- if no port specified on command line, use config entry:
	if port == nil then port = config['port'] end
	-- if still no port, fall back to default port, 80:
	if port == nil then port = 80 end

	-- load hostname from config file:
	local hostname = config['hostname']
	if hostname == nil then hostname = '*' end -- fall back to default
	
	if config["webroot"] == "" or config["webroot"] == nil
	then
		config["webroot"] = "www/"
	end

	-- display initial program information
	print(("%s web server v%s"):format(Server,ServerVersion))
	print("Copyright (c) 2008 Samuel Saint-Pettersen")
	print("Copyright (c) 2015 Daniel Rempel")

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
