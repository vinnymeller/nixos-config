function ClearReg()
  print('Clearing registers')
  vim.cmd [[
    let regs=split('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789/-"', '\zs')
    for r in regs
    call setreg(r, [])
    endfor
]]
end

--Make it so i can call ClearReg as a command
vim.api.nvim_create_user_command('ClearReg', function()
  ClearReg()
end, {})
