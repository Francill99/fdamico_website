-- filters/annote.lua
-- Append the 'annote' (if present in the .bib) as an italic paragraph under each bibliography item.

local refs_by_id = {}

function Meta(meta)
  -- Pandoc exposes bibliography entries in meta.references
  if meta.references then
    for _, r in ipairs(meta.references) do
      -- store annote by id for quick lookup
      if r.id then
        refs_by_id[r.id] = r
      end
    end
  end
end

function Div(el)
  -- In Pandoc, individual bibliography entries are Divs with identifiers like "ref-<bibkey>"
  if el.identifier and el.identifier:match("^ref%-") then
    local key = el.identifier:gsub("^ref%-", "")
    local ref = refs_by_id[key]
    if ref and ref.annote then
      -- Append a new paragraph with italic annote
      local italic = pandoc.Emph(pandoc.Str(ref.annote))
      table.insert(el.content, pandoc.Para(italic))
      return el
    end
  end
end
