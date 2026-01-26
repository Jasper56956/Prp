-- ================= LOADER UI (GitHub Linked) =================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()


local WaypointSys = loadstring(game:HttpGet("https://raw.githubusercontent.com/Jasper56956/R/main/WaypointModule.lua?v="..tick()))()

local MiningSys = loadstring(game:HttpGet("https://raw.githubusercontent.com/Jasper56956/R/main/MiningModule.lua?v="..tick()))()

-- ================= CREATE UI =================
local Window = Rayfield:CreateWindow({
    Name = "Mining Script",
    LoadingTitle = "Loading...",
    LoadingSubtitle = "Connected to ",
    ConfigurationSaving = {
       Enabled = false,
       FolderName = nil, 
       FileName = "MiningHub"
    },
})