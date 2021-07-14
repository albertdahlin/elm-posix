# Posix programs in Elm

Write your tools and build scripts in Elm.

The Elm Architecture is nice when you are writing event driven applications and long running processes.
However, I find it a bit cumbersome when you just want to do some simple scripts and tools.

This project lets you write monadic IO programs, similar to Haskell.
If you don't know what that means, don't worry about it. Try it out or have look at the [examples] instead.

**This is still under development**

The workflow idea:
- Write your Elm "CLI script", see [examples] and [package docs](https://elm-doc-preview.netlify.app/?repo=albertdahlin/elm-posix)
- install the cli tool, `npm install -g @albertdahlin/elm-cli` *(not published to npm yet)*
- run `elm-cli run src/YourProgram.elm`

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

[examples]: https://github.com/albertdahlin/elm-posix/tree/master/example/src
