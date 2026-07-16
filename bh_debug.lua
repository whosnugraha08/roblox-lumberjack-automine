local Players = game:GetService("Players")
local LP = Players.LocalPlayer

local boot = LP:WaitForChild("PlayerScripts"):WaitForChild("Bootstrapper"):WaitForChild("Client")
local VisualsHandler = require(boot:WaitForChild("VisualsHandler"))
local CaptionHandler = require(boot:WaitForChild("CaptionHandler"))

print("=== STARTING ERROR LOGGER HOOK ===")

-- Hook DisplayNewShells and print errors
local oldDisplay = VisualsHandler.DisplayNewShells
VisualsHandler.DisplayNewShells = function(self, data, ...)
    print("[DEBUG HOOK] DisplayNewShells CALLED!")
    local ok, err = pcall(function()
        if typeof(data) == "table" then
            print("  tableId:", tostring(data.tableId))
            print("  action:", tostring(data.action))
            print("  live:", tostring(data.liveShells))
            print("  blank:", tostring(data.blankShells))
        else
            print("  data is not a table, type:", typeof(data))
        end
    end)
    if not ok then
        print("[DEBUG ERROR] DisplayNewShells hook failed:", err)
    end
    return oldDisplay(self, data, ...)
end

-- Hook CaptionHandler and print errors
local oldCaption = CaptionHandler.DisplayCaption
CaptionHandler.DisplayCaption = function(self, data, ...)
    print("[DEBUG HOOK] DisplayCaption CALLED!")
    local ok, err = pcall(function()
        if typeof(data) == "table" then
            print("  text:", tostring(data.text))
            print("  duration:", tostring(data.duration))
        else
            print("  data is not a table, type:", typeof(data))
        end
    end)
    if not ok then
        print("[DEBUG ERROR] DisplayCaption hook failed:", err)
    end
    return oldCaption(self, data, ...)
end

print("[DEBUG HOOK] Overwrote with robust logging!")
