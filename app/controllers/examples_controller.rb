class ExamplesController < ApplicationController
  def index
    masks = { 1 => "a+b", 2 => "a+b-c", 3 => "a*b-c", 4 => "a+b-c+d", 5 => "a+b-c*d" }

    render :index, locals: { examples: [], masks: masks } and return unless params[:generate]

    %i(divider_range multiplication_range difference_range sum_range).each do |range|
      value = params[range].blank? ? [] : (0..params[range].to_i).to_a
      instance_variable_set("@#{range}", value)
    end

    difference_collection =
      @difference_range.each_with_object({}) { |x, memo| memo.merge!(x => @difference_range.select { |y| x <= y }) }

    devider_collection =
      @divider_range.each_with_object({}) { |x, memo| memo.merge!(x => @divider_range[1..-1].select { |y| x%y == 0 }) }

    potential_cells = {
      multiplication: [],
      sum: [],
      difference: [],
      devider: []
    }

    potential_cells[:multiplication] = @multiplication_range.map { |x| @multiplication_range.map { |y| ["#{x}*#{y}", "#{y}*#{x}"] } }.flatten.uniq
    potential_cells[:sum] = @sum_range.map { |x| @sum_range.map { |y| ["#{x}+#{y}", "#{y}+#{x}"]} }.flatten.uniq
    potential_cells[:difference] = difference_collection.map { |key, value| value.map { |x| "#{x}-#{key}"} }.flatten
    potential_cells[:devider] = devider_collection.map { |key, value| value.map { |x| "#{key}/#{x.to_f}"} }.flatten

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

    sums = examples.flatten.select { |x| eval(x) >= 0 && eval(x) < params[:max_result].to_i }.map { |x| x + "=" }.sample(150)
    sums.map { |x| x.gsub!("*", "x") }
    sums.map { |x| x.gsub!("/", ":") }
    sums.map { |x| x.gsub!(".0", "") }

    render :index, locals: { examples: sums, masks: masks }
  end

  private

  def increase_difficult_for_sums(collection)
    signs = { "+" => @sum_range, "-" => @difference_range, "*" => @multiplication_range, "/" => @divider_range }
    math_collection =
      if @math_type == 5
        collection.values
      else
        signs.each_with_object([]) { |sign, memo| memo << add_sign_to_sums(sign.first, collection.values, sign.last) }
      end
    signs.each_with_object([]) { |sign, memo| memo << add_sign_to_sums(sign.first, math_collection, sign.last) }
  end

  def add_sign_to_sums(sign, sums, digital_series)
    correct_sums =
      if sign == "/" || sign = "*"
        sums.flatten.select { |x| eval(x).in?(digital_series) }
      else
        sums.flatten.select { |x| eval(x) <= params[:max_result] }
      end

    results = digital_series.map do |digital|
      correct_sums.map do |sum|
        if sign == "/"
          sum + sign + digital.to_s if digital != 0 && eval(sum)%digital == 0
        else
          sum + sign + digital.to_s
        end
      end
    end.flatten
    condition_digital = sign == "/" ? 1 : 0

    math_results = []

    while math_results.size < 150
      return math_results if results.empty?

      new_results = results.shuffle.shift(150)
      math_results += new_results.compact.select do |x|
        eval(x) >= condition_digital && eval(x) <= params[:max_result].to_i
      end
    end

    math_results
  end

  def potential_cells_results(collection)
    collection.each_with_object({}) do |sums, memo|
      memo[sums.first] = sums.last.select { |x| eval(x) != 0 }
    end
  end
end
