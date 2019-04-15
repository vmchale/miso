{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}

module Main ( main ) where

data Action = NoOp

data St = St

main :: IO ()
main = startApp App {..}
  where 
    initialAction = NoOp
    model = St
    update = updateModel
    view = viewModel
    events = defaultEvents
    subs = mempty
    mountPoint = Nothing

updateModel :: Action -> St -> Effect Action St
updateModel _ m = noEff m

viewModel :: St -> View Action
viewModel _ = text "Hello, World!" 
