--made by XTZ, CheesyManiac
--i'd like to apologize in advance for any piece of code that mightve gotten mishandled and abused in the following lines

--ideas
--display/glow color picker (Idea: Eurobeat)
--make phone resizeable (:clueless::thumbsup: good luck)
--map view instead of chat option for singleplayer, zoom setting slider but other than just centered on the player, simple black triangles for player cars, kinda like comfy map but in pure black, since a outline glow is probably too much work use a grey for player cars so they dont blend in with the track or the other way around

--im sure this does something
ui.setAsynchronousImagesLoading(true)

--adding this so unicode characters like kanji dont break while scrolling
--had to add a -1 to data.nowplaying.length and a +1 to settings.spaces because otherwise the function complains about a nil value for j, probably fine the way it is
require 'src.utf8'
function utf8.sub(s, i, j)
    i = utf8.offset(s, i)
    j = utf8.offset(s, j + 1) - 1
    return string.sub(s, i, j)
end

--setting values
local settings = ac.storage {
    glare = true,
    glow = true,
    tracktime = false,
    nowplaying = true,
    spaces = 5,
    scrollspeed = 2,
    damage = false,
    damageduration = 5,
    fadeduration = 3,
    crackforce = 15,
    breakforce = 30,
    chatmove = true,
    chattimer = 15,
    chatmovespeed = 3,
    chatfontsize = 16
}

--initial spacing
local spacetable = {}
for i = 0, settings.spaces + 1 do
    spacetable[i] = ' '
end

--we do a minuscule amount of declaring. do i need all of this? probably not but i like the way it makes me feel
local data = {
    ['size'] = vec2(250, 400),
    ['padding'] = vec2(10, -21),
    ['scale'] = 1,
    ['offset'] = 328,
    ['src'] = {
        ['display'] = './src/img/display.png',
        ['phone'] = './src/img/phone.png',
        ['glare'] = './src/img/glare.png',
        ['glow'] = './src/img/glow.png',
        ['cracked'] = './src/img/cracked.png',
        ['destroyed'] = './src/img/destroyed.png',
        ['font'] = ui.DWriteFont('NOKIA CELLPHONE FC SMALL', './src')
    },
    ['time'] = {
        ['Local'] = '',
        ['track'] = '',
        ['display'] = ''
    },
    ['nowplaying'] = {
        ['artist'] = '',
        ['title'] = '',
        ['scroll'] = '',
        ['display'] = '',
        ['length'] = 0,
        ['pstr'] = '     PAUSE ll',
        ['isPaused'] = false,
        ['spaces'] = table.concat(spacetable),
        ['FUCK'] = false
    },
    ['chat'] = {
        ['size'] = vec2(235, 230),
        ['flags'] = bit.bor(ui.WindowFlags.NoDecoration, ui.WindowFlags.NoBackground, ui.WindowFlags.NoNav, ui.WindowFlags.NoInputs)
    },
    ['car'] = {
        ['player'] = ac.getCar(0),
        ['damagestate'] = 0
    }
}

--chat message event handler
local chatcount = 0
local chat = {}
local chatTimer = settings.chattimer
local movePhone = 0
local movePhoneDown = true
local movePhoneUp = false

ac.onChatMessage(function(message, senderCarIndex, senderSessionID)
    chatcount = chatcount + 1

    --start the countdown to move the chat if enabled
    if settings.chatmove then
        chatTimer = settings.chattimer
        movePhoneUp = true
    end

    --get message content and sender
    if ac.getDriverName(senderCarIndex) then
        chat[chatcount] = { message, ac.getDriverName(senderCarIndex) .. ":  " }
    else
        chat[chatcount] = { message, '' }
    end

    --only keep the 20 latest messages (this is enough for font sizes as small as 6)
    if table.getn(chat) > 20 then
        table.remove(chat, 1)
        chatcount = table.getn(chat)
    end
end)

--scrolling text
local scrlintvl
function scrollText()
    scrlintvl = setInterval(function()
        local nletter = utf8.sub(data.nowplaying.scroll, data.nowplaying.length - 1, data.nowplaying.length - 1)
        local nstring = utf8.sub(data.nowplaying.scroll, 1, data.nowplaying.length - 1)
        local scrollText = nletter .. nstring
        data.nowplaying.scroll = scrollText
        data.nowplaying.display = scrollText
    end, 1 / settings.scrollspeed, 'ST')
end

--update spacing
function UpdateSpacing()
    spacetable = {}
    for i = 0, settings.spaces + 1 do
        spacetable[i] = ' '
    end
    data.nowplaying.spaces = table.concat(spacetable)
    data.nowplaying.FUCK = true
end

--set and update time
function UpdateTime()
    if settings.tracktime then
        data.time.track = string.format("%02d", ac.getSim().timeHours) .. ":" .. string.format("%02d", ac.getSim().timeMinutes)
        data.time.display = data.time.track
    else
        data.time.Local = os.date("%H:%M")
        data.time.display = data.time.Local
    end
end

--set and update song info
function UpdateSong()
    if ac.currentlyPlaying().isPlaying and settings.nowplaying then
        if data.nowplaying.artist ~= ac.currentlyPlaying().artist or data.nowplaying.title ~= ac.currentlyPlaying().title or data.nowplaying.isPaused or data.nowplaying.FUCK then
            if not scrlintvl then scrollText() end
            data.nowplaying.isPaused = false
            data.nowplaying.FUCK = false
            data.nowplaying.artist = ac.currentlyPlaying().artist
            data.nowplaying.title = ac.currentlyPlaying().title
            data.nowplaying.scroll = data.nowplaying.artist .. ' - ' .. data.nowplaying.title .. data.nowplaying.spaces
            data.nowplaying.length = utf8.len(data.nowplaying.scroll)
        end
    elseif not ac.currentlyPlaying().isPlaying and not data.nowplaying.isPaused and settings.nowplaying then
        if scrlintvl then
            clearInterval(scrlintvl)
            scrlintvl = nil
        end
        data.nowplaying.isPaused = true
        data.nowplaying.length = utf8.len(data.nowplaying.pstr)
        data.nowplaying.display = data.nowplaying.pstr
    end
end

--update these every 2s, for realtime checking the time every 2s isnt necessary but with tracktime enabled and a high timeofdaymult a ingame minute could be really fast.
local updtintvl
function RunUpdate()
    updtintvl = setInterval(function()
        UpdateTime()
        if settings.nowplaying then UpdateSong() end
    end, 2, 'RU')
end

--turn on/off invervals when app gets opened/closed
function onHideWindow()
    clearInterval(updtintvl)
    clearInterval(scrlintvl)
    updtintvl = nil
    scrlintvl = nil
end

--this works as intended when reloading the script while already ingame because csp has already started the AcTools.CurrentlyPlaying.exe, when just starting the game that exe might take longer than 2s to start for whatever reason, in those cases it will go from loading to paused. i hate it
function onShowWindow()
    if settings.nowplaying then
        data.nowplaying.display = '    Loading...'
    end
    data.nowplaying.FUCK = true
    data.nowplaying.isPaused = false
    UpdateTime()
    RunUpdate()
end

--settings window
function script.windowMainSettings(dt)
    ui.tabBar('TabBar', function()

        --display settings
        ui.tabItem('Display Settings', function()

            --display glare toggle
            if ui.checkbox("Display Glare", settings.glare) then
                settings.glare = not settings.glare
            end

            --display glow toggle
            if ui.checkbox("Display Glow", settings.glow) then
                settings.glow = not settings.glow
            end

            --nowplaying toggle
            if ui.checkbox("Display Current Song", settings.nowplaying) then
                settings.nowplaying = not settings.nowplaying
                if settings.nowplaying then
                    data.nowplaying.FUCK = true
                    UpdateSong()
                else
                    clearInterval(updtintvl)
                    clearInterval(scrlintvl)
                    updtintvl = nil
                    scrlintvl = nil
                    RunUpdate()
                end
            end

            --change the spacing between the start and end of playing song names
            if settings.nowplaying then
                ui.text('\t')
                ui.sameLine()
                settings.spaces = ui.slider('##Spaces', settings.spaces, 1, 25, 'Spaces: ' .. '%.0f')
                if string.len(data.nowplaying.spaces) ~= settings.spaces + 1 then
                    UpdateSpacing()
                end

                --change the speed at which the songtext scrolls across
                ui.text('\t')
                ui.sameLine()
                settings.scrollspeed, SPEEDCHANGE = ui.slider('##Scrollspeed', settings.scrollspeed, 0, 15, 'Scrollspeed: ' .. '%.1f')
                if SPEEDCHANGE and not data.nowplaying.isPaused then
                    clearInterval(scrlintvl)
                    scrlintvl = nil
                    scrollText()
                end
            end

            --display tracktime
            if ui.checkbox("Display Track Time", settings.tracktime) then
                settings.tracktime = not settings.tracktime
                UpdateTime()
            end

            --display damage toggle
            if ui.checkbox("Display Screen Damage", settings.damage) then
                settings.damage = not settings.damage
            end

            --display duration and forces sliders
            if settings.damage then
                ui.text('\t')
                ui.sameLine()
                settings.damageduration, damageChange = ui.slider('##Duration', settings.damageduration, 1, 60, 'Duration: ' .. '%.1f seconds')
                if damageChange then damageDurationTimer = settings.damageduration end
                ui.text('\t')
                ui.sameLine()
                settings.fadeduration, fadeChange = ui.slider('##Fadeout', settings.fadeduration, 1, 60, 'Fade out: ' .. '%.1f seconds')
                if fadeChange then fadeDurationTimer = settings.fadeduration end
                ui.text('\t')
                ui.sameLine()
                settings.crackforce = ui.slider('##Crackforce', settings.crackforce, 5, 50, 'Crack Force: ' .. '%.0f')
                ui.text('\t')
                ui.sameLine()
                settings.breakforce = ui.slider('##Breakfoce', settings.breakforce, 10, 100, 'Break Force: ' .. '%.0f')
            end
        end)

        --chat settings
        ui.tabItem('Chat Settings', function()

            --chat fontsize
            settings.chatfontsize = ui.slider('##ChatFontSize', settings.chatfontsize, 1, 72, 'Chat Fontsize: ' .. '%.0f')

            --move phone down after chat inactivity
            if ui.checkbox('Chat Inactivity', settings.chatmove) then
                settings.chatmove = not settings.chatmove
                if settings.chatmove then
                    movePhoneUp = false
                    chatTimer = settings.chattimer
                end
            end

            --inactivity and movespeed slideres
            if settings.chatmove then
                ui.text('\t')
                ui.sameLine()
                settings.chattimer, deadchatchange = ui.slider('##ChatTimer', settings.chattimer, 1, 120,
                    'Inactivity: ' .. '%.0f seconds')
                if deadchatchange then chatTimer = settings.chattimer end
                ui.text('\t')
                ui.sameLine()
                settings.chatmovespeed = ui.slider('##MoveSpeed', settings.chatmovespeed, 1, 20, 'Speed: ' .. '%.0f')
            end
        end)
    end)
end

--image sizing that is probably not labled correctly, dont care for now
local vecX = vec2(data.padding.x, data.size.y - data.size.y - data.padding.y):scale(data.scale)
local vecY = vec2(data.size.x + data.padding.x, data.size.y - data.padding.y):scale(data.scale)
local chatFadeTimer = 0
local chatInputActive = false
local damageDurationTimer = 0
local fadeDurationTimer = settings.fadeduration
local left, right, front, back = 0, 0, 0, 0
local forces = {}

--main app window
function script.windowMain(dt)

    --move the phone up/down depending on chat activity
    --seems to work for the most part, time/nowplaying text is artifacting (https://media.discordapp.net/attachments/856602216047050782/1076711678596628521/image.png) during movement on speeds faster than 1 (depends on fps) if the phone image is drawn below the glare image
    if settings.chatmove then

        --countdown until moving phone
        if chatTimer > 0 and movePhone == 0 then
            chatTimer = chatTimer - dt
            movePhoneDown = true
        end

        --move the phone
        if chatTimer <= 0 and movePhoneDown then
            movePhoneDown = true
            movePhone = math.floor(movePhone + dt * 100 * settings.chatmovespeed)
        elseif chatTimer > 0 and movePhoneUp then
            movePhone = math.floor(movePhone - dt * 100 * settings.chatmovespeed)
        end

        --stop the phone from moving further if its in position
        if movePhone > 328 then
            movePhone = 328
            movePhoneDown = false
        elseif movePhone < 0 then
            movePhone = 0
            movePhoneUp = false
            chatTimer = settings.chattimer
        end

        --if the settings gets disabled, set the phone to be placed correctly
    elseif not settings.chatmove and movePhone ~= 0 then
        movePhone = 0
    end

    --set fade timer if mouse is not hovering over the app
    local phoneHovered = ui.rectHovered(0, data.size)
    if phoneHovered and settings.chatmove then
        chatTimer = settings.chattimer
        movePhoneUp = true
    end
    if phoneHovered and movePhone == 0 then
        chatFadeTimer = 1
    elseif chatFadeTimer > 0 then
        chatFadeTimer = chatFadeTimer - dt
    end

    --draw main display
    ui.setCursor(vec2(0, 0 + movePhone))
    ui.childWindow("Display", data.size, data.chat.flags, function()

        --draw display image
        ui.drawImage(data.src.display, vecX, vecY, true)

        --draw song info if enabled
        if settings.nowplaying then
            ui.pushDWriteFont(data.src.font)
            ui.setCursor(vec2(92, 72))
            ui.dwriteTextAligned(data.nowplaying.display, 16, -1, 0, vec2(142, 18), false, 0)
            ui.popDWriteFont()
        end

        --draw time
        ui.pushDWriteFont(data.src.font)
        ui.setCursor(vec2(34, 72))
        ui.dwriteTextAligned(data.time.display, 16, 0, 0, vec2(55, 17), false, 0)
        ui.popDWriteFont()
    end)

    --draw chat messages
    ui.setCursor(vec2(20, 93 + movePhone))
    ui.childWindow("Chatbox", data.chat.size, data.chat.flags, function()
        if chatcount > 0 then
            for i = 1, chatcount do
                ui.pushDWriteFont(data.src.font)
                ui.dwriteTextWrapped(chat[i][2] .. chat[i][1], settings.chatfontsize, 0)
                ui.popDWriteFont()
                ui.setScrollHereY(1)
            end
        end
    end)

    --"break" the phone screen on harder impacts if enabled
    if settings.damage then

        --check if player colided with anything, and calculate the force
        if data.car.player.collidedWith > -1 then

            --reset the table for new colisions
            if data.car.damagestate < 2 then forces = {} end

            --invert negative values to be able to add them together
            if data.car.player.acceleration.x < 0 then left = data.car.player.acceleration.x * -1 else right = data.car.player.acceleration.x end
            if data.car.player.acceleration.z < 0 then front = data.car.player.acceleration.z * -1 else back = data.car.player.acceleration.z end

            --add all the forces together and calculate the mean value (divide by 2 might be wrong but i think you cant have values in more than 2 directions at the same time)
            --then insert them into a table and then get the hardest force value
            table.insert(forces, (front + back + left + right) / 2)
            local maxForce = math.max(unpack(forces))

            --set damage state if forces exeed the force values and reset damage duration if not already fading
            if maxForce > settings.breakforce then
                data.car.damagestate = 2
                if damageDurationTimer > 0 and fadeDurationTimer == settings.fadeduration then
                    damageDurationTimer = settings.damageduration
                end
            elseif maxForce > settings.crackforce then
                data.car.damagestate = 1
                if damageDurationTimer > 0 and fadeDurationTimer == settings.fadeduration then
                    damageDurationTimer = settings.damageduration
                end
            end
        end

        --display and fade timers
        if data.car.damagestate > 0 and damageDurationTimer <= 0 and fadeDurationTimer == settings.fadeduration then
            damageDurationTimer = settings.damageduration
        elseif damageDurationTimer > 0 then
            damageDurationTimer = damageDurationTimer - dt
        end

        if damageDurationTimer <= 0 and data.car.damagestate > 0 then
            fadeDurationTimer = fadeDurationTimer - dt
        end

        if fadeDurationTimer <= 0 and data.car.damagestate > 0 then
            data.car.damagestate = 0
            fadeDurationTimer = settings.fadeduration
        end

        --display damage depending on state
        if data.car.damagestate > 0 and fadeDurationTimer > 0 then
            ui.setCursor(vec2(0, 0 + movePhone))
            ui.childWindow('DisplayDamage', vec2(302, 417), data.chat.flags, function()
                if data.car.damagestate > 1 then
                    ui.drawImage(data.src.destroyed, vecX, vecY, rgbm(1, 1, 1, ((100 / settings.fadeduration) / 100) * fadeDurationTimer), true)
                end
                if data.car.damagestate > 0 then
                    ui.drawImage(data.src.cracked, vecX, vecY, rgbm(1, 1, 1, ((100 / settings.fadeduration) / 100) * fadeDurationTimer), true)
                end
            end)
        end
    end

    --draw images that need to be on top
    ui.setCursor(vec2(0, 0 + movePhone))
    ui.childWindow('onTopImages', vec2(300, 415), data.chat.flags, function()

        --draw phone image
        ui.drawImage(data.src.phone, vecX, vecY, true)

        --draw glare image if enabled
        if settings.glare then
            ui.drawImage(data.src.glare, vecX, vecY, true)
        end

        --draw glow image if enabled
        if settings.glow then
            ui.drawImage(data.src.glow, vecX, vecY, true)
        end
    end)

    --chat input
    --not affected by glare/glow because childwindows dont have clickthrough so I cant move it "below", not important just a ocd thing
    ui.setCursor(vec2(18, 306 + movePhone))
    ui.childWindow('Chatinput', vec2(298, 32), data.chat.flags, function()
        if phoneHovered and movePhone == 0 or chatInputActive then

            --if enabled, stop the phone from moving down while hovering over the app or while textinput is active
            if settings.chatmove then
                chatTimer = settings.chattimer
                movePhoneUp = true
            end
            --ui.pushStyleColor(0, rgbm(0,0,0,1))
            local chatInputString, chatInputChange, chatInputEnter = ui.inputText('Type new message...', chatInputString, ui.InputTextFlags.Placeholder)
            chatInputActive = ui.itemActive()
            if chatInputEnter then
                ac.sendChatMessage(chatInputString)
                chatInputString = ''
                ui.setKeyboardFocusHere(-1)
            end
            --ui.popStyleColor()
        elseif chatFadeTimer > 0 then
            ui.drawRectFilled(vec2(20, 8), vec2(213, 30), rgbm(0.1, 0.1, 0.1, 0.66 * chatFadeTimer), 2)
        end
    end)
end
