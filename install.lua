term.clear()
term.setCursorPos(1,1)

print("Installer for PineCLI by Dusk")
print("[ note: not endorsed by Xella, creator of PineStore") -- as of 5/6/2024

local dirs = { "/apps/", "/pine/", "/pine/config/" }
print("Making directories: ")
for k,v in pairs(dirs) do
	print(v)
	fs.makeDir(v)
end

print("Done")

print("Fetching default startup file and pine file.")

shell.run("wget https://raw.githubusercontent.com/XDuskAshes/PineCLI/master/pine/pine.lua pine/pine.lua")
shell.run("wget https://raw.githubusercontent.com/XDuskAshes/PineCLI/master/startup.lua")

print("Installed. Restarting.")
sleep(1)
os.reboot()
