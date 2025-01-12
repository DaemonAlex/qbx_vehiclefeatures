fx_version 'cerulean'
game 'gta5'

description 'qbx_vehiclefeatures'
repository 'https://github.com/0Programmer/qbx_vehiclefeatures'
version '1.2.4'
author '0Programmer'

ox_lib 'locale'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
}

client_scripts {
    '@qbx_core/modules/playerdata.lua',
    'client/*.lua',
}

server_scripts {
    'server/*.lua',
}

files {
    'config/client.lua',
    'locales/*.json',
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'