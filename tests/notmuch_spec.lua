local nm = require("galore.notmuch")
local nu = require("galore.notmuch-util")
local tu = require("galore.test_utils")
local u = require("galore.util")

describe("Testing notmuch", function ()
	local db = tu.setup()

	local messages = tu.load_messages()
	it("Add tags", function ()
		local query = nm.create_query(db, "")
		local messages = nm.query_get_messages(query)
		for message in messages do
			nu.change_tag(message, "+testtag")
		end
		-- messages = nm.query_get_messages(query)
		for message in messages do
			local tags = u.collect(nm.message_get_tags(message))
			--- check if messages contains testtag
		end
	end)
	it("Remove tags", function ()
		local query = nm.create_query(db, "")
		local messages = nm.query_get_messages(query)
		for message in messages do
			nu.change_tag(message, "-testtag")
		end
		for message in messages do
			local tags = u.collect(nm.message_get_tags(message))
			--- check if messages do not contain testtag
		end
	end)

	tu.cleanup()
end)
