## Ladle web server

Prerequisites:

* Lua interpreter
* LuaSocket

Lua integration:
 * Lua scripts interpretation with own API (.lua)
 * Own lua pages implementation (.lp)

Lua pages:
```
<headers>\r\n
\r\n
<html code>
<? lua code ?>
<html code>
....
```

Index page logic:

Looks for any available index pages: plain html, lua page, lua script (.html, .lp, .lua)

To start the Ladle web server:
```
$ lua ladle.lua <port>
```

To stop the Ladle web server:
 * Run "telin" script followed by port number
 * Type "kill" and hit return

(or just press Ctrl+C twice in the terminal ladle runs in)
