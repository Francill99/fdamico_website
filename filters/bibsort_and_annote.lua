-- filters/bibsort_and_annote.lua
-- 1) Sort bibliography by year DESC (latest first)
-- 2) Append 'TL;DR' + italic annote below each entry

local refs_by_id = {}

local function get_year_from_date(d)
  -- CSL JSON 'issued' could be { "date-parts": [[YYYY, MM, DD]] }
  if not d then return nil end
  local dp = d["date-parts"]
  if dp and dp[1] and dp[1][1] then
    return tonumber(dp[1][1])
  end
  return nil
end

-- Capture references and sort them by year desc
function Meta(meta)
  if meta.references then
    -- build array with (ref, year)
    local arr = {}
    for _, r in ipairs(meta.references) do
      local y = nil
      if r.issued then y = get_year_from_date(r.issued) end
      -- fallback: try 'year' string field
      if not y and r.year then
        y = tonumber(tostring(r.year):match("%d%d%d%d"))
      end
      table.insert(arr, {ref = r, year = y or -math.huge})
    end
    table.sort(arr, function(a, b) return a.year > b.year end)
    -- write back sorted list
    local sorted = {}
    for _, t in ipairs(arr) do
      table.insert(sorted, t.ref)
      if t.ref.id then refs_by_id[t.ref.id] = t.ref end
    end
    meta.references = sorted
    return meta
  end
end

-- Append TL;DR (annote) under each bibliography item
function Div(el)
  -- Pandoc renders bibliography entries as Divs with identifiers like "ref-<bibkey>"
  if el.identifier and el.identifier:match("^ref%-") then
    local key = el.identifier:gsub("^ref%-", "")
    local ref = refs_by_id[key]
    if ref and ref.annote then
      -- Build: [TL;DR:] (blue) + italic annote
      local lbl = pandoc.Span({pandoc.Str("TL;DR:")}, {class = "tldr-label"})
      local note = pandoc.Emph(pandoc.Str(ref.annote))
      -- As a paragraph beneath the entry
      table.insert(el.content, pandoc.Para({lbl, pandoc.Space(), note}))
    end
    return el
  end
end
