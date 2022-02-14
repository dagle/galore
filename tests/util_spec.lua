local u = require("galore.util")
describe("Galore basic utils", function ()
	it("reverse a list", function ()
		local list = {1,2,3,4,5,6}
		local list2 = u.reverse(u.reverse(list))
		assert.are.same(list, list2)
	end)
	it("set stringlength", function ()
		local str = u.string_setlength("", 20)
		assert.equal(vim.fn.strchars(str), 20)

		local str = u.string_setlength("åöaoue", 20)
		assert.equal(vim.fn.strchars(str), 20)
		
		local str = u.string_setlength("åoaueuoeeoouaaoeuaoeuoeaaeua", 20)
		assert.equal(vim.fn.strchars(str), 20)
	end)
	it("contains finds values", function ()
		local list = {1, 2, 3, 4, 5}
		assert(u.contains(list, 2))
	end)
	it("Add prefix", function ()
		local str = "blåhaj"
		local newstr = u.add_prefix(str, "re:")
		assert.equal(newstr, "re: blåhaj")
	end)
	it("Existing prefix", function ()
		local str = "re: seal!"
		local newstr = u.add_prefix(str, "re:")
		assert.equal(newstr, str)
	end)
	it("collect", function ()
		local list = {1, 2, 3, 4}
		assert.are.same(list, u.collect(pairs(list)))
	end)
	it("use default path", function ()
		local path = "apa/bepa"
		assert.is_not.equal(u.save_path(path, "auaeuo/"), path)
	end)
	it("override path", function ()
		local path = "/apa/bepa"
		assert.equal(u.save_path(path, "auaeuo/"), path)
	end)
end)

