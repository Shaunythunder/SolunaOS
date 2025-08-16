-- /lib/core/filesystem.lua
-- Provides core filesystem functionality for SolunaOS
-- File metatables not to be confused with Lua object metatables
-- Contents are located in (file or dir).metatable.content

local disk = _G.disk or require("disk") -- Fake filesystem
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

    --- Validate object type
    ---@param abs_path string
    ---@param mode string: "s" (string), "f" (file), "d" (directory), "t" (metatable), or "n" (number)
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
                return false, "metatable expected, got " .. type(abs_path)
            end
            return true, nil, nil
        end

        if type(abs_path) ~= "string" then
            return false, "string expected, got " .. type(abs_path)
        end
        if mode == "s" then
            return true, nil, nil
        end
        
        local path_table = filesystem.getPathMetatable(abs_path)
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
            local ok, err, path_metatable = filesystem.validateType(abs_path, "f")
            if not ok then
                return nil, err
            end
            return {
                metatable = path_metatable,
                mode = mode,
                pos = 1
                }

        -- Write mode, creates a new file or overwrites an existing one
        elseif mode == "w" or mode == "wb" then
            local file_path, file_name = filesystem.validatePath(abs_path)
            local ok, err, parent_metatable = filesystem.validateType(file_path, "d")
            if not ok then
                return nil, err
            end
            parent_metatable.contents[file_name] = {
                type = "file",
                data = "",
                size = 0,
                modified = os.uptime()
            }
            return {
                metatable = parent_metatable.contents[file_name],
                mode = mode,
                pos = 1
                }

        elseif mode == "a" or mode == "ab" then
            local file_path, file_name = filesystem.validatePath(abs_path)
            local ok, err, parent_metatable = filesystem.validateType(file_path, "d")
            if not ok then
                return nil, err
            end

            if not parent_metatable.contents[file_name] or parent_metatable.contents[file_name].type ~= "file" then
                parent_metatable.contents[file_name] = {
                    type = "file",
                    data = "",
                    size = 0,
                    modified = os.uptime()
                }
            end
            local file = parent_metatable.contents[file_name]
            return {
                    metatable = file,
                    mode = mode,
                    pos = #file.data + 1
                }
        end
    end

    -- Opens file metadata for reading
    ---@param file_object table
    ---@param index_pos number
    ---@return string|nil data
    ---@return string|nil error
    function filesystem.read(file_object, index_pos)
        if index_pos == nil then
            index_pos = #file_object.metatable.data - (file_object.pos or 1) + 1
        end

        local ok, err, _ = filesystem.validateType(file_object, "t")
        if not ok then
            return nil, err
        end

        local ok, err, _ = filesystem.validateType(index_pos, "n")
        if not ok then
            return nil, err
        end

        local file_data = file_object.metatable.data
        local pos = file_object.pos or 1
        local file_length = #file_data

        if not index_pos then
            index_pos = file_length - pos + 1
        end

        if pos > file_length then
            return "", "End of file reached"
        end

        local return_data = file_data:sub(pos, pos + index_pos - 1)
        file_object.pos = pos + #return_data
        return return_data
    end

    --- Write data to a file based on file index position.
    --- @param file_object table
    --- @param data string
    --- @return boolean|nil result
    --- @return string|nil error
    function filesystem.write(file_object, data)
        local args = {file_object, data}
        local settings = {"t", "s"}

        for i, arg in ipairs(args) do
            local ok, err = filesystem.validateType(arg, settings[i])
            if not ok then
                return nil, err
            end
        end

        file_object.metatable.data = file_object.metatable.data:sub(1, file_object.pos - 1)
                        .. data
                        .. file_object.metatable.data:sub(file_object.pos + #data)
        file_object.pos = file_object.pos + #data
        file_object.metatable.size = #file_object.metatable.data
        file_object.metatable.modified = os.uptime()
        return true, nil
    end

    --- Close an open file.
    --- @param file_object table
    --- @return boolean|nil result
    --- @return string|nil error
    function filesystem.close(file_object)
        local ok, err = filesystem.validateType(file_object, "t")
        if not ok then
            return nil, err
        end
        file_object.closed = true
        if file_object.closed == true then
            return true
        else
            return false, "unable to close file"
        end
    end

    --- Moves the file cursor to specified position.
    --- @param file_object table
    --- @param pos number
    --- @param mode string "set"(from beginning), "cur" (from file pos), "end")
    function filesystem.seek(file_object, pos, mode)
        local ok, err = filesystem.validateType(file_object, "t")
        if not ok then
            return nil, err
        end

        local ok, err = filesystem.validateType(pos, "n")
        if not ok then
            return nil, err
        end

        mode = mode or "set"
        local filesize = #file_object.metatable.data
        local file_pos = file_object.pos
        print("File size:", filesize, "Current position:", file_pos, "Seek position:", pos, "Mode:", mode)

        if mode == "set" then
            file_pos = pos
        elseif mode == "cur" then
            file_pos = file_object.pos + pos
        elseif mode == "end" then
            file_pos = filesize + pos
        else
            return nil, "bad argument (refernce_point): invalid value, must be set to 'set', 'cur', or 'end'"
        end

        if file_pos < 1 then
            file_pos = 1
        end
        if file_pos > filesize then
            file_pos = filesize
        end
        file_object.pos = file_pos
        return file_pos
    end

    -- Check if a file or directory exists.
    --- @param path string
    --- @return boolean result
    function filesystem.exists(path)
        local path_metatable = filesystem.getPathMetatable(path)
        if path_metatable then
            return true
        else
            return false
        end
    end

    -- List contents of a directory.
    --- @param path string
    --- @return table|nil contents
    --- @return string|nil error
    function filesystem.list(path)
        local ok, err, dir = filesystem.validateType(path, "d")
        if not ok then
            return nil, err
        end

        local contents = {}
        for name in pairs(dir.contents) do
            if dir.contents[name] ~= nil then
                table.insert(contents, name)
            end
        end
        return contents, nil
    end

    --- Check if a path is a directory.
    --- @param path string
    --- @return boolean result
    function filesystem.isDirectory(path)
        local ok, _, _ = filesystem.validateType(path, "d")
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

        local parent_path, dir_name = filesystem.validatePath(path)

        local ok, err, parent_metatable = filesystem.validateType(parent_path, "d")
        if not ok then
            return nil, err
        end

        if parent_metatable.contents[dir_name] then
            return nil, "Directory already exists"
        end

        parent_metatable.contents[dir_name] = {
            type = "dir",
            contents = {},
            modified = os.uptime()
        }
        return true, nil
    end

    --- Recursively copy a file or directory to a new location.
    --- @param copy_dir table
    --- @return table
    local function recursionCopy(copy_dir)
        if copy_dir.type == "dir" then
            local new_directory = {
                                    type = "dir",
                                    contents = {}
                                    }
            for directory, file in pairs(copy_dir.contents) do
                new_directory.contents[directory] = recursionCopy(file)
            end
            return new_directory
        elseif copy_dir.type == "file" then
            return {
                type = "file",
                data = copy_dir.data,
                size = copy_dir.size,
                modified = copy_dir.modified
            }
        end
    end
    
    --- Copy a file or directory to a new location.
    --- @param origin_path string
    --- @param destination_path string
    --- @return boolean|nil success
    --- @return string|nil error
    function filesystem.copy(origin_path, destination_path)
        local ok, err, origin_metatable = filesystem.validateType(origin_path, "f")
        if not ok then
            ok, err, origin_metatable = filesystem.validateType(origin_path, "d")
            if not ok then
                return nil, "bad argument (origin): does not exist"
            end
        end

        if origin_metatable.type == "dir" and destination_path:sub(1, #origin_path) == origin_path then
            return nil, "bad argument (destination): cannot copy self"
        end

        local destination_path, destination_name = filesystem.validatePath(destination_path)
        local ok, err, destination_metatable = filesystem.validateType(destination_path, "d")
        if not ok then
            return nil, err
        end

        if destination_metatable.contents[destination_name] then
            return nil, "bad argument (destination): file already exists"
        end

        destination_metatable.contents[destination_name] = recursionCopy(origin_metatable)
        return true
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

        local modded_path = abs_path:gsub("/+$", "")
        local parent_path, name = filesystem.validatePath(modded_path)
        local parent_metatable = filesystem.getPathMetatable(parent_path)

        if not parent_metatable or not parent_metatable.contents[name] then
            return nil, "bad argument (path): parent directory does not exist"
        end

        if not parent_metatable.contents[name] then
            return nil, "bad argument (path): file or directory does not exist"
        end

        parent_metatable.contents[name] = nil
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

        local modded_path = abs_path:gsub("/+$", "")
        local parent_path, name = filesystem.validatePath(modded_path)
        local parent_metatable = filesystem.getPathMetatable(parent_path)

        if not parent_metatable or not parent_metatable.contents[name] then
            return nil, "bad argument (path): parent directory does not exist"
        end

        if not parent_metatable.contents[name] then
            return nil, "bad argument (path): file or directory does not exist"
        end

        local target_metatable = filesystem.getPathMetatable(modded_path)

        if target_metatable.contents and next(target_metatable.contents) then
            return nil, "error: directory not empty"
        end

        parent_metatable.contents[name] = nil
        return true
    end

    -- Get the size of a file or directory.
    --- @param abs_path string
    --- @return number|nil size
    --- @return string|nil err
    function filesystem.getSize(abs_path)
        local file_metatable = filesystem.getPathMetatable(abs_path)
        if not file_metatable then
            return nil, "bad argument (path): file or directory does not exist"
        end

        if file_metatable.type == "file" then
            return #file_metatable.data
        elseif file_metatable.type == "dir" then
            return 0, "bad argument (path): cannot get size of directory"
        else
            return nil, "bad argument (path): invalid type"
        end
    end

    --- Mount a disk to a mount point. NOT SET UP FOR REAL HARDWARE
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
        local temp_metatable = filesystem.getPathMetatable("/tmp")
        if not temp_metatable then
            filesystem.makeDirectory("/tmp")
            temp_metatable = filesystem.getPathMetatable("/tmp")
        end

        local tries = 0
        local temp_file_name
        repeat
            temp_file_name = "tmp_" .. tostring(os.uptime()) .. "_" .. tostring(math.random(1000, 9999))
            tries = tries + 1
        until not temp_metatable.contents[temp_file_name] or tries > 100

        if tries > 100 then
            return nil, "Unable to create temporary file with unique name"
        end

        temp_metatable.contents[temp_file_name] = {
            type = "file",
            data = "",
            size = 0,
            modified = os.uptime()
        }
        return "/tmp/" .. temp_file_name
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