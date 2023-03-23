import XMonad
import XMonad.Layout.BinarySpacePartition

main = xmonad def
    { terminal    = "kitty"
    , modMask     = mod4Mask
    , borderWidth = 1
    }
