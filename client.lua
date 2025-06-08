ESX = exports["es_extended"]:getSharedObject()


RegisterCommand('openlicenses', function()
    TriggerEvent('esx_license:showOwnLicenses')
end)

RegisterKeyMapping('openlicenses', 'Öffne Lizenz-Menü', 'keyboard', 'F5')

RegisterNetEvent('esx_license:showOwnLicenses', function()
    ESX.TriggerServerCallback('esx_license:getLicenses', function(licenses)
        local options = {}

        for _, license in ipairs(Config.Licenses) do
            local hasLicense = false
            for _, l in ipairs(licenses) do
                if l.type == license.type then
                    hasLicense = true
                    break
                end
            end

            table.insert(options, {
                title = license.label,
                description = hasLicense and '✅ Vorhanden' or '❌ Nicht vorhanden',
                disabled = true
            })
        end

        lib.registerContext({
            id = 'license_menu',
            title = 'Meine Lizenzen',
            options = {
                {
                    title = 'Lizenzen anzeigen',
                    description = 'Zeige einem Spieler deine Lizenzen',
                    menu = 'license_show_menu'
                },
                { title = 'Lizenzen:', menu = 'license_submenu' }
            }
        })

        lib.registerContext({
            id = 'license_submenu',
            title = 'Lizenzen',
            menu = 'license_menu',
            options = options
        })

        lib.registerContext({
            id = 'license_show_menu',
            title = 'Lizenzen zeigen',
            menu = 'license_menu',
            options = {
                {
                    title = '🧍 Spieler in der Nähe',
                    description = 'Zeige einem nahen Spieler deine Lizenzen',
                    onSelect = function()
                        showAnimation()
                        local playerPed = PlayerPedId()
                        local players = GetActivePlayers()
                        local closestPlayer, closestDistance = -1, 999.0
                        local coords = GetEntityCoords(playerPed)

                        for _, player in ipairs(players) do
                            local targetPed = GetPlayerPed(player)
                            if targetPed ~= playerPed then
                                local dist = #(coords - GetEntityCoords(targetPed))
                                if dist < closestDistance then
                                    closestDistance = dist
                                    closestPlayer = GetPlayerServerId(player)
                                end
                            end
                        end

                        if closestPlayer ~= -1 and closestDistance < 3.0 then
                            TriggerServerEvent('esx_license:showToPlayer', closestPlayer)
                            lib.notify({
                                title = 'Lizenzen',
                                description = 'Du zeigst deine Lizenzen einem Spieler in der Nähe.',
                                type = 'success',
                                position = 'top'
                            })
                        else
                            lib.notify({
                                title = 'Kein Spieler gefunden',
                                description = 'Niemand in der Nähe!',
                                type = 'error',
                                position = 'top'
                            })
                        end
                    end
                },
                {
                    title = '🔢 Spieler-ID eingeben',
                    description = 'Zeige einem bestimmten Spieler (Server-ID) deine Lizenzen',
                    onSelect = function()
                        showAnimation()
                        local playerId = lib.inputDialog('Spieler zeigen', {'Server ID'})
                        if playerId and playerId[1] then
                            TriggerServerEvent('esx_license:showToPlayer', tonumber(playerId[1]))
                            lib.notify({
                                title = 'Lizenzen',
                                description = 'Du hast deine Lizenzen an Spieler #' .. playerId[1] .. ' gesendet.',
                                type = 'success',
                                position = 'top'
                            })
                        else
                            lib.notify({
                                title = 'Abgebrochen',
                                description = 'Keine ID eingegeben.',
                                type = 'error',
                                position = 'top'
                            })
                        end
                    end
                }
            }
        })

        lib.showContext('license_menu')
    end)
end)

RegisterNetEvent('esx_license:showLicensesToClient', function(data, name)
    local licenseTexts = {}

    for _, license in ipairs(Config.Licenses) do
        local hasLicense = false
        for _, l in ipairs(data) do
            if l.type == license.type then
                hasLicense = true
                break
            end
        end
        table.insert(licenseTexts, string.format("%s: %s", license.label, hasLicense and "✅" or "❌"))
    end

    lib.notify({
        title = name .. ' zeigt dir seine Lizenzen',
        description = table.concat(licenseTexts, "\n"),
        type = 'inform',
        position = 'top'
    })
end)

-- Animation beim Lizenz zeigen (Tablet-ähnlich)
function showAnimation()
    local playerPed = PlayerPedId()
    local tabletModel = `prop_cs_tablet` -- oder `prop_tablet_02` je nach Style

    RequestModel(tabletModel)
    while not HasModelLoaded(tabletModel) do
        Wait(10)
    end

    RequestAnimDict("amb@world_human_seat_wall_tablet@female@base")
    while not HasAnimDictLoaded("amb@world_human_seat_wall_tablet@female@base") do
        Wait(10)
    end

    local coords = GetEntityCoords(playerPed)
    local tabletProp = CreateObject(tabletModel, coords.x, coords.y, coords.z + 0.2, true, true, false)

    -- Stelle sicher, dass der Spieler es richtig hält
    AttachEntityToEntity(tabletProp, playerPed, GetPedBoneIndex(playerPed, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)

    -- Animation abspielen
    TaskPlayAnim(playerPed, "amb@world_human_seat_wall_tablet@female@base", "base", 8.0, -8.0, 3000, 48, 0, false, false, false)

    -- Prop nach 3 Sekunden entfernen
    CreateThread(function()
        Wait(3000)
        ClearPedSecondaryTask(playerPed)
        if DoesEntityExist(tabletProp) then
            DeleteEntity(tabletProp)
        end
    end)
end

