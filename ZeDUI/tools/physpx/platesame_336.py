"""platesame.py over the 336 px faces and their narrow faces: the game's Lua must draw each exactly as the preview does."""
import sys
import plates_336 as P336        # noqa: F401  (lays the new designs over the registry)
import platesame as PS

if __name__ == "__main__":
    ids = sys.argv[1:] or [p for pid in P336.MAIN for p in (pid, pid + "_n")]
    sys.exit(1 if PS.main(ids) else 0)
