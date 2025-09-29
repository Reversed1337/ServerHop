--// Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")

--// GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ServerHopGUI"
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 250, 0, 160)
MainFrame.Position = UDim2.new(0.5, -125, 0.5, -80)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

-- Rounded corners
local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 12)
Corner.Parent = MainFrame

-- Frame stroke for outline
local FrameStroke = Instance.new("UIStroke")
FrameStroke.Color = Color3.fromRGB(60, 60, 60)
FrameStroke.Thickness = 1
FrameStroke.Transparency = 0.5
FrameStroke.Parent = MainFrame

-- Title bar with gradient
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 35)
TitleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleGradient = Instance.new("UIGradient")
TitleGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 50)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 30))
}
TitleGradient.Parent = TitleBar

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 12)
TitleCorner.Parent = TitleBar

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Reversed's Hopper"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

-- Close button
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -35, 0, 2.5)
CloseButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 16
CloseButton.Parent = TitleBar
local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = CloseButton

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Hover effect for close button
CloseButton.MouseEnter:Connect(function()
    TweenService:Create(CloseButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 70, 70)}):Play()
end)
CloseButton.MouseLeave:Connect(function()
    TweenService:Create(CloseButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(200, 50, 50)}):Play()
end)

-- Execute button
local ExecuteButton = Instance.new("TextButton")
ExecuteButton.Size = UDim2.new(0, 180, 0, 45)
ExecuteButton.Position = UDim2.new(0.5, -90, 0, 60)
ExecuteButton.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
ExecuteButton.Text = "Start"
ExecuteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ExecuteButton.Font = Enum.Font.GothamBold
ExecuteButton.TextSize = 18
ExecuteButton.Parent = MainFrame
local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 10)
ButtonCorner.Parent = ExecuteButton

local ButtonGradient = Instance.new("UIGradient")
ButtonGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 140, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 100, 200))
}
ButtonGradient.Parent = ExecuteButton

-- Hover effect for execute button
ExecuteButton.MouseEnter:Connect(function()
    TweenService:Create(ExecuteButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 150, 255)}):Play()
end)
ExecuteButton.MouseLeave:Connect(function()
    TweenService:Create(ExecuteButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 120, 255)}):Play()
end)

-- Status Label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 25)
StatusLabel.Position = UDim2.new(0, 0, 1, -30)
StatusLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
StatusLabel.Text = "Idle"
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 14
StatusLabel.Parent = MainFrame

local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(0, 12)
StatusCorner.Parent = StatusLabel

--// Server Hop Script
local function StartServerHop()
    local PlaceID = game.PlaceId
    local JobID = game.JobId
    local AllIDs = {}
    local actualHour = os.date("!*t").hour
    local File = "NotSameServers.json"

    -- Load JSON with reset logic
    local success, data = pcall(function() return HttpService:JSONDecode(readfile(File)) end)
    if success and type(data) == "table" and data[1] == actualHour then
        AllIDs = data
    else
        AllIDs = {actualHour}
        pcall(function() writefile(File, HttpService:JSONEncode(AllIDs)) end)
    end

    local function findAndHop()
        StatusLabel.Text = "Searching for servers..."
        local servers = {}
        local cursor = ""
        local pages = 0
        repeat
            pages = pages + 1
            StatusLabel.Text = "Searching page " .. pages .. "..."
            local url = 'https://games.roblox.com/v1/games/' .. PlaceID .. '/servers/Public?sortOrder=Asc&excludeFullGames=true&limit=100'
            if cursor ~= "" then url = url .. "&cursor=" .. cursor end
            local success, site = pcall(function() return HttpService:JSONDecode(game:HttpGet(url)) end)
            if not success then
                StatusLabel.Text = "API request failed. Retrying..."
                return false
            end
            cursor = site.nextPageCursor
            for _, v in ipairs(site.data) do
                local id = tostring(v.id)
                if v.playing < v.maxPlayers - 7 and id ~= JobID and not table.find(AllIDs, id) then
                    table.insert(servers, {id = id, ping = v.ping or 999})
                end
            end
            wait(0.2)
        until (not cursor or cursor == "null") or #servers >= 10 or pages >= 5

        if #servers == 0 then
            StatusLabel.Text = "No suitable servers found. Retrying..."
            return false
        end

        table.sort(servers, function(a, b) return a.ping < b.ping end)
        local chosen = servers[1].id
        table.insert(AllIDs, chosen)
        pcall(function() writefile(File, HttpService:JSONEncode(AllIDs)) end)

        StatusLabel.Text = "Teleporting to server (ping: " .. servers[1].ping .. ")..."
        local tpSuccess, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(PlaceID, chosen, LocalPlayer)
        end)
        if not tpSuccess then
            StatusLabel.Text = "Teleport initiation failed: " .. (err or "Unknown error")
            table.remove(AllIDs, #AllIDs)
            return false
        end

        local startJob = game.JobId
        for i = 1, 15 do
            wait(1)
            if game.JobId ~= startJob then
                return true
            end
        end
        StatusLabel.Text = "Teleport timed out. Retrying..."
        table.remove(AllIDs, #AllIDs)
        return false
    end

    while true do
        if findAndHop() then break end
        wait(5)
    end
end

ExecuteButton.MouseButton1Click:Connect(function()
    StatusLabel.Text = "Starting..."
    StartServerHop()
end)

