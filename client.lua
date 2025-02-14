local spawnedPeds = {} -- Lista do przechowywania wszystkich zrespionych ped�w

-- Funkcja odpowiedzialna za respienie peda i reakcj� na gracza
function SpawnPedWithReaction(pedName, count)
    -- Pobranie koordynat�w gracza
    local playerPed = PlayerPedId()
    local playerPos = GetEntityCoords(playerPed)
    
    -- Za�aduj model peda
    RequestModel(pedName)
    while not HasModelLoaded(pedName) do
        Citizen.Wait(100) -- Czekaj, a� model si� za�aduje
    end

    -- Respienie ped�w
    for i = 1, count do
        -- Zresp peda w losowej pozycji blisko gracza
        local offsetX = math.random(-3, 3)
        local offsetY = math.random(-3, 3)
        local ped = CreatePed(4, pedName, playerPos.x + offsetX, playerPos.y + offsetY, playerPos.z, GetEntityHeading(playerPed), true, false)
        
        -- Dodaj peda do listy
        table.insert(spawnedPeds, ped)

        -- Zwolnienie modelu, aby nie zajmowa� niepotrzebnej pami�ci
        SetModelAsNoLongerNeeded(pedName)

        -- Uzbrojenie peda w SMG
        GiveWeaponToPed(ped, GetHashKey("WEAPON_SMG"), 250, false, true)

        -- Ustawienie peda, aby ignorowa� innych NPC
        SetPedRelationshipGroupHash(ped, GetHashKey("PED_GROUP"))

        -- Ustawienie relacji mi�dzy pedami
        SetRelationshipBetweenGroups(0, GetHashKey("PED_GROUP"), GetHashKey("PED_GROUP")) -- Pedy ignoruj� siebie nawzajem
        SetRelationshipBetweenGroups(5, GetHashKey("PED_GROUP"), GetHashKey("PLAYER")) -- Pedy nienawidz� graczy

        -- Ustawienia walki peda
        SetPedCombatAttributes(ped, 46, true) -- Ped nie ucieka podczas walki
        SetPedCombatAttributes(ped, 5, true) -- Ped ignoruje walk� z innymi NPC
        SetPedFleeAttributes(ped, 0, false) -- Ped nie ucieka
        SetPedSeeingRange(ped, 25.0) -- Ped widzi tylko w promieniu 25 metr�w
        SetPedHearingRange(ped, 50.0) -- Ped s�yszy w promieniu 50 metr�w

        -- Reakcja peda na strza�y lub celowanie
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

    -- Komunikat, �e ped zosta� zrespiony
    TriggerEvent('chat:addMessage', {
        color = {0, 255, 0},
        multiline = true,
        args = {"System", "Zrespiono " .. count .. " ped�w: " .. pedName .. "."}
    })
end

-- Funkcja do usuwania wszystkich zrespionych ped�w
function RemoveAllPeds()
    for _, ped in ipairs(spawnedPeds) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped) -- Usuni�cie peda
        end
    end
    spawnedPeds = {} -- Resetowanie listy zrespionych ped�w
end

-- Komenda do respienia ped�w z reakcj�
RegisterCommand("zresp", function(source, args, rawCommand)
    -- Sprawdzenie, czy wpisano nazw� modelu peda
    if #args < 1 then
        TriggerEvent('chat:addMessage', {
            color = {255, 0, 0},
            multiline = true,
            args = {"System", "Musisz poda� nazw� modelu peda! U�yj: /zresp [pedname] [ilo��]"}
        })
        return
    end
    
    local pedName = args[1] -- Pobierz nazw� modelu peda z komendy
    local pedCount = tonumber(args[2]) or 1 -- Pobierz ilo�� ped�w lub ustaw domy�lnie 1

    -- Sprawd�, czy model peda jest poprawny
    if IsModelInCdimage(pedName) and IsModelAPed(pedName) then
        SpawnPedWithReaction(pedName, pedCount) -- Zresp peda z reakcj�
    else
        TriggerEvent('chat:addMessage', {
            color = {255, 0, 0},
            multiline = true,
            args = {"System", "Niepoprawny model peda: " .. pedName}
        })
    end
end, false)

-- Komenda do usuwania wszystkich ped�w
RegisterCommand("wywalpeda2", function()
    RemoveAllPeds() -- Usuni�cie wszystkich zrespionych ped�w
    TriggerEvent('chat:addMessage', {
        color = {255, 0, 0},
        multiline = true,
        args = {"System", "Wszystkie pedy zosta�y usuni�te!"}
    })
end, false)
