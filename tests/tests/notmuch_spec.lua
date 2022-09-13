local nm = require("galore.notmuch")
local nu = require("galore.notmuch-util")
local tu = require("galore.test_utils")
local runtime = require("galore.runtime")

describe("Testing notmuch", function ()
	local testname = "test01"
	tu.setup(testname)

	it("Add tags", function ()
		runtime.with_db_writer(function (db)
			local query = nm.create_query(db, "tag:inbox")
			for message in nm.query_get_messages(query) do
				local id = nm.message_get_id(message)
				nu.change_tag(db, id, "+testtag")
			end
			assert.equal(true, true)
		end)
	end)

	it("Read tags", function ()
		runtime.with_db(function (db)
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
		end)
	end)

	it("Remove tags", function ()
		runtime.with_db_writer(function (db)
			local query = nm.create_query(db, "tag:inbox")
			for message in nm.query_get_messages(query) do
				local id = nm.message_get_id(message)
				nu.change_tag(db, id, "-testtag")
			end
			query = nm.create_query(db, "tag:inbox")
			for message in nm.query_get_messages(query) do
				local includes = false
				for tag in nm.message_get_tags(message) do
					if tag == "testtag" then
						includes = true
					end
				end
				assert.is_not_equal(true, includes)
			end
		end)
	end)

	it("Get message", function ()
		runtime.with_db_writer(function (db)
			-- local query = nm.create_query(db, "tag:inbox")
			-- local message = nm.query_get_messages(query)()
		end)
	end)

	it("Never nil tags", function ()
	end)

	tu.cleanup(testname)
end)
