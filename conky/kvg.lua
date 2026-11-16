local STOP_FILE = os.getenv('HOME') .. '/.config/conky/kvg-stop.conf'
local CACHE_SECONDS = 30

local last_fetch = 0
local cached = '${color2}lädt ...'
local stop_nr = '2387'
local stop_name = 'Hauptbahnhof'

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

local function lpad(s, w)
    local n = vlen(s)
    if n < w then return string.rep(' ', w - n) .. s end
    return s
end

local function read_stop()
    local f = io.open(STOP_FILE, 'r')
    if not f then return end
    for line in f:lines() do
        local k, v = line:match('^%s*([%w_]+)%s*=%s*(.-)%s*$')
        if k == 'STOP' and v ~= '' then stop_nr = v
        elseif k == 'NAME' and v ~= '' then stop_name = v end
    end
    f:close()
end

local function fetch()
    read_stop()
    local url = 'https://kvg-internetservice-proxy.p.networkteam.com/internetservice/services/passageInfo/stopPassages/stop?stop=' .. stop_nr .. '&mode=departure'
    local jq = [==[([.actual[:20][] | [.patternText, .direction, ((.mixedTime | sub(" %UNIT_MIN%"; "min")) as $t | (if $t == "0min" then "sofort" else $t end)), (if (.actualTime // "") != .plannedTime then .actualTime else "" end)] | @tsv] + (if ((.generalAlerts // []) | length) > 0 then ["ALERT\t" + ([.generalAlerts[].title] | join("   +++   "))] else [] end)) | .[]]==]
    local p = io.popen("curl -sf --max-time 10 '" .. url .. "' | jq -r '" .. jq .. "'")

    if not p then return '${color2}API nicht erreichbar' end
    local rows = { '${font DejaVu Sans Mono:size=11}${color}' .. pad('Linie', 5) .. '  ' .. pad('Ziel', 24) .. '  ' .. lpad('Abfahrt', 8) }
    local footer = ''
    for line in p:lines() do
        if line:sub(1, 6) == 'ALERT\t' then
            footer = line:sub(7):gsub('[}%$]', {['}'] = ')', ['$'] = ''})
        else
            local nr, ziel, zeit, clock = line:match('^([^\t]+)\t([^\t]*)\t([^\t]*)\t(.*)$')
            if nr then
                local extra = (clock ~= nil and clock ~= '') and ('  ${color2}(' .. clock .. ')${color1}') or ''
                rows[#rows+1] = '${font Doto:size=11:weight=900}${color1}' .. pad(nr, 5) .. '  ' .. pad(ziel, 22) .. '  ' .. lpad(zeit, 8) .. extra
            end
        end
    end
    p:close()
    if #rows <= 1 and footer == '' then return '${color2}keine Abfahrten' end
    if footer ~= '' then
        rows[#rows+1] = '${font DejaVu Sans Mono:size=10}${color2}${scroll 39 ' .. footer .. '}'
    end
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

function conky_kvg_title()
    read_stop()
    return '${color1}' .. stop_name
end
