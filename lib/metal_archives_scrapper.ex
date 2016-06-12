defmodule MetalArchivesScrapper.Agente do

  def start_link do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def agregar(pid, l) do
    Agent.update(pid, fn(todas) -> todas ++ l end)
  end

  def traer_todas(pid) do
    Agent.get(pid, fn(todas) -> todas end)
  end

end

defmodule MetalArchivesScrapper.Misc do

  def generar(min, max) do
    min .. max
    |> Enum.to_list
  end

  def mezclar(l) do
    Enum.shuffle(l)
  end

  def generar_displaystart(step, maximo, acu, lista) when (acu * step) > maximo do
    lista
  end

  def generar_displaystart(step, maximo, acu, lista) do
    generar_displaystart(step, maximo, acu + 1, lista ++ [(acu * step)])
  end

  def maximo_bandas(lista_letras, agente) do
    IO.puts "Vamos con #{inspect lista_letras}"

    r = lista_letras
    |> Enum.map(&Task.async(fn -> descargar_json_maximo_letra(&1) end))
    |> Enum.map(&Task.await(&1, 20000))

    r
  end

  def maximo_bandas do

    url = armar_url(0)

    r = case HTTPoison.get(url, [timeout: 20000, recv_timeout: 20000]) do
          {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
            {:ok, json} = JSON.decode(body)
            maximo = json["iTotalRecords"]
            maximo
          {:error, %HTTPoison.Error{reason: reason}} ->
            IO.puts "ERROR #{reason}"
            :error
      end

    r
  end

  def descargar_json_maximo_letra(letra) do
    url = armar_url(letra, 0)

    r = case HTTPoison.get(url, [timeout: 20000, recv_timeout: 20000]) do
          {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
            {:ok, json} = JSON.decode(body)
            maximo = json["iTotalRecords"]
            IO.puts "OK con #{letra} = #{maximo}"
            
            [letra: letra, maximo: maximo]
          {:error, %HTTPoison.Error{reason: reason}} ->
            IO.puts "ERROR con #{letra}"
            IO.puts reason
            
            :error
        end
    r
  end

  def descarga_paralela(chunk) do
    IO.puts "Vamos con #{inspect chunk}"

    chunk
    |> Enum.map(&Task.async(fn -> descargar(&1) end))
    |> Enum.map(&Task.await(&1, 20000))
    |> Enum.reduce(fn(cl, f) ->
      f ++ cl
    end)
  end

  def descarga_paralela_por_letra([{:letra, l}, {:maximo, m}] = letra_maximo) do
    IO.puts "#{l} - #{m}"

    generar_displaystart(500, m, 0, [])
    |> Enum.chunk(10, 10, [])
    |> Enum.map(fn(ds) -> descargar_por_letra(ds, l) end)
    |> Enum.reduce(fn(cl, f) ->
        f ++ cl
    end)

  end

  def descargar_por_letra(ds, l) do
    IO.puts "#{inspect ds}"

    ds
    |> Enum.map(&Task.async(fn -> descargar(&1, l) end))
    |> Enum.map(&Task.await(&1, 20000))
    |> Enum.reduce(fn(cl, f) ->
        f ++ cl
    end)
    
  end

  def descargar(ds, l) do
    #IO.puts "#{inspect ds} #{inspect self}"

    url = armar_url(l, ds)
    #IO.puts "-> #{url}"

    r = case HTTPoison.get(url, [timeout: 20000, recv_timeout: 20000]) do
          {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
            {:ok, json} = JSON.decode(body)
            IO.puts "OK con #{l} - #{ds}"

            bandas_lista = json["aaData"]
                                                               
            final = Enum.map(bandas_lista, fn(b) -> 
              [a_href, pais, genero, span_estado] = b
                                                               
              [{"a", _, [nombre]}] = Floki.find(a_href, "a")
              [{"span", _, [estado]}] = Floki.find(span_estado, "span")
              #[nombre: nombre, genero: genero]
                                                               
              [nombre: nombre, pais: pais, genero: genero, estado: estado]
              #[nombre: nombre]
            end)

          {:error, %HTTPoison.Error{reason: reason}} ->
            IO.puts "ERROR con #{l}"
            IO.puts reason
            
            :error
        end

      r
  end

  def descargar(ds) do
    url = armar_url(ds)
    #IO.puts "-> #{url}"

    r = case HTTPoison.get(url, [timeout: 20000, recv_timeout: 20000]) do
          #{:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          {:ok, %HTTPoison.Response{body: body}} ->
            {:ok, json} = JSON.decode(body)
            IO.puts "OK con #{ds}"

            bandas_lista = json["aaData"]
                                                               
            final = Enum.map(bandas_lista, fn(b) -> 
              #[a_href, pais, genero, span_estado] = b
              [a_href, genero, pais] = b
                                                               
              [{"a", _, [nombre]}] = Floki.find(a_href, "a")
              #[{"span", _, [estado]}] = Floki.find(span_estado, "span")
              #[nombre: nombre, genero: genero]
                                                               
              #[nombre: nombre, pais: pais, genero: genero, estado: estado]
              [nombre: nombre, pais: pais, genero: genero]
            end)

          {:error, %HTTPoison.Error{reason: reason}} ->
            IO.puts "ERROR con #{ds}\n #{reason}"
            descargar(ds)
        end

    r
  end

  def armar_url(letra, ds) do
    "http://www.metal-archives.com/browse/ajax-letter/l/#{letra}/json/1?sEcho=3&iColumns=4&sColumns=&iDisplayStart=#{ds}&iDisplayLength=500&mDataProp_0=0&mDataProp_1=1&mDataProp_2=2&mDataProp_3=3&iSortCol_0=0&sSortDir_0=asc&iSortingCols=1&bSortable_0=true&bSortable_1=true&bSortable_2=true&bSortable_3=false&_=1464702878305"

  end

  def armar_url(ds) do
    "http://www.metal-archives.com/search/ajax-advanced/searching/bands/?bandName=&genre=&country=&yearCreationFrom=&yearCreationTo=&bandNotes=&status=&themes=&location=&bandLabelName=&sEcho=2&iColumns=3&sColumns=&iDisplayStart=#{ds}&iDisplayLength=200&mDataProp_0=0&mDataProp_1=1&mDataProp_2=2&_=1464914469254"
  end

end


defmodule MetalArchivesScrapper do
  use Application

  def main(args) do
    HTTPoison.start

    {:ok, agente} = MetalArchivesScrapper.Agente.start_link()
    letras = [
              "NBR",
              "a",
              "b",
              "c",
              "d",
              "e",
              "f",
              "g",
              "h",
              "i",
              "j",
              "k",
              "l",
              "m",
              "n",
              "o",
              "p",
              "q",
              "r",
              "s",
              "t",
              "u",
              "v",
              "w",
              "x",
              "y",
              "z"
    ]


    #letras = [
      #          "NBR",
      #        "q",
      #        "z"
      #]

    maximo_bandas = MetalArchivesScrapper.Misc.maximo_bandas
    IO.puts "Maximo bandas es #{maximo_bandas}"

    json = MetalArchivesScrapper.Misc.generar_displaystart(200, maximo_bandas, 0, [])
    |> Enum.chunk(50, 50, [])
    |> Enum.map(fn(c) ->
      MetalArchivesScrapper.Misc.descarga_paralela(c)
    end)
    |> Enum.reduce(fn (r, f) ->
      f ++ r
    end)

    #IO.puts "#{inspect ds_list}"

    #maximos_por_letra = letras
    #|> Enum.chunk(10, 10, [])
    #|> Enum.map(&MetalArchivesScrapper.Misc.maximo_bandas(&1, agente))
    #|> Enum.reduce(fn (r, f) ->
      #  f ++ r
      #end)

      #json = maximos_por_letra
    #|> Enum.map(fn(letra_maximo) ->
      #  MetalArchivesScrapper.Misc.descarga_paralela_por_letra(letra_maximo)
      #end)
    #|> Enum.reduce(fn(l, f) ->
      #  f ++ l
      #end)

    #|> Enum.reduce(fn (r, _) ->
      #Enum.reduce(r, fn(l, f) ->
          #f ++ l
          #IO.inspect l
          #IO.puts "**********"
          #end)
        #end)
        #
    #Enum.map(json, fn(cada) ->
      #IO.puts "#{inspect cada}"
      #IO.puts "***************"
      #end)

    #letras
    #|> Stream.chunk(10, 10, [])
    #|> Stream.with_index
    #|> Stream.each(fn (lista_letras) ->
      #  MetalArchivesScrapper.Misc.maximo_bandas(lista_letras, agente)
      #end)
      #|> Stream.run


    #IO.puts "El maximo de bandas con la letra #{letra} es #{maximo}"

    #MetalArchivesScrapper.Misc.generar_displaystart(500, maximo, 0, [])
    #|> Stream.chunk(10, 10, [])
    #|> Stream.with_index
    #|> Stream.each(fn (e) -> MetalArchivesScrapper.Misc.descargar(e, letra, agente) end)
    #|> Stream.run

    #json = MetalArchivesScrapper.Agente.traer_todas(agente)
    #|> Enum.uniq

    #IO.puts "#{length(json)}"
    #IO.puts "#{inspect json}"

    a = File.write("/tmp/metal_db.json", JSON.encode!(json))
    IO.inspect a

  end


end

#MetalArchivesScrapper.run
#MetalArchivesScrapper.run2
