## Restriction

In case of generic restrictions, arguments are checked sequentially, beginning from the upper most level.

```nx
# First, `T` is compared, then `U`, then `V`, then `W`
T<U<V>, W> : T<U<V>, W>
```

Type expressions are evaluated in restrictions. Variants and unions have special treatment, because they are really any of their inner types at a single moment. *Schredinger types*.

Type expressions may include literals, e.g. `Pointer<Storage: :caller | :local>` or `Int<8 | 16>`. Wildcard is allowed to allow any value. If omitted, a value is considered wildcarded.

Expressions can be flattened down to a list of comma-separated concrete types using the `*E` syntax, e.g. `Variant<*(Fruit | Berry)> : Variant<*Plant>`. It can be used in unions, variants, tuples. Note that in case of tuples, having a new type added to the flattening result changes the tuple type completely.

```nx
incompl struct Plant;
incompl struct Berry { derive Plant; }
incompl struct Fruit { derive Plant; }
struct Apple { derive Fruit; }
struct Orange { derive Fruit; }
struct Strawberry { derive Berry; }
struct Watermelon { derive Berry; }

Variant<Apple, Orange> : Plant # Well, it is always a plant.
Variant<*(Fruit | Berry)> : Plant

def eat(ary : Array<Plant>);

eat([Apple()] : Array<Apple>)
eat([Apple(), Orange()] : Array<Variant<Apple, Orange>>)

# # Would not match, because `Variant<Apple, Chair> !is Plant`
# eat([Apple(), Chair()] : Array<Variant<Apple, Chair>>) # Panic!
```

`:` is equivalent to `is`; `!:` is `!is`; `as` is always unsafe casting. Can use runtime `to` and `as` for safe casting, if defined; e.g. `int32.as(SInt64)` or `int32.to(FBin16)` or `int32.as!(SInt16)`.

Restricting local variants and unions downcasts them to exact type, for example:

```nx
v : Variant<*(T | U)>

assert(!(v :? T)) # It may be not T, only U

if v.is?(T)
  v : T # It's exactly T now
  # v.is? # May be not defined for `T`
else
  v : U # It's exactly U now
end
```

```nx
v : Variant<*(T & U)>
assert(v : T : U) # It's always both T and U
```
