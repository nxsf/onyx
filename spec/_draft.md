Any call requires parens. Accessing instance and static variables prohibits parens.

```nx
trait Movable {
  decl get_position() : Position
  decl set_position(position : Position)
}

struct Unit {
  let position : Position

  derive Movable {
    impl get_position() { return position }
    impl set_position(this.position);
  }
}

struct ComplexUnit {
  derive Movable {
    impl get_position() {
      some_logic()
    }

    # It's okay to leave some things unimplemented.
    # Absence would only trigger when it is required
  }
}

impl ComplexUnit:set_position(position) {
  some_logic(position)
}

re impl ComplexUnit:set_position(position) {
  another_logic(position)
}
```

Use curly brackets syntax like in C++.

```nx
struct Foo {
  def bar() {
    if foo
      bar()
    else {
      baz()
    }

    case x
    when a foo()
    when b {
      bar()
    } else
      baz()

    while foo bar()

    while foo {
      bar()
    }

    bar() if foo
    { bar() } if foo
    bar() while foo
    { bar() } while foo

    {
      bar()
      t()
    } : T

    1 * (2 + 3) == 1 * { 2 + 3 }
  }
}
```

`->` is refcall by default if there is a left operand. Either wrap in brackets or parens to emphasize that it's a block:

```nx
ptr->foo()
each() -> { &.foo() }
each(-> &.foo)
```

Calls to types can be shortcut if passed as arguments.

```nx
IPv4() == IPv4::() == IPv4.()
IPv4::zero() == IPv4.zero()
ipv4.foo() == IPv4:foo(&ipv4) == IPv4.foo(&ipv4)

server.bind(IPv4(arg)) == server.bind(.(arg))
server.bind(IPv4.zero()) == server.bind(.zero())
```

Single expr in parens is just an expr. If it has commas (even trailing), it's a tuple.

```nx
let e = (x)
let t = (x,)
let t = (x, y)
let t = (x: y)
```

Re-s.

```nx
# Destructively reopen a struct.
re struct Foo {
  re def bar();
}

# Better wrap in a refinement.
refinement MyPatch {
  # Can omit entity types.
  re Foo {
    re baz()
  }
}

using refinement MyPatch
```

Incomplete structs.

```nx
incompl struct Point {
  let x : FBin64

  def length() {
    # Allowed
    return x + y + z
  }

  # Also allowed.
  impl initialize(this.x, this.y, this.z);
}

# Point(1, 2, 3) # Panic! Can not use an incomplete object in runtime

# Still incomplete.
re incompl struct Point {
  let y : FBin64
}

# Now it's complete.
re struct Point {
  let z : FBin64
}

Point(1, 2, 3) # OK
```

Can not declare functions ending with `=`, e.g. `x=`; but can declare binops ending with `=`, e.g. `+=` and `[]=`.

```nx
T*ua8+<MyEnum> # Tagged pointer!
```

<!-- Variable reassignments move-return the previous value. Other custom declared type ending with `=` MAY return the previous value.

```nx
struct Foo {
  let bar : Bar := Bar(42)
}

final foo := Foo()
final old_bar := foo.bar = Bar(43)

final old := list[x] = 42
```

Use `:=` to define a variable. Use `=` to re-assign to it. -->
