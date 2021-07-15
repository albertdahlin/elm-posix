# Posix programs in Elm

Write your tools and build scripts in Elm.

The Elm Architecture is nice when you are writing event driven applications and long running processes.
However, I find it a bit cumbersome when you just want to do some simple scripts and tools.

This project lets you write monadic IO programs, similar to Haskell, and then compile them to a nodejs shell script.

For example
```
elm-cli make src/MyScript.elm my-script
```
will create an executable shell script that you can run with `./my-script`.

**This is still under development and will most likely change**

## Installation / Setup

You need `elm`, `node` and `npm` on your system.

Install the cli tool:
```
npm install -g @albertdahlin/elm-posix
```

Install Elm dependencies in your project
```
elm install albertdahlin/elm-posix
elm install elm/json
```

## Usage

- See [examples] for how to build and run cli programs.
- Read the package [documentation]

You can also run `elm-cli` without any arguments to get usage info.

## Work in Progress

A proof of concept is implemented and testable (on Linux).
There are still some things pending before publishing v1.0.

### Some things to fix before publishing

- Make sure it works on other OS
- Documentation and user help

IO effects to implement:
- Spawning child processes
- Executing `Cmd`, for example `Http`

[examples]: https://github.com/albertdahlin/elm-posix/tree/master/example
[documentation]: https://package.elm-lang.org/packages/albertdahlin/elm-posix/latest/
