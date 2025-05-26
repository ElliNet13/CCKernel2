print("By continuing, you will remove CCKernel2.")
print("Are you sure you want to continue? (Y/N)")
print("This will also remove the startup script and reboot your computer.")
if read() ~= "y" then return end

fs.delete("/etc")
fs.delete("/home")
fs.delete("/usr")
fs.delete("/kernel.lua")
fs.delete("/startup.lua")

local file = fs.open("/startup.lua", "w")

file.writeLine("fs.delete(\"/var\")")
file.writeLine("fs.delete(\"/startup.lua\")")
file.writeLine("os.reboot()")
file.close()

print("If you computer does not reboot, please try to press and hold CTRL+T to terminate the shell, that should force a reboot.")

os.reboot()