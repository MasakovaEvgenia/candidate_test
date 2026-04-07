# frozen_string_literal: true
require 'rest-client'
require 'active_support/all'
require_relative 'helpers/rest_wrapper'
require_relative 'helpers/logger'
require 'capybara/cucumber'
require 'selenium-webdriver'
require_relative 'helpers/class_extentions'

def browser_setup(browser = 'chrome')
  case browser
  when 'chrome'
    Capybara.register_driver :chrome do |app|
      options = Selenium::WebDriver::Chrome::Options.new
      options.add_argument('--window-size=1920,1080')
      options.add_preference(:download, default_directory: "#{Dir.pwd}/features/tmp/")
      options.add_preference(:download, prompt_for_download: false)
      options.add_preference(:plugins, plugins_disabled: ['Chrome PDF Viewer'])

      Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
    end
    Capybara.default_driver = :chrome
    Capybara.page.driver.browser.manage.window.maximize
    Capybara.default_selector = :xpath
    Capybara.default_max_wait_time = 15
  else
    Capybara.register_driver :firefox_driver do |app|
      service = Selenium::WebDriver::Firefox::Service.new
      service.driver_path = 'configuration/geckodriver.exe'

      options = Selenium::WebDriver::Firefox::Options.new
      options.add_preference('browser.download.folderList', 2)
      options.add_preference('browser.download.dir', "#{Dir.pwd}/features/tmp/")
      options.add_preference('browser.helperApps.neverAsk.saveToDisk', 'application/octet-stream, text/xml')
      options.add_preference('pdfjs.disabled', true)

      Capybara::Selenium::Driver.new(app, browser: :firefox, options: options)
    end
    Capybara.default_driver = :firefox_driver
  end
end

browser_setup('chrome')  #  используем Chrome

configuration = YAML.load_file 'configuration/default.yml'
$rest_wrap = RestWrapper.new url: 'https://testing4qa.ediweb.ru/api',
                             **configuration[:credentials]
logger_initialize