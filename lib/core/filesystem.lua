-- /lib/core/filesystem.lua
-- Provides core filesystem functionality for SolunaOS
-- File metatables not to be confused with Lua object metatables
-- Contents are located in (file or dir).metatable.content

local OS_FILESYSTEM = _G.OS_FILESYSTEM
local os = require("os")

local filesystem = {}

    --- Splits a filesystem path into its directories
    --- @param abs_path string
    --- @return table dirs
    function filesystem.splitPath(abs_path)
        local dirs = {}
        for dir in abs_path:gmatch("[^/]+") do
            table.insert(dirs, dir)
        end
        return dirs
    end

    function filesystem.validateObject(file_object)
        local ok, err = filesystem.validateType(file_object, "t")
        if not ok then
            return false, err
        end
        if not file_object.handle or not file_object.hardware_component then
            return false, "invalid file_object"
        end
        return true, nil
    end

    --- Validate object type
    ---@param abs_path string
    ---@param mode string: "s" (string), "f" (file), "d" (directory), "t" (metatable), or "n" (number)
    ---@return boolean result
    ---@return string|nil error
    function filesystem.validateType(abs_path, mode)
        if mode ~= "s" and mode ~= "f" and mode ~= "d" and mode ~= "t" and mode ~= "n" then
            return false, "bad argument (mode): invalid mode, must be 's', 'f', 'd', 't', or 'n'"
        end
        if mode == "n" then
            if type(abs_path) ~= "number" then
                return false, "number expected, got " .. type(abs_path)
            end
            return true, nil
        end

        if mode == "t" then
            if type(abs_path) ~= "table" then
                return false, "metatable expected, got " .. type(abs_path)
            end
            return true, nil
        end

        if type(abs_path) ~= "string" then
            return false, "string expected, got " .. type(abs_path)
        end
        if mode == "s" then
            return true, nil
        end
        
        if not OS_FILESYSTEM.exists(abs_path) then
            return false, "File or directory does not exist"
        end
        if mode == "f" and OS_FILESYSTEM.isDirectory(abs_path) then
            return false, "File expected, got directory"
        elseif mode == "d" and not OS_FILESYSTEM.isDirectory(abs_path) then
            return false, "Directory expected, got file"
        end
        return true, nil
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

    --- SLATED FOR DELETION PENDING REAL FILESYSTEM INTEGRATION
    --- Gets the path table for a given absolute path.
    --- @param abs_path string
    --- @return table|nil path_table
    function filesystem.getPathMetatable(abs_path)
        local path_metatable = disk["/"]
        if abs_path == "/" then
            return path_metatable
        end
        local directories = filesystem.splitPath(abs_path)
        for _, directory in ipairs(directories) do
            if not path_metatable or not path_metatable.contents or not path_metatable.contents[directory] then
                return nil
            end
            path_metatable = path_metatable.contents[directory]
        end
        return path_metatable
    end

    --- SLATED FOR DELETION PENDING REAL FILESYSTEM INTEGRATION
    function filesystem.getMntMetatable(mnt_disk, abs_path)
        local path_metatable = mnt_disk["/"]
        if abs_path == "/" then
            return path_metatable
        end
        local directories = filesystem.splitPath(abs_path)
        for _, directory in ipairs(directories) do
            if not path_metatable or not path_metatable.contents or not path_metatable.contents[directory] then
                return nil
            end
            path_metatable = path_metatable.contents[directory]
        end
        return path_metatable
    end

    --- Opens a file in the specified mode.
    --- @param abs_path string
    --- @param mode string "r" (read), "w" (write), "a" (append) 
    --- @return table|nil file
    --- @return string|nil error
    function filesystem.open(abs_path, mode)
        
        local args = {abs_path, mode}
        for _, arg in ipairs(args) do
            local ok, err = filesystem.validateType(arg, "s")
            if not ok then
                return nil, err
            end
        end

        if mode ~= "r" and mode ~= "w" and mode ~= "a" and mode ~= "rb" and mode ~= "wb" and mode ~= "ab" then
            local err = "bad argument (mode): invalid mode"
            return nil, err
        end

        -- Read mode, pulls file path and contents
        if mode == "r" or mode == "rb" then
            local ok, err = filesystem.validateType(abs_path, "f")
            if not ok then
                return nil, err
            end
        end

        local handle = OS_FILESYSTEM.open(abs_path, mode)
        if not handle then
            return nil, "Failed to open file: " .. abs_path
        end

        return {
            handle = handle,
            mode = mode,
            hardware_component = OS_FILESYSTEM
        }
    end

    -- Opens file metadata for reading
    ---@param file_object table
    ---@param index_pos number|nil
    ---@return string|nil data
    ---@return string|nil error
    function filesystem.read(file_object, index_pos)
        local ok, err = filesystem.validateObject(file_object)
        if not ok then
            return nil, err
        end

        if index_pos == nil then
            index_pos = math.huge
        else
            local ok, err = filesystem.validateType(index_pos, "n")
            if not ok then
                return nil, err
            end
        end

        local data = file_object.hardware_component.read(file_object.handle, index_pos)

        if data == nil then
            return "", "End of file reached"
        end

        return data, nil
    end

    --- Write data to a file based on file index position.
    --- @param file_object table
    --- @param data string
    --- @return boolean|nil result
    --- @return string|nil error
    function filesystem.write(file_object, data)
        local ok, err = filesystem.validateObject(file_object)
        if not ok then
            return nil, err
        end

        local ok, err = filesystem.validateType(data, "s")
        if not ok then
            return nil, err
        end

        local success = file_object.hardware_component.write(file_object.handle, data)

        if not success then
            return nil, "Failed to write data to file"
        end

        return true, nil
    end

    --- Close an open file.
    --- @param file_object table
    --- @return boolean|nil result
    --- @return string|nil error
    function filesystem.close(file_object)
        local ok, err = filesystem.validateObject(file_object)
        if not ok then
            return nil, err
        end

        file_object.hardware_component.close(file_object.handle)

        file_object.closed = true
        return true, nil
    end

    --- Moves the file cursor to specified position.
    --- @param file_object table
    --- @param pos number
    --- @param whence string "set"(from beginning), "cur" (from file pos), "end")
    function filesystem.seek(file_object, pos, whence)
        local ok, err = filesystem.validateObject(file_object)
        if not ok then
            return nil, err
        end

        local ok, err = filesystem.validateType(pos, "n")
        if not ok then
            return nil, err
        end

        whence = whence or "set"

        if whence ~= "set" and whence ~= "cur" and whence ~= "end" then
            return nil, "bad argument (whence): invalid value, must be 'set', 'cur', or 'end'"
        end

        local new_pos = file_object.hardware_component.seek(file_object.handle, whence, pos)
        
        if not new_pos then
            return nil, "Failed to seek in file"
        end

        return new_pos, nil
    end

    -- Check if a file or directory exists.
    --- @param abs_path string
    --- @return any result_or_error
    function filesystem.exists(abs_path)
        local ok, err = filesystem.validateType(abs_path, "s")
        if not ok then
            return err
        else
            return OS_FILESYSTEM.exists(abs_path)
        end
    end

    -- List contents of a directory.
    --- @param abs_path string
    --- @return any contents
    function filesystem.list(abs_path)
        local ok, err = filesystem.validateType(abs_path, "d")
        if not ok then
            return err
        end

        return OS_FILESYSTEM.list(abs_path)
    end

    --- Check if a path is a directory.
    --- @param abs_path string
    --- @return boolean result
    function filesystem.isDirectory(abs_path)
        local ok, _ = filesystem.validateType(abs_path, "d")
        if not ok then
            return false
        else
            return true
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

        if OS_FILESYSTEM.exists(path) then
            if OS_FILESYSTEM.isDirectory(path) then
                return nil, "Directory already exists"
            else
                return nil, "File with that name already exists"
            end
        end

        local success = OS_FILESYSTEM.makeDirectory(path)

        if not success then
            return nil, "Failed to create directory"
        end
        return true, nil
    end

    --- Recursively copy a file or directory to a new location.
    --- @param origin_path string
    --- @param destination_path string
    --- @return boolean|nil success
    --- @return string|nil error
    local function recursionCopy(origin_path, destination_path)
        if OS_FILESYSTEM.isDirectory(origin_path) then
            local success = OS_FILESYSTEM.makeDirectory(destination_path)
            if not success then
                return nil, "Failed to create directory: " .. destination_path
            end

            local contents = OS_FILESYSTEM.list(origin_path)
            for _, item in ipairs(contents) do
                local item_origin_path = origin_path .. "/" .. item
                local item_destination_path = destination_path .. "/" .. item
                local ok, err = recursionCopy(item_origin_path, item_destination_path)
                if not ok then
                    return nil, err
                end
            end
            return true, nil
        else
            local source_file = OS_FILESYSTEM.open(origin_path, "r")
            if not source_file then
                return nil, "Failed to open source file: " .. origin_path
            end
            local destination_file = OS_FILESYSTEM.open(destination_path, "w")
            if not destination_file then
                OS_FILESYSTEM.close(source_file)
                return nil, "Failed to open destination file: " .. destination_path
            end
            
            while true do
                local data = OS_FILESYSTEM.read(source_file, 4096)
                if not data then
                    break
                end
                OS_FILESYSTEM.write(destination_file, data)
            end
            OS_FILESYSTEM.close(source_file)
            OS_FILESYSTEM.close(destination_file)
            return true, nil
        end
    end
    
    --- Copy a file or directory to a new location.
    --- @param origin_path string
    --- @param destination_path string
    --- @return boolean|nil success
    --- @return string|nil error
    function filesystem.copy(origin_path, destination_path)
        local args = {origin_path, destination_path}

        for _, arg in ipairs(args) do
            local ok, err = filesystem.validateType(arg, "s")
            if not ok then
                return nil, err
            end
        end

        if not OS_FILESYSTEM.exists(origin_path) then
            return nil, "bad argument (origin): does not exist"
        end

        if OS_FILESYSTEM.exists(destination_path) then
            return nil, "bad argument (destination): file already exists"
        end

        if OS_FILESYSTEM.isDirectory(origin_path) and destination_path:sub(1, #origin_path) == origin_path then
            return nil, "bad argument (destination): cannot copy directory"
        end

        return recursionCopy(origin_path, destination_path)
    end

    --- Move a file or directory to a new location.
    --- @param origin_path string
    --- @param destination_path string
    --- @return boolean success
    --- @return string|nil error
    function filesystem.move(origin_path, destination_path)
        local ok, err = filesystem.copy(origin_path, destination_path)
        if not ok then
            return false, err
        end
        local ok, err = filesystem.removeRecursive(origin_path)
        if not ok then
            return false, err
        end
        return true
    end

    --- Recursively remove a directory and its contents.
    --- @param abs_path string
    --- @return boolean|nil success
    --- @return string|nil err
    function filesystem.removeRecursive(abs_path)
        if type(abs_path) ~= "string" or abs_path == "" or abs_path == "/" then
            return nil, "bad argument (path): invalid path"
        end

        if not OS_FILESYSTEM.exists(abs_path) then
            return nil, "bad argument (path): path does not exist"
        end

        if OS_FILESYSTEM.isDirectory(abs_path) then
            local contents = OS_FILESYSTEM.list(abs_path)
            for _, item in ipairs(contents) do
                local item_path = abs_path .. "/" .. item
                local ok, err = filesystem.removeRecursive(item_path)
                if not ok then
                    return nil, err
                end
            end
        end

        local success = OS_FILESYSTEM.remove(abs_path)
        if not success then
            return nil, "Failed to remove: " .. abs_path
        end
        return true
    end

    --- Remove a file or directory.
    --- @param abs_path string
    --- @return boolean|nil success
    --- @return string|nil err
    function filesystem.remove(abs_path)
        if type(abs_path) ~= "string" or abs_path == "" or abs_path == "/" then
            return nil, "bad argument (path): invalid path"
        end

        if not OS_FILESYSTEM.exists(abs_path) then
            return nil, "bad argument (path): file or directory does not exist"
        end

        if OS_FILESYSTEM.isDirectory(abs_path) then
            local contents = OS_FILESYSTEM.list(abs_path)
            if #contents > 0 then
                return nil, "error: directory not empty"
            end
        end

        local success = OS_FILESYSTEM.remove(abs_path)
        if not success then
            return nil, "Failed to remove: " .. abs_path
        end

        return true, nil
    end

    -- Get the size of a file or directory.
    --- @param abs_path string
    --- @return number|nil size
    --- @return string|nil err
    function filesystem.getSize(abs_path)
        local ok, err = filesystem.validateType(abs_path, "s")
        if not ok then
            return nil, err
        end

        if not OS_FILESYSTEM.exists(abs_path) then
            return nil, "bad argument (path): file or directory does not exist"
        end

        if OS_FILESYSTEM.isDirectory(abs_path) then
            return nil, "bad argument (path): cannot get size of directory"
        end

        local size = OS_FILESYSTEM.size(abs_path)
        if not size then
            return nil, "Failed to get size of file"
        end

        return size, nil
    end

    --- SLATED FOR DELETION
    --- @param disk_to_mnt table
    --- @return string|nil mnt_address
    --- @return string|nil err
    function filesystem.mount(disk_to_mnt)
        local mnt_metatable = filesystem.getPathMetatable("/mnt")
        if not mnt_metatable then
            filesystem.makeDirectory("/mnt")
            mnt_metatable = filesystem.getPathMetatable("/mnt")
        end

        local tries = 0
        local mnt_name
        repeat
            mnt_name = tostring(string.char(math.random(97, 122)) .. math.floor(math.random(10, 99)))
            tries = tries + 1
        until not mnt_metatable.contents[mnt_name] or tries > 100

        if tries > 100 then
            return nil, "Unable to create mount with unique name"
        end

        local mnt_disk_metatable = filesystem.getMntMetatable(disk_to_mnt, "/")

        mnt_metatable.contents[mnt_name] = mnt_disk_metatable
        local mnt_addr = "/mnt/" .. mnt_name

        return mnt_addr
    end

    --- SLATED FOR DELETION
    --- Unmount a disk from a mount point.
    --- @param abs_path string
    --- @return boolean|nil success
    --- @return string|nil err
    function filesystem.unmount(abs_path)
        if type(abs_path) ~= "string" or abs_path == "" or abs_path == "/" then
            return nil, "bad argument (target): must be valid path"
        end

        local parent_path, entry_name = filesystem.validatePath(abs_path)
        local parent_metatable = filesystem.getPathMetatable(parent_path)
    
        if not parent_metatable.contents[entry_name] then
            return nil, "bad argument (target): mount point does not exist"
        end

        parent_metatable.contents[entry_name] = nil
        return true
    end

    --- Generates temp file with random name
    --- @return string|nil temp_file_path
    --- @return string|nil err
    function filesystem.tempFile()
        if not OS_FILESYSTEM.exists("/tmp") then
            local ok = OS_FILESYSTEM.makeDirectory("/tmp")
            if not ok then
                return nil, "Failed to create temporary directory"
            end
        end

        local tries = 0
        local temp_file_name
        local temp_file_path
        repeat
            temp_file_name = "tmp_" .. tostring(os.uptime()) .. "_" .. tostring(math.random(1000, 9999))
            temp_file_path = "/tmp/" .. temp_file_name
            tries = tries + 1
        until not OS_FILESYSTEM.exists("/tmp/" .. temp_file_name) or tries > 100

        if tries > 100 then
            return nil, "Unable to create temporary file with unique name"
        end

        local handle = OS_FILESYSTEM.open("/tmp/" .. temp_file_name, "w")
        if not handle then
            return nil, "Failed to create temporary file"
        end
        OS_FILESYSTEM.close(handle)

        return temp_file_path, nil
    end
        
    --- Combines two file paths, ensures only one "/" between the two
    --- @param file_path_1 string
    --- @param file_path_2 string
    --- @return string|nil new_file_path
    --- @return string|nil err
    function filesystem.concat(file_path_1, file_path_2)
       assert(type(file_path_1) == "string", "string expected, got " .. type(file_path_1))
       assert(type(file_path_2) == "string", "string expected, got " .. type(file_path_2))

        local path_1 = file_path_1:gsub("/+$", "")
        local path_2 = file_path_2:gsub("^/+", "")
        local new_file_path = path_1 .. "/" .. path_2

        if path_1 == "" then
            new_file_path = "/" .. path_2
        end
        
        return new_file_path
    end

return filesystem