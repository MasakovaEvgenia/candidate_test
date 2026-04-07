# frozen_string_literal: true

Before do |scenario|
  @scenario_data = ScenarioData.new
  # добавила логирование в консоль:
  # перед каждым сценарием выводится его название
  # после падения воводится название и текст ошибки
  puts "Начало сценария: #{scenario.name}"
end

After do |scenario|
  if scenario.failed? && scenario.exception
    # Логируем ошибку в консоль
    puts "Сценарий не прошёл: #{scenario.name}"
    puts "Ошибка: #{scenario.exception.message}"
  end
end

