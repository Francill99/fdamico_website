-- Sort bibliography (latest first) and append TL;DR from 'abstract' (or fallback 'note'/'annote')
-- Works even when entries don't have id="ref-<key>" (appends sequentially inside #refs).

local ordered_tldr = {}   -- TL;DRs in sorted order

local function get_year_from_date(d)
  if not d then return nil end
  local dp = d["date-parts"]
  if dp and dp[1] and dp[1][1] then return tonumber(dp[1][1]) end
  return nil
end

local function tldr_text(ref)
  if ref and ref.abstract and #ref.abstract > 0 then return ref.abstract end
  if ref and ref.note and #ref.note > 0 then return ref.note end
  if ref and ref.annote and #ref.annote > 0 then return ref.annote end
  return nil
end

function Meta(meta)
  if not meta.references then return end

  -- sort references by year desc
  local arr = {}
  for _, r in ipairs(meta.references) do
    local y = r.issued and get_year_from_date(r.issued) or nil
    if not y and r.year then
      y = tonumber(tostring(r.year):match("%d%d%d%d"))
    end
    table.insert(arr, {ref = r, year = y or -math.huge})
  end
  table.sort(arr, function(a,b) return a.year > b.year end)

  -- write back sorted refs
  local sorted = {}
  ordered_tldr = {}
  for _, t in ipairs(arr) do
    table.insert(sorted, t.ref)
    table.insert(ordered_tldr, tldr_text(t.ref))  -- may be nil
  end
  meta.references = sorted
  return meta
end

-- Append TL;DR paragraphs inside the bibliography container (#refs).
function Div(el)
  if el.identifier ~= "refs" then return nil end
  local idx = 1
  local function append_tldr_para(block, txt)
    local lbl = pandoc.Span({pandoc.Str("TL;DR:")}, {class = "tldr-label"})
    local note = pandoc.Emph(pandoc.Str(txt))
    table.insert(block.content, pandoc.Para({lbl, pandoc.Space(), note}))
  end

  for i, node in ipairs(el.content) do
    -- Each bibliography entry is usually a Div with class "csl-entry"
    if node.t == "Div" then
      local classes = node.classes or {}
      local is_entry = false
      for _, c in ipairs(classes) do
        if c == "csl-entry" then is_entry = true; break end
      end
      if is_entry then
        local txt = ordered_tldr[idx]
        if txt and #txt > 0 then
          append_tldr_para(node, txt)
          el.content[i] = node
        end
        idx = idx + 1
      end
    end
  end
  return el
end
