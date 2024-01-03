fx_version  'cerulean'
game        'gta5'

name        'Vehicle Handler'
description 'FiveM vehicle collision/damage handling.'
author      'QuantumMalice'
version     '1.0.0'

dependencies {
    'ox_lib',
}

shared_scripts {
    '@ox_lib/init.lua',
}

client_scripts {
    'client.lua',
}

server_scripts {
    'server.lua',
}

files {
    'data/*.lua',
    'modules/*.lua',
    'modules/class/*.lua',
}

lua54 'yes'