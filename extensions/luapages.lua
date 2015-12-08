local extension = {}

ladleutil = require('ladleutil')
lfs = require('lfs')

function extension.executeLua(code, luaEnv, errfunc)
	local func, message = load(code, "luapage","bt", luaEnv)
	if not func
	then
		errfunc(message)
		return
	end
	local retval = pcall(func, errfunc)
end

function extension.parseLuaPage(page, luaEnv, appendfunc)
	local current_directory = lfs.currentdir() -- Let the script
	-- have its own dependencies and libs without messing with directories
	lfs.chdir("www/")
	local a,b,c
	while page:len() > 0 do
		a,b = page:find("%<%?")

		if a
		then
			a= a-1
		
			appendfunc(page:sub(0,a))
			page = page:sub(b+1)
					
			a,c = page:find("%?%>")
			if not a
			then
				appendfunc("\nError: matching '?>' not found!\n")
				page = ""
			else
				a=a-1
				local code = page:sub(1,a)
								
				extension.executeLua(code, luaEnv, function (err) appendfunc("Error: " .. err) end)
				page = page:sub(c+1)
			end
		else
			appendfunc(page)
			page = ""
		end
	end
	lfs.chdir(current_directory)
end

function extension.handler(request, client, config)
	tmp_lua_script_output_buffer = ""
	local newEnv = _ENV
	newEnv["write"] =	function(text)
							tmp_lua_script_output_buffer = tmp_lua_script_output_buffer .. text
						end
	
	local file_l = io.open("www/" .. request["uri"], "r")
	if file_l
	then
		local page = file_l:read("*all")
		extension.parseLuaPage(page, newEnv, function(text) tmp_lua_script_output_buffer = tmp_lua_script_output_buffer ..  text end)
		
		-- TODO: transform newlines
		client:send(tmp_lua_script_output_buffer)
		return
	else
		-- TODO : link to ladle's generic err
		client:send("HTTP/1.1 404 Not Found\r\nServer: Ladle\r\n")
		client:send("Content-Type: text/plain\r\n\r\n")
		client:send("Sorry! The requested page not found")
	end
end

function extension.match(filename)
	return (filename:match(".+%.lp$") ~= nil)
end

extension.id = "luaPages"
extension.name = "LuaPages handler (.lp)"

return extension
