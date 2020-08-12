## Statements

TODO: What is a statement exactly?

### Jump statements {#jump}

A jump statement interrupts the consecutive execution flow.

<!-- Jump statements have well-defined arity, therefore, unlike calls, even when arity of a statement is non-zero, wrapping parentheses are optional. -->

#### `return` {#return}

A `return` statement returns control from anywhere in the function body to the caller.

A `return` statement conveys a single optional argument, which is considered a return value of the function call. If absent, the argument is implicitly [`void`](#void).

A `return` statement is exclusive to [functions](#functions) and can not be used in [lambdas](#lambdas).

::: {paper-cite="#lifetime-return-move"}
<!-- Returning an argument won't require moving it  -->
:::

```ebnf {paper-spec-syntax="The &#96return&#96 statement"}
return = "return", [expr];
```

::: {paper-cite="#function-at-least-one-terminator"}
<!-- A function must have at least one termination point -->
:::

#### `convey` {#convey}

A `convey` statement is similar to the [`return` statement](#return), but it, in contrary, can only be used in [lambdas](#lambdas).

```ebnf {paper-spec-syntax="The &#96convey&#96 statement"}
convey = "convey", [expr];
```

#### `throw` {#throw}

A `throw` statement *throws* its single non-void argument as an exception, returning the control to the nearest matching `catch` sub-statement. Read more in [Exception handling](#exceptions).

```ebnf {paper-spec-syntax="The &#96throw&#96 statement"}
throw = "throw", expr;
```

#### `break` {#break}

<!-- TODO: What is "nearest"? -->

A `break` statement breaks the nearest [loop](#loops).

A `break` statement conveys a single optional argument, which is considered a return value of the broken loop. If absent, the argument is implicitly [`void`](#void).

```ebnf {paper-spec-syntax="The &#96break&#96 statement"}
break = "break", [expr];
```

#### `continue` {#continue}

A `continue` statement jumps to the next iteration of the nearest [loop](#loops).

A `continue` statement always has zero arity.

```ebnf {paper-spec-syntax="The &#96continue&#96 statement"}
continue = "continue";
```

### Selection statements {#selection}

A selection statement branch is a separate block of code having its own nested scope.

A selection statement allows to select a branch to run based on some runtime switch expression result.

In a selection statement, a switch expression is evaluated in a scope shared by all the branches; that is, a declaration made in a switch expression is available to any of the statement's branch. The rule does is not apply to [reverse loops](#reverse-loops). {#condition-scope-sharing}

```nx {spec-example paper-noindex}
if (let x = true; some_code(); x)
  make_use_of(x) # OK
else
  make_use_of(x) # Also OK
end

# make_use_of(x) # Panic! `x` is undefined
```

A compiler must downcast a local `Variant` variable if it is possible to convey information from a switch expression in a deterministic, non-runtime-dependent way.

```nx {spec-example="Downcasting a voidable variant"}
let variant : T?

if variant.void?
  variant : Void
else
  variant : T
end
```

```nx {spec-example="Downcasting a variant"}
let variant : *(T | U | V)

if !variant.is?(T)
  variant : *(U | V)
else
  variant : T
end
```

```nx {spec-example}
let variant : Variant<*(T | U | V)>

case variant
when T then assert(variant is? T)
else
  assert(variant : Variant<*(U | V)>)
end
```

```nx {spec-example="Can't downcast a variant in non-determenistic environment"}
let variant : T?

if (!variant.void? && Std.rand?)
  variant : T # There is a guarantee of that `variant` is non-void
else
  variant : T? # No any guarantees here
end
```

#### Conditional statemens {#conditionals}

A conditional statement is binary: based on its switch expression restricted to `Bool`, a.k.a. the *condition*, it runs code contained either in the mandatory block of code following the condition, a.k.a. the *success branch*; or in the optional *failure branch*.

An `if` conditional statement executes its success branch iff the condition is `true`.

An `unless` conditional statement executes its success branch iff the condition is `false`.

```ebnf {spec-syntax="Conditional statements"}
cond = "if" | "unless", expr, block("then"), ["else", block("then")];
```

A single success branch may precede the condition expression in a *late conditional statement*.

```ebnf {spec-syntax="Late conditional statements"}
(*
  NOTE: If a block in late conditional statements begins with a newline,
  then it always requires `end` (i.e. it's not "squashed").

  \```
  then
    foo
  end if bar # `end` is required here
  \```
*)
late_cond = block("then"), "if" | "unless", expr;
```

#### `case` {#case}

One of multiple `case` statement branches is selected based on the runtime value of the switch expression, which must evaluate to either an `Int`, a enum or a variant instance.

A `case` statement is exhaustive: if there is a possibility of some value to be never matched, a compiler would panic. It is possible to have an `else` branch, effectively consuming all *other* values, which satisifies the exhaustiveness requirement.

```ebnf {spec-syntax="The &#96case&#96 statement"}
case =
  "case", expr,
  {"when", expr, block("then")},
  ["else", block("then")];
```

#### `try` {#try}

A `try` statement declares a maybe-throwing block of code with multiple `catch` sub-statements.

A `try` statement accepts an optional stacktrace object pointer argument using the `with obj : mut Stacktrace*lr` notation.

A `try` block has different scope other than `catch` blocks. Therefore, a stacktrace object should not belong to the `try` scope, making `with (let obj = MyBacktrace(); &obj)` impractical.

```ebnf {spec-syntax="&#96try&#96 statement"}
catch = "catch", "(", arg_decl, ")", [forall], [where], block("do");
try = "try", ["with", expr], block("do"), {catch};
```

### Loop statements {#loops}

In a loop statement, the condition expression is evaluated prior to an iteration. If the condition succeeds, the only branch of code, called the *loop body*, is run. The process repeats until the condition fails.

A `while` statement condition is treated as successful if it evaluates to `true`. An `until` statement condition is successful on `false`.

Having a declaration within a loop condition expression is semantically valid: its lifetime is limited by a single iteration.

In a *reverse loop statement*, the condition is run *after* the iteration. Therefore, the loop body is guaranteed to run at least once in a reverse loop statement.

A loop condition expression shares its scope with the body. A reverse loop condition expresssion does not.

```ebnf {spec-syntax="Loop statements"}
loop = "while" | "until", expr, block("do");
```

```ebnf {spec-syntax="Reverse loop statements"}
(*
  Akin to conditional statements, if body begins with a newline,
  then it always requires `end` (i.e. it's not "squashed").

  \```
  # `bar` is first evaluated after the first iteration.
  # In other words, `foo` is to be run at least once.
  do
    foo
  end while bar # `end` is required here
  \```
*)
rev_loop = block("do"), "while" | "until", expr;
```

### Safety statements {#safety-statements}

Safety statements declare certain safety guarantees for the underying block of code. Read more in [Safety](#safety).

Safety statement keywords end with `!` for easies grepping through the code base.

TODO: Using `catch` in a safety statement does not apply that safety to the block.

```nx
unsafe! foo
catch (e) bar # `bar` has `fragile` context?

unsafe def foo
  do_stuff()
catch (e)
  handle(e) # Unsafe? Makes sense
end

unsafe! {
  do_stuff()
} catch (e) {
  handle(e) # ?
}
```

```ebnf {spec-syntax="Safety statements"}
safety =
  {
    "threadsafe!" |
    "fragile!" |
    "unsafe!" |
    "nothrow!"
  },
  branch("do");
```
