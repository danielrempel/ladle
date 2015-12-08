## Ladle web server
Simple lua-based web server with minimal dependencies.

Has a simplistic mechanism for extensions, which avails to extend server's functionality by adding handlers for specific filetypes. See `extensions/generic.lua`
No pages other than index file for web root directory should match `index*`, otherwise they may be treated as index pages and be shown instead of actual index.

Prerequisites:

* Lua interpreter
* LuaSocket


To start the Ladle web server:
```
$ lua ladle.lua <port>
```

Still no way to stop the server gently, only ^C^C in the terminal.
