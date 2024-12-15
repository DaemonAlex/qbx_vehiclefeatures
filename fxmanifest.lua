fx_version 'cerulean'
game 'gta5'

description 'qbx_hidetrunk'
repository 'https://github.com/Qbox-project/qbx_hidetrunk'
version '1.0.0'
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
