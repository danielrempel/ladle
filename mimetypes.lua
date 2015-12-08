local mimetypes = {}

function mimetypes.getMime(ext)
	if ext == ""
	then
		return mimetypes['mconf']['.html']['mime']
	else
		return mimetypes['mconf'][ext]['mime']
	end
end
function mimetypes.isBinary(ext)
	if ext == ""
	then
		return mimetypes['mconf']['.html']['bin']
	else
		return mimetypes['mconf'][ext]['bin']
	end
end

mimetypes["mconf"] = {

	[".html"] = {
		["mime"] = "text/html",
		["bin"] = false,
		},
	[".xml"] = {
		["mime"] = "application/xml",
		["bin"] = false,
		},
	[".txt"] = {
		["mime"] = "text/plain",
		["bin"] = false,
		},
	[".css"] = {
		["mime"] = "text/css",
		["bin"] = false,
		},
	[".js"] = {
		["mime"] = "application/x-javascript",
		["bin"] = false,
		},
		
	[".jpg"] = {
		["mime"] = "image/jpeg",
		["bin"] = true,
		},
	[".jpeg"] = {
		["mime"] = "image/jpeg",
		["bin"] = true,
		},
	[".png"] = {
		["mime"] = "image/png",
		["bin"] = true,
		},
	[".gif"] = {
		["mime"] = "image/gif",
		["bin"] = true,
		},
	[".ico"] = {
		["mime"] = "image/x-icon",
		["bin"] = true,
		},

}

return mimetypes
