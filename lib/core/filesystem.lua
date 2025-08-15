-- /lib/core/filesystem.lua
-- Provides core filesystem functionality for SolunaOS

-- Food for thought, these probably will get used as bin calls so throwing errors will be refactored once in prod

local disk = _G.disk or require("disk")
local os = require("os")

local filesystem = {}

    --- Splits a filesystem path into its directories
    --- @param abs_path string
    --- @return table directories
    function filesystem.splitPath(abs_path)
        local directories = {}
        for directory in abs_path:gmatch("[^/]+") do
            table.insert(directories, directory)
        end
        return directories
    end

    --- Validate object type
    ---@param abs_path string
    ---@param mode string: "s" (string), "f" (file), "d" (directory), "t" (table), or "n" (number)
    ---@return boolean result
    ---@return string|nil error
    ---@return table|nil path_table only if "f" or "d"
    function filesystem.validateType(abs_path, mode)
        if mode ~= "s" and mode ~= "f" and mode ~= "d" and mode ~= "t" and mode ~= "n" then
            return false, "bad argument (mode): invalid mode, must be 's', 'f', 'd', 't', or 'n'"
        end
        if mode == "n" then
            if type(abs_path) ~= "number" then
                return false, "number expected, got " .. type(abs_path)
            end
            return true, nil, nil
        end

        if mode == "t" then
            if type(abs_path) ~= "table" then
                return false, "table expected, got " .. type(abs_path)
            end
            return true, nil, nil
        end

        if type(abs_path) ~= "string" then
            return false, "string expected, got " .. type(abs_path)
        end
        if mode == "s" then
            return true, nil, nil
        end
        
        local path_table = filesystem.getPathTable(abs_path)
        if not path_table then
            return false, "File or directory does not exist"
        end
        if mode == "f" and path_table.type ~= "file" then
            return false, "File expected, got " .. path_table.type
        elseif mode == "d" and path_table.type ~= "dir" then
            return false, "Directory expected, got " .. path_table.type
        end
        return true, nil, path_table
    end

    --- Converts absolute path to relative path and file name
    --- Sets file_path to root if no directory
    --- @param abs_path string
    --- @return string file_path
    --- @return string file_name
    function filesystem.validatePath(abs_path)
        assert(type(abs_path) == "string", "string expected, got " .. type(abs_path))
        local file_path, file_name = abs_path:match("^(.*)/([^/]+)$")
            -- Sets path to root if file_path is empty
            if not file_path or file_path == "" then
                file_path = "/"
            end
        return file_path, file_name
    end

    --entries is for the mock file system. replace once real fs is implemented
    -- this and split path are needed for mock system. look at filesystem component api for details.
    function filesystem.getPathTable(abs_path)
        local path_table = disk["/"]
        if abs_path == "/" then
            return path_table
        end
        local directories = filesystem.splitPath(abs_path)
        for _, directory in ipairs(directories) do
            if not path_table or not path_table.entries or not path_table.entries[directory] then
                return nil
            end
            path_table = path_table.entries[directory]
        end
        return path_table
    end

    function filesystem.open(absolute_path, mode)
        local args = {absolute_path, mode}
        
        for _, arg in ipairs(args) do
            local ok, err = filesystem.validateType(arg, "s")
            if not ok then
                return nil, err
            end
        end

        if mode ~= "r" and mode ~= "w" and mode ~= "a" and mode ~= "rb" and mode ~= "wb" and mode ~= "ab" then
            local err = "bad argument (mode): invalid mode"
            error(err)
        end

        -- Read mode, pulls file path and contents
        if mode == "r" or mode == "rb" then
            local ok, err, path_table = filesystem.validateType(absolute_path, "f")
            if not ok then
                error(err)
            end
            return {table = path_table, mode = mode, position = 1}

        -- Write mode, creates a new file or overwrites an existing one
        elseif mode == "w" or mode == "wb" then
            local file_path, file_name = filesystem.validatePath(absolute_path)
            local ok, err, parent_table = filesystem.validateType(file_path, "d")
            if not ok then
                error(err)
            end
            parent_table.entries[file_name] = {type = "file", data = "", size = 0, modified = os.uptime()}
            return {table = parent_table.entries[file_name], mode = mode, position = 1}

        elseif mode == "a" or mode == "ab" then
            local file_path, file_name = filesystem.validatePath(absolute_path)
            local ok, err, parent_table = filesystem.validateType(file_path, "d")
            if not ok then
                error(err)
            end

            if not parent_table.entries[file_name] or parent_table.entries[file_name].type ~= "file" then
                parent_table.entries[file_name] = {type = "file", data = "", size = 0, modified = os.uptime()}
            end
            local file = parent_table.entries[file_name]
            return {table = file, mode = mode, position = #file.data + 1}
        end
    end

    function filesystem.read(file, index_position)
        local ok, err = filesystem.validateType(file, "t")
        if not ok then
            return nil, error
        end

        local ok, err = filesystem.validateType(file.table, "f")
        if not ok then
            return nil, error
        end

        local file_data = file.table.data or ""
        local position = file.position or 1
        local file_length = #file_data

        if not index_position then
            index_position = file_length - position + 1
        end

        if position > file_length then
            return "", "End of file reached"
        end

        local return_data = file_data:sub(position, position + index_position - 1)
        file.position = position + #return_data
        return return_data
    end

    --- Close an open file.
    --- @param file table
    --- @return boolean|nil result
    --- @return string|nil error
    function filesystem.close(file)
        local ok, err = filesystem.validateType(file, "t")
        if not ok then
            return nil, err
        end
        file.closed = true
        if file.closed == true then
            return true
        else
            return false, "unable to close file"
        end
    end

    function filesystem.seek(file, position, reference_point)
        local ok, err = filesystem.validateType(file, "t")
        if not ok then
            error(err)
        end

        local ok, err = filesystem.validateType(file.table, "f")
        if not ok then
            error(err)
        end

        local ok, err = filesystem.validateType(file.table, "n")
        if not ok then
            error(err)
        end

        reference_point = reference_point or "set"
        local filesize = #file.table.data
        local new_pos = file.position

        if reference_point == "set" then
            new_pos = position
        elseif reference_point == "cur" then
            new_pos = file.position + position
        elseif reference_point == "end" then
            new_pos = filesize + position
        else
            return nil, "bad argument (refernce_point): invalid value, must be set to 'set', 'cur', or 'end'"
        end

        if new_pos < 1 then
            new_pos = 1
        end
        if new_pos > filesize then
            new_pos = filesize
        end
        file.position = new_pos
        return new_pos
    end

    function filesystem.exists(path)
        local path_table = filesystem.getPathTable(path)
        if path_table then
            return true
        else
            return false
        end
    end

    function filesystem.list(path)
        local ok, err, directory = filesystem.validateType(path, "d")
        if not ok then
            return nil, err
        end

        local locations = {}
        for name in pairs(directory.entries) do
            table.insert(locations, name)
        end
        return locations, nil
    end

    function filesystem.isDirectory(path)
        local real_path = filesystem.getPathTable(path)
        if real_path and real_path.type == "dir" then
            return true
        else
            return false
        end
    end

    --- Creates a directory in the desired path.
    ---@param path string
    ---@return true|nil result
    ---@return nil|string error
    function filesystem.makeDirectory(path)
        if type(path) ~= "string"  or path == "" or path == "/" then
            return nil, "bad argument (path): invalid directory path"
        end

        local parent_path, dir_name = filesystem.validatePath(path)

        local ok, err, parent_table = filesystem.validateType(parent_path, "d")
        if not ok then
            error(err)
        end

        if parent_table.entries[dir_name] then
            return nil, "Directory already exists"
        end

        parent_table.entries[dir_name] = {
            type = "dir",
            entries = {},
            modified = os.uptime()
        }
        return true, nil
    end

    local function recursionCopy(copy_directory)
        if copy_directory.type == "dir" then
            local new_directory = {
                                    type = "dir",
                                    entries = {}
                                    }
            for directory, file in pairs(copy_directory.entries) do
                new_directory.entries[directory] = recursionCopy(file)
            end
            return new_directory
        elseif copy_directory.type == "file" then
            return {
                type = "file",
                data = copy_directory.data,
                size = copy_directory.size,
                modified = copy_directory.modified
            }
        end
    end

    function filesystem.recursionRemove(target_directory)
        if type(target_directory) ~= "string" or target_directory == "" then
            return nil, "bad argument (target_directory): directory expected"
        end

        local parent_path, name = filesystem.validatePath(target_directory)

        local ok, err, parent = filesystem.validateType(parent_path, "d")
        if not ok then
            error(err)
        end

        local target = parent.entries[name]
        if not target then
            return nil, "bad argument (target_directory): directory does not exist"
        end

        if target.type == "dir" then
            for child_name in pairs(target.entries) do
                filesystem.recursionRemove(target_directory .. "/" .. child_name)
            end
        end

        parent.entries[name] = nil
        return true
    end

    function filesystem.copy(source, destination)
        
        local source_file = filesystem.getPathTable(source)
        if not source_file or source_file.type ~= "file" and source_file.type ~= "dir" then
            error("bad argument (source): does not exist")
        end

        if source_file.type == "dir" and destination:sub(1, #source) == source then
            error("bad argument (destination): cannot copy self")
        end

        local destination_parent_path, destination_name = filesystem.validatePath(destination)

        local ok, err, destination_parent_table = filesystem.validateType(destination_parent_path, "d")
        if not ok then
            error(err)
        end

        if destination_parent_table.entries[destination_name] then
            error("bad argument (destination): file already exists")
        end

        destination_parent_table.entries[destination_name] = recursionCopy(source_file)
        return true
    end

    function filesystem.move(origin, destination)
        local settings = {"f", "d"}
        local results = {}
        local ok, err, origin_table
        for _, setting in ipairs(settings) do
            ok, err, origin_table = filesystem.validateType(origin, setting)
            if not ok then
                table.insert(results, err)
            end
        end

        if #results == #settings then
            return nil, "bad argument (origin): does not exist"
        end

        if origin_table.type == "dir" and destination:sub(1, #origin) == origin then 
            return nil, "bad argument (destination): cannot move self"
        end

        local _, origin_name = filesystem.validatePath(origin)

        if not origin_table or origin_table.type ~= "dir" then
            return nil, "bad argument (origin): directory does not exist"
        end
        if origin_table.entries[origin_name] then
            return nil, "bad argument (origin): file already exists"
        end

        local destination_parent_path, destination_name = filesystem.validatePath(destination)

        local ok, err, destination_table = filesystem.validateType(destination_parent_path, "d")
        if not ok then
            error(err)
        end

        if destination_table.entries[destination_name] then
            return nil, "bad argument (destination): file already exists"
        end

        destination_table.entries[destination_name] = origin_table.entries[origin_name]
        origin_table.entries[origin_name] = nil

        return true
    end

    function filesystem.remove(path)
        if type(path) ~= "string" or path == "" or path == "/" then
            return nil, "bad argument (path): invalid path"
        end

        local parent_path, name = filesystem.validatePath(path)

        local ok, err, parent_table = filesystem.getPathTable(parent_path)
        if not ok then
            error(err)
        end

        if not parent.entries[name] then
            return nil, "bad argument (path): file or directory does not exist"
        end

        parent_table.entries[name] = nil
        return true
    end

    function filesystem.getSize(path)
        local structure = filesystem.getPathTable(path)
        if not structure then
            return nil, "bad argument (path): file or directory does not exist"
        end

        if structure.type == "file" then
            return #structure.data
        elseif structure.type == "dir" then
            return 0, "bad argument (path): cannot get size of directory"
        else
            return nil, "bad argument (path): invalid type"
        end
    end

    function filesystem.mount(source, target)
        if type(source) ~= "table" then
            return nil, "bad argument (source): must be a table (disk/storage device)"
        end
        if type(target) ~= "string" or target == "" or target == "/" then
            return nil, "bad argument (target): must be a string (mount point)"
        end

        local parent_path, entry_name = filesystem.validatePath(target)

        local ok, err, parent_table = filesystem.getPathTable(parent_path)
        if not ok then
            return nil, err
        end

        if parent_table.entries[entry_name] then
            return nil, "bad argument (target): mount point already exists"
        end

        parent_table.entries[entry_name] = source

        return true
    end

    function filesystem.unmount(target)
        if type(target) ~= "string" or target == "" or target == "/" then
            return nil, "bad argument (target): must be valid path"
        end

        local parent_path, entry_name = filesystem.validatePath(target)

        local ok, err, parent_table = filesystem.getPathTable(parent_path)
        if not ok then
            return nil, err
        end

        if not parent_table.entries[entry_name] then
            return nil, "bad argument (target): mount point does not exist"
        end

        parent_table.entries[entry_name] = nil
        return true
    end

    function filesystem.tempfile()
        local ok, err, temp_path = filesystem.getPathTable("/tmp")
        if not ok then
            error(err)
        end

        local tries = 0
        local temp_file_name
        repeat
            temp_file_name = "tmp_" .. tostring(os.uptime()) .. "_" .. tostring(math.random(1000, 9999))
            tries = tries + 1
        until not temp_path.entries[temp_file_name] or tries > 100

        if tries > 100 then
            return nil, "Unable to create temporary file with unique name"
        end

        temp_path.entries[temp_file_name] = { 
            type = "file", 
            data = "",
            size = 0,
            modified = os.uptime()
        }
        return "/tmp/" .. temp_file_name
    end
        

    function filesystem.concat(file_path_1, file_path_2)
       if type(file_path_1) ~= "string" then
            return nil, "bad argument (file_path_1): must be a string"
        end

        if type(file_path_2) ~= "string" then
            return nil, "bad argument (file_path_2): must be a string"
        end

        local path_1 = file_path_1:gsub("/+$", "")
        local path_2 = file_path_2:gsub("^/+", "")
        local new_file_path = path_1 .. "/" .. path_2

        if path_1 == "" then
            new_file_path = "/" .. path_2
        end
        
        return new_file_path
    end

return filesystem