local ladleutil = {}

function ladleutil.fileExists(filename)
	local f = io.open(filename, 'r')
	if f then
		f:close()
		return true
	else
		return false
	end
end

function ladleutil.receiveHTTPRequest(client)
	local request = ""
	local line,err = ""
	repeat
		local line, err = client:receive("*l")
		if line
		then
			request = request .. "\r\n" .. line
		end
	until not line or line:len()==0 or err
	return request,err
end

function ladleutil.parseRequest(request)
	
	print("parseRequest: " .. request)
	
	local request_table = {}
	local request_text = request

	local line = ""

	repeat
		local a,b = request_text:find("\r*\n")
		line = request_text:sub(0,a-1)
		request_text = request_text:sub(b+1)
	until line:len() > 0

	print(("Parsing first line: %q"):format(line))

	request_table["method"],request_table["url"],request_table["protocol"] = line:match("^(.-) +(.-) +(.-)$")

	while request_text:len() > 0 do
		local a,b = request_text:find("\r*\n")
		local line = request_text:sub(0,a-1)
		request_text = request_text:sub(b+1)

		print("Parsing line: " .. line)

		if line:len()>0
		then
			local key, value = line:match("^(.-): +(.+)$")
			print( ("%s=%q"):format(key or "nil",value or "nil") )
			request_table[key] = value
		end
	end
	
	query_string = (request_table["url"]):match("^/[a-zA-Z.,0-9/]*%??(.*)$") or ""
	print(("url: %q"):format(request_table["url"]))
	uri = (request_table["url"]):match("^/([a-zA-Z.,0-9/]*)%??.*$") or ""
	
	request_table["query_string"] = query_string -- TODO: base64 decode?
	request_table["uri"] = uri
	
	return request_table
end

-- decides which prep to run etc
function ladleutil.prepMain(request, client)

end

-- display error message and server information
-- used while serving pages (for different errors like 404, 500 etc)
function ladleutil.err(message,client)
	client:send(message)
	client:send("\n\nLadle web server\n")
end

return ladleutil
