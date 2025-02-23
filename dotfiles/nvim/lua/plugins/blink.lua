require("blink.compat").setup({})
require("blink.cmp").setup({
    fuzzy = {
        prebuilt_binaries = {
            download = false,
        },
    },
    keymap = {
        ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-e>"] = { "cancel", "fallback" },

        ["<Tab>"] = {
            function(cmp)
                if vim.snippet.active() then
                    return cmp.accept()
                else
                    return cmp.select_and_accept()
                end
            end,
            "snippet_forward",
            "fallback",
        },
        ["<S-Tab>"] = { "snippet_backward", "fallback" },

        ["<Up>"] = { "select_prev", "fallback" },
        ["<Down>"] = { "select_next", "fallback" },
        ["<C-p>"] = { "select_prev", "fallback" },
        ["<C-n>"] = { "select_next", "fallback" },
        ["<C-y>"] = { "select_and_accept" },

        ["<C-d>"] = { "scroll_documentation_up", "fallback" },
        ["<C-f>"] = { "scroll_documentation_down", "fallback" },
    },
    signature = {
        enabled = true,
    },
    completion = {
        accept = {
            auto_brackets = {
                enabled = true,
            },
        },
        documentation = {
            auto_show = true,
            auto_show_delay_ms = 50,
        },
        trigger = {
            show_in_snippet = true,
        },
        menu = {
            draw = {
                align_to = "label",
                padding = 1,
                gap = 1,
                columns = {
                    { "label", "label_description", gap = 1 },
                    { "kind_icon" },
                },
                components = {
                    kind_icon = {
                        ellipsis = false,
                        text = function(ctx)
                            return ctx.kind_icon .. " "
                        end,
                        highlight = function(ctx)
                            return "BlinkCmpKind" .. ctx.kind
                        end,
                    },

                    kind = {
                        ellipsis = false,
                        text = function(ctx)
                            return ctx.kind .. " "
                        end,
                        highlight = function(ctx)
                            return "BlinkCmpKind" .. ctx.kind
                        end,
                    },

                    label = {
                        width = { fill = true, max = 60 },
                        text = function(ctx)
                            return ctx.label .. (ctx.label_detail or "")
                        end,
                        highlight = function(ctx)
                            -- label and label details
                            local highlights = {
                                {
                                    0,
                                    #ctx.label,
                                    group = ctx.deprecated and "BlinkCmpLabelDeprecated" or "BlinkCmpLabel",
                                },
                            }
                            if ctx.label_detail then
                                table.insert(
                                    highlights,
                                    { #ctx.label, #ctx.label + #ctx.label_detail, group = "BlinkCmpLabelDetail" }
                                )
                            end

                            -- characters matched on the label by the fuzzy matcher
                            if ctx.label_matched_indices ~= nil then
                                for _, idx in ipairs(ctx.label_matched_indices) do
                                    table.insert(highlights, { idx, idx + 1, group = "BlinkCmpLabelMatch" })
                                end
                            end

                            return highlights
                        end,
                    },

                    label_description = {
                        width = { max = 30 },
                        text = function(ctx)
                            return ctx.label_description or ""
                        end,
                        highlight = "BlinkCmpLabelDescription",
                    },
                },
            },
        },
    },
    cmdline = {
        sources = function()
            local type = vim.fn.getcmdtype()
            if type == "/" or type == "?" then
                return { "buffer" }
            end
            if type == ":" or type == "@" then
                return { "cmdline" }
            end
            return {}
        end,
    },
    sources = {
        default = {
            "lsp",
            "path",
            "codecompanion",
            "snippets",
            "buffer",
            "dadbod",
        },
        providers = {
            dadbod = {
                name = "Dadbod",
                module = "vim_dadbod_completion.blink",
            },
            cmdline = {
                enabled = function()
                    -- this is broken on wsl for some reason so idk
                    return os.getenv("WSL_DISTRO_NAME") == nil
                end,
            },
        },
    },
})
