local URL = 'https://kvg-internetservice-proxy.p.networkteam.com/internetservice/services/passageInfo/stopPassages/stop?stop=2387&mode=departure'
local CACHE_SECONDS = 30

local last_fetch = 0
local cached = '${color2}lädt ...'

local function vlen(s)
    local n = 0
    for i = 1, #s do
        local b = s:byte(i)
        if b < 128 or b >= 192 then n = n + 1 end
    end
    return n
end

local function pad(s, w)
    local n = vlen(s)
    if n < w then return s .. string.rep(' ', w - n) end
    return s
end

local function fetch()
    local jq = [[.actual[:20][] | [.patternText, .direction, (.mixedTime | sub("%UNIT_MIN%"; " Min")), (if (.actualTime // "") != .plannedTime then .actualTime else "" end)] | @tsv]]
    local p = io.popen("curl -sf --max-time 10 '" .. URL .. "' | jq -r '" .. jq .. "'")
    if not p then return '${color2}API nicht erreichbar' end
    local rows = { '${color}' .. pad('Linie', 5) .. '  ' .. pad('Ziel', 24) .. 'Min' }
    for line in p:lines() do
        local nr, ziel, zeit, clock = line:match('^([^\t]+)\t([^\t]*)\t([^\t]*)\t(.*)$')
        if nr then
            local extra = (clock ~= nil and clock ~= '') and ('  ${color2}(' .. clock .. ')${color1}') or ''
            rows[#rows+1] = '${color1}' .. pad(nr, 5) .. '  ' .. pad(ziel, 24) .. '  ' .. zeit .. extra
        end
    end
    p:close()
    if #rows <= 1 then return '${color2}keine Abfahrten' end
    return table.concat(rows, '\n')
end

function conky_kvg_abfahrten()
    local now = os.time()
    if now - last_fetch >= CACHE_SECONDS then
        last_fetch = now
        cached = fetch()
    end
    return cached
end
