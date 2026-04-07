# frozen_string_literal: true

When(/^захожу на страницу "(.+?)"$/) do |url|
 visit url
 $logger.info("Страница #{url} открыта")
 sleep 1
 end

 When(/^ввожу в поисковой строке текст "([^"]*)"$/) do |text|
 query = find("//input[@name='q']")
 query.set(text)
 query.native.send_keys(:enter)
 $logger.info('Поисковый запрос отправлен')
 sleep 1
 end

 When(/^кликаю по строке выдачи с адресом (.+?)$/) do |url|
 link_first = find("//a[@href='#{url}/']/h3")
 link_first.click
 $logger.info("Переход на страницу #{url} осуществлен")
 sleep 1
 end

 When(/^я должен увидеть текст на странице "([^"]*)"$/) do |text_page|
 sleep 1
 expect(page).to have_text text_page
 end

# выполнение тестового задания

require 'open-uri'
require 'fileutils'

When(/^нажимаю на ссылку "([^"]*)"$/) do |link_text|
  link = find("//a[@href='/ru/downloads/']")
  link.click
  $logger.info("Нажал на ссылку: #{link_text}")
  sleep 2
end

Then(/^открывается страница "([^"]*)"$/) do |expected_url|
  actual_url = current_url
  $logger.info("Ожидаемый URL: #{expected_url}")
  $logger.info("Фактический URL: #{actual_url}")

  if actual_url == expected_url
    $logger.info("Страница открыта правильно")
  else
    raise "Ожидалась страница #{expected_url}, но открылась #{actual_url}"
  end
end

When(/^нахожу ссылку на последнюю стабильную версию$/) do
  download_links = all("//a[contains(@href, '.tar.gz')]")

  if download_links.empty?
    raise "Не найдены ссылки для скачивания!"
  end

  @download_link = download_links.first
  $logger.info("Найдена ссылка: #{@download_link[:href]}")
end

When(/^запоминаю имя файла для скачивания$/) do
  full_url = @download_link[:href]
  @expected_filename = full_url.split('/').last
  $logger.info("Ожидаемое имя файла: #{@expected_filename}")
end

When(/^скачиваю файл$/) do
  download_dir = File.join(Dir.pwd, 'features', 'tmp')
  FileUtils.mkdir_p(download_dir) unless Dir.exist?(download_dir)

  file_path = File.join(download_dir, @expected_filename)

  begin
    $logger.info("Начинаю скачивание: #{@download_link[:href]}")

    URI.open(@download_link[:href]) do |remote_file|
      File.open(file_path, 'wb') do |local_file|
        while (chunk = remote_file.read(1024))
          local_file.write(chunk)
        end
      end
    end

    $logger.info("Файл скачан: #{file_path}")
    $logger.info("Размер файла: #{File.size(file_path)} байт")

  rescue => e
    $logger.error("Ошибка при скачивании: #{e.class} - #{e.message}")
    raise
  end
end

Then(/^файл сохраняется в папку features\/tmp$/) do
  download_dir = File.join(Dir.pwd, 'features', 'tmp')
  file_path = File.join(download_dir, @expected_filename)

  if File.exist?(file_path)
    $logger.info("Файл найден: #{file_path}")
  else
    raise "Файл НЕ найден: #{file_path}"
  end

  if File.size(file_path) > 0
    $logger.info("Файл не пустой, размер: #{File.size(file_path)} байт")
  else
    raise "Файл пустой!"
  end
end

Then(/^имя скачанного файла совпадает с ожидаемым$/) do
  download_dir = File.join(Dir.pwd, 'features', 'tmp')
  downloaded_files = Dir.glob(File.join(download_dir, 'ruby-*'))

  if downloaded_files.empty?
    raise "Не найдено ни одного скачанного ruby-файла"
  end

  actual_file = downloaded_files.first
  actual_filename = File.basename(actual_file)

  $logger.info("Ожидали: #{@expected_filename}")
  $logger.info("Получили: #{actual_filename}")

  if actual_filename == @expected_filename
    $logger.info("Имена совпадают!")
  else
    raise "Имена НЕ совпадают! Ожидали '#{@expected_filename}', получили '#{actual_filename}'"
  end
end