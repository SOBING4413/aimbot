--! Services
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local SobingService = game:GetService("SobingService")

--! UI Settings
local UISettings = {
    TabWidth = 160,
    Size = { 560, 440 },
    Theme = "Dark",
    Transparency = true,
    MinimizeKey = "RightShift",
    RenderingMode = "RenderStepped"
}

--! Colors Handler
local ColorsHandler = {}

function ColorsHandler:Pack(Colour)
    if typeof(Colour) == "Color3" then
        return { R = Colour.R * 255, G = Colour.G * 255, B = Colour.B * 255 }
    elseif typeof(Colour) == "table" then
        return Colour
    end
    return { R = 255, G = 255, B = 255 }
end

function ColorsHandler:Unpack(Colour)
    if typeof(Colour) == "table" then
        return Color3.fromRGB(Colour.R, Colour.G, Colour.B)
    elseif typeof(Colour) == "Color3" then
        return Colour
    end
    return Color3.fromRGB(255, 255, 255)
end

--! Configuration
local Configuration = {}

-- Aimbot
Configuration.Aimbot = false
Configuration.OnePressAimingMode = false
Configuration.AimKey = "RMB"
Configuration.AimMode = "Camera"
Configuration.SilentAimMethods = { "Mouse.Hit / Mouse.Target", "GetMouseLocation" }
Configuration.SilentAimChance = 100
Configuration.AimPartDropdownValues = { "Head", "HumanoidRootPart" }
Configuration.AimPart = "HumanoidRootPart"

Configuration.UseOffset = false
Configuration.OffsetType = "Static"
Configuration.StaticOffsetIncrement = 10
Configuration.DynamicOffsetIncrement = 10

Configuration.UseSensitivity = false
Configuration.Sensitivity = 50

-- Checks
Configuration.AliveCheck = false
Configuration.TeamCheck = false
Configuration.WallCheck = false
Configuration.WaterCheck = false
Configuration.FoVCheck = false
Configuration.FoVRadius = 100
Configuration.MagnitudeCheck = false
Configuration.TriggerMagnitude = 500
Configuration.TransparencyCheck = false
Configuration.IgnoredTransparency = 0.5

-- Visuals
Configuration.FoV = false
Configuration.FoVKey = "R"
Configuration.FoVThickness = 2
Configuration.FoVOpacity = 0.8
Configuration.FoVFilled = false
Configuration.FoVColour = Color3.fromRGB(0, 255, 100)

Configuration.SmartESP = false
Configuration.ESPKey = "T"
Configuration.ESPBox = false
Configuration.ESPBoxFilled = false
Configuration.NameESP = false
Configuration.NameESPFont = "Monospace"
Configuration.NameESPSize = 16
Configuration.NameESPOutlineColour = Color3.fromRGB(0, 0, 0)
Configuration.HealthESP = false
Configuration.MagnitudeESP = false
Configuration.TracerESP = false
Configuration.ESPThickness = 2
Configuration.ESPOpacity = 0.8
Configuration.ESPColour = Color3.fromRGB(0, 255, 100)
Configuration.ESPUseTeamColour = false

--! Constants
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local IsComputer = UserInputService.KeyboardEnabled and UserInputService.MouseEnabled

--! Fields
local Fluent = nil

local RobloxActive = true
local Aiming = false
local Target = nil
local Sobing = nil
local MouseSensitivity = UserInputService.MouseDeltaSensitivity

local ShowingFoV = false
local ShowingESP = false

--! Load Fluent UI
do
    if typeof(script) == "Instance" and script:FindFirstChild("Fluent") and script:FindFirstChild("Fluent"):IsA("ModuleScript") then
        Fluent = require(script:FindFirstChild("Fluent"))
    else
        local Success, Result = pcall(function()
            return game:HttpGet("https://raw.githubusercontent.com/SOBING4413/aimbot/refs/heads/main/dependescis/fluent.txt", true)
        end)
        if Success and typeof(Result) == "string" and string.find(Result, "dawid") then
            Fluent = getfenv().loadstring(Result)()
            if Fluent.Premium then
                return getfenv().loadstring(game:HttpGet("https://raw.githubusercontent.com/SOBING4413/aimbot/refs/heads/main/dependescis/aimbot.txt", true))()
            end
        else
            return
        end
    end
end

local SensitivityChanged
SensitivityChanged = UserInputService:GetPropertyChangedSignal("MouseDeltaSensitivity"):Connect(function()
    if not Fluent then
        SensitivityChanged:Disconnect()
    elseif not Aiming or (getfenv().mousemoverel and IsComputer and Configuration.AimMode == "Mouse") or (getfenv().hookmetamethod and getfenv().newcclosure and getfenv().checkcaller and getfenv().getnamecallmethod and Configuration.AimMode == "Silent") then
        MouseSensitivity = UserInputService.MouseDeltaSensitivity
    end
end)

--! UI Builder
do
    local Window = Fluent:CreateWindow({
        Title = "⚡ <b><i>Open Aimbot</i></b>",
        SubTitle = "Clean Edition",
        TabWidth = UISettings.TabWidth,
        Size = UDim2.fromOffset(table.unpack(UISettings.Size)),
        Theme = UISettings.Theme,
        Acrylic = false,
        MinimizeKey = UISettings.MinimizeKey
    })

    local Tabs = {
        Aimbot = Window:AddTab({ Title = "Aimbot", Icon = "crosshair" })
    }

    Window:SelectTab(1)

    Tabs.Aimbot:AddParagraph({
        Title = "⚡ Open Aimbot - Clean Edition",
        Content = "Universal Aim Assist Framework\nDibersihkan & Disederhanakan"
    })

    local AimbotSection = Tabs.Aimbot:AddSection("Aimbot")

    local AimbotToggle = AimbotSection:AddToggle("Aimbot", {
        Title = "Aimbot",
        Description = "Aktifkan/Nonaktifkan Aimbot",
        Default = Configuration.Aimbot
    })
    AimbotToggle:OnChanged(function(Value)
        Configuration.Aimbot = Value
        if not IsComputer then
            Aiming = Value
        end
    end)

    if IsComputer then
        local OnePressToggle = AimbotSection:AddToggle("OnePressAimingMode", {
            Title = "One-Press Mode",
            Description = "Tekan sekali untuk aktif, tekan lagi untuk nonaktif",
            Default = Configuration.OnePressAimingMode
        })
        OnePressToggle:OnChanged(function(Value)
            Configuration.OnePressAimingMode = Value
        end)

        local AimKeybind = AimbotSection:AddKeybind("AimKey", {
            Title = "Aim Key",
            Description = "Tombol untuk mengaktifkan aim",
            Default = Configuration.AimKey,
            ChangedCallback = function(Value)
                Configuration.AimKey = Value
            end
        })
        Configuration.AimKey = AimKeybind.Value ~= "RMB" and Enum.KeyCode[AimKeybind.Value] or Enum.UserInputType.MouseButton2
    end

    local AimModeDropdown = AimbotSection:AddDropdown("AimMode", {
        Title = "Aim Mode",
        Description = "Pilih mode aim",
        Values = { "Camera" },
        Default = Configuration.AimMode,
        Callback = function(Value)
            Configuration.AimMode = Value
        end
    })

    if getfenv().mousemoverel and IsComputer then
        table.insert(AimModeDropdown.Values, "Mouse")
        AimModeDropdown:BuildDropdownList()
    end

    if getfenv().hookmetamethod and getfenv().newcclosure and getfenv().checkcaller and getfenv().getnamecallmethod then
        table.insert(AimModeDropdown.Values, "Silent")
        AimModeDropdown:BuildDropdownList()

        AimbotSection:AddDropdown("SilentAimMethods", {
            Title = "Silent Aim Methods",
            Description = "Metode Silent Aim yang digunakan",
            Values = { "Mouse.Hit / Mouse.Target", "GetMouseLocation", "Raycast", "FindPartOnRay", "FindPartOnRayWithIgnoreList", "FindPartOnRayWithWhitelist" },
            Multi = true,
            Default = Configuration.SilentAimMethods
        }):OnChanged(function(Value)
            Configuration.SilentAimMethods = {}
            for Key, _ in next, Value do
                if typeof(Key) == "string" then
                    table.insert(Configuration.SilentAimMethods, Key)
                end
            end
        end)

        AimbotSection:AddSlider("SilentAimChance", {
            Title = "Silent Aim Chance",
            Description = "Persentase akurasi Silent Aim",
            Default = Configuration.SilentAimChance,
            Min = 1, Max = 100, Rounding = 1,
            Callback = function(Value)
                Configuration.SilentAimChance = Value
            end
        })
    end

    local AimPartDropdown = AimbotSection:AddDropdown("AimPart", {
        Title = "Aim Part",
        Description = "Bagian tubuh target",
        Values = Configuration.AimPartDropdownValues,
        Default = Configuration.AimPart,
        Callback = function(Value)
            Configuration.AimPart = Value
        end
    })

    AimbotSection:AddInput("AddAimPart", {
        Title = "Tambah Aim Part",
        Description = "Ketik lalu tekan Enter",
        Finished = true,
        Placeholder = "Nama Part",
        Callback = function(Value)
            if #Value > 0 and not table.find(Configuration.AimPartDropdownValues, Value) then
                table.insert(Configuration.AimPartDropdownValues, Value)
                AimPartDropdown:SetValue(Value)
            end
        end
    })

    -- Aim Offset Section
    local OffsetSection = Tabs.Aimbot:AddSection("Aim Offset")

    local UseOffsetToggle = OffsetSection:AddToggle("UseOffset", {
        Title = "Use Offset",
        Description = "Aktifkan offset aim",
        Default = Configuration.UseOffset
    })
    UseOffsetToggle:OnChanged(function(Value)
        Configuration.UseOffset = Value
    end)

    OffsetSection:AddDropdown("OffsetType", {
        Title = "Offset Type",
        Description = "Tipe offset",
        Values = { "Static", "Dynamic", "Static & Dynamic" },
        Default = Configuration.OffsetType,
        Callback = function(Value)
            Configuration.OffsetType = Value
        end
    })

    OffsetSection:AddSlider("StaticOffsetIncrement", {
        Title = "Static Offset",
        Description = "Nilai static offset",
        Default = Configuration.StaticOffsetIncrement,
        Min = 1, Max = 50, Rounding = 1,
        Callback = function(Value)
            Configuration.StaticOffsetIncrement = Value
        end
    })

    OffsetSection:AddSlider("DynamicOffsetIncrement", {
        Title = "Dynamic Offset",
        Description = "Nilai dynamic offset",
        Default = Configuration.DynamicOffsetIncrement,
        Min = 1, Max = 50, Rounding = 1,
        Callback = function(Value)
            Configuration.DynamicOffsetIncrement = Value
        end
    })

    -- Sensitivity Section
    local SensSection = Tabs.Aimbot:AddSection("Sensitivity")

    local UseSensToggle = SensSection:AddToggle("UseSensitivity", {
        Title = "Use Sensitivity",
        Description = "Aktifkan smoothing pada aim",
        Default = Configuration.UseSensitivity
    })
    UseSensToggle:OnChanged(function(Value)
        Configuration.UseSensitivity = Value
    end)

    SensSection:AddSlider("Sensitivity", {
        Title = "Sensitivity",
        Description = "Kelancaran gerakan mouse/kamera saat aiming",
        Default = Configuration.Sensitivity,
        Min = 1, Max = 100, Rounding = 1,
        Callback = function(Value)
            Configuration.Sensitivity = Value
        end
    })

    -- ═══════════════════════════════════════
    -- TAB 2: CHECKS
    -- ═══════════════════════════════════════
    Tabs.Checks = Window:AddTab({ Title = "Checks", Icon = "list-checks" })

    Tabs.Checks:AddParagraph({
        Title = "⚡ Pengaturan Checks",
        Content = "Filter target berdasarkan kondisi tertentu"
    })

    local SimpleChecks = Tabs.Checks:AddSection("Basic Checks")

    local function AddCheckToggle(section, key, title, desc)
        local toggle = section:AddToggle(key, {
            Title = title,
            Description = desc,
            Default = Configuration[key]
        })
        toggle:OnChanged(function(Value)
            Configuration[key] = Value
        end)
        return toggle
    end

    AddCheckToggle(SimpleChecks, "AliveCheck", "Alive Check", "Hanya target yang masih hidup")
    AddCheckToggle(SimpleChecks, "TeamCheck", "Team Check", "Abaikan anggota tim sendiri")
    AddCheckToggle(SimpleChecks, "WallCheck", "Wall Check", "Cek apakah target terhalang dinding")
    AddCheckToggle(SimpleChecks, "WaterCheck", "Water Check", "Cek air jika Wall Check aktif")

    local AdvChecks = Tabs.Checks:AddSection("Advanced Checks")

    AddCheckToggle(AdvChecks, "FoVCheck", "FoV Check", "Hanya target dalam radius FoV")

    AdvChecks:AddSlider("FoVRadius", {
        Title = "FoV Radius",
        Description = "Radius Field of View",
        Default = Configuration.FoVRadius,
        Min = 10, Max = 1000, Rounding = 1,
        Callback = function(Value)
            Configuration.FoVRadius = Value
        end
    })

    AddCheckToggle(AdvChecks, "MagnitudeCheck", "Magnitude Check", "Cek jarak ke target")

    AdvChecks:AddSlider("TriggerMagnitude", {
        Title = "Max Distance",
        Description = "Jarak maksimum ke target",
        Default = Configuration.TriggerMagnitude,
        Min = 10, Max = 1000, Rounding = 1,
        Callback = function(Value)
            Configuration.TriggerMagnitude = Value
        end
    })

    AddCheckToggle(AdvChecks, "TransparencyCheck", "Transparency Check", "Abaikan target transparan")

    AdvChecks:AddSlider("IgnoredTransparency", {
        Title = "Min Transparency",
        Description = "Target diabaikan jika transparansi >= nilai ini",
        Default = Configuration.IgnoredTransparency,
        Min = 0.1, Max = 1, Rounding = 1,
        Callback = function(Value)
            Configuration.IgnoredTransparency = Value
        end
    })

    -- ═══════════════════════════════════════
    -- TAB 3: VISUALS
    -- ═══════════════════════════════════════
    if getfenv().Drawing and getfenv().Drawing.new then
        Tabs.Visuals = Window:AddTab({ Title = "Visuals", Icon = "box" })

        Tabs.Visuals:AddParagraph({
            Title = "⚡ Pengaturan Visual",
            Content = "FoV circle dan ESP overlay"
        })

        -- FoV Section
        local FoVSection = Tabs.Visuals:AddSection("FoV Circle")

        local FoVToggle = FoVSection:AddToggle("FoV", {
            Title = "FoV Circle",
            Description = "Tampilkan lingkaran FoV",
            Default = Configuration.FoV
        })
        FoVToggle:OnChanged(function(Value)
            Configuration.FoV = Value
            if not IsComputer then
                ShowingFoV = Value
            end
        end)

        if IsComputer then
            local FoVKeybind = FoVSection:AddKeybind("FoVKey", {
                Title = "FoV Key",
                Description = "Tombol toggle FoV",
                Default = Configuration.FoVKey,
                ChangedCallback = function(Value)
                    Configuration.FoVKey = Value
                end
            })
            Configuration.FoVKey = FoVKeybind.Value ~= "RMB" and Enum.KeyCode[FoVKeybind.Value] or Enum.UserInputType.MouseButton2
        end

        FoVSection:AddSlider("FoVThickness", {
            Title = "Thickness",
            Default = Configuration.FoVThickness,
            Min = 1, Max = 10, Rounding = 1,
            Callback = function(Value) Configuration.FoVThickness = Value end
        })

        FoVSection:AddSlider("FoVOpacity", {
            Title = "Opacity",
            Default = Configuration.FoVOpacity,
            Min = 0.1, Max = 1, Rounding = 1,
            Callback = function(Value) Configuration.FoVOpacity = Value end
        })

        FoVSection:AddToggle("FoVFilled", {
            Title = "Filled",
            Default = Configuration.FoVFilled,
            Callback = function(Value) Configuration.FoVFilled = Value end
        })

        FoVSection:AddColorpicker("FoVColour", {
            Title = "FoV Colour",
            Default = Configuration.FoVColour,
            Callback = function(Value) Configuration.FoVColour = Value end
        })

        -- ESP Section
        local ESPSection = Tabs.Visuals:AddSection("ESP")

        local SmartESPToggle = ESPSection:AddToggle("SmartESP", {
            Title = "Smart ESP",
            Description = "Hanya ESP target yang valid",
            Default = Configuration.SmartESP
        })
        SmartESPToggle:OnChanged(function(Value)
            Configuration.SmartESP = Value
        end)

        if IsComputer then
            local ESPKeybind = ESPSection:AddKeybind("ESPKey", {
                Title = "ESP Key",
                Description = "Tombol toggle ESP",
                Default = Configuration.ESPKey,
                ChangedCallback = function(Value)
                    Configuration.ESPKey = Value
                end
            })
            Configuration.ESPKey = ESPKeybind.Value ~= "RMB" and Enum.KeyCode[ESPKeybind.Value] or Enum.UserInputType.MouseButton2
        end

        local function AddESPToggle(key, title, desc)
            local toggle = ESPSection:AddToggle(key, {
                Title = title,
                Description = desc,
                Default = Configuration[key]
            })
            toggle:OnChanged(function(Value)
                Configuration[key] = Value
                if not IsComputer then
                    if Value then
                        ShowingESP = true
                    elseif not Configuration.ESPBox and not Configuration.NameESP and not Configuration.HealthESP and not Configuration.MagnitudeESP and not Configuration.TracerESP then
                        ShowingESP = false
                    end
                end
            end)
            return toggle
        end

        AddESPToggle("ESPBox", "ESP Box", "Kotak di sekitar player")
        ESPSection:AddToggle("ESPBoxFilled", {
            Title = "Box Filled",
            Default = Configuration.ESPBoxFilled,
            Callback = function(Value) Configuration.ESPBoxFilled = Value end
        })
        AddESPToggle("NameESP", "Name ESP", "Nama player di atas karakter")

        ESPSection:AddDropdown("NameESPFont", {
            Title = "Name Font",
            Values = { "UI", "System", "Plex", "Monospace" },
            Default = Configuration.NameESPFont,
            Callback = function(Value) Configuration.NameESPFont = Value end
        })

        ESPSection:AddSlider("NameESPSize", {
            Title = "Name Size",
            Default = Configuration.NameESPSize,
            Min = 8, Max = 28, Rounding = 1,
            Callback = function(Value) Configuration.NameESPSize = Value end
        })

        ESPSection:AddColorpicker("NameESPOutlineColour", {
            Title = "Name Outline Colour",
            Default = Configuration.NameESPOutlineColour,
            Callback = function(Value) Configuration.NameESPOutlineColour = Value end
        })

        AddESPToggle("HealthESP", "Health ESP", "Health bar di ESP box")
        AddESPToggle("MagnitudeESP", "Distance ESP", "Jarak ke player")
        AddESPToggle("TracerESP", "Tracer ESP", "Garis ke arah player")

        ESPSection:AddSlider("ESPThickness", {
            Title = "ESP Thickness",
            Default = Configuration.ESPThickness,
            Min = 1, Max = 10, Rounding = 1,
            Callback = function(Value) Configuration.ESPThickness = Value end
        })

        ESPSection:AddSlider("ESPOpacity", {
            Title = "ESP Opacity",
            Default = Configuration.ESPOpacity,
            Min = 0.1, Max = 1, Rounding = 1,
            Callback = function(Value) Configuration.ESPOpacity = Value end
        })

        ESPSection:AddColorpicker("ESPColour", {
            Title = "ESP Colour",
            Default = Configuration.ESPColour,
            Callback = function(Value) Configuration.ESPColour = Value end
        })

        ESPSection:AddToggle("ESPUseTeamColour", {
            Title = "Use Team Colour",
            Description = "Warna ESP sesuai warna tim target",
            Default = Configuration.ESPUseTeamColour,
            Callback = function(Value) Configuration.ESPUseTeamColour = Value end
        })
    end

    -- ═══════════════════════════════════════
    -- TAB 4: SETTINGS
    -- ═══════════════════════════════════════
    Tabs.Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })

    local UISection = Tabs.Settings:AddSection("UI")

    UISection:AddDropdown("Theme", {
        Title = "Theme",
        Description = "Ganti tema UI",
        Values = Fluent.Themes,
        Default = Fluent.Theme,
        Callback = function(Value)
            Fluent:SetTheme(Value)
        end
    })

    UISection:AddToggle("Transparency", {
        Title = "Transparency",
        Description = "UI transparan",
        Default = UISettings.Transparency,
        Callback = function(Value)
            Fluent:ToggleTransparency(Value)
        end
    })

    if IsComputer then
        UISection:AddKeybind("MinimizeKey", {
            Title = "Minimize Key",
            Description = "Tombol untuk minimize UI",
            Default = Fluent.MinimizeKey,
            ChangedCallback = function() end
        })
        Fluent.MinimizeKeybind = Fluent.Options.MinimizeKey
    end

    local PerfSection = Tabs.Settings:AddSection("Performance")

    PerfSection:AddDropdown("RenderingMode", {
        Title = "Rendering Mode",
        Description = "Heartbeat / RenderStepped / Stepped",
        Values = { "Heartbeat", "RenderStepped", "Stepped" },
        Default = UISettings.RenderingMode,
        Callback = function(Value)
            UISettings.RenderingMode = Value
            Window:Dialog({
                Title = "⚡ Open Aimbot",
                Content = "Perubahan berlaku setelah restart!",
                Buttons = { { Title = "OK" } }
            })
        end
    })
end

--! Notification Helper
local function Notify(Message)
    if Fluent and typeof(Message) == "string" then
        Fluent:Notify({
            Title = "⚡ Open Aimbot",
            Content = Message,
            Duration = 1.5
        })
    end
end

Notify("Script berhasil dimuat!")

--! Fields Handler
local FieldsHandler = {}

function FieldsHandler:ResetAimbotFields(SaveAiming, SaveTarget)
    Aiming = SaveAiming and Aiming or false
    Target = SaveTarget and Target or nil
    if Sobing then
        Sobing:Cancel()
        Sobing = nil
    end
    UserInputService.MouseDeltaSensitivity = MouseSensitivity
end

--! Math Handler
local MathHandler = {}

function MathHandler:CalculateDirection(Origin, Position, Magnitude)
    if typeof(Origin) == "Vector3" and typeof(Position) == "Vector3" and typeof(Magnitude) == "number" then
        return (Position - Origin).Unit * Magnitude
    end
    return Vector3.zero
end

function MathHandler:CalculateChance(Percentage)
    if typeof(Percentage) == "number" then
        return math.round(math.clamp(Percentage, 1, 100)) / 100 >= math.round(Random.new():NextNumber() * 100) / 100
    end
    return false
end

function MathHandler:Abbreviate(Number)
    if typeof(Number) ~= "number" then return Number end
    local Abbreviations = {
        T = 10 ^ 12, B = 10 ^ 9, M = 10 ^ 6, K = 10 ^ 3
    }
    local Selected = 0
    local Result = tostring(math.round(Number))
    for Key, Value in next, Abbreviations do
        if math.abs(Number) >= Value and Value > Selected then
            Selected = Value
            Result = string.format("%s%s", tostring(math.round(Number / Value)), Key)
        end
    end
    return Result
end

--! Target Validation
local function IsReady(TargetChar)
    if not TargetChar or not TargetChar:FindFirstChildWhichIsA("Humanoid") or not Configuration.AimPart then
        return false
    end

    local TargetPart = TargetChar:FindFirstChild(Configuration.AimPart)
    if not TargetPart or not TargetPart:IsA("BasePart") then
        return false
    end

    if not Player.Character or not Player.Character:FindFirstChildWhichIsA("Humanoid") then
        return false
    end

    local NativePart = Player.Character:FindFirstChild(Configuration.AimPart)
    if not NativePart or not NativePart:IsA("BasePart") then
        return false
    end

    local _Player = Players:GetPlayerFromCharacter(TargetChar)
    if not _Player or _Player == Player then
        return false
    end

    local Humanoid = TargetChar:FindFirstChildWhichIsA("Humanoid")
    local Head = TargetChar:FindFirstChild("Head")

    -- Basic checks
    if Configuration.AliveCheck and Humanoid.Health == 0 then
        return false
    end

    if Configuration.TeamCheck and _Player.TeamColor == Player.TeamColor then
        return false
    end

    -- Wall check
    if Configuration.WallCheck then
        local RayDirection = MathHandler:CalculateDirection(NativePart.Position, TargetPart.Position, (TargetPart.Position - NativePart.Position).Magnitude)
        local Params = RaycastParams.new()
        Params.FilterType = Enum.RaycastFilterType.Exclude
        Params.FilterDescendantsInstances = { Player.Character }
        Params.IgnoreWater = not Configuration.WaterCheck
        local Result = workspace:Raycast(NativePart.Position, RayDirection, Params)
        if not Result or not Result.Instance or not Result.Instance:FindFirstAncestor(_Player.Name) then
            return false
        end
    end

    -- Distance check
    if Configuration.MagnitudeCheck and (TargetPart.Position - NativePart.Position).Magnitude > Configuration.TriggerMagnitude then
        return false
    end

    -- Transparency check
    if Configuration.TransparencyCheck and Head and Head:IsA("BasePart") and Head.Transparency >= Configuration.IgnoredTransparency then
        return false
    end

    -- Calculate offset
    local OffsetIncrement = Vector3.zero
    if Configuration.UseOffset then
        if Configuration.OffsetType == "Static" then
            OffsetIncrement = Vector3.new(0, TargetPart.Position.Y * Configuration.StaticOffsetIncrement / 10, 0)
        elseif Configuration.OffsetType == "Dynamic" then
            OffsetIncrement = Humanoid.MoveDirection * Configuration.DynamicOffsetIncrement / 10
        else
            OffsetIncrement = Vector3.new(0, TargetPart.Position.Y * Configuration.StaticOffsetIncrement / 10, 0) + Humanoid.MoveDirection * Configuration.DynamicOffsetIncrement / 10
        end
    end

    local FinalPos = TargetPart.Position + OffsetIncrement
    local ViewportPoint = { workspace.CurrentCamera:WorldToViewportPoint(FinalPos) }
    local Distance = (FinalPos - NativePart.Position).Magnitude
    local FinalCFrame = CFrame.new(FinalPos) * CFrame.fromEulerAnglesYXZ(math.rad(TargetPart.Orientation.X), math.rad(TargetPart.Orientation.Y), math.rad(TargetPart.Orientation.Z))

    return true, TargetChar, ViewportPoint, FinalPos, Distance, FinalCFrame, TargetPart
end

--! Arguments Handler (for Silent Aim)
local ValidArguments = {
    Raycast = { Required = 3, Arguments = { "Instance", "Vector3", "Vector3", "RaycastParams" } },
    FindPartOnRay = { Required = 2, Arguments = { "Instance", "Ray", "Instance", "boolean", "boolean" } },
    FindPartOnRayWithIgnoreList = { Required = 3, Arguments = { "Instance", "Ray", "table", "boolean", "boolean" } },
    FindPartOnRayWithWhitelist = { Required = 3, Arguments = { "Instance", "Ray", "table", "boolean" } }
}

local function ValidateArguments(Arguments, Method)
    if typeof(Arguments) ~= "table" or typeof(Method) ~= "table" or #Arguments < Method.Required then
        return false
    end
    local Matches = 0
    for Index, Argument in next, Arguments do
        if typeof(Argument) == Method.Arguments[Index] then
            Matches = Matches + 1
        end
    end
    return Matches >= Method.Required
end

--! Silent Aim Hook
do
    if getfenv().hookmetamethod and getfenv().newcclosure and getfenv().checkcaller and getfenv().getnamecallmethod then
        local OldIndex
        OldIndex = getfenv().hookmetamethod(game, "__index", getfenv().newcclosure(function(self, Index)
            if Fluent and not getfenv().checkcaller() and Configuration.AimMode == "Silent" and table.find(Configuration.SilentAimMethods, "Mouse.Hit / Mouse.Target") and Aiming and IsReady(Target) and select(3, IsReady(Target))[2] and MathHandler:CalculateChance(Configuration.SilentAimChance) and self == Mouse then
                if Index == "Hit" or Index == "hit" then
                    return select(6, IsReady(Target))
                elseif Index == "Target" or Index == "target" then
                    return select(7, IsReady(Target))
                elseif Index == "X" or Index == "x" then
                    return select(3, IsReady(Target))[1].X
                elseif Index == "Y" or Index == "y" then
                    return select(3, IsReady(Target))[1].Y
                elseif Index == "UnitRay" or Index == "unitRay" then
                    return Ray.new(self.Origin, (select(6, IsReady(Target)) - self.Origin).Unit)
                end
            end
            return OldIndex(self, Index)
        end))

        local OldNameCall
        OldNameCall = getfenv().hookmetamethod(game, "__namecall", getfenv().newcclosure(function(...)
            local Method = getfenv().getnamecallmethod()
            local Arguments = { ... }
            local self = Arguments[1]

            if Fluent and not getfenv().checkcaller() and Configuration.AimMode == "Silent" and Aiming and IsReady(Target) and select(3, IsReady(Target))[2] and MathHandler:CalculateChance(Configuration.SilentAimChance) then
                if table.find(Configuration.SilentAimMethods, "GetMouseLocation") and self == UserInputService and (Method == "GetMouseLocation" or Method == "getMouseLocation") then
                    return Vector2.new(select(3, IsReady(Target))[1].X, select(3, IsReady(Target))[1].Y)
                elseif table.find(Configuration.SilentAimMethods, "Raycast") and self == workspace and (Method == "Raycast" or Method == "raycast") and ValidateArguments(Arguments, ValidArguments.Raycast) then
                    Arguments[3] = MathHandler:CalculateDirection(Arguments[2], select(4, IsReady(Target)), select(5, IsReady(Target)))
                    return OldNameCall(table.unpack(Arguments))
                elseif table.find(Configuration.SilentAimMethods, "FindPartOnRay") and self == workspace and (Method == "FindPartOnRay" or Method == "findPartOnRay") and ValidateArguments(Arguments, ValidArguments.FindPartOnRay) then
                    Arguments[2] = Ray.new(Arguments[2].Origin, MathHandler:CalculateDirection(Arguments[2].Origin, select(4, IsReady(Target)), select(5, IsReady(Target))))
                    return OldNameCall(table.unpack(Arguments))
                elseif table.find(Configuration.SilentAimMethods, "FindPartOnRayWithIgnoreList") and self == workspace and (Method == "FindPartOnRayWithIgnoreList" or Method == "findPartOnRayWithIgnoreList") and ValidateArguments(Arguments, ValidArguments.FindPartOnRayWithIgnoreList) then
                    Arguments[2] = Ray.new(Arguments[2].Origin, MathHandler:CalculateDirection(Arguments[2].Origin, select(4, IsReady(Target)), select(5, IsReady(Target))))
                    return OldNameCall(table.unpack(Arguments))
                elseif table.find(Configuration.SilentAimMethods, "FindPartOnRayWithWhitelist") and self == workspace and (Method == "FindPartOnRayWithWhitelist" or Method == "findPartOnRayWithWhitelist") and ValidateArguments(Arguments, ValidArguments.FindPartOnRayWithWhitelist) then
                    Arguments[2] = Ray.new(Arguments[2].Origin, MathHandler:CalculateDirection(Arguments[2].Origin, select(4, IsReady(Target)), select(5, IsReady(Target))))
                    return OldNameCall(table.unpack(Arguments))
                end
            end
            return OldNameCall(...)
        end))
    end
end

--! Visuals Handler
local VisualsHandler = {}

function VisualsHandler:Create(ObjectType)
    if not Fluent or not getfenv().Drawing or not getfenv().Drawing.new then
        return nil
    end

    if ObjectType == "FoV" then
        local Circle = getfenv().Drawing.new("Circle")
        Circle.Visible = false
        Circle.ZIndex = 4
        Circle.NumSides = 1000
        Circle.Radius = Configuration.FoVRadius
        Circle.Thickness = Configuration.FoVThickness
        Circle.Transparency = Configuration.FoVOpacity
        Circle.Filled = Configuration.FoVFilled
        Circle.Color = Configuration.FoVColour
        return Circle
    elseif ObjectType == "ESPBox" then
        local Box = getfenv().Drawing.new("Square")
        Box.Visible = false
        Box.ZIndex = 2
        Box.Thickness = Configuration.ESPThickness
        Box.Transparency = Configuration.ESPOpacity
        Box.Filled = Configuration.ESPBoxFilled
        Box.Color = Configuration.ESPColour
        return Box
    elseif ObjectType == "NameESP" then
        local Text = getfenv().Drawing.new("Text")
        Text.Visible = false
        Text.ZIndex = 3
        Text.Center = true
        Text.Outline = true
        Text.OutlineColor = Configuration.NameESPOutlineColour
        Text.Font = getfenv().Drawing.Fonts and getfenv().Drawing.Fonts[Configuration.NameESPFont]
        Text.Size = Configuration.NameESPSize
        Text.Transparency = Configuration.ESPOpacity
        Text.Color = Configuration.ESPColour
        return Text
    elseif ObjectType == "TracerESP" then
        local Line = getfenv().Drawing.new("Line")
        Line.Visible = false
        Line.ZIndex = 1
        Line.Thickness = Configuration.ESPThickness
        Line.Transparency = Configuration.ESPOpacity
        Line.Color = Configuration.ESPColour
        return Line
    end
    return nil
end

local Visuals = { FoV = VisualsHandler:Create("FoV") }

function VisualsHandler:ClearVisual(Visual, Key)
    if not Visual then return end
    local FoundIndex = table.find(Visuals, Visual)
    if Visual.Destroy then
        Visual:Destroy()
    elseif Visual.Remove then
        Visual:Remove()
    end
    if FoundIndex then
        table.remove(Visuals, FoundIndex)
    elseif Key == "FoV" then
        Visuals.FoV = nil
    end
end

function VisualsHandler:ClearAll()
    for Key, Visual in next, Visuals do
        self:ClearVisual(Visual, Key)
    end
end

function VisualsHandler:UpdateFoV()
    if not Fluent then return self:ClearAll() end
    if not Visuals.FoV then return end
    local MouseLocation = UserInputService:GetMouseLocation()
    Visuals.FoV.Position = Vector2.new(MouseLocation.X, MouseLocation.Y)
    Visuals.FoV.Radius = Configuration.FoVRadius
    Visuals.FoV.Thickness = Configuration.FoVThickness
    Visuals.FoV.Transparency = Configuration.FoVOpacity
    Visuals.FoV.Filled = Configuration.FoVFilled
    Visuals.FoV.Color = Configuration.FoVColour
    Visuals.FoV.Visible = ShowingFoV
end

--! ESP Library
local ESPLibrary = {}

function ESPLibrary:Initialize(_Character)
    if not Fluent or typeof(_Character) ~= "Instance" then return nil end

    local self = setmetatable({}, { __index = self })
    self.Player = Players:GetPlayerFromCharacter(_Character)
    self.Character = _Character
    self.ESPBox = VisualsHandler:Create("ESPBox")
    self.NameESP = VisualsHandler:Create("NameESP")
    self.HealthESP = VisualsHandler:Create("NameESP")
    self.MagnitudeESP = VisualsHandler:Create("NameESP")
    self.TracerESP = VisualsHandler:Create("TracerESP")

    table.insert(Visuals, self.ESPBox)
    table.insert(Visuals, self.NameESP)
    table.insert(Visuals, self.HealthESP)
    table.insert(Visuals, self.MagnitudeESP)
    table.insert(Visuals, self.TracerESP)

    return self
end

function ESPLibrary:Visualize()
    if not Fluent then return VisualsHandler:ClearAll() end
    if not self.Character then return self:Disconnect() end

    local Head = self.Character:FindFirstChild("Head")
    local HRP = self.Character:FindFirstChild("HumanoidRootPart")
    local Humanoid = self.Character:FindFirstChildWhichIsA("Humanoid")

    if not (Head and Head:IsA("BasePart") and HRP and HRP:IsA("BasePart") and Humanoid) then
        self.ESPBox.Visible = false
        self.NameESP.Visible = false
        self.HealthESP.Visible = false
        self.MagnitudeESP.Visible = false
        self.TracerESP.Visible = false
        return
    end

    local IsCharacterReady = true
    if Configuration.SmartESP then
        IsCharacterReady = IsReady(self.Character)
    end

    local HRPPos, IsInViewport = workspace.CurrentCamera:WorldToViewportPoint(HRP.Position)
    local HeadPos = workspace.CurrentCamera:WorldToViewportPoint(Head.Position)
    local TopPos = workspace.CurrentCamera:WorldToViewportPoint(Head.Position + Vector3.new(0, 0.5, 0))
    local BottomPos = workspace.CurrentCamera:WorldToViewportPoint(HRP.Position - Vector3.new(0, 3, 0))

    if IsInViewport then
        local BoxSize = Vector2.new(2350 / HRPPos.Z, TopPos.Y - BottomPos.Y)
        local BoxPos = Vector2.new(HRPPos.X - BoxSize.X / 2, HRPPos.Y - BoxSize.Y / 2)

        self.ESPBox.Size = BoxSize
        self.ESPBox.Position = BoxPos
        self.ESPBox.Thickness = Configuration.ESPThickness
        self.ESPBox.Transparency = Configuration.ESPOpacity
        self.ESPBox.Filled = Configuration.ESPBoxFilled

        local isTarget = Aiming and IsReady(Target) and self.Character == Target
        self.NameESP.Text = isTarget and string.format("🎯@%s🎯", self.Player.Name) or string.format("@%s", self.Player.Name)
        self.NameESP.Font = getfenv().Drawing.Fonts and getfenv().Drawing.Fonts[Configuration.NameESPFont]
        self.NameESP.Size = Configuration.NameESPSize
        self.NameESP.Transparency = Configuration.ESPOpacity
        self.NameESP.Position = Vector2.new(HRPPos.X, HRPPos.Y + BoxSize.Y / 2 - 25)

        self.HealthESP.Text = string.format("[%s%%]", MathHandler:Abbreviate(Humanoid.Health))
        self.HealthESP.Font = getfenv().Drawing.Fonts and getfenv().Drawing.Fonts[Configuration.NameESPFont]
        self.HealthESP.Size = Configuration.NameESPSize
        self.HealthESP.Transparency = Configuration.ESPOpacity
        self.HealthESP.Position = Vector2.new(HRPPos.X, HeadPos.Y)

        local distText = "?"
        if Player.Character and Player.Character:FindFirstChild("Head") and Player.Character:FindFirstChild("Head"):IsA("BasePart") then
            distText = MathHandler:Abbreviate((Head.Position - Player.Character:FindFirstChild("Head").Position).Magnitude)
        end
        self.MagnitudeESP.Text = string.format("[%sm]", distText)
        self.MagnitudeESP.Font = getfenv().Drawing.Fonts and getfenv().Drawing.Fonts[Configuration.NameESPFont]
        self.MagnitudeESP.Size = Configuration.NameESPSize
        self.MagnitudeESP.Transparency = Configuration.ESPOpacity
        self.MagnitudeESP.Position = Vector2.new(HRPPos.X, HRPPos.Y)

        self.TracerESP.Thickness = Configuration.ESPThickness
        self.TracerESP.Transparency = Configuration.ESPOpacity
        self.TracerESP.From = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y)
        self.TracerESP.To = Vector2.new(HRPPos.X, HRPPos.Y - BoxSize.Y / 2)

        -- Apply colors
        if Configuration.ESPUseTeamColour then
            local TC = self.Player.TeamColor.Color
            local Inv = Color3.fromRGB(255 - TC.R * 255, 255 - TC.G * 255, 255 - TC.B * 255)
            self.ESPBox.Color = TC
            self.NameESP.OutlineColor = Inv
            self.NameESP.Color = TC
            self.HealthESP.OutlineColor = Inv
            self.HealthESP.Color = TC
            self.MagnitudeESP.OutlineColor = Inv
            self.MagnitudeESP.Color = TC
            self.TracerESP.Color = TC
        else
            self.ESPBox.Color = Configuration.ESPColour
            self.NameESP.OutlineColor = Configuration.NameESPOutlineColour
            self.NameESP.Color = Configuration.ESPColour
            self.HealthESP.OutlineColor = Configuration.NameESPOutlineColour
            self.HealthESP.Color = Configuration.ESPColour
            self.MagnitudeESP.OutlineColor = Configuration.NameESPOutlineColour
            self.MagnitudeESP.Color = Configuration.ESPColour
            self.TracerESP.Color = Configuration.ESPColour
        end
    end

    local ShowESP = ShowingESP and IsCharacterReady and IsInViewport
    self.ESPBox.Visible = Configuration.ESPBox and ShowESP
    self.NameESP.Visible = Configuration.NameESP and ShowESP
    self.HealthESP.Visible = Configuration.HealthESP and ShowESP
    self.MagnitudeESP.Visible = Configuration.MagnitudeESP and ShowESP
    self.TracerESP.Visible = Configuration.TracerESP and ShowESP
end

function ESPLibrary:Disconnect()
    self.Player = nil
    self.Character = nil
    VisualsHandler:ClearVisual(self.ESPBox)
    VisualsHandler:ClearVisual(self.NameESP)
    VisualsHandler:ClearVisual(self.HealthESP)
    VisualsHandler:ClearVisual(self.MagnitudeESP)
    VisualsHandler:ClearVisual(self.TracerESP)
end

--! Tracking Handler
local TrackingHandler = {}
local Tracking = {}
local Connections = {}

function TrackingHandler:VisualizeESP()
    for _, Tracked in next, Tracking do
        Tracked:Visualize()
    end
end

function TrackingHandler:DisconnectTracking(Key)
    if Key and Tracking[Key] then
        Tracking[Key]:Disconnect()
        Tracking[Key] = nil
    end
end

function TrackingHandler:DisconnectConnection(Key)
    if Key and Connections[Key] then
        for _, Connection in next, Connections[Key] do
            Connection:Disconnect()
        end
        Connections[Key] = nil
    end
end

function TrackingHandler:DisconnectAll()
    for Key, _ in next, Connections do
        self:DisconnectConnection(Key)
    end
    for Key, _ in next, Tracking do
        self:DisconnectTracking(Key)
    end
end

function TrackingHandler:Cleanup()
    FieldsHandler:ResetAimbotFields()
    ShowingFoV = false
    ShowingESP = false
    self:DisconnectAll()
    VisualsHandler:ClearAll()
end

local function CharacterAdded(_Character)
    if typeof(_Character) == "Instance" then
        local _Player = Players:GetPlayerFromCharacter(_Character)
        if _Player then
            Tracking[_Player.UserId] = ESPLibrary:Initialize(_Character)
        end
    end
end

local function CharacterRemoving(_Character)
    if typeof(_Character) == "Instance" then
        for Key, Tracked in next, Tracking do
            if Tracked.Character == _Character then
                TrackingHandler:DisconnectTracking(Key)
            end
        end
    end
end

-- Initialize existing players
if getfenv().Drawing and getfenv().Drawing.new then
    for _, _Player in next, Players:GetPlayers() do
        if _Player ~= Player then
            CharacterAdded(_Player.Character)
            Connections[_Player.UserId] = {
                _Player.CharacterAdded:Connect(CharacterAdded),
                _Player.CharacterRemoving:Connect(CharacterRemoving)
            }
        end
    end
end

--! Player Events
local OnTeleport
OnTeleport = Player.OnTeleport:Connect(function()
    if not Fluent or not getfenv().queue_on_teleport then
        OnTeleport:Disconnect()
    else
        getfenv().queue_on_teleport('getfenv().loadstring(game:HttpGet("https://raw.githubusercontent.com/SOBING4413/aimbot/refs/heads/main/aimbot.lua", true))()')
        OnTeleport:Disconnect()
    end
end)

local PlayerAdded
PlayerAdded = Players.PlayerAdded:Connect(function(_Player)
    if not Fluent or not getfenv().Drawing or not getfenv().Drawing.new then
        PlayerAdded:Disconnect()
    else
        Connections[_Player.UserId] = {
            _Player.CharacterAdded:Connect(CharacterAdded),
            _Player.CharacterRemoving:Connect(CharacterRemoving)
        }
    end
end)

local PlayerRemoving
PlayerRemoving = Players.PlayerRemoving:Connect(function(_Player)
    if not Fluent then
        PlayerRemoving:Disconnect()
    elseif _Player == Player then
        Fluent:Destroy()
        TrackingHandler:Cleanup()
        PlayerRemoving:Disconnect()
    else
        TrackingHandler:DisconnectConnection(_Player.UserId)
        TrackingHandler:DisconnectTracking(_Player.UserId)
    end
end)

--! Input Handler
if IsComputer then
    local InputBegan
    InputBegan = UserInputService.InputBegan:Connect(function(Input)
        if not Fluent then
            InputBegan:Disconnect()
            return
        end
        if UserInputService:GetFocusedTextBox() then return end

        local KC = Input.KeyCode
        local UIT = Input.UserInputType

        if Configuration.Aimbot and (KC == Configuration.AimKey or UIT == Configuration.AimKey) then
            if Aiming then
                FieldsHandler:ResetAimbotFields()
                Notify("[Aim]: OFF")
            else
                Aiming = true
                Notify("[Aim]: ON")
            end
        elseif getfenv().Drawing and getfenv().Drawing.new and Configuration.FoV and (KC == Configuration.FoVKey or UIT == Configuration.FoVKey) then
            ShowingFoV = not ShowingFoV
            Notify(ShowingFoV and "[FoV]: ON" or "[FoV]: OFF")
        elseif getfenv().Drawing and getfenv().Drawing.new and (Configuration.ESPBox or Configuration.NameESP or Configuration.HealthESP or Configuration.MagnitudeESP or Configuration.TracerESP) and (KC == Configuration.ESPKey or UIT == Configuration.ESPKey) then
            ShowingESP = not ShowingESP
            Notify(ShowingESP and "[ESP]: ON" or "[ESP]: OFF")
        end
    end)

    local InputEnded
    InputEnded = UserInputService.InputEnded:Connect(function(Input)
        if not Fluent then
            InputEnded:Disconnect()
            return
        end
        if UserInputService:GetFocusedTextBox() then return end

        if Aiming and not Configuration.OnePressAimingMode and (Input.KeyCode == Configuration.AimKey or Input.UserInputType == Configuration.AimKey) then
            FieldsHandler:ResetAimbotFields()
            Notify("[Aim]: OFF")
        end
    end)

    local WindowFocused
    WindowFocused = UserInputService.WindowFocused:Connect(function()
        if not Fluent then WindowFocused:Disconnect() else RobloxActive = true end
    end)

    local WindowFocusReleased
    WindowFocusReleased = UserInputService.WindowFocusReleased:Connect(function()
        if not Fluent then WindowFocusReleased:Disconnect() else RobloxActive = false end
    end)
end

--! Main Loop
local AimbotLoop
AimbotLoop = RunService[UISettings.RenderingMode]:Connect(function()
    if Fluent.Unloaded then
        Fluent = nil
        TrackingHandler:Cleanup()
        AimbotLoop:Disconnect()
        return
    end

    -- Auto-disable toggles
    if not Configuration.Aimbot and Aiming then
        FieldsHandler:ResetAimbotFields()
    end
    if not Configuration.FoV and ShowingFoV then
        ShowingFoV = false
    end
    if not Configuration.ESPBox and not Configuration.NameESP and not Configuration.HealthESP and not Configuration.MagnitudeESP and not Configuration.TracerESP and ShowingESP then
        ShowingESP = false
    end

    if not RobloxActive then return end

    -- Update visuals
    if getfenv().Drawing and getfenv().Drawing.new then
        VisualsHandler:UpdateFoV()
        TrackingHandler:VisualizeESP()
    end

    -- Aimbot logic
    if Aiming then
        local OldTarget = Target
        local Closest = math.huge

        if not IsReady(OldTarget) then
            if not OldTarget then
                for _, _Player in next, Players:GetPlayers() do
                    local IsCharacterReady, Character, PartViewportPosition = IsReady(_Player.Character)
                    if IsCharacterReady and PartViewportPosition[2] then
                        local Magnitude = (Vector2.new(Mouse.X, Mouse.Y) - Vector2.new(PartViewportPosition[1].X, PartViewportPosition[1].Y)).Magnitude
                        if Magnitude <= Closest and Magnitude <= (Configuration.FoVCheck and Configuration.FoVRadius or Closest) then
                            Target = Character
                            Closest = Magnitude
                        end
                    end
                end
            else
                FieldsHandler:ResetAimbotFields()
            end
        end

        local IsTargetReady, _, PartViewportPosition, PartWorldPosition = IsReady(Target)
        if IsTargetReady then
            if getfenv().mousemoverel and IsComputer and Configuration.AimMode == "Mouse" then
                if PartViewportPosition[2] then
                    FieldsHandler:ResetAimbotFields(true, true)
                    local MouseLocation = UserInputService:GetMouseLocation()
                    local Sens = Configuration.UseSensitivity and Configuration.Sensitivity / 5 or 10
                    getfenv().mousemoverel(
                        (PartViewportPosition[1].X - MouseLocation.X) / Sens,
                        (PartViewportPosition[1].Y - MouseLocation.Y) / Sens
                    )
                else
                    FieldsHandler:ResetAimbotFields(true)
                end
            elseif Configuration.AimMode == "Camera" then
                UserInputService.MouseDeltaSensitivity = 0
                if Configuration.UseSensitivity then
                    Sobing = SobingService:Create(
                        workspace.CurrentCamera,
                        SobingInfo.new(math.clamp(Configuration.Sensitivity, 9, 99) / 100, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
                        { CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, PartWorldPosition) }
                    )
                    Sobing:Play()
                else
                    workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, PartWorldPosition)
                end
            elseif getfenv().hookmetamethod and getfenv().newcclosure and getfenv().checkcaller and getfenv().getnamecallmethod and Configuration.AimMode == "Silent" then
                FieldsHandler:ResetAimbotFields(true, true)
            end
        else
            FieldsHandler:ResetAimbotFields(true)
        end
    end
end)
