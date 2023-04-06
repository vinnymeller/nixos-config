return {
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "j-hui/fidget.nvim", -- LSP status updates
            "williamboman/mason.nvim",
            "simrat39/rust-tools.nvim",
        },
        config = function()
            -- LSP settings.
            --  This function gets run when an LSP connects to a particular buffer.
            local on_attach = function(_, bufnr)
                -- NOTE: Remember that lua is a real programming language, and as such it is possible
                -- to define small helper and utility functions so you don't have to repeat yourself
                -- many times.
                --
                -- In this case, we create a function that lets us more easily define mappings specific
                -- for LSP related items. It sets the mode, buffer and description for us each time.
                local nmap = function(keys, func, desc)
                    if desc then
                        desc = "LSP: " .. desc
                    end

                    vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
                end

                nmap("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
                nmap("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")

                nmap("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
                nmap("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
                nmap("gI", vim.lsp.buf.implementation, "[G]oto [I]mplementation")
                nmap("<leader>D", vim.lsp.buf.type_definition, "Type [D]efinition")
                nmap("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
                nmap("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")

                -- See `:help K` for why this keymap
                nmap("K", vim.lsp.buf.hover, "Hover Documentation")
                nmap("<C-k>", vim.lsp.buf.signature_help, "Signature Documentation")

                -- Lesser used LSP functionality
                nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
                nmap("<leader>wa", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
                nmap("<leader>wr", vim.lsp.buf.remove_workspace_folder, "[W]orkspace [R]emove Folder")
                nmap("<leader>wl", function()
                    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
                end, "[W]orkspace [L]ist Folders")

                -- Create a command `:Format` local to the LSP buffer
                vim.api.nvim_buf_create_user_command(bufnr, "Format", function(_)
                    if vim.lsp.buf.format then
                        vim.lsp.buf.format()
                    elseif vim.lsp.buf.formatting then
                        vim.lsp.buf.formatting()
                    end
                end, { desc = "Format current buffer with LSP" })
            end

            -- nvim-cmp supports additional completion capabilities
            local capabilities = vim.lsp.protocol.make_client_capabilities()
            capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

            require("mason").setup()

            local rt = require("rust-tools")
            rt.setup({
                server = {
                    -- setup rust specific lsp keymaps
                    on_attach = function(_, bufnr)
                        on_attach(_, bufnr)
                        vim.keymap.set("n", "<leader>ha", rt.hover_actions.hover_actions, { buffer = bufnr })
                        vim.keymap.set("n", "<leader>cg", rt.code_action_group.code_action_group, { buffer = bufnr })
                        vim.keymap.set("n", "<leader>me", rt.expand_macro.expand_macro, { buffer = bufnr })
                        vim.keymap.set("n", "<leader>oc", rt.open_cargo_toml.open_cargo_toml, { buffer = bufnr })
                    end,
                    capabilities = capabilities,
                },
            })

            require("lspconfig").yamlls.setup({
                capabilities = capabilities,
                on_attach = on_attach,
                settings = {
                    yaml = {
                        schemas = {
                            ["https://json.schemastore.org/github-workflow.json"] = ".github/workflows/*",
                            ["https://json.schemastore.org/swagger-2.0.json"] = "swagger*.yaml",
                        },
                    },
                },
            })


            require("lspconfig").lua_ls.setup({
                on_attach = on_attach,
                capabilities = capabilities,
                settings = {
                    Lua = {
                        runtime = {
                            -- Tell the language server which version of Lua you're using (most likely LuaJIT)
                            version = "LuaJIT",
                        },
                        diagnostics = {
                            globals = { "vim" },
                        },
                        workspace = {
                            library = vim.api.nvim_get_runtime_file("", true)
                        },
                        -- Do not send telemetry data containing a randomized but unique identifier
                        telemetry = { enable = false },
                    },
                },
            })

            require("lspconfig").pylsp.setup({
                on_attach = on_attach,
                capabilities = capabilities,
                settings = {
                    pylsp = {
                        plugins = {
                            pycodestyle = {
                                ignore = { "W391", "E501" },
                            },
                        },
                    },
                },
            })

            require("lspconfig").hls.setup({
                on_attach = on_attach,
                capabilities = capabilities,
            })

            require("lspconfig").clangd.setup({
                on_attach = on_attach,
                capabilities = capabilities,
            })

            -- Turn on lsp status information
            require("fidget").setup()
                    end,
    }
}