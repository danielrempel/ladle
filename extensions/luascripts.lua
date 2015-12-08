local extension = {}

ladleutil = require('ladleutil')

function extension.handler(request, client, config)
	tmp_lua_script_output_buffer = ""
	local newEnv = _ENV
		newEnv["write"] = function(text) tmp_lua_script_output_buffer = tmp_lua_script_output_buffer .. text end
	
	local file_l = io.open("www/" .. request["uri"], "r")
	if file_l
	then
		local code = file_l:read("*all")
		local func, message = load(code, request["uri"],"bt", newEnv)
		if not func
		then
			-- TODO : link to ladle's generic err
			client:send("HTTP/1.1 500 Internal server error\r\nServer: Ladle\r\n")
			client:send("Content-Type: text/plain\r\n\r\n")
			client:send(message)
			return
		end
		local retval = pcall(func, function(err) tmp_lua_script_output_buffer = tmp_lua_script_output_buffer .. "\nError: " .. err end)
		client:send(tmp_lua_script_output_buffer)
		return
	else
		-- TODO : link to ladle's generic err
		client:send("HTTP/1.1 404 Not Found\r\nServer: Ladle\r\n")
		client:send("Content-Type: text/plain\r\n\r\n")
	end
end

function extension.match(filename)
	return (filename:match(".+%.lua$") ~= nil)
end

extension.id = "luaScripts"
extension.name = "Lua scripts (.lua) handler"

return extension
