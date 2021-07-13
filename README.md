# Posix programs in Elm

Write your tools and build scripts in Elm.

**This is still under development**

The workflow idea:
- Write your Elm "CLI script" using an IO monad similar to Haskell, see [examples](https://github.com/albertdahlin/elm-posix/tree/master/example/src) and [package docs](https://elm-doc-preview.netlify.app/?repo=albertdahlin/elm-posix)
- install the cli tool, `npm install -g albertdahlin/elm-posix` *(not published to npm yet)*
- run `elm-cli src/YourProgram.elm`

## Work in Progress

A proof of concept is implemented and testable (on Linux).
There are still some things pending before publishing v1.0.

Requires `node` and `elm` to be installed on your system.
```
cd example
../shell/elm-cli src/HelloUser.elm
```

### Some things to fix before publishing

- Make sure it works on other OS
- Documentation and user help

IO effects to implement:
- Spawning child processes
- Executing `Cmd`, for example `Http`

CLI:
- `elm-cli build <src> <target>` - Produce an executable node js shell script.
- `elm-cli run <src> <args>` - Evaluate the src file.
