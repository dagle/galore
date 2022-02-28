local galore = require("galore.gmime.gmime_ffi")

local function init()
	galore.g_mime_init()
	galore.g_mime_filter_reply_module_init()
end

-- include_files()

return {
	init = init,
	content = require("galore.gmime.content"),
	convert = require("galore.gmime.convert"),
	crypt = require("galore.gmime.crypt"),
	extra = require("galore.gmime.extra"),
	filter = require("galore.gmime.filter"),
	funcs = require("galore.gmime.funcs"),
	ffi = galore,
	option = require("galore.gmime.option"),
	parts = require("galore.gmime.parts"),
	stream = require("galore.gmime.stream"),
	util = require("galore.gmime.util"),
}
