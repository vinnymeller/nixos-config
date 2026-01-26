require("avante_lib").load()
require("avante").setup({
	-- provider = "copilot",
	provider = "claude-code",
	acp_providers = {
		["claude-code"] = {
			command = "claude-code-acp",
		},
	},
})
