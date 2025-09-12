-- SolunaOS Installer/Disk Imager
-- This script is designed to wipe a disk and install SolunaOS from a manifest file.
-- Only for use in a OpenOS Environment. Currently configured download from local server.

local filesystem = require("filesystem")
local os = require("os")
local table = require("table")
local io = require("io")
local print = print
local internet = require("internet")

local short_delay = .5
local long_delay = 2
local extreme_delay = 5

--These aren't technically needed but are here to satisfy an argument.
local wipe_exclusions = {
    ["/tmp"] = true,
    ["/tmp/disk_imager.lua"] = true,
}

local function labelDrive(mnt)
    print("Labeling drive as 'SolunaOS'...")
    os.execute("label /mnt/" .. mnt .. " " .. "SolunaOS")
end

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

local function wipeDirectory(path)
    -- Logic for wiping the target drive
    -- Uses the inital path (argument: path) to signify the drive to wipe.
    for file in filesystem.list(path) do
        -- Concatenate is /mnt/path/ + relative file path.
        local full_path = filesystem.concat(path, file)
            if filesystem.isDirectory(full_path) then
                --Recursive system call to wipe the directory
                wipeDirectory(full_path) 
                filesystem.remove(full_path)
                print("Removed directory: " .. full_path)
            else
                filesystem.remove(full_path)
                print("Removed file: " .. full_path)
            end
    end
end

local function checkCleanWipe(path, exclusions)
    -- Runs through the directory to make sure that there is nothing left. 
    for file in filesystem.list(path)do
        local full_path = filesystem.concat(path, file)
        -- Skips over the . and .. directories as those are always present.
        -- Also skips over any files or directories that are in the exclusions table.
        if file ~= "." and file ~= ".." and not exclusions[full_path] then
            if path == "/" and file == "tmp" then
                -- Skip the tmp directory to avoid removing it
                local clean, culprit = checkCleanWipe(full_path, exclusions)
                -- If there is an issue, it throws an error with the offending file or directory.
                if not clean then
                    return false, culprit
                end
            elseif filesystem.isDirectory(full_path) then
                -- If there is an issue, it throws an error with the offending file or directory.
                local clean, culprit = checkCleanWipe(full_path, exclusions)
                if not clean then
                    return false, culprit
                end
            else
                return false, full_path
            end
        end
    end
    -- If it gets here, then it didn't detect anything.
    return true
end

print("Welcome to SolunaOS Installer/Disk Imager v2.2.1!")
os.sleep(short_delay)
print("USER WARNING: This imager will completely wipe your disk and install SolunaOS.")
os.sleep(short_delay)
print("Failure during installation may result in an unbootable system.")
os.sleep(short_delay)

local target_mnt = checkValidMounts()[1]
if not target_mnt then
    print("No writable disk. Please insert a disk and try again.")
    os.sleep(extreme_delay)
    return
end

local base_path = "/mnt/" .. target_mnt .. "/"

print("Proceeding with installation...")
os.sleep(short_delay)
print("Wiping hard drive...")
os.sleep(short_delay)
wipeDirectory("/mnt/".. target_mnt .. "/")
os.sleep(short_delay)
local clean, culprit = checkCleanWipe("/mnt/".. target_mnt .. "/", wipe_exclusions)
if not clean then
    -- If the wipe fails, it will try to wipe the directory 5 times.
    for i = 1, 5 do
        wipeDirectory("/")
        clean, culprit = checkCleanWipe("/mnt/".. target_mnt .. "/", wipe_exclusions)
        if clean then
            break
        end
    end
end
if not clean then
    print("Wiped failed. Could not remove: " .. culprit)
    os.sleep(short_delay)
    print("Install can still continue, but file conflicts may occur.")
    os.sleep(short_delay)
    print("Installation may fail outright and hard drive irrecoverable.")
    os.sleep(short_delay)
    print("Continue at your own risk.")
    local response
    repeat
        io.write("Do you want to continue installation? (yes/no): ")
        response = io.read()
        if response then
            response = response:lower()
        end
    until response == "yes" or response == "no"
    if response == "no" then
        print("Install failed, drive may be irrecoverable.")
        print("Try again or toss the drive. Good luck!")
        os.sleep(5)
        return
    end
else
    os.sleep(1)
    print("Wipe successful.")
    os.sleep(short_delay)
end

print("Installing SolunaOS...")
os.sleep(short_delay)
print("Fetching install manifest...")
os.sleep(short_delay)


-- Pulls install manifest from dev server.
-- The manifest is a text file that contains the list of files to be installed.
local manifest_url = "http://localhost:8000/install_manifest.lua"
local response = internet.request(manifest_url)
if not response then
    print("Failed to download manifest. Please check your internet connection.")
    os.sleep(short_delay)
    local input
    repeat
        print("Connect again? Nothing is written. There is no risk")
        print("if disk imager is exited at this point.")
        print("Please ensure active internet connection.")
        print("Test by typing " .. manifest_url .. " in browser.")
        io.write("Try again? (yes/no): ")
        input = io.read()
        if input then
            input = input:lower()
        end
        if input == "yes" then
            response = internet.request(manifest_url)
        end
    until response or input == "no"
    if input == "no" then
        print("Install failed. Please check your internet connection.")
        os.sleep(extreme_delay)
        return
    end
end

print("Manifest found. Parsing...")
os.sleep(short_delay)
local content = ""

-- Handles packets from the response.
-- It concatenates the chunks into a single string.
-- The string is the content of the manifest file.
for chunk in response do
    content = content .. chunk
end

input = nil
while #content == 0 do
   print("Failed to download manifest. Please check your internet connection.")
    os.sleep(1)
    repeat
        print("Connect again? Nothing is written. There is no risk")
        print("if disk imager is exited at this point.")
        print("Please ensure active internet connection.")
        print("Test by typing " .. manifest_url .. " in browser.")
        io.write("Try again? (yes/no): ")
        input = io.read()
        if input then
            input = input:lower()
        end
    until input == "yes" or input == "no"

    if input == "no" then
        print("Install failed. Please check your internet connection.")
        os.sleep(extreme_delay)
        return
    elseif input == "yes" then
        response = internet.request(manifest_url)
        if response then
            content = ""
            for chunk in response do
                content = content .. chunk
            end
        end
    end
end

print("Manifest downloaded successfully.")
local manifest_path = filesystem.concat(base_path, "install_manifest.lua")
local manifest = io.open(manifest_path, "w")
if manifest then
print("Writing manifest to disk...")
manifest:write(content)
print("Manifest written to disk.")
manifest:close()
else
    print("Failed to open install_manifest.lua for writing. Please check your permissions.")
    os.sleep(short_delay)
    print("This means you picked a read only drive or you picked your current OS. Computer needs to be restarted.")
    print("If you picked your current OS, it may not be bootable.")
    print("Run the disk imager and try again.")
    os.sleep(extreme_delay)
    return
end

print("Manifest downloaded successfully.")
os.sleep(short_delay)
print("Parsing manifest...")

local files = dofile(manifest_path)

for _, entry in ipairs(files) do
    -- Downloads the file, concats the content into a string and then writes it to the disk.
    local filepath = entry.filename
    local url = "http://localhost:8000/" .. filepath
    local outpath = filesystem.concat(base_path, filepath)
    local file_path = filepath
    local file_response = internet.request(url)
    if not file_response then
        print("Failed to download " .. filepath)
        os.sleep(short_delay)
        print("Install failed. Hard drive may be irrecoverable.")
        os.sleep(extreme_delay)
        return
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
        print("http://localhost:8000/" .. file_path .. " -> " .. outpath)
        file:close()
    else
        print("Failed to open file for writing: " .. filepath .. ". Error: " .. tostring(open_err))
        os.sleep(short_delay)
        print("This means you picked a read only drive. Computer needs to be restarted.")
        print("Run the disk imager and try again.")
        os.sleep(extreme_delay)
        return
    end
end

print("All files downloaded and installed on disk.")
os.sleep(short_delay)
labelDrive(target_mnt)
print("SolunaOS installation complete!")
