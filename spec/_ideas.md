# Ideas

## Labels and labeled breaks

```nx
let result = main:while true
  nested:until false
    main:break 42 if something
    nested:continue
  end
end

# OR
let result = while:main true
  until:nested false
    break:main 42 if something
    continue:nested
  end
end

# OR, but `%` is taken for macro vars
let result = %main: while true
  %nested: until false
    break(%main, 42) if something
    continue(%nested)
  end
end

@:string # Literal restriction
@:bool<true>
@~text   # Allows `@:string`, `@:symbol`, `@:char`
@&foo    # In-macro variables
```

## Defering

```nx
def foo
  defer Std.out << "Done"
  bar()
  # Defer is called here
end
