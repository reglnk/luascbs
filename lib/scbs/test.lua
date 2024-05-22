local s = require "serialize"
local u = {
	"hello", "world",
	foo = 78,
	bar = 95,
	spam = {
		"somestring",
		3.1415926535897932
	},
	[{12}] = 78
}

print(s.to_lua(u))
