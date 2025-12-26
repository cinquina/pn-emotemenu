local mainMenuOptions = {
    { label = locale('emote_options'), description = locale('open_emote_options'), icon = 'fa-solid fa-person', args = { id = 'emotemenu_submenu_emotes' } },
    { label = locale('walking_styles'), icon = 'fa-solid fa-person-walking', values = {}, args = { id = 'emotemenu_walks', walks = Walks }, close = false },
    { label = locale('scenarios'), icon = 'fa-solid fa-person-walking-with-cane', values = {}, args = { id = 'emotemenu_scenarios', scenarios = Scenarios }, close = false },
    { label = locale('facial_expressions'), icon = 'fa-solid fa-face-angry', values = {}, args = { id = 'emotemenu_expressions', expressions = Expressions }, close = false },
    { label = locale('cancel'), values = {
        { label = locale('emote'), description = locale('cancel_your_emote') },
        { label = locale('walk_style'), description = locale('reset_walk_style') },
        { label = locale('expression'), description = locale('reset_your_expression') },
        { label = locale('all'), description = locale('cancel_reset_everything') }
    }, icon = 'fa-solid fa-ban', args = { id = 'emotemenu_cancel' }, close = false }
}

local preview = require 'client.modules.preview'
local isUiOpen = false

local function BuildCategories()
    local categories = {}

    local function addCategory(name, list, type)
        if not list or #list == 0 then return end
        local items = {}
        for _, data in ipairs(list) do
            local label = data.Label or data.name or "Unknown"
            local cmd = data.Command or data.anim or ""
            items[#items + 1] = { label = label, command = cmd, type = type }
        end
        categories[#categories + 1] = { name = name, animations = items }
    end

    addCategory("Walking Styles", Walks, "walk")
    addCategory("Scenarios", Scenarios, "scenario")
    addCategory("Facial Expressions", Expressions, "expression")

    for _, submenu in ipairs(Emotes or {}) do
        addCategory(submenu.name or "Emotes", submenu.options or {}, "emote")
    end

    return categories
end

for i = 1, #Config.menuCommands do
    Utils.addCommand(Config.menuCommands[i], {
        help = locale('open_emote_menu')
    }, function(source, args, raw)
        if isUiOpen then
            SetNuiFocus(false, false)
            SendNUIMessage({ action = "hide" })
            isUiOpen = false
        else
            SetNuiFocus(true, true)
            local categories = BuildCategories()
            local favEmotes = KVP.getTable("favEmotes")
            print(json.encode(favEmotes))
            SendNUIMessage({
                action = "show",
                data = { categories = categories, favEmotes = favEmotes }
            })
            isUiOpen = true
        end
    end)
end

if Config.menuKeybind ~= '' then
    if #Config.menuCommands > 0 then
        RegisterKeyMapping(Config.menuCommands[1], locale('open_emote_menu'), 'keyboard', Config.menuKeybind)
    end
end

RegisterNUICallback("playAnimation", function(data, cb)
    if not data or not data.command then return cb("no") end
    print(data.type)
    if data.type == "emote" then
        -- Emote standard
        ExecuteCommand(("e %s"):format(data.command))
    elseif data.type == "walk" then
        -- Walking style
        for _, walk in ipairs(Walks or {}) do
            if walk.Command == data.command then
                SetWalk(walk.Walk)
                break
            end
        end
    elseif data.type == "expression" then
        -- Expression
        for _, expr in ipairs(Expressions or {}) do
            if expr.Command == data.command then
                SetExpression(expr.Expression)
                break
            end
        end
    elseif data.type == "scenario" then
        -- Scenario
        for _, scen in ipairs(Scenarios or {}) do
            if scen.Command == data.command then
                PlayEmote(scen)
                break
            end
        end
    else
        print(("[AnimationMenu] Tipo sconosciuto: %s"):format(data.type or "nil"))
    end

    cb("ok")
end)

RegisterNUICallback("stopAnimation", function(_, cb)
    CancelEmote(true)
    cb("ok")
end)


RegisterNUICallback("setFavouriteEmotes", function(body, cb)
    print("settando fav", json.encode(body.favouriteEmotes))
    KVP.update("favEmotes", body.favouriteEmotes)
    cb("ok")
end)

RegisterNUICallback("previewAnimation", function(data, cb)
    if not data or not data.command then return cb("no") end

    local emoteFound = nil
    for _, submenu in ipairs(Emotes or {}) do
        for _, emote in ipairs(submenu.options or {}) do
            if emote.Command == data.command then
                emoteFound = emote
                break
            end
        end
        if emoteFound then break end
    end

    if emoteFound and Config.enableEmotePreview then
        local preview = require 'client.modules.preview'
        preview.showEmote(emoteFound)
    end

    cb("ok")
end)

RegisterNUICallback("closeUI", function(_, cb)
    preview.finish()
    SetNuiFocus(false, false)
    isUiOpen = false
    cb("ok")
end)