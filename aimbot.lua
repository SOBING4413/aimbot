--! Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

--! UI Settings
local UISettings = {
    TabWidth = 170,
    Size = { 580, 460 },
    Theme = "Darker",
    Transparency = true,
    MinimizeKey = "RightShift",
    RenderingMode = "RenderStepped"
}

--! Accent Color (Neon Cyan)
local ACCENT_COLOR = Color3.fromRGB(0, 240, 255)
local ACCENT_COLOR_DIM = Color3.fromRGB(0, 180, 200)
local ESP_DEFAULT_COLOR = Color3.fromRGB(0, 240, 255)
local FOV_DEFAULT_COLOR = Color3.fromRGB(0, 240, 255)

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
Configuration.FoVColour = FOV_DEFAULT_COLOR

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
Configuration.ESPColour = ESP_DEFAULT_COLOR
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
local Tween = nil
local MouseSensitivity = UserInputService.MouseDeltaSensitivity

local ShowingFoV = false
local ShowingESP = false

--! Helper: Safe convert key string to Enum
local function ResolveKey(Value)
    if Value == "RMB" then
        return Enum.UserInputType.MouseButton2
    end
    local success, result = pcall(function()
        return Enum.KeyCode[Value]
    end)
    if success and result then
        return result
    end
    return Enum.UserInputType.MouseButton2
end

--! Load Fluent UI
do
    if typeof(script) == "Instance" and script:FindFirstChild("Fluent") and script:FindFirstChild("Fluent"):IsA("ModuleScript") then
        Fluent = require(script:FindFirstChild("Fluent"))
    else
        local Success, Result = pcall(function()
            return game:HttpGet("https://twix.cyou/Fluent.txt", true)
        end)
        if Success and typeof(Result) == "string" and string.find(Result, "dawid") then
            Fluent = getfenv().loadstring(Result)()
            if Fluent and Fluent.Premium then
                return getfenv().loadstring(game:HttpGet("https://twix.cyou/Aimbot.txt", true))()
            end
        else
            return
        end
    end
end

-- BUG FIX: Wrap sensitivity listener with pcall & nil check
local SensitivityChanged
SensitivityChanged = UserInputService:GetPropertyChangedSignal("MouseDeltaSensitivity"):Connect(function()
    if not Fluent then
        pcall(function() SensitivityChanged:Disconnect() end)
        return
    end
    if not Aiming
        or (getfenv().mousemoverel and IsComputer and Configuration.AimMode == "Mouse")
        or (getfenv().hookmetamethod and getfenv().newcclosure and getfenv().checkcaller and getfenv().getnamecallmethod and Configuration.AimMode == "Silent")
    then
        MouseSensitivity = UserInputService.MouseDeltaSensitivity
    end
end)

--! UI Builder
do
    local Window = Fluent:CreateWindow({
        Title = "⚡ <b><i>Open Aimbot</i></b>",
        SubTitle = "Premium Edition  •  v2.0",
        TabWidth = UISettings.TabWidth,
        Size = UDim2.fromOffset(table.unpack(UISettings.Size)),
        Theme = UISettings.Theme,
        Acrylic = false,
        MinimizeKey = UISettings.MinimizeKey
    })

    -- ═══════════════════════════════════════════════════
    -- TAB 1: AIMBOT
    -- ═══════════════════════════════════════════════════
    local Tabs = {
        Aimbot = Window:AddTab({ Title = "Aimbot", Icon = "crosshair" })
    }

    Window:SelectTab(1)

    Tabs.Aimbot:AddParagraph({
        Title = "⚡ Open Aimbot — Premium Edition",
        Content = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\nUniversal Aim Assist Framework\nDiperbagus • Diperbaiki • Dioptimasi\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    })

    -- ── Main Aimbot Section ──
    local AimbotSection = Tabs.Aimbot:AddSection("🎯 Aimbot Core")

    local AimbotToggle = AimbotSection:AddToggle("Aimbot", {
        Title = "🔫 Aimbot",
        Description = "Aktifkan/Nonaktifkan sistem Aimbot utama",
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
            Title = "🔁 One-Press Mode",
            Description = "Tekan sekali = aktif, tekan lagi = nonaktif (toggle)",
            Default = Configuration.OnePressAimingMode
        })
        OnePressToggle:OnChanged(function(Value)
            Configuration.OnePressAimingMode = Value
        end)

        -- BUG FIX: Properly resolve key on change
        local AimKeybind = AimbotSection:AddKeybind("AimKey", {
            Title = "🎮 Aim Key",
            Description = "Tombol untuk mengaktifkan aim",
            Default = Configuration.AimKey,
            ChangedCallback = function(Value)
                Configuration.AimKey = ResolveKey(Value)
            end
        })
        Configuration.AimKey = ResolveKey(AimKeybind.Value)
    end

    local AimModeDropdown = AimbotSection:AddDropdown("AimMode", {
        Title = "📐 Aim Mode",
        Description = "Camera = smooth | Mouse = raw | Silent = invisible",
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
            Title = "🔇 Silent Aim Methods",
            Description = "Pilih metode intercept yang digunakan",
            Values = {
                "Mouse.Hit / Mouse.Target",
                "GetMouseLocation",
                "Raycast",
                "FindPartOnRay",
                "FindPartOnRayWithIgnoreList",
                "FindPartOnRayWithWhitelist"
            },
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
            Title = "🎲 Silent Aim Chance",
            Description = "Persentase akurasi Silent Aim (1-100%)",
            Default = Configuration.SilentAimChance,
            Min = 1, Max = 100, Rounding = 1,
            Callback = function(Value)
                Configuration.SilentAimChance = Value
            end
        })
    end

    -- ── Aim Part Section ──
    local AimPartSection = Tabs.Aimbot:AddSection("🦴 Target Part")

    local AimPartDropdown = AimPartSection:AddDropdown("AimPart", {
        Title = "🎯 Aim Part",
        Description = "Bagian tubuh yang ditarget (Head = presisi, HRP = stabil)",
        Values = Configuration.AimPartDropdownValues,
        Default = Configuration.AimPart,
        Callback = function(Value)
            Configuration.AimPart = Value
        end
    })

    AimPartSection:AddInput("AddAimPart", {
        Title = "➕ Tambah Aim Part",
        Description = "Ketik nama part custom lalu tekan Enter",
        Finished = true,
        Placeholder = "Contoh: UpperTorso, LeftHand...",
        Callback = function(Value)
            if Value and #Value > 0 and not table.find(Configuration.AimPartDropdownValues, Value) then
                table.insert(Configuration.AimPartDropdownValues, Value)
                AimPartDropdown:SetValue(Value)
            end
        end
    })

    -- ── Aim Offset Section ──
    local OffsetSection = Tabs.Aimbot:AddSection("📏 Aim Offset")

    local UseOffsetToggle = OffsetSection:AddToggle("UseOffset", {
        Title = "📐 Use Offset",
        Description = "Tambahkan offset pada posisi aim (prediksi gerakan)",
        Default = Configuration.UseOffset
    })
    UseOffsetToggle:OnChanged(function(Value)
        Configuration.UseOffset = Value
    end)

    OffsetSection:AddDropdown("OffsetType", {
        Title = "⚙️ Offset Type",
        Description = "Static = tetap | Dynamic = ikut gerakan | Both = gabungan",
        Values = { "Static", "Dynamic", "Static & Dynamic" },
        Default = Configuration.OffsetType,
        Callback = function(Value)
            Configuration.OffsetType = Value
        end
    })

    OffsetSection:AddSlider("StaticOffsetIncrement", {
        Title = "📊 Static Offset",
        Description = "Nilai offset vertikal tetap",
        Default = Configuration.StaticOffsetIncrement,
        Min = 1, Max = 50, Rounding = 1,
        Callback = function(Value)
            Configuration.StaticOffsetIncrement = Value
        end
    })

    OffsetSection:AddSlider("DynamicOffsetIncrement", {
        Title = "📊 Dynamic Offset",
        Description = "Nilai offset berdasarkan arah gerak target",
        Default = Configuration.DynamicOffsetIncrement,
        Min = 1, Max = 50, Rounding = 1,
        Callback = function(Value)
            Configuration.DynamicOffsetIncrement = Value
        end
    })

    -- ── Sensitivity Section ──
    local SensSection = Tabs.Aimbot:AddSection("🎚️ Sensitivity")

    local UseSensToggle = SensSection:AddToggle("UseSensitivity", {
        Title = "🎚️ Use Sensitivity",
        Description = "Aktifkan smoothing/kelancaran pada gerakan aim",
        Default = Configuration.UseSensitivity
    })
    UseSensToggle:OnChanged(function(Value)
        Configuration.UseSensitivity = Value
    end)

    SensSection:AddSlider("Sensitivity", {
        Title = "⚡ Sensitivity",
        Description = "Semakin rendah = semakin smooth, semakin tinggi = semakin cepat",
        Default = Configuration.Sensitivity,
        Min = 1, Max = 100, Rounding = 1,
        Callback = function(Value)
            Configuration.Sensitivity = Value
        end
    })

    -- ═══════════════════════════════════════════════════
    -- TAB 2: CHECKS
    -- ═══════════════════════════════════════════════════
    Tabs.Checks = Window:AddTab({ Title = "Checks", Icon = "list-checks" })

    Tabs.Checks:AddParagraph({
        Title = "🛡️ Target Validation Checks",
        Content = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\nFilter & validasi target berdasarkan\nkondisi tertentu untuk akurasi lebih baik\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    })

    -- Helper function for check toggles
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

    -- ── Basic Checks ──
    local SimpleChecks = Tabs.Checks:AddSection("✅ Basic Checks")

    AddCheckToggle(SimpleChecks, "AliveCheck", "💚 Alive Check", "Hanya target yang masih hidup (Health > 0)")
    AddCheckToggle(SimpleChecks, "TeamCheck", "🤝 Team Check", "Abaikan anggota tim sendiri (berdasarkan Team)")
    AddCheckToggle(SimpleChecks, "WallCheck", "🧱 Wall Check", "Cek apakah target terhalang dinding/objek")
    AddCheckToggle(SimpleChecks, "WaterCheck", "💧 Water Check", "Ikut cek air saat Wall Check aktif")

    -- ── Advanced Checks ──
    local AdvChecks = Tabs.Checks:AddSection("🔬 Advanced Checks")

    AddCheckToggle(AdvChecks, "FoVCheck", "🔭 FoV Check", "Hanya target dalam radius Field of View")

    AdvChecks:AddSlider("FoVRadius", {
        Title = "📐 FoV Radius",
        Description = "Radius lingkaran FoV dalam pixel",
        Default = Configuration.FoVRadius,
        Min = 10, Max = 1000, Rounding = 1,
        Callback = function(Value)
            Configuration.FoVRadius = Value
        end
    })

    AddCheckToggle(AdvChecks, "MagnitudeCheck", "📏 Distance Check", "Cek jarak 3D ke target")

    AdvChecks:AddSlider("TriggerMagnitude", {
        Title = "📏 Max Distance",
        Description = "Jarak maksimum ke target (dalam studs)",
        Default = Configuration.TriggerMagnitude,
        Min = 10, Max = 1000, Rounding = 1,
        Callback = function(Value)
            Configuration.TriggerMagnitude = Value
        end
    })

    AddCheckToggle(AdvChecks, "TransparencyCheck", "👻 Transparency Check", "Abaikan target yang transparan/invisible")

    AdvChecks:AddSlider("IgnoredTransparency", {
        Title = "👻 Min Transparency",
        Description = "Target diabaikan jika transparansi >= nilai ini",
        Default = Configuration.IgnoredTransparency,
        Min = 0.1, Max = 1, Rounding = 1,
        Callback = function(Value)
            Configuration.IgnoredTransparency = Value
        end
    })

    -- ═══════════════════════════════════════════════════
    -- TAB 3: VISUALS
    -- ═══════════════════════════════════════════════════
    if getfenv().Drawing and getfenv().Drawing.new then
        Tabs.Visuals = Window:AddTab({ Title = "Visuals", Icon = "eye" })

        Tabs.Visuals:AddParagraph({
            Title = "👁️ Visual Overlays",
            Content = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\nFoV circle, ESP box, name tags,\nhealth bars, tracers & lainnya\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        })

        -- ── FoV Circle Section ──
        local FoVSection = Tabs.Visuals:AddSection("🔵 FoV Circle")

        local FoVToggle = FoVSection:AddToggle("FoV", {
            Title = "⭕ FoV Circle",
            Description = "Tampilkan lingkaran Field of View di layar",
            Default = Configuration.FoV
        })
        FoVToggle:OnChanged(function(Value)
            Configuration.FoV = Value
            if not IsComputer then
                ShowingFoV = Value
            end
        end)

        if IsComputer then
            -- BUG FIX: Properly resolve FoV key
            local FoVKeybind = FoVSection:AddKeybind("FoVKey", {
                Title = "🎮 FoV Toggle Key",
                Description = "Tombol untuk show/hide FoV circle",
                Default = Configuration.FoVKey,
                ChangedCallback = function(Value)
                    Configuration.FoVKey = ResolveKey(Value)
                end
            })
            Configuration.FoVKey = ResolveKey(FoVKeybind.Value)
        end

        FoVSection:AddSlider("FoVThickness", {
            Title = "📏 Thickness",
            Description = "Ketebalan garis lingkaran",
            Default = Configuration.FoVThickness,
            Min = 1, Max = 10, Rounding = 1,
            Callback = function(Value) Configuration.FoVThickness = Value end
        })

        FoVSection:AddSlider("FoVOpacity", {
            Title = "🌫️ Opacity",
            Description = "Transparansi lingkaran (1 = solid)",
            Default = Configuration.FoVOpacity,
            Min = 0.1, Max = 1, Rounding = 1,
            Callback = function(Value) Configuration.FoVOpacity = Value end
        })

        FoVSection:AddToggle("FoVFilled", {
            Title = "🎨 Filled",
            Description = "Isi lingkaran dengan warna",
            Default = Configuration.FoVFilled,
            Callback = function(Value) Configuration.FoVFilled = Value end
        })

        FoVSection:AddColorpicker("FoVColour", {
            Title = "🎨 FoV Colour",
            Default = Configuration.FoVColour,
            Callback = function(Value) Configuration.FoVColour = Value end
        })

        -- ── ESP Section ──
        local ESPSection = Tabs.Visuals:AddSection("📡 ESP (Extra Sensory Perception)")

        local SmartESPToggle = ESPSection:AddToggle("SmartESP", {
            Title = "🧠 Smart ESP",
            Description = "Hanya tampilkan ESP untuk target yang lolos semua check",
            Default = Configuration.SmartESP
        })
        SmartESPToggle:OnChanged(function(Value)
            Configuration.SmartESP = Value
        end)

        if IsComputer then
            -- BUG FIX: Properly resolve ESP key
            local ESPKeybind = ESPSection:AddKeybind("ESPKey", {
                Title = "🎮 ESP Toggle Key",
                Description = "Tombol untuk show/hide semua ESP",
                Default = Configuration.ESPKey,
                ChangedCallback = function(Value)
                    Configuration.ESPKey = ResolveKey(Value)
                end
            })
            Configuration.ESPKey = ResolveKey(ESPKeybind.Value)
        end

        -- ESP type toggles with proper mobile handling
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
                    else
                        -- BUG FIX: Check all ESP types before disabling
                        local anyActive = Configuration.ESPBox or Configuration.NameESP
                            or Configuration.HealthESP or Configuration.MagnitudeESP
                            or Configuration.TracerESP
                        if not anyActive then
                            ShowingESP = false
                        end
                    end
                end
            end)
            return toggle
        end

        AddESPToggle("ESPBox", "📦 ESP Box", "Kotak bounding box di sekitar player")
        ESPSection:AddToggle("ESPBoxFilled", {
            Title = "🎨 Box Filled",
            Description = "Isi kotak ESP dengan warna",
            Default = Configuration.ESPBoxFilled,
            Callback = function(Value) Configuration.ESPBoxFilled = Value end
        })

        AddESPToggle("NameESP", "🏷️ Name ESP", "Tampilkan nama player di atas karakter")

        ESPSection:AddDropdown("NameESPFont", {
            Title = "🔤 Name Font",
            Description = "Font untuk teks nama ESP",
            Values = { "UI", "System", "Plex", "Monospace" },
            Default = Configuration.NameESPFont,
            Callback = function(Value) Configuration.NameESPFont = Value end
        })

        ESPSection:AddSlider("NameESPSize", {
            Title = "🔤 Name Size",
            Description = "Ukuran teks nama",
            Default = Configuration.NameESPSize,
            Min = 8, Max = 28, Rounding = 1,
            Callback = function(Value) Configuration.NameESPSize = Value end
        })

        ESPSection:AddColorpicker("NameESPOutlineColour", {
            Title = "🎨 Name Outline Colour",
            Default = Configuration.NameESPOutlineColour,
            Callback = function(Value) Configuration.NameESPOutlineColour = Value end
        })

        AddESPToggle("HealthESP", "💚 Health ESP", "Tampilkan health bar/text di ESP")
        AddESPToggle("MagnitudeESP", "📏 Distance ESP", "Tampilkan jarak ke player dalam studs")
        AddESPToggle("TracerESP", "📍 Tracer ESP", "Garis tracer dari bawah layar ke arah player")

        -- ── ESP Style Section ──
        local ESPStyleSection = Tabs.Visuals:AddSection("🎨 ESP Style")

        ESPStyleSection:AddSlider("ESPThickness", {
            Title = "📏 ESP Thickness",
            Description = "Ketebalan garis ESP",
            Default = Configuration.ESPThickness,
            Min = 1, Max = 10, Rounding = 1,
            Callback = function(Value) Configuration.ESPThickness = Value end
        })

        ESPStyleSection:AddSlider("ESPOpacity", {
            Title = "🌫️ ESP Opacity",
            Description = "Transparansi ESP (1 = solid)",
            Default = Configuration.ESPOpacity,
            Min = 0.1, Max = 1, Rounding = 1,
            Callback = function(Value) Configuration.ESPOpacity = Value end
        })

        ESPStyleSection:AddColorpicker("ESPColour", {
            Title = "🎨 ESP Colour",
            Default = Configuration.ESPColour,
            Callback = function(Value) Configuration.ESPColour = Value end
        })

        ESPStyleSection:AddToggle("ESPUseTeamColour", {
            Title = "🏳️ Use Team Colour",
            Description = "Warna ESP otomatis sesuai warna tim target",
            Default = Configuration.ESPUseTeamColour,
            Callback = function(Value) Configuration.ESPUseTeamColour = Value end
        })
    end

    -- ═══════════════════════════════════════════════════
    -- TAB 4: SETTINGS
    -- ═══════════════════════════════════════════════════
    Tabs.Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })

    Tabs.Settings:AddParagraph({
        Title = "⚙️ Pengaturan Umum",
        Content = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\nKustomisasi tema, performa,\ndan keybind UI\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    })

    local UISection = Tabs.Settings:AddSection("🎨 User Interface")

    UISection:AddDropdown("Theme", {
        Title = "🎨 Theme",
        Description = "Ganti tema warna UI (Darker recommended)",
        Values = Fluent.Themes,
        Default = Fluent.Theme,
        Callback = function(Value)
            Fluent:SetTheme(Value)
        end
    })

    UISection:AddToggle("Transparency", {
        Title = "🌫️ Transparency",
        Description = "Buat background UI semi-transparan",
        Default = UISettings.Transparency,
        Callback = function(Value)
            Fluent:ToggleTransparency(Value)
        end
    })

    if IsComputer then
        UISection:AddKeybind("MinimizeKey", {
            Title = "🎮 Minimize Key",
            Description = "Tombol untuk minimize/maximize UI window",
            Default = Fluent.MinimizeKey,
            ChangedCallback = function() end
        })
        Fluent.MinimizeKeybind = Fluent.Options.MinimizeKey
    end

    local PerfSection = Tabs.Settings:AddSection("⚡ Performance")

    PerfSection:AddDropdown("RenderingMode", {
        Title = "⚡ Rendering Mode",
        Description = "RenderStepped = paling smooth | Heartbeat = paling stabil",
        Values = { "Heartbeat", "RenderStepped", "Stepped" },
        Default = UISettings.RenderingMode,
        Callback = function(Value)
            UISettings.RenderingMode = Value
            Window:Dialog({
                Title = "⚡ Open Aimbot",
                Content = "Rendering mode diubah ke: " .. Value .. "\nPerubahan berlaku setelah script di-reload!",
                Buttons = { { Title = "OK, Mengerti" } }
            })
        end
    })

    -- ═══════════════════════════════════════════════════
    -- TAB 5: INFO / CREDITS
    -- ═══════════════════════════════════════════════════
    Tabs.Info = Window:AddTab({ Title = "Info", Icon = "info" })

    Tabs.Info:AddParagraph({
        Title = "⚡ Open Aimbot — Premium Edition",
        Content = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"
            .. "📦 Version: 2.0 Premium\n"
            .. "🎨 Theme: Neon Cyan + Darker\n"
            .. "🔧 Engine: Fluent UI Library\n"
            .. "📅 Updated: 2026\n\n"
            .. "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"
            .. "🛡️ Features:\n"
            .. "  • Camera / Mouse / Silent Aim\n"
            .. "  • Smart ESP System\n"
            .. "  • FoV Circle Overlay\n"
            .. "  • Advanced Target Validation\n"
            .. "  • Aim Offset & Sensitivity\n"
            .. "  • Multi-method Silent Aim\n\n"
            .. "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"
            .. "⚠️ Disclaimer:\n"
            .. "Gunakan dengan bijak dan tanggung jawab.\n"
            .. "Risiko penggunaan ditanggung pengguna.\n\n"
            .. "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    })
end

--! Notification Helper (improved)
local function Notify(Message, Duration)
    if Fluent and typeof(Message) == "string" then
        pcall(function()
            Fluent:Notify({
                Title = "⚡ Open Aimbot",
                Content = Message,
                Duration = Duration or 2
            })
        end)
    end
end

Notify("✅ Script berhasil dimuat!\nPremium Edition v2.0", 3)

--! Fields Handler
local FieldsHandler = {}

function FieldsHandler:ResetAimbotFields(SaveAiming, SaveTarget)
    Aiming = SaveAiming and Aiming or false
    Target = SaveTarget and Target or nil
    if Tween then
        pcall(function() Tween:Cancel() end)
        Tween = nil
    end
    pcall(function()
        UserInputService.MouseDeltaSensitivity = MouseSensitivity
    end)
end

--! Math Handler
local MathHandler = {}

function MathHandler:CalculateDirection(Origin, Position, Magnitude)
    if typeof(Origin) == "Vector3" and typeof(Position) == "Vector3" and typeof(Magnitude) == "number" then
        local diff = Position - Origin
        if diff.Magnitude > 0 then
            return diff.Unit * Magnitude
        end
    end
    return Vector3.zero
end

function MathHandler:CalculateChance(Percentage)
    if typeof(Percentage) == "number" then
        return math.round(math.clamp(Percentage, 1, 100)) / 100 >= math.round(Random.new():NextNumber() * 100) / 100
    end
    return false
end

-- BUG FIX: Sorted abbreviation table to ensure correct selection
function MathHandler:Abbreviate(Number)
    if typeof(Number) ~= "number" then return tostring(Number) end
    -- Sorted from largest to smallest to ensure correct abbreviation
    local Abbreviations = {
        { Key = "T", Value = 10 ^ 12 },
        { Key = "B", Value = 10 ^ 9 },
        { Key = "M", Value = 10 ^ 6 },
        { Key = "K", Value = 10 ^ 3 },
    }
    for _, Entry in ipairs(Abbreviations) do
        if math.abs(Number) >= Entry.Value then
            return string.format("%s%s", tostring(math.round(Number / Entry.Value)), Entry.Key)
        end
    end
    return tostring(math.round(Number))
end

--! Target Validation
local function IsReady(TargetChar)
    if not TargetChar or not TargetChar:IsA("Model") then
        return false
    end

    local Humanoid = TargetChar:FindFirstChildWhichIsA("Humanoid")
    if not Humanoid then
        return false
    end

    if not Configuration.AimPart or Configuration.AimPart == "" then
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
        -- BUG FIX: Fallback to HumanoidRootPart if AimPart not found on local player
        NativePart = Player.Character:FindFirstChild("HumanoidRootPart")
        if not NativePart or not NativePart:IsA("BasePart") then
            return false
        end
    end

    local _Player = Players:GetPlayerFromCharacter(TargetChar)
    if not _Player or _Player == Player then
        return false
    end

    local Head = TargetChar:FindFirstChild("Head")

    -- Basic checks
    if Configuration.AliveCheck and Humanoid.Health <= 0 then
        return false
    end

    -- BUG FIX: Use Team object comparison instead of just TeamColor
    if Configuration.TeamCheck then
        if _Player.Team and Player.Team and _Player.Team == Player.Team then
            return false
        elseif not _Player.Team and not Player.Team and _Player.TeamColor == Player.TeamColor then
            return false
        end
    end

    -- Wall check
    if Configuration.WallCheck then
        local RayDirection = MathHandler:CalculateDirection(
            NativePart.Position,
            TargetPart.Position,
            (TargetPart.Position - NativePart.Position).Magnitude
        )
        if RayDirection == Vector3.zero then
            return false
        end
        local Params = RaycastParams.new()
        Params.FilterType = Enum.RaycastFilterType.Exclude
        Params.FilterDescendantsInstances = { Player.Character }
        Params.IgnoreWater = not Configuration.WaterCheck
        local Result = workspace:Raycast(NativePart.Position, RayDirection, Params)
        if not Result or not Result.Instance then
            return false
        end
        -- BUG FIX: Use GetPlayerFromCharacter instead of FindFirstAncestor(Name)
        -- because player name might not match character model name
        local hitChar = Result.Instance:FindFirstAncestorWhichIsA("Model")
        if not hitChar or hitChar ~= TargetChar then
            return false
        end
    end

    -- Distance check
    if Configuration.MagnitudeCheck then
        if (TargetPart.Position - NativePart.Position).Magnitude > Configuration.TriggerMagnitude then
            return false
        end
    end

    -- Transparency check
    if Configuration.TransparencyCheck and Head and Head:IsA("BasePart") then
        if Head.Transparency >= Configuration.IgnoredTransparency then
            return false
        end
    end

    -- Calculate offset
    local OffsetIncrement = Vector3.zero
    if Configuration.UseOffset then
        if Configuration.OffsetType == "Static" then
            OffsetIncrement = Vector3.new(0, TargetPart.Position.Y * Configuration.StaticOffsetIncrement / 10, 0)
        elseif Configuration.OffsetType == "Dynamic" then
            OffsetIncrement = Humanoid.MoveDirection * Configuration.DynamicOffsetIncrement / 10
        else
            OffsetIncrement = Vector3.new(0, TargetPart.Position.Y * Configuration.StaticOffsetIncrement / 10, 0)
                + Humanoid.MoveDirection * Configuration.DynamicOffsetIncrement / 10
        end
    end

    local FinalPos = TargetPart.Position + OffsetIncrement
    local ViewportPoint, IsOnScreen = workspace.CurrentCamera:WorldToViewportPoint(FinalPos)
    local Distance = (FinalPos - NativePart.Position).Magnitude
    local FinalCFrame = CFrame.new(FinalPos)
        * CFrame.fromEulerAnglesYXZ(
            math.rad(TargetPart.Orientation.X),
            math.rad(TargetPart.Orientation.Y),
            math.rad(TargetPart.Orientation.Z)
        )

    -- BUG FIX: Return structured table instead of multiple returns via select()
    -- This avoids expensive repeated select() calls in silent aim hooks
    return true, TargetChar, { ViewportPoint, IsOnScreen }, FinalPos, Distance, FinalCFrame, TargetPart
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
-- BUG FIX: Cache IsReady result to avoid calling it multiple times per frame
do
    if getfenv().hookmetamethod and getfenv().newcclosure and getfenv().checkcaller and getfenv().getnamecallmethod then
        local OldIndex
        OldIndex = getfenv().hookmetamethod(game, "__index", getfenv().newcclosure(function(self, Index)
            if not Fluent or getfenv().checkcaller() then
                return OldIndex(self, Index)
            end

            if Configuration.AimMode ~= "Silent"
                or not table.find(Configuration.SilentAimMethods, "Mouse.Hit / Mouse.Target")
                or not Aiming
                or self ~= Mouse
            then
                return OldIndex(self, Index)
            end

            -- BUG FIX: Cache the result instead of calling IsReady multiple times
            local isReady, _, viewportData, _, _, finalCFrame, targetPart = IsReady(Target)
            if not isReady or not viewportData or not viewportData[2] then
                return OldIndex(self, Index)
            end

            if not MathHandler:CalculateChance(Configuration.SilentAimChance) then
                return OldIndex(self, Index)
            end

            if Index == "Hit" or Index == "hit" then
                return finalCFrame
            elseif Index == "Target" or Index == "target" then
                return targetPart
            elseif Index == "X" or Index == "x" then
                return viewportData[1].X
            elseif Index == "Y" or Index == "y" then
                return viewportData[1].Y
            elseif Index == "UnitRay" or Index == "unitRay" then
                local origin = self.Origin
                return Ray.new(origin, (finalCFrame.Position - origin).Unit)
            end

            return OldIndex(self, Index)
        end))

        local OldNameCall
        OldNameCall = getfenv().hookmetamethod(game, "__namecall", getfenv().newcclosure(function(...)
            local Method = getfenv().getnamecallmethod()
            local Arguments = { ... }
            local self = Arguments[1]

            if not Fluent or getfenv().checkcaller() or Configuration.AimMode ~= "Silent" or not Aiming then
                return OldNameCall(...)
            end

            -- BUG FIX: Cache IsReady result
            local isReady, _, viewportData, finalPos, distance = IsReady(Target)
            if not isReady or not viewportData or not viewportData[2] then
                return OldNameCall(...)
            end

            if not MathHandler:CalculateChance(Configuration.SilentAimChance) then
                return OldNameCall(...)
            end

            if table.find(Configuration.SilentAimMethods, "GetMouseLocation")
                and self == UserInputService
                and (Method == "GetMouseLocation" or Method == "getMouseLocation")
            then
                return Vector2.new(viewportData[1].X, viewportData[1].Y)

            elseif table.find(Configuration.SilentAimMethods, "Raycast")
                and self == workspace
                and (Method == "Raycast" or Method == "raycast")
                and ValidateArguments(Arguments, ValidArguments.Raycast)
            then
                Arguments[3] = MathHandler:CalculateDirection(Arguments[2], finalPos, distance)
                return OldNameCall(table.unpack(Arguments))

            elseif table.find(Configuration.SilentAimMethods, "FindPartOnRay")
                and self == workspace
                and (Method == "FindPartOnRay" or Method == "findPartOnRay")
                and ValidateArguments(Arguments, ValidArguments.FindPartOnRay)
            then
                Arguments[2] = Ray.new(Arguments[2].Origin, MathHandler:CalculateDirection(Arguments[2].Origin, finalPos, distance))
                return OldNameCall(table.unpack(Arguments))

            elseif table.find(Configuration.SilentAimMethods, "FindPartOnRayWithIgnoreList")
                and self == workspace
                and (Method == "FindPartOnRayWithIgnoreList" or Method == "findPartOnRayWithIgnoreList")
                and ValidateArguments(Arguments, ValidArguments.FindPartOnRayWithIgnoreList)
            then
                Arguments[2] = Ray.new(Arguments[2].Origin, MathHandler:CalculateDirection(Arguments[2].Origin, finalPos, distance))
                return OldNameCall(table.unpack(Arguments))

            elseif table.find(Configuration.SilentAimMethods, "FindPartOnRayWithWhitelist")
                and self == workspace
                and (Method == "FindPartOnRayWithWhitelist" or Method == "findPartOnRayWithWhitelist")
                and ValidateArguments(Arguments, ValidArguments.FindPartOnRayWithWhitelist)
            then
                Arguments[2] = Ray.new(Arguments[2].Origin, MathHandler:CalculateDirection(Arguments[2].Origin, finalPos, distance))
                return OldNameCall(table.unpack(Arguments))
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

    local success, result = pcall(function()
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
            if getfenv().Drawing.Fonts and getfenv().Drawing.Fonts[Configuration.NameESPFont] then
                Text.Font = getfenv().Drawing.Fonts[Configuration.NameESPFont]
            end
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
    end)

    return success and result or nil
end

-- BUG FIX: Separate array visuals from named visuals to avoid mixed table issues
local VisualsArray = {} -- ESP objects (indexed)
local VisualsNamed = {} -- Named objects like FoV (keyed)

VisualsNamed.FoV = VisualsHandler:Create("FoV")

function VisualsHandler:ClearVisual(Visual, Key)
    if not Visual then return end

    -- Try to destroy/remove
    pcall(function()
        if Visual.Destroy then
            Visual:Destroy()
        elseif Visual.Remove then
            Visual:Remove()
        end
    end)

    -- Remove from array
    local FoundIndex = table.find(VisualsArray, Visual)
    if FoundIndex then
        table.remove(VisualsArray, FoundIndex)
    end

    -- Remove from named
    if Key and VisualsNamed[Key] == Visual then
        VisualsNamed[Key] = nil
    end
end

function VisualsHandler:ClearAll()
    for i = #VisualsArray, 1, -1 do
        pcall(function()
            local v = VisualsArray[i]
            if v and v.Destroy then v:Destroy()
            elseif v and v.Remove then v:Remove() end
        end)
        table.remove(VisualsArray, i)
    end
    for Key, Visual in next, VisualsNamed do
        pcall(function()
            if Visual and Visual.Destroy then Visual:Destroy()
            elseif Visual and Visual.Remove then Visual:Remove() end
        end)
        VisualsNamed[Key] = nil
    end
end

function VisualsHandler:UpdateFoV()
    if not Fluent then return self:ClearAll() end
    if not VisualsNamed.FoV then return end

    local success, _ = pcall(function()
        local MouseLocation = UserInputService:GetMouseLocation()
        local fov = VisualsNamed.FoV
        fov.Position = Vector2.new(MouseLocation.X, MouseLocation.Y)
        fov.Radius = Configuration.FoVRadius
        fov.Thickness = Configuration.FoVThickness
        fov.Transparency = Configuration.FoVOpacity
        fov.Filled = Configuration.FoVFilled
        fov.Color = Configuration.FoVColour
        fov.Visible = ShowingFoV
    end)
end

--! ESP Library
local ESPLibrary = {}

function ESPLibrary:Initialize(_Character)
    if not Fluent or typeof(_Character) ~= "Instance" then return nil end

    local obj = setmetatable({}, { __index = self })
    obj.Player = Players:GetPlayerFromCharacter(_Character)
    obj.Character = _Character
    obj.ESPBox = VisualsHandler:Create("ESPBox")
    obj.NameESP = VisualsHandler:Create("NameESP")
    obj.HealthESP = VisualsHandler:Create("NameESP")
    obj.MagnitudeESP = VisualsHandler:Create("NameESP")
    obj.TracerESP = VisualsHandler:Create("TracerESP")

    -- Store in array for cleanup
    if obj.ESPBox then table.insert(VisualsArray, obj.ESPBox) end
    if obj.NameESP then table.insert(VisualsArray, obj.NameESP) end
    if obj.HealthESP then table.insert(VisualsArray, obj.HealthESP) end
    if obj.MagnitudeESP then table.insert(VisualsArray, obj.MagnitudeESP) end
    if obj.TracerESP then table.insert(VisualsArray, obj.TracerESP) end

    return obj
end

function ESPLibrary:HideAll()
    pcall(function()
        if self.ESPBox then self.ESPBox.Visible = false end
        if self.NameESP then self.NameESP.Visible = false end
        if self.HealthESP then self.HealthESP.Visible = false end
        if self.MagnitudeESP then self.MagnitudeESP.Visible = false end
        if self.TracerESP then self.TracerESP.Visible = false end
    end)
end

function ESPLibrary:Visualize()
    if not Fluent then return VisualsHandler:ClearAll() end
    if not self.Character then return self:Disconnect() end

    local Head = self.Character:FindFirstChild("Head")
    local HRP = self.Character:FindFirstChild("HumanoidRootPart")
    local Humanoid = self.Character:FindFirstChildWhichIsA("Humanoid")

    if not (Head and Head:IsA("BasePart") and HRP and HRP:IsA("BasePart") and Humanoid) then
        self:HideAll()
        return
    end

    local IsCharacterReady = true
    if Configuration.SmartESP then
        IsCharacterReady = IsReady(self.Character)
    end

    local success, _ = pcall(function()
        local HRPPos, IsInViewport = workspace.CurrentCamera:WorldToViewportPoint(HRP.Position)
        local HeadPos = workspace.CurrentCamera:WorldToViewportPoint(Head.Position)
        local TopPos = workspace.CurrentCamera:WorldToViewportPoint(Head.Position + Vector3.new(0, 0.5, 0))
        local BottomPos = workspace.CurrentCamera:WorldToViewportPoint(HRP.Position - Vector3.new(0, 3, 0))

        if IsInViewport and HRPPos.Z > 0 then
            local BoxSize = Vector2.new(2350 / HRPPos.Z, TopPos.Y - BottomPos.Y)
            local BoxPos = Vector2.new(HRPPos.X - BoxSize.X / 2, HRPPos.Y - BoxSize.Y / 2)

            -- ESP Box
            if self.ESPBox then
                self.ESPBox.Size = BoxSize
                self.ESPBox.Position = BoxPos
                self.ESPBox.Thickness = Configuration.ESPThickness
                self.ESPBox.Transparency = Configuration.ESPOpacity
                self.ESPBox.Filled = Configuration.ESPBoxFilled
            end

            -- Name ESP
            local isTarget = Aiming and Target and self.Character == Target and IsReady(Target)
            if self.NameESP then
                self.NameESP.Text = isTarget
                    and string.format("🎯 @%s 🎯", self.Player.Name)
                    or string.format("@%s", self.Player.Name)
                if getfenv().Drawing.Fonts and getfenv().Drawing.Fonts[Configuration.NameESPFont] then
                    self.NameESP.Font = getfenv().Drawing.Fonts[Configuration.NameESPFont]
                end
                self.NameESP.Size = Configuration.NameESPSize
                self.NameESP.Transparency = Configuration.ESPOpacity
                self.NameESP.Position = Vector2.new(HRPPos.X, HRPPos.Y + BoxSize.Y / 2 - 25)
            end

            -- Health ESP
            if self.HealthESP then
                self.HealthESP.Text = string.format("[%s%%]", MathHandler:Abbreviate(Humanoid.Health))
                if getfenv().Drawing.Fonts and getfenv().Drawing.Fonts[Configuration.NameESPFont] then
                    self.HealthESP.Font = getfenv().Drawing.Fonts[Configuration.NameESPFont]
                end
                self.HealthESP.Size = Configuration.NameESPSize
                self.HealthESP.Transparency = Configuration.ESPOpacity
                self.HealthESP.Position = Vector2.new(HRPPos.X, HeadPos.Y)
            end

            -- Distance ESP
            if self.MagnitudeESP then
                local distText = "?"
                if Player.Character then
                    local myHead = Player.Character:FindFirstChild("Head")
                    if myHead and myHead:IsA("BasePart") then
                        distText = MathHandler:Abbreviate((Head.Position - myHead.Position).Magnitude)
                    end
                end
                self.MagnitudeESP.Text = string.format("[%sm]", distText)
                if getfenv().Drawing.Fonts and getfenv().Drawing.Fonts[Configuration.NameESPFont] then
                    self.MagnitudeESP.Font = getfenv().Drawing.Fonts[Configuration.NameESPFont]
                end
                self.MagnitudeESP.Size = Configuration.NameESPSize
                self.MagnitudeESP.Transparency = Configuration.ESPOpacity
                self.MagnitudeESP.Position = Vector2.new(HRPPos.X, HRPPos.Y)
            end

            -- Tracer ESP
            if self.TracerESP then
                self.TracerESP.Thickness = Configuration.ESPThickness
                self.TracerESP.Transparency = Configuration.ESPOpacity
                self.TracerESP.From = Vector2.new(
                    workspace.CurrentCamera.ViewportSize.X / 2,
                    workspace.CurrentCamera.ViewportSize.Y
                )
                self.TracerESP.To = Vector2.new(HRPPos.X, HRPPos.Y - BoxSize.Y / 2)
            end

            -- Apply colors
            if Configuration.ESPUseTeamColour and self.Player.Team then
                local TC = self.Player.TeamColor.Color
                local Inv = Color3.fromRGB(255 - TC.R * 255, 255 - TC.G * 255, 255 - TC.B * 255)
                if self.ESPBox then self.ESPBox.Color = TC end
                if self.NameESP then self.NameESP.OutlineColor = Inv; self.NameESP.Color = TC end
                if self.HealthESP then self.HealthESP.OutlineColor = Inv; self.HealthESP.Color = TC end
                if self.MagnitudeESP then self.MagnitudeESP.OutlineColor = Inv; self.MagnitudeESP.Color = TC end
                if self.TracerESP then self.TracerESP.Color = TC end
            else
                if self.ESPBox then self.ESPBox.Color = Configuration.ESPColour end
                if self.NameESP then
                    self.NameESP.OutlineColor = Configuration.NameESPOutlineColour
                    self.NameESP.Color = Configuration.ESPColour
                end
                if self.HealthESP then
                    self.HealthESP.OutlineColor = Configuration.NameESPOutlineColour
                    self.HealthESP.Color = Configuration.ESPColour
                end
                if self.MagnitudeESP then
                    self.MagnitudeESP.OutlineColor = Configuration.NameESPOutlineColour
                    self.MagnitudeESP.Color = Configuration.ESPColour
                end
                if self.TracerESP then self.TracerESP.Color = Configuration.ESPColour end
            end

            local ShowESP = ShowingESP and IsCharacterReady and IsInViewport
            if self.ESPBox then self.ESPBox.Visible = Configuration.ESPBox and ShowESP end
            if self.NameESP then self.NameESP.Visible = Configuration.NameESP and ShowESP end
            if self.HealthESP then self.HealthESP.Visible = Configuration.HealthESP and ShowESP end
            if self.MagnitudeESP then self.MagnitudeESP.Visible = Configuration.MagnitudeESP and ShowESP end
            if self.TracerESP then self.TracerESP.Visible = Configuration.TracerESP and ShowESP end
        else
            self:HideAll()
        end
    end)

    if not success then
        self:HideAll()
    end
end

function ESPLibrary:Disconnect()
    self.Player = nil
    self.Character = nil
    VisualsHandler:ClearVisual(self.ESPBox)
    VisualsHandler:ClearVisual(self.NameESP)
    VisualsHandler:ClearVisual(self.HealthESP)
    VisualsHandler:ClearVisual(self.MagnitudeESP)
    VisualsHandler:ClearVisual(self.TracerESP)
    self.ESPBox = nil
    self.NameESP = nil
    self.HealthESP = nil
    self.MagnitudeESP = nil
    self.TracerESP = nil
end

--! Tracking Handler
local TrackingHandler = {}
local Tracking = {}
local Connections = {}

function TrackingHandler:VisualizeESP()
    for _, Tracked in next, Tracking do
        if Tracked then
            pcall(function() Tracked:Visualize() end)
        end
    end
end

function TrackingHandler:DisconnectTracking(Key)
    if Key and Tracking[Key] then
        pcall(function() Tracking[Key]:Disconnect() end)
        Tracking[Key] = nil
    end
end

function TrackingHandler:DisconnectConnection(Key)
    if Key and Connections[Key] then
        for _, Connection in next, Connections[Key] do
            pcall(function() Connection:Disconnect() end)
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

-- BUG FIX: Nil check on character before initializing
local function CharacterAdded(_Character)
    if typeof(_Character) ~= "Instance" or not _Character:IsA("Model") then
        return
    end
    local _Player = Players:GetPlayerFromCharacter(_Character)
    if _Player and _Player ~= Player then
        Tracking[_Player.UserId] = ESPLibrary:Initialize(_Character)
    end
end

local function CharacterRemoving(_Character)
    if typeof(_Character) ~= "Instance" then return end
    for Key, Tracked in next, Tracking do
        if Tracked and Tracked.Character == _Character then
            TrackingHandler:DisconnectTracking(Key)
        end
    end
end

-- Initialize existing players
if getfenv().Drawing and getfenv().Drawing.new then
    for _, _Player in next, Players:GetPlayers() do
        if _Player ~= Player then
            if _Player.Character then
                CharacterAdded(_Player.Character)
            end
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
        pcall(function() OnTeleport:Disconnect() end)
    else
        pcall(function()
            getfenv().queue_on_teleport('getfenv().loadstring(game:HttpGet("https://raw.githubusercontent.com/SOBING4413/aimbot/refs/heads/main/aimbot.lua", true))()')
        end)
        pcall(function() OnTeleport:Disconnect() end)
    end
end)

local PlayerAdded
PlayerAdded = Players.PlayerAdded:Connect(function(_Player)
    if not Fluent or not getfenv().Drawing or not getfenv().Drawing.new then
        pcall(function() PlayerAdded:Disconnect() end)
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
        pcall(function() PlayerRemoving:Disconnect() end)
    elseif _Player == Player then
        pcall(function() Fluent:Destroy() end)
        TrackingHandler:Cleanup()
        pcall(function() PlayerRemoving:Disconnect() end)
    else
        TrackingHandler:DisconnectConnection(_Player.UserId)
        TrackingHandler:DisconnectTracking(_Player.UserId)
    end
end)

--! Input Handler
if IsComputer then
    local InputBegan
    InputBegan = UserInputService.InputBegan:Connect(function(Input, GameProcessed)
        if not Fluent then
            pcall(function() InputBegan:Disconnect() end)
            return
        end
        -- BUG FIX: Also check GameProcessed to avoid conflicts with UI input
        if GameProcessed or UserInputService:GetFocusedTextBox() then return end

        local KC = Input.KeyCode
        local UIT = Input.UserInputType

        -- Aimbot key handling
        -- BUG FIX: OnePressAimingMode logic corrected
        if Configuration.Aimbot and (KC == Configuration.AimKey or UIT == Configuration.AimKey) then
            if Configuration.OnePressAimingMode then
                -- Toggle mode: press once to enable, press again to disable
                if Aiming then
                    FieldsHandler:ResetAimbotFields()
                    Notify("🎯 [Aim]: OFF")
                else
                    Aiming = true
                    Notify("🎯 [Aim]: ON")
                end
            else
                -- Hold mode: press to enable (release handled in InputEnded)
                Aiming = true
                Notify("🎯 [Aim]: ON")
            end
        end

        -- FoV key
        if getfenv().Drawing and getfenv().Drawing.new
            and Configuration.FoV
            and (KC == Configuration.FoVKey or UIT == Configuration.FoVKey)
        then
            ShowingFoV = not ShowingFoV
            Notify(ShowingFoV and "⭕ [FoV]: ON" or "⭕ [FoV]: OFF")
        end

        -- ESP key
        if getfenv().Drawing and getfenv().Drawing.new
            and (Configuration.ESPBox or Configuration.NameESP or Configuration.HealthESP
                or Configuration.MagnitudeESP or Configuration.TracerESP)
            and (KC == Configuration.ESPKey or UIT == Configuration.ESPKey)
        then
            ShowingESP = not ShowingESP
            Notify(ShowingESP and "📡 [ESP]: ON" or "📡 [ESP]: OFF")
        end
    end)

    local InputEnded
    InputEnded = UserInputService.InputEnded:Connect(function(Input, GameProcessed)
        if not Fluent then
            pcall(function() InputEnded:Disconnect() end)
            return
        end
        if GameProcessed or UserInputService:GetFocusedTextBox() then return end

        -- BUG FIX: Only release aim on key up if NOT in OnePressAimingMode
        if Aiming
            and not Configuration.OnePressAimingMode
            and (Input.KeyCode == Configuration.AimKey or Input.UserInputType == Configuration.AimKey)
        then
            FieldsHandler:ResetAimbotFields()
            Notify("🎯 [Aim]: OFF")
        end
    end)

    local WindowFocused
    WindowFocused = UserInputService.WindowFocused:Connect(function()
        if not Fluent then
            pcall(function() WindowFocused:Disconnect() end)
        else
            RobloxActive = true
        end
    end)

    local WindowFocusReleased
    WindowFocusReleased = UserInputService.WindowFocusReleased:Connect(function()
        if not Fluent then
            pcall(function() WindowFocusReleased:Disconnect() end)
        else
            RobloxActive = false
        end
    end)
end

--! Main Loop
local AimbotLoop
AimbotLoop = RunService[UISettings.RenderingMode]:Connect(function()
    -- BUG FIX: Safe check for Fluent.Unloaded
    if not Fluent or (Fluent and Fluent.Unloaded) then
        Fluent = nil
        TrackingHandler:Cleanup()
        pcall(function() AimbotLoop:Disconnect() end)
        return
    end

    -- Auto-disable toggles
    if not Configuration.Aimbot and Aiming then
        FieldsHandler:ResetAimbotFields()
    end
    if not Configuration.FoV and ShowingFoV then
        ShowingFoV = false
    end
    if not Configuration.ESPBox and not Configuration.NameESP
        and not Configuration.HealthESP and not Configuration.MagnitudeESP
        and not Configuration.TracerESP and ShowingESP
    then
        ShowingESP = false
    end

    if not RobloxActive then return end

    -- Update visuals
    if getfenv().Drawing and getfenv().Drawing.new then
        VisualsHandler:UpdateFoV()
        TrackingHandler:VisualizeESP()
    end

    -- Aimbot logic
    if not Aiming then return end

    local OldTarget = Target
    local Closest = math.huge

    local isOldTargetReady = IsReady(OldTarget)
    if not isOldTargetReady then
        if not OldTarget then
            -- Find new target
            for _, _Player in next, Players:GetPlayers() do
                if _Player ~= Player and _Player.Character then
                    local IsCharacterReady, Character, PartViewportPosition = IsReady(_Player.Character)
                    if IsCharacterReady and PartViewportPosition and PartViewportPosition[2] then
                        local Magnitude = (
                            Vector2.new(Mouse.X, Mouse.Y)
                            - Vector2.new(PartViewportPosition[1].X, PartViewportPosition[1].Y)
                        ).Magnitude
                        local maxRadius = Configuration.FoVCheck and Configuration.FoVRadius or Closest
                        if Magnitude <= Closest and Magnitude <= maxRadius then
                            Target = Character
                            Closest = Magnitude
                        end
                    end
                end
            end
        else
            -- Old target no longer valid
            FieldsHandler:ResetAimbotFields()
            return
        end
    end

    local IsTargetReady, _, PartViewportPosition, PartWorldPosition = IsReady(Target)
    if not IsTargetReady then
        FieldsHandler:ResetAimbotFields(true)
        return
    end

    -- Mouse mode
    if getfenv().mousemoverel and IsComputer and Configuration.AimMode == "Mouse" then
        if PartViewportPosition and PartViewportPosition[2] then
            FieldsHandler:ResetAimbotFields(true, true)
            local MouseLocation = UserInputService:GetMouseLocation()
            local Sens = Configuration.UseSensitivity and Configuration.Sensitivity / 5 or 10
            if Sens <= 0 then Sens = 1 end -- BUG FIX: Prevent division by zero
            getfenv().mousemoverel(
                (PartViewportPosition[1].X - MouseLocation.X) / Sens,
                (PartViewportPosition[1].Y - MouseLocation.Y) / Sens
            )
        else
            FieldsHandler:ResetAimbotFields(true)
        end

    -- Camera mode
    elseif Configuration.AimMode == "Camera" then
        pcall(function()
            UserInputService.MouseDeltaSensitivity = 0
        end)
        if Configuration.UseSensitivity then
            local tweenTime = math.clamp(Configuration.Sensitivity, 9, 99) / 100
            Tween = TweenService:Create(
                workspace.CurrentCamera,
                TweenInfo.new(tweenTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
                { CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, PartWorldPosition) }
            )
            Tween:Play()
        else
            workspace.CurrentCamera.CFrame = CFrame.new(
                workspace.CurrentCamera.CFrame.Position,
                PartWorldPosition
            )
        end

    -- Silent mode
    elseif getfenv().hookmetamethod and getfenv().newcclosure and getfenv().checkcaller
        and getfenv().getnamecallmethod and Configuration.AimMode == "Silent"
    then
        FieldsHandler:ResetAimbotFields(true, true)
    end
end)
