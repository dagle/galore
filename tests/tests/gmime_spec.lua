local tu = require("galore.test_utils")
local gu = require("galore.gmime.util")
local gp = require("galore.gmime.parts")
local u = require("galore.util")

local function make_traverse_message()
end

describe("Gmime tests", function ()
	it("message_foreach", function ()
	end)
	it("message_foreach_dfs", function ()
	end)
	it("part_iter", function ()
	end)
	it("split and reconstuct", function ()
		local message
		gp.message_get_mime_part(message)
	end)
	it("set and get warning callback", function ()
	end)
	it("Normalize a list address", function ()
		local addr =  "Testie McTest via test-dev-public <test-dev-public@lists.test.org>"
		local from = gu.preview_addr(addr, 30)
		assert.is.True(vim.fn.strchars(from) > 30)
	end)
	it("Normalize a normal addr", function ()
		local addr =  "Testie McTest <test@test.org>"
		local from = gu.preview_addr(addr, 30)
		assert.equal(vim.fn.strchars(from), 30)
	end)

	it("Generate and nonmalize", function ()
		local addr = "" -- generate random emails
		local from = gu.preview_addr(addr, 30)
		assert.is.True(vim.fn.strchars(from) >= 30)
	end)

	it("Get a ref from a message", function ()
	end)
	it("Make a ref from a message", function ()
	end)
end)
