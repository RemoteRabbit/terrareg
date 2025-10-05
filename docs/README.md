# terrareg Documentation

This directory contains the documentation for the terrareg Neovim plugin.

## Documentation Structure

- `generated/` - Auto-generated API documentation from source code comments
- Developer documentation and guides (to be added)

## API Documentation

The API documentation is automatically generated from the source code using [LDoc](https://stevedonovan.github.io/ldoc/).

To generate documentation locally:

```bash
# Install ldoc
luarocks install ldoc

# Generate docs
ldoc -d docs/generated -t "terrareg Documentation" .
```

## Online Documentation

The latest documentation is automatically deployed to GitHub Pages at:
https://remoterabbit.github.io/terrareg/

## Writing Documentation

When adding new functions or modules, please include proper documentation comments:

```lua
--- Brief description of the function
-- Longer description if needed
-- @tparam string param1 Description of parameter
-- @tparam number param2 Description of parameter
-- @treturn boolean Description of return value
-- @usage require('terrareg').function_name("example")
function M.function_name(param1, param2)
  -- implementation
end
```

### Documentation Tags

- `@module` - Module name
- `@tparam type name` - Typed parameter
- `@treturn type` - Typed return value
- `@usage` - Usage example
- `@see` - Reference to other functions/modules
- `@author` - Author information
- `@license` - License information
