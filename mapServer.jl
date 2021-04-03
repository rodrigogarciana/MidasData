HTTP.listen("127.0.0.1", 8081) do http
    @show http.message
    @show HTTP.header(http, "Content-Type")
    while !eof(http)
        println("body data: ", String(readavailable(http)))
    end
    #HTTP.setstatus(http, 404)
    #HTTP.setheader(http, "Foo-Header" => "bar")
    startwrite(http)
    write(http, read("midasmap/map.html"))
end
