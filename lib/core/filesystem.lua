-- /lib/core/filesystem.lua
-- Provides core filesystem functionality for SolunaOS
-- File metatables not to be confused with Lua object metatables
-- Contents are located in (file or dir).metatable.content
-- Also manages mounts which use a virtual filesystem abstraction that is synced with the hardware updates.

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

    --- Retrieves directory contents from a mounted filesystem structure
    --- @param structure table
    --- @param abs_path string
    --- @return table|nil contents
    --- @return string|nil error
    function filesystem.getDirectoryFromStructure(structure, abs_path)
        local mount_structure = structure

         if abs_path ~= "/" then
            local path_components = filesystem.splitPath(abs_path)
            for _, part in ipairs(path_components) do
                local found_key
                if mount_structure[part] then
                    found_key = part
                elseif mount_structure[part .. "/"] then
                    found_key = part .. "/"
                end
                
                if found_key and mount_structure[found_key].isDirectory and mount_structure[found_key].contents then
                    mount_structure = mount_structure[found_key].contents
                else
                    return nil, "Path not found in mounted structure"
                end
            end
        end

        local dir_contents = {}
        for object, metadata in pairs(mount_structure) do
            if metadata.isDirectory then
                table.insert(dir_contents, object .. "/")
            else
                table.insert(dir_contents, object)
            end
        end
        return dir_contents
    end

    -- Retrieves a file from a mounted filesystem structure
    ---@param structure table
    ---@param abs_path string
    ---@return table|nil contents
    ---@return string|nil error
    function filesystem.getFileFromStructure(structure, abs_path)
        local mount_structure = structure

        if abs_path ~= "/" then
            local path_components = filesystem.splitPath(abs_path)
            for i, part in ipairs(path_components) do
                local found_key
                if mount_structure[part] then
                    found_key = part
                elseif mount_structure[part .. "/"] then
                    found_key = part .. "/"
                end
                if found_key then
                    if i == #path_components then
                        return mount_structure[found_key]
                    else
                        if mount_structure[found_key].contents then
                            mount_structure = mount_structure[found_key].contents
                        else
                            return mount_structure[found_key]
                        end
                    end
                else
                    return nil, "Path not found in mounted structure"
                end
            end
        end
        return mount_structure
    end

    --- Resolves if a path is within a mounted filesystem
    --- @param abs_path string
    --- @return string|nil address
    --- @return string|nil relative_path
    --- @return table|nil structure
    function filesystem.resolveIfMount(abs_path)
        if type(abs_path) ~= "string" then
            return nil, "bad argument (abs_path): string expected, got " .. type(abs_path)
        end
        
        if abs_path:sub(1, 5) == "/mnt/" then
            local mount_dir = abs_path:sub(1, 8) -- "/mnt/xyz"
            if _G.mounted_filesystems[mount_dir] then
                local address = _G.mounted_filesystems[mount_dir].address
                local structure = _G.mounted_filesystems[mount_dir].structure
                local relative_path = abs_path:sub(9) -- Path after the mount point
                if relative_path == "" then
                    relative_path = "/"
                end
                return address, relative_path, structure
            end
        end
        return nil, abs_path
    end

    --- Validates a file object
    --- @param file_object table
    --- @return boolean result
    --- @return string|nil error
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

        local filesystem_addr, relative_path = filesystem.resolveIfMount(abs_path)
        local exists
        local is_directory
        if filesystem_addr then
            exists = component.invoke(filesystem_addr, "exists", relative_path)
            is_directory = component.invoke(filesystem_addr, "isDirectory", relative_path)
        else
            exists = OS_FILESYSTEM.exists(abs_path)
            is_directory = OS_FILESYSTEM.isDirectory(abs_path)
        end

        if not exists then
            return false, "File or directory does not exist"
        end
        if mode == "f" and is_directory then
            return false, "File expected, got directory"
        elseif mode == "d" and not is_directory then
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

        local filesystem_addr, relative_path = filesystem.resolveIfMount(abs_path)
        local handle
        
        if filesystem_addr then
            handle = component.invoke(filesystem_addr, "open", relative_path, mode)
        else
            handle = OS_FILESYSTEM.open(abs_path, mode)
        end

        if not handle then
            return nil, "Failed to open file: " .. abs_path
        end

        return {
            handle = handle,
            mode = mode,
            hardware_component = filesystem_addr or OS_FILESYSTEM
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

        local data
        if type(file_object.hardware_component) == "string" then
            data = component.invoke(file_object.hardware_component, "read", file_object.handle, index_pos)
        else
            data = file_object.hardware_component.read(file_object.handle, index_pos)
        end

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

        local success
        if type(file_object.hardware_component) == "string" then
            success = component.invoke(file_object.hardware_component, "write", file_object.handle, data)
        else
            success = file_object.hardware_component.write(file_object.handle, data)
        end

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

        if type(file_object.hardware_component) == "string" then
            component.invoke(file_object.hardware_component, "close", file_object.handle)
        else
            file_object.hardware_component.close(file_object.handle)
        end
        
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

        local new_pos
        if type(file_object.hardware_component) == "string" then
            new_pos = component.invoke(file_object.hardware_component, "seek", file_object.handle, whence, pos)
        else
            new_pos = file_object.hardware_component.seek(file_object.handle, whence, pos)
        end
        
        if not new_pos then
            return nil, "Failed to seek in file"
        end

        return new_pos, nil
    end

    -- Check if a file or directory exists.
    --- @param abs_path string
    --- @return any result_or_error
    function filesystem.exists(abs_path)
       local filesystem_addr, relative_path, structure = filesystem.resolveIfMount(abs_path)
        local handle
        if structure then
            handle = filesystem.getFileFromStructure(structure, relative_path)
            return handle ~= nil
        elseif filesystem_addr then
            handle = component.invoke(filesystem_addr, "exists", relative_path)
            return handle
        else
            return OS_FILESYSTEM.exists(abs_path)
        end
    end

    -- List contents of a directory.
    --- @param abs_path string
    --- @return any contents
    function filesystem.list(abs_path)
       local filesystem_addr, relative_path, structure = filesystem.resolveIfMount(abs_path)
        local handle
        
        if structure then 
            return filesystem.getDirectoryFromStructure(structure, relative_path)
        elseif filesystem_addr then
            handle = component.invoke(filesystem_addr, "list", relative_path)
            return handle
        else
            return OS_FILESYSTEM.list(abs_path)
        end
    end

    --- Check if a path is a directory.
    --- @param abs_path string
    --- @return boolean result
    function filesystem.isDirectory(abs_path)
        local filesystem_addr, relative_path, structure = filesystem.resolveIfMount(abs_path)

        if structure then
            if relative_path == "/" then
                return true
            else
                local metadata = filesystem.getFileFromStructure(structure, relative_path)
                return metadata and metadata.isDirectory or false
            end
           
        elseif filesystem_addr then
            return component.invoke(filesystem_addr, "isDirectory", relative_path)
        else
            return OS_FILESYSTEM.isDirectory(abs_path)
        end
    end

    --- Creates a directory in a mounted filesystem and updates the structure cache
    --- @param filesystem_addr string
    --- @param relative_path string
    --- @param structure table
    --- @return boolean success
    function filesystem.createDirectoryInMount(filesystem_addr, relative_path, structure)
        local success = component.invoke(filesystem_addr, "makeDirectory", relative_path)

        if success and structure then
            local path_components = filesystem.splitPath(relative_path)
            local dir_name = table.remove(path_components)

            local parent_structure = structure
            for _, component in ipairs(path_components) do
                local found_key
                if parent_structure[component] then
                    found_key = component
                elseif parent_structure[component .. "/"] then
                    found_key = component .. "/"
                end

                if found_key and parent_structure[found_key].contents then
                    parent_structure = parent_structure[found_key].contents
                else
                    return success
                end
            end

            parent_structure[dir_name .. "/"] = {
                isDirectory = true,
                size = 0,
                last_modified = component.invoke(filesystem_addr, "lastModified", relative_path),
                contents = {}
            }

        end
        return success
    end

    --- Creates a directory in the desired path.
    ---@param path string
    ---@return true|nil result
    ---@return nil|string error
    function filesystem.makeDirectory(path)
        
        if type(path) ~= "string" or path == "" or path == "/" then
            return nil, "bad argument (path): invalid directory path"
        end

        local filesystem_addr, relative_path, structure = filesystem.resolveIfMount(path)
        
        local exists, isDirectory, success

        if filesystem_addr then
            exists = component.invoke(filesystem_addr, "exists", relative_path)
            if exists then
                isDirectory = component.invoke(filesystem_addr, "isDirectory", relative_path)
            else
                success = filesystem.createDirectoryInMount(filesystem_addr, relative_path, structure)
            end
        else
            exists = OS_FILESYSTEM.exists(path)
            
            if exists then
                isDirectory = OS_FILESYSTEM.isDirectory(path)
            else
                success = OS_FILESYSTEM.makeDirectory(path)
            end
        end

        if exists then
            if isDirectory then
                return nil, "Directory already exists"
            else
                return nil, "File with that name already exists"
            end
        end

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
        if filesystem.isDirectory(origin_path) then
            local success = filesystem.makeDirectory(destination_path)
            if not success then
                return nil, "Failed to create directory: " .. destination_path
            end

            local contents = filesystem.list(origin_path)
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
            local source_file = filesystem.open(origin_path, "r")
            if not source_file then
                return nil, "Failed to open source file: " .. origin_path
            end
            local destination_file = filesystem.open(destination_path, "w")
            if not destination_file then
                filesystem.close(source_file)
                return nil, "Failed to open destination file: " .. destination_path
            end
            
            while true do
                local data = filesystem.read(source_file, 4096)
                if not data then
                    break
                end
                filesystem.write(destination_file, data)
            end
            filesystem.close(source_file)
            filesystem.close(destination_file)
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

        if not filesystem.exists(origin_path) then
            return nil, "bad argument (origin): does not exist"
        end

        if filesystem.exists(destination_path) then
            return nil, "bad argument (destination): file already exists"
        end

        if filesystem.isDirectory(origin_path) and destination_path:sub(1, #origin_path) == origin_path then
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

    --- Removes a directory in a mounted filesystem and updates the structure cache
    --- @param filesystem_addr string
    --- @param relative_path string
    --- @param structure table
    --- @return boolean success
    function filesystem.removeInMount(filesystem_addr, relative_path, structure)
        local success = component.invoke(filesystem_addr, "remove", relative_path)

        if success and structure then
            local path_components = filesystem.splitPath(relative_path)
            local dir_name = table.remove(path_components)

            local parent_structure = structure
            for _, component in ipairs(path_components) do
                local found_key
                if parent_structure[component] then
                    found_key = component
                elseif parent_structure[component .. "/"] then
                    found_key = component .. "/"
                end

                if found_key and parent_structure[found_key].contents then
                    parent_structure = parent_structure[found_key].contents
                else
                    return success
                end
            end

            parent_structure[dir_name .. "/"] = nil
            parent_structure[dir_name] = nil

        end
        return success
    end

    --- Recursively remove a directory and its contents.
    --- @param abs_path string
    --- @return boolean|nil success
    --- @return string|nil err
    function filesystem.removeRecursive(abs_path)
        if type(abs_path) ~= "string" or abs_path == "" or abs_path == "/" then
            return nil, "bad argument (path): invalid path"
        end

        if not filesystem.exists(abs_path) then
            return nil, "bad argument (path): path does not exist"
        end

        if filesystem.isDirectory(abs_path) then
            local contents = filesystem.list(abs_path)
            for _, item in ipairs(contents) do
                local item_path = abs_path .. "/" .. item
                local ok, err = filesystem.removeRecursive(item_path)
                if not ok then
                    return nil, err
                end
            end
        end

        local success = filesystem.remove(abs_path)
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

        if not filesystem.exists(abs_path) then
            return nil, "bad argument (path): file or directory does not exist"
        end

        if filesystem.isDirectory(abs_path) then
            local contents = filesystem.list(abs_path)
            if #contents > 0 then
                return nil, "error: directory not empty"
            end
        end

        local filesystem_addr, relative_path, structure = filesystem.resolveIfMount(abs_path)
        local success

        if filesystem_addr then
            success = filesystem.removeInMount(filesystem_addr, relative_path, structure)
        else
            success = OS_FILESYSTEM.remove(abs_path)
        end
        if not success then
            return nil, "Failed to remove file or directory"
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

        if not filesystem.exists(abs_path) then
            return nil, "bad argument (path): file or directory does not exist"
        end

        if filesystem.isDirectory(abs_path) then
            return nil, "bad argument (path): cannot get size of directory"
        end

        local filesystem_addr, relative_path = filesystem.resolveIfMount(abs_path)
        local size

        if filesystem_addr then
            size = component.invoke(filesystem_addr, "size", relative_path)
        else
            size = OS_FILESYSTEM.size(abs_path)
        end

        if not size then
            return nil, "Failed to get size of file"
        end

        return size, nil
    end

    --- Builds a file structure cache for a mounted filesystem
    --- @param filesystem_addr string
    --- @return table structure
    function filesystem.buildMountFileStructure(filesystem_addr)
        local structure = {}

        local function exploreAndCache(mnt_addr, cache_to_build)
            local contents = component.invoke(filesystem_addr, "list", mnt_addr)
            for _, object in ipairs(contents) do
                local object_path = filesystem.concat(mnt_addr, object)
                local is_dir = component.invoke(filesystem_addr, "isDirectory", object_path)

                cache_to_build[object] = {
                    isDirectory = is_dir,
                    size = is_dir and 0 or component.invoke(filesystem_addr, "size", object_path),
                    last_modified = component.invoke(filesystem_addr, "lastModified", object_path),
                    contents = is_dir and {} or nil,
                }
                if is_dir then
                    exploreAndCache(object_path, cache_to_build[object].contents)
                end
            end
        end
        exploreAndCache("/", structure)
        return structure
    end

    --- Mounts a filesystem and builds its structure cache
    --- @param filesystem_addr string
    --- @return string|nil mount_point
    function filesystem.mount(filesystem_addr)
        -- Create mount directory (your existing code)
        local mnt_addr = "/mnt/" .. string.sub(filesystem_addr, 1, 3)
        filesystem.makeDirectory(mnt_addr)
        local structure = filesystem.buildMountFileStructure(filesystem_addr)
        -- Register the mapping
        _G.mounted_filesystems[mnt_addr] = {
            address = filesystem_addr,
            structure = structure
        }

        return mnt_addr
    end

    --- Unmounts a filesystem and removes its structure cache
    --- @param mnt_addr string
    --- @return boolean success
    --- @return string|nil err
    function filesystem.unmount(mnt_addr)
        if _G.mounted_filesystems[mnt_addr] then
            _G.mounted_filesystems[mnt_addr] = nil
            filesystem.removeRecursive(mnt_addr)
            return true
        end
        return false, "Mount point not found"
    end

    --- Generates temp file with random name
    --- @return string|nil temp_file_path
    --- @return string|nil err
    function filesystem.tempFile()
        if not filesystem.exists("/tmp") then
            local ok = filesystem.makeDirectory("/tmp")
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
        until not filesystem.exists("/tmp/" .. temp_file_name) or tries > 100

        if tries > 100 then
            return nil, "Unable to create temporary file with unique name"
        end

        local handle = filesystem.open("/tmp/" .. temp_file_name, "w")
        if not handle then
            return nil, "Failed to create temporary file"
        end
        filesystem.close(handle)

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