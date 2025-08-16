_G.disk = {
    ["/"] = {
        type = "dir",
        contents = {
            ["tmp"] = {
                type = "dir",
                contents = {}
            },
            ["home"] = {
                type = "dir",
                contents = {}
            },
            ["foo.txt"] = {
                type = "file",
                data = "Hello, World!",
                size = 13,
                modified = os.time()
            },
            ["mnt"] = {
                type = "dir",
                contents = {}
            }
        },
        modified = os.time()
    }
}

_G.alt_disk = {
    ["/"] = {
        type = "dir",
        contents = {
            ["alttmp"] = {
                type = "dir",
                contents = {}
            },
            ["althome"] = {
                type = "dir",
                contents = {}
            },
            ["altfoo.txt"] = {
                type = "file",
                data = "Hello, World!",
                size = 13,
                modified = os.time()
            }
        },
        modified = os.time()
    }
}

local fs = require("filesystem")
local os = require("os")
local dir_list, err = fs.list("/")

if not dir_list then
    print("list() error:", err)
else
    print("Root directory contents:", table.concat(dir_list, ", "))
end

local list0, err0 = fs.list("/home/")

fs.makeDirectory("/home/user")
fs.makeDirectory("/home/user/projects")
fs.makeDirectory("/home/user/projects/test")


local list1, err1 = fs.list("/home/user/")
local list2, err2 = fs.list("/home/user/projects/")
local list3, err3 = fs.list("/home/user/projects/test/")

local file0 = fs.open("/hullo.txt", "w")
fs.close(file0)

local file = fs.open("/home/user/projects/test/hello.txt", "w")
fs.close(file)

local file2 = fs.open("/home/user/projects/helloproject.txt", "w")
fs.close(file2)

local file3 = fs.open("/home/user/hello2.txt", "w")
fs.close(file3)

local list33, err33 = fs.list("/home/")
local list4, err4 = fs.list("/home/user/")
local list5, err5 = fs.list("/home/user/projects/")
local list6, err6 = fs.list("/home/user/projects/test/")

--print("Home directory contents:", table.concat(list0, ", "))
--print("User directory contents:", table.concat(list1, ", "))
--print("User projects directory contents:", table.concat(list2, ", "))
--print("User projects test directory contents:", table.concat(list3, ", "))
--print("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
--print("Home directory contents after creating files:", table.concat(list33, ", "))
--print("User directory contents after creating files:", table.concat(list4, ", "))
--print("User projects directory contents after creating files:", table.concat(list5, ", "))
--print("User projects test directory contents after creating files:", table.concat(list6, ", "))

local new_dir_list, err = fs.list("/")

if not new_dir_list then
    print("list() error:", err)
else
    print("Root directory contents after creating files:", table.concat(new_dir_list, ", "))
end

local file0 = fs.open("/hullo.txt", "w")
fs.write(file0, "I'm a potato")
print("Written to /hullo.txt")
print("Data of file0: " .. tostring(file0 and file0.metatable.data))
fs.close(file0)


local file0 = fs.open("/hullo.txt", "r")
local content = fs.read(file0)
fs.close(file0)
print("Content of /hullo.txt: ", content)

local file6 = fs.open("/home/user/projects/test/hello.txt", "w")
fs.write(file6, "Hello from /home/user/projects/test/hello.txt")
print("Written to /home/user/projects/test/hello.txt")
print("Data of file6: " .. tostring(file6 and file6.metatable.data))
fs.close(file6)


local file6 = fs.open("/home/user/projects/test/hello.txt", "r")
local content6 = fs.read(file6)
fs.close(file6)
print("Content of /home/user/projects/test/hello.txt:", content6)


local exists = fs.exists("/hullo.txt") -- Should return true
print("File /hullo.txt exists:", exists)

local exists2 = fs.exists("/nonexistent.txt") -- Should return false
print("File /nonexistent.txt exists:", exists2)

local dir_exists = fs.isDirectory("/home/user/projects/test/") -- Should return true
print("Is directory /home/user/projects/test/: ", dir_exists)

local dir_exists2 = fs.isDirectory("/hullo.txt") -- Should return false
print("Is directory /hullo.txt: ", dir_exists2)

local size, err = fs.getSize("/hullo.txt") -- Should return the size of the file
print("Size of /hullo.txt: ", size .. (err or ""))

local size2, err2 = fs.getSize("/home/user/projects/test/") -- Should Return 0
print("Size of /home/user/projects/test/: ", size2 .. " " .. (err2 or ""))

local file_address = fs.concat("/home/////", "user/projects/test/hello.txt")

local file9 = fs.open(file_address, "r")
local contentt = fs.read(file9)
print("Content of file at address " .. file_address .. ": " .. contentt)
fs.close(file9)


print("Does /hullo.txt exist: " .. tostring(fs.exists("/hullo.txt"))) -- Should return true
fs.remove("/hullo.txt")
print("Does /hullo.txt exist: " .. tostring(fs.exists("/hullo.txt"))) -- Should return false
local _, err = fs.remove("/nonexistent.txt") -- Should return an error
print("Attempt to remove nonexistent file: " .. (err or "No error")) -- Should print an error message

local file10, err = fs.list("/home/user/projects")
print("User projects directory contents:", table.concat(file10, ", "))
print("Does /home/user/projects/test exist: ", tostring(fs.exists("/home/user/projects/test")))
local _, err = fs.remove("/home/user/projects/test/")
print("Removed /home/user/projects/test : " .. (err or "No error"))
print("Does /home/user/projects/test exist after removal: ", tostring(fs.exists("/home/user/projects/test")))

local file11, err = fs.list("/home/user/projects")
print("User projects directory contents:", table.concat(file11, ", "))

local ok, err = fs.copy("foo.txt", "/home/user/projects/foo.txt")
if not ok then
    print("Copy error:", err)
else
    print("File copied successfully to /home/user/projects/foo.txt")
end
local file12, err = fs.list("/home/user/projects")
print("User projects directory contents:", table.concat(file12, ", "))


local ok, err = fs.copy("home/user/", "/user")
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

local ok, err = fs.removeRecursive("/home/user/")
if not ok then
    print("Remove error:", err)
end

local file16 = fs.exists("/home/user/")
print("User directory exists after removal:", tostring(file16))

local ok, err = fs.move("/user", "/home/user")
if not ok then
    print("Move error:", err)
end

local file17, err = fs.list("/home/user")
print("User directory contents after moving:", table.concat(file17, ", "))

local file18 = fs.open("/happyeverafter.txt", "w")
fs.write(file18, "This is a test file. ")
fs.close(file18)

local file19 = fs.open("/happyeverafter.txt", "r")
local content19 = fs.read(file19)
fs.close(file19)
print("Content of /happyeverafter.txt:", content19)

local file20 = fs.open("/happyeverafter.txt", "a")
fs.write(file20, "This is an appended line.")
fs.close(file20)

local file21 = fs.open("/happyeverafter.txt", "r")
local content21 = fs.read(file21)
fs.close(file21)
print("Content of /happyeverafter.txt after appending:", content21)

local file22 = fs.open("/happyeverafter.txt", "a")
local file_pos, err = fs.seek(file22, 6, "set")
if err then
    print("Seek error:", err)
end

file_pos, err = fs.seek(file22, 13, "cur")

print(file22.pos)
local content22 = fs.read(file22, file_pos)
fs.close(file22)
print("Content of /happyeverafter.txt after seek:", content22)

local file23_addr = fs.tempFile()
print("Temporary file address:", file23_addr)

local file25, err = fs.list("/mnt")
print("Contents of /mnt:", table.concat(file25, ", "))

local mnt_address, err = fs.mount(alt_disk)
if err then
    error(err)
end

local file24, err = fs.list("/mnt")
print("Contents of /mnt after mounting alt_disk:", table.concat(file24, ", "))

local file26 = fs.list(mnt_address)
print("Contents of " .. mnt_address .. ":", table.concat(file26, ", "))

fs.unmount(mnt_address)
local file27, err = fs.list("/mnt")
print("Contents of /mnt after unmounting alt_disk:", table.concat(file27, ", "))

while true do
    os.sleep(1)
end

