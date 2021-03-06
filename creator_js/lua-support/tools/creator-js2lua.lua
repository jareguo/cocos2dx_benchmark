
-- Convert Creator JS project to Lua

local json = require "json_pure_lua"
local dumpval = require "dumpval"

local _error = error

local function help()
    print [[

lua creator-js2lua.lua js-build-dir out-dir

options:
    js-build-dir The directory of Creator project build
    out-dir Lua Project directory

examples:

    lua creator-js2lua.lua my-game-js/build/web-mobile my-game-lua

]]
end

local function pathinfo(path)
    local pos = string.len(path)
    local extpos = pos + 1
    while pos > 0 do
        local b = string.byte(path, pos)
        if b == 46 then -- 46 = char "."
            extpos = pos
        elseif b == 47 then -- 47 = char "/"
            break
        end
        pos = pos - 1
    end

    local dirname  = string.sub(path, 1, pos)
    local filename = string.sub(path, pos + 1)

    extpos = extpos - pos
    local basename = string.sub(filename, 1, extpos - 1)
    local extname  = string.sub(filename, extpos)

    return {
        dirname  = dirname,
        filename = filename,
        basename = basename,
        extname  = extname
    }
end

local function checkdir(dir)
    local lastchar = dir[#dir]
    if lastchar == "/" or lastchar == "\\" then
        return string.sub(dir, 1, -2)
    else
        return dir
    end
end

local function mkdir(dir)
    local command = string.format("if [ ! -d %s ]; then mkdir -p %s; fi", dir, dir)
    local ok, status, code = os.execute(command)
    if not ok or status ~= "exit" or code ~= 0 then
        _error(string.format("Create directory %s failed", dir))
    end
end

local function copyfile(src, dst)
    local pi = pathinfo(dst)
    mkdir(pi.dirname)

    local command = string.format("cp %s %s", src, dst)
    local ok, status, code = os.execute(command)
    if not ok or status ~= "exit" or code ~= 0 then
        _error(string.format("Copy file %s to %s failed", src, dst))
    end

    print(string.format("Copy file %s", dst))
end

local function readfile(filename)
    local file, err = io.open(filename, "rb")
    if not file then
        _error(string.format("Open file %s failed", filename))
    end

    local contents = file:read("*a")
    io.close(file)

    if not contents then
        _error(string.format("Read file %s failed", filename))
    end

    print(string.format("Read file %s", filename))
    return contents
end

local function writefile(filename, contents)
    local pi = pathinfo(filename)
    mkdir(pi.dirname)

    mode = "w+b"
    local file = io.open(filename, mode)
    if not file or not file:write(contents) then
        _error(string.format("Write file %s failed", filename))
    end

    io.close(file)
    print(string.format("Write file %s", filename))
end

local function validateLuaFile(filename)
    local ok, err = loadfile(filename)
    if not ok then
        _error(string.format("Valid file %s failed", filename))
    end
    return true
end

local removeNullFromJson
removeNullFromJson = function(jsonval)
    for k, v in pairs(jsonval) do
        if v == json.null then
            jsonval[k] = nil
        elseif type(v) == "table" then
            removeNullFromJson(v)
        end
    end
end

local convertId
convertId = function(val)
    for k, v in pairs(val) do
        if k == "__id__" then
            if type(v) ~= "number" then
                _error(string.format("Found invalid __id__, key: %s, value: %s", tostring(k), tostring(v)))
            end
            val[k] = v + 1
        elseif type(v) == "table" then
            convertId(v)
        end
    end
end

local function loadAssets(builddir, uuid)
    local pattern = "%s/res/import/%s/%s.json"
    local path = string.format(pattern, builddir, string.sub(uuid, 1, 2), uuid)
    local contents = readfile(path)
    local val = json.parse(contents)
    removeNullFromJson(val)
    convertId(val)

    if type(val["__type__"]) ~= "string" then
        return {
            ["__type__"] = "__js_array__",
            ["__js_array__"] = val,
        }
    else
        return val
    end
end

local function dumpToLuaFile(filename, varname, var)
    local lines = dumpval.dumpval(var, string.format("local %s =", varname), "", true)
    table.insert(lines, 1, "")
    lines[#lines + 1] = ""
    lines[#lines + 1] = string.format("return %s", varname)
    lines[#lines + 1] = ""
    contents = table.concat(lines, "\n")
    writefile(filename, contents)
    validateLuaFile(filename)
end

----

local args = {...}

if #args < 2 then
    help()
    os.exit(1)
end

local builddir = checkdir(args[1])
local outdir = checkdir(args[2])

-- prepare
mkdir(outdir)

-- step 1
-- convert settings.js to settings.lua
local contents = readfile(builddir .. "/src/settings.js")
local settings = json.parse(string.gsub(contents, "_CCSettings = {", "{"))
dumpToLuaFile(outdir .. "/src/assets/settings.lua", "settings", settings)

-- step 2
-- load all json files form res/import, write to import.lua
local rawAssets = settings.rawAssets
local assetsdb = {}
local filesdb = {}
for _, key in pairs({"assets", "internal"}) do
    for uuid, asset in pairs(rawAssets[key]) do
        if asset.raw == false then
            assetsdb[uuid] = loadAssets(builddir, uuid)
        else
            if key == "internal" then
                filesdb[uuid] = "raw-internal/" .. asset.url
            else
                filesdb[uuid] = "raw-assets/" .. asset.url
            end
        end
    end
end
dumpToLuaFile(outdir .. "/src/assets/assetsdb.lua", "assetsdb", assetsdb)
dumpToLuaFile(outdir .. "/src/assets/filesdb.lua", "filesdb", filesdb)

-- step 3
-- copy all raw asset files
for _, filename in pairs(filesdb) do
    copyfile(builddir .. "/res/" .. filename, outdir .. "/res/" .. filename)
end
