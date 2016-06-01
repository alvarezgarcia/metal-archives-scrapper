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

    #json = Enum.reduce(r, fn(c, f) ->
      #  f ++ c
      #end)

      #json
    #MetalArchivesScrapper.Agente.agregar(agente, json)

    r

  end


  def descargar_json_maximo_letra(letra) do
    url = armar_url(letra, 0)

    r = case HTTPoison.get(url, [timeout: 10, recv_timeout: 10]) do
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


  def armar_url(letra, ds) do
    "http://www.metal-archives.com/browse/ajax-letter/l/#{letra}/json/1?sEcho=3&iColumns=4&sColumns=&iDisplayStart=#{ds}&iDisplayLength=500&mDataProp_0=0&mDataProp_1=1&mDataProp_2=2&mDataProp_3=3&iSortCol_0=0&sSortDir_0=asc&iSortingCols=1&bSortable_0=true&bSortable_1=true&bSortable_2=true&bSortable_3=false&_=1464702878305"


  end

  def descargar({lista, i} = l, letra, agente) do

    r = lista
    |> Enum.map(&Task.async(fn -> descargar_json(letra, &1) end))
    |> Enum.map(&Task.await(&1, 20000))
    #|> Enum.map(fn(e) -> descargar_json(letra, e) end)


    json = Enum.reduce(r, fn(c, f) ->
      f ++ c
    end)
    #|> Enum.uniq


    #Enum.map(json, fn(c) ->
      #[n, g] = c
      #g = c
      #IO.puts "GENERO #{inspect g}"
      #end)

    MetalArchivesScrapper.Agente.agregar(agente, json)

  end

  def descargar_json(letra, ds) do
    url = armar_url(letra, ds)
    #IO.puts "-> #{url}"

    r = case HTTPoison.get(url) do
          {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
            {:ok, json} = JSON.decode(body)
            bandas_lista = json["aaData"]

            final = Enum.map(bandas_lista, fn(b) -> 
              [a_href, pais, genero, span_estado] = b

              [{"a", _, [nombre]}] = Floki.find(a_href, "a")
              [{"span", _, [estado]}] = Floki.find(span_estado, "span")
              #[nombre: nombre, genero: genero]

              [nombre: nombre, pais: pais, genero: genero, estado: estado]
            end)

            IO.puts "OK con #{ds}"
            final
        _ -> 
            IO.puts "Error con #{ds}"
            :error
        end

        r
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


    maximos = letras
    |> Enum.chunk(10, 10, [])
    |> Enum.map(&MetalArchivesScrapper.Misc.maximo_bandas(&1, agente))
    |> Enum.reduce(fn (r, f) ->
      f ++ r
    end)

    maximos
    |> Enum.chunk(10, 10, [])
    |> Enum.map(fn(letras) ->
      IO.inspect letras
    end)

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
    #a = File.write("/tmp/black_metal.json", JSON.encode!(json))
    #IO.inspect a

  end


end

#MetalArchivesScrapper.run
#MetalArchivesScrapper.run2
