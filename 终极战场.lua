local HttpService = cloneref(game:GetService("HttpService"))

local isfunctionhooked = clonefunction(isfunctionhooked)
if isfunctionhooked(game.HttpGet) or isfunctionhooked(getnamecallmethod) or isfunctionhooked(request) then 
    return 
end

local function verifyKey(k)
    local ok, res = pcall(function()
        return request({
            Url = "https://ouo.lat/api/verify.php",
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({key = k, time = os.time()})
        })
    end)
    
    if not ok then return false end
    
    if res.Body ~= "True" then
        return false
    end
    
    local ok2, res2 = pcall(function()
        return game:HttpGet("https://www.wtb.lat/keysystem/check-key?key="..k.."&user="..game.Players.LocalPlayer.Name)
    end)
    
    return ok2 and res2 == "success"
end

local key = ""
pcall(function() key = readfile("DyzhKey.json") end)
if key ~= "" then
    if verifyKey(key) then
        print('验证完成')
    else
        return
    end
end

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/dream77239/china-ui/refs/heads/main/China%20ui.lua"))()
local Window = WindUI:CreateWindow({
    Title = "终极战场",
    Icon = "sword",
    IconThemed = true,
    Author = "Sybsy制作",
    Folder = "CloudHub",
    Size = UDim2.fromOffset(500, 400),
    Transparent = true,
    Theme = "Dark",
    User = {
        Enabled = true,
        Callback = function() end,
        Anonymous = false
    },
    SideBarWidth = 200,
    ScrollBarEnabled = true
})
Window:Tag({
    Title = "塔菲喵喵喵喵",
    Color = Color3.fromHex("#30ff6a")
})

local TimeTag = Window:Tag({
    Title = "--:--",
    Radius = 999,
    Color = Color3.fromRGB(255, 255, 255),
})

task.spawn(function()
	while true do
		local now = os.date("*t")
		local hours = string.format("%02d", now.hour)
		local minutes = string.format("%02d", now.min)
		
		TimeTag:SetTitle(hours .. ":" .. minutes)
		task.wait(0.06)
	end
end)
local LangTab = Window:Tab({
    Title = "选择语言/Select Language",
    Icon = "smile",
    Locked = false,
})
local function createChineseUI()
local notTab = Window:Tab({
    Title = "公告",
    Icon = "",
    Locked = false,
})
notTab:Paragraph({
    Title = "sybsy信息",
    Desc = "sybsy",
    Image = "file-warning",
    Color = "Red",
    ImageSize = 40, 
    ThumbnailSize = 120
})
local Tab = Window:Tab({
    Title = "功能",
    Icon = "sword",
    Locked = false,
})
local HttpService = game:GetService("HttpService")

local InviteCode = "E6meCtvdZ"
local DiscordAPI = "https://discord.com/api/v10/invites/" .. InviteCode .. "?with_counts=true&with_expiration=true"

local Response = HttpService:JSONDecode(WindUI.Creator.Request({
    Url = DiscordAPI,
    Method = "GET"
}).Body)

if Response and Response.guild then
    local iconUrl = Response.guild.icon and ("https://cdn.discordapp.com/icons/" .. Response.guild.id .. "/" .. Response.guild.icon .. ".png?size=1024") or "rbxassetid://129260712070622"

    Tab:Paragraph({
        Title = Response.guild.name,
        Desc =
            ' <font color="#52525b">●</font> 总人数: ' .. tostring(Response.approximate_member_count) ..
            '\n <font color="#16a34a">●</font> 在线人数: ' .. tostring(Response.approximate_presence_count),
        Image = iconUrl,
        ImageSize = 42,
    })
else
    warn("Discord API Error: ", HttpService:JSONEncode(Response))
end
Tab:Button({
    Title = "复制QQ群链接",
    Description = "复制链接加入我的TF群",
    Callback = function()
        setclipboard("https://qun.qq.com/universal-share/share?ac=1&authKey=Y1pfa3iAOnJsHBtBfXCxO51jDmEYCCJZ3W9q8pLMZPenFvDSGAdxJ3KkcPkHR4e7&busi_data=eyJncm91cENvZGUiOiI0OTY0MTY4MDAiLCJ0b2tlbiI6IkFKTGxiTlRUMEFIYlhwMHdmYWNMNnV0SXpkK3ZjZWgrWlp3TFI3emY0QjNKWUpQbE5yS3hYMi94YTN1am03TFIiLCJ1aW4iOiIzMTE2NzgxMTY3In0%3D&data=oQuMEbzXCK1zMikSSJkatrFnAR7SnbNUSs7IOUEp9sgKQWLNgHisjFVUDpn0qKgbS17sTONLDXLm7fxt_yEv_w&svctype=4&tempid=h5_group_info")
    end
})
Tab:Button({
    Title = "篡改",
    Desc = "玩的时候第一先开启这个功能一定要",
    Callback = function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/dream77239/ubg-script/refs/heads/main/%E6%8B%A6%E6%88%AA.txt"))()
    end
})
local fakeBlockEnabled = false
local loopRunning = false

Tab:Toggle({
    Title = "假防(关闭功能后按一次防御即可取消假防)",
    Value = false,
    Callback = function(state)
        fakeBlockEnabled = state

        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local BlockRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Combat"):WaitForChild("Block")
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()

        local function enableBlock()
            pcall(function()
                BlockRemote:FireServer(true)
            end)
        end

        if fakeBlockEnabled then
            enableBlock()
        end

        if not loopRunning then
            loopRunning = true
            task.spawn(function()
                while true do
                    task.wait(0.01)
                    if fakeBlockEnabled then
                        local success, isBlocking = pcall(function()
                            return character:GetAttribute("IsBlocking")
                        end)
                        if success and not isBlocking then
                            enableBlock()
                        end
                    end
                end
            end)
        end
    end
})

local defaultCooldown = game:GetService("ReplicatedStorage").Settings.Cooldowns.Dash.Value

Tab:Toggle({
    Title = "侧闪无冷却",
    Value = false,
    Callback = function(state)
        local dashCooldown = game:GetService("ReplicatedStorage").Settings.Cooldowns.Dash
        if state then
            dashCooldown.Value = 1
        else
            dashCooldown.Value = defaultCooldown
        end
    end
})
local defaultMeleeCooldown = game:GetService("ReplicatedStorage").Settings.Cooldowns.Melee.Value

Tab:Toggle({
    Title = "近战无冷却",
    Value = false,
    Callback = function(state)
        local meleeCooldown = game:GetService("ReplicatedStorage").Settings.Cooldowns.Melee
        if state then
            meleeCooldown.Value = 1
        else
            meleeCooldown.Value = defaultMeleeCooldown
        end
    end
})
local rs = game:GetService("ReplicatedStorage")
local settings = rs.Settings

local defaultAbility = settings.Cooldowns.Ability.Value
Tab:Toggle({
    Title = "技能无冷却(仅宿傩角色)",
    Value = false,
    Callback = function(state)
        settings.Cooldowns.Ability.Value = state and 1 or defaultAbility
    end
})

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local noSlowdownsToggle = ReplicatedStorage.Settings.Toggles.NoSlowdowns

local defaultValue = false

Tab:Toggle({
    Title = "无减速效果",
    Value = noSlowdownsToggle.Value,
    Callback = function(state)
        if state then
            noSlowdownsToggle.Value = true
        else
            noSlowdownsToggle.Value = defaultValue
        end
    end
})

local defaultDisableHitStun = settings.Toggles.DisableHitStun.Value
Tab:Toggle({
    Title = "取消被攻击硬直",
    Value = false,
    Callback = function(state)
        settings.Toggles.DisableHitStun.Value = state
    end
})

local defaultDisableIntros = settings.Toggles.DisableIntros.Value
Tab:Toggle({
    Title = "跳过角色开场动作",
    Value = false,
    Callback = function(state)
        settings.Toggles.DisableIntros.Value = state
    end
})

local defaultNoStunOnMiss = settings.Toggles.NoStunOnMiss.Value
Tab:Toggle({
    Title = "普攻无僵直",
    Value = false,
    Callback = function(state)
        settings.Toggles.NoStunOnMiss.Value = state
    end
})

local defaultRagdollTimer = settings.Multipliers.RagdollTimer.Value
Tab:Toggle({
    Title = "被别人击倒不会变成布娃娃",
    Value = false,
    Callback = function(state)
        settings.Multipliers.RagdollTimer.Value = state and 0.5 or defaultRagdollTimer
    end
})

local defaultUltimateTimer = settings.Multipliers.UltimateTimer.Value
Tab:Toggle({
    Title = "延长大招时间",
    Value = false,
    Callback = function(state)
        settings.Multipliers.UltimateTimer.Value = state and 100000 or defaultUltimateTimer
    end
})

local defaultInstantTransformation = settings.Toggles.InstantTransformation.Value
Tab:Toggle({
    Title = "秒开大",
    Value = false,
    Callback = function(state)
        settings.Toggles.InstantTransformation.Value = state
    end
})
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local Ping = player:WaitForChild("Info"):WaitForChild("Ping")

local loop

Tab:Toggle({
    Title = "ping乱码",
    Value = false,
    Callback = function(state)
        if state then
            loop = task.spawn(function()
                while state do
                    for i = 0, 999, 25 do
                        if not state then break end
                        Ping.Value = i
                        task.wait(0.03)
                    end
                    for i = 999, 0, -25 do
                        if not state then break end
                        Ping.Value = i
                        task.wait(0.03)
                    end
                end
            end)
        else
            if loop then
                task.cancel(loop)
                loop = nil
            end
        end
    end
})
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MeleeDamage = ReplicatedStorage:WaitForChild("Settings"):WaitForChild("Multipliers"):WaitForChild("MeleeDamage")

MeleeDamage.Value = 100

Tab:Toggle({
    Title = "一拳倒地",
    Value = false,
    Callback = function(state)
        if state then
            MeleeDamage.Value = 1000000
        else
            MeleeDamage.Value = 100
        end
    end
})
Tab:Toggle({
    Title = "一拳击飞",
    Value = false,
    Callback = function(state)
        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local RunService = game:GetService("RunService")

        local LocalPlayer = Players.LocalPlayer
        local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

        local RagdollPower = ReplicatedStorage:WaitForChild("Settings"):WaitForChild("Multipliers"):WaitForChild("RagdollPower")

        local maxTeleportDistance = 50
        local lastPosition = HumanoidRootPart.Position
        local connection

        if state then
            RagdollPower.Value = 10000

            connection = RunService.RenderStepped:Connect(function()
                -- refresh character in case of reset
                if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
                    lastPosition = HumanoidRootPart.Position
                end

                local currentPos = HumanoidRootPart.Position
                local distance = (currentPos - lastPosition).Magnitude

                if distance > maxTeleportDistance then
                    HumanoidRootPart.CFrame = CFrame.new(lastPosition)
                else
                    lastPosition = currentPos
                end
            end)
        else
            RagdollPower.Value = 100
            if connection then
                connection:Disconnect()
                connection = nil
            end
        end
    end
})
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local wallCombo = ReplicatedStorage.Settings.Cooldowns.WallCombo

Tab:Toggle({
    Title = "墙打无冷却",
    Value = false,
    Callback = function(state)
        if state then
            wallCombo.Value = 0
            print("WallCombo cooldown set to 0")
        else
            wallCombo.Value = 100
            print("WallCombo cooldown reset to 100")
        end
    end
})
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local wall = nil
pcall(function()
    wall = workspace.Map.Structural.Terrain:GetChildren()[5]:GetChildren()[12]
end)

if not wall then
    wall = Instance.new("Part")
    wall.Parent = workspace
end

wall.Size = Vector3.new(12,6,2)
wall.Transparency = 0.6
wall.Material = Enum.Material.SmoothPlastic
wall.Anchored = true
wall.CanCollide = true
wall.CFrame = wall.CFrame or CFrame.new(0,5,0)

if getconnections then
    for _, conn in pairs(getconnections(wall.AncestryChanged)) do
        conn:Disable()
    end
end

local mt = getrawmetatable(game)
setreadonly(mt,false)
local old = mt.__namecall
mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if self == wall and method == "Destroy" then
        return
    end
    return old(self, ...)
end)
setreadonly(mt,true)

local followConnection = nil
Tab:Toggle({
    Title = "随处墙打",
    Value = false,
    Callback = function(state)
        if state then
            if not followConnection then
                followConnection = RunService.RenderStepped:Connect(function()
                    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        wall.CFrame = hrp.CFrame * CFrame.new(0,0,-8)
                    end
                end)
            end
        else
            if followConnection then
                followConnection:Disconnect()
                followConnection = nil
            end
        end
    end
})
local originalData = {}
local skyBackup = nil

Tab:Toggle({
    Title = "防卡",
    Value = false,
    Callback = function(state)
        if state then
            originalData = {}
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Explosion") then
                    originalData[v] = v.Enabled
                    v.Enabled = false
                elseif v:IsA("Decal") or v:IsA("Texture") then
                    originalData[v] = v.Transparency
                    v.Transparency = 1
                elseif v:IsA("MeshPart") or v:IsA("UnionOperation") or v:IsA("Part") then
                    if v.Name ~= "HumanoidRootPart" then
                        originalData[v] = v.Material
                        v.Material = Enum.Material.SmoothPlastic
                    end
                elseif v:IsA("SurfaceGui") or v:IsA("BillboardGui") or v:IsA("Beam") then
                    if v:IsA("Beam") then
                        originalData[v] = v.Enabled
                        v.Enabled = false
                    else
                        originalData[v] = v.Enabled ~= nil and v.Enabled or true
                        if v.Enabled ~= nil then
                            v.Enabled = false
                        end
                    end
                end
            end
            originalData["GlobalShadows"] = game.Lighting.GlobalShadows
            originalData["FogEnd"] = game.Lighting.FogEnd
            game.Lighting.GlobalShadows = false
            game.Lighting.FogEnd = 9e9
            local sky = game.Lighting:FindFirstChildOfClass("Sky")
            if sky then
                skyBackup = sky:Clone()
                sky:Destroy()
            end
            local newSky = Instance.new("Sky")
            newSky.SkyboxBk = ""
            newSky.SkyboxDn = ""
            newSky.SkyboxFt = ""
            newSky.SkyboxLf = ""
            newSky.SkyboxRt = ""
            newSky.SkyboxUp = ""
            newSky.SunAngularSize = 0
            newSky.MoonAngularSize = 0
            newSky.Parent = game.Lighting
            game.Lighting.Ambient = Color3.fromRGB(128,128,128)
            game.Lighting.OutdoorAmbient = Color3.fromRGB(128,128,128)
        else
            for obj, value in pairs(originalData) do
                if typeof(obj) == "Instance" and obj.Parent then
                    if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Explosion") then
                        obj.Enabled = value
                    elseif obj:IsA("Decal") or obj:IsA("Texture") then
                        obj.Transparency = value
                    elseif obj:IsA("MeshPart") or obj:IsA("UnionOperation") or obj:IsA("Part") then
                        obj.Material = value
                    elseif obj:IsA("SurfaceGui") or obj:IsA("BillboardGui") or obj:IsA("Beam") then
                        if obj:IsA("Beam") then
                            obj.Enabled = value
                        elseif obj.Enabled ~= nil then
                            obj.Enabled = value
                        end
                    end
                elseif obj == "GlobalShadows" then
                    game.Lighting.GlobalShadows = value
                elseif obj == "FogEnd" then
                    game.Lighting.FogEnd = value
                end
            end
            if skyBackup then
                local currentSky = game.Lighting:FindFirstChildOfClass("Sky")
                if currentSky then
                    currentSky:Destroy()
                end
                skyBackup.Parent = game.Lighting
                skyBackup = nil
            end
            originalData = {}
        end
    end
})
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Camera = workspace.CurrentCamera

local clone, platform, originalCFrame, originalCameraSubject

local function CreatePlatform(position)
    local part = Instance.new("Part")
    part.Size = Vector3.new(10, 1, 10)
    part.Position = position - Vector3.new(0, 3, 0)
    part.Anchored = true
    part.CanCollide = true
    part.Transparency = 0.5
    part.Parent = workspace
    return part
end

local function CreateClone()
    local newClone = Character:Clone()
    for _, v in ipairs(newClone:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Transparency = 0.5
        end
    end
    newClone.Parent = workspace
    return newClone
end

local function ToggleInvisibility(state)
    if state then
        originalCFrame = HumanoidRootPart.CFrame
        HumanoidRootPart.CFrame = HumanoidRootPart.CFrame + Vector3.new(0, -50, 0)
        platform = CreatePlatform(HumanoidRootPart.Position)
        
        task.wait(1)
        
        clone = CreateClone()
        clone:MoveTo(originalCFrame.Position)
        Camera.CameraSubject = clone:FindFirstChildWhichIsA("Humanoid")
        LocalPlayer.Character = clone
    else
        if clone then
            clone:Destroy()
            clone = nil
        end
        
        if platform then
            platform:Destroy()
            platform = nil
        end
        
        if originalCFrame then
            HumanoidRootPart.CFrame = originalCFrame
            originalCFrame = nil
        end
        
        Camera.CameraSubject = Character:FindFirstChildWhichIsA("Humanoid")
        LocalPlayer.Character = Character
    end
end

Tab:Toggle({
    Title = "隐身",
    Value = false,
    Callback = ToggleInvisibility
})
local v_u_1 = require(game.ReplicatedStorage:WaitForChild("Core"))
local v155 = game.Players.LocalPlayer:WaitForChild("Data"):WaitForChild("Character")
local v156 = game.ReplicatedStorage.Characters:FindFirstChild(v155.Value):FindFirstChild("WallCombo")
local v158 = Vector3.new(7, 5, 7)
local v159 = CFrame.new(0, 0, 0)
local v160 = v_u_1.Get("Character", "FullCustomReplication").GetCFrame()
local v163 = game.Players.LocalPlayer.Character

local v167 = {
    ["Size"] = v158,
    ["Offset"] = v159,
    ["CustomValidation"] = function()
        return true
    end,
}

local v_u_168 = v_u_1.Get("Combat", "Hit").Box(nil, v163, v167)
local v58 = v156:GetAttribute("Interrupt")

function Run(p_u_7, p8, p_u_9, p10, ...)
    local v_u_11 = p_u_7 and p_u_7:FindFirstChild("Humanoid") or p_u_7
    local v_u_12 = p_u_7 and p_u_7:FindFirstChild("HumanoidRootPart") or p_u_7
    if p_u_7 and (v_u_11 and v_u_12) then
        local v_u_13 = p_u_7 == game.Players.LocalPlayer.Character
        local v_u_17 = p8
        v_u_1.Get("Combat", "Cancel").Init(v_u_17, p_u_9, p_u_7)
        v_u_1.Get("Combat", "Cancel").Set(v_u_17, p_u_9, p_u_7, "Timeout")
        local v_u_36 = { ... }
        task.spawn(function()
            local v37 = {}
            local v38 = v_u_36
            for i, v in ipairs({ p_u_7, v_u_11, v_u_12, v_u_13, p_u_9 }) do
                v37[i] = v
            end
            for i, v in ipairs(v38) do
                v37[#v37 + 1] = v
            end
            v_u_1.Get("Cosmetics", "KillEmote").RunAfter(v_u_17, table.unpack(v37))
        end)
    end
end

local originPos = v160.Position
local rs = game:GetService("RunService")
local running = false

Tab:Toggle({
    Title = "杀戮光环",
    Value = false,
    Callback = function(state)
        running = state
        if running then
            rs:BindToRenderStep("KillAura", Enum.RenderPriority.Input.Value, function()
                local pos = originPos + v160.LookVector * 6
                for i = 1, 4 do
                    task.spawn(function()
                        v_u_1.Library("Remote").Send("Ability", v156, 9e9, v58, v_u_168, pos)
                        Run(game.Players.LocalPlayer.Character, v156, 9e9, v58, v_u_168, pos)
                    end)
                end
            end)
        else
            rs:UnbindFromRenderStep("KillAura")
        end
    end
})
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local wallComboSpamming = false
local wallComboHeartbeat = nil
local wallComboPerFrame = 2
local wallComboKeybind = Enum.KeyCode.E

local core = require(ReplicatedStorage.Core)
local chars = ReplicatedStorage.Characters
local char = LocalPlayer.Data.Character

local function executeWallCombo()
    local head = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
    if not head then return end

    local res = core.Get("Combat","Hit").Box(nil, LocalPlayer.Character, {Size = Vector3.new(50,50,50)})
    if res then
        local success, err = pcall(core.Get("Combat","Ability").Activate, chars[char.Value].WallCombo, res, head.Position + Vector3.new(0,0,2.5))
        if not success then
            warn(err)
        end
    end
end

local function updateWallComboHeartbeat()
    if wallComboHeartbeat then
        wallComboHeartbeat:Disconnect()
        wallComboHeartbeat = nil
    end
    if wallComboSpamming then
        wallComboHeartbeat = RunService.Heartbeat:Connect(function()
            for i = 1, wallComboPerFrame do
                executeWallCombo()
            end
        end)
    end
end

UserInputService.InputBegan:Connect(function(input, isProcessed)
    if isProcessed then return end
    if input.KeyCode == wallComboKeybind then
        executeWallCombo()
    end
end)

Tab:Toggle({
    Title = "墙打秒杀",
    Value = false,
    Callback = function(state)
        wallComboSpamming = state
        updateWallComboHeartbeat()
    end
})
Tab:Button({
    Title = "删除墙打特效",
    Desc = "点了该功能就无法恢复墙打特效",
    Callback = function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local paths = {
            ReplicatedStorage.Characters.Gon.WallCombo.GonWallCombo.Center,
            ReplicatedStorage.Characters.Gon.WallCombo.GonWallCombo.Explosion,
            ReplicatedStorage.Characters.Gon.WallCombo.GonIntroHands,
            ReplicatedStorage.Characters.Mob.WallCombo.MobWallCombo.Center,
            ReplicatedStorage.Characters.Nanami.WallCombo.NanamiWallCombo.Center,
            ReplicatedStorage.Characters.Stark.WallCombo.StarkWallCombo.Center,
            ReplicatedStorage.Characters.Sukuna.WallCombo.SukunaTransformWallCombo,
            ReplicatedStorage.Characters.Sukuna.WallCombo.SukunaWallCombo
        }

        for _, obj in ipairs(paths) do
            if obj and obj:IsA("Instance") then
                for _, child in ipairs(obj:GetChildren()) do
                    child:Destroy()
                end
            end
        end
    end
})
Tab:Button({
    Title = "删除击杀表情特效",
    Desc = "点击删除击杀表情的部分特效,不可恢复",
    Callback = function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local KillEmote = ReplicatedStorage:WaitForChild("Cosmetics"):WaitForChild("KillEmote")

        local function removeEffects(obj)
            for _, child in ipairs(obj:GetChildren()) do
                if child:IsA("ParticleEmitter") 
                or child:IsA("Trail") 
                or child:IsA("Beam") 
                or child:IsA("Fire") 
                or child:IsA("Smoke") 
                or child:IsA("Sparkles") 
                or child:IsA("Light") then
                    child:Destroy()
                else
                    removeEffects(child)
                end
            end
        end

        removeEffects(KillEmote)
        print("KillEmote 特效已删除（保留本体）")
    end
})
 local ReplicatedStorage = game:GetService("ReplicatedStorage")
local multiUseCutscenesToggle = ReplicatedStorage.Settings.Toggles.MultiUseCutscenes

local defaultValue = false

Tab:Toggle({
    Title = "艾斯帕大招技能多次使用(全角色通用)",
    Value = multiUseCutscenesToggle.Value,
    Callback = function(state)
        if state then
            multiUseCutscenesToggle.Value = true
        else
            multiUseCutscenesToggle.Value = defaultValue
        end
    end
})
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local tpwalking = false
local tpwalkSpeed = 100

Tab:Toggle({
    Title = "速度",
    Value = false,
    Callback = function(state)
        tpwalking = state
        if state then
            spawn(function()
                while tpwalking do
                    local chr = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                    local hrp = chr:FindFirstChild("HumanoidRootPart")
                    local hum = chr:FindFirstChildWhichIsA("Humanoid")
                    local delta = RunService.Heartbeat:Wait()
                    if hrp and hum and hum.MoveDirection.Magnitude > 0 then
                        hrp.CFrame = hrp.CFrame + (hum.MoveDirection * tpwalkSpeed * delta)
                    end
                end
            end)
        end
    end
})

Tab:Slider({
    Title = "速度调节",
    Value = {
        Min = 0,
        Max = 250,
        Default = tpwalkSpeed,
    },
    Callback = function(value)
        tpwalkSpeed = value
    end
})
Tab:Slider({
    Title = "冲刺加速(默认值100)",
    Value = {
        Min = 0,
        Max = 1000,
        Default = 100,
    },
    Callback = function(value)
        game:GetService("ReplicatedStorage").Settings.Multipliers.DashSpeed.Value = value
    end
})

Tab:Slider({
    Title = "跳跃增强(默认值100)",
    Value = {
        Min = 0,
        Max = 1000,
        Default = 100,
    },
    Callback = function(value)
        game:GetService("ReplicatedStorage").Settings.Multipliers.JumpHeight.Value = value
    end
})

Tab:Slider({
    Title = "攻击加速(默认值100)",
    Value = {
        Min = 0,
        Max = 1000,
        Default = 100,
    },
    Callback = function(value)
        game:GetService("ReplicatedStorage").Settings.Multipliers.MeleeSpeed.Value = value
    end
})
local Players = game:GetService("Players")
local Tab = Window:Tab({
    Title = "碰撞箱扩大",
    Icon = "box",
    Locked = false,
})

local expansionMethod = "Add"
local hitboxX, hitboxY, hitboxZ = 0, 0, 0
local isHitboxExpanded = false
local hitModuleTable = nil
local originalBox = nil
local sizeModifier = Vector3.new(0, 0, 0)

local function setupHitboxHook()
    if hitModuleTable and hitModuleTable._boxSizeModifierHookInstalled then
        print("Hitbox hook already installed.")
        return true
    end
    
    local player = Players.LocalPlayer
    local playerScripts = player:WaitForChild("PlayerScripts")
    local combatFolder = playerScripts:WaitForChild("Combat")
    local hitModule = combatFolder:WaitForChild("Hit")
    
    hitModuleTable = require(hitModule)
    originalBox = hitModuleTable.Box
    
    hitModuleTable.Box = function(...)
        local args = {...}
        if args[3] and typeof(args[3]) == "table" then
            local config = args[3]
            if config.Size and typeof(config.Size) == "Vector3" then
                if not config._originalSize then
                    config._originalSize = config.Size
                end
                if expansionMethod == "Set" then
                    config.Size = sizeModifier
                elseif expansionMethod == "Add" then
                    config.Size = config._originalSize + sizeModifier
                end
            end
            return originalBox(...)
        else
            return originalBox(...)
        end
    end
    hitModuleTable._boxSizeModifierHookInstalled = true
    return true
end

local function applySigmaHitbox(x, y, z)
    if not setupHitboxHook() then
        warn("Failed to setup hitbox hook!")
        return
    end
    sizeModifier = Vector3.new(x, y, z)
    print("Sigma hitbox expansion applied:", sizeModifier)
end

Tab:Input({
    Title = "X 轴向量",
    Value = "0",
    InputIcon = "bird",
    Type = "Input",
    Placeholder = "输入一个数字...",
    Callback = function(input)
        hitboxX = tonumber(input) or 0
        print("Hitbox X vector set to:", hitboxX)
    end
})

Tab:Input({
    Title = "Y 轴向量",
    Value = "0",
    InputIcon = "bird",
    Type = "Input",
    Placeholder = "输入一个数字...",
    Callback = function(input)
        hitboxY = tonumber(input) or 0
        print("Hitbox Y vector set to:", hitboxY)
    end
})

Tab:Input({
    Title = "Z 轴向量",
    Value = "0",
    InputIcon = "bird",
    Type = "Input",
    Placeholder = "输入一个数字...",
    Callback = function(input)
        hitboxZ = tonumber(input) or 0
        print("Hitbox Z vector set to:", hitboxZ)
    end
})

Tab:Dropdown({
    Title = "扩展方法",
    Values = {"Add", "Set"},
    Value = "Add",
    Multi = false,
    AllowNone = false,
    Callback = function(option)
        expansionMethod = option
        print("Hitbox method set to:", expansionMethod)
    end
})

Tab:Button({
    Title = "应用碰撞箱修改",
    Desc = nil,
    Locked = false,
    Callback = function()
        applySigmaHitbox(hitboxX, hitboxY, hitboxZ)
        isHitboxExpanded = true
    end
})

Tab:Button({
    Title = "小幅扩展 (+5范围)",
    Desc = nil,
    Locked = false,
    Callback = function()
        hitboxX, hitboxY, hitboxZ = 5, 5, 5
        applySigmaHitbox(hitboxX, hitboxY, hitboxZ)
        isHitboxExpanded = true
    end
})

Tab:Button({
    Title = "中幅扩展 (+10范围)",
    Desc = nil,
    Locked = false,
    Callback = function()
        hitboxX, hitboxY, hitboxZ = 10, 10, 10
        applySigmaHitbox(hitboxX, hitboxY, hitboxZ)
        isHitboxExpanded = true
    end
})

Tab:Button({
    Title = "大幅扩展 (+20范围)",
    Desc = nil,
    Locked = false,
    Callback = function()
        hitboxX, hitboxY, hitboxZ = 20, 20, 20
        applySigmaHitbox(hitboxX, hitboxY, hitboxZ)
        isHitboxExpanded = true
    end
})
local lightningCharacterSwapTab = Window:Tab({
    Title = "快速切换角色",
    Icon = "bird",
    Locked = false,
})

local lastPosition

local function getHumanoidRootPart()
    local character = LocalPlayer.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function savePosition()
    local rootPart = getHumanoidRootPart()
    if rootPart then
        lastPosition = rootPart.CFrame
    end
end

local function handleKeyPress(characterName)
    savePosition()
    
    local rootPart = getHumanoidRootPart()
    if rootPart then
        rootPart.CFrame = CFrame.new(1011.1289672851562, -1009.359588623046875, 116.37605285644531)
    end

    ReplicatedStorage.Remotes.Character.ChangeCharacter:FireServer(characterName)

    local groundY = workspace.Map.Structural.Ground:GetChildren()[21].Position.Y
    repeat task.wait() until getHumanoidRootPart() and getHumanoidRootPart().Position.Y > groundY
    task.wait(0.15)

    local newRootPart = getHumanoidRootPart()
    if newRootPart and lastPosition then
        repeat
            newRootPart.CFrame = lastPosition
            task.wait(0.1)
        until (newRootPart.Position - lastPosition.Position).Magnitude < 10
    end
end

lightningCharacterSwapTab:Button({
    Title = "快速切换成小杰",
    Locked = false,
    Callback = function() handleKeyPress("Gon") end
})

lightningCharacterSwapTab:Button({
    Title = "快速切换成被诅咒的导师",
    Locked = false,
    Callback = function() handleKeyPress("Nanami") end
})

lightningCharacterSwapTab:Button({
    Title = "快速切换成沉默的艾丝帕",
    Locked = false,
    Callback = function() handleKeyPress("Mob") end
})
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local core = require(ReplicatedStorage:WaitForChild("Core"))
local Character = LocalPlayer.Character
local HumanoidRootPart = Character and Character:WaitForChild("HumanoidRootPart")
local orbitToggle = nil
local fakeWallToggle = nil
local serverStatus = "goodstate"

local forceKillEmoteTab = Window:Tab({
    Title = "击杀表情功能",
    Icon = "smile",
    Locked = false,
})

local killEmotes = {}
local isAuraMode = false
local isSpammingSelectedEmote = false
local auraDelay = 0.5
local spamDelay = 0.5
local selectedEmote = ""
local selectedKeybind = Enum.KeyCode.G
local emoteDropdown

local function getRoot(char)
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function useEmote(emoteName)
    local emoteModule = ReplicatedStorage:WaitForChild("Cosmetics"):WaitForChild("KillEmote"):FindFirstChild(emoteName)
    local myRoot = getRoot(LocalPlayer.Character)
    if not myRoot then return end
    local closestTarget = nil
    local shortestDistance = math.huge
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetRoot = getRoot(player.Character)
            if targetRoot then
                local distance = (myRoot.Position - targetRoot.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestTarget = player.Character
                end
            end
        end
    end
    if closestTarget and emoteModule then
        task.spawn(function()
            _G.KillEmote = true
            pcall(function()
                if core and core.Get then
                    core.Get("Combat", "Ability").Activate(emoteModule, closestTarget)
                end
            end)
            _G.KillEmote = false
        end)
    end
end

local function useRandomEmote()
    if #killEmotes > 0 then
        local randomEmote = killEmotes[math.random(1, #killEmotes)]
        useEmote(randomEmote)
    end
end

task.spawn(function()
    while true do
        if isAuraMode then
            useRandomEmote()
            task.wait(auraDelay)
        else
            task.wait(0.1)
        end
    end
end)

task.spawn(function()
    while true do
        if isSpammingSelectedEmote and selectedEmote ~= "" then
            useEmote(selectedEmote)
            task.wait(spamDelay)
        else
            task.wait(0.1)
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, isGameProcessed)
    if isGameProcessed then return end
    if input.KeyCode == selectedKeybind and selectedEmote ~= "" then
        useEmote(selectedEmote)
    end
end)

local function createOrUpdateEmoteDropdown(emoteList)
    local values = emoteList
    if not values or #values == 0 then
        values = {"No emotes found"}
    end
    emoteDropdown = forceKillEmoteTab:Dropdown({
        Title = "击杀表情功能(要靠近别人)",
        Values = values,
        Multi = false,
        AllowNone = false,
        Callback = function(option)
            if option ~= "No emotes found" then
                selectedEmote = option
                useEmote(option)
            end
        end
    })
end

forceKillEmoteTab:Button({
    Title = "刷新击杀表情",
    Desc = "刷新可用的击杀表情",
    Callback = function()
        local currentEmotes = {}
        for _, emote in pairs(ReplicatedStorage:WaitForChild("Cosmetics"):WaitForChild("KillEmote"):GetChildren()) do
            table.insert(currentEmotes, emote.Name)
        end
        killEmotes = currentEmotes
        createOrUpdateEmoteDropdown(killEmotes)
    end
})

for _, emote in pairs(ReplicatedStorage:WaitForChild("Cosmetics"):WaitForChild("KillEmote"):GetChildren()) do
    table.insert(killEmotes, emote.Name)
end

createOrUpdateEmoteDropdown(killEmotes)

forceKillEmoteTab:Toggle({
    Title = "击杀表情光环",
    Desc = "对旁边的人持续使用随机的击杀表情",
    Icon = "bird",
    Type = "Checkbox",
    Default = false,
    Callback = function(isEnabled)
        isAuraMode = isEnabled
    end
})

forceKillEmoteTab:Slider({
    Title = "击杀表情光环间隔",
    Step = 0.01,
    Value = { Min = 0.01, Max = 5.0, Default = 0.5 },
    Callback = function(value)
        auraDelay = value
    end
})

forceKillEmoteTab:Toggle({
    Title = "持续发送你选择的表情",
    Desc = "持续发送当前选择的表情",
    Icon = "bird",
    Type = "Checkbox",
    Default = false,
    Callback = function(isEnabled)
        isSpammingSelectedEmote = isEnabled
    end
})

forceKillEmoteTab:Slider({
    Title = "调整你选择的表情速度",
    Step = 0.01,
    Value = { Min = 0.01, Max = 5.0, Default = 0.5 },
    Callback = function(value)
        spamDelay = value
    end
})

local emoteKeybindOptions = { "G", "F", "H", "J", "K", "L", "Z", "X", "C", "V", "B", "N", "M", "Q", "E", "R", "T", "Y", "U", "I", "O", "P" }
local emoteKeybindMap = {
    ["G"] = Enum.KeyCode.G, ["F"] = Enum.KeyCode.F, ["H"] = Enum.KeyCode.H,
    ["J"] = Enum.KeyCode.J, ["K"] = Enum.KeyCode.K, ["L"] = Enum.KeyCode.L,
    ["Z"] = Enum.KeyCode.Z, ["X"] = Enum.KeyCode.X, ["C"] = Enum.KeyCode.C,
    ["V"] = Enum.KeyCode.V, ["B"] = Enum.KeyCode.B, ["N"] = Enum.KeyCode.N,
    ["M"] = Enum.KeyCode.M, ["Q"] = Enum.KeyCode.Q, ["E"] = Enum.KeyCode.E,
    ["R"] = Enum.KeyCode.R, ["T"] = Enum.KeyCode.T, ["Y"] = Enum.KeyCode.Y,
    ["U"] = Enum.KeyCode.U, ["I"] = Enum.KeyCode.I, ["O"] = Enum.KeyCode.O,
    ["P"] = Enum.KeyCode.P
}

forceKillEmoteTab:Dropdown({
    Title = "快捷键设置",
    Values = emoteKeybindOptions,
    Value = "G",
    Multi = false,
    AllowNone = false,
    Callback = function(option)
        selectedKeybind = emoteKeybindMap[option]
    end
})

forceKillEmoteTab:Button({
    Title = "随机用一个击杀表情",
    Desc = "字面意思",
    Locked = false,
    Callback = function()
        useRandomEmote()
    end
})
local MusicTab = Window:Tab({
    Title = "音乐",
    Icon = "music",
    Locked = false,
})

local SoundService = game:GetService("SoundService")

local music1 = Instance.new("Sound")
music1.SoundId = "rbxassetid://107990547300911"
music1.Volume = 1
music1.Looped = true
music1.Parent = SoundService
MusicTab:Toggle({
    Title = "因果",
    Value = false,
    Callback = function(state)
        if state then music1:Play() else music1:Stop() end
    end
})

local music2 = Instance.new("Sound")
music2.SoundId = "rbxassetid://76463442516219"
music2.Volume = 1
music2.Looped = true
music2.Parent = SoundService
MusicTab:Toggle({
    Title = "死亡之林(音频可能有问题)",
    Value = false,
    Callback = function(state)
        if state then music2:Play() else music2:Stop() end
    end
})

local music3 = Instance.new("Sound")
music3.SoundId = "rbxassetid://75544352326610"
music3.Volume = 1
music3.Looped = true
music3.Parent = SoundService
MusicTab:Toggle({
    Title = "后室",
    Value = false,
    Callback = function(state)
        if state then music3:Play() else music3:Stop() end
    end
})

local music4 = Instance.new("Sound")
music4.SoundId = "rbxassetid://6910191685"
music4.Volume = 1
music4.Looped = true
music4.Parent = SoundService
MusicTab:Toggle({
    Title = "？",
    Value = false,
    Callback = function(state)
        if state then music4:Play() else music4:Stop() end
    end
})
local music5 = Instance.new("Sound")
music5.SoundId = "rbxassetid://1841771337"
music5.Volume = 1
music5.Looped = true
music5.Parent = SoundService
MusicTab:Toggle({
    Title = "苏醒了",
    Value = false,
    Callback = function(state)
        if state then music5:Play() else music5:Stop() end
    end
})

local music6 = Instance.new("Sound")
music6.SoundId = "rbxassetid://115877769571526"
music6.Volume = 1
music6.Looped = true
music6.Parent = SoundService
MusicTab:Toggle({
    Title = "compass",
    Value = false,
    Callback = function(state)
        if state then music6:Play() else music6:Stop() end
    end
})
local Tab = Window:Tab({
    Title = "设置",
    Icon = "settings",
    Locked = false,
})
local themeValues = {}
for name, _ in pairs(WindUI:GetThemes()) do
    table.insert(themeValues, name)
end

Tab:Dropdown({
    Title = "更改ui颜色",
    Multi = false,
    AllowNone = false,
    Value = nil,
    Values = themeValues,
    Callback = function(theme)
        WindUI:SetTheme(theme)
    end
})
end

local function createEnglishUI()
local Tab = Window:Tab({
    Title = "function",
    Icon = "sword",
    Locked = false,
})
local HttpService = game:GetService("HttpService")

local InviteCode = "E6meCtvdZ"
local DiscordAPI = "https://discord.com/api/v10/invites/" .. InviteCode .. "?with_counts=true&with_expiration=true"

local Response = HttpService:JSONDecode(WindUI.Creator.Request({
    Url = DiscordAPI,
    Method = "GET"
}).Body)

if Response and Response.guild then
    local iconUrl = Response.guild.icon and ("https://cdn.discordapp.com/icons/" .. Response.guild.id .. "/" .. Response.guild.icon .. ".png?size=1024") or "rbxassetid://129260712070622"

    Tab:Paragraph({
        Title = Response.guild.name,
        Desc =
            ' <font color="#52525b">●</font> overallpeople: ' .. tostring(Response.approximate_member_count) ..
            '\n <font color="#16a34a">●</font> online: ' .. tostring(Response.approximate_presence_count),
        Image = iconUrl,
        ImageSize = 42,
    })
else
    warn("Discord API Error: ", HttpService:JSONEncode(Response))
end
Tab:Button({
    Title = "copy discord link",
    Callback = function()
        setclipboard("https://discord.gg/E6meCtvdZ")
    end
})
Tab:Button({
    Title = "distort",
    Desc = "Click this function if you want to play spam wallcombo",
    Callback = function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/dream77239/ubg-script/refs/heads/main/%E6%8B%A6%E6%88%AA.txt"))()
    end
})
local fakeBlockEnabled = false
local loopRunning = false

Tab:Toggle({
    Title = "fake block",
    Value = false,
    Callback = function(state)
        fakeBlockEnabled = state

        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local BlockRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Combat"):WaitForChild("Block")
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()

        local function enableBlock()
            pcall(function()
                BlockRemote:FireServer(true)
            end)
        end

        if fakeBlockEnabled then
            enableBlock()
        end

        if not loopRunning then
            loopRunning = true
            task.spawn(function()
                while true do
                    task.wait(0.01)
                    if fakeBlockEnabled then
                        local success, isBlocking = pcall(function()
                            return character:GetAttribute("IsBlocking")
                        end)
                        if success and not isBlocking then
                            enableBlock()
                        end
                    end
                end
            end)
        end
    end
})

local defaultCooldown = game:GetService("ReplicatedStorage").Settings.Cooldowns.Dash.Value

Tab:Toggle({
    Title = "no dash cooldown",
    Value = false,
    Callback = function(state)
        local dashCooldown = game:GetService("ReplicatedStorage").Settings.Cooldowns.Dash
        if state then
            dashCooldown.Value = 1
        else
            dashCooldown.Value = defaultCooldown
        end
    end
})
local defaultMeleeCooldown = game:GetService("ReplicatedStorage").Settings.Cooldowns.Melee.Value

Tab:Toggle({
    Title = "no melee cooldown",
    Value = false,
    Callback = function(state)
        local meleeCooldown = game:GetService("ReplicatedStorage").Settings.Cooldowns.Melee
        if state then
            meleeCooldown.Value = 1
        else
            meleeCooldown.Value = defaultMeleeCooldown
        end
    end
})
local rs = game:GetService("ReplicatedStorage")
local settings = rs.Settings

local defaultAbility = settings.Cooldowns.Ability.Value
Tab:Toggle({
    Title = "no skill cooldown(only sukuna)",
    Value = false,
    Callback = function(state)
        settings.Cooldowns.Ability.Value = state and 1 or defaultAbility
    end
})

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local noSlowdownsToggle = ReplicatedStorage.Settings.Toggles.NoSlowdowns

local defaultValue = false

Tab:Toggle({
    Title = "no slowdown",
    Value = noSlowdownsToggle.Value,
    Callback = function(state)
        if state then
            noSlowdownsToggle.Value = true
        else
            noSlowdownsToggle.Value = defaultValue
        end
    end
})

local defaultDisableHitStun = settings.Toggles.DisableHitStun.Value
Tab:Toggle({
    Title = "no stun",
    Value = false,
    Callback = function(state)
        settings.Toggles.DisableHitStun.Value = state
    end
})

local defaultDisableIntros = settings.Toggles.DisableIntros.Value
Tab:Toggle({
    Title = "Skip opening action",
    Value = false,
    Callback = function(state)
        settings.Toggles.DisableIntros.Value = state
    end
})

local defaultNoStunOnMiss = settings.Toggles.NoStunOnMiss.Value
Tab:Toggle({
    Title = "Melee no rigidity",
    Value = false,
    Callback = function(state)
        settings.Toggles.NoStunOnMiss.Value = state
    end
})

local defaultRagdollTimer = settings.Multipliers.RagdollTimer.Value
Tab:Toggle({
    Title = "no ragdoll",
    Value = false,
    Callback = function(state)
        settings.Multipliers.RagdollTimer.Value = state and 0.5 or defaultRagdollTimer
    end
})

local defaultUltimateTimer = settings.Multipliers.UltimateTimer.Value
Tab:Toggle({
    Title = "Extend the ultimate time",
    Value = false,
    Callback = function(state)
        settings.Multipliers.UltimateTimer.Value = state and 100000 or defaultUltimateTimer
    end
})
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local Ping = player:WaitForChild("Info"):WaitForChild("Ping")

local loop

Tab:Toggle({
    Title = "ping error",
    Value = false,
    Callback = function(state)
        if state then
            loop = task.spawn(function()
                while state do
                    for i = 0, 999, 25 do
                        if not state then break end
                        Ping.Value = i
                        task.wait(0.03)
                    end
                    for i = 999, 0, -25 do
                        if not state then break end
                        Ping.Value = i
                        task.wait(0.03)
                    end
                end
            end)
        else
            if loop then
                task.cancel(loop)
                loop = nil
            end
        end
    end
})
local defaultInstantTransformation = settings.Toggles.InstantTransformation.Value
Tab:Toggle({
    Title = "Open the ultimate immediately",
    Value = false,
    Callback = function(state)
        settings.Toggles.InstantTransformation.Value = state
    end
})
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MeleeDamage = ReplicatedStorage:WaitForChild("Settings"):WaitForChild("Multipliers"):WaitForChild("MeleeDamage")

MeleeDamage.Value = 100

Tab:Toggle({
    Title = "one punch fall",
    Value = false,
    Callback = function(state)
        if state then
            MeleeDamage.Value = 1000000
        else
            MeleeDamage.Value = 100
        end
    end
})
Tab:Toggle({
    Title = "one punch kill(collocation one punch fall)",
    Value = false,
    Callback = function(state)
        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local RunService = game:GetService("RunService")

        local LocalPlayer = Players.LocalPlayer
        local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

        local RagdollPower = ReplicatedStorage:WaitForChild("Settings"):WaitForChild("Multipliers"):WaitForChild("RagdollPower")

        local maxTeleportDistance = 50
        local lastPosition = HumanoidRootPart.Position
        local connection

        if state then
            RagdollPower.Value = 10000

            connection = RunService.RenderStepped:Connect(function()
                -- refresh character in case of reset
                if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
                    lastPosition = HumanoidRootPart.Position
                end

                local currentPos = HumanoidRootPart.Position
                local distance = (currentPos - lastPosition).Magnitude

                if distance > maxTeleportDistance then
                    HumanoidRootPart.CFrame = CFrame.new(lastPosition)
                else
                    lastPosition = currentPos
                end
            end)
        else
            RagdollPower.Value = 100
            if connection then
                connection:Disconnect()
                connection = nil
            end
        end
    end
})
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local wallCombo = ReplicatedStorage.Settings.Cooldowns.WallCombo

Tab:Toggle({
    Title = "wallcombo no cooldown",
    Value = false,
    Callback = function(state)
        if state then
            wallCombo.Value = 0
            print("WallCombo cooldown set to 0")
        else
            wallCombo.Value = 100
            print("WallCombo cooldown reset to 100")
        end
    end
})
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local wall = nil
pcall(function()
    wall = workspace.Map.Structural.Terrain:GetChildren()[5]:GetChildren()[12]
end)

if not wall then
    wall = Instance.new("Part")
    wall.Parent = workspace
end

wall.Size = Vector3.new(12,6,2)
wall.Transparency = 0.6
wall.Material = Enum.Material.SmoothPlastic
wall.Anchored = true
wall.CanCollide = true
wall.CFrame = wall.CFrame or CFrame.new(0,5,0)

if getconnections then
    for _, conn in pairs(getconnections(wall.AncestryChanged)) do
        conn:Disable()
    end
end

local mt = getrawmetatable(game)
setreadonly(mt,false)
local old = mt.__namecall
mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if self == wall and method == "Destroy" then
        return
    end
    return old(self, ...)
end)
setreadonly(mt,true)

local followConnection = nil
Tab:Toggle({
    Title = "wallcombo anywhere",
    Value = false,
    Callback = function(state)
        if state then
            if not followConnection then
                followConnection = RunService.RenderStepped:Connect(function()
                    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        wall.CFrame = hrp.CFrame * CFrame.new(0,0,-8)
                    end
                end)
            end
        else
            if followConnection then
                followConnection:Disconnect()
                followConnection = nil
            end
        end
    end
})
local originalData = {}
local skyBackup = nil

Tab:Toggle({
    Title = "antiLag",
    Value = false,
    Callback = function(state)
        if state then
            originalData = {}
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Explosion") then
                    originalData[v] = v.Enabled
                    v.Enabled = false
                elseif v:IsA("Decal") or v:IsA("Texture") then
                    originalData[v] = v.Transparency
                    v.Transparency = 1
                elseif v:IsA("MeshPart") or v:IsA("UnionOperation") or v:IsA("Part") then
                    if v.Name ~= "HumanoidRootPart" then
                        originalData[v] = v.Material
                        v.Material = Enum.Material.SmoothPlastic
                    end
                elseif v:IsA("SurfaceGui") or v:IsA("BillboardGui") or v:IsA("Beam") then
                    if v:IsA("Beam") then
                        originalData[v] = v.Enabled
                        v.Enabled = false
                    else
                        originalData[v] = v.Enabled ~= nil and v.Enabled or true
                        if v.Enabled ~= nil then
                            v.Enabled = false
                        end
                    end
                end
            end
            originalData["GlobalShadows"] = game.Lighting.GlobalShadows
            originalData["FogEnd"] = game.Lighting.FogEnd
            game.Lighting.GlobalShadows = false
            game.Lighting.FogEnd = 9e9
            local sky = game.Lighting:FindFirstChildOfClass("Sky")
            if sky then
                skyBackup = sky:Clone()
                sky:Destroy()
            end
            local newSky = Instance.new("Sky")
            newSky.SkyboxBk = ""
            newSky.SkyboxDn = ""
            newSky.SkyboxFt = ""
            newSky.SkyboxLf = ""
            newSky.SkyboxRt = ""
            newSky.SkyboxUp = ""
            newSky.SunAngularSize = 0
            newSky.MoonAngularSize = 0
            newSky.Parent = game.Lighting
            game.Lighting.Ambient = Color3.fromRGB(128,128,128)
            game.Lighting.OutdoorAmbient = Color3.fromRGB(128,128,128)
        else
            for obj, value in pairs(originalData) do
                if typeof(obj) == "Instance" and obj.Parent then
                    if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Explosion") then
                        obj.Enabled = value
                    elseif obj:IsA("Decal") or obj:IsA("Texture") then
                        obj.Transparency = value
                    elseif obj:IsA("MeshPart") or obj:IsA("UnionOperation") or obj:IsA("Part") then
                        obj.Material = value
                    elseif obj:IsA("SurfaceGui") or obj:IsA("BillboardGui") or obj:IsA("Beam") then
                        if obj:IsA("Beam") then
                            obj.Enabled = value
                        elseif obj.Enabled ~= nil then
                            obj.Enabled = value
                        end
                    end
                elseif obj == "GlobalShadows" then
                    game.Lighting.GlobalShadows = value
                elseif obj == "FogEnd" then
                    game.Lighting.FogEnd = value
                end
            end
            if skyBackup then
                local currentSky = game.Lighting:FindFirstChildOfClass("Sky")
                if currentSky then
                    currentSky:Destroy()
                end
                skyBackup.Parent = game.Lighting
                skyBackup = nil
            end
            originalData = {}
        end
    end
})
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Camera = workspace.CurrentCamera

local clone, platform, originalCFrame, originalCameraSubject

local function CreatePlatform(position)
    local part = Instance.new("Part")
    part.Size = Vector3.new(10, 1, 10)
    part.Position = position - Vector3.new(0, 3, 0)
    part.Anchored = true
    part.CanCollide = true
    part.Transparency = 0.5
    part.Parent = workspace
    return part
end

local function CreateClone()
    local newClone = Character:Clone()
    for _, v in ipairs(newClone:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Transparency = 0.5
        end
    end
    newClone.Parent = workspace
    return newClone
end

local function ToggleInvisibility(state)
    if state then
        originalCFrame = HumanoidRootPart.CFrame
        HumanoidRootPart.CFrame = HumanoidRootPart.CFrame + Vector3.new(0, -50, 0)
        platform = CreatePlatform(HumanoidRootPart.Position)
        
        task.wait(1)
        
        clone = CreateClone()
        clone:MoveTo(originalCFrame.Position)
        Camera.CameraSubject = clone:FindFirstChildWhichIsA("Humanoid")
        LocalPlayer.Character = clone
    else
        if clone then
            clone:Destroy()
            clone = nil
        end
        
        if platform then
            platform:Destroy()
            platform = nil
        end
        
        if originalCFrame then
            HumanoidRootPart.CFrame = originalCFrame
            originalCFrame = nil
        end
        
        Camera.CameraSubject = Character:FindFirstChildWhichIsA("Humanoid")
        LocalPlayer.Character = Character
    end
end

Tab:Toggle({
    Title = "invisible",
    Value = false,
    Callback = ToggleInvisibility
})
local v_u_1 = require(game.ReplicatedStorage:WaitForChild("Core"))
local v155 = game.Players.LocalPlayer:WaitForChild("Data"):WaitForChild("Character")
local v156 = game.ReplicatedStorage.Characters:FindFirstChild(v155.Value):FindFirstChild("WallCombo")
local v158 = Vector3.new(7, 5, 7)
local v159 = CFrame.new(0, 0, 0)
local v160 = v_u_1.Get("Character", "FullCustomReplication").GetCFrame()
local v163 = game.Players.LocalPlayer.Character

local v167 = {
    ["Size"] = v158,
    ["Offset"] = v159,
    ["CustomValidation"] = function()
        return true
    end,
}

local v_u_168 = v_u_1.Get("Combat", "Hit").Box(nil, v163, v167)
local v58 = v156:GetAttribute("Interrupt")

function Run(p_u_7, p8, p_u_9, p10, ...)
    local v_u_11 = p_u_7 and p_u_7:FindFirstChild("Humanoid") or p_u_7
    local v_u_12 = p_u_7 and p_u_7:FindFirstChild("HumanoidRootPart") or p_u_7
    if p_u_7 and (v_u_11 and v_u_12) then
        local v_u_13 = p_u_7 == game.Players.LocalPlayer.Character
        local v_u_17 = p8
        v_u_1.Get("Combat", "Cancel").Init(v_u_17, p_u_9, p_u_7)
        v_u_1.Get("Combat", "Cancel").Set(v_u_17, p_u_9, p_u_7, "Timeout")
        local v_u_36 = { ... }
        task.spawn(function()
            local v37 = {}
            local v38 = v_u_36
            for i, v in ipairs({ p_u_7, v_u_11, v_u_12, v_u_13, p_u_9 }) do
                v37[i] = v
            end
            for i, v in ipairs(v38) do
                v37[#v37 + 1] = v
            end
            v_u_1.Get("Cosmetics", "KillEmote").RunAfter(v_u_17, table.unpack(v37))
        end)
    end
end

local originPos = v160.Position
local rs = game:GetService("RunService")
local running = false

Tab:Toggle({
    Title = "killaura",
    Value = false,
    Callback = function(state)
        running = state
        if running then
            rs:BindToRenderStep("KillAura", Enum.RenderPriority.Input.Value, function()
                local pos = originPos + v160.LookVector * 6
                for i = 1, 4 do
                    task.spawn(function()
                        v_u_1.Library("Remote").Send("Ability", v156, 9e9, v58, v_u_168, pos)
                        Run(game.Players.LocalPlayer.Character, v156, 9e9, v58, v_u_168, pos)
                    end)
                end
            end)
        else
            rs:UnbindFromRenderStep("KillAura")
        end
    end
})
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local wallComboSpamming = false
local wallComboHeartbeat = nil
local wallComboPerFrame = 2
local wallComboKeybind = Enum.KeyCode.E

local core = require(ReplicatedStorage.Core)
local chars = ReplicatedStorage.Characters
local char = LocalPlayer.Data.Character

local function executeWallCombo()
    local head = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
    if not head then return end

    local res = core.Get("Combat","Hit").Box(nil, LocalPlayer.Character, {Size = Vector3.new(50,50,50)})
    if res then
        local success, err = pcall(core.Get("Combat","Ability").Activate, chars[char.Value].WallCombo, res, head.Position + Vector3.new(0,0,2.5))
        if not success then
            warn(err)
        end
    end
end

local function updateWallComboHeartbeat()
    if wallComboHeartbeat then
        wallComboHeartbeat:Disconnect()
        wallComboHeartbeat = nil
    end
    if wallComboSpamming then
        wallComboHeartbeat = RunService.Heartbeat:Connect(function()
            for i = 1, wallComboPerFrame do
                executeWallCombo()
            end
        end)
    end
end

UserInputService.InputBegan:Connect(function(input, isProcessed)
    if isProcessed then return end
    if input.KeyCode == wallComboKeybind then
        executeWallCombo()
    end
end)

Tab:Toggle({
    Title = "spam wallcombo",
    Value = false,
    Callback = function(state)
        wallComboSpamming = state
        updateWallComboHeartbeat()
    end
})
Tab:Button({
    Title = "Delete the spam wallcombo special effects",
    Desc = "Click this function, you can't restore the wall special effects",
    Callback = function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local paths = {
            ReplicatedStorage.Characters.Gon.WallCombo.GonWallCombo.Center,
            ReplicatedStorage.Characters.Gon.WallCombo.GonWallCombo.Explosion,
            ReplicatedStorage.Characters.Gon.WallCombo.GonIntroHands,
            ReplicatedStorage.Characters.Mob.WallCombo.MobWallCombo.Center,
            ReplicatedStorage.Characters.Nanami.WallCombo.NanamiWallCombo.Center,
            ReplicatedStorage.Characters.Stark.WallCombo.StarkWallCombo.Center,
            ReplicatedStorage.Characters.Sukuna.WallCombo.SukunaTransformWallCombo,
            ReplicatedStorage.Characters.Sukuna.WallCombo.SukunaWallCombo
        }

        for _, obj in ipairs(paths) do
            if obj and obj:IsA("Instance") then
                for _, child in ipairs(obj:GetChildren()) do
                    child:Destroy()
                end
            end
        end
    end
})
Tab:Button({
    Title = "Delete the kill emoticon effect",
    Desc = "Click delete to kill some special effects of the expression, which cannot be recovered",
    Callback = function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local KillEmote = ReplicatedStorage:WaitForChild("Cosmetics"):WaitForChild("KillEmote")

        local function removeEffects(obj)
            for _, child in ipairs(obj:GetChildren()) do
                if child:IsA("ParticleEmitter") 
                or child:IsA("Trail") 
                or child:IsA("Beam") 
                or child:IsA("Fire") 
                or child:IsA("Smoke") 
                or child:IsA("Sparkles") 
                or child:IsA("Light") then
                    child:Destroy()
                else
                    removeEffects(child)
                end
            end
        end

        removeEffects(KillEmote)
        print("KillEmote 特效已删除（保留本体）")
    end
})
 local ReplicatedStorage = game:GetService("ReplicatedStorage")
local multiUseCutscenesToggle = ReplicatedStorage.Settings.Toggles.MultiUseCutscenes

local defaultValue = false

Tab:Toggle({
    Title = "Esper's big move skill used many times",
    Value = multiUseCutscenesToggle.Value,
    Callback = function(state)
        if state then
            multiUseCutscenesToggle.Value = true
        else
            multiUseCutscenesToggle.Value = defaultValue
        end
    end
})
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local tpwalking = false
local tpwalkSpeed = 100

Tab:Toggle({
    Title = "tpwalk",
    Value = false,
    Callback = function(state)
        tpwalking = state
        if state then
            spawn(function()
                while tpwalking do
                    local chr = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                    local hrp = chr:FindFirstChild("HumanoidRootPart")
                    local hum = chr:FindFirstChildWhichIsA("Humanoid")
                    local delta = RunService.Heartbeat:Wait()
                    if hrp and hum and hum.MoveDirection.Magnitude > 0 then
                        hrp.CFrame = hrp.CFrame + (hum.MoveDirection * tpwalkSpeed * delta)
                    end
                end
            end)
        end
    end
})

Tab:Slider({
    Title = "tpwalk set",
    Value = {
        Min = 0,
        Max = 250,
        Default = tpwalkSpeed,
    },
    Callback = function(value)
        tpwalkSpeed = value
    end
})
Tab:Slider({
    Title = "dash speed",
    Value = {
        Min = 0,
        Max = 1000,
        Default = 100,
    },
    Callback = function(value)
        game:GetService("ReplicatedStorage").Settings.Multipliers.DashSpeed.Value = value
    end
})

Tab:Slider({
    Title = "jump power",
    Value = {
        Min = 0,
        Max = 1000,
        Default = 100,
    },
    Callback = function(value)
        game:GetService("ReplicatedStorage").Settings.Multipliers.JumpHeight.Value = value
    end
})

Tab:Slider({
    Title = "melee speed",
    Value = {
        Min = 0,
        Max = 1000,
        Default = 100,
    },
    Callback = function(value)
        game:GetService("ReplicatedStorage").Settings.Multipliers.MeleeSpeed.Value = value
    end
})
local Players = game:GetService("Players")
local Tab = Window:Tab({
    Title = "hit box",
    Icon = "box",
    Locked = false,
})

local expansionMethod = "Add"
local hitboxX, hitboxY, hitboxZ = 0, 0, 0
local isHitboxExpanded = false
local hitModuleTable = nil
local originalBox = nil
local sizeModifier = Vector3.new(0, 0, 0)

local function setupHitboxHook()
    if hitModuleTable and hitModuleTable._boxSizeModifierHookInstalled then
        print("Hitbox hook already installed.")
        return true
    end
    
    local player = Players.LocalPlayer
    local playerScripts = player:WaitForChild("PlayerScripts")
    local combatFolder = playerScripts:WaitForChild("Combat")
    local hitModule = combatFolder:WaitForChild("Hit")
    
    hitModuleTable = require(hitModule)
    originalBox = hitModuleTable.Box
    
    hitModuleTable.Box = function(...)
        local args = {...}
        if args[3] and typeof(args[3]) == "table" then
            local config = args[3]
            if config.Size and typeof(config.Size) == "Vector3" then
                if not config._originalSize then
                    config._originalSize = config.Size
                end
                if expansionMethod == "Set" then
                    config.Size = sizeModifier
                elseif expansionMethod == "Add" then
                    config.Size = config._originalSize + sizeModifier
                end
            end
            return originalBox(...)
        else
            return originalBox(...)
        end
    end
    hitModuleTable._boxSizeModifierHookInstalled = true
    return true
end

local function applySigmaHitbox(x, y, z)
    if not setupHitboxHook() then
        warn("Failed to setup hitbox hook!")
        return
    end
    sizeModifier = Vector3.new(x, y, z)
    print("Sigma hitbox expansion applied:", sizeModifier)
end

Tab:Input({
    Title = "X",
    Value = "0",
    InputIcon = "bird",
    Type = "Input",
    Placeholder = "输入一个数字...",
    Callback = function(input)
        hitboxX = tonumber(input) or 0
        print("Hitbox X vector set to:", hitboxX)
    end
})

Tab:Input({
    Title = "Y",
    Value = "0",
    InputIcon = "bird",
    Type = "Input",
    Placeholder = "输入一个数字...",
    Callback = function(input)
        hitboxY = tonumber(input) or 0
        print("Hitbox Y vector set to:", hitboxY)
    end
})

Tab:Input({
    Title = "Z",
    Value = "0",
    InputIcon = "bird",
    Type = "Input",
    Placeholder = "输入一个数字...",
    Callback = function(input)
        hitboxZ = tonumber(input) or 0
        print("Hitbox Z vector set to:", hitboxZ)
    end
})

Tab:Dropdown({
    Title = "Extension method",
    Values = {"Add", "Set"},
    Value = "Add",
    Multi = false,
    AllowNone = false,
    Callback = function(option)
        expansionMethod = option
        print("Hitbox method set to:", expansionMethod)
    end
})

Tab:Button({
    Title = "Apply collision box modification",
    Desc = nil,
    Locked = false,
    Callback = function()
        applySigmaHitbox(hitboxX, hitboxY, hitboxZ)
        isHitboxExpanded = true
    end
})

Tab:Button({
    Title = "Slight expansion(5)",
    Desc = nil,
    Locked = false,
    Callback = function()
        hitboxX, hitboxY, hitboxZ = 5, 5, 5
        applySigmaHitbox(hitboxX, hitboxY, hitboxZ)
        isHitboxExpanded = true
    end
})

Tab:Button({
    Title = "Mesomorphic extension(10)",
    Desc = nil,
    Locked = false,
    Callback = function()
        hitboxX, hitboxY, hitboxZ = 10, 10, 10
        applySigmaHitbox(hitboxX, hitboxY, hitboxZ)
        isHitboxExpanded = true
    end
})

Tab:Button({
    Title = "Large expansion(20)",
    Desc = nil,
    Locked = false,
    Callback = function()
        hitboxX, hitboxY, hitboxZ = 20, 20, 20
        applySigmaHitbox(hitboxX, hitboxY, hitboxZ)
        isHitboxExpanded = true
    end
})
local lightningCharacterSwapTab = Window:Tab({
    Title = "Fast switching role function",
    Icon = "bird",
    Locked = false,
})

local lastPosition

local function getHumanoidRootPart()
    local character = LocalPlayer.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function savePosition()
    local rootPart = getHumanoidRootPart()
    if rootPart then
        lastPosition = rootPart.CFrame
    end
end

local function handleKeyPress(characterName)
    savePosition()
    
    local rootPart = getHumanoidRootPart()
    if rootPart then
        rootPart.CFrame = CFrame.new(1011.1289672851562, -1009.359588623046875, 116.37605285644531)
    end

    ReplicatedStorage.Remotes.Character.ChangeCharacter:FireServer(characterName)

    local groundY = workspace.Map.Structural.Ground:GetChildren()[21].Position.Y
    repeat task.wait() until getHumanoidRootPart() and getHumanoidRootPart().Position.Y > groundY
    task.wait(0.15)

    local newRootPart = getHumanoidRootPart()
    if newRootPart and lastPosition then
        repeat
            newRootPart.CFrame = lastPosition
            task.wait(0.1)
        until (newRootPart.Position - lastPosition.Position).Magnitude < 10
    end
end

lightningCharacterSwapTab:Button({
    Title = "Quickly switch to mob",
    Locked = false,
    Callback = function() handleKeyPress("Gon") end
})

lightningCharacterSwapTab:Button({
    Title = "Quick switch to nanami",
    Locked = false,
    Callback = function() handleKeyPress("Nanami") end
})

lightningCharacterSwapTab:Button({
    Title = "Quick switch to esper",
    Locked = false,
    Callback = function() handleKeyPress("Mob") end
})
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local core = require(ReplicatedStorage:WaitForChild("Core"))
local Character = LocalPlayer.Character
local HumanoidRootPart = Character and Character:WaitForChild("HumanoidRootPart")
local orbitToggle = nil
local fakeWallToggle = nil
local serverStatus = "goodstate"

local forceKillEmoteTab = Window:Tab({
    Title = "kill emote",
    Icon = "smile",
    Locked = false,
})

local killEmotes = {}
local isAuraMode = false
local isSpammingSelectedEmote = false
local auraDelay = 0.5
local spamDelay = 0.5
local selectedEmote = ""
local selectedKeybind = Enum.KeyCode.G
local emoteDropdown

local function getRoot(char)
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function useEmote(emoteName)
    local emoteModule = ReplicatedStorage:WaitForChild("Cosmetics"):WaitForChild("KillEmote"):FindFirstChild(emoteName)
    local myRoot = getRoot(LocalPlayer.Character)
    if not myRoot then return end
    local closestTarget = nil
    local shortestDistance = math.huge
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetRoot = getRoot(player.Character)
            if targetRoot then
                local distance = (myRoot.Position - targetRoot.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestTarget = player.Character
                end
            end
        end
    end
    if closestTarget and emoteModule then
        task.spawn(function()
            _G.KillEmote = true
            pcall(function()
                if core and core.Get then
                    core.Get("Combat", "Ability").Activate(emoteModule, closestTarget)
                end
            end)
            _G.KillEmote = false
        end)
    end
end

local function useRandomEmote()
    if #killEmotes > 0 then
        local randomEmote = killEmotes[math.random(1, #killEmotes)]
        useEmote(randomEmote)
    end
end

task.spawn(function()
    while true do
        if isAuraMode then
            useRandomEmote()
            task.wait(auraDelay)
        else
            task.wait(0.1)
        end
    end
end)

task.spawn(function()
    while true do
        if isSpammingSelectedEmote and selectedEmote ~= "" then
            useEmote(selectedEmote)
            task.wait(spamDelay)
        else
            task.wait(0.1)
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, isGameProcessed)
    if isGameProcessed then return end
    if input.KeyCode == selectedKeybind and selectedEmote ~= "" then
        useEmote(selectedEmote)
    end
end)

local function createOrUpdateEmoteDropdown(emoteList)
    local values = emoteList
    if not values or #values == 0 then
        values = {"No emotes found"}
    end
    emoteDropdown = forceKillEmoteTab:Dropdown({
        Title = "Kill emote function(need to be close to others)",
        Values = values,
        Multi = false,
        AllowNone = false,
        Callback = function(option)
            if option ~= "No emotes found" then
                selectedEmote = option
                useEmote(option)
            end
        end
    })
end

forceKillEmoteTab:Button({
    Title = "Refresh the available kill emote",
    Desc = ":p",
    Callback = function()
        local currentEmotes = {}
        for _, emote in pairs(ReplicatedStorage:WaitForChild("Cosmetics"):WaitForChild("KillEmote"):GetChildren()) do
            table.insert(currentEmotes, emote.Name)
        end
        killEmotes = currentEmotes
        createOrUpdateEmoteDropdown(killEmotes)
    end
})

for _, emote in pairs(ReplicatedStorage:WaitForChild("Cosmetics"):WaitForChild("KillEmote"):GetChildren()) do
    table.insert(killEmotes, emote.Name)
end

createOrUpdateEmoteDropdown(killEmotes)

forceKillEmoteTab:Toggle({
    Title = "Kill aura of expression",
    Desc = ":p",
    Icon = "bird",
    Type = "Checkbox",
    Default = false,
    Callback = function(isEnabled)
        isAuraMode = isEnabled
    end
})

forceKillEmoteTab:Slider({
    Title = "Kill emote halo interval",
    Step = 0.01,
    Value = { Min = 0.01, Max = 5.0, Default = 0.5 },
    Callback = function(value)
        auraDelay = value
    end
})

forceKillEmoteTab:Toggle({
    Title = "Keep sending kill emote of your choice",
    Desc = "nothing",
    Icon = "bird",
    Type = "Checkbox",
    Default = false,
    Callback = function(isEnabled)
        isSpammingSelectedEmote = isEnabled
    end
})

forceKillEmoteTab:Slider({
    Title = "Adjust your currently selected kill emote aura",
    Step = 0.01,
    Value = { Min = 0.01, Max = 5.0, Default = 0.5 },
    Callback = function(value)
        spamDelay = value
    end
})

local emoteKeybindOptions = { "G", "F", "H", "J", "K", "L", "Z", "X", "C", "V", "B", "N", "M", "Q", "E", "R", "T", "Y", "U", "I", "O", "P" }
local emoteKeybindMap = {
    ["G"] = Enum.KeyCode.G, ["F"] = Enum.KeyCode.F, ["H"] = Enum.KeyCode.H,
    ["J"] = Enum.KeyCode.J, ["K"] = Enum.KeyCode.K, ["L"] = Enum.KeyCode.L,
    ["Z"] = Enum.KeyCode.Z, ["X"] = Enum.KeyCode.X, ["C"] = Enum.KeyCode.C,
    ["V"] = Enum.KeyCode.V, ["B"] = Enum.KeyCode.B, ["N"] = Enum.KeyCode.N,
    ["M"] = Enum.KeyCode.M, ["Q"] = Enum.KeyCode.Q, ["E"] = Enum.KeyCode.E,
    ["R"] = Enum.KeyCode.R, ["T"] = Enum.KeyCode.T, ["Y"] = Enum.KeyCode.Y,
    ["U"] = Enum.KeyCode.U, ["I"] = Enum.KeyCode.I, ["O"] = Enum.KeyCode.O,
    ["P"] = Enum.KeyCode.P
}

forceKillEmoteTab:Dropdown({
    Title = "Shortcut key setting",
    Values = emoteKeybindOptions,
    Value = "G",
    Multi = false,
    AllowNone = false,
    Callback = function(option)
        selectedKeybind = emoteKeybindMap[option]
    end
})

forceKillEmoteTab:Button({
    Title = "Randomly use a kill emote",
    Desc = "Literal meaning",
    Locked = false,
    Callback = function()
        useRandomEmote()
    end
})
local MusicTab = Window:Tab({
    Title = "music",
    Icon = "music",
    Locked = false,
})

local SoundService = game:GetService("SoundService")

local music1 = Instance.new("Sound")
music1.SoundId = "rbxassetid://107990547300911"
music1.Volume = 1
music1.Looped = true
music1.Parent = SoundService
MusicTab:Toggle({
    Title = "因果",
    Value = false,
    Callback = function(state)
        if state then music1:Play() else music1:Stop() end
    end
})

local music2 = Instance.new("Sound")
music2.SoundId = "rbxassetid://76463442516219"
music2.Volume = 1
music2.Looped = true
music2.Parent = SoundService
MusicTab:Toggle({
    Title = "死亡之林(音频可能有问题)",
    Value = false,
    Callback = function(state)
        if state then music2:Play() else music2:Stop() end
    end
})

local music3 = Instance.new("Sound")
music3.SoundId = "rbxassetid://75544352326610"
music3.Volume = 1
music3.Looped = true
music3.Parent = SoundService
MusicTab:Toggle({
    Title = "后室",
    Value = false,
    Callback = function(state)
        if state then music3:Play() else music3:Stop() end
    end
})

local music4 = Instance.new("Sound")
music4.SoundId = "rbxassetid://6910191685"
music4.Volume = 1
music4.Looped = true
music4.Parent = SoundService
MusicTab:Toggle({
    Title = "？",
    Value = false,
    Callback = function(state)
        if state then music4:Play() else music4:Stop() end
    end
})
local music5 = Instance.new("Sound")
music5.SoundId = "rbxassetid://1841771337"
music5.Volume = 1
music5.Looped = true
music5.Parent = SoundService
MusicTab:Toggle({
    Title = "苏醒了",
    Value = false,
    Callback = function(state)
        if state then music5:Play() else music5:Stop() end
    end
})

local music6 = Instance.new("Sound")
music6.SoundId = "rbxassetid://115877769571526"
music6.Volume = 1
music6.Looped = true
music6.Parent = SoundService
MusicTab:Toggle({
    Title = "compass",
    Value = false,
    Callback = function(state)
        if state then music6:Play() else music6:Stop() end
    end
})
local Tab = Window:Tab({
    Title = "setting",
    Icon = "settings",
    Locked = false,
})
local themeValues = {}
for name, _ in pairs(WindUI:GetThemes()) do
    table.insert(themeValues, name)
end

Tab:Dropdown({
    Title = "Change ui color",
    Multi = false,
    AllowNone = false,
    Value = nil,
    Values = themeValues,
    Callback = function(theme)
        WindUI:SetTheme(theme)
    end
})
end

LangTab:Button({
    Title = "中文",
    Callback = function()
        createChineseUI()
    end
})

LangTab:Button({
    Title = "English",
    Callback = function()
        createEnglishUI()
    end
})