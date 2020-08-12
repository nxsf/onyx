-- This file defines the Onyx Macro API.
--
-- The following identifiers: `string`, `nil`, `boolean`, `number` and
-- `table`; represent fundamental Lua types. Additional identifiers
-- `int` and `uint` are used to represent whole numbers. Logical
-- operators may be used to express variativity of possible values.
-- Concrete literals may be used to represent exact possible values.
-- Arrays are represented using the `{ type }` notation,
-- e.g. `{ string }`.
--
-- For example, `{foo = { string } or 42 or nil}` means that the `foo`
-- entry may contain either an array of strings, exact number 42, or nil.
--
-- Sum of tables represents an extensions. For example,
-- `foo = bar + { baz = 42 }` means that the `foo` table
-- includes the contents of the `bar` table.
--
-- Special strings beginning from `@` are local to this documentation
-- and should not be implemented. Purposes of each special string are
-- documentented individually.

-- The global Onyx table accessible from any Onyx source code
-- file without any thread-safety considerations.
nx = {
  -- Access current compilation context; the contents may be
  -- sensitive to the position within a source file.
  ctx = {
    -- Access current function implementation, if any.
    impl = nx.Node.FunctionDef or nil,

    -- Access current type (which may
    -- also be the top-level namespace).
    type = nx.Node['@Type'],

    -- Access information about the source code
    -- file currently being compiled.
    file = {
      path = string
    },

    -- A function performing Onyx path lookup in accordance to
    -- the regular lookup rules, from the current context.
    lookup = function (path)
      -- Returns `nil` if lookup failed
      return nx.Node or nil
    end,
  },

  -- Access current compilation target information.
  target = {
    -- The target Instruction Set Architecture.
    -- It may contain additional fields
    -- defined in the Targets Appendix.
    isa = {
      id = string,
    },

    -- A list of deviant target Instruction Set Extensions,
    -- which may be empty. The list of possible ISEs
    -- is defined in the Targets Appendix.
    ise = { string },

    -- An exact target Processing Unit, which may be unknown.
    pu = string or nil,

    -- The target Operating System information,
    -- which may be empty. It may contain additional
    -- fields defined in the Targets Appendix.
    os = {
      id = { string },
    },

    -- A list of target Application Binary Interfaces,
    -- which may be empty. An ABI may have additional
    -- fields defined in the Targets Appendix.
    abi = { { id = string } }
  },

  -- C interoperability constraints and utilities. Note that these
  -- do not neccessarily align with the target's capatibilites.
  --
  -- The table defines some C constraints which are barely express-able
  -- by the C standard, e.g. signedness representation of integers.
  -- Additionally, this information is useful in cases when a program
  -- does not have access to target-specific _hosted_ C headers (§4.6).
  --
  -- Note that it should always be assumed that a program has access
  -- to the target-specific _freestanding_ C headers (§4.6):
  -- float.h, iso646.h, limits.h, stdalign.h, stdarg.h, stdbool.h,
  -- stddef.h, stdint.h and stdnoreturn.h.
  c = {
    -- A function performing C path lookup.
    lookup = function (path)
      -- Returns `nil` if lookup failed
      return nx.c.Node or nil
    end,

    -- Access C integer environment.
    integer = {
      -- "Sign and magnitude", two's, or one's complement.
      signedness = 'SM' or '2C' or '1C',

      -- > ... is whether the value with sign bit 1 and all value bits
      -- zero (for the first two), or with sign bit and all value bits 1
      -- (for ones’ complement), is a trap representation or a normal
      -- value. In the case of sign and magnitude and ones’ complement,
      -- if this representation is a normal value it is called a
      -- negative zero.
      --
      -- Therefore, `{signedness = 'SM', can_trap = false}` means that
      -- negative zero is supported.
      can_trap = bool
    },

    -- TODO:
    -- -- Access C floating-point environment.
    -- floating_point = {
    --   -- Is `INFINITY` supported?
    --   infinity = boolean,

    --   -- Is negative zero supported?
    --   negative_zero = boolean,

    --   -- Are NaNs supported? Note that C treats all NaNs as qNaNs.
    --   nan = boolean,
    -- },

    type = {
      float = {
        format = 'IEEE-754'
      },
      double = {
        format = 'IEEE-754'
      },
      'long double' = {
        format = 'IEEE-754' or 'X87' or 'PPC'
      },
      char = {
        signed = bool -- A char's sign is not defined by the standard
      },
      short = {
        bitsize = int
      },
      int = {
        bitsize = int
      },
      long = {
        bitsize = int
      },
      'long long' = {
        bitsize = int
      }
    },

    Node = {
      Macro = {
        id = value,
        arity = int,
        call = function (args)
          -- Return the result of macro evaluation
          return string
        end
      },
      Constant = {
        Integer = {
          -- The type may be unknown for freestanding constants
          type = nx.c.Node.Type.Int or nil,

          base = 'decimal' or 'octal' or 'hex',
          value = int,
          suffixes = {'unsigned' or ('long' or 'long long')}
        },

        Char = {
          -- The type may be unknown for freestanding constants
          type = nx.c.Node.Type.Int or nil,

          value = string,

          -- TODO: > (byte) If c-char is not representable as a single
          -- byte in the execution character set, the value is
          -- implementation-defined.
          -- TODO: > (16bit, 32bit, wide) If c-char is not
          -- or maps to more than one 16-bit character, the behavior is
          -- implementation-defined.
          -- TODO: > (multichar) has [...] implementation-defined value
          kind = 'byte' or -- E.g. `'a'` or `'\n'` or `'\13'`
            'utf8' or      -- E.g. `u8'a'`
            '16bit' or     -- E.g. `u'貓'`, but not `u'🍌'`
            '32bit' or     -- E.g. `U'貓'`, but not `U'🍌'`
            'wide' or      -- E.g. `L'β'` or `L'貓'`
            'multichar'    -- E.g. `'AB'`
        },

        Floating = {
          -- The type may be unknown for freestanding constants
          type = nx.c.Node.Type.Int or nil,

          base = 'decimal' or 'hex',

          significand = {
            whole = int,
            fraction = uint
          },

          exponent = int or nil,
          suffix = 'f' or 'l' or nil
        },

        String = {
          -- The type may be unknown for freestanding constants,
          -- e.g. `char* = "foo"` has type, but `"foo"` does not.
          type = nx.c.Node.Type.Pointer or nx.c.Node.Type.Array or nil,

          value = string,

          -- TODO: > (byte) If c-char is not representable as a single
          -- byte in the execution character set, the value is
          -- implementation-defined.
          -- TODO: > (16bit, 32bit, wide) If c-char is not
          -- or maps to more than one 16-bit character, the behavior is
          -- implementation-defined.
          -- TODO: > (multichar) has [...] implementation-defined value
          kind = 'byte' or -- E.g. `'a'` or `'\n'` or `'\13'`
            'utf8' or      -- E.g. `u8'a'`
            '16bit' or     -- E.g. `u'貓'`, but not `u'🍌'`
            '32bit' or     -- E.g. `U'貓'`, but not `U'🍌'`
            'wide' or      -- E.g. `L'β'` or `L'貓'`
            'multichar'    -- E.g. `'AB'`
        }
      },
      Type = {
        Int = {
          kind = 'short' or 'int' or 'long' or 'long long',
          signed = boolean,
          atomic = boolean,
          constant = boolean,
          volatile = boolean,
          alignment = int or nil
        },
        Float = {
          kind = 'float' or 'double' or 'long double',
          complex = boolean,
          imaginary = boolean,
          atomic = boolean,
          alignment = int or nil
        },
        Pointer = {
          to = nx.c.Node.Type,
          alignment = int
        },
        Reference = {
          to = nx.c.Node.Type,
          alignment = int
        },
        Struct = {

        },
        Enum = {

        },
        Union = {

        },
        Function = {

        },
      },
      TypeDef = {
        id = string,
        target = nx.c.Node.Type or nil
      },
      FunctionDecl = {

      }
    }
  },

  Node = {
    -- Represent any referencable type.
    ['@Type'] = nx.Node.Namespace or
      nx.Node.Trait or
      nx.Node.Struct or
      nx.Node.Enum or
      nx.Node.Primitive or
      nx.Node.TypeAlias

    -- Represent a declaration.
    ['@Decl'] = nx.Node['@Type'] or
      nx.Node.FunctionDecl or
      nx.Node.FunctionDef or
      nx.Node.VarDecl or
      nx.Node.AnnotationDef or
      nx.Node.MacroDef

    -- A namespace node. Any other type declaration
    -- is also considered a name space.
    Namespace = {
      name = string, -- E.g. `'Bar'` for `::Foo::Bar`

      -- Would be nil for the top-level namespace.
      parent = nx.Node['@Type'] or nil,

      declarations = { nx.Node['@Decl'] },

      -- Return a fully qualified path to the namespace in form of
      -- an array of strings, e.g. `{'Foo', 'Bar'}` for `::Foo::Bar`.
      path = function ()
        return {string}
      end
    },

    -- A trait node
    Trait = nx.Node.Namespace + {
      annotations = { nx.Node.AnnotationCall },

      -- A trait may derive from other traits
      derivees = {
        [1] = {
          trait = nx.Node.TypeRef,
          declarations = { nx.Node['@Decl'] }
        }
      }
    },

    -- A struct node derives from the Trait node
    Struct = nx.Node.Trait,

    -- A enum node, which may also be a flag
    Enum = nx.Node.Namespace + {
      is_flag = true or false,

      -- The enum type, which is `$int` by default
      type = nx.Node.TypeRef,

      elements = { nx.Node.Enum.Element },
      annotations = { nx.Node.TypeRef  },

      -- A enum element
      Element = {
        name = string,
        value = nx.Node.Literal or nil
      }
    },

    Primitive = nx.Node.Namespace,

    FunctionDecl = {
      parent = nx.Node['@Type'],

      visibility = 'public' or 'protected' or 'private' or nil,
      storage = 'static' or 'instance' or nil,
      safety = 'threadsafe' or 'fragile' or 'unsafe' or nil,
      mutability = 'mut' or 'const' or nil,

      name = string,
      arguments = { nx.Node.ArgDecl },

      annotations = { nx.Node.AnnotationCall }
    },

    FunctionDef = {
      parent = nx.Node['@Type'],

      proto = nx.Node.FunctionDecl, -- A prototype per specialization
      body = { nx.Node.Expr },

      annotations = { nx.Node.AnnotationCall }
    },

    VarDecl = {
      parent = nx.Node['@Type'],

      -- Would be nil if undefined
      is_static = true or false or nil,

      -- Would be nil if undefined
      visibility = 'public' or 'protected' or 'private' or nil,

      -- Always defined
      is_final = true or false,

      -- Would be false for `set foo`, always defined
      has_getter = true or false,

      -- Would be false for `get foo` or `final foo`, always defined
      has_setter = true or false,

      name = 'MyVar',
      type = nx.Node.TypeRef or nil,
      annotations = { nx.Node.AnnotationCall }
    },

    -- An annotation definition node
    AnnotationDef = {
      parent = nx.Node['@Type'],
      name = string,

      -- An annotation consists of macro code (may be empty)
      macros = { nx.Node.Macro },

      -- Resolve a full path to the annotation
      path = function,

      -- Annotations may be annotated themselves!
      annotations = { nx.Node.AnnotationCall }
    },

    -- A macro definition node
    MacroDef = {
      parent = nx.Node['@Type'],
      is_builtin = boolean,
      visibility = 'public' or 'protected' or 'private' or nil,
      name = string,
      arguments = { nx.Node.ArgDecl },
      body = { nx.Node.Macro }
    }

    -- An annotation call (i.e. the act of annotating) node
    AnnotationCall = {
      annotation = nx.Node.AnnotationDef,
      arguments = { nx.Node.ArgCall }
    },

    TypeAlias = {
      parent = nx.Node['@Type'],

      name = string,
      arguments = { nx.Node.ArgDecl },

      target_type = nx.Node['@Type'],
      target_arguments = { nx.Node.ArgCall }
    },

    TypeRef = {
      type = nx.Node['@Type'],
      arguments = { nx.Node.ArgCall }
    },

    ArgDecl = {
      name = string or nil,
      alias = string or nil,
      is_static = boolean,
      type = nx.Node.TypeRef or nil,
      annotations = { nx.Node.AnnotationCall },
      has_default_value = boolean
    },

    ArgCall = {
      parent = { nx.Node.TypeRef or nx.Node.FunctionCall },

      -- A link to the target argument declaration, if resolved
      declaration = nx.Node.ArgDecl or nil,

      -- How the argument is referenced.
      -- Would be a number for `[0]:` reference,
      -- a string for named reference,
      -- and nil for a simple sequence
      ref = number or string or nil,

      value = nx.Node.Expr
    }
  }
}
