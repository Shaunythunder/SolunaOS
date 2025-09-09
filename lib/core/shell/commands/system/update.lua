-- /lib/core/shell/commands/system/update.lua

-- SolunaOS Updater
-- This script is designed to wipe a disk and install SolunaOS from a manifest file.
-- Only for use in a OpenOS Environment. Currently configured download from local server.

local sys = require("system")
local terminal = require("terminal")
local internet = require("internet")
local fs = require("filesystem")

local update = {}
update.description = "Installs or updates SolunaOS from a manifest file"
update.usage = "Usage: installer"
update.flags = {}

    function update.execute(args, input_data, shell)
        if #args ~= 0 then
            return update.usage
        end

        local short_delay = .5
        local long_delay = 2
        local extreme_delay = 5

        local manifest_download_path
        local download_path
        manifest_download_path = "http://localhost:8000/install_manifest.lua"
        download_path = "http://localhost:8000/"

        --These aren't technically needed but are here to satisfy an argument.
        local wipe_exclusions = {
            ["/tmp"] = true,
            ["/tmp/disk_imager.lua"] = true,
        }

        local function checkValidMounts()
            local running_OS_mount_address = _G.BOOT_ADDRESS
            local valid_mnts = {}
            local mnts = fs.list("/mnt")
            for _, mnt in ipairs(mnts) do
                local mnt_path = fs.concat("/mnt", mnt)
                local mnt_address = fs.getMountAddress(mnt_path)
                if mnt_address ~= running_OS_mount_address then
                    local file_path = fs.concat(mnt_path, "fhae45q54h789qthq43w8thfw78hfgew.lua")
                    local file = fs.open(file_path, "w")
                    if file then
                        fs.close(file)
                        fs.remove(file_path)
                        table.insert(valid_mnts, mnt)
                    end
                end
            end
            return valid_mnts
        end

        local function verifyManifest(base_path)
            local file_path = fs.open("/install_manifest.lua", "r")
            if not file_path then
                print("Install manifest not found at " .. fs.concat(base_path, "install_manifest.lua"))
                return false
            else
                fs.close(file_path)
                return true
            end
        end

        local updates_needed = {}

        local function validateChecksum(host_manifest, update_manifest)
            local installed = {}
            for _, file in pairs(host_manifest) do
                installed[file.filename] = file.checksum
            end
            for _, file in ipairs(update_manifest) do
                if installed[file.filename] ~= file.checksum then
                    table.insert(updates_needed, file.filename)
                end
            end
        end

        local function deleteAndReplace(base_path, file)
            local file_path = fs.concat(base_path, file)
            if fs.exists(file_path) then
                fs.remove(file_path)
                if fs.exists(file_path) then
                    print("Failed to remove file: " .. file_path)
                    return false
                end
            end
            -- If the file is in the exclusions table, it will not be downloaded.
                -- Downloads the file, concats the content into a string and then writes it to the disk.
                local filepath = file_path
                local url = download_path .. file
                local outpath = file_path
                local file_response = internet.request(url)
                if not file_response then
                    print("Failed to download " .. filepath)
                    sys.sleep(short_delay)
                    print("Update failed. Please check your internet connection.")
                    sys.sleep(extreme_delay)
                    return false
                end

                local file_content = ""
                for chunk in file_response do
                    file_content = file_content .. chunk
                end

                local dir = outpath:match("(.*/)")
                if dir and not fs.exists(dir) then
                    -- Creates the directory if it does not exist.
                    fs.makeDirectory(dir)
                    sys.sleep(short_delay)
                end
                local file = fs.open(outpath, "w")
                if file then
                    -- Writes the content to the file.
                    fs.write(file, file_content)
                    fs.close(file)
                    return true
                end
        end


        local target_mnt = checkValidMounts()[1]
        if not target_mnt then
            print("No writable disk. Please insert a disk and try again.")
            sys.sleep(extreme_delay)
            return
        end

        print("Welcome to Dev Updater v1.0!")
        sys.sleep(short_delay)
        print("Do not shut down the computer while the updater is running.")
        sys.sleep(short_delay)

        local base_path = "/"
        local base_manifest_path = fs.concat(base_path, "install_manifest.lua")

        print("Running in development mode. Download path set to: " .. manifest_download_path)
        sys.sleep(short_delay)

        if verifyManifest(base_path) then
            print("Manifest verified successfully.")
        else
            print("Manifest verification failed.")
            sys.sleep(extreme_delay)
            return
        end

        if not fs.exists(base_manifest_path) then
            print("No install manifest found. Cannot update.")
            sys.sleep(short_delay)
            return
        end

        print("Fetching update manifest...")
        sys.sleep(short_delay)

        -- Pulls install manifest from GitHub.
        -- The manifest is a text file that contains the list of files to be installed.
        -- It is stored in the LorielleOS-Mod repository.
        local response, err = internet.request(manifest_download_path)
        if not response then
            print("Failed to download manifest. Please check your internet connection.")
            sys.sleep(short_delay)
            local input
            repeat
                input = terminal.read("Try again? (yes/no): ")
                terminal.write(input)
                if input then
                    input = input:lower()
                end
                if input == "yes" then
                    response = internet.request(manifest_download_path)
                end
            until response or input == "no"
            if input == "no" then
                print("Update failed. Please check your internet connection.")
                sys.sleep(extreme_delay)
                return
            end
        end

        print("Manifest found. Parsing...")
        sys.sleep(short_delay)
        local manifest_content = ""

        -- Handles packets from the response.
        -- It concatenates the chunks into a single string.
        -- The string is the content of the manifest file.

        for chunk in response do
            manifest_content = manifest_content .. chunk
        end

        local input = nil
        while #manifest_content == 0 do
        print("Failed to download manifest. Please check your internet connection.")
            sys.sleep(1)
            repeat
                input = terminal.read("Try again? (yes/no): ")
                terminal.write(input)
                if input then
                    input = input:lower()
                end
            until input == "yes" or input == "no"

            if input == "no" then
                print("Update failed. Please check your internet connection.")
                sys.sleep(extreme_delay)
                return
            elseif input == "yes" then
                response = internet.request(manifest_download_path)
                if response then
                    manifest_content = ""
                    for chunk in response do
                        manifest_content = manifest_content .. chunk
                    end
                end
            end
        end

        local manifest_path = "/tmp/install_manifest.lua"
        local temp_manifest = fs.open(manifest_path, "w")

        if temp_manifest then
            fs.write(temp_manifest, manifest_content)
            fs.close(temp_manifest)
        else
            print("Failed to open install_manifest.lua for writing. Please check your permissions.")
            sys.sleep(short_delay)
            print("Exiting updater.")
            sys.sleep(extreme_delay)
            return
        end

        print("Manifest downloaded successfully.")
        sys.sleep(short_delay)

        local host_manifest = dofile(base_manifest_path)
        local update_manifest = dofile(manifest_path)

        print("Checking for updates...")
        sys.sleep(short_delay)

        validateChecksum(host_manifest, update_manifest)

        if #updates_needed == 0 then
            print("No updates needed. Exiting updater.")
            return
        end
        if #updates_needed == 1 then
            print("Update needed! 1 file to be updated.")
        else
            print("Updates needed!  " .. #updates_needed .. " files to update.")
        end

        sys.sleep(short_delay)
        for i, update in ipairs(updates_needed) do
            print("Updating file " .. i .. " of " .. #updates_needed .. ": " .. update)
            sys.sleep(long_delay)
            local result = deleteAndReplace(base_path, update)
            if not result then
                print("Failed to update " .. tostring(update) .. ".")
                sys.sleep(short_delay)
                print("Aborting updater.")
                return
            end
        end

        fs.remove(base_manifest_path)
        local os_manifest_path = base_manifest_path
        local os_manifest = fs.open(os_manifest_path, "w")

        if os_manifest then
            fs.write(os_manifest, manifest_content)
            fs.close(os_manifest)
        else
            print("Failed to open " .. os_manifest_path .. " for writing. Please check your permissions.")
            sys.sleep(short_delay)
            print("Exiting updater.")
            sys.sleep(extreme_delay)
            return
        end

        print("All files updated!")
        sys.sleep(short_delay)
        sys.reboot()
    end

return update
