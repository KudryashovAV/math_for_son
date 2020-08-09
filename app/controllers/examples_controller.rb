class ExamplesController < ApplicationController
  def index
    masks = { 1 => "a+b", 2 => "a+b-c", 3 => "a*b-c", 4 => "a+b-c+d", 5 => "a+b-c*d" }

    render :index, locals: { examples: [], masks: masks } and return unless params[:generate]

    @sum_range = (0..params[:sum_range].to_i).to_a
    @difference_range = (0..params[:difference_range].to_i).to_a
    @multiplication_range = (0..params[:multiplication_range].to_i).to_a
    @divider_range = (1..params[:divider_range].to_i).to_a

    difference_collection =
      @difference_range.each_with_object({}) { |x, memo| memo.merge!(x => @difference_range.select { |y| x <= y }) }

    devider_collection =
      @divider_range.each_with_object({}) { |x, memo| memo.merge!(x => @divider_range.select { |y| x%y == 0 }) }

    potential_cells = {
      multiplication: [],
      sum: [],
      difference: [],
      devider: []
    }

    potential_cells[:multiplication] = @multiplication_range.map { |x| @multiplication_range.map { |y| ["#{x}*#{y}", "#{y}*#{x}"] } }.flatten.uniq
    potential_cells[:sum] = @sum_range.map { |x| @sum_range.map { |y| ["#{x}+#{y}", "#{y}+#{x}"]} }.flatten.uniq
    potential_cells[:difference] = difference_collection.map { |key, value| value.map { |x| "#{key}-#{x}"} }.flatten
    potential_cells[:devider] = devider_collection.map { |key, value| value.map { |x| "#{key}/#{x}"} }.flatten

    require_masks_ids = params[:masks].flatten.map(&:to_i).reject { |mask| mask == 0 }

    require_masks = masks.slice(*require_masks_ids)

    results = potential_cells_results(potential_cells)

    examples = require_masks.values.each_with_object([]) do |mask, memo|
      if mask.size == 3
        memo << results.values.flatten
      else
        @math_type = mask.size
        memo << increase_difficult_for_sums(results).flatten
      end

      memo
    end

    sums = examples.flatten.select { |x| eval(x) < params[:max_result].to_i }.map { |x| x + "=" }.sample(150)
    sums.map { |x| x.gsub!("*", "x") }
    sums.map { |x| x.gsub!("/", ":") }

    render :index, locals: { examples: sums, masks: masks }
  end

  private

  def increase_difficult_for_sums(collection)
    signs = { "+" => @sum_range, "-" => @difference_range, "*" => @multiplication_range, ":" => @divider_range }
    math_collection =
      if @math_type == 5
        collection.values
      else
        signs.each_with_object([]) { |sign, memo| memo << add_sign_to_sums(sign.first, collection.values, sign.last) }
      end
    signs.each_with_object([]) { |sign, memo| memo << add_sign_to_sums(sign.first, math_collection, sign.last) }
  end

  def add_sign_to_sums(sign, sums, digital_series)
    correct_sums = sums.flatten.select { |x| eval(x).in?(digital_series) }
    result = digital_series.map do |digital|
      correct_sums.map do |sum|
        sum + sign + digital.to_s
      end
    end.flatten
    condition_digital = sign == ":" ? 1 : 0

    math_result = []

    while math_result.size < 150
      return math_result if result.empty?

      new_result = result.shuffle.shift(150)
      math_result += new_result.select { |x| eval(x) >= condition_digital }
    end

    math_result
  end

  def potential_cells_results(collection)
    collection.each_with_object({}) do |sums, memo|
      memo[sums.first] = sums.last.select { |x| eval(x) != 0 }
    end
  end
end
