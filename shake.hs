#!/usr/bin/env cabal
{- cabal:
build-depends: base, shake, shake-cabal, shake-google-closure-compiler, directory
default-language: Haskell2010
ghc-options: -Wall
-}

import           Development.Shake     
import           Development.Shake.Cabal
import           Development.Shake.ClosureCompiler
import           Development.Shake.FilePath
import           System.Directory

main :: IO ()
main = shakeArgs shakeOptions { shakeFiles = ".shake", shakeLint = Just LintBasic, shakeChange = ChangeModtimeAndDigestInput } $ do
    want [ "target/index.html" ]

    [ "dist-newstyle/build/x86_64-linux/ghcjs-8.6.0.1/{{ project }}-0.1.0.0/x/{{ project }}/build/{{ project }}/{{ project }}.jsexe/all.js", "dist-newstyle/build/x86_64-linux/ghcjs-8.6.0.1/{{ project }}-0.1.0.0/x/{{ project }}/build/{{ project }}/{{ project }}.jsexe/all.js.externs" ] &%> \_ -> do
        need . snd =<< getCabalDepsA "{{ project }}.cabal"
        command [RemEnv "GHC_PACKAGE_PATH"] "cabal" ["new-build", "--ghcjs"]

    googleClosureCompiler ["dist-newstyle/build/x86_64-linux/ghcjs-8.6.0.1/{{ project }}-0.1.0.0/x/{{ project }}/build/{{ project }}/{{ project }}.jsexe/all.js", "dist-newstyle/build/x86_64-linux/ghcjs-8.6.0.1/{{ project }}-0.1.0.0/x/{{ project }}/build/{{ project }}/{{ project }}.jsexe/all.js.externs" ] "target/all.min.js"

    "target/index.html" %> \out -> do
        liftIO $ createDirectoryIfMissing True (takeDirectory out)
        need ["target/all.min.js", "web-src/index.html"]
        copyFile' "web-src/index.html" out
