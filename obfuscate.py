import sys

with open("auto_mine.luau", "rb") as f:
    data = f.read()

hex_data = data.hex()
rev_hex = hex_data[::-1]

code = f"""
-- Obfuscated for Indo Voice Hub
local h = "{rev_hex}"
local r = string.reverse(h)
local s = r:gsub('..', function(cc)
    return string.char(tonumber(cc, 16))
end)
local func = loadstring(s)
if func then func() else warn("Gagal meload script!") end
"""

with open("obf_auto_mine.lua", "w", encoding="utf-8") as f:
    f.write(code)
print("Obfuscation complete.")
