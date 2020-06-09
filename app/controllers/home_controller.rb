class HomeController < ApplicationController
  def index
    sum_range = params[:sum_range] || (0..10).to_a
    difference_range = params[:sum_range] || (1..10).to_a
    multiplication_range = params[:multiplication_range] || (0..10).to_a
    devider_range = params[:multiplication_range] || (1..10).to_a

    difference_collection =
      difference_range.each_with_object({}) { |x, memo| memo.merge!(x => difference_range.select { |y| x <= y }) }

    devider_collection =
      devider_range.each_with_object({}) { |x, memo| memo.merge!(x => devider_range.select { |y| x%y == 0 }) }

    potential_cells = {
      multiplication: [],
      sum: [],
      difference: [],
      devider: []
    }
    potential_cells[:multiplication] = multiplication_range.map { |x| multiplication_range.map { |y| ["#{x}x#{y}", "#{y}x#{x}"] } }.flatten.uniq
    potential_cells[:sum] = sum_range.map { |x| sum_range.map { |y| ["#{x}+#{y}", "#{y}+#{x}"]} }.flatten.uniq
    potential_cells[:difference] = difference_collection.map { |key, value| value.map { |x| "#{key}-#{x}"} }.flatten
    potential_cells[:devider] = devider_collection.map { |key, value| value.map { |x| "#{key}:#{x}"} }.flatten

    # x+y
    # x-y
    # x*y
    # x:y
    # ---
    # x+y+c
    # x-y+c
    # x*y+c
    # x:y+c
    # ---
    # x+y-c
    # x-y-c
    # x*y-c
    # x:y-c
    # ---
    # x+y*c
    # x-y*c
    # x*y*c
    # x:y*c
    # ---
    # x+y:c
    # x-y:c
    # x*y:c
    # x:y:c

    # mask = params[:mask]

    examples = potential_cells.map { |_, values| values.map { |x| x + "=" } }.flatten
    render :index, locals: { examples: examples }
  end
end
