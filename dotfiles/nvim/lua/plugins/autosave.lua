local filters = require("autosave.filters")
require("autosave").setup({
	filters = {
		filters.writeable,
		filters.not_empty,
		filters.modified,
		filters.modifiable,
		filters.filetype("sql"), -- don't autosave sql because 90% of the time in in dadbod
	},
})
