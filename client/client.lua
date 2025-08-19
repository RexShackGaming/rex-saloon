local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

---------------------------------
-- blips
---------------------------------
CreateThread(function()
    for _,v in pairs(Config.PlayerSaloonLocations) do
        if v.showblip == true then    
            local PlayerSaloonBlip = BlipAddForCoords(1664425300, v.coords)
            SetBlipSprite(PlayerSaloonBlip, joaat(v.blipsprite), true)
            SetBlipScale(PlayerSaloonBlip, v.blipscale)
            SetBlipName(PlayerSaloonBlip, v.blipname)
        end
    end
end)

---------------------------------------------
-- get correct menu
---------------------------------------------
RegisterNetEvent('rex-saloon:client:opensaloon', function(saloonid, jobaccess, name, rentprice)
    if not Config.EnableRentSystem then
        local PlayerData = RSGCore.Functions.GetPlayerData()
        local playerjob = PlayerData.job.name
        if playerjob == jobaccess then
            TriggerEvent('rex-saloon:client:openjobmenu', saloonid)
        else
            TriggerEvent('rex-saloon:client:opencustomermenu', saloonid)
        end
    else
        RSGCore.Functions.TriggerCallback('rex-saloon:server:getsaloondata', function(result)
            local owner = result[1].owner
            local status = result[1].status
            if owner ~= 'vacant' then
                local PlayerData = RSGCore.Functions.GetPlayerData()
                local playerjob = PlayerData.job.name
                if playerjob == jobaccess then
                    TriggerEvent('rex-saloon:client:openrentjobmenu', saloonid, status)
                else
                    TriggerEvent('rex-saloon:client:opencustomermenu', saloonid, status)
                end
            else
                TriggerEvent('rex-saloon:client:rentsaloon', saloonid, name, rentprice)
            end
        end, saloonid)
    end
end)

---------------------------------------------
-- saloon job menu (non rent)
---------------------------------------------
RegisterNetEvent('rex-saloon:client:openjobmenu', function(saloonid, status)
    lib.registerContext({
        id = 'job_menu',
        title = locale('cl_lang_1'),
        options = {
            {
                title = locale('cl_lang_2'),
                icon = 'fa-solid fa-store',
                event = 'rex-saloon:client:ownerviewitems',
                args = { saloonid = saloonid },
                arrow = true
            },
            {
                title = locale('cl_lang_3'),
                icon = 'fa-solid fa-circle-plus',
                iconColor = 'green',
                event = 'rex-saloon:client:newstockitem',
                args = { saloonid = saloonid },
                arrow = true
            },
            {
                title = locale('cl_lang_4'),
                icon = 'fa-solid fa-circle-minus',
                iconColor = 'red',
                event = 'rex-saloon:client:removestockitem',
                args = { saloonid = saloonid },
                arrow = true
            },
            {
                title = locale('cl_lang_5'),
                icon = 'fa-solid fa-sack-dollar',
                event = 'rex-saloon:client:withdrawmoney',
                args = { saloonid = saloonid },
                arrow = true
            },
            {
                title = locale('cl_lang_6'),
                icon = 'fa-solid fa-box',
                event = 'rex-saloon:client:ownerstoragemenu',
                args = { saloonid = saloonid },
                arrow = true
            },
            {
                title = locale('cl_lang_7'),
                icon = 'fa-solid fa-box',
                event = 'rex-saloon:client:craftingmenu',
                args = { saloonid = saloonid },
                arrow = true
            },
            {
                title = locale('cl_lang_9'),
                icon = 'fa-solid fa-user-tie',
                event = 'rsg-bossmenu:client:mainmenu',
                arrow = true
            },
        }
    })
    lib.showContext('job_menu')
end)

---------------------------------------------
-- saloon job menu (rent)
---------------------------------------------
RegisterNetEvent('rex-saloon:client:openrentjobmenu', function(saloonid, status)
    if status == 'open' then
        lib.registerContext({
            id = 'job_menu',
            title = locale('cl_lang_1'),
            options = {
                {
                    title = locale('cl_lang_2'),
                    icon = 'fa-solid fa-store',
                    event = 'rex-saloon:client:ownerviewitems',
                    args = { saloonid = saloonid },
                    arrow = true
                },
                {
                    title = locale('cl_lang_3'),
                    icon = 'fa-solid fa-circle-plus',
                    iconColor = 'green',
                    event = 'rex-saloon:client:newstockitem',
                    args = { saloonid = saloonid },
                    arrow = true
                },
                {
                    title = locale('cl_lang_4'),
                    icon = 'fa-solid fa-circle-minus',
                    iconColor = 'red',
                    event = 'rex-saloon:client:removestockitem',
                    args = { saloonid = saloonid },
                    arrow = true
                },
                {
                    title = locale('cl_lang_5'),
                    icon = 'fa-solid fa-sack-dollar',
                    event = 'rex-saloon:client:withdrawmoney',
                    args = { saloonid = saloonid },
                    arrow = true
                },
                {
                    title = locale('cl_lang_6'),
                    icon = 'fa-solid fa-box',
                    event = 'rex-saloon:client:ownerstoragemenu',
                    args = { saloonid = saloonid },
                    arrow = true
                },
                {
                    title = locale('cl_lang_7'),
                    icon = 'fa-solid fa-box',
                    event = 'rex-saloon:client:craftingmenu',
                    args = { saloonid = saloonid },
                    arrow = true
                },
                {
                    title = locale('cl_lang_8'),
                    icon = 'fa-solid fa-box',
                    event = 'rex-saloon:client:rentmenu',
                    args = { saloonid = saloonid },
                    arrow = true
                },
                {
                    title = locale('cl_lang_9'),
                    icon = 'fa-solid fa-user-tie',
                    event = 'rsg-bossmenu:client:mainmenu',
                    arrow = true
                },
            }
        })
        lib.showContext('job_menu')
    else
        lib.registerContext({
            id = 'job_menu',
            title = locale('cl_lang_1'),
            options = {
                {
                    title = locale('cl_lang_8'),
                    icon = 'fa-solid fa-box',
                    event = 'rex-saloon:client:rentmenu',
                    args = { saloonid = saloonid },
                    arrow = true
                },
            }
        })
        lib.showContext('job_menu')
    end
end)

---------------------------------------------
-- saloon customer menu
---------------------------------------------
RegisterNetEvent('rex-saloon:client:opencustomermenu', function(saloonid, status)
    if status == 'closed' then
        lib.notify({ title = locale('cl_lang_10'), type = 'error', duration = 7000 })
        return
    end
    lib.registerContext({
        id = 'saloon_customer_menu',
        title = locale('cl_lang_11'),
        options = {
            {
                title = locale('cl_lang_12'),
                icon = 'fa-solid fa-store',
                event = 'rex-saloon:client:customerviewitems',
                args = { saloonid = saloonid },
                arrow = true
            },
            {
                title = locale('cl_lang_13'),
                icon = 'fa-solid fa-box',
                event = 'rex-saloon:client:storagebartray',
                args = { saloonid = saloonid },
                arrow = true
            },
        }
    })
    lib.showContext('saloon_customer_menu')
end)

---------------------------------------------
-- saloon rent money menu
---------------------------------------------
RegisterNetEvent('rex-saloon:client:rentmenu', function(data)

    RSGCore.Functions.TriggerCallback('rex-saloon:server:getsaloondata', function(result)
    
        local rent = result[1].rent
        if rent > 50  then rentColorScheme = 'green' end
        if rent <= 50 and rent > 10 then rentColorScheme = 'yellow' end
        if rent <= 10 then rentColorScheme = 'red' end
        
        lib.registerContext({
            id = 'saloon_rent_menu',
            title = locale('cl_lang_14'),
            menu = 'job_menu',
            options = {
                {
                    title = locale('cl_lang_15')..rent,
                    progress = rent,
                    colorScheme = rentColorScheme,
                },
                {
                    title = locale('cl_lang_16'),
                    icon = 'fa-solid fa-dollar-sign',
                    event = 'rex-saloon:client:payrent',
                    args = { saloonid = data.saloonid },
                    arrow = true
                },
            }
        })
        lib.showContext('saloon_rent_menu')

    end, data.saloonid)
    
end)

-------------------------------------------------------------------------------------------
-- job : view saloon items
-------------------------------------------------------------------------------------------
RegisterNetEvent('rex-saloon:client:ownerviewitems', function(data)

    RSGCore.Functions.TriggerCallback('rex-saloon:server:checkstock', function(result)

        if result == nil then
            lib.registerContext({
                id = 'saloon_no_inventory',
                title = locale('cl_lang_17'),
                menu = 'job_menu',
                options = {
                    {
                        title = locale('cl_lang_18'),
                        icon = 'fa-solid fa-box',
                        disabled = true,
                        arrow = false
                    }
                }
            })
            lib.showContext('saloon_no_inventory')
        else
            local options = {}
            for k,v in ipairs(result) do
                options[#options + 1] = {
                    title = RSGCore.Shared.Items[result[k].item].label..' ($'..result[k].price..')',
                    description = locale('cl_lang_19')..result[k].stock,
                    icon = 'fa-solid fa-box',
                    event = 'rex-saloon:client:buyitem',
                    icon = "nui://" .. Config.Img .. RSGCore.Shared.Items[tostring(result[k].item)].image,
                    image = "nui://" .. Config.Img .. RSGCore.Shared.Items[tostring(result[k].item)].image,
                    args = {
                        item = result[k].item,
                        stock = result[k].stock,
                        price = result[k].price,
                        label = RSGCore.Shared.Items[result[k].item].label,
                        saloonid = result[k].saloonid
                    },
                    arrow = true,
                }
            end
            lib.registerContext({
                id = 'saloon_inv_menu',
                title = locale('cl_lang_17'),
                menu = 'job_menu',
                position = 'top-right',
                options = options
            })
            lib.showContext('saloon_inv_menu')
        end
    end, data.saloonid)

end)

-------------------------------------------------------------------------------------------
-- customer : view saloon items
-------------------------------------------------------------------------------------------
RegisterNetEvent('rex-saloon:client:customerviewitems', function(data)
    RSGCore.Functions.TriggerCallback('rex-saloon:server:checkstock', function(result)
        if result == nil then
            lib.registerContext({
                id = 'saloon_no_inventory',
                title = locale('cl_lang_17'),
                menu = 'saloon_customer_menu',
                options = {
                    {
                        title = locale('cl_lang_18'),
                        icon = 'fa-solid fa-box',
                        disabled = true,
                        arrow = false
                    }
                }
            })
            lib.showContext('saloon_no_inventory')
        else
            local options = {}
            for k,v in ipairs(result) do
                options[#options + 1] = {
                    title = RSGCore.Shared.Items[result[k].item].label..' ($'..result[k].price..')',
                    description = locale('cl_lang_19')..result[k].stock,
                    icon = 'fa-solid fa-box',
                    event = 'rex-saloon:client:buyitem',
                    icon = "nui://" .. Config.Img .. RSGCore.Shared.Items[tostring(result[k].item)].image,
                    image = "nui://" .. Config.Img .. RSGCore.Shared.Items[tostring(result[k].item)].image,
                    args = {
                        item = result[k].item,
                        stock = result[k].stock,
                        price = result[k].price,
                        label = RSGCore.Shared.Items[result[k].item].label,
                        saloonid = result[k].saloonid
                    },
                    arrow = true,
                }
            end
            lib.registerContext({
                id = 'saloon_inv_menu',
                title = locale('cl_lang_17'),
                menu = 'saloon_customer_menu',
                position = 'top-right',
                options = options
            })
            lib.showContext('saloon_inv_menu')
        end
    end, data.saloonid)

end)

-------------------------------------------------------------------
-- sort table function
-------------------------------------------------------------------
local function compareNames(a, b)
    return a.value < b.value
end

-------------------------------------------------------------------
-- add / update stock item
-------------------------------------------------------------------
RegisterNetEvent('rex-saloon:client:newstockitem', function(data)

    local items = {}

    for k,v in pairs(RSGCore.Functions.GetPlayerData().items) do
        local content = { value = v.name, label = v.label..' ('..v.amount..')' }
        items[#items + 1] = content
    end

    table.sort(items, compareNames)

    local item = lib.inputDialog(locale('cl_lang_20'), {
        { 
            type = 'select',
            options = items,
            label = locale('cl_lang_21'),
            required = true
        },
        { 
            type = 'input',
            label = locale('cl_lang_22'),
            placeholder = '0',
            icon = 'fa-solid fa-hashtag',
            required = true
        },
        { 
            type = 'input',
            label = locale('cl_lang_23'),
            placeholder = '0.00',
            icon = 'fa-solid fa-dollar-sign',
            required = true
        },
    })
    
    if not item then 
        return 
    end
    
    local hasItem = RSGCore.Functions.HasItem(item[1], tonumber(item[2]))
    
    if hasItem then
        TriggerServerEvent('rex-saloon:server:newstockitem', data.saloonid, item[1], tonumber(item[2]), tonumber(item[3]))
    else
        lib.notify({ title = locale('cl_lang_24'), type = 'error', duration = 7000 })
    end

end)

-------------------------------------------------------------------------------------------
-- remove stock item
-------------------------------------------------------------------------------------------
RegisterNetEvent('rex-saloon:client:removestockitem', function(data)
    RSGCore.Functions.TriggerCallback('rex-saloon:server:checkstock', function(result)
        if result == nil then
            lib.registerContext({
                id = 'saloon_no_stock',
                title = locale('cl_lang_25'),
                menu = 'saloon_owner_menu',
                options = {
                    {
                        title = locale('cl_lang_26'),
                        icon = 'fa-solid fa-box',
                        disabled = true,
                        arrow = false
                    }
                }
            })
            lib.showContext('saloon_no_stock')
        else
            local options = {}
            for k,v in ipairs(result) do
                options[#options + 1] = {
                    title = RSGCore.Shared.Items[result[k].item].label,
                    description = locale('cl_lang_19')..result[k].stock,
                    icon = 'fa-solid fa-box',
                    serverEvent = 'rex-saloon:server:removestockitem',
                    icon = "nui://" .. Config.Img .. RSGCore.Shared.Items[tostring(result[k].item)].image,
                    image = "nui://" .. Config.Img .. RSGCore.Shared.Items[tostring(result[k].item)].image,
                    args = {
                        item = result[k].item,
                        saloonid = result[k].saloonid
                    },
                    arrow = true,
                }
            end
            lib.registerContext({
                id = 'saloon_stock_menu',
                title = locale('cl_lang_25'),
                menu = 'job_menu',
                position = 'top-right',
                options = options
            })
            lib.showContext('saloon_stock_menu')
        end
    end, data.saloonid)
end)

-------------------------------------------------------------------------------------------
-- withdraw money 
-------------------------------------------------------------------------------------------
RegisterNetEvent('rex-saloon:client:withdrawmoney', function(data)
    RSGCore.Functions.TriggerCallback('rex-saloon:server:getmoney', function(result)
        local input = lib.inputDialog(locale('cl_lang_27'), {
            { 
                type = 'input',
                label = locale('cl_lang_28')..result.money,
                icon = 'fa-solid fa-dollar-sign',
                required = true
            },
        })
        if not input then
            return 
        end
        local withdraw = tonumber(input[1])
        if withdraw <= result.money then
            TriggerServerEvent('rex-saloon:server:withdrawfunds', withdraw, data.saloonid)
        else
            lib.notify({ title = locale('cl_lang_29'), type = 'error', duration = 7000 })
        end
    end, data.saloonid)
end)

---------------------------------------------
-- buy item amount
---------------------------------------------
RegisterNetEvent('rex-saloon:client:buyitem', function(data)
    local input = lib.inputDialog(locale('cl_lang_30')..data.label, {
        { 
            label = locale('cl_lang_31'),
            type = 'input',
            required = true,
            icon = 'fa-solid fa-hashtag'
        },
    })
    if not input then
        return
    end
    
    local amount = tonumber(input[1])
    
    if data.stock >= amount then
        local newstock = (data.stock - amount)
        TriggerServerEvent('rex-saloon:server:buyitem', amount, data.item, newstock, data.price, data.label, data.saloonid)
    else
        lib.notify({ title = locale('cl_lang_32'), type = 'error', duration = 7000 })
    end
end)

---------------------------------------------
-- rent saloon
---------------------------------------------
RegisterNetEvent('rex-saloon:client:rentsaloon', function(saloonid, name)
    
    local input = lib.inputDialog(locale('cl_lang_33')..name, {
        {
            label = locale('cl_lang_34')..Config.RentStartup,
            type = 'select',
            options = {
                { value = 'yes', label = locale('cl_lang_35') },
                { value = 'no',  label = locale('cl_lang_36') }
            },
            required = true
        },
    })

    -- check there is an input
    if not input then
        return 
    end

    -- if no then return
    if input[1] == 'no' then
        return
    end

    RSGCore.Functions.TriggerCallback('rsg-multijob:server:checkjobs', function(canbuy)
        if not canbuy then
            lib.notify({ title = locale('cl_lang_50'), type = 'error', duration = 7000 })
            return
        else
            RSGCore.Functions.TriggerCallback('rex-saloon:server:countowned', function(result)
        
                if result >= Config.MaxSaloons then
                    lib.notify({ title = locale('cl_lang_48'), description = locale('cl_lang_49'), type = 'error', duration = 7000 })
                    return
                end
        
                -- check player has a licence
                if Config.LicenseRequired then
                    local hasItem = RSGCore.Functions.HasItem('saloonlicence', 1)
        
                    if hasItem then
                        TriggerServerEvent('rex-saloon:server:rentsaloon', saloonid)
                    else
                        lib.notify({ title = locale('cl_lang_37'), type = 'error', duration = 7000 })
                    end
                else
                    TriggerServerEvent('rex-saloon:server:rentsaloon', saloonid)
                end
                
            end)
        end
    end)
end)

-------------------------------------------------------------------------------------------
-- pay rent
-------------------------------------------------------------------------------------------
RegisterNetEvent('rex-saloon:client:payrent', function(data)

        local input = lib.inputDialog(locale('cl_lang_38'), {
            { 
                label = locale('cl_lang_39'),
                type = 'input',
                icon = 'fa-solid fa-dollar-sign',
                required = true
            },
        })
        if not input then
            return 
        end
        
        TriggerServerEvent('rex-saloon:server:addrentmoney', input[1], data.saloonid)

end)

---------------------------------------------
-- owner saloon storage menu
---------------------------------------------
RegisterNetEvent('rex-saloon:client:ownerstoragemenu', function(data)
    lib.registerContext({
        id = 'owner_storage_menu',
        title = locale('cl_lang_43'),
        menu = 'job_menu',
        options = {
            {
                title = locale('cl_lang_40'),
                icon = 'fa-solid fa-box',
                event = 'rex-saloon:client:storagebartray',
                args = { saloonid = data.saloonid },
                arrow = true
            },
            {
                title = locale('cl_lang_41'),
                icon = 'fa-solid fa-box',
                event = 'rex-saloon:client:storagebrewing',
                args = { saloonid = data.saloonid },
                arrow = true
            },
            {
                title = locale('cl_lang_42'),
                icon = 'fa-solid fa-box',
                event = 'rex-saloon:client:storagestock',
                args = { saloonid = data.saloonid },
                arrow = true
            },
        }
    })
    lib.showContext('owner_storage_menu')
end)

---------------------------------------------
-- bar tray storage
---------------------------------------------
RegisterNetEvent('rex-saloon:client:storagebartray', function(data)
    TriggerServerEvent('rex-saloon:server:storagebartray', data.saloonid)
end)

---------------------------------------------
-- brewing storage
---------------------------------------------
RegisterNetEvent('rex-saloon:client:storagebrewing', function(data)
    local PlayerData = RSGCore.Functions.GetPlayerData()
    local playerjob = PlayerData.job.name
    if playerjob == data.saloonid then
       TriggerServerEvent('rex-saloon:server:storagebrewing', data.saloonid)
    end
end)

---------------------------------------------
-- stock storage
---------------------------------------------
RegisterNetEvent('rex-saloon:client:storagestock', function(data)
    local PlayerData = RSGCore.Functions.GetPlayerData()
    local playerjob = PlayerData.job.name
    if playerjob == data.saloonid then
       TriggerServerEvent('rex-saloon:server:storagestock', data.saloonid)
    end
end)
