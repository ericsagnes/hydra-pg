# Sample custom nixpkgs repository for custom Hydra channels

Foreword: work in progress, use at your own risk.

This repository is an example of how to create a custom set of packages with a dedicated channel extending the official nixpkgs.

The idea is to have a base for nixpkgs based projects.


## Files

### default.nix

This is the entry point of the main package set.
The main package set consist of the main <nixpkgs> extendended with the `customPkgs` set.

The custom packages are accessible in a dedicated set or under `pkgs`.

exaple:

```
$ nix-build -A trivial
```

is equivalent to


```
$ nix-build -A customPkgs.trivial
```

Having the custom packages in a dedicated set becomes handy when dealing with Hydra.


### pkgs/default.nix

Is more or less the equivalent to the official nixpkgs `./pkgs/top-level/all-packages.nix`.

It is the place to declare all the custom packages.


### release.nix

The beast. This file is the hardest to understand, so it is better to have some basic understanding of the nix expression language and Hydra before diving in.


## Playing with this repository

clone localy and build some useless packages!

```
$ nix-build -A trivial
$ ./result/bin/trivial
```


# Play with this repo and Hydra

Hydra is fun! Building useless packages with it is even more.

First, you should set some hydra server to play with. It is a piece of cake with `nixos-unstable` and `nixops`.

TODO: add nixops hydra expressions and instructions

In hydra, create a projet then a jobset.

For projects, the only important things are to check `Enabled` and `Visible in the list of projects`.

Jobsets are little more complicated to configure, but it is not that hard:

- `State` should be `enabled`
- `Check interval` to 10 sec (for fast feedback on testing)
- `Scheduling` shares to 1
- `Inputs` are the way to override what is passed to `release.nix`, but `release.nix` is also an input we will set 2 inputs:
    - `hydra-pg` `Git Checkout` `git://github.com/ericsagnes/hydra-pg`  (release.nix in this repo)
    - `nixpkgs` `Git Checkout` `git://github.com/nixos/nixpkgs-channels.git nixos-unstable` (official nixpkgs, is is possible to change the branch name)
- Going back up, `Nix Expression` `release.nix` in `hydra-pg`

To summarize. Hydra will evaluate `release.nix` from `hydra-pg` passing the `nixpkgs` input as a function argument. (`release.nix` is a function)

The apply changes, and the jobset will evaluate and if everything work as it should a channel wild be available in the `Channels` tab of the jobset.



# TODO

- Figure how publish channel binary cache
- more comments, better comments
