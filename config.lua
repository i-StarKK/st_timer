Config = {}

Config.Framework = 'vorp'
Config.Notification = 'vorp'
Config.Language = 'EN'
Config.Debug = false
Config.APIKey = 'CHANGE_ME'
Config.Command = 'timer'
Config.ConsolePrints = true

Config.StormWarning = {
    enabled = true,
    time = 2,
}

Config.Permissions = {
    Identifiers = {
        enabled = false,
        list = { 'steam:xxxxx', 'license:xxxxx' },
    },
    AcePerms = {
        enabled = true,
        list = { 'command', 'st_timer.staff' },
    },
    Discord = {
        enabled = false,
        list = { 'xxxxx', 'xxxxx' },
    },
}

Config.Weather = {
    method = 'game',

    Game = {
        dynamic_time = 10,
        rain_chance = 20,
        thunder_chance = 20,
        fog_chance = 20,
        snow_chance = 5,
        groups = {
            [1] = { 'SUNNY', 'CLOUDS', 'MISTY', 'OVERCAST' },
            [2] = { 'RAIN', 'DRIZZLE', 'THUNDER', 'THUNDERSTORM' },
            [3] = { 'FOG', 'SANDSTORM' },
            [4] = { 'SNOW', 'SNOWLIGHT', 'BLIZZARD', 'WHITEOUT' },
        },
    },

    Real = {
        city = 'London',
        check_interval = 30,
        types = {
            ['SUNNY'] = { 800, 801 },
            ['CLOUDS'] = { 802, 803 },
            ['OVERCAST'] = { 804 },
            ['MISTY'] = { 701, 711, 721 },
            ['DRIZZLE'] = { 300, 301, 302, 310, 311, 312, 313, 314, 321 },
            ['RAIN'] = { 500, 501, 502, 503, 504, 511, 520, 521, 522, 531 },
            ['THUNDER'] = { 200, 201, 202, 210, 211, 212, 221, 230, 231, 232 },
            ['THUNDERSTORM'] = { 200, 201, 202, 210, 211, 212, 221 },
            ['FOG'] = { 741 },
            ['SANDSTORM'] = { 731, 751, 761, 762, 771, 781 },
            ['SNOWLIGHT'] = { 600, 611, 615, 616 },
            ['SNOW'] = { 601, 620, 621 },
            ['BLIZZARD'] = { 602, 612, 613, 622 },
            ['WHITEOUT'] = { 602 },
        },
    },
}

Config.Time = {
    method = 'game',

    Game = {
        cycle_speed = 5,
    },

    Real = {
        city = 'London',
        utc_offset = 0,
        transition_speed = 10,
    },
}

Config.Locales = {
    invalid_permissions = 'You do not have permissions to use this command.',
    drop_player = 'Unauthorized access detected. You have been removed.',
    command_name = 'Timer',
    chat_suggestion = 'Opens the time and weather management panel.',
}

if GetResourceState('Badger_Discord_API') ~= 'started' then
    Config.Permissions.Discord.enabled = false
end

Config.Time.Game.cycle_speed = math.max(1, math.min(10, math.ceil(Config.Time.Game.cycle_speed)))
