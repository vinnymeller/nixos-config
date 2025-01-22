require("snacks").setup({
    dashboard = {
        preset = {
            keys = {
                { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
                { icon = " ", key = "e", desc = "New File", action = ":ene | startinsert" },
                { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
                { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
                {
                    icon = " ",
                    key = "c",
                    desc = "Config",
                    action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
                },
                { icon = " ", key = "s", desc = "Restore Session", section = "session" },
                { icon = "󰒲 ", key = "L", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy ~= nil },
                { icon = " ", key = "q", desc = "Quit", action = ":qa" },
            },
        },
        sections = {
            { section = "header" },
            { section = "keys", gap = 1, padding = 1 },
            {
                icon = " ",
                title = "Projects",
                section = "projects",
                indent = 2,
                padding = 1,
                action = function(path)
                    local tmux = vim.fn.getenv("TMUX")
                    if tmux == nil then
                        vim.print("Must be in a tmux session to open project")
                        return
                    end
                    local twm_name = vim.system({ "twm", "-d", "-N", "-p", path }, { text = true })
                        :wait().stdout
                        :sub(1, -2)
                    vim.system({ "tmux", "switch-client", "-t", twm_name }):wait()
                end,
            },
            -- {
            --     section = "terminal",
            --     cmd = "chafa /home/vinny/.nixdots/files/nvappa.jpg --format symbols --symbols vhalf --size 60x20 --stretch; sleep .1",
            --     height = 20,
            --     padding = 1,
            -- },
            {
                pane = 2,
                icon = " ",
                desc = "Browse Repo",
                padding = 1,
                key = "b",
                action = function()
                    Snacks.gitbrowse()
                    -- gitbrowse isnt working for some reason, so use fugitive instead
                    -- vim.cmd("GBrowse")
                end,
            },
            function()
                local in_git = Snacks.git.get_root() ~= nil
                local cmds = {
                    {
                        title = "Notifications",
                        cmd = "gh notify -s -a -n5",
                        action = function()
                            vim.ui.open("https://github.com/notifications")
                        end,
                        key = "n",
                        icon = " ",
                        height = 5,
                        enabled = true,
                    },
                    {
                        title = "Open Issues",
                        cmd = "gh issue list -L 3",
                        key = "i",
                        action = function()
                            vim.fn.jobstart("gh issue list --web", { detach = true })
                        end,
                        icon = " ",
                        height = 7,
                    },
                    {
                        icon = " ",
                        title = "Open PRs",
                        cmd = "gh pr list -L 3",
                        key = "p",
                        action = function()
                            vim.fn.jobstart("gh pr list --web", { detach = true })
                        end,
                        height = 7,
                    },
                    {
                        icon = " ",
                        title = "Git Status",
                        cmd = "git --no-pager diff --stat -B -M -C",
                        height = 10,
                    },
                }
                return vim.tbl_map(function(cmd)
                    return vim.tbl_extend("force", {
                        pane = 2,
                        section = "terminal",
                        enabled = in_git,
                        padding = 1,
                        ttl = 5 * 60,
                        indent = 3,
                    }, cmd)
                end, cmds)
            end,
        },
    },
})
