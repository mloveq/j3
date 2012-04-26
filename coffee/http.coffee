do (j3) ->
  if j3.isRunInServer() then return

  # the XMLHttpRequest factory
  if window.XMLHttpRequest
    __getXHR = -> new XMLHttpRequest
  else
    __getXHR = -> new ActiveXObject 'MSXML2.XmlHttp'


  __serializeToFormUrlencoded = (data, buffer) ->
    if not data then return

    firstItem = yes
    for name of data
      if data.hasOwnProperty name
        if not firstItem
          buffer.append '&'
        else
          firstItem = no

        buffer.append encodeURIComponent name
        buffer.append '='
        buffer.append encodeURIComponent data[name]

  # serialize the body to be send
  __serializeBody = (buffer, data, dataType) ->
    switch dataType
      when 'text'
        buffer.append data
      when 'json'
        j3.toJson data, buffer
      else
        __serializeToFormUrlencoded data, buffer
    return

  __parseResponse = (xhr) ->
    contentType = xhr.getResponseHeader('Content-Type')
    if !contentType then contentType = ''

    if contentType.indexOf 'application/json' == 0
      return j3.fromJson xhr.responseText

    xhr.responseText

  # process the request
  __doRequest = (req) ->
    xhr = __getXHR()
    url = req.url
    async = req.async isnt false
    headers = req.headers

    xhr.open req.method, req.url, async, req.username, req.password

    # set headers
    xhr.setRequestHeader 'Content-Type', 'application/x-www-form-urlencoded'
    if headers
      for name of headers
        if headers.hasOwnProperty name
          xhr.setRequestHeader name, headers[name]

    # set async callback
    if async
      xhr.onreadystatechange = ->
        if xhr.readyState isnt 4 then return

        req.callback && req.callback.call req.context, xhr, __parseResponse xhr

    if req.method is 'GET' or not req.data
      xhr.send ''
    else
      # set request body
      buffer = new j3.StringBuilder
      __serializeBody buffer, req.data
      
      # now send the request
      xhr.send buffer.toString()
    xhr

  # generate http functions
  for method in ['GET', 'POST', 'PUT', 'DELETE']
    j3[method.toLowerCase()] = do (method) ->
      # option
      # url, context, callback
      # url, data, context, callback
      # url, data, dataType, context, callback
      ->
        url = arguments[0]
        if j3.isObject url
          options = url
        else
          options = {}

          if arguments.length == 3
            context = arguments[1]
            callback = arguments[2]
            data = null
            dataType = null
          else if arguments.length == 4
            data = arguments[1]
            context = arguments[2]
            callback = arguments[3]
            dataType = 'form'

          options.method = method
          options.data = data
          options.dataType = dataType
          options.url = url
          options.callback = callback
          options.context = context

        __doRequest options