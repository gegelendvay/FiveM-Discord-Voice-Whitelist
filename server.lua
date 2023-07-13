-- Configure your Discord bot's token, your guild ID you want to check voice connections in, and the interval of additional checks
local token = 'Bot {YOUR TOKEN HERE}'
local guildId = '{YOUR GUILD ID HERE}'
local minutes = 0.1 -- Equals 6 seconds

AddEventHandler('playerConnecting', function(name, setCallback, deferrals)
    local src = source
    deferrals.defer()
    deferrals.update('Welcome, '..GetPlayerName(src)..'. Checking your Discord voice channel connection state.')

    -- Get the player's license and Discord ID
    local license, discordId = nil, nil
    for _, v in ipairs(GetPlayerIdentifiers(src)) do
        if string.sub(v, 1, string.len('license:')) == 'license:' then
            license = v
        elseif string.sub(v, 1, string.len('discord:')) == 'discord:' then
            discordId = v
            discordId = string.gsub(discordId, 'discord:', '')
        end
    end

    -- Check if the player has a Discord account linked
    if discordId then
        -- Check if the player is connected to a voice channel
        if checkVoiceChannel(src, discordId) then
            deferrals.done()
        else
            deferrals.done('You are not connected to a voice channel.')
        end
    else
        deferrals.done('No Discord account was found.')
    end
end)

CreateThread(function()
    while true do
        Wait(minutes * 60000)
        for _, v in ipairs(GetPlayers()) do
            local license, discordId = nil, nil
            for _, v in ipairs(GetPlayerIdentifiers(v)) do
                if string.sub(v, 1, string.len('license:')) == 'license:' then
                    license = v
                elseif string.sub(v, 1, string.len('discord:')) == 'discord:' then
                    discordId = v
                    discordId = string.gsub(discordId, 'discord:', '')
                end
            end

            if discordId then
                -- Send the current state to the client
                if not checkVoiceChannel(v, discordId) then
                    TriggerClientEvent('DiscordVoiceChecker', v, false)
                else
                    TriggerClientEvent('DiscordVoiceChecker', v, true)
                end
            end
        end
    end
end)

-- The function will try to voice mute the user. If the response code is 400, it means that the user is not connected to a voice channel
function checkVoiceChannel(src, discordId)
    local data = nil
    local url = ('https://discord.com/api/v10/guilds/%s/members/%s'):format(guildId, discordId)
    PerformHttpRequest(url, function(errorCode, resultData, resultHeaders)
		data = {data=resultData, code=errorCode, headers=resultHeaders}
    end, "PATCH", json.encode{mute = false}, {["Content-Type"] = "application/json", ["Authorization"] = token})

    repeat Wait(0) until data ~= nil

    -- If the player is not connected to a voice channel, return false
    if data.code == 400 then
        return false
    end
    -- In any other case, return true
    return true
end