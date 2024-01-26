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

-- addon

_addon.name = 'target_inspector'
_addon.author = 'rjt'
_addon.version = '0.1'
_addon.commands = { 'ti' }

texts = require('texts')

target_settings = {
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
    }
}
target_info = texts:new('${value}', target_settings)


windower.register_event('target change', function(index)
    local mob = windower.ffxi.get_mob_by_index(index)
    if mob then
        local msg = ""
        for k, v in pairs(mob) do
            msg = msg .. string.format("%s: %s\n", k, v)
        end
        target_info.value = msg
        target_info:visible(true)
    else
        target_info:visible(false)
    end
end)
