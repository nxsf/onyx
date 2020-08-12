# TODOs

Member is function or variable declaration.

Special types:

* `Return`, e.g. `blk = => |: Return| return 42`. Well, isn't it `NoReturn` really? I mean, it does not return from the block.
* `NoReturn`, e.g. a function which always throws
* `Discard : _`
* `Void`
* `Undef`
* `Label`, e.g. `%blk`

TODO: Remove `convey` keyword, as it's only to be used w/in lambdas? And it's almost always clear that you're within a lambda?

## Pipe op

```nx
# Use `|=>` instead? E.g. `T() |=> |t| t.foo`
T() |> &.bar |> |t| x = t * 2
t1 = T()
t2 = t1.bar
(x = t2 * 2)

T() <|> &.bar |> x = & * 2
t1 = T()
t2 = t1.bar
(x = t1 * 2)

T() <|> &.bar
t1 = T()
t2 = t1.bar
(t1)
```

`self` expands to full self with args, `self<>` to just the type, `self<x>` to concrete specialization.

`a..bar..baz` for chaining, as in Dart.
