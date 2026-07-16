$bytes = [System.IO.File]::ReadAllBytes("f:\tempat script\auto_mine_source.luau")
$hex = [System.BitConverter]::ToString($bytes) -replace "-"
$charArray = $hex.ToCharArray()
[Array]::Reverse($charArray)
$rev_hex = -join $charArray
$code = @"
local h = "$rev_hex"
local r = string.reverse(h)
local s = r:gsub('..', function(cc) return string.char(tonumber(cc, 16)) end)
local f = loadstring(s)
if f then f() end
"@
[System.IO.File]::WriteAllText("f:\tempat script\auto_mine.luau", $code)
