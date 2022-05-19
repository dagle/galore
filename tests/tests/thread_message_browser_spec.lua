local tmb = require("galore.thread_message_browser")

describe("Test the logic in the tmb", function ()
	local threads = {
		{start=1, stop=3, expand=true, messages={1,2,3}},
		{start=4, stop=7, expand=false, messages={1,2,3}},
		{start=8, stop=8, expand=false, messages={1}},
		{start=9, stop=9, expand=true, messages={1}},
		{start=10, stop=14, expand=true, messages={1,2,3,4}},
	}
	it("realline boundry", function ()
	end)

	it("virtualline boundry", function ()
		
	end)
	it("toggle virtual", function ()
		local line = 8
		local virt = tmb.to_virtualline(threads, line)
		local real = tmb.to_realline(threads, virt)
		assert.equal(real, line)
	end)
end)
