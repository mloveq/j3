do (j3) ->
  j3.compileSelector = (selector) ->
    if j3.isFunction selector then return selector

    if j3.isString selector
      return (source) ->
        j3.getVal source, selector

    if j3.isArray selector
      return (source) ->
        result = {}
        for name in selector
          result[name] = j3.getVal source, name
        result

    if j3.isObject selector
      return (source) ->
        result = {}
        for name, value of selector
          result[name] = j3.getVal source, value
        result

  j3.compileEquals = (equals) ->
    if j3.isFunction equals then return equals

    if j3.isString equals
      return (obj1, obj2) ->
        j3.equals j3.getVal(obj1, equals), j3.getVal(obj2, equals)

    if j3.isArray equals
      return (obj1, obj2) ->
        for name in equals
          if not j3.equals j3.getVal(obj1, name), j3.getVal(obj2, name) then return false
        true

  j3.compileSortBy = (sortBy) ->
    if j3.isFunction sortBy then return sortBy

    if j3.isString sortBy then sortBy = [sortBy]

    sortRules = []
    for eachSortBy in sortBy
      sortInfo = eachSortBy.split ' '

      sortRule =
        name : sortInfo[0]

      if sortInfo.length > 1
        for info in sortInfo.slice 1
          if info is 'desc'
            sortRule.desc = true
          else if info is 'nullGreat'
            sortRule.nullGreat = true

      sortRules.push sortRule
    
    return (obj1, obj2) ->
      res = 0
      for eachRule in sortRules
        res = j3.compare obj1[eachRule.name], obj2[eachRule.name], eachRule.nullGreat
        if eachRule.desc then res *= -1
        
        if res isnt 0 then return res
      0


  _compiledGroupBy = {}

  j3.compileGroupBy = (groupBy) ->
    if j3.isFunction groupBy then return groupBy

    if j3.isString groupBy
      compiledGroupBy = _compiledGroupBy[groupBy]
      if compiledGroupBy then return compiledGroupBy
      
      _compiledGroupBy[groupBy] = compiledGroupBy = (obj) ->
        j3.getVal obj, groupBy

      return compiledGroupBy

