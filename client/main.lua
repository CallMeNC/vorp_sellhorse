local VORPCore = {}

Citizen.CreateThread(function()
    while not VORPCore do        
        TriggerEvent("getCore", function(core)
            VORPCore = core
        end)
        Citizen.Await(200)
    end
end)

RegisterNetEvent("vorp:SelectedCharacter") -- NPC loads after selecting character
AddEventHandler("vorp:SelectedCharacter", function(charid)
    startTrainer()
end)

function startTrainer() -- Loading Trainer Function
    for i,v in ipairs(Config.trainers) do 
        local x, y, z = table.unpack(v.coords)
        if Config.aiTrainerped then 
            -- Loading Model
            local hashModel = GetHashKey(v.npcmodel) 
            if IsModelValid(hashModel) then 
                RequestModel(hashModel)
                while not HasModelLoaded(hashModel) do                
                    Wait(100)
                end
            else 
                print(v.npcmodel .. " is not valid") -- Concatenations
            end        
            -- Spawn Ped
            local npc = CreatePed(hashModel, x, y, z, v.heading, false, true, true, true)
            Citizen.InvokeNative(0x283978A15512B2FE, npc, true) -- SetRandomOutfitVariation
            SetEntityNoCollisionEntity(PlayerPedId(), npc, false)
            SetEntityCanBeDamaged(npc, false)
            SetEntityInvincible(npc, true)
            Wait(1000)
            FreezeEntityPosition(npc, true) -- NPC can't escape
            SetBlockingOfNonTemporaryEvents(npc, true) -- NPC can't be scared
        end
        local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, x, y, z) -- Blip Creation
        SetBlipSprite(blip, v.blip, true) -- Blip Texture
        Citizen.InvokeNative(0x9CB1A1623062F402, blip, v.trainername) -- Name of Blip
    end
end

function drawTxt(text, x, y, fontscale, fontsize, r, g, b, alpha, textcentred, shadow) -- Text function
    local str = CreateVarString(10, "LITERAL_STRING", text)
    SetTextScale(fontscale, fontsize)
    SetTextColor(r, g, b, alpha)
    SetTextCentre(textcentred)
    if shadow then 
        SetTextDropshadow(1, 0, 0, 255)
    end
    SetTextFontForCurrentCommand(1)
    DisplayText(str, x, y)
end

-------------------------------------------------------
--                 WARNING                           --
-- Don't accidently sell PLAYERS horses. Can sell AI --
-------------------------------------------------------

function sellAnimal() -- Selling horse function
    local horse = Citizen.InvokeNative(0xE7E11B8DCBED1058,PlayerPedId()) -- Gets mount
    local model = GetEntityModel(horse)
    print("model",model)
    if Config.Animals[model] ~= nil then -- Paying for animals
        local animal = Config.Animals[model]
        local money = animal.money
        local gold = animal.gold
        local rolPoints = animal.rolPoints
        local xp = animal.xp               
        TriggerServerEvent("vorp_sellhorse:giveReward", money, gold, rolPoints, xp) 
        TriggerEvent("vorp:TipRight", Config.Language.AnimalSold, 4000) -- Sold notification
        DeletePed(horse)  
    else
        TriggerEvent("vorp:TipRight", Config.Language.NoMount, 4000) -- Notification when you don't have an mount to sell           
    end
end

Citizen.CreateThread(function()
    while true do
        local sleep = true
        for i,v in ipairs(Config.trainers) do
            local playerCoords = GetEntityCoords(PlayerPedId())       
            if Vdist(playerCoords, v.coords) <= v.radius then -- Checking distance between player and trainer
                local job
                sleep = false
                drawTxt(v.pressToSell, 0.5, 0.9, 0.7, 0.7, 255, 255, 255, 255, true, true)
                if IsControlJustPressed(2, 0xD9D0E1C0) then
                    if Config.joblocked then 
                        TriggerEvent('vorp:ExecuteServerCallBack','vorp_sellhorse:getjob', function(result)  
                            job =   result
                        end)
                        while job == nil do 
                            Wait(100)
                        end
                        if job == v.trainerjob then 
                            sellAnimal()     
                            Citizen.Wait(200)
                        else
                            TriggerEvent("vorp:TipRight", Config.Language.notatrainer.." : "..v.trainerjob, 4000) 
                        end
                    else
                        sellAnimal()  
                        Citizen.Wait(200)
                    end  
                    Citizen.Wait(1000)       
                end
            end
        end  
        if sleep then 
            Citizen.Wait(500)
        end 
        Citizen.Wait(1)
    end
end)

-- DEV TOOLS -- 

RegisterCommand("horse", function() -- prints what entity model current mount is
    local horse = Citizen.InvokeNative(0xE7E11B8DCBED1058,PlayerPedId())
    local model = GetEntityModel(horse)
    print("model",model) 
 end)

 RegisterCommand("dh", function() -- deletes horse
    local horse = Citizen.InvokeNative(0xE7E11B8DCBED1058,PlayerPedId()) -- 
    DeletePed(horse)
 end)
