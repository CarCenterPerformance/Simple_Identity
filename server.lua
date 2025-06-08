ESX = exports['es_extended']:getSharedObject()

ESX.RegisterServerCallback('esx_license:getLicenses', function(src, cb)
    local xPlayer = ESX.GetPlayerFromId(src)

    exports.oxmysql:fetch('SELECT type FROM user_licenses WHERE owner = ?', {
        xPlayer.identifier
    }, function(result)
        cb(result)
    end)
end)

RegisterNetEvent('esx_license:showToPlayer', function(target)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local targetPlayer = ESX.GetPlayerFromId(target)

    if not targetPlayer then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Fehler',
            description = 'Spieler nicht gefunden.',
            type = 'error'
        })
        return
    end

    exports.oxmysql:fetch('SELECT type FROM user_licenses WHERE owner = ?', {
        xPlayer.identifier
    }, function(result)
        TriggerClientEvent('esx_license:showLicensesToClient', target, result, xPlayer.getName())
    end)
end)
