local state = {}
local resName = GetCurrentResourceName()
local weatherGroup = Config.Weather.Game.groups[1]
local lastWeatherGroup = weatherGroup
local lastWeatherTable = {}
local timesChanged = 0
local realTimezone = 0

if Config.Weather.method ~= 'game' and Config.Weather.method ~= 'real' then
    print('^1[st_timer] Invalid Config.Weather.method: ' .. Config.Weather.method .. '^0')
end

if Config.Time.method ~= 'game' and Config.Time.method ~= 'real' then
    print('^1[st_timer] Invalid Config.Time.method: ' .. Config.Time.method .. '^0')
end

if (Config.Weather.method == 'real' or Config.Time.method == 'real') and Config.APIKey == 'CHANGE_ME' then
    print('^1[st_timer] API key not configured.^0')
end

local function foundInGroup(group, weather)
    for _, v in ipairs(group) do
        if v == weather then return true end
    end
    return false
end

local function getRealTime()
    local dt = os.time() + realTimezone
    return os.date("!*t", dt).hour, os.date("!*t", dt).min
end

function GetRealWorldData(city)
    local data = {}
    PerformHttpRequest('https://api.openweathermap.org/data/2.5/weather?q=' .. city .. '&appid=' .. Config.APIKey .. '&units=metric', function(code, result)
        if code == 200 then
            local decoded = json.decode(result)
            for weatherName, codes in pairs(Config.Weather.Real.types) do
                for i = 1, #codes do
                    if codes[i] == decoded.weather[1].id then
                        data.weather = weatherName
                        data.info = {
                            weather = decoded.weather[1].main,
                            weather_description = decoded.weather[1].description,
                            country = decoded.sys.country,
                            city = decoded.name,
                        }
                        break
                    end
                end
            end
            realTimezone = decoded.timezone
            data.hours, data.mins = getRealTime()
        else
            print('^1[st_timer] Failed to fetch weather data. Check city name or API key.^0')
        end
    end, 'GET', '', { ['Content-Type'] = 'application/json' })
    local timeout = 0
    while not data.weather and timeout <= 100 do Wait(0) timeout = timeout + 1 end
    return data
end

function PermissionsCheck(source)
    if Config.Permissions.Identifiers.enabled then
        local ids = {}
        for _, id in pairs(GetPlayerIdentifiers(source)) do
            ids[#ids + 1] = { full = id, trimmed = id:sub(id:find(':') + 1) }
        end
        for _, allowed in pairs(Config.Permissions.Identifiers.list) do
            for _, pid in pairs(ids) do
                if pid.full == allowed:lower() or pid.trimmed == allowed:lower() then
                    return true
                end
            end
        end
    end

    if Config.Permissions.AcePerms.enabled then
        for _, perm in pairs(Config.Permissions.AcePerms.list) do
            if IsPlayerAceAllowed(source, perm) then return true end
        end
    end

    if Config.Permissions.Discord.enabled then
        local roles = exports.Badger_Discord_API:GetDiscordRoles(source)
        for _, allowed in pairs(Config.Permissions.Discord.list) do
            for _, role in pairs(roles) do
                if allowed == role then return true end
            end
        end
    end

    return false
end

local function notify(source, message)
    if not source or not message then return end
    if Config.Notification == 'vorp' then
        TriggerClientEvent('vorp:TipRight', source, message, 4000)
    elseif Config.Notification == 'chat' then
        TriggerClientEvent('chatMessage', source, message)
    end
end

CreateThread(function()
    if Config.Weather.method == 'real' and Config.Time.method == 'real' then
        local weatherData = GetRealWorldData(Config.Weather.Real.city)
        state.weather = weatherData.weather or 'SUNNY'
        local timeData = GetRealWorldData(Config.Time.Real.city)
        state.real_info = timeData.info
        state.hours = timeData.hours or 8
        state.mins = timeData.mins or 0
        state.dynamic = false
        state.freeze = false
        state.instantweather = false
        state.instanttime = false
    elseif Config.Weather.method == 'real' then
        local data = GetRealWorldData(Config.Weather.Real.city)
        state.real_info = data.info
        state.weather = data.weather or 'SUNNY'
        state.dynamic = false
        state.instantweather = false
    elseif Config.Time.method == 'real' then
        local data = GetRealWorldData(Config.Time.Real.city)
        state.real_info = data.info
        state.hours = data.hours or 8
        state.mins = data.mins or 0
        state.freeze = false
        state.instanttime = false
    end

    state.weathermethod = Config.Weather.method
    state.timemethod = Config.Time.method

    local settings = json.decode(LoadResourceFile(resName, './settings.txt'))
    if state.weather == nil then state.weather = settings.weather or 'SUNNY' end
    if state.hours == nil then state.hours = settings.hours or 8 end
    if state.mins == nil then state.mins = settings.mins or 0 end
    if state.dynamic == nil then state.dynamic = settings.dynamic == true end
    if state.freeze == nil then state.freeze = settings.freeze == true end
    if state.instanttime == nil then state.instanttime = settings.instanttime == true end
    if state.instantweather == nil then state.instantweather = settings.instantweather == true end
    state.blackout = settings.blackout == true
    state.tsunami = false

    print('^3[' .. resName .. '] Settings loaded.^0')

    Wait(2000)
    local temp = json.decode(json.encode(state))
    temp.instanttime = true
    temp.instantweather = true
    TriggerClientEvent('st_timer:ForceUpdate', -1, temp)
end)

RegisterCommand(Config.Command, function(source)
    if PermissionsCheck(source) then
        TriggerClientEvent('st_timer:OpenUI', source, state)
    else
        notify(source, Config.Locales.invalid_permissions)
    end
end, false)

TriggerEvent('chat:addSuggestion', '/' .. Config.Command, Config.Locales.chat_suggestion)

RegisterServerEvent('st_timer:SyncMe', function()
    local src = source
    local temp = json.decode(json.encode(state))
    temp.instanttime = true
    temp.instantweather = true
    TriggerClientEvent('st_timer:ForceUpdate', src, temp)
end)

RegisterServerEvent('st_timer:SyncBasics', function(data)
    local src = source
    if data.weather then
        TriggerClientEvent('st_timer:SyncWeather', src, { weather = state.weather, instantweather = true })
    end
    if data.time then
        TriggerClientEvent('st_timer:SyncTime', src, { hours = state.hours, mins = state.mins })
    end
end)

RegisterServerEvent('st_timer:ForceUpdate', function(data)
    local src = source
    if not PermissionsCheck(src) then
        DropPlayer(src, Config.Locales.drop_player)
        return
    end

    if data.hours then
        state.hours = data.hours
        state.mins = data.mins
    end

    if data.weather and data.weather ~= state.weather then
        state.weather = data.weather
        timesChanged = 0
        lastWeatherTable = {}
        for _, group in pairs(Config.Weather.Game.groups) do
            if foundInGroup(group, state.weather) then
                weatherGroup = group
                break
            end
        end
        for _, wt in ipairs(weatherGroup) do
            if wt == state.weather then break end
            lastWeatherTable[wt] = true
            timesChanged = timesChanged + 1
        end
    end

    if data.dynamic ~= nil then state.dynamic = data.dynamic end
    if data.blackout ~= nil then state.blackout = data.blackout end
    if data.freeze ~= nil then
        state.freeze = data.freeze
        data.hours = state.hours
        data.mins = state.mins
    end
    if data.instanttime ~= nil then state.instanttime = data.instanttime end
    if data.instantweather ~= nil then state.instantweather = data.instantweather end
    if data.tsunami ~= nil and Config.StormWarning.enabled then state.tsunami = data.tsunami end

    if data.weathermethod ~= nil and data.weathermethod ~= state.weathermethod then
        state.weathermethod = data.weathermethod
        weatherMethodChange(data.weathermethod)
    end
    if data.timemethod ~= nil and data.timemethod ~= state.timemethod then
        state.timemethod = data.timemethod
        timeMethodChange(data.timemethod)
    end

    TriggerClientEvent('st_timer:ForceUpdate', -1, data, src)
end)

local function realWeatherChange()
    local data = GetRealWorldData(Config.Weather.Real.city)
    state.real_info = data.info
    if data.weather ~= state.weather then
        state.weather = data.weather
        TriggerClientEvent('st_timer:SyncWeather', -1, { weather = state.weather, instantweather = false })
        if Config.ConsolePrints then
            print('^3[' .. resName .. '] Weather: ' .. state.weather .. '^0')
        end
    end
end

local function gameWeatherChange()
    if timesChanged >= #weatherGroup then
        weatherGroup = chooseWeatherType()
        timesChanged = 0
        lastWeatherTable = {}
        lastWeatherGroup = weatherGroup
    end

    for _, w in ipairs(weatherGroup) do
        if not lastWeatherTable[w] then
            if w == 'THUNDER' and math.random(1, 100) > Config.Weather.Game.thunder_chance then
                lastWeatherTable[w] = true
                timesChanged = timesChanged + 1
                break
            end
            state.weather = w
            lastWeatherTable[w] = true
            timesChanged = timesChanged + 1
            TriggerClientEvent('st_timer:SyncWeather', -1, { weather = state.weather, instantweather = state.instantweather })
            if Config.ConsolePrints then
                print('^3[' .. resName .. '] Weather: ' .. state.weather .. '^0')
            end
            break
        end
    end
end

function weatherMethodChange(method)
    if method == 'real' then
        state.weathermethod = 'real'
        state.dynamic = false
        state.instantweather = false
        realWeatherChange()
    elseif method == 'game' then
        state.weathermethod = 'game'
        gameWeatherChange()
    end
    TriggerClientEvent('st_timer:WeatherMethodChange', -1, method)
end

CreateThread(function()
    Wait(1000)
    while true do
        if state.weathermethod == 'real' then
            realWeatherChange()
            Wait(Config.Weather.Real.check_interval * 60 * 1000)
        else
            Wait(1000)
        end
    end
end)

CreateThread(function()
    Wait(1000)
    while true do
        if state.weathermethod == 'game' and state.dynamic then
            gameWeatherChange()
            Wait(Config.Weather.Game.dynamic_time * 60 * 1000)
        else
            Wait(1000)
        end
    end
end)

local function realTimeChange()
    state.hours, state.mins = getRealTime()
    TriggerClientEvent('st_timer:SyncTime', -1, { hours = state.hours, mins = state.mins })
end

function gameTimeChange(time)
    local total = (state.hours * 60 + state.mins + time) % (24 * 60)
    if total < 0 then total = total + 24 * 60 end
    state.hours = math.floor(total / 60)
    state.mins = total % 60
    TriggerClientEvent('st_timer:SyncTime', -1, { hours = state.hours, mins = state.mins })
end

function timeMethodChange(method)
    if method == 'real' then
        state.timemethod = 'real'
        state.freeze = false
        state.instanttime = false
        realTimeChange()
    elseif method == 'game' then
        state.timemethod = 'game'
        TriggerClientEvent('st_timer:SyncTime', -1, { hours = state.hours, mins = state.mins })
    end
    TriggerClientEvent('st_timer:TimeMethodChange', -1, method)
end

RegisterServerEvent('st_timer:SetNewGameTime', function(time)
    state.hours = time.hours
    state.mins = time.mins
end)

CreateThread(function()
    Wait(1000)
    while true do
        if state.timemethod == 'real' then
            local secs = os.date("!*t", os.time() + realTimezone).sec
            local waitTime = (60 - secs) * 1000
            if waitTime == 0 then waitTime = 60000 end
            realTimeChange()
            Wait(waitTime)
        else
            Wait(1000)
        end
    end
end)

CreateThread(function()
    Wait(1000)
    local waitTime = Config.Time.Game.cycle_speed * 1000
    while true do
        if state.timemethod == 'game' and not state.freeze then
            gameTimeChange(1)
            Wait(waitTime)
        else
            Wait(1000)
        end
    end
end)

function chooseWeatherType()
    math.randomseed(GetGameTimer())
    local groups = Config.Weather.Game.groups

    local function getRandomGroup(excluded)
        local available = {}
        for i, g in ipairs(groups) do
            if not excluded[g] then
                available[#available + 1] = { index = i, group = g }
            end
        end
        if #available == 0 then return 1 end
        return available[math.random(1, #available)].index
    end

    local result = math.random(1, #groups)

    if result == 2 then
        if math.random(1, 100) > Config.Weather.Game.rain_chance then
            result = getRandomGroup({ [groups[result]] = true })
        end
    elseif result == 3 then
        if math.random(1, 100) > Config.Weather.Game.fog_chance then
            result = getRandomGroup({ [groups[result]] = true })
        end
    elseif result == 4 then
        if math.random(1, 100) > Config.Weather.Game.snow_chance then
            result = getRandomGroup({ [groups[result]] = true })
        end
    end

    return groups[result]
end

RegisterServerEvent('st_timer:ToggleInstant', function(action, val)
    if action == 'time' then
        state.instanttime = val
    elseif action == 'weather' then
        state.instantweather = val
    end
end)

local function saveSettings()
    SaveResourceFile(resName, 'settings.txt', json.encode(state), -1)
    print('^3[' .. resName .. '] Settings saved.^0')
end

RegisterServerEvent('st_timer:SaveSettings', function()
    saveSettings()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == resName then saveSettings() end
end)

AddEventHandler('txAdmin:events:scheduledRestart', function(eventData)
    if eventData.secondsRemaining == math.ceil(Config.StormWarning.time * 60) then
        saveSettings()
        if not Config.StormWarning.enabled then return end
        state.tsunami = true
        TriggerClientEvent('st_timer:StartStormWarning', -1, true)
    end
end)

RegisterServerEvent('st_timer:StartStormWarning', function(val)
    local src = source
    if not Config.StormWarning.enabled then return end
    if src ~= 0 or not PermissionsCheck(src) then return end
    state.tsunami = val
    TriggerClientEvent('st_timer:StartStormWarning', -1, val)
end)

function GetWeather()
    return state
end

function GetAllData()
    return state
end

function GetRealData()
    local data
    if Config.Weather.method == 'real' then
        data = GetRealWorldData(Config.Weather.Real.city)
    elseif Config.Time.method == 'real' then
        data = GetRealWorldData(Config.Time.Real.city)
    else
        return nil
    end
    return {
        hours = data.hours,
        mins = data.mins,
        rdr_weather = data.weather,
        real_weather = data.info.weather,
        real_weather_description = data.info.weather_description,
        country = data.info.country,
        city = data.info.city,
    }
end

function SetTime(hours, mins)
    if type(hours) ~= 'number' or type(mins) ~= 'number' then return false end
    hours = math.floor(hours)
    mins = math.floor(mins)
    if hours < 0 or hours > 23 or mins < 0 or mins > 59 then return false end
    state.hours = hours
    state.mins = mins
    TriggerClientEvent('st_timer:ForceUpdate', -1, { hours = state.hours, mins = state.mins, instanttime = true, freeze = state.freeze })
    return true
end

function SetWeather(weather)
    if type(weather) ~= 'string' then return false end
    local valid = false
    for _, group in pairs(Config.Weather.Game.groups) do
        for _, wt in ipairs(group) do
            if wt == weather then valid = true break end
        end
        if valid then break end
    end
    if not valid then
        for wt in pairs(Config.Weather.Real.types) do
            if wt == weather then valid = true break end
        end
    end
    if not valid then return false end

    if weather ~= state.weather then
        state.weather = weather
        timesChanged = 0
        lastWeatherTable = {}
        for _, group in pairs(Config.Weather.Game.groups) do
            if foundInGroup(group, state.weather) then
                weatherGroup = group
                break
            end
        end
        for _, wt in ipairs(weatherGroup) do
            if wt == state.weather then break end
            lastWeatherTable[wt] = true
            timesChanged = timesChanged + 1
        end
    end

    TriggerClientEvent('st_timer:ForceUpdate', -1, { weather = state.weather, instantweather = true, freeze = state.freeze })
    return true
end
