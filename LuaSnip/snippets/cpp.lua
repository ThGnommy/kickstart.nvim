local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt

return {
  s("uelog", fmt(
    "UE_LOG(LogTemp, {}, TEXT(\"{}\"));",
    { i(1, "Warning"), i(2, "Something happened") }
  )),
}

