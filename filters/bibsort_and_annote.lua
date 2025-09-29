-- Sort bibliography (latest first) and append TL;DR (annote/note) under each entry.

local refs_by_id = {}

local function get_year_from_date(d)
  if not d then return nil end
  local dp = d["date-parts"]
  if dp and dp[1] and dp[1][1] then
    return tonumber(dp[1][1])
  end
  return nil
end

function Meta(meta)
  if meta.references then
    local arr = {}
    for _, r in ipairs(meta.references) do
      -- store by id for later lookup
      if r.id then refs_by_id[r.id] = r end
      -- figure out year (issued or literal 'year')
      local y = r.issued and get_year_from_date(r.issued) or nil
      if not y and r.year then
        y = tonumber(tostring(r.year):match("%d%d%d%d"))
      end
      table.insert(arr, {ref = r, year = y or -math.huge})
    end
    table.sort(arr, function(a, b) return a.year > b.year end)
    local sorted = {}
    for _, t in ipairs(arr) do table.insert(sorted, t.ref) end
    meta.references = sorted
    return meta
  end
end

-- Helper to append TL;DR paragraph to a block container
local function append_tldr(container, txt)
  local lbl = pandoc.Span({pandoc.Str("TL;DR:")}, {class = "tldr-label"})
  local note = pandoc.Emph(pandoc.Str(txt))
  table.insert(container.content, pandoc.Para({lbl, pandoc.Space(), note}))
  return container
end

function Div(el)
  -- Pandoc usually wraps each entry as Div id="ref-<key>" class="csl-entry"
  if el.identifier and el.identifier:match("^ref%-") then
    local key = el.identifier:gsub("^ref%-", "")
    local ref = refs_by_id[key]
    local txt = ref and (ref.annote or ref.note)
    if txt and #txt > 0 then
      return append_tldr(el, txt)
    end
  end
end

function Span(el)
  -- Some outputs may produce spans with id="ref-<key>"
  if el.identifier and el.identifier:match("^ref%-") then
    local key = el.identifier:gsub("^ref%-", "")
    local ref = refs_by_id[key]
    local txt = ref and (ref.annote or ref.note)
    if txt and #txt > 0 then
      -- Wrap span in a Div so we can append a paragraph under it
      local d = pandoc.Div({el}, {id = el.identifier, class = el.classes})
      return append_tldr(d, txt)
    end
  end
end
