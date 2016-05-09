# TALyx
Lyx pipe implementation for textadept editor.

TALyx is a plugin for textadept editor which allows applications that using lyx pipe to connect textadept and send commands to it.

## Installation
Just clone this repository to your `~/.textadept/modules` directory and add following line to `~/.textadept/init.lua`

``` lua
require "talyx"
```

## Settings
At the moment pipe path is hardcoded in `init.lua` at the first lines.

``` lua
local input_pipe = ".lyxpipe.in"
local output_pipe = ".lyxpipe.out"

if WIN32 then
  input_pipe = "\\\\.\\pipe\\" .. input_pipe
  output_pipe = "\\\\.\\pipe\\" .. output_pipe
else
  input_pipe = os.getenv("HOME") .. "/" .. input_pipe
  output_pipe = os.getenv("HOME") .. "/" .. output_pipe
end
```
Feel free to change it.

## Commands
List of supported commands now includes only 5 commands. You may add your own to the `react` table:

``` lua
local react = {
  ["citation-insert"] = insert_citation,
  ["server-get-filename"] = function (client, args)
      return "INFO:"..client..":server-get-filename:"..tostring(buffer.filename).."\n"
    end,
  ["buffer-write"] = function(client, args) io.save_file() end,
  ["server-get-xy"] = function(client, args)
      return "INFO:"..client..":server-get-xy:0,0\n"
    end, -- Not implemented
  ["server-set-xy"] = function(client, args) return end, -- Not implemented
  

}
```
