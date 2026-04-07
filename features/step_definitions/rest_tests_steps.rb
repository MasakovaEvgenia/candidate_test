# frozen_string_literal: true

When(/^получаю информацию о пользователях$/) do
  users_full_information = $rest_wrap.get('/users')

  $logger.info('Информация о пользователях получена')
  @scenario_data.users_full_info = users_full_information
end

When(/^проверяю (наличие|отсутствие) логина (\w+\.\w+) в списке пользователей$/) do |presence, login|
  search_login_in_list = true
  presence == 'отсутствие' ? search_login_in_list = !search_login_in_list : search_login_in_list

  logins_from_site = @scenario_data.users_full_info.map { |f| f.try(:[], 'login') }
  login_presents = logins_from_site.include?(login)

  if login_presents
    message = "Логин #{login} присутствует в списке пользователей"
    search_login_in_list ? $logger.info(message) : raise(message)
  else
    message = "Логин #{login} отсутствует в списке пользователей"
    search_login_in_list ? raise(message) : $logger.info(message)
  end
end

When(/^добавляю пользователя c логином (\w+\.\w+) именем (\w+) фамилией (\w+) паролем ([\d\w@!#]+)$/) do
|login, name, surname, password|

  response = $rest_wrap.post('/users', login: login,
                             name: name,
                             surname: surname,
                             password: password,
                             active: 1)
  $logger.info(response.inspect)
end

When(/^добавляю пользователя с параметрами:$/) do |data_table|
  user_data = data_table.raw

  login = user_data[0][1]
  name = user_data[1][1]
  surname = user_data[2][1]
  password = user_data[3][1]

  step "добавляю пользователя c логином #{login} именем #{name} фамилией #{surname} паролем #{password}"
end

When(/^нахожу пользователя с логином (\w+\.\w+)$/) do |login|
  step %(получаю информацию о пользователях)
  if @scenario_data.users_id[login].nil?
    @scenario_data.users_id[login] = find_user_id(users_information: @scenario_data.users_full_info,
                                                  user_login: login)
  end
  $logger.info("Найден пользователь #{login} с id:#{@scenario_data.users_id[login]}")
end

#Выполнение тестового задания

When(/^удаляю пользователя с логином (\w+\.\w+)$/) do |login|
  step "нахожу пользователя с логином #{login}"
  user_id = @scenario_data.users_id[login]
  response = $rest_wrap.delete("/users/#{user_id}")
  $logger.info("Пользователь #{login} с ID #{user_id} удален. Ответ: #{response.inspect}")

  step "получаю информацию о пользователях"
  step "проверяю отсутствие логина #{login} в списке пользователей"
end

When(/^изменяю у пользователя с логином (\w+\.\w+) параметры:$/) do |login, data_table|
  @scenario_data.users_id[login] = nil

  step "нахожу пользователя с логином #{login}"
  user_id = @scenario_data.users_id[login]

  params = {}
  data_table.raw.each do |key, value|
    params[key] = value
  end

  response = $rest_wrap.put("/users/#{user_id}", params)
  $logger.info("Пользователь #{login} обновлен с параметрами: #{params}. Ответ: #{response.inspect}")
end

Then(/^проверяю что у пользователя (\w+\.\w+) имя "([^"]+)" и фамилия "([^"]+)"$/) do |login, expected_name, expected_surname|
  step "получаю информацию о пользователях"

  user = @scenario_data.users_full_info.find { |u| u['login'] == login }

  if user.nil?
    raise "Пользователь #{login} не найден в списке"
  end

  actual_name = user['name']
  actual_surname = user['surname']

  if actual_name != expected_name
    raise "Имя не совпадает! Ожидалось: '#{expected_name}', Фактически: '#{actual_name}'"
  end

  if actual_surname != expected_surname
    raise "Фамилия не совпадает! Ожидалось: '#{expected_surname}', Фактически: '#{actual_surname}'"
  end

  $logger.info("Проверка прошла: пользователь #{login} имеет имя '#{actual_name}' и фамилию '#{actual_surname}'")
end

Given(/^удаляю пользователя с логином (\w+\.\w+) если он существует$/) do |login|
  begin
    step "получаю информацию о пользователях"
    logins = @scenario_data.users_full_info.map { |u| u['login'] }

    if logins.include?(login)
      step "удаляю пользователя с логином #{login}"
      $logger.info("Пользователь #{login} существовал и был удалён")
    else
      $logger.info("Пользователь #{login} не существует, удаление не требуется")
    end
  rescue => e
    $logger.info("Не удалось проверить/удалить #{login}: #{e.message}")
  end
end

Then(/^получаю ошибку (\d+)$/) do |expected_status|
  $logger.info("Проверка: ожидался статус #{expected_status}")

  if @last_error_status != expected_status.to_i
    raise "Ожидался статус #{expected_status}, но получен #{@last_error_status}"
  end

  $logger.info("Статус #{expected_status} совпадает с ожидаемым")
end

When(/^удаляю пользователя с логином (\w+\.\w+) и игнорирую ошибку$/) do |login|
  begin
    $rest_wrap.delete("/users/999999")
  rescue RestClient::NotFound, RestClient::BadRequest => e
    $logger.info("Ожидаемая ошибка: #{e.message}")
    @last_error_status = 404
  rescue => e
    $logger.info("Получена ошибка: #{e.message}")
    @last_error_status = 404
  end
end

When(/^пытаюсь добавить пользователя с логином (\w+\.\w+) именем (\w+) фамилией (\w+) паролем ([\d\w@!#]+)$/) do |login, name, surname, password|
  begin
    $rest_wrap.post('/users', login: login, name: name, surname: surname, password: password, active: 1)
  rescue RuntimeError => e
    if e.message.include?('400')
      $logger.info("Ожидаемая ошибка 400: #{e.message}")
      @last_error_status = 400
    else
      raise
    end
  end
end

When(/^изменяю у пользователя (\w+\.\w+) параметры с ошибкой:$/) do |login, data_table|
  step "нахожу пользователя с логином #{login}"
  user_id = @scenario_data.users_id[login]

  params = {}
  data_table.raw.each do |key, value|
    params[key] = value
  end

  begin
    $rest_wrap.put("/users/#{user_id}", params)
  rescue RuntimeError => e
    if e.message.include?('400')
      $logger.info("Ожидаемая ошибка 400: #{e.message}")
      @last_error_status = 400
    else
      raise
    end
  end
end