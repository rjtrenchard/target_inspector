-- Copyright © 2024, rj
-- All rights reserved.

-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:

--     * Redistributions of source code must retain the above copyright
--       notice, this list of conditions and the following disclaimer.
--     * Redistributions in binary form must reproduce the above copyright
--       notice, this list of conditions and the following disclaimer in the
--       documentation and/or other materials provided with the distribution.
--     * Neither the name of <addon name> nor the
--       names of its contributors may be used to endorse or promote products
--       derived from this software without specific prior written permission.

-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
-- ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
-- WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL rjt BE LIABLE FOR ANY
-- DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
-- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
-- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
-- ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
-- (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
-- SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


-------------------------------------------------------------------------------------
-- This addon displays the windower.ffxi.get_mob_by_index(index) table on screen.
-- it will also store
-------------------------------------------------------------------------------------

_addon.name = 'target_inspector'
_addon.author = 'rjt'
_addon.version = '0.1'
_addon.commands = { 'ti' }

config = require('config')
texts = require('texts')
json = require('json')
files = require('files')
packets = require('packets')
res = require('resources')

do
    local target_settings = {
        bg = { alpha = 50 },
        pos = {
            x = -100,
            y = 45
        },
        text = {
            font = 'arial',
            size = 10,
            stroke = {
                width = 1,
                alpha = 155,
                red = 0,
                green = 0,
                blue = 0
            },
            padding = 4,
            flags = {
                bold = false,
                right = true
            }
        },
        show = false,
        json_file = "mob_index.json",
        do_not_store = false
    }

    settings = config.load(target_settings)
end

target_info = texts.new('${value}', settings)


-- returns a file object pointing to the JSON file on disk
function open_json_file(file_name)
    if not type(file_name) == 'string' then error("No valid file passed.") end

    -- make new file object
    local file = files.new(file_name)

    if not file:exists() then
        file:create()
        file:write("{}\n", true)
    end

    return file
end

-- reads JSON data from file and returns it as a table
function read_json_file()
    if settings.do_not_store then return {} end

    local file = open_json_file(settings.json_file)

    local json_str = file:read()

    return json.decode(json_str)
end

-- updates the JSON file to match the table
function update_json_file()
    if settings.do_not_store then return end
    local file = open_json_file(settings.json_file)

    local mob_table_stringify = json.encode(mob_table)

    file:write(mob_table_stringify, true)
end

-- grabs all mobs in mob table and adds them
function update_mob_table_from_memory()
    local mob_array = windower.ffxi.get_mob_array()
    for k, mob in pairs(mob_array) do
        add_mob_to_table(mob)
    end
end

-- adds a single mob to the mob_table, as would be returned from windower.ffxi.get_mob_by_id(id)
function add_mob_to_table(mob)
    if not mob or not mob.is_npc then return end

    local zone = res.zones[windower.ffxi.get_info().zone]
    if not mob_table[zone] then mob_table[zone] = {} end
    if mob_table[zone][mob.name] then return end

    mob_table[zone][mob.name] = {
        ["model_number"] = mob.models,
        ["entity_type"] = mob.entity_type,
        ["spawn_type"] = mob.spawn_type,
        ["race"] = mob.race,
        ["status"] = mob.status,
    }
    updated = true;
end

-- updates text display
function draw_update()
    target_info:visible(settings.show)
end

windower.register_event('incoming chunk', function(id, data)
    -- on NPC update, add mob to table
    if id == 0x00e then
        local p = packets.parse('incoming', data)
        local index = p['Index']
        local mob = windower.ffxi.get_mob_by_index(index)
        add_mob_to_table(mob)
    end
end)

-- autosave
windower.register_event('day change', function()
    update_mob_table_from_memory()
    update_json_file()
end)

-- on target change, add mob to table, display mob data
windower.register_event('target change', function(index)
    local mob = windower.ffxi.get_mob_by_index(index)

    add_mob_to_table(mob)

    if mob and settings.show then
        local msg = string.format("%s (%d)\n==================\n", mob.name, mob.id)
        for k, v in pairs(mob) do
            msg = msg .. string.format("%s: %s\n", tostring(k), tostring(v))
            if k == 'models' then
                for i, l in pairs(v) do
                    msg = msg .. string.format("    %s: %s\n", i, l)
                end
            end
        end
        target_info.value = msg
        draw_update()
    else
        target_info:visible(false)
    end
end)

windower.register_event('addon command', function(arg)
    if arg == 'save' then
        config.save(settings)
        print("target_index saved")
    elseif arg == 'update' then
        update_mob_table_from_memory()
        update_json_file()
    elseif arg == 'show' then
        settings.show = not settings.show
        draw_update()
    elseif arg == 'nostore' then
        settings.do_not_store = not settings.do_not_store
        print((settings.do_not_store and "Not storing mob data" or "Storing mob data"))
    end
end)

mob_table = read_json_file()
