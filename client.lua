local spawnedPeds = {} -- Lista do przechowywania wszystkich zrespionych pedów

-- Funkcja odpowiedzialna za respienie peda i reakcjê na gracza
function SpawnPedWithReaction(pedName, count)
    -- Pobranie koordynatów gracza
    local playerPed = PlayerPedId()
    local playerPos = GetEntityCoords(playerPed)
    
    -- Za³aduj model peda
    RequestModel(pedName)
    while not HasModelLoaded(pedName) do
        Citizen.Wait(100) -- Czekaj, a¿ model siê za³aduje
    end

    -- Respienie pedów
    for i = 1, count do
        -- Zresp peda w losowej pozycji blisko gracza
        local offsetX = math.random(-3, 3)
        local offsetY = math.random(-3, 3)
        local ped = CreatePed(4, pedName, playerPos.x + offsetX, playerPos.y + offsetY, playerPos.z, GetEntityHeading(playerPed), true, false)
        
        -- Dodaj peda do listy
        table.insert(spawnedPeds, ped)

        -- Zwolnienie modelu, aby nie zajmowa³ niepotrzebnej pamiêci
        SetModelAsNoLongerNeeded(pedName)

        -- Uzbrojenie peda w SMG
        GiveWeaponToPed(ped, GetHashKey("WEAPON_SMG"), 250, false, true)

        -- Ustawienie peda, aby ignorowa³ innych NPC
        SetPedRelationshipGroupHash(ped, GetHashKey("PED_GROUP"))

        -- Ustawienie relacji miêdzy pedami
        SetRelationshipBetweenGroups(0, GetHashKey("PED_GROUP"), GetHashKey("PED_GROUP")) -- Pedy ignoruj¹ siebie nawzajem
        SetRelationshipBetweenGroups(5, GetHashKey("PED_GROUP"), GetHashKey("PLAYER")) -- Pedy nienawidz¹ graczy

        -- Ustawienia walki peda
        SetPedCombatAttributes(ped, 46, true) -- Ped nie ucieka podczas walki
        SetPedCombatAttributes(ped, 5, true) -- Ped ignoruje walkê z innymi NPC
        SetPedFleeAttributes(ped, 0, false) -- Ped nie ucieka
        SetPedSeeingRange(ped, 25.0) -- Ped widzi tylko w promieniu 25 metrów
        SetPedHearingRange(ped, 50.0) -- Ped s³yszy w promieniu 50 metrów

        -- Reakcja peda na strza³y lub celowanie
        Citizen.CreateThread(function()
            while DoesEntityExist(ped) do
                Citizen.Wait(500)
                if IsPlayerFreeAimingAtEntity(PlayerId(), ped) or HasEntityBeenDamagedByEntity(ped, playerPed, true) then
                    TaskCombatPed(ped, playerPed, 0, 16) -- Ped atakuje gracza
                    SetPedAlertness(ped, 3)
                end
            end
        end)
    end

    -- Komunikat, ¿e ped zosta³ zrespiony
    TriggerEvent('chat:addMessage', {
        color = {0, 255, 0},
        multiline = true,
        args = {"System", "Zrespiono " .. count .. " pedów: " .. pedName .. "."}
    })
end

-- Funkcja do usuwania wszystkich zrespionych pedów
function RemoveAllPeds()
    for _, ped in ipairs(spawnedPeds) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped) -- Usuniêcie peda
        end
    end
    spawnedPeds = {} -- Resetowanie listy zrespionych pedów
end

-- Komenda do respienia pedów z reakcj¹
RegisterCommand("zresp", function(source, args, rawCommand)
    -- Sprawdzenie, czy wpisano nazwê modelu peda
    if #args < 1 then
        TriggerEvent('chat:addMessage', {
            color = {255, 0, 0},
            multiline = true,
            args = {"System", "Musisz podaæ nazwê modelu peda! U¿yj: /zresp [pedname] [iloœæ]"}
        })
        return
    end
    
    local pedName = args[1] -- Pobierz nazwê modelu peda z komendy
    local pedCount = tonumber(args[2]) or 1 -- Pobierz iloœæ pedów lub ustaw domyœlnie 1

    -- SprawdŸ, czy model peda jest poprawny
    if IsModelInCdimage(pedName) and IsModelAPed(pedName) then
        SpawnPedWithReaction(pedName, pedCount) -- Zresp peda z reakcj¹
    else
        TriggerEvent('chat:addMessage', {
            color = {255, 0, 0},
            multiline = true,
            args = {"System", "Niepoprawny model peda: " .. pedName}
        })
    end
end, false)

-- Komenda do usuwania wszystkich pedów
RegisterCommand("wywalpeda2", function()
    RemoveAllPeds() -- Usuniêcie wszystkich zrespionych pedów
    TriggerEvent('chat:addMessage', {
        color = {255, 0, 0},
        multiline = true,
        args = {"System", "Wszystkie pedy zosta³y usuniête!"}
    })
end, false)
