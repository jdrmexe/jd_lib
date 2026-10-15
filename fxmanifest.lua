fx_version 'cerulean'
game { 'gta5' }

name        'jd_lib'
author      'JD Development & Designs'
-- Allows other resources to list `dependencies { 'jd_lib' }` in their
-- own fxmanifest.lua and FiveM will ensure jd_lib starts first.
provide 'jd_lib'

ui_page 'modules/notify/html/index.html'

files {
    'modules/notify/html/index.html',
    'modules/notify/html/style.css',
    'modules/notify/html/app.js',
}

server_scripts {
    'addons/joinserver-event/*.lua',
    'addons/*.lua',
}

shared_scripts {
    'shared/lib.lua',
}

client_scripts {
    'modules/notify/client.lua',
    'addons/joinserver-event/*.lua',
    'client/main.lua',
    'addons/*.lua',
}

-- Export so other resources can call: local lib = exports['jd_lib']:getLib()
exports {
    'getLib',
}
