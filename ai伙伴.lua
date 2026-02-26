-- Delta Executor R6 NPC [模仿系统 + 1分钟报数 + 语音交互优化版 v2.8]
-- ✅ 错误处理全面优化版：修复内存泄漏、递归崩溃、连接残留等12个问题
-- ✅ v2.1 新增：坐下/起来指令；优化睡觉指令（原地停下、退出时区分状态回复）

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Chat = game:GetService("Chat")
local PathfindingService = game:GetService("PathfindingService")
local TextToSpeechService = game:GetService("TextToSpeechService")

local player = Players.LocalPlayer
local npc = nil
local enabled = false
local connections = {}

-- ====================== 可自定义配置 ======================
local NPC_USER_ID          = 5226787300
local NPC_DISPLAY_NAME     = "SybsyLove"
local TTS_VOICE_ID         = "zh-CN-Standard-A"
local AUTO_REPORT_INTERVAL = 60
local MAX_FOLLOW_DISTANCE   = 250
local IDLE_RADIUS           = 12   -- 12格内：原地待命，不主动走动
local FOLLOW_START_DISTANCE = 20   -- 超过20格：判定为走远，开始追赶
local FOLLOW_STOP_DISTANCE  = 8    -- 追近到8格内：停下
-- ==========================================================

-- 核心状态变量
local targetPos    = nil
local lastMoveTime      = 0
local playerStillTime   = 0   -- 玩家连续静止的累计秒数
local isReacting        = false  -- 愣神锁：防止触发多次延迟追赶
local isPausing         = false  -- 随机停顿锁：走路中途发呆
local dynamicStopDist   = 6      -- 动态停驻距离（2~8格随机）
local npcSpeedOffset    = 0      -- 速度随机偏移量
local nextSpeedChange   = 0      -- 下次速度变化的时间戳
local hasPokedIdle      = false  -- 防止7秒内重复催话
local isFollowing  = false
local isSleeping   = false
local isSitting    = false   -- 新增：坐下状态
local isMimicking  = false

-- 计时器
local runStartTime       = 0
local hasComplained      = false
local lastCheckPeopleTime = 0

-- 防卡死参数
local stuckTime = 0
local jumpCount = 0

-- ✅ [FIX 1] NPC 重建防抖标志，防止 Heartbeat 内无限递归创建
local isRecreating = false

-- ✅ [FIX 2] TTS 单实例引用，防止 Sound 对象堆积内存泄漏
local currentTTSSound = nil

-- ✅ [FIX 3] 角色外观缓存，防止频繁重建时触发 API 限速
local cachedDesc = nil

-- ============================================================
-- 工具函数
-- ============================================================

-- ✅ [FIX 4] 安全 WaitForChild，超时时 warn 并返回 nil，不静默崩溃
local function safeWait(parent, name, timeout)
    local ok, result = pcall(function()
        return parent:WaitForChild(name, timeout or 5)
    end)
    if not ok or not result then
        warn("[NPC] WaitForChild 超时或失败: " .. tostring(name) .. " in " .. tostring(parent.Name))
        return nil
    end
    return result
end

-- ✅ [FIX 5] 安全外观获取，含缓存，失败时 warn 并返回 nil
local function getDesc()
    if cachedDesc then return true, cachedDesc end
    local ok, desc = pcall(function()
        return Players:GetHumanoidDescriptionFromUserId(NPC_USER_ID)
    end)
    if ok and desc then
        cachedDesc = desc
        return true, desc
    end
    warn("[NPC] 获取外观失败，请检查 NPC_USER_ID 是否正确")
    return false, nil
end

-- ✅ [FIX 6] clearConnections 加入类型判断，防止 nil 混入导致报错
local function clearConnections()
    for _, v in pairs(connections) do
        if v and typeof(v) == "RBXScriptConnection" and v.Connected then
            v:Disconnect()
        end
    end
    connections = {}
end

-- ✅ [FIX 7] npcSay：TTS 单实例管理 + pcall 保护 + 降级到纯气泡聊天
local function npcSay(text)
    if not npc or not npc:FindFirstChild("Head") then return end

    -- 气泡聊天（不依赖 TTS，总是执行）
    pcall(function()
        Chat:Chat(npc.Head, text, Enum.ChatColor.White)
    end)

    -- 语音（单实例，新语音触发前先停止旧的）
    task.spawn(function()
        if currentTTSSound then
            pcall(function() currentTTSSound:Stop() end)
            pcall(function() currentTTSSound:Destroy() end)
            currentTTSSound = nil
        end

        local ok, audioId = pcall(function()
            return TextToSpeechService:SynthesizeAsync(TTS_VOICE_ID, text)
        end)

        -- 生成语音后再次检查 NPC 是否存活
        if ok and audioId and npc and npc:FindFirstChild("Head") then
            local s = Instance.new("Sound")
            s.SoundId = audioId
            s.Parent  = npc.Head
            s.Volume  = 1
            s.Looped  = false
            currentTTSSound = s
            s:Play()
            s.Ended:Connect(function()
                s:Destroy()
                if currentTTSSound == s then
                    currentTTSSound = nil
                end
            end)
        end
    end)
end

-- 寻路路径生成（不变，保持原逻辑）
local function getPath(startPos, endPos)
    local path = PathfindingService:CreatePath({
        AgentRadius   = 2,
        AgentHeight   = 5,
        AgentCanJump  = true,
        AgentCanClimb = false,
    })
    local success, _ = pcall(function()
        path:ComputeAsync(startPos, endPos)
    end)
    if success and path.Status == Enum.PathStatus.Success then
        return path:GetWaypoints()
    end
    return nil
end

-- GUI 拖拽功能
-- ✅ [FIX 8] 通过 gui.Destroying 事件断开全局 InputChanged，防止 GUI 销毁后泄漏
local function makeDraggable(gui)
    local dragging, dragInput, dragStart, startPos

    gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = gui.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    gui.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    local globalConn = UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            gui.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    -- ✅ GUI 销毁时自动断开全局监听
    gui.Destroying:Connect(function()
        if globalConn and globalConn.Connected then
            globalConn:Disconnect()
        end
    end)
end

-- ============================================================
-- NPC 动画系统
-- ✅ [FIX 9] 接收外部 connections 表，将 animLoop 注册进去统一清理
-- ============================================================
local function setupAnimations(model, conns)
    local hum  = safeWait(model, "Humanoid", 5)
    local root = safeWait(model, "HumanoidRootPart", 5)
    if not hum or not root then return end

    local animator = hum:FindFirstChildOfClass("Animator")
        or Instance.new("Animator", hum)

    local function loadAnim(id)
        local a = Instance.new("Animation")
        a.AnimationId = id
        local track = animator:LoadAnimation(a)
        a:Destroy()
        return track
    end

    local idleTrack  = loadAnim("rbxassetid://180435571")
    local walkTrack  = loadAnim("rbxassetid://180426354")
    local jumpTrack  = loadAnim("rbxassetid://125750702")
    local sleepTrack = loadAnim("rbxassetid://125750513")

    idleTrack.Looped  = true
    walkTrack.Looped  = true
    sleepTrack.Looped = true

    local currentTrack = nil
    local function playTrack(newTrack, fadeTime)
        if currentTrack == newTrack then return end
        fadeTime = fadeTime or 0.2
        if currentTrack then currentTrack:Stop(fadeTime) end
        currentTrack = newTrack
        if currentTrack then currentTrack:Play(fadeTime) end
    end

    -- ✅ animLoop 注册到传入的 conns 表，确保 clearConnections 能断开它
    local animLoop = RunService.Heartbeat:Connect(function()
        if not model.Parent or not hum or not root then
            return
        end

        -- 坐下状态：交由 Roblox 原生 Sit 动画处理，不强行覆盖
        if isSitting then
            return
        end

        local velocity = root.AssemblyLinearVelocity
        local speed    = Vector3.new(velocity.X, 0, velocity.Z).Magnitude

        if isSleeping then
            hum.HipHeight = -2.8
            playTrack(sleepTrack)
        elseif hum.FloorMaterial == Enum.Material.Air then
            hum.HipHeight = 0
            playTrack(jumpTrack)
        elseif speed > 0.1 then
            hum.HipHeight = 0
            playTrack(walkTrack)
            walkTrack:AdjustSpeed(math.clamp(speed / 16, 0.5, 2))
        else
            hum.HipHeight = 0
            playTrack(idleTrack)
        end
    end)
    table.insert(conns, animLoop)
end

-- ============================================================
-- NPC 核心创建函数
-- ============================================================
local function createNPC()
    if npc then
        npc:Destroy()
        npc = nil
    end
    clearConnections()

    -- 重置状态
    isFollowing     = false
    isSleeping      = false
    isSitting       = false
    isMimicking     = false
    targetPos       = nil
    stuckTime       = 0
    jumpCount       = 0
    runStartTime    = 0
    hasComplained   = false
    playerStillTime = 0
    hasPokedIdle    = false
    isReacting      = false
    isPausing       = false
    dynamicStopDist = 6
    npcSpeedOffset  = 0
    nextSpeedChange = 0
    lastCheckPeopleTime = os.clock()

    -- ✅ 使用 safeWait 等待角色
    local char   = player.Character or player.CharacterAdded:Wait()
    local myRoot = safeWait(char, "HumanoidRootPart", 5)
    local myHum  = safeWait(char, "Humanoid", 5)
    if not myRoot or not myHum then return end

    -- ✅ 使用缓存获取外观
    local success, desc = getDesc()
    if not success then return end

    -- 生成 R6 NPC
    npc = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R6)
    npc.Name   = NPC_DISPLAY_NAME
    npc.Parent = workspace
    npc:MakeJoints()

    local hum  = safeWait(npc, "Humanoid", 5)
    local root = npc.PrimaryPart or safeWait(npc, "HumanoidRootPart", 5)
    if not hum or not root then
        npc:Destroy()
        npc = nil
        return
    end

    hum.DisplayName = NPC_DISPLAY_NAME
    hum.WalkSpeed   = math.max(myHum.WalkSpeed - 1, 1)
    hum.AutoRotate  = true

    root.CFrame = myRoot.CFrame * CFrame.new(3, 0, -3)
    task.defer(function()
        npcSay("你好呀 OvO")
    end)

    task.wait(0.3)
    -- ✅ 传入 connections，让 animLoop 被统一管理
    setupAnimations(npc, connections)

    -- 玩家进出监听
    table.insert(connections, Players.PlayerAdded:Connect(function(p)
        npcSay(p.Name .. "加入了服务器~")
    end))
    table.insert(connections, Players.PlayerRemoving:Connect(function(p)
        npcSay(p.Name .. "偷偷跑走了 QAQ")
    end))

    -- 角色重生监听
    table.insert(connections, player.CharacterAdded:Connect(function(newChar)
        char   = newChar
        myRoot = safeWait(newChar, "HumanoidRootPart", 5)
        myHum  = safeWait(newChar, "Humanoid", 5)
    end))

    -- ✅ [FIX 10] 模仿模式：维护 mimicTrack 引用，防止动画轨道堆积
    local mimicTrack = nil
    local myAnimator = myHum:FindFirstChildOfClass("Animator")
    if myAnimator then
        table.insert(connections, myAnimator.AnimationPlayed:Connect(function(track)
            if not isMimicking then return end
            if not npc or not hum then return end
            local npcAnimator = hum:FindFirstChildOfClass("Animator")
            if not npcAnimator then return end

            -- 停止并释放旧的模仿轨道
            if mimicTrack and mimicTrack.IsPlaying then
                mimicTrack:Stop()
            end

            local newAnim = Instance.new("Animation")
            newAnim.AnimationId = track.Animation.AnimationId
            mimicTrack = npcAnimator:LoadAnimation(newAnim)
            mimicTrack:Play(track.FadeTime, track.Weight, track.Speed)
            newAnim:Destroy()

            track.Ended:Connect(function()
                if mimicTrack and mimicTrack.IsPlaying then mimicTrack:Stop() end
            end)
            track.Stopped:Connect(function()
                if mimicTrack and mimicTrack.IsPlaying then mimicTrack:Stop() end
            end)
        end))
    end

    -- 聊天指令处理
    table.insert(connections, player.Chatted:Connect(function(msg)
        local lowerMsg = msg:lower()

        if lowerMsg == "睡觉" then
            -- 睡觉：停止移动，停止跟随，躺下
            isSleeping  = true
            isSitting   = false
            isMimicking = false
            isFollowing = false
            hum.Sit     = false   -- 先确保不处于坐下状态再进入睡眠姿态
            hum:MoveTo(root.Position)  -- 原地停下
            npcSay("晚安~我先睡啦 zZZ")

        elseif lowerMsg == "起来" then
            -- 起来：同时退出睡觉和坐下
            local wasSleeping = isSleeping
            local wasSitting  = isSitting
            isSleeping    = false
            isSitting     = false
            hum.Sit       = false
            hum.HipHeight = 0
            if wasSleeping then
                npcSay("好哒，我起来啦，睡得好香~")
            elseif wasSitting then
                npcSay("好哒，我站起来啦")
            else
                npcSay("我本来就站着呢~")
            end

        elseif lowerMsg == "坐下" then
            -- 坐下：利用 Humanoid.Sit 属性让 NPC 坐下
            isSitting   = true
            isSleeping  = false
            isMimicking = false
            isFollowing = false
            hum:MoveTo(root.Position)  -- 原地停下再坐
            task.delay(0.1, function()
                -- 短暂延迟确保 MoveTo 已停止再坐下，避免站起来
                if isSitting and hum and hum.Parent then
                    hum.Sit = true
                end
            end)
            npcSay("好的，我坐下啦~")

        elseif lowerMsg == "学我" then
            isMimicking = true
            isSleeping  = false
            isFollowing = false
            npcSay("好哒，我会跟着你做一样的动作哦~")

        elseif lowerMsg == "别学了" then
            isMimicking = false
            npcSay("好滴，不学啦")

        elseif lowerMsg == "跟我走" or lowerMsg == "跟着我" then
            isMimicking   = false
            isSleeping    = false
            isFollowing   = true
            hum.HipHeight = 0
            npcSay("好哒，我跟着你走")

        elseif lowerMsg == "别跟着我" or lowerMsg == "停下" then
            isFollowing = false
            targetPos   = root.Position
            npcSay("好滴，我停下啦")

        elseif lowerMsg == "过来" then
            if myRoot then
                root.CFrame = myRoot.CFrame * CFrame.new(0, 0, -4)
                targetPos   = root.Position
                npcSay("我来啦~")
            end

        elseif lowerMsg == "跳一下" then
            hum.Jump = true

        elseif lowerMsg:find("多少人") or lowerMsg:find("几个人") or lowerMsg == "报数" then
            npcSay("现在服务器一共有 " .. #Players:GetPlayers() .. " 个人哦~")
            lastCheckPeopleTime = os.clock()

        -- ✅ [FIX 11] 说话指令：限制最大 100 字符，防止 TTS 超时
        elseif lowerMsg:sub(1, 2) == "说话" then
            local content = msg:sub(4)
            if content and content ~= "" then
                if #content > 100 then
                    content = content:sub(1, 100)
                    npcSay("（内容太长已截断）" .. content)
                else
                    npcSay(content)
                end
            end
        end
    end))

    -- ============================================================
    -- 核心逻辑主循环
    -- ============================================================
    local lastPathCalcTime    = 0
    local currentWaypoints    = {}
    local currentWaypointIndex = 1

    -- ✅ 独立定时报数，避免与 Heartbeat 竞态（FIX: os.clock 竞态问题）
    task.delay(AUTO_REPORT_INTERVAL, function()
        while enabled and npc and npc.Parent do
            npcSay("检查了一下，现在服务器还是 " .. #Players:GetPlayers() .. " 个人呢~")
            lastCheckPeopleTime = os.clock()
            task.wait(AUTO_REPORT_INTERVAL)
        end
    end)

    -- 每隔 7 秒随机说一句闲话
    local IDLE_LINES = {
        "你好呀 7w7",
        "我好无聊 OvO",
        "我想吃火锅 QAQ",
        "在干嘛呢 :3",
        "月不月呀 7w7",
        "我会一直跟着你 OvO",
    }
    task.delay(7, function()
        while enabled and npc and npc.Parent do
            local line = IDLE_LINES[math.random(1, #IDLE_LINES)]
            npcSay(line)
            task.wait(7)
        end
    end)

    local logicLoop = RunService.Heartbeat:Connect(function(dt)
        if not enabled then return end

        -- ✅ [FIX 1] NPC 失效时用防抖标志防止递归
        if not npc or not npc.Parent or not hum or not root then
            if not isRecreating then
                isRecreating = true
                task.spawn(function()
                    task.wait(0.5)
                    pcall(createNPC)
                    isRecreating = false
                end)
            end
            return
        end
        if not myRoot or not myHum then return end

        local currentPos = root.Position
        local playerPos  = myRoot.Position
        local dist       = (currentPos - playerPos).Magnitude

        -- 超远距离瞬移
        if dist > MAX_FOLLOW_DISTANCE then
            root.CFrame = myRoot.CFrame * CFrame.new(3, 0, 3)
            npcSay("等等我，我瞬移过来啦:D")
            isFollowing    = false
            currentWaypoints = {}
            return
        end

        -- 【模仿模式】
        if isMimicking then
            local targetFollowPos = playerPos + (myRoot.CFrame.LookVector * -3)
            hum:MoveTo(targetFollowPos)
            root.CFrame = CFrame.new(root.Position, root.Position + myRoot.CFrame.LookVector)
            if myHum.FloorMaterial == Enum.Material.Air
                and hum.FloorMaterial ~= Enum.Material.Air then
                hum.Jump = true
            end
            hum.Sit       = myHum.Sit
            hum.HipHeight = myHum.HipHeight
            hum.WalkSpeed = math.max(myHum.WalkSpeed - 1, 1)  -- 模仿模式同样保持慢1点
            return
        end

        -- ── 玩家静止超7秒主动搭话 ────────────────────────────
        local pSpeed = Vector3.new(
            myRoot.AssemblyLinearVelocity.X, 0,
            myRoot.AssemblyLinearVelocity.Z).Magnitude
        if pSpeed < 0.5 then
            playerStillTime = playerStillTime + dt
            if playerStillTime >= 7 and not hasPokedIdle then
                hasPokedIdle = true
                local POKE_LINES = {
                    "你在干什么呀 :3",
                    "人呢人呢～",
                    "干啥呢 OvO",
                    "挂机了吗 DAD",
                }
                npcSay(POKE_LINES[math.random(1, #POKE_LINES)])
            end
        else
            -- 玩家一动，重置计时，下次静止后可以再次催话
            playerStillTime = 0
            hasPokedIdle    = false
        end

        -- ── 速度随机化：每4~8秒小幅波动一次 ──────────────────
        if os.clock() > nextSpeedChange then
            -- 偏移范围 -1.5 ~ 0：只允许更慢，绝不超过"玩家速度-1"
            npcSpeedOffset  = -(math.random() * 1.5)
            nextSpeedChange = os.clock() + 4 + math.random() * 4
        end
        -- 硬性上限：始终 ≤ 玩家速度 - 1，防止贴背
        local cap       = math.max(myHum.WalkSpeed - 1, 1)
        local baseSpeed = math.max(cap + npcSpeedOffset, 1)
        hum.WalkSpeed   = math.min(baseSpeed, cap)

        -- 【跟随模式】
        if isFollowing then
            -- ── 随机停顿：走路中途有概率发呆 ──────────────────
            -- 每帧约 0.02% 概率触发，平均约 50 秒一次，
            -- 但当距离 > 1.5×停驻距离时概率翻倍（走着走着忽然停）
            if not isPausing then
                local pauseChance = (dist > dynamicStopDist * 1.5) and 0.0004 or 0.0002
                if math.random() < pauseChance then
                    isPausing = true
                    task.spawn(function()
                        -- 停下发呆 0.8 ~ 2.5 秒
                        hum.WalkSpeed = 0
                        task.wait(0.8 + math.random() * 1.7)
                        if enabled and npc and npc.Parent then
                            -- 恢复速度，快步追上
                            -- 快步追赶：最多与玩家同速（不超过），保持压迫感但不贴背
                            hum.WalkSpeed = math.max(myHum.WalkSpeed - 1, 1)
                            task.wait(1.5)
                            if enabled and npc and npc.Parent then
                                local recapSpeed = math.max(myHum.WalkSpeed - 1, 1)
                                hum.WalkSpeed = math.min(
                                    math.max(recapSpeed + npcSpeedOffset, 1), recapSpeed)
                            end
                        end
                        isPausing = false
                    end)
                end
            end

            -- 发呆期间不更新寻路，就地等候
            if not isPausing then
                if os.clock() - lastPathCalcTime > 0.3 then
                    local waypoints = getPath(currentPos, playerPos)
                    if waypoints then
                        currentWaypoints     = waypoints
                        currentWaypointIndex = 2
                    end
                    lastPathCalcTime = os.clock()
                end

                if #currentWaypoints > 0 and currentWaypointIndex <= #currentWaypoints then
                    local waypoint = currentWaypoints[currentWaypointIndex]
                    hum:MoveTo(waypoint.Position)
                    if (currentPos - waypoint.Position).Magnitude < 3 then
                        currentWaypointIndex = currentWaypointIndex + 1
                    end
                    if waypoint.Action == Enum.PathWaypointAction.Jump then
                        hum.Jump = true
                    end
                else
                    hum:MoveTo(playerPos)
                end
            end

            -- ✅ [FIX 3] 防卡死：CanCollide 恢复块加 NPC 存活检查
            if root.AssemblyLinearVelocity.Magnitude < 1 and dist > 8 then
                stuckTime = stuckTime + dt
                if stuckTime > 1.5 then
                    hum.Jump  = true
                    stuckTime = 0
                    jumpCount = jumpCount + 1
                    if jumpCount >= 3 then
                        task.spawn(function()
                            for _, p in pairs(npc:GetChildren()) do
                                if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                                    p.CanCollide = false
                                end
                            end
                            task.wait(1.5)
                            -- ✅ 恢复前检查 NPC 是否仍存活
                            if not npc or not npc.Parent then return end
                            for _, p in pairs(npc:GetChildren()) do
                                if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                                    p.CanCollide = true
                                end
                            end
                            jumpCount = 0
                        end)
                    end
                end
            else
                stuckTime = 0
                jumpCount = 0
            end

            if runStartTime > 0 and not hasComplained
                and os.clock() - runStartTime > 5 then
                local COMPLAIN_LINES = {
                    "等等我 QAQ",
                    "好累呀 TAT",
                    "让我休息一下吧 T^T",
                    "不要再走了 DAD",
                }
                npcSay(COMPLAIN_LINES[math.random(1, #COMPLAIN_LINES)])
                hasComplained = true
            end

        else
            -- ── 原地待命 / 15秒闲逛 ──────────────────────────────
            -- 12格以内：NPC安静待命，只有玩家和NPC都接近静止时
            -- 才每15秒缓缓换一个观察位（半径6格内小幅移动）
            local playerSpeed = Vector3.new(
                myRoot.AssemblyLinearVelocity.X, 0,
                myRoot.AssemblyLinearVelocity.Z).Magnitude
            local npcSpeed = Vector3.new(
                root.AssemblyLinearVelocity.X, 0,
                root.AssemblyLinearVelocity.Z).Magnitude
            local bothStill = playerSpeed < 1 and npcSpeed < 1

            if dist <= IDLE_RADIUS then
                -- 在安静范围内：只有双方都静止才允许15秒小幅闲逛
                if bothStill and os.clock() - lastMoveTime > 15 then
                    -- 小幅随机位移（半径6格），不跑远
                    targetPos    = playerPos + Vector3.new(
                        math.random(-6, 6), 0, math.random(-6, 6))
                    lastMoveTime = os.clock()
                end
                -- 若还没到目标位置就继续走，否则原地待命
                if targetPos and (root.Position - targetPos).Magnitude > 2 then
                    hum:MoveTo(targetPos)
                else
                    -- 原地停下，不乱动
                    hum:MoveTo(root.Position)
                end
            else
                -- 超出待命范围但还未触发追赶：保持当前 targetPos 不变
                if targetPos then hum:MoveTo(targetPos) end
            end
        end

        -- 距离自动切换跟随状态（睡觉或坐下时不自动跟随）
        if not isSleeping and not isSitting then
            if dist > FOLLOW_START_DISTANCE then
                -- 真的走远了：先"愣"一下再追赶
                if not isFollowing and not isReacting then
                    isReacting = true
                    task.spawn(function()
                        -- 随机愣神 0.4 ~ 0.8 秒
                        task.wait(0.4 + math.random() * 0.4)
                        -- 愣完再确认还需要追（防止玩家瞬间走回来）
                        if not enabled or not npc or not npc.Parent then
                            isReacting = false
                            return
                        end
                        isFollowing      = true
                        runStartTime     = os.clock()
                        hasComplained    = false
                        currentWaypoints = {}
                        isReacting       = false
                    end)
                end
            elseif dist < dynamicStopDist then
                -- 追近到动态停驻距离，停下回到待命状态
                if isFollowing then
                    isFollowing      = false
                    isReacting       = false
                    isPausing        = false
                    runStartTime     = 0
                    hasComplained    = false
                    -- 每次停下随机选一个新停驻距离（2~8格）
                    dynamicStopDist  = 2 + math.random() * 6
                    targetPos        = root.Position
                    lastMoveTime     = os.clock()
                    currentWaypoints = {}
                end
            end
        end  -- end: not isSleeping and not isSitting
    end)
    table.insert(connections, logicLoop)
end

-- ============================================================
-- GUI 创建（可爱粉嫩风）
-- ============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name            = "NPC_Executor_GUI"
screenGui.Parent          = player:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn    = false
screenGui.DisplayOrder    = 100
screenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling

-- 颜色常量
local COLOR_OFF_BG     = Color3.fromRGB(255, 182, 193)  -- 浅玫瑰粉（关闭背景）
local COLOR_ON_BG      = Color3.fromRGB(255, 105, 150)  -- 深玫瑰粉（开启背景）
local COLOR_OFF_TEXT   = Color3.fromRGB(255, 255, 255)
local COLOR_ON_TEXT    = Color3.fromRGB(255, 255, 255)
local COLOR_OFF_STROKE = Color3.fromRGB(255, 150, 170)
local COLOR_ON_STROKE  = Color3.fromRGB(220, 60, 110)
local COLOR_SHADOW     = Color3.fromRGB(230, 130, 155)

-- 外层阴影框（模拟投影）
local shadowFrame = Instance.new("Frame")
shadowFrame.Name               = "Shadow"
shadowFrame.Size               = UDim2.new(0, 162, 0, 56)
shadowFrame.Position           = UDim2.new(1, -168, 0.7, 4)  -- 向右下偏移4px
shadowFrame.BackgroundColor3   = COLOR_SHADOW
shadowFrame.BackgroundTransparency = 0.55
shadowFrame.BorderSizePixel    = 0
shadowFrame.ZIndex             = 1
shadowFrame.Parent             = screenGui
local shadowCorner = Instance.new("UICorner")
shadowCorner.CornerRadius = UDim.new(0, 22)
shadowCorner.Parent       = shadowFrame

-- 主按钮
local mainBtn = Instance.new("TextButton")
mainBtn.Name                   = "MainToggleBtn"
mainBtn.Size                   = UDim2.new(0, 162, 0, 52)
mainBtn.Position               = UDim2.new(1, -170, 0.7, 0)
mainBtn.BackgroundColor3       = COLOR_OFF_BG
mainBtn.BackgroundTransparency = 0
mainBtn.Text                   = "🌸 伙伴：关"
mainBtn.TextColor3             = COLOR_OFF_TEXT
mainBtn.Font                   = Enum.Font.GothamBold
mainBtn.TextSize               = 17
mainBtn.AutoButtonColor        = false   -- 自己控制按下效果
mainBtn.Active                 = true
mainBtn.ZIndex                 = 2
mainBtn.Parent                 = screenGui

-- 圆角（pill形状）
local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 22)
btnCorner.Parent       = mainBtn

-- 柔和描边
local btnStroke = Instance.new("UIStroke")
btnStroke.Color       = COLOR_OFF_STROKE
btnStroke.Thickness   = 2.5
btnStroke.Transparency = 0.1
btnStroke.Parent      = mainBtn

-- 内发光装饰条（顶部高光线，营造立体感）
local highlight = Instance.new("Frame")
highlight.Name                 = "Highlight"
highlight.Size                 = UDim2.new(0.6, 0, 0, 3)
highlight.Position             = UDim2.new(0.2, 0, 0, 5)
highlight.BackgroundColor3     = Color3.fromRGB(255, 255, 255)
highlight.BackgroundTransparency = 0.55
highlight.BorderSizePixel      = 0
highlight.ZIndex               = 3
highlight.Parent               = mainBtn
local hlCorner = Instance.new("UICorner")
hlCorner.CornerRadius = UDim.new(1, 0)
hlCorner.Parent       = highlight

-- 按下时的缩放动画
local function tweenBtnScale(scaleX, scaleY)
    TweenService:Create(mainBtn, TweenInfo.new(0.1, Enum.EasingStyle.Back), {
        Size = UDim2.new(0, 162 * scaleX, 0, 52 * scaleY)
    }):Play()
end

mainBtn.MouseButton1Down:Connect(function()
    tweenBtnScale(0.94, 0.92)
end)
mainBtn.MouseButton1Up:Connect(function()
    tweenBtnScale(1, 1)
end)

makeDraggable(mainBtn)

-- 同步阴影跟随按钮（拖拽时阴影跟着动）
local function syncShadow()
    shadowFrame.Position = UDim2.new(
        mainBtn.Position.X.Scale,
        mainBtn.Position.X.Offset + 6,
        mainBtn.Position.Y.Scale,
        mainBtn.Position.Y.Offset + 5
    )
end

mainBtn.MouseButton1Click:Connect(function()
    enabled = not enabled

    if enabled then
        -- 开启：深粉 + 心形emoji + 弹跳动画
        mainBtn.Text         = "💕 伙伴：开"
        TweenService:Create(mainBtn, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            BackgroundColor3 = COLOR_ON_BG,
            TextColor3       = COLOR_ON_TEXT,
        }):Play()
        TweenService:Create(btnStroke, TweenInfo.new(0.25), {
            Color = COLOR_ON_STROKE,
        }):Play()
        TweenService:Create(shadowFrame, TweenInfo.new(0.25), {
            BackgroundColor3 = Color3.fromRGB(200, 60, 100),
        }):Play()
        -- 弹跳
        TweenService:Create(mainBtn, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 172, 0, 56),
        }):Play()
        task.delay(0.15, function()
            TweenService:Create(mainBtn, TweenInfo.new(0.2, Enum.EasingStyle.Bounce), {
                Size = UDim2.new(0, 162, 0, 52),
            }):Play()
        end)
        createNPC()
    else
        -- 关闭：浅粉 + 花emoji + 收缩动画
        mainBtn.Text         = "🌸 伙伴：关"
        TweenService:Create(mainBtn, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
            BackgroundColor3 = COLOR_OFF_BG,
            TextColor3       = COLOR_OFF_TEXT,
        }):Play()
        TweenService:Create(btnStroke, TweenInfo.new(0.25), {
            Color = COLOR_OFF_STROKE,
        }):Play()
        TweenService:Create(shadowFrame, TweenInfo.new(0.25), {
            BackgroundColor3 = COLOR_SHADOW,
        }):Play()
        if npc then
            npc:Destroy()
            npc = nil
        end
        clearConnections()
        if currentTTSSound then
            pcall(function() currentTTSSound:Stop() end)
            pcall(function() currentTTSSound:Destroy() end)
            currentTTSSound = nil
        end
    end

    syncShadow()
end)

-- ✅ [FIX 12] 退出清理：pcall 保护 + 检查 screenGui.Parent
player.Removing:Connect(function()
    pcall(function()
        enabled = false
        if npc then npc:Destroy() end
        clearConnections()
        if currentTTSSound then
            pcall(function() currentTTSSound:Stop() end)
            pcall(function() currentTTSSound:Destroy() end)
        end
        if screenGui and screenGui.Parent then
            screenGui:Destroy()
        end
    end)
end)
