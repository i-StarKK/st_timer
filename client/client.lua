print('st_timer/client Loading')

local state = {}
local nuiOpen = false
local originalTime = {}
local timeTransition = false
local forcedInstant = false
local mySource = GetPlayerServerId(PlayerId())
local pauseSync = { active = false }

local function setTimeOverride(h, m, s)
    Citizen.InvokeNative(0x669E223E64B1903C, h, m, s, 0, true)
end

local function changeWeather(weather, instant)
    local t = instant and 1.0 or 15.0
    Citizen.InvokeNative(0x59174F1AFE095B5A, GetHashKey(string.lower(weather)), true, false, true, t, false)
end

local function changeBlackout(val)
    Citizen.InvokeNative(0x1268615ACE24D504, val)
end

local function smoothChangeTime(data, speed)
    local curTotal = GetClockHours() * 3600 + GetClockMinutes() * 60 + GetClockSeconds()
    local tgtTotal = data.hours * 3600 + data.mins * 60 + (data.seconds or 0)
    if tgtTotal < curTotal then tgtTotal = tgtTotal + 86400 end

    local startMs = GetGameTimer()
    local duration = speed * 1000
    while GetGameTimer() - startMs < duration do
        local p = (GetGameTimer() - startMs) / duration
        local total = (curTotal + (tgtTotal - curTotal) * p) % 86400
        setTimeOverride(math.floor(total / 3600) % 24, math.floor((total % 3600) / 60) % 60, math.floor(total % 60))
        if forcedInstant then break end
        Wait(0)
    end
    if forcedInstant then
        setTimeOverride(state.hours, state.mins, 0)
        return
    end
    setTimeOverride(data.hours, data.mins, data.seconds or 0)
end

CreateThread(function()
    Wait(5000)
    while true do
        Wait(1000)
        if NetworkIsSessionStarted() then
            TriggerServerEvent('st_timer:SyncMe', { time = true, weather = true })
            break
        end
    end
end)

TriggerEvent('chat:addSuggestion', '/' .. Config.Command, Config.Locales.chat_suggestion)

function GetWeather() return state end
function GetAllData() return state end
function GetPauseSyncState() return pauseSync.active end

RegisterNetEvent('st_timer:OpenUI', function(values)
    TriggerEvent('st_timer:ToggleNUI')
    values.game_build = 0
    values.original_timemethod = Config.Time.method
    values.original_weathermethod = Config.Weather.method
    originalTime = { hours = values.hours, mins = values.mins }
    SendNUIMessage({ action = 'open', values = values })
end)

RegisterNetEvent('st_timer:PauseSync', function(val, hours)
    if val == pauseSync.active then return end
    if val then
        pauseSync.active = true
        changeWeather('SUNNY', true)
        while pauseSync.active do
            Wait(0)
            setTimeOverride(hours or 20, 0, 0)
        end
    else
        pauseSync.active = false
        Wait(300)
        TriggerServerEvent('st_timer:SyncBasics', { weather = true, time = true })
    end
end)

RegisterNetEvent('st_timer:ForceUpdate', function(data, src)
    if not pauseSync.active then
        if data.weather ~= nil then
            changeWeather(data.weather, data.instantweather)
            state.weather = data.weather
        end

        if (data.hours ~= nil and data.hours ~= state.hours) or (data.mins ~= nil and data.mins ~= state.mins) then
            if not data.instanttime then
                smoothChangeTime(data, 1)
                state.hours = data.hours
                state.mins = data.mins
                if src == mySource then
                    TriggerServerEvent('st_timer:SetNewGameTime', { hours = data.hours, mins = data.mins })
                end
            else
                forcedInstant = true
                state.hours = data.hours
                state.mins = data.mins
                setTimeOverride(state.hours, state.mins, 0)
                Wait(1000)
                forcedInstant = false
            end
        end
    end

    state.freeze = data.freeze
    CreateThread(function()
        while state.freeze and not pauseSync.active do
            Wait(0)
            setTimeOverride(data.hours, data.mins, 0)
        end
    end)

    if data.blackout ~= nil and data.blackout ~= state.blackout then
        state.blackout = data.blackout
        changeBlackout(state.blackout)
    end

    if data.tsunami ~= nil and Config.StormWarning.enabled and data.tsunami ~= state.tsunami then
        state.tsunami = data.tsunami
        TriggerEvent('st_timer:StartStormWarning', data.tsunami)
    end

    if data.timemethod ~= nil then state.timemethod = data.timemethod end
    if data.weathermethod ~= nil then state.weathermethod = data.weathermethod end
end)

RegisterNetEvent('st_timer:SyncWeather', function(data)
    if not pauseSync.active then
        state.weather = data.weather
        changeWeather(state.weather, data.instantweather)
    end
end)

RegisterNetEvent('st_timer:SyncTime')
AddEventHandler('st_timer:SyncTime', function(data)
    if pauseSync.active or state.freeze then return end
    local speed = state.timemethod == 'game' and 1 or Config.Time.Real.transition_speed
    timeTransition = true
    smoothChangeTime(data, speed)
    timeTransition = false
    state.hours, state.mins = data.hours, data.mins
end)

CreateThread(function()
    while true do
        Wait(0)
        if not timeTransition and not state.freeze and not forcedInstant then
            if state.hours and state.mins then
                setTimeOverride(state.hours, state.mins, 0)
            end
        end
    end
end)

local stormCanceled = false
RegisterNetEvent('st_timer:StartStormWarning', function(val)
    if not Config.StormWarning.enabled then return end
    if val then
        pauseSync.active = true
        pauseSync.hours = state.hours
        stormCanceled = false
        changeWeather('THUNDERSTORM', false)
        Wait(Config.StormWarning.time * 60 * 1000 / 4 * 2)
        if stormCanceled then return end
        changeBlackout(true)
        SendNUIMessage({ action = 'playsound' })
    else
        pauseSync.active = false
        stormCanceled = true
        TriggerServerEvent('st_timer:SyncMe')
    end
end)

RegisterNUICallback('close', function()
    nuiOpen = false
end)

RegisterNUICallback('instanttime', function(data)
    TriggerServerEvent('st_timer:ToggleInstant', 'time', data.instanttime)
end)

RegisterNUICallback('instantweather', function(data)
    TriggerServerEvent('st_timer:ToggleInstant', 'weather', data.instantweather)
end)

RegisterNUICallback('change', function(data)
    if data.values.hours ~= nil and data.values.hours == originalTime.hours and data.values.mins ~= nil and data.values.mins == originalTime.mins then
        data.values.hours = nil
        data.values.mins = nil
    end
    originalTime = {}
    TriggerServerEvent('st_timer:ForceUpdate', data.values)
    if data.savesettings then
        nuiOpen = false
        Wait(2000)
        TriggerServerEvent('st_timer:SaveSettings')
    end
end)

RegisterNetEvent('st_timer:WeatherMethodChange', function(method)
    state.weathermethod = method
    if method == 'real' then
        state.dynamic = false
        state.instantweather = false
    end
end)

RegisterNetEvent('st_timer:TimeMethodChange', function(method)
    state.timemethod = method
    if method == 'real' then
        state.freeze = false
        state.instanttime = false
    end
end)

RegisterNetEvent('st_timer:ToggleNUI')
AddEventHandler('st_timer:ToggleNUI', function()
    nuiOpen = true
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    while nuiOpen do
        Wait(0)
        DisableAllControlActions(0)
    end
    SetNuiFocus(false, false)
end)
