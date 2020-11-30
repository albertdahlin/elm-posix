# Posix programs in Elm

**This is still under development**

The idea:
- [x] Write your Elm "CLI script" using an IO monad similar to Haskell, see [examples](/example/src/) and [package docs](https://elm-doc-preview.netlify.app/?repo=albertdahlin/elm-posix)
- [ ] install the cli tool, `npm install -g albertdahlin/elm-posix`
- [ ] run `elm-cli src/YourProgram.elm`

## WIP

A proof of concept is implemented and testable. There are still some IO to be added.

Requires `node` and `elm`.
```
cd example
../shell/elm-cli src/HelloUser.elm
```
