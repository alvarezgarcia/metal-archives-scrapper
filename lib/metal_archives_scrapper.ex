defmodule MetalArchivesScrapper.Misc do

  def generar(min, max) do
    min .. max
    |> Enum.to_list
  end

  def mezclar(l) do
    Enum.shuffle(l)
  end

  def descargar(l) do
    IO.puts "Tengo 10"

    l
    |> Enum.map(&Task.async(fn -> visitar(&1) end))
    |> Enum.map(&Task.await(&1, 10000))
    #|> Enum.map(fn(e) -> visitar(e) end)
    IO.puts "Termine los 10"

  end

  def visitar(i) do
    url = "http://www.metal-archives.com/band/view/id/#{i}"
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        parsear(body)
      _ -> 
        IO.puts "Error con #{url}"
    end
  end

  def parsear(h) do
    IO.puts "#{traer_nombre(h)} - #{traer_genero(h)}"
  end

  def traer_nombre(h) do
    [{"a", [{"href", _url}], [nombre]}] = Floki.find(h, "h1.band_name a")
    nombre
  end

  def traer_genero(h) do
    dd_list = Floki.find(h, "dd")
    {"dd", [], genero} = Enum.at(dd_list, 4)
    genero
  end

end




defmodule MetalArchivesScrapper do
  def run do
    HTTPoison.start
    MetalArchivesScrapper.Misc.generar(1, 10000)
    #MetalGame.Misc.generar(1, 10)
    #|> MetalGame.Misc.mezclar
    |> Stream.chunk(10, 10, [])
    |> Stream.each(fn(e) -> MetalArchivesScrapper.Misc.descargar(e) end)
    |> Stream.run
  end
end

MetalArchivesScrapper.run
