if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

if not LocalPlayer.Character then LocalPlayer.CharacterAdded:Wait() end
task.wait(0.5)

local function safeSet(obj, prop, value) pcall(function() obj[prop] = value end) end

local CONFIG_FOLDER = "RivalsCheat"
local CONFIG_EXTENSION = ".json"
local currentConfigName = "default"

pcall(function()
    if not isfolder(CONFIG_FOLDER) then
        makefolder(CONFIG_FOLDER)
    end
end)

local function createKeybind(keyCodeOrUserInput)
    local isMouse = typeof(keyCodeOrUserInput) == "EnumItem" and keyCodeOrUserInput.EnumType == Enum.UserInputType
    return {
        isMouseButton = isMouse,
        value = keyCodeOrUserInput
    }
end

local config = {
    aimbot = {
        enabled = false,
        mode = "Legit"
    },
    legitAim = {
        fovRadius = 120,
        showFov = true,
        fovColor = Color3.fromRGB(100, 255, 100),
        smoothness = 10,
        targetPart = "Head",
        aimKey = createKeybind(Enum.UserInputType.MouseButton2),
        toggleKey = createKeybind(Enum.KeyCode.X)
    },
    rageAim = {
        fovRadius = 300,
        showFov = true,
        fovColor = Color3.fromRGB(255, 100, 100),
        targetPart = "Head",
        aimKey = createKeybind(Enum.UserInputType.MouseButton2),
        toggleKey = createKeybind(Enum.KeyCode.X)
    },
    menu = {
        menuKey = createKeybind(Enum.KeyCode.Insert)
    },
    antiAim = {
        enabled = false,
        mode = "Spin",
        spinSpeed = 20,
        headEnabled = true,
        headSpeed = 15,
        onlyWhenStill = false
    },
    other = {
        fly = false,
        flySpeed = 50,
        noclip = false
    },
    esp = {
        enabled = false,
        maxDistance = 500,
        chamsEnabled = true,
        boxEnabled = true,
        healthBarEnabled = true,
        enemyColor = Color3.fromRGB(255, 85, 85),
        targetColor = Color3.fromRGB(255, 200, 87)
    },
    crosshair = {
        enabled = true,
        size = 10,
        thickness = 2,
        gap = 5,
        color = Color3.fromRGB(0, 255, 0),
        outline = true,
        dot = true
    },
    watermark = {
        enabled = true,
        showFps = true,
        showPing = true,
        showTime = true
    },
    configSystem = {
        autoSave = true,
        autoSaveInterval = 60
    },
    ui = {
        accentColor = Color3.fromRGB(255, 100, 100),
        backgroundColor = Color3.fromRGB(20, 20, 20),
        textColor = Color3.fromRGB(255, 255, 255)
    }
}

local lockedTarget = nil
local currentTargetPart = nil
local isAiming = false
local waitingForKeybind = nil
local keybindWaitStartTime = 0

local function getKeybindName(keybindData)
    if not keybindData or not keybindData.value then return "None" end
    if keybindData.isMouseButton then
        if keybindData.value == Enum.UserInputType.MouseButton1 then
            return "Mouse1"
        elseif keybindData.value == Enum.UserInputType.MouseButton2 then
            return "Mouse2"
        elseif keybindData.value == Enum.UserInputType.MouseButton3 then
            return "Mouse3"
        end
        return keybindData.value.Name
    else
        return keybindData.value.Name
    end
end

local function isKeybindPressed(keybindData, input)
    if not keybindData or not keybindData.value then return false end
    if keybindData.isMouseButton then
        return input.UserInputType == keybindData.value
    else
        return input.KeyCode == keybindData.value
    end
end

local function isKeybindHeld(keybindData)
    if not keybindData or not keybindData.value then return false end
    if keybindData.isMouseButton then
        if keybindData.value == Enum.UserInputType.MouseButton1 then
            return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
        elseif keybindData.value == Enum.UserInputType.MouseButton2 then
            return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        elseif keybindData.value == Enum.UserInputType.MouseButton3 then
            return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton3)
        end
    else
        return UIS:IsKeyDown(keybindData.value)
    end
    return false
end

local function color3ToTable(color)
    return {R = color.R, G = color.G, B = color.B}
end

local function tableToColor3(t)
    if type(t) == "table" and t.R then
        return Color3.new(t.R, t.G, t.B)
    end
    return Color3.fromRGB(255, 255, 255)
end

local function keybindToTable(keybindData)
    if not keybindData or not keybindData.value then 
        return {_isKeybind = true, isMouseButton = false, name = "X"}
    end
    return {
        _isKeybind = true,
        isMouseButton = keybindData.isMouseButton,
        name = keybindData.value.Name
    }
end

local function tableToKeybind(t)
    if type(t) == "table" and t._isKeybind then
        if t.isMouseButton then
            local success, result = pcall(function()
                return Enum.UserInputType[t.name]
            end)
            if success and result then
                return createKeybind(result)
            end
        else
            local success, result = pcall(function()
                return Enum.KeyCode[t.name]
            end)
            if success and result then
                return createKeybind(result)
            end
        end
    end
    return createKeybind(Enum.KeyCode.X)
end

local function prepareConfigForSave(cfg)
    local saved = {}
    for k, v in pairs(cfg) do
        if type(v) == "table" then
            if v.isMouseButton ~= nil and v.value then
                saved[k] = keybindToTable(v)
            else
                saved[k] = {}
                for k2, v2 in pairs(v) do
                    if typeof(v2) == "Color3" then
                        saved[k][k2] = color3ToTable(v2)
                        saved[k][k2]._isColor3 = true
                    elseif type(v2) == "table" and v2.isMouseButton ~= nil and v2.value then
                        saved[k][k2] = keybindToTable(v2)
                    else
                        saved[k][k2] = v2
                    end
                end
            end
        else
            saved[k] = v
        end
    end
    return saved
end

local function restoreConfigFromSave(saved)
    for k, v in pairs(saved) do
        if config[k] and type(v) == "table" then
            if v._isKeybind then
                config[k] = tableToKeybind(v)
            else
                for k2, v2 in pairs(v) do
                    if type(v2) == "table" and v2._isColor3 then
                        config[k][k2] = tableToColor3(v2)
                    elseif type(v2) == "table" and v2._isKeybind then
                        config[k][k2] = tableToKeybind(v2)
                    elseif config[k][k2] ~= nil and not (type(v2) == "table" and v2.isMouseButton ~= nil) then
                        config[k][k2] = v2
                    elseif type(v2) == "table" and v2.isMouseButton ~= nil then
                        config[k][k2] = tableToKeybind(v2)
                    end
                end
            end
        end
    end
end

local ConfigSystem = {}
ConfigSystem.configs = {}
ConfigSystem.lastSave = 0

function ConfigSystem.listConfigs()
    local configs = {}
    pcall(function()
        if isfolder(CONFIG_FOLDER) then
            local files = listfiles(CONFIG_FOLDER)
            for _, file in pairs(files) do
                local name = file:match("([^/\\]+)$")
                if name and name:sub(-#CONFIG_EXTENSION) == CONFIG_EXTENSION then
                    local configName = name:sub(1, -#CONFIG_EXTENSION - 1)
                    table.insert(configs, configName)
                end
            end
        end
    end)
    ConfigSystem.configs = configs
    return configs
end

function ConfigSystem.save(name)
    name = name or currentConfigName
    local success, err = pcall(function()
        local data = prepareConfigForSave(config)
        data._configName = name
        data._saveTime = os.date("%Y-%m-%d %H:%M:%S")
        data._version = "3.9.1"
        local json = HttpService:JSONEncode(data)
        writefile(CONFIG_FOLDER .. "/" .. name .. CONFIG_EXTENSION, json)
    end)
    if success then
        currentConfigName = name
        ConfigSystem.lastSave = tick()
        return true
    else
        warn("Config save error:", err)
    end
    return false
end

function ConfigSystem.load(name)
    local success, err = pcall(function()
        local path = CONFIG_FOLDER .. "/" .. name .. CONFIG_EXTENSION
        if isfile(path) then
            local json = readfile(path)
            local data = HttpService:JSONDecode(json)
            restoreConfigFromSave(data)
            currentConfigName = name
        end
    end)
    if not success then
        warn("Config load error:", err)
    end
    return success
end

function ConfigSystem.delete(name)
    local success = pcall(function()
        local path = CONFIG_FOLDER .. "/" .. name .. CONFIG_EXTENSION
        if isfile(path) then
            delfile(path)
        end
    end)
    ConfigSystem.listConfigs()
    return success
end

function ConfigSystem.export(name)
    name = name or currentConfigName
    local success = pcall(function()
        local path = CONFIG_FOLDER .. "/" .. name .. CONFIG_EXTENSION
        local json = ""
        if isfile(path) then
            json = readfile(path)
        else
            local data = prepareConfigForSave(config)
            data._configName = name
            data._saveTime = os.date("%Y-%m-%d %H:%M:%S")
            data._version = "3.9.1"
            json = HttpService:JSONEncode(data)
        end
        setclipboard(json)
    end)
    return success
end

local function autoSaveLoop()
    while true do
        task.wait(config.configSystem.autoSaveInterval)
        if config.configSystem.autoSave then
            ConfigSystem.save(currentConfigName)
        end
    end
end

task.spawn(autoSaveLoop)

task.spawn(function()
    task.wait(1)
    ConfigSystem.listConfigs()
    if #ConfigSystem.configs > 0 then
        if table.find(ConfigSystem.configs, "default") then
            ConfigSystem.load("default")
        end
    end
end)

local antiAimAngle = 0
local headAngle = 0
local originalC0 = nil

local function isPlayerMoving()
    local char = LocalPlayer.Character
    if not char then return false end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    return humanoid.MoveDirection.Magnitude > 0.1
end

local function updateAntiAim(dt)
    if not config.antiAim.enabled then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local neck = nil
    
    local head = char:FindFirstChild("Head")
    if head then neck = head:FindFirstChild("Neck") end
    if not neck then
        local upperTorso = char:FindFirstChild("UpperTorso")
        if upperTorso then neck = upperTorso:FindFirstChild("Neck") end
    end
    if not neck then
        local torso = char:FindFirstChild("Torso")
        if torso then neck = torso:FindFirstChild("Neck") end
    end
    
    if not hrp then return end
    
    local isMoving = isPlayerMoving()
    if config.antiAim.onlyWhenStill and isMoving then
        if neck and originalC0 then
            pcall(function() neck.C0 = originalC0 end)
        end
        return
    end
    
    if neck and not originalC0 then
        originalC0 = neck.C0
    end
    
    local mode = config.antiAim.mode
    
    if mode == "Spin" then
        antiAimAngle = antiAimAngle + (config.antiAim.spinSpeed * dt * 10)
        if antiAimAngle > 360 then antiAimAngle = antiAimAngle - 360 end
    elseif mode == "Jitter" then
        antiAimAngle = math.random(-180, 180)
    elseif mode == "Random" then
        if math.random(1, 3) == 1 then
            antiAimAngle = math.random(-180, 180)
        end
    end
    
    pcall(function()
        local currentPos = hrp.Position
        local baseAngle = math.rad(antiAimAngle)
        hrp.CFrame = CFrame.new(currentPos) * CFrame.Angles(0, baseAngle, 0)
    end)
    
    if config.antiAim.headEnabled and neck then
        if mode == "Spin" then
            headAngle = headAngle + (config.antiAim.headSpeed * dt * 10)
            if headAngle > 360 then headAngle = headAngle - 360 end
        elseif mode == "Jitter" then
            headAngle = math.random(-90, 90)
        elseif mode == "Random" then
            if math.random(1, 2) == 1 then
                headAngle = math.random(-90, 90)
            end
        end
        
        pcall(function()
            if originalC0 then
                local headRad = math.rad(headAngle)
                local pitchRandom = math.rad(math.random(-30, 30))
                neck.C0 = originalC0 * CFrame.Angles(pitchRandom, headRad, 0)
            end
        end)
    end
end

local function stopAntiAim()
    local char = LocalPlayer.Character
    if not char then return end
    
    local neck = nil
    local head = char:FindFirstChild("Head")
    if head then neck = head:FindFirstChild("Neck") end
    if not neck then
        local upperTorso = char:FindFirstChild("UpperTorso")
        if upperTorso then neck = upperTorso:FindFirstChild("Neck") end
    end
    if not neck then
        local torso = char:FindFirstChild("Torso")
        if torso then neck = torso:FindFirstChild("Neck") end
    end
    
    if neck and originalC0 then
        pcall(function() neck.C0 = originalC0 end)
    end
    
    antiAimAngle = 0
    headAngle = 0
end

local noclipParts = {}

local function enableNoclip()
    local char = LocalPlayer.Character
    if not char then return end
    
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            noclipParts[part] = part.CanCollide
            part.CanCollide = false
        end
    end
end

local function disableNoclip()
    local char = LocalPlayer.Character
    if not char then return end
    
    for part, originalCollide in pairs(noclipParts) do
        if part and part.Parent then
            pcall(function() part.CanCollide = originalCollide end)
        end
    end
    noclipParts = {}
end

local function updateNoclip()
    if not config.other.noclip and not config.other.fly then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end

local flyBodyVelocity = nil
local flyBodyGyro = nil
local isFlying = false

local function startFly()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then return end
    
    isFlying = true
    pcall(function() humanoid.PlatformStand = true end)
    
    local oldBV = hrp:FindFirstChild("FlyVelocity")
    local oldBG = hrp:FindFirstChild("FlyGyro")
    if oldBV then oldBV:Destroy() end
    if oldBG then oldBG:Destroy() end
    
    flyBodyVelocity = Instance.new("BodyVelocity")
    flyBodyVelocity.Name = "FlyVelocity"
    flyBodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
    flyBodyVelocity.Parent = hrp
    
    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.Name = "FlyGyro"
    flyBodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    flyBodyGyro.P = 9000
    flyBodyGyro.D = 500
    flyBodyGyro.CFrame = hrp.CFrame
    flyBodyGyro.Parent = hrp
    
    enableNoclip()
end

local function stopFly()
    isFlying = false
    
    local char = LocalPlayer.Character
    if char then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            pcall(function() humanoid.PlatformStand = false end)
        end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local oldBV = hrp:FindFirstChild("FlyVelocity")
            local oldBG = hrp:FindFirstChild("FlyGyro")
            if oldBV then oldBV:Destroy() end
            if oldBG then oldBG:Destroy() end
        end
    end
    
    flyBodyVelocity = nil
    flyBodyGyro = nil
    
    if not config.other.noclip then
        disableNoclip()
    end
end

local function updateFly()
    if not config.other.fly or not isFlying then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    if not flyBodyVelocity or not flyBodyVelocity.Parent then
        startFly()
        return
    end
    
    local speed = config.other.flySpeed
    local direction = Vector3.new(0, 0, 0)
    
    if UIS:IsKeyDown(Enum.KeyCode.W) then
        direction = direction + Camera.CFrame.LookVector
    end
    if UIS:IsKeyDown(Enum.KeyCode.S) then
        direction = direction - Camera.CFrame.LookVector
    end
    if UIS:IsKeyDown(Enum.KeyCode.A) then
        direction = direction - Camera.CFrame.RightVector
    end
    if UIS:IsKeyDown(Enum.KeyCode.D) then
        direction = direction + Camera.CFrame.RightVector
    end
    if UIS:IsKeyDown(Enum.KeyCode.Space) then
        direction = direction + Vector3.new(0, 1, 0)
    end
    if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
        direction = direction - Vector3.new(0, 1, 0)
    end
    
    if direction.Magnitude > 0 then
        direction = direction.Unit * speed
    end
    
    flyBodyVelocity.Velocity = direction
    flyBodyGyro.CFrame = Camera.CFrame
end

local library = {drawings = {}, hidden = {}, connections = {}, began = {}, ended = {}, changed = {}, shared = {initialized = false}, allTexts = {}}
local utility = {}
local pages = {}
local sections = {}

local theme = {
    accent = config.ui.accentColor,
    light_contrast = Color3.fromRGB(30, 30, 30),
    dark_contrast = config.ui.backgroundColor,
    outline = Color3.fromRGB(0, 0, 0),
    inline = Color3.fromRGB(50, 50, 50),
    textcolor = config.ui.textColor,
    textborder = Color3.fromRGB(0, 0, 0),
    font = 2, textsize = 13
}

function utility:Size(xS,xO,yS,yO,i) if i then return Vector2.new(xS*i.Size.x+xO,yS*i.Size.y+yO) else return Vector2.new(xS*Camera.ViewportSize.x+xO,yS*Camera.ViewportSize.y+yO) end end
function utility:Position(xS,xO,yS,yO,i) if i then return Vector2.new(i.Position.x+xS*i.Size.x+xO,i.Position.y+yS*i.Size.y+yO) else return Vector2.new(xS*Camera.ViewportSize.x+xO,yS*Camera.ViewportSize.y+yO) end end

function utility:Create(instanceType, instanceOffset, instanceProperties, instanceParent)
    local instanceHidden = false
    local instance = nil
    local success, result = pcall(function()
        if instanceType == "Frame" then
            local f = Drawing.new("Square"); safeSet(f,"Visible",true); safeSet(f,"Filled",true); safeSet(f,"Thickness",0); safeSet(f,"Color",Color3.fromRGB(255,255,255)); safeSet(f,"Size",Vector2.new(100,100)); safeSet(f,"Position",Vector2.new(0,0)); safeSet(f,"ZIndex",50); safeSet(f,"Transparency",library.shared.initialized and 1 or 0); return f
        elseif instanceType == "TextLabel" then
            local t = Drawing.new("Text"); safeSet(t,"Font",3); safeSet(t,"Visible",true); safeSet(t,"Outline",true); safeSet(t,"Center",false); safeSet(t,"Color",Color3.fromRGB(255,255,255)); safeSet(t,"ZIndex",50); safeSet(t,"Transparency",library.shared.initialized and 1 or 0); return t
        elseif instanceType == "Triangle" then
            local f = Drawing.new("Triangle"); safeSet(f,"Visible",true); safeSet(f,"Filled",true); safeSet(f,"Color",Color3.fromRGB(255,255,255)); safeSet(f,"ZIndex",50); safeSet(f,"Transparency",library.shared.initialized and 1 or 0); return f
        end
    end)
    if success and result then instance = result else return nil end
    if instance then
        for i, v in pairs(instanceProperties or {}) do
            if i == "Hidden" then instanceHidden = true
            else pcall(function() if library.shared.initialized then instance[i] = v elseif i ~= "Transparency" then instance[i] = v end end) end
        end
        if instanceType == "TextLabel" and not instanceHidden then table.insert(library.allTexts, instance) end
        if not instanceHidden then library.drawings[#library.drawings + 1] = {instance, instanceOffset or {Vector2.new(0,0)}, instanceProperties and instanceProperties["Transparency"] or 1}
        else library.hidden[#library.hidden + 1] = {instance} end
        if instanceParent then instanceParent[#instanceParent + 1] = instance end
        return instance
    end
end

function utility:UpdateOffset(i, o) for _,v in pairs(library.drawings) do if v[1] == i then v[2] = o end end end
function utility:Remove(i, h) local ind = 0; for x,v in pairs(h and library.hidden or library.drawings) do if v[1] == i then ind = x; if h then v[1] = nil else v[2] = nil; v[1] = nil end end end; if ind > 0 then table.remove(h and library.hidden or library.drawings, ind) end; pcall(function() if i and i.Remove then i:Remove() end end) end
function utility:Connection(t, c) local conn = t:Connect(c); library.connections[#library.connections + 1] = conn; return conn end
function utility:MouseLocation() return UIS:GetMouseLocation() end
function utility:MouseOverDrawing(v, a) local a = a or {}; local v = {(v[1] or 0)+(a[1] or 0),(v[2] or 0)+(a[2] or 0),(v[3] or 0)+(a[3] or 0),(v[4] or 0)+(a[4] or 0)}; local m = utility:MouseLocation(); return (m.x >= v[1] and m.x <= v[3]) and (m.y >= v[2] and m.y <= v[4]) end
function utility:GetTextBounds(t, s, f) local tb = Vector2.new(0,0); pcall(function() local tl = utility:Create("TextLabel",{Vector2.new(0,0)},{Text=t,Size=s,Font=f,Hidden=true}); if tl and tl.TextBounds then tb = tl.TextBounds end; utility:Remove(tl,true) end); return tb end
function utility:GetScreenSize() return Camera.ViewportSize end

local Watermark = {}
Watermark.drawings = {}

function Watermark.create()
    Watermark.drawings.bg = Drawing.new("Square")
    Watermark.drawings.bg.Size = Vector2.new(220, 28)
    Watermark.drawings.bg.Position = Vector2.new(10, Camera.ViewportSize.Y - 38)
    Watermark.drawings.bg.Color = Color3.fromRGB(15, 15, 15)
    Watermark.drawings.bg.Filled = true
    Watermark.drawings.bg.Visible = true
    Watermark.drawings.bg.ZIndex = 100
    Watermark.drawings.bg.Transparency = 0.9
    
    Watermark.drawings.accent = Drawing.new("Square")
    Watermark.drawings.accent.Size = Vector2.new(220, 2)
    Watermark.drawings.accent.Position = Vector2.new(10, Camera.ViewportSize.Y - 38)
    Watermark.drawings.accent.Color = theme.accent
    Watermark.drawings.accent.Filled = true
    Watermark.drawings.accent.Visible = true
    Watermark.drawings.accent.ZIndex = 101
    Watermark.drawings.accent.Transparency = 1
    
    Watermark.drawings.outline = Drawing.new("Square")
    Watermark.drawings.outline.Size = Vector2.new(220, 28)
    Watermark.drawings.outline.Position = Vector2.new(10, Camera.ViewportSize.Y - 38)
    Watermark.drawings.outline.Color = Color3.fromRGB(60, 60, 60)
    Watermark.drawings.outline.Filled = false
    Watermark.drawings.outline.Thickness = 1
    Watermark.drawings.outline.Visible = true
    Watermark.drawings.outline.ZIndex = 102
    Watermark.drawings.outline.Transparency = 1
    
    Watermark.drawings.text = Drawing.new("Text")
    Watermark.drawings.text.Size = 14
    Watermark.drawings.text.Font = 2
    Watermark.drawings.text.Color = Color3.fromRGB(255, 255, 255)
    Watermark.drawings.text.Outline = true
    Watermark.drawings.text.OutlineColor = Color3.fromRGB(0, 0, 0)
    Watermark.drawings.text.Position = Vector2.new(18, Camera.ViewportSize.Y - 32)
    Watermark.drawings.text.Visible = true
    Watermark.drawings.text.ZIndex = 103
    Watermark.drawings.text.Transparency = 1
end

function Watermark.update()
    if not config.watermark.enabled then
        for _, drawing in pairs(Watermark.drawings) do drawing.Visible = false end
        return
    end
    for _, drawing in pairs(Watermark.drawings) do drawing.Visible = true end
    
    local parts = {"RIVALS"}
    
    if config.aimbot.enabled then
        table.insert(parts, config.aimbot.mode:upper())
    end
    
    if config.antiAim.enabled then
        table.insert(parts, "AA")
    end
    
    if config.watermark.showFps then table.insert(parts, "FPS: " .. math.floor(workspace:GetRealPhysicsFPS())) end
    if config.watermark.showPing then table.insert(parts, "PING: " .. math.floor(LocalPlayer:GetNetworkPing() * 1000) .. "ms") end
    if config.watermark.showTime then table.insert(parts, os.date("%H:%M:%S")) end
    
    Watermark.drawings.text.Text = table.concat(parts, " | ")
    local textBounds = Watermark.drawings.text.TextBounds
    if textBounds then
        local width = math.max(textBounds.X + 20, 150)
        local yPos = Camera.ViewportSize.Y - 38
        Watermark.drawings.bg.Size = Vector2.new(width, 28)
        Watermark.drawings.bg.Position = Vector2.new(10, yPos)
        Watermark.drawings.accent.Size = Vector2.new(width, 2)
        Watermark.drawings.accent.Position = Vector2.new(10, yPos)
        Watermark.drawings.outline.Size = Vector2.new(width, 28)
        Watermark.drawings.outline.Position = Vector2.new(10, yPos)
        Watermark.drawings.text.Position = Vector2.new(18, yPos + 6)
    end
    Watermark.drawings.accent.Color = theme.accent
end

Watermark.create()

local Crosshair = {}
Crosshair.drawings = {}

function Crosshair.create()
    Crosshair.drawings.dot = Drawing.new("Circle")
    Crosshair.drawings.dot.Filled = true
    Crosshair.drawings.dot.Visible = false
    Crosshair.drawings.dot.ZIndex = 99
    Crosshair.drawings.dot.Transparency = 1
    
    Crosshair.drawings.dotOutline = Drawing.new("Circle")
    Crosshair.drawings.dotOutline.Color = Color3.fromRGB(0, 0, 0)
    Crosshair.drawings.dotOutline.Filled = true
    Crosshair.drawings.dotOutline.Visible = false
    Crosshair.drawings.dotOutline.ZIndex = 98
    
    Crosshair.drawings.top = Drawing.new("Line")
    Crosshair.drawings.top.Visible = false
    Crosshair.drawings.top.ZIndex = 99
    Crosshair.drawings.topOutline = Drawing.new("Line")
    Crosshair.drawings.topOutline.Color = Color3.fromRGB(0, 0, 0)
    Crosshair.drawings.topOutline.Visible = false
    Crosshair.drawings.topOutline.ZIndex = 98
    
    Crosshair.drawings.bottom = Drawing.new("Line")
    Crosshair.drawings.bottom.Visible = false
    Crosshair.drawings.bottom.ZIndex = 99
    Crosshair.drawings.bottomOutline = Drawing.new("Line")
    Crosshair.drawings.bottomOutline.Color = Color3.fromRGB(0, 0, 0)
    Crosshair.drawings.bottomOutline.Visible = false
    Crosshair.drawings.bottomOutline.ZIndex = 98
    
    Crosshair.drawings.left = Drawing.new("Line")
    Crosshair.drawings.left.Visible = false
    Crosshair.drawings.left.ZIndex = 99
    Crosshair.drawings.leftOutline = Drawing.new("Line")
    Crosshair.drawings.leftOutline.Color = Color3.fromRGB(0, 0, 0)
    Crosshair.drawings.leftOutline.Visible = false
    Crosshair.drawings.leftOutline.ZIndex = 98
    
    Crosshair.drawings.right = Drawing.new("Line")
    Crosshair.drawings.right.Visible = false
    Crosshair.drawings.right.ZIndex = 99
    Crosshair.drawings.rightOutline = Drawing.new("Line")
    Crosshair.drawings.rightOutline.Color = Color3.fromRGB(0, 0, 0)
    Crosshair.drawings.rightOutline.Visible = false
    Crosshair.drawings.rightOutline.ZIndex = 98
end

function Crosshair.update()
    local cX, cY = Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2
    local size, gap, thick = config.crosshair.size, config.crosshair.gap, config.crosshair.thickness
    local color, outline, dot = config.crosshair.color, config.crosshair.outline, config.crosshair.dot
    
    for _, d in pairs(Crosshair.drawings) do d.Visible = false end
    if not config.crosshair.enabled then return end
    
    Crosshair.drawings.dot.Color = color
    Crosshair.drawings.top.Color = color
    Crosshair.drawings.bottom.Color = color
    Crosshair.drawings.left.Color = color
    Crosshair.drawings.right.Color = color
    
    Crosshair.drawings.top.Thickness = thick
    Crosshair.drawings.bottom.Thickness = thick
    Crosshair.drawings.left.Thickness = thick
    Crosshair.drawings.right.Thickness = thick
    Crosshair.drawings.topOutline.Thickness = thick + 2
    Crosshair.drawings.bottomOutline.Thickness = thick + 2
    Crosshair.drawings.leftOutline.Thickness = thick + 2
    Crosshair.drawings.rightOutline.Thickness = thick + 2
    
    Crosshair.drawings.top.From = Vector2.new(cX, cY - gap)
    Crosshair.drawings.top.To = Vector2.new(cX, cY - gap - size)
    Crosshair.drawings.top.Visible = true
    Crosshair.drawings.topOutline.From = Crosshair.drawings.top.From
    Crosshair.drawings.topOutline.To = Crosshair.drawings.top.To
    Crosshair.drawings.topOutline.Visible = outline
    
    Crosshair.drawings.bottom.From = Vector2.new(cX, cY + gap)
    Crosshair.drawings.bottom.To = Vector2.new(cX, cY + gap + size)
    Crosshair.drawings.bottom.Visible = true
    Crosshair.drawings.bottomOutline.From = Crosshair.drawings.bottom.From
    Crosshair.drawings.bottomOutline.To = Crosshair.drawings.bottom.To
    Crosshair.drawings.bottomOutline.Visible = outline
    
    Crosshair.drawings.left.From = Vector2.new(cX - gap, cY)
    Crosshair.drawings.left.To = Vector2.new(cX - gap - size, cY)
    Crosshair.drawings.left.Visible = true
    Crosshair.drawings.leftOutline.From = Crosshair.drawings.left.From
    Crosshair.drawings.leftOutline.To = Crosshair.drawings.left.To
    Crosshair.drawings.leftOutline.Visible = outline
    
    Crosshair.drawings.right.From = Vector2.new(cX + gap, cY)
    Crosshair.drawings.right.To = Vector2.new(cX + gap + size, cY)
    Crosshair.drawings.right.Visible = true
    Crosshair.drawings.rightOutline.From = Crosshair.drawings.right.From
    Crosshair.drawings.rightOutline.To = Crosshair.drawings.right.To
    Crosshair.drawings.rightOutline.Visible = outline
    
    if dot then
        Crosshair.drawings.dot.Position = Vector2.new(cX, cY)
        Crosshair.drawings.dot.Radius = thick
        Crosshair.drawings.dot.Visible = true
        Crosshair.drawings.dotOutline.Position = Vector2.new(cX, cY)
        Crosshair.drawings.dotOutline.Radius = thick + 1
        Crosshair.drawings.dotOutline.Visible = outline
    end
end

Crosshair.create()

local function findBodyPart(c, n) 
    if not c then return nil end
    if n == "Head" then return c:FindFirstChild("Head") 
    elseif n == "UpperTorso" then return c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso")
    elseif n == "LowerTorso" then return c:FindFirstChild("LowerTorso") or c:FindFirstChild("Torso")
    elseif n == "Torso" then return c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso") or c:FindFirstChild("HumanoidRootPart")
    elseif n == "HumanoidRootPart" then return c:FindFirstChild("HumanoidRootPart")
    elseif n == "Left Arm" then return c:FindFirstChild("LeftUpperArm") or c:FindFirstChild("Left Arm")
    elseif n == "Right Arm" then return c:FindFirstChild("RightUpperArm") or c:FindFirstChild("Right Arm")
    elseif n == "Left Leg" then return c:FindFirstChild("LeftUpperLeg") or c:FindFirstChild("Left Leg")
    elseif n == "Right Leg" then return c:FindFirstChild("RightUpperLeg") or c:FindFirstChild("Right Leg")
    end
    return c:FindFirstChild("Head") or c:FindFirstChild("HumanoidRootPart") 
end

local function getDistance(p1, p2) 
    if not p1 or not p2 then return math.huge end
    return (p1.Position - p2.Position).Magnitude 
end

local function getBoxBounds(character)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    
    local rootPos = hrp.Position
    local charHeight = 6
    
    local topPos = rootPos + Vector3.new(0, charHeight / 2 + 0.5, 0)
    local bottomPos = rootPos - Vector3.new(0, charHeight / 2 - 0.5, 0)
    
    local topScreen, topOnScreen = Camera:WorldToViewportPoint(topPos)
    local bottomScreen, bottomOnScreen = Camera:WorldToViewportPoint(bottomPos)
    
    if not topOnScreen and not bottomOnScreen then return nil end
    if topScreen.Z < 0 or bottomScreen.Z < 0 then return nil end
    
    local height = math.abs(bottomScreen.Y - topScreen.Y)
    local width = height * 0.6
    
    local centerX = (topScreen.X + bottomScreen.X) / 2
    local centerY = (topScreen.Y + bottomScreen.Y) / 2
    
    return {
        x = centerX - width / 2,
        y = topScreen.Y,
        width = width,
        height = height,
        centerX = centerX,
        centerY = centerY
    }
end

local function isTargetValid(player)
    if not player then return false end
    if not player.Character then return false end
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    
    local myChar = LocalPlayer.Character
    if myChar then
        local myHRP = myChar:FindFirstChild("HumanoidRootPart")
        local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
        if myHRP and targetHRP and getDistance(myHRP, targetHRP) / 3.5 > config.esp.maxDistance then
            return false
        end
    end
    return true
end

local function findTargetInFOV_Mouse(fovRadius, targetPartName)
    local myChar = LocalPlayer.Character
    if not myChar then return nil end
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end
    
    local mousePos = UIS:GetMouseLocation()
    local closest, minDist = nil, fovRadius + 1

    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer and pl.Character then
            local char = pl.Character
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            
            if humanoid and humanoid.Health > 0 then
                local targetPart = findBodyPart(char, targetPartName)
                if targetPart then
                    local distance = getDistance(myHRP, targetPart)
                    if distance <= config.esp.maxDistance * 3.5 then
                        local success, screenPos, onScreen = pcall(function() return Camera:WorldToViewportPoint(targetPart.Position) end)
                        if success and onScreen then
                            local distToMouse = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                            if distToMouse <= fovRadius and distToMouse < minDist then 
                                minDist = distToMouse
                                closest = pl
                            end
                        end
                    end
                end
            end
        end
    end
    return closest
end

local function findTargetInFOV_Center(fovRadius, targetPartName)
    local myChar = LocalPlayer.Character
    if not myChar then return nil end
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end
    
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local closest, minDist = nil, fovRadius + 1

    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer and pl.Character then
            local char = pl.Character
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            
            if humanoid and humanoid.Health > 0 then
                local targetPart = findBodyPart(char, targetPartName)
                if targetPart then
                    local distance = getDistance(myHRP, targetPart)
                    if distance <= config.esp.maxDistance * 3.5 then
                        local success, screenPos, onScreen = pcall(function() return Camera:WorldToViewportPoint(targetPart.Position) end)
                        if success and onScreen then
                            local distToCenter = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                            if distToCenter <= fovRadius and distToCenter < minDist then 
                                minDist = distToCenter
                                closest = pl
                            end
                        end
                    end
                end
            end
        end
    end
    return closest
end

local accumulatedX = 0
local accumulatedY = 0

local function executeLegitAim()
    if not config.aimbot.enabled or config.aimbot.mode ~= "Legit" then return end
    
    local shouldAim = isKeybindHeld(config.legitAim.aimKey)
    
    if not shouldAim then
        lockedTarget = nil
        currentTargetPart = nil
        isAiming = false
        accumulatedX = 0
        accumulatedY = 0
        return
    end
    
    isAiming = true
    
    if not lockedTarget or not isTargetValid(lockedTarget) then
        lockedTarget = findTargetInFOV_Mouse(config.legitAim.fovRadius, config.legitAim.targetPart)
        accumulatedX = 0
        accumulatedY = 0
    end
    
    if lockedTarget and isTargetValid(lockedTarget) then
        currentTargetPart = findBodyPart(lockedTarget.Character, config.legitAim.targetPart)
        
        if currentTargetPart and mousemoverel then
            local screenPos, onScreen = Camera:WorldToViewportPoint(currentTargetPart.Position)
            if onScreen then
                local mousePos = UIS:GetMouseLocation()
                local deltaX = screenPos.X - mousePos.X
                local deltaY = screenPos.Y - mousePos.Y
                
                local distance = math.sqrt(deltaX * deltaX + deltaY * deltaY)
                
                if distance < 2 then
                    return
                end
                
                local smooth = config.legitAim.smoothness
                if smooth <= 0 then smooth = 1 end
                
                local speed = math.clamp(distance / (smooth * 2), 0.5, distance * 0.5)
                
                if distance > 0 then
                    local moveX = (deltaX / distance) * speed
                    local moveY = (deltaY / distance) * speed
                    
                    accumulatedX = accumulatedX + moveX
                    accumulatedY = accumulatedY + moveY
                    
                    local finalX = math.floor(accumulatedX)
                    local finalY = math.floor(accumulatedY)
                    
                    if finalX ~= 0 or finalY ~= 0 then
                        mousemoverel(finalX, finalY)
                        accumulatedX = accumulatedX - finalX
                        accumulatedY = accumulatedY - finalY
                    end
                end
            end
        end
    else
        lockedTarget = nil
        currentTargetPart = nil
    end
end

local function executeRageAim()
    if not config.aimbot.enabled or config.aimbot.mode ~= "Rage" then return end
    
    local shouldAim = isKeybindHeld(config.rageAim.aimKey)
    
    if not shouldAim then
        lockedTarget = nil
        currentTargetPart = nil
        isAiming = false
        return
    end
    
    isAiming = true
    
    if not lockedTarget or not isTargetValid(lockedTarget) then
        lockedTarget = findTargetInFOV_Center(config.rageAim.fovRadius, config.rageAim.targetPart)
    end
    
    if lockedTarget and isTargetValid(lockedTarget) then
        currentTargetPart = findBodyPart(lockedTarget.Character, config.rageAim.targetPart)
        
        if currentTargetPart then
            pcall(function() Camera.CFrame = CFrame.new(Camera.CFrame.Position, currentTargetPart.Position) end)
        end
    else
        lockedTarget = nil
        currentTargetPart = nil
    end
end

local lastTime = tick()

RunService.RenderStepped:Connect(function() 
    pcall(executeLegitAim)
    pcall(executeRageAim)
end)

RunService.Heartbeat:Connect(function()
    local currentTime = tick()
    local dt = currentTime - lastTime
    lastTime = currentTime
    
    pcall(function() updateAntiAim(dt) end)
    pcall(updateFly)
    pcall(updateNoclip)
end)

RunService.Stepped:Connect(function()
    if config.other.noclip or config.other.fly then
        pcall(updateNoclip)
    end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    noclipParts = {}
    originalC0 = nil
    if config.other.fly then
        startFly()
    end
    if config.other.noclip then
        enableNoclip()
    end
end)

local espMap = {}

local function cleanupPlayer(p) 
    local uid = p.UserId
    local e = espMap[uid]
    if not e then return end
    if e.highlight then pcall(function() if e.highlight.Parent then e.highlight:Destroy() end end) end
    if e.box then pcall(function() e.box:Remove() end) end
    if e.boxOutline then pcall(function() e.boxOutline:Remove() end) end
    if e.healthBarBg then pcall(function() e.healthBarBg:Remove() end) end
    if e.healthBar then pcall(function() e.healthBar:Remove() end) end
    if e.healthBarOutline then pcall(function() e.healthBarOutline:Remove() end) end
    if e.nameTag then pcall(function() e.nameTag:Remove() end) end
    if e.conn then pcall(function() e.conn:Disconnect() end) end
    espMap[uid] = nil 
end

local function createEspFor(player)
    if player == LocalPlayer then return end
    if not player.Character then return end
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    local uid = player.UserId
    if espMap[uid] then cleanupPlayer(player) end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "Rivals_ESP"
    highlight.FillColor = config.esp.enemyColor
    highlight.OutlineColor = config.esp.enemyColor
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Enabled = config.esp.chamsEnabled
    highlight.Parent = player.Character
    
    local boxOutline = Drawing.new("Square")
    boxOutline.Color = Color3.fromRGB(0, 0, 0)
    boxOutline.Filled = false
    boxOutline.Thickness = 3
    boxOutline.Visible = false
    boxOutline.ZIndex = 9
    boxOutline.Transparency = 1
    
    local box = Drawing.new("Square")
    box.Color = config.esp.enemyColor
    box.Filled = false
    box.Thickness = 1
    box.Visible = false
    box.ZIndex = 10
    box.Transparency = 1
    
    local healthBarOutline = Drawing.new("Square")
    healthBarOutline.Color = Color3.fromRGB(0, 0, 0)
    healthBarOutline.Filled = true
    healthBarOutline.Visible = false
    healthBarOutline.ZIndex = 10
    healthBarOutline.Transparency = 1
    
    local healthBarBg = Drawing.new("Square")
    healthBarBg.Color = Color3.fromRGB(30, 30, 30)
    healthBarBg.Filled = true
    healthBarBg.Visible = false
    healthBarBg.ZIndex = 11
    healthBarBg.Transparency = 1
    
    local healthBar = Drawing.new("Square")
    healthBar.Color = Color3.fromRGB(0, 255, 0)
    healthBar.Filled = true
    healthBar.Visible = false
    healthBar.ZIndex = 12
    healthBar.Transparency = 1
    
    local nameTag = Drawing.new("Text")
    nameTag.Size = 13
    nameTag.Font = 2
    nameTag.Color = Color3.fromRGB(255, 255, 255)
    nameTag.Outline = true
    nameTag.OutlineColor = Color3.fromRGB(0, 0, 0)
    nameTag.Center = true
    nameTag.Visible = false
    nameTag.ZIndex = 13
    nameTag.Transparency = 1
    nameTag.Text = player.DisplayName or player.Name
    
    espMap[uid] = {
        highlight = highlight, 
        humanoid = humanoid,
        box = box,
        boxOutline = boxOutline,
        healthBarBg = healthBarBg,
        healthBar = healthBar,
        healthBarOutline = healthBarOutline,
        nameTag = nameTag
    }
    
    local conn = player.Character.AncestryChanged:Connect(function(_, parent) 
        if not parent then cleanupPlayer(player) end 
    end)
    espMap[uid].conn = conn
end

local function updateEspFor(player)
    if not config.esp.enabled then return end
    if player == LocalPlayer then return end
    
    local uid = player.UserId
    local entry = espMap[uid]
    
    if not entry or not entry.highlight or not entry.highlight.Parent then
        createEspFor(player)
        entry = espMap[uid]
        if not entry then return end
    end
    
    local highlight = entry.highlight
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    entry.humanoid = humanoid
    
    local box = entry.box
    local boxOutline = entry.boxOutline
    local healthBarBg = entry.healthBarBg
    local healthBar = entry.healthBar
    local healthBarOutline = entry.healthBarOutline
    local nameTag = entry.nameTag
    
    local myChar = LocalPlayer.Character
    local shouldShow = true
    local isDead = humanoid.Health <= 0
    
    if myChar then
        local myHRP = myChar:FindFirstChild("HumanoidRootPart")
        local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
        if myHRP and targetHRP and getDistance(myHRP, targetHRP) / 3.5 > config.esp.maxDistance then
            shouldShow = false
        end
    end
    
    if isDead then shouldShow = false end
    
    local isCurrentTarget = (lockedTarget == player) and (not isDead) and isAiming
    local color = isCurrentTarget and config.esp.targetColor or config.esp.enemyColor
    
    pcall(function() 
        highlight.Enabled = config.esp.chamsEnabled and shouldShow
        highlight.FillColor = color
        highlight.OutlineColor = color 
    end)
    
    local bounds = shouldShow and getBoxBounds(player.Character) or nil
    
    if bounds and (config.esp.boxEnabled or config.esp.healthBarEnabled) then
        if config.esp.boxEnabled then
            box.Position = Vector2.new(bounds.x, bounds.y)
            box.Size = Vector2.new(bounds.width, bounds.height)
            box.Color = color
            box.Visible = true
            
            boxOutline.Position = Vector2.new(bounds.x, bounds.y)
            boxOutline.Size = Vector2.new(bounds.width, bounds.height)
            boxOutline.Visible = true
        else
            box.Visible = false
            boxOutline.Visible = false
        end
        
        if config.esp.healthBarEnabled then
            local health = humanoid.Health
            local maxHealth = humanoid.MaxHealth
            local healthPercent = math.clamp(health / maxHealth, 0, 1)
            
            local barWidth = 4
            local barX = bounds.x - barWidth - 3
            local barY = bounds.y
            local barHeight = bounds.height
            
            local healthHeight = barHeight * healthPercent
            
            healthBarOutline.Position = Vector2.new(barX - 1, barY - 1)
            healthBarOutline.Size = Vector2.new(barWidth + 2, barHeight + 2)
            healthBarOutline.Visible = true
            
            healthBarBg.Position = Vector2.new(barX, barY)
            healthBarBg.Size = Vector2.new(barWidth, barHeight)
            healthBarBg.Visible = true
            
            healthBar.Position = Vector2.new(barX, barY + (barHeight - healthHeight))
            healthBar.Size = Vector2.new(barWidth, math.max(healthHeight, 1))
            healthBar.Visible = true
            
            if healthPercent > 0.6 then
                healthBar.Color = Color3.fromRGB(0, 255, 0)
            elseif healthPercent > 0.3 then
                healthBar.Color = Color3.fromRGB(255, 255, 0)
            else
                healthBar.Color = Color3.fromRGB(255, 0, 0)
            end
        else
            healthBarOutline.Visible = false
            healthBarBg.Visible = false
            healthBar.Visible = false
        end
        
        nameTag.Position = Vector2.new(bounds.centerX, bounds.y - 15)
        nameTag.Text = player.DisplayName or player.Name
        nameTag.Visible = config.esp.boxEnabled
    else
        box.Visible = false
        boxOutline.Visible = false
        healthBarOutline.Visible = false
        healthBarBg.Visible = false
        healthBar.Visible = false
        nameTag.Visible = false
    end
end

local function setEspActive(on)
    config.esp.enabled = on
    if not on then 
        for _, p in ipairs(Players:GetPlayers()) do cleanupPlayer(p) end
        return 
    end
    for _, p in ipairs(Players:GetPlayers()) do 
        if p ~= LocalPlayer and p.Character then createEspFor(p) end 
    end
end

RunService.RenderStepped:Connect(function()
    pcall(Watermark.update)
    pcall(Crosshair.update)
    if config.esp.enabled then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then pcall(updateEspFor, player) end
        end
    end
end)

Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(function(c) task.wait(0.5); if config.esp.enabled and c.Parent then createEspFor(p) end end) end)
Players.PlayerRemoving:Connect(function(p) cleanupPlayer(p) end)
for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then p.CharacterAdded:Connect(function(c) task.wait(0.5); if config.esp.enabled and c.Parent then createEspFor(p) end end) end end

library.__index = library
pages.__index = pages
sections.__index = sections

function library:New(info)
    info = info or {}
    local name = info.name or "Ulycheat - Rivals"
    local size = info.size or Vector2.new(504,680)
    theme.accent = info.accent or theme.accent
    
    local window = {pages = {}, isVisible = false, currentPage = nil, fading = false, dragging = false, drag = Vector2.new(0,0)}
    
    local main_frame = utility:Create("Frame", {Vector2.new(0,0)}, {Size = utility:Size(0, size.X, 0, size.Y), Position = utility:Position(0.5, -(size.X/2), 0.5, -(size.Y/2)), Color = theme.outline}); window["main_frame"] = main_frame
    local frame_inline = utility:Create("Frame", {Vector2.new(1,1), main_frame}, {Size = utility:Size(1, -2, 1, -2, main_frame), Position = utility:Position(0, 1, 0, 1, main_frame), Color = theme.accent})
    local inner_frame = utility:Create("Frame", {Vector2.new(1,1), frame_inline}, {Size = utility:Size(1, -2, 1, -2, frame_inline), Position = utility:Position(0, 1, 0, 1, frame_inline), Color = theme.light_contrast})
    utility:Create("TextLabel", {Vector2.new(4,2), inner_frame}, {Text = name, Size = theme.textsize, Font = theme.font, Color = theme.textcolor, OutlineColor = theme.textborder, Position = utility:Position(0, 4, 0, 2, inner_frame)})
    local inner_frame_inline = utility:Create("Frame", {Vector2.new(4,18), inner_frame}, {Size = utility:Size(1, -8, 1, -22, inner_frame), Position = utility:Position(0, 4, 0, 18, inner_frame), Color = theme.inline})
    local inner_frame_inline2 = utility:Create("Frame", {Vector2.new(1,1), inner_frame_inline}, {Size = utility:Size(1, -2, 1, -2, inner_frame_inline), Position = utility:Position(0, 1, 0, 1, inner_frame_inline), Color = theme.outline})
    local back_frame = utility:Create("Frame", {Vector2.new(1,1), inner_frame_inline2}, {Size = utility:Size(1, -2, 1, -2, inner_frame_inline2), Position = utility:Position(0, 1, 0, 1, inner_frame_inline2), Color = theme.dark_contrast}); window["back_frame"] = back_frame
    local tab_frame_inline = utility:Create("Frame", {Vector2.new(4,24), back_frame}, {Size = utility:Size(1, -8, 1, -28, back_frame), Position = utility:Position(0, 4, 0, 24, back_frame), Color = theme.outline})
    local tab_frame_inline2 = utility:Create("Frame", {Vector2.new(1,1), tab_frame_inline}, {Size = utility:Size(1, -2, 1, -2, tab_frame_inline), Position = utility:Position(0, 1, 0, 1, tab_frame_inline), Color = theme.inline})
    local tab_frame = utility:Create("Frame", {Vector2.new(1,1), tab_frame_inline2}, {Size = utility:Size(1, -2, 1, -2, tab_frame_inline2), Position = utility:Position(0, 1, 0, 1, tab_frame_inline2), Color = theme.light_contrast}); window["tab_frame"] = tab_frame
    
    function window:Move(v) for _,d in pairs(library.drawings) do pcall(function() if d[2][2] then d[1].Position = utility:Position(0, d[2][1].X, 0, d[2][1].Y, d[2][2]) else d[1].Position = utility:Position(0, v.X, 0, v.Y) end end) end end
    
    function window:Cursor()
        window.cursor = {}
        local cursor_bg = utility:Create("Triangle", nil, {Color = Color3.fromRGB(0,0,0), Filled = true, ZIndex = 64, Hidden = true})
        local cursor_inline = utility:Create("Triangle", nil, {Color = theme.accent, Filled = true, ZIndex = 66, Hidden = true})
        window.cursor["cursor_bg"] = cursor_bg
        window.cursor["cursor_inline"] = cursor_inline
        utility:Connection(RunService.RenderStepped, function()
            pcall(function()
                local m = utility:MouseLocation()
                safeSet(cursor_bg, "PointA", Vector2.new(m.X+1, m.Y+1)); safeSet(cursor_bg, "PointB", Vector2.new(m.X+21, m.Y+9)); safeSet(cursor_bg, "PointC", Vector2.new(m.X+9, m.Y+21))
                safeSet(cursor_inline, "PointA", Vector2.new(m.X, m.Y)); safeSet(cursor_inline, "PointB", Vector2.new(m.X+20, m.Y+8)); safeSet(cursor_inline, "PointC", Vector2.new(m.X+8, m.Y+20))
                if window.isVisible then safeSet(cursor_bg, "Transparency", 0.8); safeSet(cursor_inline, "Transparency", 0.9) else safeSet(cursor_bg, "Transparency", 0); safeSet(cursor_inline, "Transparency", 0) end
            end)
        end)
        UIS.MouseIconEnabled = false
    end
    
    function window:Fade() if window.fading then return end; window.fading = true; task.spawn(function() window.isVisible = not window.isVisible; for _, v in pairs(library.drawings) do pcall(function() v[1].Transparency = window.isVisible and v[3] or 0 end) end; UIS.MouseIconEnabled = not window.isVisible; task.wait(0.1); window.fading = false end) end
    function window:Initialize() if #window.pages > 0 then window.pages[1]:Show() end; for _,v in pairs(window.pages) do v:Update() end; library.shared.initialized = true; window:Cursor(); window.isVisible = false; for _, v in pairs(library.drawings) do pcall(function() v[1].Transparency = 0 end) end; UIS.MouseIconEnabled = true; task.spawn(function() task.wait(0.5); window:Fade() end) end
    
    library.began[#library.began + 1] = function(I) if I.UserInputType == Enum.UserInputType.MouseButton1 and window.isVisible and utility:MouseOverDrawing({main_frame.Position.X, main_frame.Position.Y, main_frame.Position.X + main_frame.Size.X, main_frame.Position.Y + 20}) then window.dragging = true; window.drag = Vector2.new(utility:MouseLocation().X - main_frame.Position.X, utility:MouseLocation().Y - main_frame.Position.Y) end end
    library.ended[#library.ended + 1] = function(I) if I.UserInputType == Enum.UserInputType.MouseButton1 and window.dragging then window.dragging = false end end
    library.changed[#library.changed + 1] = function() if window.dragging and window.isVisible then local m = utility:MouseLocation(); window:Move(Vector2.new(math.clamp(m.X - window.drag.X, 5, utility:GetScreenSize().X - main_frame.Size.X - 5), math.clamp(m.Y - window.drag.Y, 5, utility:GetScreenSize().Y - main_frame.Size.Y - 5))) end end
    
    utility:Connection(UIS.InputBegan, function(I) for _, f in pairs(library.began) do if not window.dragging then pcall(f, I) end end end)
    utility:Connection(UIS.InputEnded, function(I) for _, f in pairs(library.ended) do pcall(f, I) end end)
    utility:Connection(UIS.InputChanged, function() for _, f in pairs(library.changed) do pcall(f) end end)
    
    return setmetatable(window, library)
end

function library:Page(info)
    info = info or {}
    local name = info.name or "Page"
    local window = self
    local page = {open = false, sections = {}, sectionOffset = {left = 0, right = 0}, window = window}
    local position = 4; for _,v in pairs(window.pages) do position = position + (v.page_button.Size.X + 2) end
    local textbounds = utility:GetTextBounds(name, theme.textsize, theme.font)
    local page_button = utility:Create("Frame", {Vector2.new(position, 4), window.back_frame}, {Size = utility:Size(0, textbounds.X + 20, 0, 21), Position = utility:Position(0, position, 0, 4, window.back_frame), Color = theme.outline}); page["page_button"] = page_button
    local page_button_inline = utility:Create("Frame", {Vector2.new(1,1), page_button}, {Size = utility:Size(1, -2, 1, -1, page_button), Position = utility:Position(0, 1, 0, 1, page_button), Color = theme.inline}); page["page_button_inline"] = page_button_inline
    local page_button_color = utility:Create("Frame", {Vector2.new(1,1), page_button_inline}, {Size = utility:Size(1, -2, 1, -1, page_button_inline), Position = utility:Position(0, 1, 0, 1, page_button_inline), Color = theme.dark_contrast}); page["page_button_color"] = page_button_color
    utility:Create("TextLabel", {Vector2.new(utility:Position(0.5, 0, 0, 2, page_button_color).X - page_button_color.Position.X, 2), page_button_color}, {Text = name, Size = theme.textsize, Font = theme.font, Color = theme.textcolor, Center = true, OutlineColor = theme.textborder, Position = utility:Position(0.5, 0, 0, 2, page_button_color)})
    window.pages[#window.pages + 1] = page
    function page:Update() page.sectionOffset["left"] = 0; page.sectionOffset["right"] = 0; for _,v in pairs(page.sections) do utility:UpdateOffset(v.section_inline, {Vector2.new(v.side == "right" and (window.tab_frame.Size.X/2)+2 or 5, 5 + page["sectionOffset"][v.side]), window.tab_frame}); page.sectionOffset[v.side] = page.sectionOffset[v.side] + v.section_inline.Size.Y + 5 end; window:Move(window.main_frame.Position) end
    function page:Show() if window.currentPage then window.currentPage.page_button_color.Size = utility:Size(1, -2, 1, -1, window.currentPage.page_button_inline); window.currentPage.page_button_color.Color = theme.dark_contrast; window.currentPage.open = false; for _,v in pairs(window.currentPage.sections) do for _,x in pairs(v.visibleContent) do pcall(function() x.Visible = false end) end end end; window.currentPage = page; page_button_color.Size = utility:Size(1, -2, 1, 0, page_button_inline); page_button_color.Color = theme.light_contrast; page.open = true; for _,v in pairs(page.sections) do for _,x in pairs(v.visibleContent) do pcall(function() x.Visible = true end) end end end
    library.began[#library.began + 1] = function(I) if I.UserInputType == Enum.UserInputType.MouseButton1 and window.isVisible and utility:MouseOverDrawing({page_button.Position.X, page_button.Position.Y, page_button.Position.X + page_button.Size.X, page_button.Position.Y + page_button.Size.Y}) and window.currentPage ~= page then page:Show() end end
    return setmetatable(page, pages)
end

function pages:Section(info)
    info = info or {}
    local name = info.name or "Section"
    local side = (info.side or "left"):lower()
    local window = self.window
    local page = self
    local section = {window = window, page = page, visibleContent = {}, currentAxis = 20, side = side}
    local section_inline = utility:Create("Frame", {Vector2.new(side == "right" and (window.tab_frame.Size.X/2)+2 or 5, 5 + page["sectionOffset"][side]), window.tab_frame}, {Size = utility:Size(0.5, -7, 0, 22, window.tab_frame), Position = utility:Position(side == "right" and 0.5 or 0, side == "right" and 2 or 5, 0, 5 + page.sectionOffset[side], window.tab_frame), Color = theme.inline, Visible = page.open}, section.visibleContent); section["section_inline"] = section_inline
    local section_outline = utility:Create("Frame", {Vector2.new(1,1), section_inline}, {Size = utility:Size(1, -2, 1, -2, section_inline), Position = utility:Position(0, 1, 0, 1, section_inline), Color = theme.outline, Visible = page.open}, section.visibleContent)
    local section_frame = utility:Create("Frame", {Vector2.new(1,1), section_outline}, {Size = utility:Size(1, -2, 1, -2, section_outline), Position = utility:Position(0, 1, 0, 1, section_outline), Color = theme.dark_contrast, Visible = page.open}, section.visibleContent); section["section_frame"] = section_frame
    utility:Create("Frame", {Vector2.new(0,0), section_frame}, {Size = utility:Size(1, 0, 0, 2, section_frame), Position = utility:Position(0, 0, 0, 0, section_frame), Color = theme.accent, Visible = page.open}, section.visibleContent)
    utility:Create("TextLabel", {Vector2.new(3,3), section_frame}, {Text = name, Size = theme.textsize, Font = theme.font, Color = theme.textcolor, OutlineColor = theme.textborder, Position = utility:Position(0, 3, 0, 3, section_frame), Visible = page.open}, section.visibleContent)
    function section:Update() pcall(function() section_inline.Size = utility:Size(0.5, -7, 0, section.currentAxis + 4, window.tab_frame) end) end
    page.sectionOffset[side] = page.sectionOffset[side] + 100 + 5
    page.sections[#page.sections + 1] = section
    return setmetatable(section, sections)
end

function sections:Toggle(info)
    info = info or {}
    local name = info.name or "Toggle"
    local def = info.def or false
    local callback = info.callback or function() end
    local window, page, section = self.window, self.page, self
    local toggle = {axis = section.currentAxis, current = def}
    local toggle_outline = utility:Create("Frame", {Vector2.new(4, toggle.axis), section.section_frame}, {Size = utility:Size(0, 15, 0, 15), Position = utility:Position(0, 4, 0, toggle.axis, section.section_frame), Color = theme.outline, Visible = page.open}, section.visibleContent)
    local toggle_inline = utility:Create("Frame", {Vector2.new(1,1), toggle_outline}, {Size = utility:Size(1, -2, 1, -2, toggle_outline), Position = utility:Position(0, 1, 0, 1, toggle_outline), Color = theme.inline, Visible = page.open}, section.visibleContent)
    local toggle_frame = utility:Create("Frame", {Vector2.new(1,1), toggle_inline}, {Size = utility:Size(1, -2, 1, -2, toggle_inline), Position = utility:Position(0, 1, 0, 1, toggle_inline), Color = toggle.current and theme.accent or theme.light_contrast, Visible = page.open}, section.visibleContent)
    utility:Create("TextLabel", {Vector2.new(23, toggle.axis + 2), section.section_frame}, {Text = name, Size = theme.textsize, Font = theme.font, Color = theme.textcolor, OutlineColor = theme.textborder, Position = utility:Position(0, 23, 0, toggle.axis + 2, section.section_frame), Visible = page.open}, section.visibleContent)
    function toggle:Set(b) toggle.current = b; pcall(function() toggle_frame.Color = toggle.current and theme.accent or theme.light_contrast end); callback(toggle.current) end
    library.began[#library.began + 1] = function(I) if I.UserInputType == Enum.UserInputType.MouseButton1 and toggle_outline.Visible and window.isVisible and page.open and utility:MouseOverDrawing({section.section_frame.Position.X, section.section_frame.Position.Y + toggle.axis, section.section_frame.Position.X + section.section_frame.Size.X, section.section_frame.Position.Y + toggle.axis + 15}) then toggle:Set(not toggle.current) end end
    section.currentAxis = section.currentAxis + 19; section:Update()
    return toggle
end

function sections:Button(info)
    info = info or {}
    local name = info.name or "Button"
    local callback = info.callback or function() end
    local window, page, section = self.window, self.page, self
    local button = {axis = section.currentAxis}
    local button_outline = utility:Create("Frame", {Vector2.new(4, button.axis), section.section_frame}, {Size = utility:Size(1, -8, 0, 20, section.section_frame), Position = utility:Position(0, 4, 0, button.axis, section.section_frame), Color = theme.outline, Visible = page.open}, section.visibleContent)
    local button_inline = utility:Create("Frame", {Vector2.new(1,1), button_outline}, {Size = utility:Size(1, -2, 1, -2, button_outline), Position = utility:Position(0, 1, 0, 1, button_outline), Color = theme.inline, Visible = page.open}, section.visibleContent)
    local button_frame = utility:Create("Frame", {Vector2.new(1,1), button_inline}, {Size = utility:Size(1, -2, 1, -2, button_inline), Position = utility:Position(0, 1, 0, 1, button_inline), Color = theme.light_contrast, Visible = page.open}, section.visibleContent)
    utility:Create("TextLabel", {Vector2.new(button_frame.Size.X/2, 3), button_frame}, {Text = name, Size = theme.textsize, Font = theme.font, Color = theme.textcolor, Center = true, OutlineColor = theme.textborder, Position = utility:Position(0.5, 0, 0, 3, button_frame), Visible = page.open}, section.visibleContent)
    library.began[#library.began + 1] = function(I) if I.UserInputType == Enum.UserInputType.MouseButton1 and button_outline.Visible and window.isVisible and page.open and utility:MouseOverDrawing({button_outline.Position.X, button_outline.Position.Y, button_outline.Position.X + button_outline.Size.X, button_outline.Position.Y + button_outline.Size.Y}) then pcall(function() button_frame.Color = theme.accent end); task.spawn(function() task.wait(0.1); pcall(function() button_frame.Color = theme.light_contrast end) end); callback() end end
    section.currentAxis = section.currentAxis + 24; section:Update()
    return button
end

function sections:Slider(info)
    info = info or {}
    local name = info.name or "Slider"
    local def = math.clamp(info.def or 50, info.min or 0, info.max or 100)
    local min, max = info.min or 0, info.max or 100
    local suffix = info.suffix or ""
    local decimals = info.decimals or 0
    local callback = info.callback or function() end
    local window, page, section = self.window, self.page, self
    local slider = {axis = section.currentAxis, current = def, holding = false}
    utility:Create("TextLabel", {Vector2.new(4, slider.axis), section.section_frame}, {Text = name, Size = theme.textsize, Font = theme.font, Color = theme.textcolor, OutlineColor = theme.textborder, Position = utility:Position(0, 4, 0, slider.axis, section.section_frame), Visible = page.open}, section.visibleContent)
    local slider_outline = utility:Create("Frame", {Vector2.new(4, slider.axis + 15), section.section_frame}, {Size = utility:Size(1, -8, 0, 12, section.section_frame), Position = utility:Position(0, 4, 0, slider.axis + 15, section.section_frame), Color = theme.outline, Visible = page.open}, section.visibleContent)
    local slider_inline = utility:Create("Frame", {Vector2.new(1,1), slider_outline}, {Size = utility:Size(1, -2, 1, -2, slider_outline), Position = utility:Position(0, 1, 0, 1, slider_outline), Color = theme.inline, Visible = page.open}, section.visibleContent)
    local slider_frame = utility:Create("Frame", {Vector2.new(1,1), slider_inline}, {Size = utility:Size(1, -2, 1, -2, slider_inline), Position = utility:Position(0, 1, 0, 1, slider_inline), Color = theme.light_contrast, Visible = page.open}, section.visibleContent)
    local slider_slide = utility:Create("Frame", {Vector2.new(1,1), slider_inline}, {Size = utility:Size(0, 0, 1, -2, slider_inline), Position = utility:Position(0, 1, 0, 1, slider_inline), Color = theme.accent, Visible = page.open}, section.visibleContent)
    local slider_value = utility:Create("TextLabel", {Vector2.new(slider_outline.Size.X/2, 0), slider_outline}, {Text = def..suffix.."/"..max..suffix, Size = theme.textsize, Font = theme.font, Color = theme.textcolor, Center = true, OutlineColor = theme.textborder, Position = utility:Position(0.5, 0, 0, 0, slider_outline), Visible = page.open}, section.visibleContent)
    function slider:Set(v) local mult = 10 ^ decimals; slider.current = math.clamp(math.floor(v * mult + 0.5) / mult, min, max); local displayValue = decimals > 0 and string.format("%." .. decimals .. "f", slider.current) or tostring(math.floor(slider.current)); local displayMax = decimals > 0 and string.format("%." .. decimals .. "f", max) or tostring(max); pcall(function() slider_value.Text = displayValue..suffix.."/"..displayMax..suffix; slider_slide.Size = utility:Size(0, ((slider.current - min) / (max - min)) * slider_frame.Size.X, 1, -2, slider_inline) end); callback(slider.current) end
    function slider:Refresh() slider:Set(min + (max - min) * math.clamp((utility:MouseLocation().X - slider_slide.Position.X) / slider_frame.Size.X, 0, 1)) end
    slider:Set(def)
    library.began[#library.began + 1] = function(I) if I.UserInputType == Enum.UserInputType.MouseButton1 and slider_outline.Visible and window.isVisible and page.open and utility:MouseOverDrawing({section.section_frame.Position.X, section.section_frame.Position.Y + slider.axis, section.section_frame.Position.X + section.section_frame.Size.X, section.section_frame.Position.Y + slider.axis + 27}) then slider.holding = true; slider:Refresh() end end
    library.ended[#library.ended + 1] = function(I) if I.UserInputType == Enum.UserInputType.MouseButton1 then slider.holding = false end end
    library.changed[#library.changed + 1] = function() if slider.holding and window.isVisible then slider:Refresh() end end
    section.currentAxis = section.currentAxis + 31; section:Update()
    return slider
end

function sections:Dropdown(info)
    info = info or {}
    local name = info.name or "Dropdown"
    local options = info.options or {"Option 1"}
    local def = info.def or options[1]
    local callback = info.callback or function() end
    local window, page, section = self.window, self.page, self
    local dropdown = {axis = section.currentAxis, current = def, currentIndex = 1}
    for i, v in ipairs(options) do if v == def then dropdown.currentIndex = i break end end
    utility:Create("TextLabel", {Vector2.new(4, dropdown.axis), section.section_frame}, {Text = name, Size = theme.textsize, Font = theme.font, Color = theme.textcolor, OutlineColor = theme.textborder, Position = utility:Position(0, 4, 0, dropdown.axis, section.section_frame), Visible = page.open}, section.visibleContent)
    local dropdown_outline = utility:Create("Frame", {Vector2.new(4, dropdown.axis + 15), section.section_frame}, {Size = utility:Size(1, -8, 0, 18, section.section_frame), Position = utility:Position(0, 4, 0, dropdown.axis + 15, section.section_frame), Color = theme.outline, Visible = page.open}, section.visibleContent)
    local dropdown_inline = utility:Create("Frame", {Vector2.new(1,1), dropdown_outline}, {Size = utility:Size(1, -2, 1, -2, dropdown_outline), Position = utility:Position(0, 1, 0, 1, dropdown_outline), Color = theme.inline, Visible = page.open}, section.visibleContent)
    local dropdown_frame = utility:Create("Frame", {Vector2.new(1,1), dropdown_inline}, {Size = utility:Size(1, -2, 1, -2, dropdown_inline), Position = utility:Position(0, 1, 0, 1, dropdown_inline), Color = theme.light_contrast, Visible = page.open}, section.visibleContent)
    local dropdown_value = utility:Create("TextLabel", {Vector2.new(4, 2), dropdown_frame}, {Text = def, Size = theme.textsize, Font = theme.font, Color = theme.textcolor, OutlineColor = theme.textborder, Position = utility:Position(0, 4, 0, 2, dropdown_frame), Visible = page.open}, section.visibleContent)
    function dropdown:Set(opt) dropdown.current = opt; for i, v in ipairs(options) do if v == opt then dropdown.currentIndex = i break end end; pcall(function() dropdown_value.Text = opt end); callback(opt) end
    function dropdown:Next() dropdown.currentIndex = dropdown.currentIndex + 1; if dropdown.currentIndex > #options then dropdown.currentIndex = 1 end; dropdown:Set(options[dropdown.currentIndex]) end
    library.began[#library.began + 1] = function(I) if I.UserInputType == Enum.UserInputType.MouseButton1 and dropdown_outline.Visible and window.isVisible and page.open and utility:MouseOverDrawing({dropdown_outline.Position.X, dropdown_outline.Position.Y, dropdown_outline.Position.X + dropdown_outline.Size.X, dropdown_outline.Position.Y + dropdown_outline.Size.Y}) then dropdown:Next() end end
    section.currentAxis = section.currentAxis + 37; section:Update()
    return dropdown
end

function sections:Keybind(info)
    info = info or {}
    local name = info.name or "Keybind"
    local def = info.def or createKeybind(Enum.KeyCode.C)
    local callback = info.callback or function() end
    local window, page, section = self.window, self.page, self
    local keybind = {axis = section.currentAxis, current = def, waiting = false}
    
    utility:Create("TextLabel", {Vector2.new(4, keybind.axis), section.section_frame}, {Text = name, Size = theme.textsize, Font = theme.font, Color = theme.textcolor, OutlineColor = theme.textborder, Position = utility:Position(0, 4, 0, keybind.axis, section.section_frame), Visible = page.open}, section.visibleContent)
    
    local keybind_outline = utility:Create("Frame", {Vector2.new(4, keybind.axis + 15), section.section_frame}, {Size = utility:Size(1, -8, 0, 18, section.section_frame), Position = utility:Position(0, 4, 0, keybind.axis + 15, section.section_frame), Color = theme.outline, Visible = page.open}, section.visibleContent)
    local keybind_inline = utility:Create("Frame", {Vector2.new(1,1), keybind_outline}, {Size = utility:Size(1, -2, 1, -2, keybind_outline), Position = utility:Position(0, 1, 0, 1, keybind_outline), Color = theme.inline, Visible = page.open}, section.visibleContent)
    local keybind_frame = utility:Create("Frame", {Vector2.new(1,1), keybind_inline}, {Size = utility:Size(1, -2, 1, -2, keybind_inline), Position = utility:Position(0, 1, 0, 1, keybind_inline), Color = theme.light_contrast, Visible = page.open}, section.visibleContent)
    local keybind_value = utility:Create("TextLabel", {Vector2.new(4, 2), keybind_frame}, {Text = "[ " .. getKeybindName(def) .. " ]", Size = theme.textsize, Font = theme.font, Color = theme.textcolor, OutlineColor = theme.textborder, Position = utility:Position(0, 4, 0, 2, keybind_frame), Visible = page.open}, section.visibleContent)
    
    function keybind:Set(inputType)
        local newKeybind = createKeybind(inputType)
        keybind.current = newKeybind
        keybind.waiting = false
        waitingForKeybind = nil
        pcall(function() 
            keybind_value.Text = "[ " .. getKeybindName(newKeybind) .. " ]"
            keybind_frame.Color = theme.light_contrast
        end)
        callback(newKeybind)
    end
    
    function keybind:StartWaiting()
        keybind.waiting = true
        waitingForKeybind = keybind
        keybindWaitStartTime = tick()
        pcall(function() 
            keybind_value.Text = "[ ... ]"
            keybind_frame.Color = theme.accent
        end)
    end
    
    function keybind:CancelWaiting()
        keybind.waiting = false
        waitingForKeybind = nil
        pcall(function() 
            keybind_value.Text = "[ " .. getKeybindName(keybind.current) .. " ]"
            keybind_frame.Color = theme.light_contrast
        end)
    end
    
    library.began[#library.began + 1] = function(I) 
        if keybind_outline.Visible and window.isVisible and page.open and utility:MouseOverDrawing({keybind_outline.Position.X, keybind_outline.Position.Y, keybind_outline.Position.X + keybind_outline.Size.X, keybind_outline.Position.Y + keybind_outline.Size.Y}) then 
            if I.UserInputType == Enum.UserInputType.MouseButton1 then
                if not keybind.waiting then
                    keybind:StartWaiting()
                end
            end
        end 
    end
    
    section.currentAxis = section.currentAxis + 37; section:Update()
    return keybind
end

function sections:ColorPicker(info)
    info = info or {}
    local name = info.name or "Color"
    local def = info.def or Color3.fromRGB(255, 255, 255)
    local callback = info.callback or function() end
    local window, page, section = self.window, self.page, self
    local colorpicker = {axis = section.currentAxis, r = math.floor(def.R * 255), g = math.floor(def.G * 255), b = math.floor(def.B * 255)}
    utility:Create("TextLabel", {Vector2.new(4, colorpicker.axis), section.section_frame}, {Text = name, Size = theme.textsize, Font = theme.font, Color = theme.textcolor, OutlineColor = theme.textborder, Position = utility:Position(0, 4, 0, colorpicker.axis, section.section_frame), Visible = page.open}, section.visibleContent)
    local preview_outline = utility:Create("Frame", {Vector2.new(4, colorpicker.axis + 15), section.section_frame}, {Size = utility:Size(0, 25, 0, 25), Position = utility:Position(0, 4, 0, colorpicker.axis + 15, section.section_frame), Color = theme.outline, Visible = page.open}, section.visibleContent)
    local preview = utility:Create("Frame", {Vector2.new(1,1), preview_outline}, {Size = utility:Size(1, -2, 1, -2, preview_outline), Position = utility:Position(0, 1, 0, 1, preview_outline), Color = def, Visible = page.open}, section.visibleContent)
    local r_outline = utility:Create("Frame", {Vector2.new(35, colorpicker.axis + 15), section.section_frame}, {Size = utility:Size(1, -43, 0, 7, section.section_frame), Position = utility:Position(0, 35, 0, colorpicker.axis + 15, section.section_frame), Color = theme.outline, Visible = page.open}, section.visibleContent)
    local r_inline = utility:Create("Frame", {Vector2.new(1,1), r_outline}, {Size = utility:Size(1, -2, 1, -2, r_outline), Position = utility:Position(0, 1, 0, 1, r_outline), Color = theme.inline, Visible = page.open}, section.visibleContent)
    local r_frame = utility:Create("Frame", {Vector2.new(1,1), r_inline}, {Size = utility:Size(1, -2, 1, -2, r_inline), Position = utility:Position(0, 1, 0, 1, r_inline), Color = Color3.fromRGB(50,50,50), Visible = page.open}, section.visibleContent)
    local r_slide = utility:Create("Frame", {Vector2.new(1,1), r_inline}, {Size = utility:Size(0, (colorpicker.r/255) * r_frame.Size.X, 1, -2, r_inline), Position = utility:Position(0, 1, 0, 1, r_inline), Color = Color3.fromRGB(255, 80, 80), Visible = page.open}, section.visibleContent)
    local g_outline = utility:Create("Frame", {Vector2.new(35, colorpicker.axis + 24), section.section_frame}, {Size = utility:Size(1, -43, 0, 7, section.section_frame), Position = utility:Position(0, 35, 0, colorpicker.axis + 24, section.section_frame), Color = theme.outline, Visible = page.open}, section.visibleContent)
    local g_inline = utility:Create("Frame", {Vector2.new(1,1), g_outline}, {Size = utility:Size(1, -2, 1, -2, g_outline), Position = utility:Position(0, 1, 0, 1, g_outline), Color = theme.inline, Visible = page.open}, section.visibleContent)
    local g_frame = utility:Create("Frame", {Vector2.new(1,1), g_inline}, {Size = utility:Size(1, -2, 1, -2, g_inline), Position = utility:Position(0, 1, 0, 1, g_inline), Color = Color3.fromRGB(50,50,50), Visible = page.open}, section.visibleContent)
    local g_slide = utility:Create("Frame", {Vector2.new(1,1), g_inline}, {Size = utility:Size(0, (colorpicker.g/255) * g_frame.Size.X, 1, -2, g_inline), Position = utility:Position(0, 1, 0, 1, g_inline), Color = Color3.fromRGB(80, 255, 80), Visible = page.open}, section.visibleContent)
    local b_outline = utility:Create("Frame", {Vector2.new(35, colorpicker.axis + 33), section.section_frame}, {Size = utility:Size(1, -43, 0, 7, section.section_frame), Position = utility:Position(0, 35, 0, colorpicker.axis + 33, section.section_frame), Color = theme.outline, Visible = page.open}, section.visibleContent)
    local b_inline = utility:Create("Frame", {Vector2.new(1,1), b_outline}, {Size = utility:Size(1, -2, 1, -2, b_outline), Position = utility:Position(0, 1, 0, 1, b_outline), Color = theme.inline, Visible = page.open}, section.visibleContent)
    local b_frame = utility:Create("Frame", {Vector2.new(1,1), b_inline}, {Size = utility:Size(1, -2, 1, -2, b_inline), Position = utility:Position(0, 1, 0, 1, b_inline), Color = Color3.fromRGB(50,50,50), Visible = page.open}, section.visibleContent)
    local b_slide = utility:Create("Frame", {Vector2.new(1,1), b_inline}, {Size = utility:Size(0, (colorpicker.b/255) * b_frame.Size.X, 1, -2, b_inline), Position = utility:Position(0, 1, 0, 1, b_inline), Color = Color3.fromRGB(80, 80, 255), Visible = page.open}, section.visibleContent)
    local r_holding, g_holding, b_holding = false, false, false
    function colorpicker:UpdateColor() local newColor = Color3.fromRGB(colorpicker.r, colorpicker.g, colorpicker.b); pcall(function() preview.Color = newColor end); callback(newColor) end
    function colorpicker:UpdateR() local m = utility:MouseLocation(); local percent = math.clamp((m.X - r_slide.Position.X) / r_frame.Size.X, 0, 1); colorpicker.r = math.floor(percent * 255); pcall(function() r_slide.Size = utility:Size(0, percent * r_frame.Size.X, 1, -2, r_inline) end); colorpicker:UpdateColor() end
    function colorpicker:UpdateG() local m = utility:MouseLocation(); local percent = math.clamp((m.X - g_slide.Position.X) / g_frame.Size.X, 0, 1); colorpicker.g = math.floor(percent * 255); pcall(function() g_slide.Size = utility:Size(0, percent * g_frame.Size.X, 1, -2, g_inline) end); colorpicker:UpdateColor() end
    function colorpicker:UpdateB() local m = utility:MouseLocation(); local percent = math.clamp((m.X - b_slide.Position.X) / b_frame.Size.X, 0, 1); colorpicker.b = math.floor(percent * 255); pcall(function() b_slide.Size = utility:Size(0, percent * b_frame.Size.X, 1, -2, b_inline) end); colorpicker:UpdateColor() end
    library.began[#library.began + 1] = function(I) if I.UserInputType == Enum.UserInputType.MouseButton1 and window.isVisible and page.open then if r_outline.Visible and utility:MouseOverDrawing({r_outline.Position.X, r_outline.Position.Y, r_outline.Position.X + r_outline.Size.X, r_outline.Position.Y + r_outline.Size.Y}) then r_holding = true; colorpicker:UpdateR() elseif g_outline.Visible and utility:MouseOverDrawing({g_outline.Position.X, g_outline.Position.Y, g_outline.Position.X + g_outline.Size.X, g_outline.Position.Y + g_outline.Size.Y}) then g_holding = true; colorpicker:UpdateG() elseif b_outline.Visible and utility:MouseOverDrawing({b_outline.Position.X, b_outline.Position.Y, b_outline.Position.X + b_outline.Size.X, b_outline.Position.Y + b_outline.Size.Y}) then b_holding = true; colorpicker:UpdateB() end end end
    library.ended[#library.ended + 1] = function(I) if I.UserInputType == Enum.UserInputType.MouseButton1 then r_holding = false; g_holding = false; b_holding = false end end
    library.changed[#library.changed + 1] = function() if window.isVisible then if r_holding then colorpicker:UpdateR() end; if g_holding then colorpicker:UpdateG() end; if b_holding then colorpicker:UpdateB() end end end
    section.currentAxis = section.currentAxis + 45; section:Update()
    return colorpicker
end

function sections:Label(info)
    info = info or {}
    local text = info.text or "Label"
    local window, page, section = self.window, self.page, self
    local label = {axis = section.currentAxis}
    local label_text = utility:Create("TextLabel", {Vector2.new(4, label.axis), section.section_frame}, {Text = text, Size = theme.textsize, Font = theme.font, Color = theme.textcolor, OutlineColor = theme.textborder, Position = utility:Position(0, 4, 0, label.axis, section.section_frame), Visible = page.open}, section.visibleContent)
    function label:SetText(t) pcall(function() label_text.Text = t end) end
    section.currentAxis = section.currentAxis + 16; section:Update()
    return label
end

if not Drawing then warn("Drawing non disponible!"); return end

local lib = library:New({name = "UlyCheat - Rivals"})
local mainWindow = lib

local legit_page = lib:Page({name = "Legit"})
local rage_page = lib:Page({name = "Rage"})
local visuals_page = lib:Page({name = "Visuals"})
local other_page = lib:Page({name = "Other"})
local config_page = lib:Page({name = "Config"})
local misc_page = lib:Page({name = "Misc"})

local legit_main = legit_page:Section({name = "Legit Aim"})
local legit_keybinds = legit_page:Section({name = "Keybinds", side = "right"})

local rage_main = rage_page:Section({name = "Rage Aim"})
local rage_keybinds = rage_page:Section({name = "Keybinds", side = "right"})

local visuals_esp = visuals_page:Section({name = "ESP"})
local visuals_colors = visuals_page:Section({name = "Colors", side = "right"})

local other_antiaim = other_page:Section({name = "Anti-Aim"})
local other_fly = other_page:Section({name = "Fly / Noclip", side = "right"})

local config_main = config_page:Section({name = "Config Manager"})
local config_settings = config_page:Section({name = "Menu Settings", side = "right"})

local misc_crosshair = misc_page:Section({name = "Crosshair"})
local misc_watermark = misc_page:Section({name = "Watermark", side = "right"})

local legitFovCircle = Drawing.new("Circle")
legitFovCircle.Visible = false
legitFovCircle.Thickness = 2
legitFovCircle.NumSides = 64
legitFovCircle.Filled = false
legitFovCircle.Transparency = 0.5
legitFovCircle.ZIndex = 5

local rageFovCircle = Drawing.new("Circle")
rageFovCircle.Visible = false
rageFovCircle.Thickness = 2
rageFovCircle.NumSides = 64
rageFovCircle.Filled = false
rageFovCircle.Transparency = 0.5
rageFovCircle.ZIndex = 5

RunService.RenderStepped:Connect(function()
    pcall(function()
        local mousePos = UIS:GetMouseLocation()
        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        
        legitFovCircle.Position = mousePos
        legitFovCircle.Radius = config.legitAim.fovRadius
        legitFovCircle.Color = config.legitAim.fovColor
        legitFovCircle.Visible = config.aimbot.enabled and config.aimbot.mode == "Legit" and config.legitAim.showFov
        
        rageFovCircle.Position = center
        rageFovCircle.Radius = config.rageAim.fovRadius
        rageFovCircle.Color = config.rageAim.fovColor
        rageFovCircle.Visible = config.aimbot.enabled and config.aimbot.mode == "Rage" and config.rageAim.showFov
    end)
end)

local bodyParts = {"Head", "UpperTorso", "LowerTorso", "HumanoidRootPart", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}

legit_main:Toggle({name = "Enable Aimbot", def = config.aimbot.enabled, callback = function(v) config.aimbot.enabled = v; config.aimbot.mode = "Legit" end})
legit_main:Toggle({name = "Show FOV", def = config.legitAim.showFov, callback = function(v) config.legitAim.showFov = v end})
legit_main:Slider({name = "FOV Radius", min = 50, max = 400, def = config.legitAim.fovRadius, callback = function(v) config.legitAim.fovRadius = v end})
legit_main:Dropdown({name = "Target Part", options = bodyParts, def = config.legitAim.targetPart, callback = function(v) config.legitAim.targetPart = v end})
legit_main:Slider({name = "Smoothness", min = 1, max = 50, def = config.legitAim.smoothness, callback = function(v) config.legitAim.smoothness = v end})
legit_main:ColorPicker({name = "FOV Color", def = config.legitAim.fovColor, callback = function(c) config.legitAim.fovColor = c end})

legit_keybinds:Label({text = "1. Click on keybind box"})
legit_keybinds:Label({text = "2. Press any key or mouse"})
legit_keybinds:Keybind({name = "Aim Key (Hold)", def = config.legitAim.aimKey, callback = function(key) config.legitAim.aimKey = key end})
legit_keybinds:Keybind({name = "Toggle Aimbot", def = config.legitAim.toggleKey, callback = function(key) config.legitAim.toggleKey = key end})
legit_keybinds:Label({text = ""})
legit_keybinds:Label({text = "Mouse1/2/3 supported!"})

rage_main:Toggle({name = "Enable Aimbot", def = config.aimbot.enabled, callback = function(v) config.aimbot.enabled = v; config.aimbot.mode = "Rage" end})
rage_main:Toggle({name = "Show FOV", def = config.rageAim.showFov, callback = function(v) config.rageAim.showFov = v end})
rage_main:Slider({name = "FOV Radius", min = 100, max = 600, def = config.rageAim.fovRadius, callback = function(v) config.rageAim.fovRadius = v end})
rage_main:Dropdown({name = "Target Part", options = bodyParts, def = config.rageAim.targetPart, callback = function(v) config.rageAim.targetPart = v end})
rage_main:ColorPicker({name = "FOV Color", def = config.rageAim.fovColor, callback = function(c) config.rageAim.fovColor = c end})

rage_keybinds:Label({text = "1. Click on keybind box"})
rage_keybinds:Label({text = "2. Press any key or mouse"})
rage_keybinds:Keybind({name = "Aim Key (Hold)", def = config.rageAim.aimKey, callback = function(key) config.rageAim.aimKey = key end})
rage_keybinds:Keybind({name = "Toggle Aimbot", def = config.rageAim.toggleKey, callback = function(key) config.rageAim.toggleKey = key end})
rage_keybinds:Label({text = ""})
rage_keybinds:Label({text = "Mouse1/2/3 supported!"})

visuals_esp:Toggle({name = "Enable ESP", def = config.esp.enabled, callback = function(v) setEspActive(v) end})
visuals_esp:Toggle({name = "Chams", def = config.esp.chamsEnabled, callback = function(v) config.esp.chamsEnabled = v end})
visuals_esp:Toggle({name = "Box ESP", def = config.esp.boxEnabled, callback = function(v) config.esp.boxEnabled = v end})
visuals_esp:Toggle({name = "Health Bar", def = config.esp.healthBarEnabled, callback = function(v) config.esp.healthBarEnabled = v end})
visuals_esp:Slider({name = "Max Distance", min = 10, max = 1000, def = config.esp.maxDistance, suffix = "m", callback = function(v) config.esp.maxDistance = v end})
visuals_colors:ColorPicker({name = "Enemy Color", def = config.esp.enemyColor, callback = function(c) config.esp.enemyColor = c end})
visuals_colors:ColorPicker({name = "Target Color", def = config.esp.targetColor, callback = function(c) config.esp.targetColor = c end})

other_antiaim:Toggle({name = "Enable Anti-Aim", def = config.antiAim.enabled, callback = function(v) config.antiAim.enabled = v; if not v then stopAntiAim() end end})
other_antiaim:Dropdown({name = "Mode", options = {"Spin", "Jitter", "Random"}, def = config.antiAim.mode, callback = function(v) config.antiAim.mode = v end})
other_antiaim:Slider({name = "Spin Speed", min = 5, max = 50, def = config.antiAim.spinSpeed, callback = function(v) config.antiAim.spinSpeed = v end})
other_antiaim:Toggle({name = "Head Spin", def = config.antiAim.headEnabled, callback = function(v) config.antiAim.headEnabled = v end})
other_antiaim:Slider({name = "Head Speed", min = 5, max = 50, def = config.antiAim.headSpeed, callback = function(v) config.antiAim.headSpeed = v end})
other_antiaim:Toggle({name = "Only When Still", def = config.antiAim.onlyWhenStill, callback = function(v) config.antiAim.onlyWhenStill = v end})

other_fly:Toggle({name = "Fly", def = config.other.fly, callback = function(v) config.other.fly = v; if v then startFly() else stopFly() end end})
other_fly:Slider({name = "Fly Speed", min = 10, max = 200, def = config.other.flySpeed, callback = function(v) config.other.flySpeed = v end})
other_fly:Toggle({name = "Noclip", def = config.other.noclip, callback = function(v) config.other.noclip = v; if v then enableNoclip() elseif not config.other.fly then disableNoclip() end end})

local currentConfigLabel = config_main:Label({text = "Current: " .. currentConfigName})
local configNames = {"default", "legit", "rage", "hvh", "closet", "blatant", "config1", "config2", "config3"}

config_main:Dropdown({
    name = "Config Name", 
    options = configNames, 
    def = "default", 
    callback = function(v) 
        currentConfigName = v 
        currentConfigLabel:SetText("Current: " .. currentConfigName)
    end
})

config_main:Button({name = "Save Config", callback = function()
    ConfigSystem.save(currentConfigName)
    currentConfigLabel:SetText("Saved: " .. currentConfigName)
    task.spawn(function() task.wait(2); currentConfigLabel:SetText("Current: " .. currentConfigName) end)
end})

config_main:Button({name = "Load Config", callback = function()
    if ConfigSystem.load(currentConfigName) then
        currentConfigLabel:SetText("Loaded: " .. currentConfigName)
    else
        currentConfigLabel:SetText("Error loading!")
    end
    task.spawn(function() task.wait(2); currentConfigLabel:SetText("Current: " .. currentConfigName) end)
end})

config_main:Button({name = "Export to Clipboard", callback = function()
    ConfigSystem.export(currentConfigName)
    currentConfigLabel:SetText("Exported!")
    task.spawn(function() task.wait(2); currentConfigLabel:SetText("Current: " .. currentConfigName) end)
end})

config_main:Button({name = "Delete Config", callback = function()
    ConfigSystem.delete(currentConfigName)
    currentConfigLabel:SetText("Deleted!")
    task.spawn(function() task.wait(2); currentConfigLabel:SetText("Current: " .. currentConfigName) end)
end})

config_main:Toggle({name = "Auto-Save", def = config.configSystem.autoSave, callback = function(v) config.configSystem.autoSave = v end})

config_settings:Label({text = "Menu Keybind"})
config_settings:Keybind({name = "Menu Key", def = config.menu.menuKey, callback = function(key) config.menu.menuKey = key end})
config_settings:Label({text = ""})
config_settings:Label({text = "Keybinds are saved!"})
config_settings:Label({text = "in config files"})

misc_crosshair:Toggle({name = "Enable Crosshair", def = config.crosshair.enabled, callback = function(v) config.crosshair.enabled = v end})
misc_crosshair:Toggle({name = "Outline", def = config.crosshair.outline, callback = function(v) config.crosshair.outline = v end})
misc_crosshair:Toggle({name = "Center Dot", def = config.crosshair.dot, callback = function(v) config.crosshair.dot = v end})
misc_crosshair:Slider({name = "Size", min = 3, max = 30, def = config.crosshair.size, callback = function(v) config.crosshair.size = v end})
misc_crosshair:Slider({name = "Gap", min = 0, max = 20, def = config.crosshair.gap, callback = function(v) config.crosshair.gap = v end})
misc_crosshair:Slider({name = "Thickness", min = 1, max = 5, def = config.crosshair.thickness, callback = function(v) config.crosshair.thickness = v end})
misc_crosshair:ColorPicker({name = "Color", def = config.crosshair.color, callback = function(c) config.crosshair.color = c end})

misc_watermark:Toggle({name = "Enable Watermark", def = config.watermark.enabled, callback = function(v) config.watermark.enabled = v end})
misc_watermark:Toggle({name = "Show FPS", def = config.watermark.showFps, callback = function(v) config.watermark.showFps = v end})
misc_watermark:Toggle({name = "Show Ping", def = config.watermark.showPing, callback = function(v) config.watermark.showPing = v end})
misc_watermark:Toggle({name = "Show Time", def = config.watermark.showTime, callback = function(v) config.watermark.showTime = v end})

UIS.InputBegan:Connect(function(input, gameProcessed)
    if waitingForKeybind then
        if tick() - keybindWaitStartTime < 0.15 then
            return
        end
        
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.MouseButton2 or
           input.UserInputType == Enum.UserInputType.MouseButton3 then
            waitingForKeybind:Set(input.UserInputType)
            return
        elseif input.KeyCode ~= Enum.KeyCode.Unknown then
            if input.KeyCode == Enum.KeyCode.Escape then
                waitingForKeybind:CancelWaiting()
                return
            end
            waitingForKeybind:Set(input.KeyCode)
            return
        end
    end
    
    if gameProcessed then return end
    
    if isKeybindPressed(config.legitAim.toggleKey, input) then
        config.aimbot.enabled = not config.aimbot.enabled
        config.aimbot.mode = "Legit"
        if not config.aimbot.enabled then
            lockedTarget = nil
            currentTargetPart = nil
            isAiming = false
        end
    end
    
    if isKeybindPressed(config.rageAim.toggleKey, input) then
        config.aimbot.enabled = not config.aimbot.enabled
        config.aimbot.mode = "Rage"
        if not config.aimbot.enabled then
            lockedTarget = nil
            currentTargetPart = nil
            isAiming = false
        end
    end
    
    if isKeybindPressed(config.menu.menuKey, input) then
        mainWindow:Fade()
    end
end)

lib:Initialize()