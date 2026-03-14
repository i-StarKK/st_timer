fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
author 'ST Scripts'
description 'Time & Weather Management for RedM'
version '1.0.0'
lua54 'yes'

shared_scripts {
    'config.lua',
}

client_scripts {
    'client/*.lua',
}

server_scripts {
    'server/*.lua',
}

ui_page 'html/index.html'
files {
    'html/index.html',
    'html/css/*.css',
    'html/js/*.js',
    'html/font/*.svg',
    'html/font/*.ttf',
    'html/font/*.eot',
    'html/font/*.woff',
    'html/font/*.woff2',
    'html/images/**/*.svg',
    'html/sound/*.ogg',
}

exports {
    'GetWeather',
    'GetAllData',
    'GetPauseSyncState',
}

server_exports {
    'GetWeather',
    'GetAllData',
    'GetRealData',
    'SetTime',
    'SetWeather',
}
