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

  def maximo_bandas_por_letra(letra) do
    9670
  end

  def armar_url(letra, ds) do
    "http://www.metal-archives.com/browse/ajax-letter/l/#{letra}/json/1?sEcho=3&iColumns=4&sColumns=&iDisplayStart=#{ds}&iDisplayLength=500&mDataProp_0=0&mDataProp_1=1&mDataProp_2=2&mDataProp_3=3&iSortCol_0=0&sSortDir_0=asc&iSortingCols=1&bSortable_0=true&bSortable_1=true&bSortable_2=true&bSortable_3=false&_=1464702878305"

  end

  def descargar(lista, letra) do

    lista
    |> Enum.map(&Task.async(fn -> descargar_json(letra, &1) end))
    |> Enum.map(&Task.await(&1, 10000))
    #|> Enum.map(fn(e) -> descargar_json(letra, e) end)

  end

  def descargar_json(letra, ds) do
    url = armar_url(letra, ds)
    #IO.puts "-> #{url}"

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        #IO.inspect(body)
        IO.puts "OK con #{ds}"
      _ -> 
        IO.puts "Error con #{ds}"
        #IO.inspect aaa
      end
  end

  #def descargar(l) do
    #  IO.puts "Tengo 10"
    #
    #l
    #|> Enum.map(&Task.async(fn -> visitar(&1) end))
    #|> Enum.map(&Task.await(&1, 10000))
    ##|> Enum.map(fn(e) -> visitar(e) end)
    #IO.puts "Termine los 10"
    #
    #end

    #def visitar(i) do
      #url = "http://www.metal-archives.com/band/view/id/#{i}"
      #case HTTPoison.get(url) do
 #{:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
   #       parsear(body)
   #   _ -> 
   #     IO.puts "Error con #{url}"
   # end
   #end

   #def parsear(h) do
     # IO.puts "#{traer_nombre(h)} - #{traer_genero(h)}"
     #end

     #def traer_nombre(h) do
       #[{"a", [{"href", _url}], [nombre]}] = Floki.find(h, "h1.band_name a")
       #nombre
       #end

       #def traer_genero(h) do
         #dd_list = Floki.find(h, "dd")
         #{"dd", [], genero} = Enum.at(dd_list, 4)
         #genero
         #end

end




defmodule MetalArchivesScrapper do
  use Application

  def main(args) do
    HTTPoison.start

    letra = "A"
    maximo = MetalArchivesScrapper.Misc.maximo_bandas_por_letra(letra)

    MetalArchivesScrapper.Misc.generar_displaystart(500, maximo, 0, [])
    |> Stream.chunk(10, 10, [])
    |> Stream.each(fn (e) -> MetalArchivesScrapper.Misc.descargar(e, letra) end)
    |> Stream.run

  end

end

#MetalArchivesScrapper.run
#MetalArchivesScrapper.run2
