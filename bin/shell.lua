local currentDir = "/"

local function isFile(path)
    return fs.exists(path) and not fs.isDir(path)
end

local function resolvePath(cmd)
    if string.sub(cmd, 1, 1) == "/" and isFile(cmd) then
        return cmd
    end

    local locations = {
        fs.combine(currentDir, cmd),
        fs.combine("/usr/bin", cmd),
        fs.combine("/rom/programs", cmd)
    }

    for _, path in ipairs(locations) do
        if isFile(path) then
            return path
        end
    end

    return nil
end

local function split(str)
    local parts = {}
    for part in string.gmatch(str, "[^%s]+") do
        table.insert(parts, part)
    end
    return parts
end

local function drawPrompt()
    term.write("root@" .. os.getComputerLabel() or "computer" .. ":" .. currentDir .. "# ")
end

local function listDir(path)
    path = fs.combine(currentDir, path or "")
    if not fs.exists(path) or not fs.isDir(path) then
        printError("No such directory")
        return
    end

    local items = fs.list(path)
    table.sort(items)
    for _, item in ipairs(items) do
        if fs.isDir(fs.combine(path, item)) then
            print(item .. "/")
        else
            print(item)
        end
    end
end

local function runBuiltIn(cmd, args)
    if cmd == "cd" then
        local target = fs.combine(currentDir, args[1] or "/")
        if fs.exists(target) and fs.isDir(target) then
            currentDir = fs.combine("/", target)
        else
            printError("No such directory")
        end

    elseif cmd == "ls" then
        listDir(args[1])

    elseif cmd == "clear" then
        term.clear()
        term.setCursorPos(1,1)

    elseif cmd == "id" then
        print("uid=0(root) gid=0(root) groups=0(root)")

    elseif cmd == "reboot" then
        os.reboot()

    elseif cmd == "pwd" then
        print(currentDir)

    elseif cmd == "mkdir" then
        if not args[1] then
            printError("Usage: mkdir <dir>")
        else
            local dir = fs.combine(currentDir, args[1])
            if fs.exists(dir) then
                printError("File or directory already exists")
            else
                fs.makeDir(dir)
            end
        end

    elseif cmd == "rm" then
        if not args[1] then
            printError("Usage: rm <file>")
        else
            local path = fs.combine(currentDir, args[1])
            if not fs.exists(path) then
                printError("No such file or directory")
            else
                fs.delete(path)
            end
        end

    elseif cmd == "cat" then
        if not args[1] then
            printError("Usage: cat <file>")
        else
            local path = fs.combine(currentDir, args[1])
            if not isFile(path) then
                printError("No such file")
            else
                local f = fs.open(path, "r")
                print(f.readAll())
                f.close()
            end
        end

    elseif cmd == "exit" then
        return false

    else
        return nil
    end

    return true
end

local function runProgram(path, args)
    local env = {}
    setmetatable(env, { __index = _G })
    local ok, err = os.run(env, path, table.unpack(args))
    if not ok then
        printError(err)
    end
end

-- Main loop
while true do
    drawPrompt()
    local input = read()
    if input and input ~= "" then
        local args = split(input)
        local cmd = table.remove(args, 1)

        local builtIn = runBuiltIn(cmd, args)
        if builtIn == false then
            break
        elseif builtIn == nil then
            local resolved = resolvePath(cmd)
            if resolved then
                runProgram(resolved, args)
            else
                printError("Command not found: " .. cmd)
            end
        end
    end
end
