{-# LANGUAGE
    TupleSections
  #-}

module Profile where

import Prelude hiding (readFile)
import Data.Text.Lazy (Text(..))
import Data.Text.Lazy.IO (readFile)
import Data.ByteString.Lazy hiding (readFile, elem)
import System.Environment (getArgs)
import System.FilePath ((<.>), (</>))
import System.Process.Typed
import System.TimeIt
import GHC.Prof

data InstanceData = InstanceData { _name :: String
                                 , _optimizationFlags :: [String]
                                 , _externalTime :: Double
                                 , _rtsMeasures :: Text
                                 , _profileText :: Maybe Profile
                                 } deriving Show


optimizations = [ [], ["-O"], ["-O2"] ]

profiling = [ ([ "-prof" ], [ "-pa" ]), ([], []) ]

generateInstances :: [String]
                  -> [IO InstanceData]
generateInstances programs = do
    programName <- programs
    let programSrc = programName ++ ".hs"
    optimizationFlags <- optimizations
    ( profCompilerFlags, profRtsFlags ) <- profiling

    let compileSpec = proc "stack" $ [ "ghc", "--"
                                     ,             programSrc
                                     , "-main-is", programName
                                     , "-o",       programName
                                     , "-rtsopts"
                                     ] ++ optimizationFlags
                                       ++ profCompilerFlags

    let runSpec = setStdin closed $ proc ("." </> programName) $
            [ "+RTS"
            , "-t" ++ programName ++ ".rts", "--machine-readable"
            ] ++ profRtsFlags

    return $ do  -- TODO: Later on, we will enter multiple directories as well.
        runProcess_ compileSpec
        (time, (out, err)) <- timeItT (readProcess_ runSpec)
        rtsMeasures <- readFile (programName <.> ".rts")
        profileText <- if "-prof" `elem` profCompilerFlags
                       then Just . either error id . decode <$> readFile (programName <.> ".prof")
                       else return Nothing
        return InstanceData { _name              = programName
                            , _optimizationFlags = optimizationFlags
                            , _externalTime      = time
                            , _rtsMeasures       = rtsMeasures
                            , _profileText       = profileText
                            }

main = do
    programs <- getArgs


    -- Deal with the facts that:
    --  * A processInstance will write some files (programName.prof}.
    --  * A processInstance will say its RTS report to a file.
    --  * I also need to know the time!

    let instances = generateInstances programs

    results <- sequence instances

    print results
