-- SolunaOS Installer/Disk Imager
-- This script is designed to wipe a disk and install SolunaOS from a manifest file.
-- Only for use in a OpenOS Environment. Currently configured download from local server.

local os = require("os")
local table = require("table")
local io = require("io")
local print = print
local internet = require("internet")
local filesystem = require("filesystem")

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
    local running_OS_mount_address = filesystem.get("/home")
    local valid_mnts = {}
    for mnt in filesystem.list("/mnt") do
        local mnt_path = filesystem.concat("/mnt", mnt)
        local mnt_address = filesystem.get(mnt_path)
        if mnt_address ~= running_OS_mount_address then
            local file_path = filesystem.concat(mnt_path, "fhae45q54h789qthq43w8thfw78hfgew.lua")
            local file = io.open(file_path, "w")
            if file then
                file:close()
                filesystem.remove(file_path)
                table.insert(valid_mnts, mnt)
            end
        end
    end
    return valid_mnts
end

local function verifyManifest(base_path)
    local file_path = io.open(filesystem.concat(base_path, "install_manifest.lua"), "r")
    if not file_path then
        print("Install manifest not found at " .. filesystem.concat(base_path, "install_manifest.lua"))
        return false
    else 
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
    local file_path = filesystem.concat(base_path, file)
    if filesystem.exists(file_path) then
        filesystem.remove(file_path)
        if filesystem.exists(file_path) then
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
            os.sleep(short_delay)
            print("Update failed. Please check your internet connection.")
            os.sleep(extreme_delay)
            return false
        end

        local file_content = ""
        for chunk in file_response do
            file_content = file_content .. chunk
        end

        local dir = filesystem.path(outpath)
        if dir and not filesystem.exists(dir) then
            -- Creates the directory if it does not exist.
            filesystem.makeDirectory(dir)
            os.sleep(short_delay)
        end
        local file = io.open(outpath, "w")
        if file then
            -- Writes the content to the file.
            file:write(file_content)
            file:close()
            return true
        end
end


local target_mnt = checkValidMounts()[1]
if not target_mnt then
    print("No writable disk. Please insert a disk and try again.")
    os.sleep(extreme_delay)
    return
end

print("Welcome to Dev Updater v1.0!")
os.sleep(short_delay)
print("Do not shut down the computer while the updater is running.")
os.sleep(short_delay)

local base_path = "/mnt/" .. target_mnt .. "/"
local base_manifest_path = filesystem.concat(base_path, "install_manifest.lua")

print("Running in development mode. Download path set to: " .. manifest_download_path)
os.sleep(short_delay)

if verifyManifest(base_path) then
    print("Manifest verified successfully.")
else
    print("Manifest verification failed.")
    os.sleep(extreme_delay)
    return
end

if not filesystem.exists(base_manifest_path) then
    print("No install manifest found. Cannot update.")
    os.sleep(short_delay)
    return
end

print("Fetching update manifest...")
os.sleep(short_delay)

-- Pulls install manifest from GitHub.
-- The manifest is a text file that contains the list of files to be installed.
-- It is stored in the LorielleOS-Mod repository.
local response = internet.request(manifest_download_path)
if not response then
    print("Failed to download manifest. Please check your internet connection.")
    os.sleep(short_delay)
    local input
    repeat
        io.write("Try again? (yes/no): ")
        input = io.read()
        if input then
            input = input:lower()
        end
        if input == "yes" then
            response = internet.request(manifest_download_path)
        end
    until response or input == "no"
    if input == "no" then
        print("Update failed. Please check your internet connection.")
        os.sleep(extreme_delay)
        return
    end
end

print("Manifest found. Parsing...")
os.sleep(short_delay)
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
    os.sleep(1)
    repeat
        io.write("Try again? (yes/no): ")
        input = io.read()
        if input then
            input = input:lower()
        end
    until input == "yes" or input == "no"

    if input == "no" then
        print("Update failed. Please check your internet connection.")
        os.sleep(extreme_delay)
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
local temp_manifest = io.open(manifest_path, "w")

if temp_manifest then
temp_manifest:write(manifest_content)
temp_manifest:close()
else
    print("Failed to open install_manifest.lua for writing. Please check your permissions.")
    os.sleep(short_delay)
    print("Exiting updater.")
    os.sleep(extreme_delay)
    return
end

print("Manifest downloaded successfully.")
os.sleep(short_delay)

local host_manifest = dofile(base_manifest_path)
local update_manifest = dofile(manifest_path)

print("Checking for updates...")
os.sleep(short_delay)

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

os.sleep(short_delay)
for i, update in ipairs(updates_needed) do
    print("Updating file " .. i .. " of " .. #updates_needed .. ": " .. update)
    os.sleep(long_delay)
    local result = deleteAndReplace(base_path, update)
    if not result then
        print("Failed to update " .. tostring(update) .. ".")
        os.sleep(short_delay)
        print("Aborting updater.")
        return
    end
end

filesystem.remove(base_manifest_path)
local os_manifest_path = filesystem.concat(base_manifest_path)
local os_manifest = io.open(os_manifest_path, "w")

if os_manifest then
os_manifest:write(manifest_content)
os_manifest:close()
else
    print("Failed to open " .. os_manifest_path .. " for writing. Please check your permissions.")
    os.sleep(short_delay)
    print("Exiting updater.")
    os.sleep(extreme_delay)
    return
end

print("All files updated!")
os.sleep(short_delay)