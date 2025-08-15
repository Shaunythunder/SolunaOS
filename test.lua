_G.disk = {
    ["/"] = {
        type = "dir",
        entries = {
            ["tmp"] = {
                type = "dir",
                entries = {}
            },
            ["home"] = {
                type = "dir",
                entries = {}
            },
            ["foo.txt"] = {
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

print("Home directory contents:", table.concat(list0, ", "))
print("User directory contents:", table.concat(list1, ", "))
print("User projects directory contents:", table.concat(list2, ", "))
print("User projects test directory contents:", table.concat(list3, ", "))
print("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
print("Home directory contents after creating files:", table.concat(list33, ", "))
print("User directory contents after creating files:", table.concat(list4, ", "))
print("User projects directory contents after creating files:", table.concat(list5, ", "))
print("User projects test directory contents after creating files:", table.concat(list6, ", "))

local new_dir_list, err = fs.list("/")

if not new_dir_list then
    print("list() error:", err)
else
    print("Root directory contents after creating files:", table.concat(new_dir_list, ", "))
end

while true do
    os.sleep(1)
end

