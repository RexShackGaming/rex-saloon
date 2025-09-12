local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

---------------------------------------------
-- admin command for saloon reset /resetsaloon saloonid
---------------------------------------------
RSGCore.Commands.Add('resetsaloon', locale('sv_lang_7'), { { name = 'saloonid', help = locale('sv_lang_8') } }, true, function(source, args)

    local saloonid = args[1]
    local result = MySQL.prepare.await("SELECT COUNT(*) as count FROM rex_saloon WHERE saloonid = ?", { saloonid })

    if result == 1 then
        -- update rex_saloon table
        MySQL.update('UPDATE rex_saloon SET owner = ? WHERE saloonid = ?', {'vacant', saloonid})
        MySQL.update('UPDATE rex_saloon SET rent = ? WHERE saloonid = ?', {0, saloonid})
        MySQL.update('UPDATE rex_saloon SET rent = ? WHERE saloonid = ?', {0, saloonid})
        MySQL.update('UPDATE rex_saloon SET status = ? WHERE saloonid = ?', {'closed', saloonid})
        MySQL.update('UPDATE rex_saloon SET money = ? WHERE saloonid = ?', {0.00, saloonid})
        -- delete stock in rex_ranch_stock
        MySQL.Async.execute('DELETE FROM rex_saloon_stock WHERE saloonid = ?', { saloonid })
        -- update funds in management_funds
        MySQL.update('UPDATE management_funds SET amount = ? WHERE job_name = ?', {0, saloonid})
        -- delete job in player_jobs
        MySQL.Async.execute('DELETE FROM player_jobs WHERE job = ?', { saloonid })
        -- delete stashes
        MySQL.Async.execute('DELETE FROM inventories WHERE identifier = ?', { 'brewery_'..saloonid })
        MySQL.Async.execute('DELETE FROM inventories WHERE identifier = ?', { 'bartray_'..saloonid })
        MySQL.Async.execute('DELETE FROM inventories WHERE identifier = ?', { 'stock_'..saloonid })
        TriggerClientEvent('ox_lib:notify', source, {title = locale('sv_lang_9'), type = 'success', duration = 7000 })
    else
        TriggerClientEvent('ox_lib:notify', source, {title = locale('sv_lang_10'), type = 'error', duration = 7000 })
    end

end, 'admin')


---------------------------------------------
-- functions
---------------------------------------------
function isPlayerSaloonOwner(src, saloonid)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return false end
    local result = MySQL.query.await('SELECT * FROM rex_saloon WHERE owner = ? AND saloonid = ?', { Player.PlayerData.citizenid, saloonid})
    return result[1] ~= nil
end
function countOwnedSaloons(src)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return 0 end
    local citizenid = Player.PlayerData.citizenid
    local result = MySQL.prepare.await("SELECT COUNT(*) as count FROM rex_saloon WHERE owner = ?", { citizenid })
    return result
end

---------------------------------------------
-- count owned saloons
---------------------------------------------
RSGCore.Functions.CreateCallback('rex-saloon:server:countowned', function(source, cb)
    local src = source
    cb(countOwnedSaloons(src))
end)

---------------------------------------------
-- get data
---------------------------------------------
RSGCore.Functions.CreateCallback('rex-saloon:server:getsaloondata', function(source, cb, saloonid)
    MySQL.query('SELECT * FROM rex_saloon WHERE saloonid = ?', { saloonid }, function(result)
        if result[1] then
            cb(result)
        else
            cb(nil)
        end
    end)
end)

---------------------------------------------
-- check stock
---------------------------------------------
RSGCore.Functions.CreateCallback('rex-saloon:server:checkstock', function(source, cb, saloonid)
    MySQL.query('SELECT * FROM rex_saloon_stock WHERE saloonid = ?', { saloonid }, function(result)
        if result[1] then
            cb(result)
        else
            cb(nil)
        end
    end)
end)

---------------------------------------------
-- update stock or add new stock
---------------------------------------------
RegisterNetEvent('rex-saloon:server:newstockitem', function(saloonid, item, amount, price)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)

    if not isPlayerSaloonOwner(src, saloonid) then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_not_saloon_owner'), type = 'error', duration = 7000 })
        return
    end

    if not Player.Functions.RemoveItem(item, amount) then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_no_item'), type = 'error', duration = 7000 })
        return
    end
    
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[item], 'remove', amount)
    local itemcount = MySQL.prepare.await("SELECT COUNT(*) as count FROM rex_saloon_stock WHERE saloonid = ? AND item = ?", { saloonid, item })
    if itemcount == 0 then
        MySQL.Async.execute('INSERT INTO rex_saloon_stock (saloonid, item, stock, price) VALUES (@saloonid, @item, @stock, @price)',
        {
            ['@saloonid'] = saloonid,
            ['@item'] = item,
            ['@stock'] = amount,
            ['@price'] = price
        })
    else
        MySQL.query('SELECT * FROM rex_saloon_stock WHERE saloonid = ? AND item = ?', { saloonid, item }, function(data)
            local stockupdate = (amount + data[1].stock)
            MySQL.update('UPDATE rex_saloon_stock SET stock = ? WHERE saloonid = ? AND item = ?',{stockupdate, saloonid, item})
            MySQL.update('UPDATE rex_saloon_stock SET price = ? WHERE saloonid = ? AND item = ?',{price, saloonid, item})
        end)
    end
end)

---------------------------------------------
-- buy item amount / add money to account
---------------------------------------------
RegisterNetEvent('rex-saloon:server:buyitem', function(amount, item, saloonid)
    local src = source

    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    if amount <= 0 then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_invalid_amount'), type = 'error', duration = 7000 })
        return
    end

    -- Get stock data / verify existence
    local result = MySQL.query.await('SELECT id, stock, price FROM rex_saloon_stock WHERE saloonid = ? AND item = ?', {saloonid, item})
    if not result[1] then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_stock_not_found'), type = 'error', duration = 7000 })
        return
    end
    local stockId = result[1].id
    local stockPrice = result[1].price
    local stockAmount = result[1].stock

    -- Verify stock amount
    if stockAmount < amount then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('Not enough in stock'), type = 'error', duration = 7000 })
        return
    end

    -- Verify player money
    local money = Player.PlayerData.money[Config.Money]
    local totalcost = (stockPrice * amount)
    if money < totalcost then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_lang_1')..Config.Money, type = 'error', duration = 7000 })
        return
    end

    -- Sell item to player and update saloon data
    if Player.Functions.AddItem(item, amount) then
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[item], 'add', amount)
        Player.Functions.RemoveMoney(Config.Money, totalcost)
        
        -- Update saloon money
        MySQL.query('SELECT * FROM rex_saloon WHERE saloonid = ?', { saloonid }, function(data2)
            local moneyupdate = (data2[1].money + totalcost)
            MySQL.update('UPDATE rex_saloon SET money = ? WHERE saloonid = ?',{moneyupdate, saloonid})
        end)

        -- Update saloon item
        local newStockAmount = stockAmount - amount
        if newStockAmount > 0 then
            MySQL.update('UPDATE rex_saloon_stock SET stock = ? WHERE id = ?', { newStockAmount, stockId })
        else
            print('delete item from stock, id of stock', stockId)
            MySQL.Async.execute('DELETE FROM rex_saloon_stock WHERE id = ?', { stockId })
        end
    end
end)

---------------------------------------------
-- remove stock item
---------------------------------------------
RegisterNetEvent('rex-saloon:server:removestockitem', function(data)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)

    if not isPlayerSaloonOwner(src, data.saloonid) then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_not_saloon_owner'), type = 'error', duration = 7000 })
        return
    end

    MySQL.query('SELECT * FROM rex_saloon_stock WHERE saloonid = ? AND item = ?', { data.saloonid, data.item }, function(result)
        if Player.Functions.AddItem(result[1].item, result[1].stock) then
            TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[result[1].item], 'add', result[1].stock)
        end
        MySQL.Async.execute('DELETE FROM rex_saloon_stock WHERE id = ?', { result[1].id })
    end)
end)

---------------------------------------------
-- get money
---------------------------------------------
RSGCore.Functions.CreateCallback('rex-saloon:server:getmoney', function(source, cb, saloonid)
    MySQL.query('SELECT * FROM rex_saloon WHERE saloonid = ?', { saloonid }, function(result)
        if result[1] then
            cb(result[1])
        else
            cb(nil)
        end
    end)
end)

---------------------------------------------
-- withdraw money
---------------------------------------------
RegisterNetEvent('rex-saloon:server:withdrawfunds', function(amount, saloonid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)

    if not isPlayerSaloonOwner(src, saloonid) then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_not_saloon_owner'), type = 'error', duration = 7000 })
        return
    end

    MySQL.query('SELECT * FROM rex_saloon WHERE saloonid = ?', {saloonid} , function(result)
        if result[1] ~= nil then
            if result[1].money >= amount then
                local updatemoney = (result[1].money - amount)
                MySQL.update('UPDATE rex_saloon SET money = ? WHERE saloonid = ?', { updatemoney, saloonid })
                Player.Functions.AddMoney(Config.Money, amount)
            end
        end
    end)
end)

---------------------------------------------
-- rent saloon
---------------------------------------------
RegisterNetEvent('rex-saloon:server:rentsaloon', function(saloonid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local money = Player.PlayerData.money[Config.Money]
    local citizenid = Player.PlayerData.citizenid

    local saloonData = MySQL.query.await('SELECT * FROM rex_saloon WHERE saloonid = ?', { saloonid })[1]
    if not saloonData then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('invalid_saloon'), type = 'error', duration = 7000 })
        return 
    end
    if saloonData.owner ~= 'vacant' then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('saloon_already_rented'), type = 'error', duration = 7000 })
        return
    end

    if money > Config.RentStartup then
        if countOwnedSaloons(src) >= Config.MaxSaloons then
            TriggerClientEvent('ox_lib:notify', src, {title = locale('cl_lang_48'), description = locale('cl_lang_49'), type = 'error', duration = 7000 })
            return
        end

        Player.Functions.RemoveMoney(Config.Money, Config.RentStartup)
        Player.Functions.SetJob(saloonid, 2)
        if Config.LicenseRequired then
            Player.Functions.RemoveItem('saloonlicence', 1)
            TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items['saloonlicence'], 'remove', 1)
        end
        MySQL.update('UPDATE rex_saloon SET owner = ? WHERE saloonid = ?',{ citizenid, saloonid })
        MySQL.update('UPDATE rex_saloon SET rent = ? WHERE saloonid = ?',{ Config.RentStartup, saloonid })
        MySQL.update('UPDATE rex_saloon SET status = ? WHERE saloonid = ?', {'open', saloonid})
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_lang_2'), type = 'success', duration = 7000 })
    else
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_lang_3'), type = 'error', duration = 7000 })
    end
end)

---------------------------------------------
-- add saloon rent
---------------------------------------------
RegisterNetEvent('rex-saloon:server:addrentmoney', function(rentmoney, saloonid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)

    if not isPlayerSaloonOwner(src, saloonid) then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_not_saloon_owner'), type = 'error', duration = 7000 })
        return
    end

    MySQL.query('SELECT * FROM rex_saloon WHERE saloonid = ?', { saloonid }, function(result)
        local currentrent = result[1].rent
        local rentupdate = (currentrent + rentmoney)
        if rentupdate >= Config.MaxRent then
            TriggerClientEvent('ox_lib:notify', src, {title = 'Can\'t add that much rent!', type = 'error', duration = 7000 })
        else
            if Player.Functions.RemoveMoney(Config.Money, rentmoney) then
                MySQL.update('UPDATE rex_saloon SET rent = ? WHERE saloonid = ?',{ rentupdate, saloonid })
                MySQL.update('UPDATE rex_saloon SET status = ? WHERE saloonid = ?', {'open', saloonid})
                TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_lang_4'), type = 'success', duration = 7000 })
            else
                TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_not_enough_money'), type = 'error', duration = 7000 })
            end
        end
    end)
end)

---------------------------------------------
-- check player has the ingredients
---------------------------------------------
local function hasIngredients(src, ingredients)
    local icheck = 0
    for k, v in pairs(ingredients) do
        if exports['rsg-inventory']:GetItemCount(src, v.item) < v.amount then
            return false
        end
    end
    return true
end

RSGCore.Functions.CreateCallback('rsg-saloon:server:checkingredients', function(source, cb, ingredients)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if hasIngredients(src, ingredients) then
        cb(true)
    else
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_lang_5'), type = 'error', duration = 7000 })
        cb(false)
    end
end)

---------------------------------------------
-- finish crafting / give item
---------------------------------------------
RegisterNetEvent('rex-saloon:server:finishcrafting', function(data)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local receive = data.receive
    local giveamount = data.giveamount

    if not hasIngredients(src, data.ingredients) then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_lang_5'), type = 'error', duration = 7000 })
        return
    end

    for k, v in pairs(data.ingredients) do
        Player.Functions.RemoveItem(v.item, v.amount)
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[v.item], 'remove', v.amount)
    end
    Player.Functions.AddItem(receive, giveamount)
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[receive], 'add', giveamount)
end)

---------------------------------
-- open saloon bartray storage
---------------------------------
RegisterServerEvent('rex-saloon:server:storagebartray', function(saloonid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local data = { label = 'Saloon Bartray', maxweight = Config.BarTrayMaxWeight, slots = Config.BarTrayMaxSlots }
    local stashName = 'bartray_'.. saloonid
    exports['rsg-inventory']:OpenInventory(src, stashName, data)
end)

---------------------------------
-- open brewing storage
---------------------------------
RegisterServerEvent('rex-saloon:server:storagebrewing', function(saloonid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    if not isPlayerSaloonOwner(src, saloonid) then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_not_saloon_owner'), type = 'error', duration = 7000 })
        return
    end

    local data = { label = 'Saloon Brewery', maxweight = Config.BrewingMaxWeight, slots = Config.BrewingMaxSlots }
    local stashName = 'brewery_'.. saloonid
    exports['rsg-inventory']:OpenInventory(src, stashName, data)
end)

---------------------------------
-- open stock storage
---------------------------------
RegisterServerEvent('rex-saloon:server:storagestock', function(saloonid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    if not isPlayerSaloonOwner(src, saloonid) then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_not_saloon_owner'), type = 'error', duration = 7000 })
        return
    end

    local data = { label = 'Saloon Stock', maxweight = Config.StockMaxWeight, slots = Config.StockMaxSlots }
    local stashName = 'stock_'.. saloonid
    exports['rsg-inventory']:OpenInventory(src, stashName, data)
end)

---------------------------------------------
-- saloon rent system
---------------------------------------------
lib.cron.new(Config.SaloonCronJob, function ()

    if not Config.EnableRentSystem then
        print(locale('sv_lang_11'))
        return
    end

    local result = MySQL.query.await('SELECT * FROM rex_saloon')

    if not result then goto continue end

    for i = 1, #result do

        local saloonid = result[i].saloonid
        local owner = result[i].owner
        local rent = result[i].rent
        local money = result[i].money

        if rent >= 1 then
            local moneyupdate = (rent - Config.RentPerHour)
            MySQL.update('UPDATE rex_saloon SET rent = ? WHERE saloonid = ?', {moneyupdate, saloonid})
            MySQL.update('UPDATE rex_saloon SET status = ? WHERE saloonid = ?', {'open', saloonid})
        else
            MySQL.update('UPDATE rex_saloon SET status = ? WHERE saloonid = ?', {'closed', saloonid})
        end

    end

    ::continue::

    if Config.ServerNotify then
        print(locale('sv_lang_6'))
    end

end)
