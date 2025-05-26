-- Create shell table
local shell = {}

-- Get directories to search, in order
local function getSearchDirs()
  local dirs = {}

  -- 1. Current directory (empty path means just "file")
  table.insert(dirs, "")

  -- 2. /usr/bin (non-recursive)
  for _, file in ipairs(fs.list("/usr/bin")) do
    local full = fs.combine("/usr/bin", file)
    if not fs.isDir(full) then
      table.insert(dirs, "/usr/bin")
      break -- Only need to add once
    end
  end

  -- 3. /rom/programs and all subdirectories (recursive)
  local function recurse(path)
    table.insert(dirs, path)
    for _, file in ipairs(fs.list(path)) do
      local fullPath = fs.combine(path, file)
      if fs.isDir(fullPath) then
        recurse(fullPath)
      end
    end
  end

  recurse("/rom/programs")

  return dirs
end

-- Try to resolve a program name to a path
function shell.resolveProgram(name)
  for _, dir in ipairs(getSearchDirs()) do
    local full1 = fs.combine(dir, name)
    local full2 = full1 .. ".lua"

    if fs.exists(full1) and not fs.isDir(full1) then
      return full1
    elseif fs.exists(full2) and not fs.isDir(full2) then
      return full2
    end
  end

  return nil -- Not found
end

-- Split a string by spaces
local function split(str)
  local t = {}
  for word in string.gmatch(str, "%S+") do
    table.insert(t, word)
  end
  return t
end

-- Reimplement shell.run
function shell.run(...)
  local input = table.concat({...}, " ")
  local args = split(input)
  if #args == 0 then return false end

  local program = args[1]
  local progArgs = {table.unpack(args, 2)}

  local path = shell.resolveProgram(program)
  if not path then
    printError("No such program: " .. program)
    return false
  end

  return os.run({}, path, table.unpack(progArgs))
end