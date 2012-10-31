require File.dirname(__FILE__) + '/test_helper'
require File.dirname(__FILE__) + '/../lib/caterpillar'

class ScraperTest < Test::Unit::TestCase
  def test_should_raise_error_with_bad_login
    email = "bad@email.here"
    password = "invalid"

    VCR.use_cassette("AmazonReportScraper/with_bad_login/raise_error") do
      assert_raises Caterpillar::Amazon::AuthenticationError do
        Caterpillar::Amazon::ReportScraper.new(email, password, "123")
      end
    end
  end
  
  def test_should_be_xml_if_button_label_is_Download_XML
    assert_equal :xml, Caterpillar::Amazon::ReportScraper.report_type("Download XML")
  end

  def test_should_be_xml_if_button_label_is_Flat_File
    assert_equal :tsv, Caterpillar::Amazon::ReportScraper.report_type("Download Flat File")
  end

  def test_should_be_xml_if_button_label_is_Flat_File_V2
    assert_equal :tsv2, Caterpillar::Amazon::ReportScraper.report_type("Download Flat File V2")
  end

  def test_should_raise_error_if_type_is_not_identifiable_from_the_button_label
    assert_raises Caterpillar::Amazon::UnknownReportType do
      Caterpillar::Amazon::ReportScraper.report_type("Download PDF")
    end
  end
 
  def test_should_be_able_to_get_buyer_name_and_shipping_address_for_orders
    VCR.use_cassette("AmazonReportScraper/with_good_login/get_orders") do
      scraper = Caterpillar::Amazon::ReportScraper.new("far@far.away", "test", "123")
      orders = scraper.get_orders(["103-4328675-4697061"])

      assert_equal({
        "103-4328675-4697061" => {
          "BuyerName"       => "Jared Smith",
          "ShippingAddress" => {
            "street"     => "813 FARLEY ST",
            "city"       => "MOUNTAIN VIEW",
            "state"      => "CA",
            "postalcode" => "94043-3013"
          }
        }
      }, orders)
    end
  end
 
  def test_should_support_addresses_where_the_street_address_line_does_not_start_with_a_number
    VCR.use_cassette("AmazonReportScraper/with_good_login/shipping_address_not_starting_with_number") do
      scraper = Caterpillar::Amazon::ReportScraper.new("far@far.away", "test", "123")
      orders = scraper.get_orders(["105-1753716-0471420"])

      assert_equal({
        "105-1753716-0471420" => {
          "BuyerName" => "Lisa M Strand",
          "ShippingAddress" => {
            "street" => "W190S6321 Preston Ln",
            "city" => "Muskego",
            "state" => "WI",
            "postalcode" => "53150-8512"
          }
        }
      }, orders)
    end
  end
 
  def test_should_handle_large_reports
    VCR.use_cassette("AmazonReportScraper/with_good_login/get_orders_big") do
      scraper = Caterpillar::Amazon::ReportScraper.new("far@far.away", "test", "FOO")
      scraper.select_marketplace("ATVPDKIKX0DER")
      assert_nothing_raised do
        scraper.reports('2012-05-01', '2012-05-08')
      end
    end
  end

  def test_should_find_no_reports_if_none_exist
    VCR.use_cassette("AmazonReportScraper/with_good_login/find_reports/no_reports_to_request") do
      scraper = Caterpillar::Amazon::ReportScraper.new("far@far.away", "password17", "123")
      reports = scraper.reports("1/1/2012", "3/20/2012")

      assert_equal( true, reports.any? { |type, reports| !reports.empty? } )
    end
  end

  def test_should_find_reports_with_good_login
    VCR.use_cassette("AmazonReportScraper/with_good_login/find_reports/reports_to_request") do
      scraper = Caterpillar::Amazon::ReportScraper.new("far@far.away", "password", "123")
      reports = scraper.reports("12/28/2011", "12/30/2011")

      assert_equal( true, reports.any? { |type, reports| !reports.empty? } )
    end
  end
 
  def test_should_find_reports_in_more_than_on_page
    VCR.use_cassette("AmazonReportScraper/with_good_login/find_reports/multiple_pages") do
      scraper = Caterpillar::Amazon::ReportScraper.new("far@far.away", "password", "123")
      reports = scraper.reports("3/1/2012", "3/21/2012")

      assert_equal( true, reports.any? { |type, reports| !reports.empty? } )
    end
  end
  
  def test_should_find_no_reports_if_not_in_date_range
    VCR.use_cassette("AmazonReportScraper/with_good_login/find_reports/no_reports") do
      scraper = Caterpillar::Amazon::ReportScraper.new("far@far.away", "password17", "123")
      reports = scraper.reports("1/1/2011", "1/8/2011")

      assert_equal( true, reports.all? { |type, reports| reports.empty? } )
    end
  end

  def test_should_raise_error_if_nothing_to_request
    VCR.use_cassette("AmazonReportScraper/with_good_login/find_reports/no_reports_to_request") do
      scraper = Caterpillar::Amazon::ReportScraper.new("far@far.away", "password17", "123")
      Caterpillar::Amazon::ReportScraper.stubs(:report_type).raises(Caterpillar::Amazon::UnknownReportType)

      assert_raises Caterpillar::Amazon::UnknownReportType do
        scraper.reports("1/1/2012", "3/20/2012")
      end
    end
  end

  def test_should_return_balance
    VCR.use_cassette("AmazonReportScraper/with_good_login/get_balance", :record => :once) do
      scraper = Caterpillar::Amazon::ReportScraper.new("far@far.away", "password", "FOO")
      assert_equal(26.14, scraper.get_balance)
    end
  end

  def test_should_list_marketplaces_if_single
    VCR.use_cassette("AmazonReportScraper/with_good_login/with_single_marketplaces/get_marketplaces") do
      scraper = Caterpillar::Amazon::ReportScraper.new("far@far.away", "password", "FOO")
      expected_marketplaces = [["www.amazon.com", nil]]
      assert_equal expected_marketplaces, scraper.get_marketplaces.sort
    end
  end

  def test_should_list_marketplaces_if_several
    VCR.use_cassette("AmazonReportScraper/with_good_login/with_multiple_marketplaces/get_marketplaces") do
      scraper = Caterpillar::Amazon::ReportScraper.new("far@far.away", "password", "FOO")
      expected_marketplaces = [["Your Checkout Website", "AZ4B0ZS3LGLX"], ["Your Checkout Website (Sandbox)", "A2SMC08ZTYKXKX"], ["www.amazon.com", "ATVPDKIKX0DER"]]
      assert_equal expected_marketplaces, scraper.get_marketplaces.sort
    end
  end

  def test_should_find_reports_for_current_marketplace
    VCR.use_cassette("AmazonReportScraper/with_good_login/with_multiple_marketplaces/find_reports/reports_to_request") do
      scraper = Caterpillar::Amazon::ReportScraper.new("far@far.away", "password", "123")
      scraper.select_marketplace("AZ4B0ZS3LGLX")
      reports_1 = scraper.reports("4/1/2012", "4/5/2012")
      assert_equal(719, ( reports_1[:xml].first =~ /<AmazonOrderID>.*<\/AmazonOrderID>/ ) )
      assert_equal("<AmazonOrderID>105-3439340-2677033</AmazonOrderID>", reports_1[:xml].first[719,50])
      scraper.select_marketplace("ATVPDKIKX0DER")
      reports_2 = scraper.reports("4/1/2012", "4/5/2012")
      assert_equal(720, ( reports_2[:xml].first =~ /<AmazonOrderID>.*<\/AmazonOrderID>/ ) )
      assert_equal("<AmazonOrderID>105-3231361-4893023</AmazonOrderID>", reports_2[:xml].first[720,50])
    end
  end

  def test_should_raise_error_with_bad_login
    VCR.use_cassette("AmazonReportScraper/with_bad_login/raise_error") do
      assert_raises Caterpillar::Amazon::AuthenticationError do
        scraper = Caterpillar::Amazon::ReportScraper.new("far@far.away", "invalid", "123")
      end
    end
  end

  def test_should_raise_error_with_no_email_or_password
    VCR.use_cassette("AmazonReportScraper/with_bad_login/raise_error") do
      assert_raises Caterpillar::Amazon::AuthenticationError do
        scraper = Caterpillar::Amazon::ReportScraper.new(nil, nil, "123")
      end
    end
  end

  def test_should_raise_error_with_locked_account
    VCR.use_cassette("AmazonReportScraper/with_locked_account/raise_error", :record => :once) do
      assert_raises Caterpillar::Amazon::LockedAccountError do
        scraper = Caterpillar::Amazon::ReportScraper.new("far@far.away", "test", "123")
      end
    end
  end
end