defmodule Identicon do
  def main(str) do
    str
    |> create_image
    |> pick_color
    |> build_grid
    |> filter_odd_squares
    |> build_pixel_map
    |> draw_image
    |> save_image(str)
  end

  defp create_image(str) do
    # hex is list of numbers from bytes
    hex = :crypto.hash(:md5, str) |> :binary.bin_to_list
    %Identicon.Image{hex: hex}
  end

  defp pick_color(image) do
    %Identicon.Image{hex: [r, g, b | _tail]} = image
    %Identicon.Image{image | color: {r, g, b}}
  end

  defp build_grid(%Identicon.Image{hex: hex} = image) do
    grid = hex
    |> Enum.chunk_every(3, 3, :discard)
    |> Enum.map(&mirror_row/1) # fn ref
    |> List.flatten
    |> Enum.with_index
    
    %Identicon.Image{image | grid: grid}
  end

  defp mirror_row(row) do
    [a, b | _tail] = row
    row ++ [b, a]
  end
  
  defp filter_odd_squares(%Identicon.Image{grid: grid} = image) do
    even_grid = Enum.filter grid, fn({code, _index}) ->
      rem(code, 2) == 0
    end

    %Identicon.Image{image | grid: even_grid}
  end
  
  defp build_pixel_map(%Identicon.Image{grid: grid} = image) do
    pixel_map = Enum.map grid, fn({_code, index}) ->
      horizontal = rem(index, 5) * 50
      vertical = div(index, 5) * 50
      top_left = {horizontal, vertical}
      bottom_right = {horizontal + 50, vertical + 50}
      {top_left, bottom_right}
    end
    
    %Identicon.Image{image | pixel_map: pixel_map}
  end
  
  defp draw_image(%Identicon.Image{color: color, pixel_map: pixel_map}) do
    # egd modifies the image with each operation
    image = :egd.create(250, 250)

    # background color
    gray_fill = :egd.color({200, 200, 200})
    :egd.filledRectangle(image, {0, 0}, {250, 250}, gray_fill)

    # foreground color
    fill = :egd.color(color)

    Enum.each pixel_map, fn({start, stop}) ->
      :egd.filledRectangle(image, start, stop, fill)
    end

    :egd.render(image)
  end
  
  defp save_image(image, filename) do
    File.write("#{filename}.jpg", image)
  end
end
