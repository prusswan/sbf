require 'spec_helper'

describe "BrochureSpecs" do
  sbf_link = 'http://esales.hdb.gov.sg/hdbvsf/eampu05p.nsf/3ccada7e5293fd9748256e990029b104/13MAYSBF_page_5789/$file/about0_static.htm'
  details_dropdown = "//div[@id='MenuBoxTop']//a[@class='t7']"

  describe "GET /brochure_specs" do
    it "load SBF main page" do
      visit sbf_link
      # page.find(:xpath, details_dropdown).trigger(:mouseover)

      within('div#cssdrivemenu1') do
        link = find_link('Geylang')
        link['onclick'].should == "goFlats('../../13MAYSBF_page_5789/$file/map.htm?open&ft=sbf&twn=GL')"
      end
    end
  end
end
