-- pine CLI/TUI (TUI comes later)
-- by Dusk
-- not endorsed by Xella

local ver = 1.0
local args = {...}
local spinner = {"|","/","-","\\"}
local stage = 0
local iCurrentDir = fs.list("/"..shell.dir())

if args[1] == "" or args[1] == nil then
	printError("If you need help, just say that. ( pine help )")
else
	if args[1] == "help" then
		print("Usage:\n pine <args> <app>")
		print("Flags:\n -a/add <app> | Install an application.\n -r/remove <app> | Uninstall an application.\n -i/info <app> | Get an application's info.\n -s/sync | Update the packages database file.\n -v/version | View PineCLI version.")
	elseif args[1] == "config" then
		if args[2] == "help" then
			print("Usage: pine config <key>:<value>")
			print("This edits /pine/config/config.cfg directly.")
		else
			local key,value = string.match(args[2],"([^:]+):([^:]+)")
			local handle = fs.open("/pine/config/config.cfg","a")
			handle.writeLine(key..":"..value)
			handle.close()
			print("Config added.")
		end
	else
		if args[1] == "-a" or args[1] == "add" then
			
			if args[2] == nil or args[2] == "" then
				error("Tell me what to add, please. ( pine "..args[1].." <app> )",0)
			else
				local loopOver = {}
				local whatID = 0
				local handle = fs.open("/pine/config/apps.list","r")

				if not handle then
					error("Can't find the apps list. Have you run 'pine sync' yet?",0)
				end

				repeat
					local a = handle.readLine()
					table.insert(loopOver,a)
				until a == nil

				handle.close()

				for k,v in pairs(loopOver) do
					local name, id = string.match(v, "([^:]+):([^:]+)")

					if args[2] == name then
						whatID = id
						break
					end
				end

				if whatID == 0 then
					error("Couldn't find: "..args[2],0)
				end

				local request = http.get("https://pinestore.cc/api/project/"..whatID)

				if not request then
					error("Could not connect to 'https://pinestore.cc/api/project/'. Is it whitelisted?",0)
				end
				
				local reqRaw = request.readAll()
				local reqUns = textutils.unserializeJSON(reqRaw)

				term.setTextColor(colors.green)
				write("Name: ")
				term.setTextColor(colors.white)
				print(reqUns.project.name)
				term.setTextColor(colors.green)
				write("Description: ")
				term.setTextColor(colors.white)
				print(reqUns.project.description_short)

				local yn = true
				write("\nInstall? [Y/N]:")
				while true do
					local event = {os.pullEvent()}
					local nEvent = event[1]
					local vEvent = event[2]

					if nEvent == "key" then
						if vEvent == keys.y then
							print("Y")
							break
						elseif vEvent == keys.n then
							yn = false
							print("N")
							break
						end
					end
				end

				if not yn then
					error("Cancelling.",0)
				end

				fs.makeDir("/apps/"..reqUns.project.name)

				local finalDir = "/apps/"..reqUns.project.name.."/"

				print("+=====+")

				shell.run("wget run https://pinestore.cc/d/"..whatID)

				print("+=====+")

				-- thanks to oca for idiot-checking my code :]

				local dir = fs.list(shell.dir())

				if shell.dir() ~= "" then
					for k,v in pairs(dir) do
						fs.move(v,finalDir..v)
					end
				else
					for k,v in pairs(dir) do
						if v == "apps" or v == "pine" then
							table.remove(dir,k)
						elseif v == "startup.lua" then
							table.remove(dir,k)
						elseif v == "rom" then
							table.remove(dir,k)
						end
					end

					for k,v in pairs(dir) do
						if v ~= "rom" then
							fs.move(v,finalDir..v)
						end
					end
				end
				
				print("Installation done.")
				printError("Reccomendation: edit your /startup.lua file to include:\n :"..finalDir.."\nto the 'cPath' variable, then restarting.")

			end

		elseif args[1] == "-r" or args[1] == "remove" then
			
			if not fs.exists("/apps/"..args[2]) then
				error("Cannot remove '"..args[2].."': either not installed or buggy install.",0)
			else
				fs.delete("/apps/"..args[2])

				if fs.exists("/apps/"..args[2]) then
					error("An issue occured uninstalling. Consider manually doing it.",0)
				end
			end

			print("Deletion success.")

			printError("Reccomendation: edit your /startup.lua file to remove:\n :"..finalDir.."\nfrom the 'cPath' variable, then restarting.")

		elseif args[1] == "-i" or args[1] == "info" then
			
			if args[2] == nil or args[2] == "" then
				error("I need an app name to lookup before I can find the info.",0)
			end

			local list = {}

			local handle = fs.open("/pine/config/apps.list","r")

			if not handle then
				error("Can't find the apps list. Have you run 'pine sync' yet?",0)
			end

			repeat
				local a = handle.readLine()
				table.insert(list,a)
			until a == nil

			handle.close()
			
			local foundIt = false
			local whatID = 0
			for k,v in pairs(list) do
				local app,id = string.match(v, "([^:]+):([^:]+)")

				if app == args[2] then
					foundIt = true
					whatID = id
					break
				end
			end

			if foundIt then
				local request = http.get("https://pinestore.cc/api/project/"..whatID)

				if not request then
					error("Could not connect to 'https://pinestore.cc/'. Is it whitelisted?",0)
				else
					local reqRaw = request.readAll()
					local reqUns = textutils.unserializeJSON(reqRaw)

					term.setTextColor(colors.green)
					write("Name: ")
					term.setTextColor(colors.white)
					print(reqUns.project.name)
					term.setTextColor(colors.green)
					write("Description: ")
					term.setTextColor(colors.white)
					print(reqUns.project.description_short)
				end
			else
				error("Couldn't find: '"..args[2].."'. Try 'pine sync' to update the local apps.list file.",0)
			end

		elseif args[1] == "-s" or args[1] == "sync" then
			print("Contacting API for all proper project IDs...")
			
			local writeTo = {}

			local request = http.get("https://pinestore.cc/api/projects")

			if not request then
				error("Could not access: 'https://pinestore.cc/'. Is it whitelisted?",0)
			else
				print("Reading JSON...")
				local reqRaw = request.readAll()
				local reqUns = textutils.unserializeJSON(reqRaw)
				for i = 1, #reqUns.projects do
					table.insert(writeTo,reqUns.projects[i].name..":"..reqUns.projects[i].id)
				end
				
				local cx,cy = term.getCursorPos()
				local handle = fs.open("/pine/config/apps.list","w")
				for k,v in pairs(writeTo) do
					term.setCursorPos(cx,cy)
					term.clearLine(cy)
					stage = (stage % 4) + 1
					write("Writing out to '/pine/config/apps.list'... " .. spinner[stage])
					
					handle.writeLine(v)
					sleep(0.01)
				end

				handle.close()
				print("\nSync done.")
			end
		elseif args[1] == "-v" or args[1] == "version" then
			print("PineCLI v"..ver.." by Dusk")
		else
			error("Unknown opt: '"..args[1].."' ( pine help )",0)
		end
	end
end
