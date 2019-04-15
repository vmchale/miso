#!/usr/bin/env cabal
{- cabal:
build-depends: base, shake, shake-cabal, shake-google-closure-compiler, shake-ext, directory
default-language: Haskell2010
-}

import           Control.Monad
import           Development.Shake                 hiding (getEnv)
import           Development.Shake.Cabal
import           Development.Shake.Clean
import           Development.Shake.ClosureCompiler
import           Development.Shake.FilePath
import           System.Directory
import           System.Environment                (getEnv)

main :: IO ()
main = shakeArgs shakeOptions { shakeFiles = ".shake", shakeLint = Just LintBasic, shakeChange = ChangeModtimeAndDigestInput } $ do
    want [ "target/index.html" ]

    "deploy" ~> do
        home <- liftIO $ getEnv "HOME"
        let srcFiles = [ "target/index.html", "target/all.min.js" ]
            dir = home ++ "/programming/rust/drunk/static/"
        need srcFiles
        zipWithM_ copyFile' srcFiles ((dir ++) . takeFileName <$> srcFiles)
        command [Cwd "/home/vanessa/programming/rust/drunk"] "just" ["deploy"]

    "build" %> \_ -> do
        need ["shake.hs"]
        copyFile' "shake.hs" ".shake/shake.hs"
        command_ [Cwd ".shake"] "ghc" ["-Wall", "-Werror", "-O", "shake.hs", "-o", "build", "-threaded", "-rtsopts", "-with-rtsopts=-I0 -qg -qb"]
        cmd ["cp", "-f", ".shake/build", "."]

    "size" ~> do
        need ["target/all.min.js"]
        cmd ["sn", "d", "target/all.min.js"]

    "clean" ~> do
        cleanHaskell
        removeFilesAfter "target" ["//*"]
        removeFilesAfter ".shake" ["//*"]

    [ "dist-newstyle/build/x86_64-linux/ghcjs-8.6.0.1/{{ project }}-0.1.0.0/x/{{ project }}/opt/build/{{ project }}/{{ project }}.jsexe/all.js", "dist-newstyle/build/x86_64-linux/ghcjs-8.6.0.1/{{ project }}-0.1.0.0/x/{{ project }}/opt/build/{{ project }}/{{ project }}.jsexe/all.js.externs" ] &%> \_ -> do
        need . snd =<< getCabalDepsA "{{ project }}.cabal"
        command [RemEnv "GHC_PACKAGE_PATH"] "cabal" ["new-build", "--ghcjs"]

    googleClosureCompiler ["dist-newstyle/build/x86_64-linux/ghcjs-8.6.0.1/{{ project }}-0.1.0.0/x/{{ project }}/opt/build/{{ project }}/{{ project }}.jsexe/all.js", "dist-newstyle/build/x86_64-linux/ghcjs-8.6.0.1/{{ project }}-0.1.0.0/x/{{ project }}/opt/build/{{ project }}/{{ project }}.jsexe/all.js.externs" ] "target/all.min.js"

    "target/index.html" %> \out -> do
        liftIO $ createDirectoryIfMissing True (takeDirectory out)
        need ["target/all.min.js", "web-src/index.html"]
        copyFile' "web-src/index.html" out
