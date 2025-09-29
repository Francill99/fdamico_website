-- Sort bibliography (latest first) and append TL;DR from 'abstract' (or fallback 'note'/'annote')

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
      if r.id then refs_by_id[r.id] = r end
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

local function tldr_text(ref)
  -- prefer 'abstract'; fallback to 'note' then 'annote'
  if ref and ref.abstract and #ref.abstract > 0 then return ref.abstract end
  if ref and ref.note and #ref.note > 0 then return ref.note end
  if ref and ref.annote and #ref.annote > 0 then return ref.annote end
  return nil
end

local function append_tldr(container, txt)
  local lbl = pandoc.Span({pandoc.Str("TL;DR:")}, {class = "tldr-label"})
  local note = pandoc.Emph(pandoc.Str(txt))
  table.insert(container.content, pandoc.Para({lbl, pandoc.Space(), note}))
  return container
end

function Div(el)
  -- bibliography entries are typically Divs with id="ref-<bibkey>"
  if el.identifier and el.identifier:match("^ref%-") then
    local key = el.identifier:gsub("^ref%-", "")
    local ref = refs_by_id[key]
    local txt = tldr_text(ref)
    if txt then return append_tldr(el, txt) end
  end
end

function Span(el)
  -- fallback if entries are Spans (rare)
  if el.identifier and el.identifier:match("^ref%-") then
    local key = el.identifier:gsub("^ref%-", "")
    local ref = refs_by_id[key]
    local txt = tldr_text(ref)
    if txt then
      local d = pandoc.Div({el}, {id = el.identifier, class = el.classes})
      return append_tldr(d, txt)
    end
  end
end
