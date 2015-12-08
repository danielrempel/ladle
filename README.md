## Ladle web server
Simple lua-based web server with minimal dependencies.

Has a simplistic mechanism for extensions, which avails to extend server's functionality by adding handlers for specific filetypes. See `extensions/generic.lua`
No pages other than index file for web root directory should match `index*`, otherwise they may be treated as index pages and be shown instead of actual index.

Configuration is stored in config.lua. In case the file doesn't exist or lacks fields, Ladle falls back to default values.

Prerequisites:

* Lua interpreter
* LuaSocket

### Lua integration:
Via modules:
 * Lua scripts (.lua)
 * Lua pages (.lp)

### Lua pages:
```
<http response headers>\r\n
\r\n
<html code>
<? lua code ?>
<html code>
....
```

To start the Ladle web server:
```
$ lua Ladle.lua
```
The server supports one command line parameter: port
All other parameters are set in the config file.

Still no way to stop the server gently, only ^C^C in the terminal.
