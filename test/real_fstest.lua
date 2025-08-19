local fs = require("filesystem")
local os = require("os")

-- Test basic directory listing
local dir_list, err = fs.list("/")
if not dir_list then
    print("list() error:", err)
else
    print("Root directory contents:", table.concat(dir_list, ", "))
end

local lib = fs.list("/lib")
print("/lib directory contents:", table.concat(lib, ", "))

local core = fs.list("/lib/core")
print("/lib/core directory contents:", table.concat(core, ", "))

-- Create directory structure
fs.makeDirectory("/home/user")
fs.makeDirectory("/home/user/projects")
fs.makeDirectory("/home/user/projects/test")

-- Create test files
local file0 = fs.open("/hullo.txt", "w")
fs.close(file0)

local file = fs.open("/home/user/projects/test/hello.txt", "w")
fs.close(file)

local file2 = fs.open("/home/user/projects/helloproject.txt", "w")
fs.close(file2)

local file3 = fs.open("/home/user/hello2.txt", "w")
fs.close(file3)

-- List directories after file creation
local new_dir_list, err = fs.list("/")
if not new_dir_list then
    print("list() error:", err)
else
    print("Root directory contents after creating files:", table.concat(new_dir_list, ", "))
end

-- Test file writing and reading
local file0 = fs.open("/hullo.txt", "w")
fs.write(file0, "I'm a potato")
print("Written to /hullo.txt")
-- REMOVED: print("Data of file0: " .. tostring(file0 and file0.metatable.data)) -- No metatable.data in real filesystem
fs.close(file0)

local file0 = fs.open("/hullo.txt", "r")
local content = fs.read(file0)
fs.close(file0)
print("Content of /hullo.txt: ", content)

local file6 = fs.open("/home/user/projects/test/hello.txt", "w")
fs.write(file6, "Hello from /home/user/projects/test/hello.txt")
print("Written to /home/user/projects/test/hello.txt")
-- REMOVED: print("Data of file6: " .. tostring(file6 and file6.metatable.data)) -- No metatable.data in real filesystem
fs.close(file6)

local file6 = fs.open("/home/user/projects/test/hello.txt", "r")
local content6 = fs.read(file6)
fs.close(file6)
print("Content of /home/user/projects/test/hello.txt:", content6)

-- Test exists and isDirectory
local exists = fs.exists("/hullo.txt")
print("File /hullo.txt exists:", exists)

local exists2 = fs.exists("/nonexistent.txt")
print("File /nonexistent.txt exists:", exists2)

local dir_exists = fs.isDirectory("/home/user/projects/test/")
print("Is directory /home/user/projects/test/: ", dir_exists)

local dir_exists2 = fs.isDirectory("/hullo.txt")
print("Is directory /hullo.txt: ", dir_exists2)

-- Test getSize
local size, err = fs.getSize("/hullo.txt")
if size then
    print("Size of /hullo.txt: ", size)
else
    print("Size error:", err)
end

local size2, err2 = fs.getSize("/home/user/projects/test/")
if size2 then
    print("Size of /home/user/projects/test/: ", size2)
else
    print("Size error:", err2)
end

-- Test concat and file reading
local file_address = fs.concat("/home/////", "user/projects/test/hello.txt")
local file9 = fs.open(file_address, "r")
local contentt = fs.read(file9)
print("Content of file at address " .. file_address .. ": " .. contentt)
fs.close(file9)

-- Test remove
print("Does /hullo.txt exist: " .. tostring(fs.exists("/hullo.txt")))
fs.remove("/hullo.txt")
print("Does /hullo.txt exist: " .. tostring(fs.exists("/hullo.txt")))
local _, err = fs.remove("/nonexistent.txt")
print("Attempt to remove nonexistent file: " .. (err or "No error"))

-- Test directory removal
local file10, err = fs.list("/home/user/projects")
print("User projects directory contents:", table.concat(file10, ", "))
print("Does /home/user/projects/test exist: ", tostring(fs.exists("/home/user/projects/test")))
local _, err = fs.remove("/home/user/projects/test/")
print("Removed /home/user/projects/test : " .. (err or "No error"))
print("Does /home/user/projects/test exist after removal: ", tostring(fs.exists("/home/user/projects/test")))

local file11, err = fs.list("/home/user/projects")
print("User projects directory contents:", table.concat(file11, ", "))

-- Test copy (skip foo.txt test since it may not exist)
-- SKIPPED: local ok, err = fs.copy("foo.txt", "/home/user/projects/foo.txt")

-- Test directory copy
local ok, err = fs.copy("/home/user/", "/user")
if not ok then
    print("Copy error:", err)
else
    print("Directory copied successfully to /user")
end

local file13, err = fs.list("/")
local file15, err = fs.list("/user")
local file14, err = fs.list("/user/projects")
print("Root directory contents after copying:", table.concat(file13, ", "))
print("User directory contents after copying:", table.concat(file15, ", "))
print("Projects directory contents after copying:", table.concat(file14, ", "))

-- Test removeRecursive
local ok, err = fs.removeRecursive("/home/user/")
if not ok then
    print("Remove error:", err)
end

local file16 = fs.exists("/home/user/")
print("User directory exists after removal:", tostring(file16))

-- Test move
local ok, err = fs.move("/user", "/home/user")
if not ok then
    print("Move error:", err)
end

local file17, err = fs.list("/home/user")
print("User directory contents after moving:", table.concat(file17, ", "))

-- Test append mode
local file18 = fs.open("/happyeverafter.txt", "w")
fs.write(file18, "This is a test file. ")
fs.close(file18)

local file19 = fs.open("/happyeverafter.txt", "r")
local content19 = fs.read(file19)
fs.close(file19)
print("Content of /happyeverafter.txt:", content19)

local file20 = fs.open("/happyeverafter.txt", "a")
fs.write(file20, "This is an appended line. I am still a potato.")
fs.close(file20)

local file21 = fs.open("/happyeverafter.txt", "r")
local content21 = fs.read(file21)
fs.close(file21)
print("Content of /happyeverafter.txt after appending:", content21)

-- Test seek (use read mode, not append)
local file22 = fs.open("/happyeverafter.txt", "r")  -- Read mode instead
local file_pos, err = fs.seek(file22, 6, "set")
if err then
    print("Seek error:", err)
else
    print("Seek position:", file_pos)
end

file_pos, err = fs.seek(file22, 13, "cur")
if err then
    print("Seek error:", err)
else
    print("New seek position:", file_pos)
end

-- Read from the seek position
local content22 = fs.read(file22, 15)
fs.close(file22)
print("Content of /happyeverafter.txt after seek:", content22)

-- Test tempFile
local file23_addr = fs.tempFile()
print("Temporary file address:", file23_addr)

while true do
    os.sleep(1) -- Keep the script running to see the output
end