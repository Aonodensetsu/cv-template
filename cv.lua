-- helper function for title exceptions
-- exception_list{ 'some', 'words', 'here' } = those words are exceptions
-- exception_list({ 'words' }, first_in_sentence, last_in_sentence)
local function exc_list(ws, f, l) -- words, first, last
    return function(i, n, w) -- index, num_words, word
        if not f == nil then return f end
        if not l == nil then return l end
        for _, word in ipairs(ws) do if word == w then return true end end
        return false
    end
end

-- when converting text to title case some words should be left lowercase
-- Because This Is a Title (notice the lowercase a)
-- 2_letter_language_code = <function(index, num_words, word) that returns if word is an exception>,
local title_exceptions = {
    en = exc_list({ 'a', 'an', 'in', 'the', 'to', 'as', 'and', 'but', 'for', 'or', 'nor', 'with', 'of', 'on' }, true, true),
}

-- setting to "true" will force all text into title mode
-- use for spotting words you might want to add to the title exceptions
local title_debug = false

-- setting to "true" will print the translation ID instead of the text
-- use to see if any text is not using the translation system
-- if a translation ID is used but not in the translations table, the ID will be displayed (for typos)
local tl_debug = false

-- translations now found in file: translations.yaml


local ver = os.getenv'CVVER' or 'pdf'
local lang = os.getenv'CVLANG' or 'en'

local yf = io.open('translations.yaml', 'r')
local content = yf:read('*all')
local translations = require'tinyyaml'.parse(content)
yf:close()

local utf8 = require'.utf8lua':init()
for k, v in pairs(utf8) do string[k] = v end

getmetatable''.__mod = function(s, tab)
    return (s:gsub('(%%%b{})', function(w)
        local key = w:sub(3, -2)
        return tab[tonumber(key) or key] or w
    end))
end

local function print(s)
  if s:sub(-1) ~= '\n' then s = s .. '\n' end
  for line in s:gmatch'([^\n]*)\n' do
    line = line:match'^%s*(.-)%s*$'
    if line then tex.sprint(line) end
  end
end

function size(size, ratio)
    local s = tonumber(size)
    local r = tonumber(ratio) or 1.2
    print([[
        \fontsize{%{1}pt}{%{2}pt}\selectfont
    ]] % { s, s * r })
end

function whenpdf(yes, no)
    if ver == 'pdf' and yes ~= '' then print(yes) end
    if ver ~= 'pdf' and no ~= '' then print(no) end
end

local function totitlecase(s)
    local matcher = "[%w'-]+"
    local cap = function(t) return t:sub(1, 1):upper() .. t:sub(2) end
    local word_amt = 0
    for _ in s:gmatch(matcher) do
        word_amt = word_amt + 1
    end
    local i = 0
    return s:gsub('(%{1})' % {matcher}, function(w)
        i = i + 1
        if not title_exceptions[lang](i, word_amt, w:lower())
        then return cap(w)
        else return w end
    end)
end

function tl(id, format)
    if title_debug then format = 'title' end
    local dsp_id = id:gsub('_', '\\_')
    local entry = translations[id]
    if not entry then return '?tl:' .. dsp_id end
    if not entry[lang] then return '?tl:%{1}:%{2}' % { dsp_id, lang } end
    local text = (entry[lang]:gsub('\n', ' '):gsub('^%s*(.-)%s*$', '%1'))
    if tl_debug then return 'tl:' .. dsp_id end
    local formatter = ({
        [''] = function(t) return t end,
        upper = function(t) return t:upper() end,
        lower = function(t) return t:lower() end,
        cap = function(t) return t:sub(1, 1):upper() .. t:sub(2) end,
        sentence = function(t) return t:sub(1, 1):upper() .. t:sub(2) .. '.' end,
        title = totitlecase,
    })[format]
    print(formatter(text))
end

local defined_icons = {}
function icon(size, name, style)
    if style == '' then style = 'regular' end
    local font = ({
        light   = 'Font-Awesome-5-Pro-Light',
        regular = 'Font-Awesome-5-Pro-Regular',
        solid   = 'Font-Awesome-5-Pro-Solid',
        duotone = 'Font-Awesome-5-Duotone-Solid',
        brands  = 'Font-Awesome-5-Brands-Regular',
    })[style]
    local icons_dir = 'icons'
    local icons_path = '%{1}/%{2}' % { lfs.currentdir():gsub('\\', '/'), icons_dir }
    if lfs.attributes(icons_path) == nil then lfs.mkdir(icons_path) end
    local icon = '%{1}_%{2}' % { name, style }
    local icon_path = '%{1}/%{2}.png' % { icons_path, icon }
    if lfs.attributes(icon_path) == nil then
        os.execute(([[
            magick -size 100x100 -background none -pointsize 50 -fill white
                   -font "%{1}" label:"%{2}" -flatten -trim "%{3}"
        ]]):gsub('\n', '') % { font, name, icon_path })
    end
    local latex_path = '%{1}/%{2}' % { icons_dir, icon }
    if not defined_icons[icon] then
        print([[
            \begin{tikzfadingfrompicture}[name=%{1}]
                \node[inner sep=0] (%{1}) {\includegraphics{%{2}}};
            \end{tikzfadingfrompicture}
        ]] % { icon, latex_path })
        defined_icons[icon] = true
    end
    print([[
        \raisebox{%{3}\height}{
            \resizebox{!}{%{2}\fontcharht\font`B}{
                \begin{tikzpicture}
                    \fill[path fading=%{1},fit fading=false,inner sep=0] (%{1}.south west) rectangle (%{1}.north east);
                \end{tikzpicture}
            }
        }
    ]] % { icon, size, (1 - size) / 2 })
end

function link(name, url)
    if name == '' then name = url end
    whenpdf([[
        \href{%{1}}{%
            \color{.!50!section-compound}%{2}\hspace{0.2ex}\raisebox{0.7ex}{\size{6}\icon{external-link}[solid]}%
        }
    ]] % {url, name}, name)
end

function separate(num)
    local num = tonumber(num) or 1
    print([[\vspace{%{1}mm}]] % { 2.3 + num/4 })
    for i = 1, num do
        print[[{\color{section-compound}\hrule\relax}]]
        if i < num then
            print[[\vspace{0.6mm}]]
        end
    end
    print([[\vspace{%{1}mm}]] % { 0.45 + num/4 })
end

function starbar(num)
    local num = tonumber(num) or 1
    print([[
      \\
      \progressbar[
        emptycolor=section,
        filledcolor=section-compound,
        linecolor=section!75!black,
        width=0.85\columnwidth,
        heighta=2.6mm,
        borderwidth=0.5mm,
        roundnessr=0.3,
        subdivisions=1,
      ]{%{1}}
    ]] % { num })
    if num == 1 then print [[{\hspace{-0.5em}\color{section-compound}\size{18}\icon{stars}[solid]}]] end
    print [[\\]]
end

print[[
\NewDocumentCommand\size{ m O{} }{\luadirect{size(\luastringN{#1},\luastringN{#2})}}
\NewDocumentCommand\whenpdf{ +m +m }{\luadirect{whenpdf(\luastringN{#1},\luastringN{#2})}}
\NewDocumentCommand\tl{ m O{} }{\luadirect{tl(\luastringN{#1},\luastringN{#2})}}
\NewDocumentCommand\icon{ O{1} m O{regular} }{\luadirect{icon(\luastringN{#1},\luastringN{#2},\luastringN{#3})}}
\NewDocumentCommand\link{ O{} m }{\luadirect{link(\luastringN{#1},\luastringN{#2})}}
\NewDocumentCommand\separate{ O{1} }{\luadirect{separate(\luastringN{#1})}}
\NewDocumentCommand\starbar{ O{1} }{\luadirect{starbar(\luastringN{#1})}}
]]
