local input_pipe = ".lyxpipe.in"
local output_pipe = ".lyxpipe.out"

if WIN32 then
  input_pipe = "\\\\.\\pipe\\" .. input_pipe
  output_pipe = "\\\\.\\pipe\\" .. output_pipe
else
  input_pipe = os.getenv("HOME") .. "/" .. input_pipe
  output_pipe = os.getenv("HOME") .. "/" .. output_pipe
end
local running = true

local function insert_citation(client, reference)
  local pos = buffer.current_pos
  buffer:insert_text(pos, "\\cite{"..reference.."}")
end

local function file_exist(filename)
  local f = io.open(filename, "r")
  if f == nil then return false end
  io.close(f)
  return true
end

function renew(filename)
  local f = io.open(filename, "w")
  if f == nil then
    return false
  else
    f:close()
    return true
  end
end



local defval = {
  __index = function(t, k)
      local retfunc = function(client, args)
        ui.print("Unknown message: "..tostring(k).."("..tostring(args)..
          ") from client "..client)
      end
      return retfunc
    end
}

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

setmetatable(react, defval)

local function onexit()
  running = false
  os.remove(input_pipe)
  os.remove(output_pipe)
end



local function process_message(message)
  req, client, command, argument = message:match("([^:]+):([^:]+):([^:]+):?([^:]*).*")
  if req ~= "LYXCMD" then
    return
  end
  return (react[command])(client, argument)
end

local function check_updates(ip, op)
  
  local message = ip:read()
  
  if message ~= nil then
    local answer = process_message(message)
    if answer ~= nil then
      op:write(answer)
    end
    op:flush()
  end
  
  if not running then
    op:close()
    ip:close()
    onexit()
    return false
  end
  return true
end

local function onload()
  --os.execute("mkfifo -m 0600 "..input_pipe)
  if WIN32 then
    renew(output_pipe)
  else
    os.execute("mkfifo -m 0600  "..output_pipe)
  end
  renew(input_pipe)
  local op = io.open(output_pipe, "r+")
  if op == nil then
    ui.print("Error in lyxpipe: broken output pipe!")
    onexit()
    return false
  end
  local ip = io.open(input_pipe, "r")
  if ip == nil then
    ui.print("Error in lyxpipe: broken input pipe!")
    onexit()
    return false
  end
  running = true
  timeout(1, check_updates, ip, op)
end

events.connect(events.QUIT, onexit)
events.connect(events.RESET_BEFORE, onexit)
onload()
