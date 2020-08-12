# Errors

There are two types of errors in Onyx:

  1. Panics happening during the translation stage;
  1. Exceptions thrown in runtime.

## Panics

A panic is an unrecoverable condition happening during and unconditionally halting the translation process.

Panics may be triggered either by a compiler itself or by calling the `nx.panic()` function from the macro API.

Examples of panicking behavior include incorrect syntax and user-defined compilation conditions, e.g. a node type incompatibility. {paper-noindex spec-tip}

## Exceptions

An exception is a runtime object instance indicating an exceptional yet recoverable runtime condition.

Runtime objects are allowed to be of zero size in Onyx, therefore it is practical to declare empty structs for exception purposes. {paper-no-index spec-tip}

### `throw` {#throw}

Exceptions are said to be thrown using a `throw` statement. A `throw` statement must be followed by an expression resulting in an object instance to be thrown, i.e. the exception, optionally wrapped in parentheses.

```abnf {spec-syntax="Throwing exceptions"}
(*
  A `throw` statement throws an exception object,
  returning the control to a caller.

  ```nx
  throw x
  throw (some_call() : Restriction)
  \```

  NOTE: The parentheses must match.
*)
throw = "throw", ["(" | sp], expr, [")"]
```

### `rethrow` {#rethrow}

An exception may be re-thrown using a `rethrow` statement with syntax similar to the [`throw`](#throw) statement.

A `rethrow` statement may only re-throw caught exception variables.

A `rethrow` statement preserves the exception [stack trace](#stacktrace), while re-throwing an exception with a [`throw`](#throw) statement may reset the trace. {#throw-vs-rethrow-stacktrace-preserving}

### `try` and `catch` {#try-and-catch}

A block of code may be wrapped in a `try` statement. A `try` statement must contain at least one `catch` definition.

```abnf
try = "try", {expr}, 1*{catch}, "end"
```

An exception thrown by a `throw` statement from within a code block within a `try` statement or one of its `catch` definitions is sequentially tried to be caught by further `catch` definitions in the containing `try` statement, if any, in the order of declaration.

If a `throw` statement is not contained in a `try` statement code block or an exception is failed to be caught by any of `catch` definitions in the containing `try` statement, then the execution flow of the containing function is interrupted and the control is returned to the caller. The caller treats such a callee interruption as a `throw` statement, and the process is repeated until the exception is caught somewhere in the call stack. This process is called "stack unwinding". The exact implementation of stack unwinding is not defined.

A `catch` definition follows the same rules as a function definition with the following differences:

  * It must contain exactly one instance argument, which is an exception to be caught. The argument may also be aliased, anonymous or discarded;
  * It does not allow any function modifiers other than `nothrow`;
  * It inherits the containing scope runtime safety;
  * It does not allow sub-statements other than `forall` and `where`.

A `catch` definition would match an exception of type `E` if the definition is either having a discarded argument, having no argument type restriction at all, or having a matching variable type restriction.

```abnf
(*
  NOTE: `forall` sub-statements are only allowed
  if there is a type restriction present.

  ```nx
  # Catch all exceptions into a variable named `e`
  catch (e)
    handle(e)

  # Catch all exceptions and discard them, ensuring that
  # no other exception is thrown from the body
  nothrow catch (_) {
    # throw "Boom!" # Panic! Can not throw from a `nothrow` block
  }

  # Catch all exceptions of type `T`
  catch (e : T)
    nothrow threadsafe! do_smth_with(e)

  # Catch all exceptions matching some macro condition
  catch (e : T)
  forall T
  where \{{ cond }}
    do_smth(e)
  \```
*)
catch =
  ["nothrow"],
  "catch", "(", arg_decl, ")",
  {forall},
  [where],
  {expr}
```

A function definition, as well as a code block, are considered implicit `try` statements without requiring any `catch` defintions. In other words, `def` and blocks imply `try`. For example:

```nx {paper-noindex spec-example}
def foo
  do_stuff()
catch (e)
  handle(e)
end

# Is the same as:
def foo
  try
    do_stuff()
  catch (e)
    handle(e)
  end
end
```

```nx {paper-noindex spec-example}
final l = ~> unsafe! |(arg)| do
  do_stuff(arg)
catch (e)
  handle(e)
end

final b = -> { do_stuff() } catch (e) handle(e)
```

### Stack tracing {#stacktrace}

A compiler may choose to implement the stack tracing feature for certain targets to find out the origin of an exception.

A pointer to the stack trace object of type `Stacktrace` must be obtainable via the `stacktrace()` call if the stack tracing feature is enabled. The object and the function must conform to the virtual declarations listed below.

```nx
virtual struct Stacktrace
  # NOTE: A stack trace of size greater than 2 ^ 16 is not practical.
  virtual def size : UInt16

  # Iterate through the stack trace, where the first element
  # is the original throw location.
  virtual def each(
    range : Range<UInt16> = 0..UInt16::MAX,
    block :: B
  ) forall B : -> |(
    filepath : String*sr,
    row : UInt32,
    col : UInt32
  ) : discard|
end

virtual def stacktrace() : Stacktrace*sr
```

The stack tracing feature may be optionally disabled even for a supported target in a certain compilation context, e.g. with an implementation-defined debug switch.

The `nx.ctx.stacktrace_available` macro API represents the final state of the stack tracing feature.

If the stack tracing feature is disabled, then neither `Stacktrace` object nor `stacktrace()` function are defined.

{{ paper-cite="#throw-vs-rethrow-stacktrace-preserving" }}

### `nothrow`

A function may have a `nothrow` modifier, which prohibits throwing exceptions at any point from within the function. If a compiler finds out that a `nothrow` function may actually throw at some point, it would panic.

```nx {paper-noindex spec-example="A &#96nothrow&#96 function modifier"}
# Is an implicitly throwing function.
def bar
  throw "Boom!"
end

nothrow def foo
  # throw "Boom!" # Panic! Can not `throw` from
                  # a `nothrow` function `::foo`

  # bar() # Panic! Can not call a throwing function `::bar`
          # from within a `nothrow` function `::foo`
end
```

Any exported function is implicitly `nothrow`.

TODO: Also `nothrow` statement, e.g. `nothrow foo()`.

### `throws`

A function may have a `throws` sub-statement restricting exception types to be potentially thrown by the function. If present, the sub-statement must cover all the potentially thrown types.

```nx {paper-noindex spec-example}
def foo throws String* # That's an undefined pointer restriction
                       # covering `*sr` pointers as wll
  throw "Boom!" : String*sr
end

def bar throws String* | SInt32
  if @rand
    throw "Boom!"
  else
    throw 42
  end
end

# From the outside, the function would be treated as
# potentially throwing any `Numeric` object, e.g. a `BigNum`.
def baz throws Numeric
  if @rand
    throw 42
  else
    throw 42.5
  end
end
```
