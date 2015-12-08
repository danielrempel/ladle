local generic = {}

ladleutil = require('ladleutil')

function generic.handler(request, client, config)
	local file, mimetype, flags = ladleutil.getRequestedFileInfo(request)

	local served = io.open(config["webroot"] .. file, flags)
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
end

function generic.match(filename)
	return true
end

generic.id = "generic"
generic.name = "Generic/Static file handler"

return generic
