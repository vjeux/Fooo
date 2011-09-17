-------------------------------------------------------------------
-- Table library

local tab = table
foreach = tab.foreach
foreachi = tab.foreachi
getn = tab.getn
tinsert = tab.insert
tremove = tab.remove
sort = tab.sort

-------------------------------------------------------------------
-- math library

local math = math
abs = math.abs
acos = function (x) return math.deg(math.acos(x)) end
asin = function (x) return math.deg(math.asin(x)) end
atan = function (x) return math.deg(math.atan(x)) end
atan2 = function (x,y) return math.deg(math.atan2(x,y)) end
ceil = math.ceil
cos = function (x) return math.cos(math.rad(x)) end
deg = math.deg
exp = math.exp
floor = math.floor
frexp = math.frexp
ldexp = math.ldexp
log = math.log
log10 = math.log10
max = math.max
min = math.min
mod = math.mod
PI = math.pi
--??? pow = math.pow
rad = math.rad
random = math.random
randomseed = math.randomseed
sin = function (x) return math.sin(math.rad(x)) end
sqrt = math.sqrt
tan = function (x) return math.tan(math.rad(x)) end

-------------------------------------------------------------------
-- string library

local str = string
strbyte = str.byte
strchar = str.char
strfind = str.find
format = str.format
gsub = str.gsub
strlen = str.len
strlower = str.lower
strrep = str.rep
strsub = str.sub
strupper = str.upper

function trim(s) return (string.gsub(s, "^%s*(.-)%s*$", "%1")) end
string.trim = trim;

--------------------------------------------------------------------
-- debug

function print_r(t, name, indent)
	local tableList = {}
	function table_r (t, name, indent, full)
		local serial = string.len(full) == 0 and name
				or type(name) ~= "number" and '["'..tostring(name)..'"]' or '['..name..']'
		local txt = indent..serial..' = ';
		if type(t) == "table" then
			if tableList[t] ~= nil then
				print(txt..'{}; -- '..tableList[t]..' (self reference)')
			else
				tableList[t]=full..serial
				if next(t) then -- Table not empty
					print(txt..'{');
					for key, value in pairs(t) do
						table_r(value, key, indent..'   ', full..serial);
					end 
					print(indent..'};');
				else
					print(txt..'{};');
				end
			end
		elseif type(t) == "boolean" then
			if t == true then
				print(txt.."true;");
			else
				print(txt.."false;");
			end
		elseif type(t) == "number" then
			print(txt..tostring(t)..";");
		else
			print(txt..'"'..tostring(t)..'"'..';');
		end
	end
	table_r(t, name or '__', indent or '', '');
end
