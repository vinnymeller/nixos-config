---@meta
---@diagnostic disable: missing-fields

-- Editor-only type definitions for the `NIX` global that
-- features/hyprland/default.nix injects ahead of hyprland.lua (rendered as
-- `local NIX = { ... }` by the Home Manager Hyprland module via settings.NIX._var).
--
-- This file is NEVER loaded by Hyprland; it exists purely so the Lua LSP can
-- offer completion and type-checking for NIX.*. Keep these fields in sync with
-- the `settings.NIX._var` attrset in default.nix -- the values live there, this
-- only describes their shape.

---@class Nix.Colors
---@field active_border string   Hyprland color string, e.g. "rgb(fb4934)"
---@field group_active string
---@field group_inactive string

---@class Nix.Features
---@field vtt boolean

---@class Nix
---@field colors Nix.Colors
---@field features Nix.Features

---@type Nix
NIX = {}
