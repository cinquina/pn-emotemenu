local config = lib.load('shared.data.config')

local function createExports (name, cb)
    exports(name, cb)
    if config.provideScullyEmoteMenuExports then
        AddEventHandler(('__cfx_export_scully_emotemenu_%s'):format(name), function(setCB)
            setCB(cb)
        end)
    end
end

return {
    createExports = createExports
}
