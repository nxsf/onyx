# Onyx Standard Specification

The Standard [Onyx programming language](https://onyxlang.org) specification.

## About

This is an ongoing effort to standardize the [Onyx programming language](https://onyxlang.org).

Development of the Standard is governed by [NXSF](https://nxsf.org).

The Standard is open and free.
Anyone is welcome to contribute into the Standard, given that they follow the [contribution rules](#TODO:).

## Audience

Target audience of this specification is anyone willing to implement an Onyx language compiler.
A reader is expected to be familiar with a number of ISO standards, including the C programming language standard.

## Current state

The Standard is currently in pre-alpha stage.
It is dirty and incomplete.
Some sections may already be deprecated.

The repository is not licensed yet, so you can not do anything with the specification other than read it.
Issues and pull requests are therefore not accepted, unless you waive all copyright and patent claims in the commit message.

The commits history is likely to be rewritten prior to moving to the alpha stage.

## Development

Make sure the following executables are available:

  * [`blockdiag`](http://blockdiag.com/en/blockdiag/index.html)
  * [`bytefield-svg`](https://github.com/Deep-Symmetry/bytefield-svg)

### HTML5

Run `bundle exec ruby build-html5.rb`.
The resulting HTML5 file is available at `build/index.html`.

### PDF

Run `bundle exec ruby build-pdf.rb`.
The resulting PDF file is available at `build/index.pdf`.
