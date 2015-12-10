local ladleutil = {}

mime = require('mimetypes')

function ladleutil.scandir(directory)
    local i, t, popen = 0, {}, io.popen
    for filename in popen('ls -a "'..directory..'"'):lines() do
        i = i + 1
        t[i] = filename
    end
    return t
end

function ladleutil.getRequestedFileInfo(request)
	local file = request["uri"]

	-- retrieve mime type for file based on extension
	local ext = string.match(file, "%.%l%l%l?%l?$") or ""
	local mimetype = mime.getMime(ext)

	local flags
	if mime.isBinary(ext) == false then
		-- if file is ASCII, use just read flag
		flags = "r"
	else
		-- otherwise file is binary, so also use binary flag (b)
		-- note: this is for operating systems which read binary
		-- files differently to plain text such as Windows
		flags = "rb"
	end

	return file, mimetype, flags
end

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

function ladleutil.parseQueryString(query_string)
	-- From lua-wiki
	local urldecode = function (str)
							str = string.gsub (str, "+", " ")
							str = string.gsub (str, "%%(%x%x)",
									function(h) return string.char(tonumber(h,16)) end
								)
							str = string.gsub (str, "\r\n", "\n")
							return str
						end

	local retval = {}

	while query_string:len()>0 do
		local a,b = query_string:find('=')
		local c = nil
		local index = query_string:sub( 0, a-1 )
		b,c = query_string:find('&')
		local value = ""
		if b
		then
			value = query_string:sub( a+1, b-1 )
			query_string = query_string:sub(b+1)
		else
			value = query_string:sub( a+1 )
			query_string = ""
		end

		index = urldecode(index)

		retval[index] = urldecode(value)
	end
	return retval
end

function ladleutil.parseRequest(request)
	local request_table = {}
	local request_text = request

	local line = ""

	local a,b = request_text:find("\r*\n")
	if not a or not b
	then
		ladleutil.trace("ladleutil.parseRequest(request):")
		ladleutil.trace("Suspicious request:")
		ladleutil.trace(request)
		ladleutil.trace("=======================================================")
		ladleutil.trace("Newlines (\\r\\n) not found")

		return {}
	end

	repeat
		local a,b = request_text:find("\r*\n")
		line = request_text:sub(0,a-1)
		request_text = request_text:sub(b+1)
	until line:len() > 0

	request_table["method"],request_table["url"],request_table["protocol"] = line:match("^([^ ]-) +([^ ]-) +([^ ]-)$")

	while request_text:len() > 0 do
		local a,b = request_text:find("\r*\n")
		local line = request_text:sub(0,a-1)
		request_text = request_text:sub(b+1)

		if line:len()>0
		then
			local key, value = line:match("^([^:]*): +(.+)$")
			request_table[key] = value
		end
	end

	query_string = (request_table["url"]):match("^/[^?]*%??(.*)$") or ""
	uri = (request_table["url"]):match("^/([^?]*)%??.*$") or ""

	request_table["query_string"] = query_string -- TODO: base64 decode?
	request_table["query"] = ladleutil.parseQueryString(query_string)
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

function ladleutil.trace(message)
	print(os.date() .. ": " .. message)
end

return ladleutil
