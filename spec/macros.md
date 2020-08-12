## Macros {#spec--macros}

A macro is a code embedded into source files to be evaluated during the [compilation](#spec--compilation){paper-link} stage.

Macros are written in the [Lua language](https://lua.org), version 5.3.

Macros are evaluated as soon as they are read in a source file, unless it is a [delayed macro](#spec--macros--delayed-macros){paper-link}.

If a macro is evaluated into an incomplete expression, then all the source code after it is considered being wrapped into an [emitting macro](#spec--macros--emitting-macros){paper-link}, until the expression is complete.{#spec--macros--incomplete-expression}

```nx
# A compiled program would output `Hello!\n` three times
{% for i = 0, 3 do %}
  @cout << "Hello!\n"
{% end %}

# The same result
{% for i = 0, 3 do %}
  {{ '@cout << "Hello!\\n"' }}
{% end %}
```

A source file containg an [incomplete macro expression](#spec--macros--incomplete-expression){paper-link} at the end of processing is considered errornous.

### Code emission {#spec--macros--code-emission}

A macro is able to emit Onyx source code, which is compiled once the macro expression is complete.

A code is emitted virtually, without actually changing the file contents.

An emitted source code may contain macros as well.

#### Non-emitting macros {#spec--macros--non-emitting-macros}

A non-emitting macro evaluation does not alter the source code unless the [`nx.emit`](#spec--macros--api--onyxemit){paper-link} function is explicitly called.

```abnf {paper-spec-syntax="Non-emitting macros"}
non_emitting_macro = "{%", (? Lua code ?), "%}";
```

```nx
{% puts "Hello, world!" %} # Outputs during the compilation process,
                           # but does not alter the source code

require "std/io"

# Would output `"Hello, world!` in runtime
{%
  nx.emit('@cout << "Hello,')
  nx.emit(' world!"')
%}
```

#### Emitting macros {#spec--macros--emitting-macros}

An emitting macro evaluation treats its final evaluation result as an Onyx source code to be emitted in addition to explicit [`nx.emit`](#spec--macros--api--onyxemit){paper-link} calls.

Wrapping an incomplete expression into an emitting macro would result in a error, as there is no [`:nxdump()`](#spec--macros--api--nxdump){paper-link} method defined for it.

```abnf {paper-spec-syntax="Emitting macros"}
emitting_macro = "{{", (? Lua code ?), "}}";
```

```nx
{{ "let x = 42" }}
# Similar to:
{% nx.emit("let x = 42") %}
```

### Delayed macros {#spec--macros--delayed-macros}

A macro evaluation may be delayed by prepending a single `\` to its opening bracket(s):

```abnf {paper-spec-syntax="Delayed macros"}
non_emitting_delayed_macro = "\{%", (? Lua code ?), "%}";
delayed_emitting_macro = "\{{", (? Lua code ?), "}}";
```

A delayed macro is evaluated on some context-dependent event. It would be a error to have a delayed macro which is never evaluated.

A delayed macro may be put *(1)* to be evaluated *(2)*:

  * *(1)* in a function body *(2)* on each containing function specialization;
  * *(1)* in a generic object declaration *(2)* on each containing object specialization;
  * *(1)* in a `where` statement *(2)* on each `where` call;
  * *(1)* in an annotation body *(2)* on each containing annotation call;
  * *(1)* in an intrinsic definition *(2)* on each intrinsic call.

### Intrinsics

```nx
# Literal restrictions
@:string # Any string literal
(@:string("foo") || @:string("bar")) # Expression
@:string("foo", "bar") # Ditto
@:sym
@:char
@:bool(true)
@:num, @:int, @:uint, @:float
@:array # Array (`[1, 2]`)
@:array<num>
@:array<string("foo" || "bar")>
@:vector # Vector (`<1, 2>`)
@:block # Block
@:struct<[0]: string>

@~text(x) # Allows `@:str(x)`, `@:sym(x)`, `@:char(x)`

@&foo       # In-macro variables, unique per invocation

# Lua
@:number # Any number
@:int, @:uint # Integer
@:float # Floating point (`1` is also valid)
```

### API {#spec--macros-api}

The macro API is well-defined to allow interoperation between the macro world and the Onyx compilation context.

#### `nx`

The `nx` global table contains the current Onyx compilation context and is required implicitly before any macro evaluation.

```lua
nx = {
  -- A table containing the current source file data
  source = {
    -- This table is shared among all macro evaluations
    -- in the same file, including the delayed ones
    module = {}
  },

  -- A function to lookup for an object with semantics
  -- similar to Onyx, e.g. `nx.lookup('T')`
  lookup = function (path) end,

  -- Virtually emit the contents into the source code
  emit = function (value) end,

  -- Panic with a *message*, optionally pointing to the *node*
  panic = function (message, node) end,

  -- A table containing current target information
  target = {
    -- The target Instruction Set Architecture
    isa = 'id',

    -- An array of target Instruction Set Extensions
    ise = {
      [0] = 'id'
    },

    -- The target Processing Unit
    pu = 'id',

    -- The target Operating System
    os = {
      id = 'id',
      ver = Dotver
    },

    -- An array of target Application
    -- Binary Interface conventions
    abi = {
      [0] = {
        id = 'id',
        ver = Dotver
      }
    }
  }
}
```

##### `nx.source.module`

The `nx.source.module` table allows to share data between macro evaluations (including delayed) in the same source file, but not between macros in different files.

```nx
{%
  nx.source.module.sum = function (a, b)
    return a + b
  end
%}

def compile_time_sum(a : A, b : B) forall A : %num, B : %num
  return \{{ nx.source.module.sum(
    nx.lookup("A").value,
    nx.lookup("B").value) }}
end
```

#### `Onyx.Node`

The `Onyx.Node` class represents an Onyx AST node.

```lua
Onyx.Node = {
  is_primitive = true,
  is_struct = true,
  is_type = true,
  is_enum = true,
  is_flag = true,
  is_trait = true,
  functions = {},
  variables = {}
}
```

##### `nx.lookup`

The `nx.lookup(path)` function looks up for an Onyx entity by its *path* following the same rules as in Onyx, returning `nil` if the entity is not found.

```nx
{%
  assert(
    nx.lookup("SInt32") ==
    nx.lookup("::SInt32") ==
    nx.lookup("Int<Bitsize: 32, Signed: true>"))

  assert(nx.lookup("SInt32").is_primitive)
%}

macro foo;
annotation Bar;

struct Baz
  def qux();
end

{%
  assert(nx.lookup("@foo"))
  assert(nx.lookup("Bar"))
  assert(nx.lookup("Baz:qux"))
%}

{%
  assert(not nx.lookup("DoesNotExist"))
%}
```

##### `nx.emit` {#spec--macros--api--onyxemit}

The `nx.emit(content)` function pushes *content* into the macro emission buffer, which is then output as a raw Onyx source code in the FIFO order once the current macro expression is complete. See [code emission](#spec--macros--code-emission)).

If an `nx.emit()` function call argument is not a `string`, then it implicitly calls [`:nxdump()`](#spec--macros--api--nxdump){paper-link} on the argument before pushing it into the buffer.

##### `nxdump` {#spec--macros--api--nxdump}

The standard defines `:nxdump()` method for fundamental scalar Lua types with the following API.

```lua
assert(nil:nxdump() == "void")

assert(42.0:nxdump() == "42") -- Whole numbers don't have fraction dumped
assert(42.5:nxdump() == "42.5")

assert(true:nxdump() == "true")
assert(false:nxdump() == "false")

assert("foo":nxdump() == "foo")
assert('"foo"':nxdump() == '"foo"')
```

##### `nx.panic`

The `nx.panic(message = nil, node = nil)` function halts the compilation, optionally outputting the *message* and pointing to the *node*.

The exact format of panicking output is not defined.

Unlike the built-in `error` Lua function, `nx.panic` should not expose a Lua call stack.

##### `nx.target`

The `nx.target` table has a well-defined structure containing the current target information.

#### `Dotver`

The `Dotver` Lua class holds an instance of a dot version conforming to the [DotVer](#TODO:) specification.

```lua
local dv = Dotver:parse('~> 1.0.5')

assert(dv.op == '~>')
assert(dv.major == dv[1] == 1)
assert(dv.minor == dv[2] == 0)
assert(dv.patch == dv[3] == 5)
assert(dv[4] == nil)

assert(Dotver:parse('1.0.0') < dv)
assert(not Dotver:parse('1.0.0').conforms(dv))
assert(Dotver:parse('1.0.9').conforms(dv))
assert(not Dotver:parse('1.1').conforms(dv))
```
