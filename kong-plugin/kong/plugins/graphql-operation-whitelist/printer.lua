
local newLineChar = "\n"
local spaceChar = " "
local emptyChar = ""

local tabsize = 2

local function indent(s, n) 
  return string.rep(spaceChar, tabsize * n) .. s 
end

local nameSelector = {
  inlineFragment = function (s) 
    return s.typeCondition.name.value 
  end,
  field = function(s) 
    return s.alias and s.alias.name.value or s.name.value 
  end,
  fragmentSpread = function(s) 
    return s.name.value
  end
}

local function sortFields(s1, s2) 
  return nameSelector[s1.kind](s1) < nameSelector[s2.kind](s2)
end

local visitors = {
  document = {
    enter = function(node, context)
      for index, definition in ipairs(node.definitions) do
        if definition.kind == 'fragmentDefinition' then
          context.fragmentMap[definition.name.value] = definition
        end
      end

      return emptyChar
    end,

    exit = function(node, context)
      return newLineChar
    end,

    children = function(node)
      return node.definitions
    end
  },

  operation = {
    enter = function(node, context)
      context.indentLevel = 0
      return indent(node.operation, context.indentLevel)
    end,

    exit = function(node, context)
      return newLineChar
    end,

    children = function(node)
      return { node.selectionSet }
    end
  },

  selectionSet = {
    enter = function(node, context)
      
      for index, selection in ipairs(node.selections) do
        -- inline the fragment spreads
        if selection.kind == 'fragmentSpread' then
          -- replace the node by the fragment 
          local fragment = context.fragmentMap[selection.name.value]
          
          for _, selection in ipairs(fragment.selectionSet.selections) do
            table.insert(node.selections, selection)
          end
        end
      end

      -- sort the selections
      table.sort(node.selections, sortFields)
      context.indentLevel = context.indentLevel + 1
      return spaceChar .. "{" .. newLineChar
    end,

    exit = function(node, context)
      context.indentLevel = context.indentLevel - 1
      return indent("}" .. newLineChar, context.indentLevel)
    end,

    children = function(node)
      return node.selections
    end
  },

  field = {
    enter = function(node, context)
      local alias = node.alias and node.alias.name.value .. ": " or ""
      local endOfLine = node.selectionSet and "" or newLineChar

      return indent(alias .. node.name.value .. endOfLine, context.indentLevel)
    end,

    children = function(node)
      if node.selectionSet then
        return {node.selectionSet}
      end
    end
  },

  inlineFragment = {
    enter = function(node, context)
      return indent("... on " .. nameSelector[node.kind](node), context.indentLevel)
    end,

    children = function(node, context)
      if node.selectionSet then
        return {node.selectionSet}
      end
    end,
  },
}

return function(tree, operationName)
  local output = ""

  local context = {
    indentLevel = 0,
    fragmentMap = {}
  }

  local function visit(node)
    local visitor = node.kind and visitors[node.kind]

    if not visitor then return end

    if node.kind == 'operation' 
      and node.name 
      and node.name.value ~= operationName then 
      return
    end

    if not visitor then return end

    if visitor.enter then
      output = output .. visitor.enter(node, context)
    end

    if visitor.children then
      local children = visitor.children(node)
      if children then
        for _, child in ipairs(children) do
          visit(child)
        end
      end
    end

    if visitor.exit then
      output = output .. visitor.exit(node, context)
    end

    return output
  end

  return visit(tree)
end
