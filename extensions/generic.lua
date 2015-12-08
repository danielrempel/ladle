local extension = {}

ladleutil = require('ladleutil')

function extension.handler(request, client, config)
	local file, mimetype, flags = ladleutil.getRequestedFileInfo(request)

	local served = io.open(config["webroot"] .. file, flags)
	if served ~= nil then
		client:send("HTTP/1.1 200/OK\r\nServer: Ladle\r\n")
		client:send("Content-Type:" .. mimetype .. "\r\n\r\n")

		local content = served:read("*all")
		client:send(content)
	else
		-- TODO : link to ladle's generic err
		client:send("HTTP/1.1 404 Not Found\r\nServer: Ladle\r\n")
		client:send("Content-Type: text/plain\r\n\r\n")

		ladleutil.err("Not found!", client)
	end
end

function extension.match(filename)
	return true
end

extension.id = "generic"
extension.name = "Generic/Static file handler"

return extension
