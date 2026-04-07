# frozen_string_literal: true

class RestWrapper
  attr_accessor :url, :login, :password

  def initialize(url:, login:, password:)
    @url = url
    @login = login
    @password = password
  end

  def get(current_url, _params = {})
    response = RestClient::Request.execute method: :get,
                                           url: compile_full_url(current_url),
                                           user: login,
                                           password: password,
                                           accept: 'application/json',
                                           headers: { content_type: 'application/json' }
    JSON.parse(response)
  rescue StandardError => e
    send_error e
  end

  def post(current_url, params = {})
    response = RestClient::Request.execute method: :post,
                                           url: compile_full_url(current_url),
                                           user: login,
                                           password: password,
                                           payload: params.to_json,
                                           headers: { content_type: 'application/json' }
    JSON.parse(response)
  rescue => e
    send_error(e)
  end

  def put(current_url, params = {})
    response = RestClient::Request.execute method: :put,
                                           url: compile_full_url(current_url),
                                           user: login,
                                           password: password,
                                           payload: params.to_json,
                                           headers: { content_type: 'application/json' }
    JSON.parse(response)
  rescue => e
    send_error(e)
  end
  def delete(current_url, params = {})
    response = RestClient::Request.execute method: :delete,
                                           url: compile_full_url(current_url),
                                           user: login,
                                           password: password,
                                           payload: params.to_json,
                                           headers: { content_type: 'application/json' }
    JSON.parse(response)
  rescue StandardError => e
    send_error e
  end

  private

  def send_error(exception)
    puts exception.inspect

    #есть ли у исключения метод response
    if exception.respond_to?(:response) && exception.response
      status_code = exception.response.code
      body = exception.response.body

      if body && body.strip.start_with?('{', '[')
        begin
          parsed_body = JSON.parse(body)
          raise_message = "Ошибка #{status_code} с текстом #{parsed_body}"
        rescue
          raise_message = "Ошибка #{status_code} с телом: #{body[0..200]}"
        end
      else
        raise_message = "Ошибка #{status_code}"
      end
    else
      # если это не RestClient ошибка
      raise_message = "Ошибка: #{exception.message}"
    end

    raise raise_message
  end

   def compile_full_url(current_url)
     # добавида метод, без него негативные тесты падают
    url + current_url
  end
  end
