local nm = require("galore.notmuch")
local nu = require("galore.notmuch-util")
local tu = require("galore.test_utils")
local u = require("galore.util")

describe("Testing notmuch", function ()
	local testname = "test01"
	local db = tu.setup(testname)

	it("Add tags", function ()
		local query = nm.create_query(db, "tag:inbox")
		local messages = u.collect(nm.query_get_messages(query))
		nu.change_tag(db, messages, "+testtag")
		nm.query_destroy(query)
	end)
	it("Read tags", function ()
		local query = nm.create_query(db, "tag:inbox")
		local messages = nm.query_get_messages(query)
		for message in messages do
			local includes = false
			for tag in nm.message_get_tags(message) do
				if tag == "testtag" then
					includes = true
				end
			end
			assert.equals(true, includes)
		end
		nm.query_destroy(query)
	end)
	it("Remove tags", function ()
		local query = nm.create_query(db, "tag:inbox")
		local messages = u.collect(nm.query_get_messages(query))
		nu.change_tag(db, messages, "+testtag")
		for _, message in ipairs(messages) do
			local includes = false
			for tag in nm.message_get_tags(message) do
				if tag == "testtag" then
					includes = true
				end
			end
			assert.is_not_equal(true, includes)
		end
		nm.query_destroy(query)
	end)

	tu.cleanup(testname)
end)
