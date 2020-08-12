## Blocks

A block of code is either:

  * a selection statement branch; or
  * a `try` statement body; or
  * a `catch` statement body; or
  * a safety statement body; or
  * a function body; or
  * a lambda body; or
  * a region of code passed as an argument to a generator function; or
  * an expression wrapped in parentheses, which is also called an *inline block*.

A block of code has its own [nested scope](#nested-scope-declarations-lifetime).

```abnf {spec-syntax="Blocks of code"}
block($separator) =
  (*
    A block of code may be a one-line expression, e.g. `bar` in
    `if foo then bar`. Sequential expression are prohibited in Onyx,
    therefore a separator would be required in that case. However,
    no separator would be required for an `else baz` statement.
  *)
  ([$separator], expr) |

  (*
    A block of code may consist of multiple expressions.
    For that, the block must either begin with a newline
    or wrapped into curly brackets. The separator
    would be optional in either cases.
  *)
  ([$separator], "{", {expr}, "}") |

  (*
    If a block body begins with a newline, then it would allow
    and require the `end` keyword iff there are no succeeding
    statements which would "squash" that `end` keyword.

    Late conditions and reverse loops are exception to this rule.

    \```
    if foo
      bar
    end # `end` is required here

    if foo
      bar
    else baz # `end` is replaced by `else`

    def foo
      bar
    end # `end` is required here

    def foo
      bar
    catch (e) # `end` is replaced by `catch`
      baz(e)
    end

    do
      foo
    end while bar # `end` is still required here
    \```
  *)
  ([$separator], nl, {expr}, "end");
```

## Lambdas

Lambdas are anonymous functions with optional closure.

```nx
final l = ~> foo()
fragile! l()

final l = ~> |[c] (a) : R| foo(c, a) : R
fragile! l.call(a)

final l = unsafe ~> foo() : Lambda<Safety: :unsafe>
final l = ~> unsafe! foo() : Lambda<Safety: :fragile>
final l = threadsafe ~> || { nothrow! fragile! foo(arg) }

final l = nothrow unsafe ~> do
  some_stuff()
catch (e)
  handle(e) # Unsafe context here
end
```

## Captured blocks

Blocks are surrogates. They can not be in runtime. They can only be passed as arguments.

```nx
def async(lambda : ~> |[C] (A) : R|)
  lambda()
end

def each(block: :: B) forall B : => |(self) : Discard|
  \{{ nx.yield(nx.lookup("B")) }}
end

# Seems natural, though.
def each(block: :: B) forall B : => |(T) : Discard|
  B(self[i])
  @yield(B, self[i])
end

list.each(block: => |element| { $puts(element) })
```

```nx
final b = fragile => |(a) : R| do foo() : R end

# Won't do `b()` or `b.call()`,
# as there is no real calling whatsoever
fragile! @invoke(b)
```

On the other side, why not? Pass them as runtime args, `call` them! Just don't allow using in any runtime way.

```nx
final a = => |(arg)| foo(arg)
final b = (=> |(arg)| bar(arg)) : Block<|unsafe (A) : R|>
```

TODO:

```nx
# OK, explicitly no closure
def get(proc : ~> |[] A : B|)

# Can only fuzzy-match,
# because can have any closure
def get(proc ~ ~> |A : B|)
```
